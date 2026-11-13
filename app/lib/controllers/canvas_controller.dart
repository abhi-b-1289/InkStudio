import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/app_constants.dart';
import '../models/canvas_item.dart';
import '../models/canvas_preset.dart';
import '../models/shape.dart';
import '../services/svg_document.dart';

enum _Drag { none, resize, rotate, lasso, multiMove }

class CanvasController extends ChangeNotifier {
  final List<CanvasItem> items = [];
  final List<List<CanvasItem>> _undo = [];
  final List<List<CanvasItem>> _redo = [];

  ToolType tool = ToolType.pen;
  Color color = Colors.black;
  double penSize = 4;
  double eraserSize = 20;
  Size canvasSize = Size.zero;

  CanvasPreset? preset;

  int? selectedId;

  final Set<int> selectedIds = {};
  int _nextId = 1;

  Offset? lassoStart;
  Offset? lassoEnd;

  Color? _styleStroke;
  Color? _styleFill;
  double _styleWidth = 3;

  Stroke? _current;
  _Drag _drag = _Drag.none;
  bool _dragRecorded = false;
  Stroke? _initialStroke;
  Offset _initialCenter = Offset.zero;
  double _dragStartAngle = 0;
  double _strokeRotationAtDragStart = 0;

  double get size => tool == ToolType.eraser ? eraserSize : penSize;
  set size(double v) {
    if (tool == ToolType.eraser) {
      eraserSize = v;
    } else {
      penSize = v;
    }
    notifyListeners();
  }

  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;

  ShapeItem? get selected {
    if (selectedId == null) return null;
    for (final it in items) {
      if (it is ShapeItem && it.id == selectedId) return it;
    }
    return null;
  }

  Stroke? get selectedStroke {
    if (selectedIds.length != 1) return null;
    final id = selectedIds.first;
    for (final it in items) {
      if (it is Stroke && it.id == id) return it;
    }
    return null;
  }

  int get _selIndex => items.indexWhere((e) => e is ShapeItem && e.id == selectedId);

  int idOf(CanvasItem it) {
    if (it is ShapeItem) return it.id;
    if (it is GroupItem) return it.id;
    if (it is Stroke) return it.id;
    return -1;
  }

  void loadItems(List<CanvasItem> saved) {
    items
      ..clear()
      ..addAll(saved);
    var maxId = 0;
    for (final it in items) {
      if (it is ShapeItem && it.id > maxId) maxId = it.id;
      if (it is GroupItem && it.id > maxId) maxId = it.id;
      if (it is Stroke && it.id > maxId) maxId = it.id;
    }
    _nextId = maxId + 1;
  }

  void _pushHistory() {
    _undo.add(List.of(items));
    if (_undo.length > 100) _undo.removeAt(0);
    _redo.clear();
  }

  void _restore(List<CanvasItem> snapshot) {
    items..clear()..addAll(snapshot);
    selectedId = null;
    selectedIds.clear();
    _drag = _Drag.none;
  }

  void undo() { if (!canUndo) return; _redo.add(List.of(items)); _restore(_undo.removeLast()); notifyListeners(); }
  void redo() { if (!canRedo) return; _undo.add(List.of(items)); _restore(_redo.removeLast()); notifyListeners(); }
  void clear() {
    if (items.isEmpty) return;
    _pushHistory(); items.clear(); selectedId = null; selectedIds.clear(); notifyListeners();
  }

  void setTool(ToolType t) {
    tool = t;
    if (t != ToolType.select) { selectedId = null; selectedIds.clear(); }
    lassoStart = lassoEnd = null;
    notifyListeners();
  }

  void setColor(Color c) {
    color = c;
    _styleStroke = null;
    tool = ToolType.pen;
    selectedId = null; selectedIds.clear();
    notifyListeners();
  }

  void pointerDown(Offset p) {
    if (tool == ToolType.pen || tool == ToolType.eraser) {
      _startStroke(p);
    } else if (tool == ToolType.select) {
      _selectDown(p);
    }
  }

  void pointerMove(Offset p, Offset delta) {
    if (_current != null) {
      _current!.points.add(p);
      notifyListeners();
      return;
    }

    if (_drag == _Drag.lasso) {
      lassoEnd = p;
      notifyListeners();
      return;
    }

    if (_drag == _Drag.multiMove) {
      _recordOnce();

      for (var i = 0; i < items.length; i++) {
        final it = items[i];
        if (!selectedIds.contains(idOf(it))) continue;
        if (it is ShapeItem) {
          items[i] = it.copyWith(center: it.center + delta);
        } else if (it is GroupItem) {
          items[i] = GroupItem(id: it.id, children: it.children, offset: it.offset + delta);
        } else if (it is Stroke) {
          items[i] = Stroke(
            id: it.id, tool: it.tool, color: it.color, width: it.width,
            points: it.points.map((q) => q + delta).toList(),
            cap: it.cap,
            startRound: it.startRound,
            endRound: it.endRound,
            erases: it.erases.map((e) => e.translate(delta)).toList(),
            rotation: it.rotation,
            origin: it.origin == null ? null : it.origin! + delta,
          );
        }
      }
      notifyListeners();
      return;
    }

    if (_drag == _Drag.rotate && _initialStroke != null) {
      _recordOnce();
      final currentAngle = math.atan2(p.dx - _initialCenter.dx, -(p.dy - _initialCenter.dy));
      final deltaAngle = currentAngle - _dragStartAngle;
      final newRotation = _strokeRotationAtDragStart + deltaAngle;
      final rotated = _initialStroke!.rotateAround(_initialCenter, deltaAngle, newRotation);
      final idx = items.indexWhere((it) => it is Stroke && it.id == _initialStroke!.id);
      if (idx >= 0) items[idx] = rotated;
      notifyListeners();
      return;
    }

    final i = _selIndex;
    if (i < 0 || _drag == _Drag.none) return;
    final s = items[i] as ShapeItem;
    _recordOnce();
    switch (_drag) {
      case _Drag.resize:
        final l = s.toLocal(p);
        if (s.type == ShapeType.circle) {
          final d = math.max(16.0, math.max(l.dx.abs(), l.dy.abs()) * 2);
          items[i] = s.copyWith(size: Size(d, d));
        } else {
          items[i] = s.copyWith(size: Size(math.max(16, l.dx.abs() * 2), math.max(16, l.dy.abs() * 2)));
        }
      case _Drag.rotate:
        final v = p - s.center;
        items[i] = s.copyWith(rotation: math.atan2(v.dx, -v.dy));
      default: break;
    }
    notifyListeners();
  }

  void pointerUp() {
    if (_drag == _Drag.lasso) {
      _commitLasso();
    }
    final current = _current;
    if (current != null && current.tool == ToolType.eraser) {
      _applyEraser(current);
    }
    _current = null;
    _drag = _Drag.none;
    _initialStroke = null;
    lassoStart = lassoEnd = null;
    notifyListeners();
  }

  void _recordOnce() { if (!_dragRecorded) { _pushHistory(); _dragRecorded = true; } }

  void _startStroke(Offset p) {
    if (tool != ToolType.eraser) _pushHistory();
    _current = Stroke(id: _nextId++, tool: tool, color: color, width: size, points: [p]);
    items.add(_current!);
    notifyListeners();
  }

  void _applyEraser(Stroke eraser) {
    if (eraser.points.isEmpty) return;
    final radius = eraser.width / 2;
    final pts = eraser.points;
    final rebuilt = <CanvasItem>[];
    var changed = false;
    for (final it in items) {
      if (identical(it, eraser)) continue;
      if (it is Stroke) {
        final erased = _eraseStroke(it, pts, radius);
        if (!identical(erased, it)) changed = true;
        rebuilt.add(erased);
      } else if (it is ShapeItem) {
        final erased = _eraseShape(it, pts, radius);
        if (!identical(erased, it)) changed = true;
        rebuilt.add(erased);
      } else if (it is GroupItem) {
        final erased = _eraseGroup(it, pts, radius);
        if (!identical(erased, it)) changed = true;
        rebuilt.add(erased);
      } else {
        rebuilt.add(it);
      }
    }
    if (!changed) {
      items.removeWhere((it) => identical(it, eraser));
      return;
    }
    items.removeWhere((it) => identical(it, eraser));
    _pushHistory();
    items
      ..clear()
      ..addAll(rebuilt);
    selectedIds.removeWhere((id) => !items.any((it) => idOf(it) == id));
    if (selectedId != null && !items.any((it) => it is ShapeItem && it.id == selectedId)) {
      selectedId = null;
    }
  }

  Stroke _eraseStroke(Stroke s, List<Offset> eraser, double eraserRadius) {
    if (s.tool == ToolType.eraser || s.points.isEmpty) return s;
    final reach = eraserRadius + s.width / 2;
    final eraserBounds = _polyBounds(eraser);
    final eraserBox = eraserBounds.inflate(reach);
    if (!eraserBox.overlaps(_polyBounds(s.points))) return s;

    final hit = s.points.length == 1
        ? (eraserBox.contains(s.points.first) &&
            _distToPolyline(s.points.first, eraser) <= reach)
        : _strokeHitsEraser(s, eraser, reach, eraserBounds);
    if (!hit) return s;

    return s.copyWith(
      erases: [
        ...s.erases,
        StrokeErase(points: List.of(eraser), width: eraserRadius * 2),
      ],
    );
  }

  static bool _strokeHitsEraser(
      Stroke s, List<Offset> eraser, double reach, Rect eraserBounds) {
    for (var i = 0; i < s.points.length - 1; i++) {
      if (_segmentHitsPolyline(s.points[i], s.points[i + 1], eraser, reach, eraserBounds)) {
        return true;
      }
    }
    return false;
  }

  ShapeItem _eraseShape(ShapeItem s, List<Offset> eraser, double eraserRadius) {
    final reach = Offset(s.size.width / 2, s.size.height / 2).distance +
        s.strokeWidth + eraserRadius + 2;
    final box = Rect.fromCircle(center: s.center, radius: reach);
    if (!eraser.any(box.contains)) return s;
    final local = eraser.map((p) {
      final l = s.toLocal(p);
      return Offset(l.dx / s.size.width + 0.5, l.dy / s.size.height + 0.5);
    }).toList();
    return s.copyWith(erases: [...s.erases, ShapeErase(points: local, width: eraserRadius * 2)]);
  }

  GroupItem _eraseGroup(GroupItem g, List<Offset> eraser, double eraserRadius) {
    final local = eraser.map((p) => p - g.offset).toList();
    final children = <CanvasItem>[];
    var changed = false;
    for (final c in g.children) {
      if (c is Stroke) {
        final erased = _eraseStroke(c, local, eraserRadius);
        if (!identical(erased, c)) changed = true;
        children.add(erased);
      } else if (c is ShapeItem) {
        final erased = _eraseShape(c, local, eraserRadius);
        if (!identical(erased, c)) changed = true;
        children.add(erased);
      } else if (c is GroupItem) {
        final erased = _eraseGroup(c, local, eraserRadius);
        if (!identical(erased, c)) changed = true;
        children.add(erased);
      } else {
        children.add(c);
      }
    }
    if (!changed) return g;
    return GroupItem(id: g.id, children: children, offset: g.offset);
  }

  static double _distToSegment(Offset p, Offset a, Offset b) {
    final ab = b - a;
    final len2 = ab.dx * ab.dx + ab.dy * ab.dy;
    if (len2 == 0) return (p - a).distance;
    var t = ((p.dx - a.dx) * ab.dx + (p.dy - a.dy) * ab.dy) / len2;
    t = t.clamp(0.0, 1.0).toDouble();
    return (p - Offset(a.dx + ab.dx * t, a.dy + ab.dy * t)).distance;
  }

  static bool _segmentsCross(Offset p1, Offset p2, Offset q1, Offset q2) {
    double cross(Offset a, Offset b, Offset c) =>
        (b.dx - a.dx) * (c.dy - a.dy) - (b.dy - a.dy) * (c.dx - a.dx);
    final d1 = cross(q1, q2, p1), d2 = cross(q1, q2, p2);
    final d3 = cross(p1, p2, q1), d4 = cross(p1, p2, q2);
    return ((d1 > 0 && d2 < 0) || (d1 < 0 && d2 > 0)) &&
        ((d3 > 0 && d4 < 0) || (d3 < 0 && d4 > 0));
  }

  static double _segSegDist(Offset a1, Offset a2, Offset b1, Offset b2) {
    if (_segmentsCross(a1, a2, b1, b2)) return 0;
    return math.min(
      math.min(_distToSegment(a1, b1, b2), _distToSegment(a2, b1, b2)),
      math.min(_distToSegment(b1, a1, a2), _distToSegment(b2, a1, a2)),
    );
  }

  static double _distToPolyline(Offset p, List<Offset> poly) {
    if (poly.isEmpty) return double.infinity;
    if (poly.length == 1) return (p - poly.first).distance;
    var best = double.infinity;
    for (var i = 0; i < poly.length - 1; i++) {
      best = math.min(best, _distToSegment(p, poly[i], poly[i + 1]));
    }
    return best;
  }

  static Rect _polyBounds(List<Offset> pts) {
    var l = double.infinity, t = double.infinity;
    var r = -double.infinity, b = -double.infinity;
    for (final p in pts) {
      if (p.dx < l) l = p.dx;
      if (p.dy < t) t = p.dy;
      if (p.dx > r) r = p.dx;
      if (p.dy > b) b = p.dy;
    }
    if (l == double.infinity) return Rect.zero;
    return Rect.fromLTRB(l, t, r, b);
  }

  static bool _segmentHitsPolyline(
      Offset a, Offset b, List<Offset> poly, double r, Rect polyBounds) {
    if (poly.isEmpty) return false;
    final box = Rect.fromLTRB(
      math.min(a.dx, b.dx) - r,
      math.min(a.dy, b.dy) - r,
      math.max(a.dx, b.dx) + r,
      math.max(a.dy, b.dy) + r,
    );
    if (!box.overlaps(polyBounds)) return false;
    if (poly.length == 1) return _distToSegment(poly.first, a, b) <= r;
    for (var i = 0; i < poly.length - 1; i++) {
      if (_segSegDist(a, b, poly[i], poly[i + 1]) <= r) return true;
    }
    return false;
  }

  void _commitLasso() {
    if (lassoStart == null || lassoEnd == null) return;
    final rect = Rect.fromPoints(lassoStart!, lassoEnd!);
    selectedIds.clear();
    selectedId = null;
    for (final it in items) {
      if (it is ShapeItem && _shapeInLasso(it, rect)) {
        selectedIds.add(it.id);
      } else if (it is GroupItem && rect.overlaps(it.bounds.translate(it.offset.dx, it.offset.dy))) {
        selectedIds.add(it.id);
      } else if (it is Stroke) {

        if (it.points.any((p) => rect.contains(p))) {
          selectedIds.add(it.id);
        }
      }
    }

    if (selectedIds.length == 1) {
      final id = selectedIds.first;
      for (final it in items) {
        if (it is ShapeItem && it.id == id) { selectedId = id; break; }
      }
    }
  }

  bool _shapeInLasso(ShapeItem s, Rect rect) {
    final hw = s.size.width / 2, hh = s.size.height / 2;
    final shapeBounds = Rect.fromCenter(center: s.center, width: hw * 2, height: hh * 2);
    return rect.overlaps(shapeBounds);
  }

  void _selectDown(Offset p) {
    _dragRecorded = false;
    final s = selected;

    if (s != null && selectedIds.length == 1) {
      final rot = s.toWorld(Offset(0, -s.size.height / 2 - kRotateGap));
      final res = s.toWorld(Offset(s.size.width / 2, s.size.height / 2));
      if ((p - rot).distance <= kHandleHit) { _drag = _Drag.rotate; return; }
      if ((p - res).distance <= kHandleHit) { _drag = _Drag.resize; return; }
    }

    final stroke = selectedStroke;
    if (stroke != null && selectedIds.length == 1) {
      final rot = stroke.rotateHandle;
      if ((p - rot).distance <= kHandleHit) {
        _drag = _Drag.rotate;
        _initialStroke = stroke;
        _initialCenter = stroke.center;
        _dragStartAngle = math.atan2(p.dx - _initialCenter.dx, -(p.dy - _initialCenter.dy));
        _strokeRotationAtDragStart = stroke.rotation;
        return;
      }
    }

    if (selectedIds.isNotEmpty) {
      for (final it in items) {
        if (!selectedIds.contains(idOf(it))) continue;
        bool hit = false;
        if (it is ShapeItem) hit = _hits(it, p);
        if (it is GroupItem) hit = it.bounds.translate(it.offset.dx, it.offset.dy).inflate(10).contains(p);
        if (it is Stroke) hit = _strokeHit(it, p);
        if (hit) {

          if (selectedIds.length == 1 && it is ShapeItem) selectedId = it.id;
          _drag = _Drag.multiMove;
          return;
        }
      }
    }

    CanvasItem? hitItem;
    for (var i = items.length - 1; i >= 0; i--) {
      final it = items[i];
      if (it is ShapeItem && _hits(it, p)) { hitItem = it; break; }
      if (it is GroupItem && it.bounds.translate(it.offset.dx, it.offset.dy).inflate(10).contains(p)) { hitItem = it; break; }
      if (it is Stroke && _strokeHit(it, p)) { hitItem = it; break; }
    }

    if (hitItem == null) {

      selectedId = null;
      selectedIds.clear();
      lassoStart = p;
      lassoEnd = p;
      _drag = _Drag.lasso;
    } else {

      final id = idOf(hitItem);
      selectedIds.clear();
      selectedId = null;
      selectedIds.add(id);
      if (hitItem is ShapeItem) selectedId = hitItem.id;
      _drag = _Drag.multiMove;
    }
    notifyListeners();
  }

  bool _strokeHit(Stroke s, Offset p) {
    const r = 18.0;
    for (final q in s.points) {
      if ((q - p).distanceSquared < r * r) return true;
    }
    return false;
  }

  bool _hits(ShapeItem s, Offset p) {
    final l = s.toLocal(p);
    final box = Rect.fromCenter(center: Offset.zero, width: s.size.width, height: s.size.height);
    return box.inflate(10 + s.strokeWidth / 2).contains(l);
  }

  void selectAll() {
    selectedIds.clear();
    selectedId = null;
    for (final it in items) {
      final id = idOf(it);
      if (id >= 0) selectedIds.add(id);
    }
    if (selectedIds.length == 1) {
      for (final it in items) {
        if (it is ShapeItem && selectedIds.contains(it.id)) { selectedId = it.id; break; }
      }
    }
    notifyListeners();
  }

  void clearSelection() {
    selectedId = null;
    selectedIds.clear();
    notifyListeners();
  }

  void groupSelected() {
    if (selectedIds.length < 2) return;
    _pushHistory();
    final toGroup = <CanvasItem>[];
    final toRemove = <int>[];
    for (var i = 0; i < items.length; i++) {
      final it = items[i];
      if (selectedIds.contains(idOf(it))) {

        if (it is GroupItem) {
          toGroup.addAll(it.bake());
        } else {
          toGroup.add(it);
        }
        toRemove.add(i);
      }
    }
    for (final idx in toRemove.reversed) items.removeAt(idx);
    final g = GroupItem(id: _nextId++, children: toGroup);
    items.add(g);
    selectedIds.clear();
    selectedId = null;
    selectedIds.add(g.id);
    notifyListeners();
  }

  void ungroupSelected() {
    _pushHistory();
    final toUngroup = items
        .whereType<GroupItem>()
        .where((g) => selectedIds.contains(g.id))
        .toList();
    if (toUngroup.isEmpty) return;
    for (final g in toUngroup) {
      final idx = items.indexOf(g);
      items.removeAt(idx);
      items.insertAll(idx, g.bake());
      selectedIds.remove(g.id);
    }
    notifyListeners();
  }

  void deleteMultiSelected() {
    if (selectedIds.isEmpty) return;
    _pushHistory();
    items.removeWhere((it) => selectedIds.contains(idOf(it)));
    selectedIds.clear();
    selectedId = null;
    notifyListeners();
  }

  void duplicateMultiSelected() {
    if (selectedIds.isEmpty) return;
    _pushHistory();
    final newIds = <int>{};
    final copies = <CanvasItem>[];
    for (final it in items) {
      if (!selectedIds.contains(idOf(it))) continue;
      if (it is ShapeItem) {
        final c = ShapeItem(
          id: _nextId++, type: it.type,
          center: it.center + const Offset(24, 24),
          size: it.size, rotation: it.rotation,
          strokeColor: it.strokeColor, fillColor: it.fillColor, strokeWidth: it.strokeWidth,
          erases: it.erases,
        );
        copies.add(c); newIds.add(c.id);
      } else if (it is GroupItem) {
        final g = GroupItem(id: _nextId++, children: List.of(it.bake()));
        copies.add(g); newIds.add(g.id);
      } else if (it is Stroke) {
        final newId = _nextId++;
        copies.add(Stroke(
          id: newId, tool: it.tool, color: it.color, width: it.width,
          points: it.points.map((p) => p + const Offset(24, 24)).toList(),
          cap: it.cap,
          startRound: it.startRound,
          endRound: it.endRound,
          erases: it.erases.map((e) => e.translate(const Offset(24, 24))).toList(),
          rotation: it.rotation,
          origin: it.origin == null ? null : it.origin! + const Offset(24, 24),
        ));
        newIds.add(newId);
      }
    }
    items.addAll(copies);
    selectedIds
      ..clear()
      ..addAll(newIds);
    selectedId = null;
    notifyListeners();
  }

  void rotateSelectedBy(double degrees) {
    if (selectedIds.isEmpty) return;
    _pushHistory();
    final rad = degrees * math.pi / 180;
    final cosA = math.cos(rad), sinA = math.sin(rad);

    double sumX = 0, sumY = 0, count = 0;
    for (final it in items) {
      if (!selectedIds.contains(idOf(it))) continue;
      if (it is ShapeItem) { sumX += it.center.dx; sumY += it.center.dy; count++; }
      if (it is GroupItem) {
        final b = it.bounds.translate(it.offset.dx, it.offset.dy);
        sumX += b.center.dx; sumY += b.center.dy; count++;
      }
      if (it is Stroke && it.points.isNotEmpty) {
        sumX += it.center.dx; sumY += it.center.dy; count++;
      }
    }
    if (count == 0) return;
    final cx = sumX / count, cy = sumY / count;

    Offset rotFn(Offset o) {
      final dx = o.dx - cx, dy = o.dy - cy;
      return Offset(cx + dx * cosA - dy * sinA, cy + dx * sinA + dy * cosA);
    }

    for (var i = 0; i < items.length; i++) {
      final it = items[i];
      if (!selectedIds.contains(idOf(it))) continue;
      if (it is ShapeItem) {
        items[i] = it.copyWith(center: rotFn(it.center), rotation: it.rotation + rad);
      } else if (it is GroupItem) {
        final baked = it.bake();
        final rotated = baked.map((c) {
          if (c is ShapeItem) return c.copyWith(center: rotFn(c.center), rotation: c.rotation + rad);
          if (c is Stroke) {
            return Stroke(
              id: c.id, tool: c.tool, color: c.color, width: c.width,
              points: c.points.map(rotFn).toList(),
              cap: c.cap, startRound: c.startRound, endRound: c.endRound,
              erases: c.erases.map((e) => e.mapPoints(rotFn)).toList(),
              rotation: c.rotation + rad,
              origin: rotFn(c.center),
            );
          }
          return c;
        }).toList();
        items[i] = GroupItem(id: it.id, children: rotated);
      } else if (it is Stroke) {
        items[i] = Stroke(
          id: it.id, tool: it.tool, color: it.color, width: it.width,
          points: it.points.map(rotFn).toList(),
          cap: it.cap, startRound: it.startRound, endRound: it.endRound,
          erases: it.erases.map((e) => e.mapPoints(rotFn)).toList(),
          rotation: it.rotation + rad,
          origin: rotFn(it.center),
        );
      }
    }
    notifyListeners();
  }

  void addShape(ShapeType type, {Offset? at}) {
    _pushHistory();
    final c = at ?? (canvasSize == Size.zero ? const Offset(160, 200) : Offset(canvasSize.width / 2, canvasSize.height / 2));
    final s = ShapeItem(
      id: _nextId++, type: type, center: c, size: type.defaultSize,
      strokeColor: _styleStroke ?? color, fillColor: _styleFill, strokeWidth: _styleWidth,
    );
    items.add(s);
    selectedIds.clear();
    selectedId = s.id;
    selectedIds.add(s.id);
    tool = ToolType.select;
    notifyListeners();
  }

  void beginEdit() => _pushHistory();
  void updateSelected(ShapeItem Function(ShapeItem) fn, {bool record = true}) {
    final i = _selIndex; if (i < 0) return;
    if (record) _pushHistory();
    final updated = fn(items[i] as ShapeItem);
    items[i] = updated;
    _styleStroke = updated.strokeColor;
    _styleFill = updated.fillColor;
    _styleWidth = updated.strokeWidth;
    notifyListeners();
  }

  void deleteSelected() {
    final i = _selIndex; if (i < 0) return;
    final id = selectedId;
    _pushHistory();
    items.removeAt(i);
    selectedId = null;
    if (id != null) selectedIds.remove(id);
    notifyListeners();
  }

  void duplicateSelected() {
    final s = selected; if (s == null) return;
    _pushHistory();
    final copy = ShapeItem(
      id: _nextId++, type: s.type,
      center: s.center + const Offset(24, 24), size: s.size, rotation: s.rotation,
      strokeColor: s.strokeColor, fillColor: s.fillColor, strokeWidth: s.strokeWidth,
      erases: s.erases,
    );
    items.add(copy);
    selectedId = copy.id;
    selectedIds.clear();
    selectedIds.add(copy.id);
    notifyListeners();
  }

  void bringToFront() {
    final i = _selIndex; if (i < 0 || i == items.length - 1) return;
    _pushHistory(); items.add(items.removeAt(i)); notifyListeners();
  }

  void updateStroke(int strokeId, {Color? color, double? width, bool record = true}) {
    final i = items.indexWhere((it) => it is Stroke && it.id == strokeId);
    if (i < 0) return;
    if (record) _pushHistory();
    final stroke = items[i] as Stroke;
    items[i] = stroke.copyWith(
      color: color,
      width: width,
    );
    notifyListeners();
  }

  void rotateStrokeTo(int strokeId, double targetRad, {bool record = true}) {
    final i = items.indexWhere((it) => it is Stroke && it.id == strokeId);
    if (i < 0) return;
    final stroke = items[i] as Stroke;
    if (record) _pushHistory();
    final delta = targetRad - stroke.rotation;
    items[i] = stroke.rotateAround(stroke.center, delta, targetRad);
    notifyListeners();
  }

  void deleteStroke(int strokeId) {
    final i = items.indexWhere((it) => it is Stroke && it.id == strokeId);
    if (i < 0) return;
    _pushHistory();
    items.removeAt(i);
    selectedIds.remove(strokeId);
    selectedId = null;
    notifyListeners();
  }

  void duplicateStroke(int strokeId) {
    final i = items.indexWhere((it) => it is Stroke && it.id == strokeId);
    if (i < 0) return;
    _pushHistory();
    final stroke = items[i] as Stroke;
    final newId = _nextId++;
    items.add(Stroke(
      id: newId, tool: stroke.tool, color: stroke.color, width: stroke.width,
      points: stroke.points.map((p) => p + const Offset(24, 24)).toList(),
      cap: stroke.cap,
      startRound: stroke.startRound,
      endRound: stroke.endRound,
      erases: stroke.erases.map((e) => e.translate(const Offset(24, 24))).toList(),
      rotation: stroke.rotation,
      origin: stroke.origin == null ? null : stroke.origin! + const Offset(24, 24),
    ));
    selectedIds.clear();
    selectedId = null;
    selectedIds.add(newId);
    notifyListeners();
  }

  String toSvg() => buildSvgDocument(items, canvasSize);

  void resetAll() {
    items.clear();
    _undo.clear();
    _redo.clear();
    selectedId = null;
    selectedIds.clear();
    _current = null;
    _drag = _Drag.none;
    _dragRecorded = false;
    lassoStart = lassoEnd = null;
    notifyListeners();
  }
}


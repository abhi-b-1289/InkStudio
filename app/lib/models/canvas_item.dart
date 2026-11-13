import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/app_constants.dart';
import '../core/formatters.dart';
import 'shape.dart';

enum ToolType { pen, eraser, shapes, select }

abstract class CanvasItem {
  String toSvg();
}

int _svgMaskSeq = 0;

class StrokeErase {
  final List<Offset> points;
  final double width;
  const StrokeErase({required this.points, required this.width});

  StrokeErase translate(Offset delta) =>
      StrokeErase(points: points.map((p) => p + delta).toList(), width: width);

  StrokeErase mapPoints(Offset Function(Offset) fn) =>
      StrokeErase(points: points.map(fn).toList(), width: width);
}

class Stroke extends CanvasItem {
  final int id;
  final ToolType tool;
  final Color color;
  final double width;
  final List<Offset> points;
  final StrokeCap cap;
  final bool startRound;
  final bool endRound;
  final List<StrokeErase> erases;
  final double rotation;
  final Offset? origin;

  Stroke({
    required this.id,
    required this.tool,
    required this.color,
    required this.width,
    required this.points,
    StrokeCap? cap,
    bool? startRound,
    bool? endRound,
    this.erases = const [],
    this.rotation = 0,
    this.origin,
  })  : startRound = startRound ?? (cap == null || cap == StrokeCap.round),
        endRound = endRound ?? (cap == null || cap == StrokeCap.round),
        cap = cap ??
            (((startRound ?? (cap == null || cap == StrokeCap.round)) &&
                    (endRound ?? (cap == null || cap == StrokeCap.round)))
                ? StrokeCap.round
                : StrokeCap.butt);

  Stroke copyWith({
    int? id,
    ToolType? tool,
    Color? color,
    double? width,
    List<Offset>? points,
    StrokeCap? cap,
    bool? startRound,
    bool? endRound,
    List<StrokeErase>? erases,
    double? rotation,
    Offset? origin,
    bool clearOrigin = false,
  }) {
    return Stroke(
      id: id ?? this.id,
      tool: tool ?? this.tool,
      color: color ?? this.color,
      width: width ?? this.width,
      points: points ?? this.points,
      cap: cap ?? this.cap,
      startRound: startRound ?? this.startRound,
      endRound: endRound ?? this.endRound,
      erases: erases ?? this.erases,
      rotation: rotation ?? this.rotation,
      origin: clearOrigin ? null : (origin ?? this.origin),
    );
  }

  Offset get center => origin ?? bounds.center;

  Rect get unrotatedBounds {
    if (points.isEmpty) return Rect.zero;
    if (rotation == 0) return bounds;
    final c = center;
    final cosA = math.cos(-rotation), sinA = math.sin(-rotation);
    double l = double.infinity, t = double.infinity, r = -double.infinity, b = -double.infinity;
    for (final p in points) {
      final dx = p.dx - c.dx, dy = p.dy - c.dy;
      final rx = c.dx + dx * cosA - dy * sinA;
      final ry = c.dy + dx * sinA + dy * cosA;
      l = math.min(l, rx);
      t = math.min(t, ry);
      r = math.max(r, rx);
      b = math.max(b, ry);
    }
    return Rect.fromLTRB(l - width / 2, t - width / 2, r + width / 2, b + width / 2);
  }

  Offset get rotateHandle {
    final c = center;
    final h = math.max(24.0, unrotatedBounds.height);
    final cosA = math.cos(rotation), sinA = math.sin(rotation);
    final localDy = -h / 2 - kRotateGap;
    return Offset(c.dx - localDy * sinA, c.dy + localDy * cosA);
  }

  Stroke rotateAround(Offset pivot, double deltaAngle, double newRotation) {
    final cosA = math.cos(deltaAngle), sinA = math.sin(deltaAngle);
    Offset rot(Offset pt) {
      final dx = pt.dx - pivot.dx;
      final dy = pt.dy - pivot.dy;
      return Offset(pivot.dx + dx * cosA - dy * sinA, pivot.dy + dx * sinA + dy * cosA);
    }
    return copyWith(
      points: points.map(rot).toList(),
      erases: erases.map((e) => e.mapPoints(rot)).toList(),
      rotation: newRotation,
      origin: pivot,
    );
  }

  Rect get bounds {
    if (points.isEmpty) return Rect.zero;
    double l = points.first.dx, t = points.first.dy, r = points.first.dx, b = points.first.dy;
    for (final p in points) {
      l = math.min(l, p.dx);
      t = math.min(t, p.dy);
      r = math.max(r, p.dx);
      b = math.max(b, p.dy);
    }
    return Rect.fromLTRB(l - width / 2, t - width / 2, r + width / 2, b + width / 2);
  }

  Path smoothPath() {
    final pts = points;
    if (pts.isEmpty) return Path();
    if (pts.length == 1) return Path()..addOval(Rect.fromCircle(center: pts.first, radius: width / 2));
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 1; i < pts.length - 1; i++) {
      final mid = Offset((pts[i].dx + pts[i + 1].dx) / 2, (pts[i].dy + pts[i + 1].dy) / 2);
      path.quadraticBezierTo(pts[i].dx, pts[i].dy, mid.dx, mid.dy);
    }
    path.lineTo(pts.last.dx, pts.last.dy);
    return path;
  }

  @override
  String toSvg() {
    final col = tool == ToolType.eraser ? Colors.white : color;
    final pts = points;
    if (pts.isEmpty) return '';

    var maskDef = '';
    var maskAttr = '';
    if (erases.isNotEmpty) {
      final maskId = 'erase${_svgMaskSeq++}';
      var b = bounds;
      for (final e in erases) {
        for (final p in e.points) {
          b = b.expandToInclude(Rect.fromCircle(center: p, radius: e.width / 2));
        }
      }
      final inflated = b.inflate(width + 32);
      final m = StringBuffer('<mask id="$maskId" maskUnits="userSpaceOnUse" '
          'x="${formatNum(inflated.left)}" y="${formatNum(inflated.top)}" '
          'width="${formatNum(inflated.width)}" height="${formatNum(inflated.height)}">'
          '<rect x="${formatNum(inflated.left)}" y="${formatNum(inflated.top)}" '
          'width="${formatNum(inflated.width)}" height="${formatNum(inflated.height)}" fill="#ffffff"/>');
      for (final e in erases) {
        if (e.points.isEmpty) continue;
        if (e.points.length == 1) {
          m.write('<circle cx="${formatNum(e.points.first.dx)}" cy="${formatNum(e.points.first.dy)}" '
              'r="${formatNum(e.width / 2)}" fill="#000000"/>');
        } else {
          final d = StringBuffer('M ${formatNum(e.points.first.dx)} ${formatNum(e.points.first.dy)}');
          for (final p in e.points.skip(1)) {
            d.write(' L ${formatNum(p.dx)} ${formatNum(p.dy)}');
          }
          m.write('<path d="$d" fill="none" stroke="#000000" stroke-width="${formatNum(e.width)}" '
              'stroke-linecap="round" stroke-linejoin="round"/>');
        }
      }
      m.write('</mask>');
      maskDef = m.toString();
      maskAttr = ' mask="url(#$maskId)"';
    }

    final String mainEl;
    if (pts.length == 1) {
      mainEl = '<circle cx="${formatNum(pts.first.dx)}" cy="${formatNum(pts.first.dy)}" '
          'r="${formatNum(width / 2)}" fill="${hexColor(col)}"${opacityAttr('fill-opacity', col)}$maskAttr/>';
    } else {
      final d = StringBuffer('M ${formatNum(pts.first.dx)} ${formatNum(pts.first.dy)}');
      for (var i = 1; i < pts.length - 1; i++) {
        final mid = Offset((pts[i].dx + pts[i + 1].dx) / 2, (pts[i].dy + pts[i + 1].dy) / 2);
        d.write(' Q ${formatNum(pts[i].dx)} ${formatNum(pts[i].dy)} ${formatNum(mid.dx)} ${formatNum(mid.dy)}');
      }
      d.write(' L ${formatNum(pts.last.dx)} ${formatNum(pts.last.dy)}');
      mainEl = '<path d="$d" fill="none" stroke="${hexColor(col)}"'
          '${opacityAttr('stroke-opacity', col)} stroke-width="${formatNum(width)}" '
          'stroke-linecap="round" stroke-linejoin="round"$maskAttr/>';
    }
    return maskDef.isEmpty ? mainEl : '<g>$maskDef$mainEl</g>';
  }
}

class GroupItem extends CanvasItem {
  final int id;
  final List<CanvasItem> children;
  Offset offset;

  GroupItem({required this.id, required this.children, this.offset = Offset.zero});

  Rect get bounds {
    double l = double.infinity, t = double.infinity, r = -double.infinity, b = -double.infinity;
    for (final c in children) {
      if (c is ShapeItem) {
        final hw = c.size.width / 2, hh = c.size.height / 2;
        l = math.min(l, c.center.dx - hw);
        t = math.min(t, c.center.dy - hh);
        r = math.max(r, c.center.dx + hw);
        b = math.max(b, c.center.dy + hh);
      } else if (c is Stroke) {
        for (final p in c.points) {
          l = math.min(l, p.dx); t = math.min(t, p.dy);
          r = math.max(r, p.dx); b = math.max(b, p.dy);
        }
      }
    }
    if (l == double.infinity) return Rect.zero;
    return Rect.fromLTRB(l, t, r, b);
  }

  List<CanvasItem> bake() {
    if (offset == Offset.zero) return List.of(children);
    return children.map((c) {
      if (c is ShapeItem) return c.copyWith(center: c.center + offset);
      if (c is Stroke) {
        return Stroke(
          id: c.id, tool: c.tool, color: c.color, width: c.width,
          points: c.points.map((p) => p + offset).toList(),
          cap: c.cap, startRound: c.startRound, endRound: c.endRound,
          erases: c.erases.map((e) => e.translate(offset)).toList(),
        );
      }
      return c;
    }).toList();
  }

  @override
  String toSvg() {
    final baked = bake();
    return '<g>${baked.map((c) => c.toSvg()).join()}</g>';
  }
}

const _heartStart = Offset(0.5, 0.95);
const _heartCurves = <List<Offset>>[
  [Offset(0.2, 0.75), Offset(0.0, 0.5), Offset(0.0, 0.28)],
  [Offset(0.0, 0.1), Offset(0.15, 0.0), Offset(0.28, 0.0)],
  [Offset(0.4, 0.0), Offset(0.47, 0.08), Offset(0.5, 0.18)],
  [Offset(0.53, 0.08), Offset(0.6, 0.0), Offset(0.72, 0.0)],
  [Offset(0.85, 0.0), Offset(1.0, 0.1), Offset(1.0, 0.28)],
  [Offset(1.0, 0.5), Offset(0.8, 0.75), Offset(0.5, 0.95)],
];

class ShapeItem extends CanvasItem {
  final int id;
  final ShapeType type;
  final Offset center;
  final Size size;
  final double rotation;
  final Color strokeColor;
  final Color? fillColor;
  final double strokeWidth;
  final List<ShapeErase> erases;

  ShapeItem({
    required this.id, required this.type, required this.center, required this.size,
    this.rotation = 0, required this.strokeColor, this.fillColor, this.strokeWidth = 3,
    this.erases = const [],
  });

  ShapeItem copyWith({
    int? id, Offset? center, Size? size, double? rotation,
    Color? strokeColor, Color? fillColor, bool clearFill = false, double? strokeWidth,
    List<ShapeErase>? erases,
  }) {
    return ShapeItem(
      id: id ?? this.id, type: type, center: center ?? this.center, size: size ?? this.size,
      rotation: rotation ?? this.rotation, strokeColor: strokeColor ?? this.strokeColor,
      fillColor: clearFill ? null : (fillColor ?? this.fillColor), strokeWidth: strokeWidth ?? this.strokeWidth,
      erases: erases ?? this.erases,
    );
  }

  Offset unitToLocal(Offset u) => _lp(u);

  Offset toWorld(Offset local) {
    final c = math.cos(rotation), s = math.sin(rotation);
    return center + Offset(local.dx * c - local.dy * s, local.dx * s + local.dy * c);
  }

  Offset toLocal(Offset world) {
    final d = world - center;
    final c = math.cos(rotation), s = math.sin(rotation);
    return Offset(d.dx * c + d.dy * s, -d.dx * s + d.dy * c);
  }

  Offset _lp(Offset u) => Offset((u.dx - 0.5) * size.width, (u.dy - 0.5) * size.height);

  Path localPath() {
    final w = size.width, h = size.height;
    final r = Rect.fromLTWH(-w / 2, -h / 2, w, h);
    final p = Path();
    switch (type) {
      case ShapeType.rectangle: p.addRect(r);
      case ShapeType.roundedRect: p.addRRect(RRect.fromRectAndRadius(r, Radius.circular(math.min(w, h) * 0.2)));
      case ShapeType.circle:
      case ShapeType.ellipse: p.addOval(r);
      case ShapeType.heart:
        final s = _lp(_heartStart);
        p.moveTo(s.dx, s.dy);
        for (final c in _heartCurves) {
          final a = _lp(c[0]), b = _lp(c[1]), e = _lp(c[2]);
          p.cubicTo(a.dx, a.dy, b.dx, b.dy, e.dx, e.dy);
        }
        p.close();
      default:
        for (final poly in type.polylines) {
          final pts = poly.map(_lp).toList();
          p.moveTo(pts.first.dx, pts.first.dy);
          for (final q in pts.skip(1)) p.lineTo(q.dx, q.dy);
          if (type.isClosed) p.close();
        }
    }
    return p;
  }

  @override
  String toSvg() {
    final w = size.width, h = size.height;
    final fill = (fillColor != null && type.isClosed)
        ? 'fill="${hexColor(fillColor!)}"${opacityAttr('fill-opacity', fillColor!)}'
        : 'fill="none"';
    final stroke = 'stroke="${hexColor(strokeColor)}"${opacityAttr('stroke-opacity', strokeColor)} '
        'stroke-width="${formatNum(strokeWidth)}" stroke-linejoin="round" stroke-linecap="round"';

    final String el;
    switch (type) {
      case ShapeType.rectangle:
        el = '<rect x="${formatNum(-w / 2)}" y="${formatNum(-h / 2)}" width="${formatNum(w)}" height="${formatNum(h)}" $fill $stroke/>';
      case ShapeType.roundedRect:
        final rx = formatNum(math.min(w, h) * 0.2);
        el = '<rect x="${formatNum(-w / 2)}" y="${formatNum(-h / 2)}" width="${formatNum(w)}" height="${formatNum(h)}" rx="$rx" ry="$rx" $fill $stroke/>';
      case ShapeType.circle:
      case ShapeType.ellipse:
        el = '<ellipse cx="0" cy="0" rx="${formatNum(w / 2)}" ry="${formatNum(h / 2)}" $fill $stroke/>';
      case ShapeType.heart:
        final s = _lp(_heartStart);
        final d = StringBuffer('M ${formatNum(s.dx)} ${formatNum(s.dy)}');
        for (final c in _heartCurves) {
          final a = _lp(c[0]), b = _lp(c[1]), e = _lp(c[2]);
          d.write(' C ${formatNum(a.dx)} ${formatNum(a.dy)} ${formatNum(b.dx)} ${formatNum(b.dy)} ${formatNum(e.dx)} ${formatNum(e.dy)}');
        }
        d.write(' Z');
        el = '<path d="$d" $fill $stroke/>';
      default:
        final pts = type.polylines.map((poly) => poly.map((u) {
          final l = _lp(u);
          return '${formatNum(l.dx)},${formatNum(l.dy)}';
        }).join(' ')).toList();
        el = type.isClosed
            ? '<polygon points="${pts.first}" $fill $stroke/>'
            : pts.map((p) => '<polyline points="$p" fill="none" $stroke/>').join();
    }
    final deg = rotation * 180 / math.pi;
    var maskDef = '';
    var maskAttr = '';
    if (erases.isNotEmpty) {
      final maskId = 'erase${_svgMaskSeq++}';
      var l = -w / 2, t = -h / 2, r = w / 2, b = h / 2;
      final pad = strokeWidth + 8;
      for (final e in erases) {
        for (final u in e.points) {
          final p = _lp(u);
          l = math.min(l, p.dx - e.width / 2);
          t = math.min(t, p.dy - e.width / 2);
          r = math.max(r, p.dx + e.width / 2);
          b = math.max(b, p.dy + e.width / 2);
        }
      }
      l -= pad;
      t -= pad;
      r += pad;
      b += pad;
      final m = StringBuffer('<mask id="$maskId" maskUnits="userSpaceOnUse" '
          'x="${formatNum(l)}" y="${formatNum(t)}" width="${formatNum(r - l)}" height="${formatNum(b - t)}">'
          '<rect x="${formatNum(l)}" y="${formatNum(t)}" width="${formatNum(r - l)}" height="${formatNum(b - t)}" fill="#ffffff"/>');
      for (final e in erases) {
        final pts = e.points.map(_lp).toList();
        if (pts.isEmpty) continue;
        if (pts.length == 1) {
          m.write('<circle cx="${formatNum(pts.first.dx)}" cy="${formatNum(pts.first.dy)}" '
              'r="${formatNum(e.width / 2)}" fill="#000000"/>');
        } else {
          final d = StringBuffer('M ${formatNum(pts.first.dx)} ${formatNum(pts.first.dy)}');
          for (final p in pts.skip(1)) {
            d.write(' L ${formatNum(p.dx)} ${formatNum(p.dy)}');
          }
          m.write('<path d="$d" fill="none" stroke="#000000" stroke-width="${formatNum(e.width)}" '
              'stroke-linecap="round" stroke-linejoin="round"/>');
        }
      }
      m.write('</mask>');
      maskDef = m.toString();
      maskAttr = ' mask="url(#$maskId)"';
    }
    return '<g transform="translate(${formatNum(center.dx)} ${formatNum(center.dy)}) rotate(${formatNum(deg)})">$maskDef'
        '<g$maskAttr>$el</g></g>';
  }
}


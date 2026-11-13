import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../controllers/canvas_controller.dart';
import '../core/app_constants.dart';
import '../models/canvas_item.dart';
import '../models/saved_drawing.dart';
import '../models/shape.dart';

void paintItems(Canvas canvas, Size size, List<CanvasItem> items) {
  canvas.saveLayer(Offset.zero & size, Paint());
  for (final it in items) {
    if (it is Stroke) {
      _drawStroke(canvas, it);
    } else if (it is ShapeItem) {
      _drawShape(canvas, it);
    } else if (it is GroupItem) {
      canvas.save();
      canvas.translate(it.offset.dx, it.offset.dy);
      for (final child in it.children) {
        if (child is Stroke) _drawStroke(canvas, child);
        if (child is ShapeItem) _drawShape(canvas, child);
      }
      canvas.restore();
    }
  }
  canvas.restore();
}

void _drawStroke(Canvas canvas, Stroke s) {
  final isEraser = s.tool == ToolType.eraser;
  final pts = s.points;
  if (pts.isEmpty) return;
  final hasErases = s.erases.isNotEmpty;
  if (hasErases) {
    var b = s.bounds;
    for (final e in s.erases) {
      for (final p in e.points) {
        b = b.expandToInclude(Rect.fromCircle(center: p, radius: e.width / 2));
      }
    }
    canvas.saveLayer(b.inflate(s.width + 32), Paint());
  }

  if (pts.length == 1) {
    final dot = Paint()..style = PaintingStyle.fill..isAntiAlias = true;
    dot.blendMode = isEraser ? BlendMode.clear : BlendMode.srcOver;
    dot.color = isEraser ? Colors.white : s.color;
    canvas.drawCircle(pts.first, s.width / 2, dot);
  } else {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = s.width
      ..isAntiAlias = true;
    paint.blendMode = isEraser ? BlendMode.clear : BlendMode.srcOver;
    paint.color = isEraser ? Colors.white : s.color;
    canvas.drawPath(s.smoothPath(), paint);
  }

  if (hasErases) {
    for (final e in s.erases) {
      if (e.points.isEmpty) continue;
      final paint = Paint()
        ..isAntiAlias = true
        ..blendMode = BlendMode.clear
        ..style = PaintingStyle.stroke
        ..strokeWidth = e.width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      if (e.points.length == 1) {
        paint.style = PaintingStyle.fill;
        canvas.drawCircle(e.points.first, e.width / 2, paint);
      } else {
        final ep = Path()..moveTo(e.points.first.dx, e.points.first.dy);
        for (final q in e.points.skip(1)) {
          ep.lineTo(q.dx, q.dy);
        }
        canvas.drawPath(ep, paint);
      }
    }
    canvas.restore();
  }
}

void _drawShape(Canvas canvas, ShapeItem s) {
  canvas.save();
  canvas.translate(s.center.dx, s.center.dy);
  canvas.rotate(s.rotation);
  final path = s.localPath();
  final hasErases = s.erases.isNotEmpty;
  if (hasErases) {
    final pad = s.size.width + s.size.height + s.strokeWidth + 64;
    canvas.saveLayer(Rect.fromCenter(center: Offset.zero, width: pad * 2, height: pad * 2), Paint());
  }
  if (s.fillColor != null && s.type.isClosed) {
    canvas.drawPath(path, Paint()..style = PaintingStyle.fill..color = s.fillColor!..isAntiAlias = true);
  }
  canvas.drawPath(path, Paint()
    ..style = PaintingStyle.stroke..strokeWidth = s.strokeWidth..strokeJoin = StrokeJoin.round
    ..strokeCap = StrokeCap.round..color = s.strokeColor..isAntiAlias = true);
  if (hasErases) {
    for (final e in s.erases) {
      final pts = e.points.map(s.unitToLocal).toList();
      if (pts.isEmpty) continue;
      final paint = Paint()
        ..isAntiAlias = true
        ..blendMode = BlendMode.clear
        ..style = PaintingStyle.stroke
        ..strokeWidth = e.width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      if (pts.length == 1) {
        paint.style = PaintingStyle.fill;
        canvas.drawCircle(pts.first, e.width / 2, paint);
      } else {
        final ep = Path()..moveTo(pts.first.dx, pts.first.dy);
        for (final q in pts.skip(1)) {
          ep.lineTo(q.dx, q.dy);
        }
        canvas.drawPath(ep, paint);
      }
    }
    canvas.restore();
  }
  canvas.restore();
}

class StrokePainter extends CustomPainter {
  final CanvasController controller;
  final Color selectionColor;
  StrokePainter(this.controller, this.selectionColor) : super(repaint: controller);

  @override
  void paint(Canvas canvas, Size size) {
    paintItems(canvas, size, controller.items);

    if (controller.tool != ToolType.select) return;

    final highlightPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = selectionColor;
    final dashPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = selectionColor.withValues(alpha: 0.55);

    for (final it in controller.items) {

      final int id;
      if (it is ShapeItem) {
        id = it.id;
      } else if (it is GroupItem) {
        id = it.id;
      } else if (it is Stroke) {
        id = it.id;
      } else {
        continue;
      }
      if (!controller.selectedIds.contains(id)) continue;

      if (it is ShapeItem) {

        if (controller.selectedIds.length == 1) {
          _drawSingleSelection(canvas, it);
        } else {
          _drawItemHighlight(canvas, it, highlightPaint);
        }
      } else if (it is GroupItem) {
        final b = it.bounds.translate(it.offset.dx, it.offset.dy);
        _drawDashedRect(canvas, b.inflate(6), dashPaint);
      } else if (it is Stroke) {
        if (controller.selectedIds.length == 1) {
          _drawSingleStrokeSelection(canvas, it);
        } else {
          for (final p in it.points) {
            canvas.drawCircle(p, 6, Paint()..color = selectionColor.withValues(alpha: 0.18)..style = PaintingStyle.fill);
          }
        }
      }
    }

    if (controller.lassoStart != null && controller.lassoEnd != null) {
      final lassoRect = Rect.fromPoints(controller.lassoStart!, controller.lassoEnd!);
      final lassoBg = Paint()..color = selectionColor.withValues(alpha: 0.08)..style = PaintingStyle.fill;
      canvas.drawRect(lassoRect, lassoBg);
      _drawDashedRect(canvas, lassoRect, dashPaint..color = selectionColor);
    }
  }

  void _drawItemHighlight(Canvas canvas, ShapeItem s, Paint paint) {
    final w = s.size.width, h = s.size.height;
    canvas.save();
    canvas.translate(s.center.dx, s.center.dy);
    canvas.rotate(s.rotation);
    canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: w, height: h).inflate(4), paint);
    canvas.restore();
  }

  void _drawSingleSelection(Canvas canvas, ShapeItem s) {
    final w = s.size.width, h = s.size.height;
    canvas.save();
    canvas.translate(s.center.dx, s.center.dy);
    canvas.rotate(s.rotation);
    final line = Paint()..style = PaintingStyle.stroke..strokeWidth = 1.5..color = selectionColor;
    final handleFill = Paint()..color = Colors.white;
    canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: w, height: h).inflate(4), line);
    final rot = Offset(0, -h / 2 - kRotateGap);
    canvas.drawLine(Offset(0, -h / 2 - 4), rot, line);
    canvas.drawCircle(rot, 10, handleFill);
    canvas.drawCircle(rot, 10, line..strokeWidth = 2);
    final res = Rect.fromCenter(center: Offset(w / 2, h / 2), width: 18, height: 18);
    canvas.drawRRect(RRect.fromRectAndRadius(res, const Radius.circular(4)), handleFill);
    canvas.drawRRect(RRect.fromRectAndRadius(res, const Radius.circular(4)), line);

    final String label;
    switch (s.type) {
      case ShapeType.circle:
        label = 'R: ${(w / 2).round()} px';
      case ShapeType.line:
        label = 'L: ${w.round()} px';
      case ShapeType.ellipse:
        label = 'Rx: ${(w / 2).round()}  Ry: ${(h / 2).round()}';
      case ShapeType.triangle:
      case ShapeType.rightTriangle:
        label = 'B: ${w.round()}  H: ${h.round()}';
      case ShapeType.pentagon:
      case ShapeType.hexagon:
      case ShapeType.star:
        label = 'R: ${(w / 2).round()} px';
      default:
        label = '${w.round()} × ${h.round()} px';
    }
    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final badgeRect = Rect.fromCenter(
      center: Offset(0, h / 2 + 18),
      width: tp.width + 12,
      height: tp.height + 6,
    );
    final bgPaint = Paint()..color = const Color(0xFF1E1E2E).withValues(alpha: 0.88);
    canvas.drawRRect(RRect.fromRectAndRadius(badgeRect, const Radius.circular(8)), bgPaint);
    tp.paint(canvas, Offset(-tp.width / 2, h / 2 + 18 - tp.height / 2));

    canvas.restore();
  }

  void _drawSingleStrokeSelection(Canvas canvas, Stroke s) {
    final center = s.center;
    final unrotated = s.unrotatedBounds;
    final w = math.max(24.0, unrotated.width);
    final h = math.max(24.0, unrotated.height);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(s.rotation);
    final line = Paint()..style = PaintingStyle.stroke..strokeWidth = 1.5..color = selectionColor;
    final handleFill = Paint()..color = Colors.white;
    canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: w, height: h).inflate(4), line);
    final rot = Offset(0, -h / 2 - kRotateGap);
    canvas.drawLine(Offset(0, -h / 2 - 4), rot, line);
    canvas.drawCircle(rot, 10, handleFill);
    canvas.drawCircle(rot, 10, line..strokeWidth = 2);

    final strokeLabel = '${w.round()} × ${h.round()} px';
    final tp = TextPainter(
      text: TextSpan(
        text: strokeLabel,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final badgeRect = Rect.fromCenter(
      center: Offset(0, h / 2 + 18),
      width: tp.width + 12,
      height: tp.height + 6,
    );
    final bgPaint = Paint()..color = const Color(0xFF1E1E2E).withValues(alpha: 0.88);
    canvas.drawRRect(RRect.fromRectAndRadius(badgeRect, const Radius.circular(8)), bgPaint);
    tp.paint(canvas, Offset(-tp.width / 2, h / 2 + 18 - tp.height / 2));

    canvas.restore();
  }

  void _drawDashedRect(Canvas canvas, Rect rect, Paint paint) {
    const dashLen = 6.0, gapLen = 4.0;
    void _dashLine(Offset a, Offset b) {
      final total = (b - a).distance;
      final dir = (b - a) / total;
      var pos = 0.0;
      var drawing = true;
      while (pos < total) {
        final seg = math.min(drawing ? dashLen : gapLen, total - pos);
        if (drawing) canvas.drawLine(a + dir * pos, a + dir * (pos + seg), paint);
        pos += seg;
        drawing = !drawing;
      }
    }
    _dashLine(rect.topLeft, rect.topRight);
    _dashLine(rect.topRight, rect.bottomRight);
    _dashLine(rect.bottomRight, rect.bottomLeft);
    _dashLine(rect.bottomLeft, rect.topLeft);
  }

  @override
  bool shouldRepaint(covariant StrokePainter old) => true;
}

class ThumbnailPainter extends CustomPainter {
  final SavedDrawing drawing;
  ThumbnailPainter(this.drawing);

  @override
  void paint(Canvas canvas, Size size) {
    final cs = drawing.canvasSize;
    if (cs.width <= 0 || cs.height <= 0) return;
    final scale = math.min(size.width / cs.width, size.height / cs.height);
    final dx = (size.width - cs.width * scale) / 2;
    final dy = (size.height - cs.height * scale) / 2;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.translate(dx, dy);
    canvas.scale(scale);
    paintItems(canvas, cs, drawing.items);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant ThumbnailPainter old) => old.drawing != drawing;
}


import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../controllers/canvas_controller.dart';
import '../models/canvas_item.dart';
import '../models/shop.dart';

class GuidePainter extends CustomPainter {
  final List<CanvasItem> guide;
  final Color color;
  final double opacity;
  GuidePainter(this.guide, this.color, {this.opacity = 0.3});

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true
      ..color = color.withValues(alpha: opacity);
    final dot = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true
      ..color = color.withValues(alpha: opacity);
    for (final it in guide) {
      if (it is Stroke) {
        if (it.points.length == 1) {
          canvas.drawCircle(it.points.first, math.max(it.width / 2, 3), dot);
        } else {
          stroke.strokeWidth = math.max(it.width, 3);
          canvas.drawPath(it.smoothPath(), stroke);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant GuidePainter old) =>
      old.guide != guide || old.opacity != opacity || old.color != color;
}

class QuestCanvasPainter extends CustomPainter {
  final CanvasController controller;
  QuestCanvasPainter(this.controller) : super(repaint: controller);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.saveLayer(Offset.zero & size, Paint());
    for (final it in controller.items) {
      if (it is Stroke) _drawStroke(canvas, it);
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

  @override
  bool shouldRepaint(covariant QuestCanvasPainter old) => true;
}

class ThemePainter extends CustomPainter {
  final CanvasTheme theme;
  ThemePainter(this.theme);
  @override
  void paint(Canvas canvas, Size size) => theme.paint(canvas, size);
  @override
  bool shouldRepaint(covariant ThemePainter old) => old.theme.id != theme.id;
}


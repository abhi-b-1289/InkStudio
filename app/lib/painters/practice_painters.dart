import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../controllers/canvas_controller.dart';
import '../models/canvas_item.dart';
import 'canvas_painters.dart';

class PracticePainter extends CustomPainter {
  final CanvasController controller;
  final List<CanvasItem> guide;
  final Color accent;
  PracticePainter(this.controller, this.guide, this.accent) : super(repaint: controller);

  @override
  void paint(Canvas canvas, Size size) {
    _paintGuide(canvas, guide, accent);
    paintItems(canvas, size, controller.items);
  }

  @override
  bool shouldRepaint(covariant PracticePainter old) => true;
}

void _paintGuide(Canvas canvas, List<CanvasItem> items, Color color) {
  final outline = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..isAntiAlias = true
    ..color = color.withValues(alpha: 0.30);
  final dot = Paint()
    ..style = PaintingStyle.fill
    ..isAntiAlias = true
    ..color = color.withValues(alpha: 0.30);
  for (final it in items) {
    if (it is Stroke) {
      if (it.points.length == 1) {
        canvas.drawCircle(it.points.first, math.max(it.width / 2, 3), dot);
      } else {
        outline.strokeWidth = math.max(it.width, 3);
        canvas.drawPath(it.smoothPath(), outline);
      }
    }
  }
}


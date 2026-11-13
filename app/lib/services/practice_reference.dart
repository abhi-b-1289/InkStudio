import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/app_constants.dart';
import '../models/canvas_item.dart';
import '../models/practice_target.dart';
import '../models/shape.dart';

Stroke _guideStroke(ShapeItem shape, {required int id, double width = 3}) {
  final pts = <Offset>[];
  for (final metric in shape.localPath().computeMetrics()) {
    final n = math.max(24, (metric.length / 4).round());
    for (var i = 0; i <= n; i++) {
      final t = metric.getTangentForOffset(metric.length * i / n);
      if (t != null) pts.add(shape.toWorld(t.position));
    }
  }
  return Stroke(id: id, tool: ToolType.pen, color: kGuideInk, width: width, points: pts);
}

Stroke _guidePolyline(List<Offset> points, {required int id, double width = 3}) =>
    Stroke(id: id, tool: ToolType.pen, color: kGuideInk, width: width, points: points);

List<CanvasItem> buildPracticeGuide(PracticeTarget target, Size size) {
  final c = Offset(size.width / 2, size.height / 2);
  final s = math.min(size.width, size.height);

  ShapeItem shape(ShapeType type, double scale) => ShapeItem(
        id: 1,
        type: type,
        center: c,
        size: Size(s * scale, s * scale),
        strokeColor: kGuideInk,
        strokeWidth: 3,
      );

  switch (target) {
    case PracticeTarget.circle:
      return [_guideStroke(shape(ShapeType.circle, 0.58), id: 1)];
    case PracticeTarget.triangle:
      return [_guideStroke(shape(ShapeType.triangle, 0.62), id: 1)];
    case PracticeTarget.star:
      return [_guideStroke(shape(ShapeType.star, 0.68), id: 1)];
    case PracticeTarget.heart:
      return [_guideStroke(shape(ShapeType.heart, 0.62), id: 1)];
    case PracticeTarget.smiley:
      final r = s * 0.30;
      final smile = List<Offset>.generate(33, (i) {
        final a = math.pi * (0.16 + 0.68 * i / 32);
        return c + Offset(math.cos(a) * r * 0.62, math.sin(a) * r * 0.62 + r * 0.06);
      });
      return [
        _guideStroke(shape(ShapeType.circle, 0.60), id: 1),
        _guidePolyline([c + Offset(-r * 0.42, -r * 0.30)], id: 2, width: math.max(s * 0.045, 6)),
        _guidePolyline([c + Offset(r * 0.42, -r * 0.30)], id: 3, width: math.max(s * 0.045, 6)),
        _guidePolyline(smile, id: 4),
      ];
    case PracticeTarget.wave:
      final pts = List<Offset>.generate(49, (i) {
        final t = i / 48;
        return Offset(
          size.width * (0.14 + 0.72 * t),
          c.dy - math.sin(t * math.pi * 2) * s * 0.16,
        );
      });
      return [_guidePolyline(pts, id: 1)];
  }
}


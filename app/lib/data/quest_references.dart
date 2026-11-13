import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/app_constants.dart';
import '../models/canvas_item.dart';
import '../models/shape.dart';

Stroke _iqSampleShape(ShapeItem shape, {required int id, double width = 3}) {
  final pts = <Offset>[];
  for (final metric in shape.localPath().computeMetrics()) {
    final n = math.max(24, (metric.length / 4).round());
    for (var i = 0; i <= n; i++) {
      final t = metric.getTangentForOffset(metric.length * i / n);
      if (t != null) pts.add(shape.toWorld(t.position));
    }
  }
  if (pts.isEmpty) pts.add(shape.center);
  return Stroke(
      id: id,
      tool: ToolType.pen,
      color: kGuideInk,
      width: width,
      points: pts);
}

Stroke _iqPolyline(List<Offset> pts, {required int id, double width = 3}) =>
    Stroke(
        id: id,
        tool: ToolType.pen,
        color: kGuideInk,
        width: width,
        points: pts);

ShapeItem _iqShape(ShapeType type, Offset center, Size size, {int id = 1}) =>
    ShapeItem(
      id: id,
      type: type,
      center: center,
      size: size,
      strokeColor: kGuideInk,
      strokeWidth: 3,
    );

List<CanvasItem> circleReference(Size s) {
  final c = Offset(s.width / 2, s.height / 2);
  final r = math.min(s.width, s.height) * 0.32;
  return [
    _iqSampleShape(_iqShape(ShapeType.circle, c, Size(r * 2, r * 2)), id: 1)
  ];
}

List<CanvasItem> triangleReference(Size s) {
  final c = Offset(s.width / 2, s.height / 2);
  final sz = math.min(s.width, s.height) * 0.66;
  return [
    _iqSampleShape(
        _iqShape(ShapeType.triangle, c, Size(sz, sz * 0.9)),
        id: 1)
  ];
}

List<CanvasItem> starReference(Size s) {
  final c = Offset(s.width / 2, s.height / 2);
  final sz = math.min(s.width, s.height) * 0.72;
  return [
    _iqSampleShape(_iqShape(ShapeType.star, c, Size(sz, sz * 0.95)), id: 1)
  ];
}

List<CanvasItem> heartReference(Size s) {
  final c = Offset(s.width / 2, s.height / 2);
  final sz = math.min(s.width, s.height) * 0.65;
  return [
    _iqSampleShape(_iqShape(ShapeType.heart, c, Size(sz, sz * 0.92)), id: 1)
  ];
}

List<CanvasItem> smileyReference(Size s) {
  final c = Offset(s.width / 2, s.height / 2);
  final r = math.min(s.width, s.height) * 0.32;
  final smile = List<Offset>.generate(33, (i) {
    final a = math.pi * (0.16 + 0.68 * i / 32);
    return c +
        Offset(math.cos(a) * r * 0.62, math.sin(a) * r * 0.62 + r * 0.06);
  });
  final double eyeW =
      math.max(math.min(s.width, s.height) * 0.045, 6.0).toDouble();
  return [
    _iqSampleShape(_iqShape(ShapeType.circle, c, Size(r * 2, r * 2)), id: 1),
    _iqPolyline([c + Offset(-r * 0.42, -r * 0.3)], id: 2, width: eyeW),
    _iqPolyline([c + Offset(r * 0.42, -r * 0.3)], id: 3, width: eyeW),
    _iqPolyline(smile, id: 4),
  ];
}

List<CanvasItem> waveReference(Size s) {
  final c = Offset(s.width / 2, s.height / 2);
  final sn = math.min(s.width, s.height);
  final pts = List<Offset>.generate(49, (i) {
    final t = i / 48;
    return Offset(
      s.width * (0.14 + 0.72 * t),
      c.dy - math.sin(t * math.pi * 2) * sn * 0.16,
    );
  });
  return [_iqPolyline(pts, id: 1)];
}

List<CanvasItem> squareReference(Size s) {
  final c = Offset(s.width / 2, s.height / 2);
  final sz = math.min(s.width, s.height) * 0.58;
  return [
    _iqSampleShape(_iqShape(ShapeType.rectangle, c, Size(sz, sz)), id: 1)
  ];
}

List<CanvasItem> diamondReference(Size s) {
  final c = Offset(s.width / 2, s.height / 2);
  final sz = math.min(s.width, s.height) * 0.62;
  return [
    _iqSampleShape(_iqShape(ShapeType.diamond, c, Size(sz, sz)), id: 1)
  ];
}

List<CanvasItem> arrowReference(Size s) {
  final c = Offset(s.width / 2, s.height / 2);
  final sn = math.min(s.width, s.height);
  return [
    _iqPolyline([
      Offset(c.dx - sn * 0.3, c.dy),
      Offset(c.dx + sn * 0.3, c.dy),
    ], id: 1),
    _iqPolyline([
      Offset(c.dx + sn * 0.18, c.dy - sn * 0.15),
      Offset(c.dx + sn * 0.3, c.dy),
      Offset(c.dx + sn * 0.18, c.dy + sn * 0.15),
    ], id: 2),
  ];
}

List<CanvasItem> houseReference(Size s) {
  final c = Offset(s.width / 2, s.height / 2);
  final sn = math.min(s.width, s.height);
  final bodyCenter = Offset(c.dx, c.dy + sn * 0.08);
  final bodySize = Size(sn * 0.55, sn * 0.45);
  final roofCenter = Offset(c.dx, c.dy - sn * 0.32);
  final roofSize = Size(sn * 0.7, sn * 0.35);
  final doorCenter = Offset(c.dx + sn * 0.12, c.dy + sn * 0.20);
  final doorSize = Size(sn * 0.12, sn * 0.18);
  return [
    _iqSampleShape(_iqShape(ShapeType.rectangle, bodyCenter, bodySize), id: 1),
    _iqSampleShape(_iqShape(ShapeType.triangle, roofCenter, roofSize), id: 2),
    _iqSampleShape(_iqShape(ShapeType.rectangle, doorCenter, doorSize),
        id: 3),
  ];
}

List<CanvasItem> sunReference(Size s) {
  final c = Offset(s.width / 2, s.height / 2);
  final sn = math.min(s.width, s.height);
  final r = sn * 0.16;
  final parts = <CanvasItem>[
    _iqSampleShape(_iqShape(ShapeType.circle, c, Size(r * 2, r * 2)), id: 1),
  ];
  for (var i = 0; i < 8; i++) {
    final a = i * math.pi / 4;
    parts.add(_iqPolyline([
      c + Offset(math.cos(a) * r * 1.5, math.sin(a) * r * 1.5),
      c + Offset(math.cos(a) * r * 2.2, math.sin(a) * r * 2.2),
    ], id: 2 + i));
  }
  return parts;
}

List<CanvasItem> treeReference(Size s) {
  final c = Offset(s.width / 2, s.height / 2);
  final sn = math.min(s.width, s.height);
  return [
    _iqSampleShape(
        _iqShape(ShapeType.rectangle, Offset(c.dx, c.dy + sn * 0.22),
            Size(sn * 0.14, sn * 0.3)),
        id: 1),
    _iqSampleShape(
        _iqShape(ShapeType.circle, Offset(c.dx, c.dy - sn * 0.12),
            Size(sn * 0.5, sn * 0.5)),
        id: 2),
  ];
}

List<CanvasItem> flowerReference(Size s) {
  final c = Offset(s.width / 2, s.height / 2);
  final sn = math.min(s.width, s.height);
  final parts = <CanvasItem>[
    _iqSampleShape(_iqShape(ShapeType.circle, c, Size(sn * 0.14, sn * 0.14)),
        id: 1),
  ];
  for (var i = 0; i < 6; i++) {
    final a = i * math.pi / 3;
    final pc = c + Offset(math.cos(a) * sn * 0.15, math.sin(a) * sn * 0.15);
    parts.add(_iqSampleShape(
        _iqShape(ShapeType.circle, pc, Size(sn * 0.14, sn * 0.14)),
        id: 2 + i));
  }
  return parts;
}

List<CanvasItem> sparkleReference(Size s) {
  final c = Offset(s.width / 2, s.height / 2);
  final sn = math.min(s.width, s.height);
  final pts = <Offset>[];
  for (var i = 0; i < 8; i++) {
    final a = -math.pi / 2 + math.pi * i / 4;
    final r = i.isEven ? sn * 0.32 : sn * 0.12;
    pts.add(c + Offset(math.cos(a) * r, math.sin(a) * r));
  }
  pts.add(pts.first);
  return [_iqPolyline(pts, id: 1)];
}

List<CanvasItem> crownReference(Size s) {
  final c = Offset(s.width / 2, s.height / 2);
  final sn = math.min(s.width, s.height);
  return [
    _iqPolyline([
      Offset(c.dx - sn * 0.3, c.dy + sn * 0.2),
      Offset(c.dx - sn * 0.3, c.dy - sn * 0.1),
      Offset(c.dx - sn * 0.15, c.dy),
      Offset(c.dx, c.dy - sn * 0.2),
      Offset(c.dx + sn * 0.15, c.dy),
      Offset(c.dx + sn * 0.3, c.dy - sn * 0.1),
      Offset(c.dx + sn * 0.3, c.dy + sn * 0.2),
      Offset(c.dx - sn * 0.3, c.dy + sn * 0.2),
    ], id: 1),
  ];
}

List<CanvasItem> rocketReference(Size s) {
  final c = Offset(s.width / 2, s.height / 2);
  final sn = math.min(s.width, s.height);
  return [
    _iqSampleShape(
        _iqShape(ShapeType.roundedRect, Offset(c.dx, c.dy + sn * 0.02),
            Size(sn * 0.28, sn * 0.5)),
        id: 1),
    _iqSampleShape(
        _iqShape(ShapeType.triangle, Offset(c.dx, c.dy - sn * 0.34),
            Size(sn * 0.28, sn * 0.22)),
        id: 2),
    _iqPolyline([
      Offset(c.dx - sn * 0.14, c.dy + sn * 0.18),
      Offset(c.dx - sn * 0.26, c.dy + sn * 0.32),
      Offset(c.dx - sn * 0.14, c.dy + sn * 0.28),
    ], id: 3),
    _iqPolyline([
      Offset(c.dx + sn * 0.14, c.dy + sn * 0.18),
      Offset(c.dx + sn * 0.26, c.dy + sn * 0.32),
      Offset(c.dx + sn * 0.14, c.dy + sn * 0.28),
    ], id: 4),
    _iqSampleShape(
        _iqShape(ShapeType.circle, Offset(c.dx, c.dy - sn * 0.14),
            Size(sn * 0.1, sn * 0.1)),
        id: 5),
  ];
}

List<CanvasItem> boatReference(Size s) {
  final c = Offset(s.width / 2, s.height / 2);
  final sn = math.min(s.width, s.height);
  return [
    _iqPolyline([
      Offset(c.dx - sn * 0.3, c.dy + sn * 0.1),
      Offset(c.dx + sn * 0.3, c.dy + sn * 0.1),
      Offset(c.dx + sn * 0.2, c.dy + sn * 0.25),
      Offset(c.dx - sn * 0.2, c.dy + sn * 0.25),
      Offset(c.dx - sn * 0.3, c.dy + sn * 0.1),
    ], id: 1),
    _iqPolyline([
      Offset(c.dx, c.dy + sn * 0.1),
      Offset(c.dx, c.dy - sn * 0.3),
    ], id: 2),
    _iqPolyline([
      Offset(c.dx, c.dy - sn * 0.3),
      Offset(c.dx + sn * 0.2, c.dy + sn * 0.05),
      Offset(c.dx, c.dy + sn * 0.05),
    ], id: 3),
  ];
}

List<CanvasItem> keyReference(Size s) {
  final c = Offset(s.width / 2, s.height / 2);
  final sn = math.min(s.width, s.height);
  return [
    _iqSampleShape(
        _iqShape(ShapeType.circle, Offset(c.dx - sn * 0.2, c.dy),
            Size(sn * 0.25, sn * 0.25)),
        id: 1),
    _iqPolyline([
      Offset(c.dx - sn * 0.08, c.dy),
      Offset(c.dx + sn * 0.3, c.dy),
    ], id: 2),
    _iqPolyline([
      Offset(c.dx + sn * 0.2, c.dy),
      Offset(c.dx + sn * 0.2, c.dy + sn * 0.1),
    ], id: 3),
  ];
}

List<CanvasItem> lightbulbReference(Size s) {
  final c = Offset(s.width / 2, s.height / 2);
  final sn = math.min(s.width, s.height);
  return [
    _iqSampleShape(
        _iqShape(ShapeType.circle, Offset(c.dx, c.dy - sn * 0.08),
            Size(sn * 0.36, sn * 0.36)),
        id: 1),
    _iqSampleShape(
        _iqShape(ShapeType.rectangle, Offset(c.dx, c.dy + sn * 0.22),
            Size(sn * 0.16, sn * 0.12)),
        id: 2),
  ];
}


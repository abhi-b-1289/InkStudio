import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';

import '../models/canvas_item.dart';
import '../painters/canvas_painters.dart';

Future<Uint8List> renderPng(
  List<CanvasItem> items,
  Size size, {
  double pixelRatio = 1.0,
  Color background = const Color(0xFFFFFFFF),
}) async {
  final targetWidth = (size.width * pixelRatio).round();
  final targetHeight = (size.height * pixelRatio).round();
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(
    recorder,
    Rect.fromLTWH(0, 0, targetWidth.toDouble(), targetHeight.toDouble()),
  );

  canvas.drawRect(
    Rect.fromLTWH(0, 0, targetWidth.toDouble(), targetHeight.toDouble()),
    Paint()..color = background,
  );

  if (pixelRatio != 1.0) {
    canvas.scale(pixelRatio, pixelRatio);
  }

  paintItems(canvas, size, items);

  final picture = recorder.endRecording();
  final image = await picture.toImage(targetWidth, targetHeight);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  picture.dispose();
  image.dispose();

  if (byteData == null) {
    throw StateError('Failed to encode PNG');
  }

  return byteData.buffer.asUint8List();
}


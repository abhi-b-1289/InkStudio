import 'package:flutter/material.dart';

import 'canvas_item.dart';
import 'canvas_preset.dart';

class SavedDrawing {
  final int id;
  String name;
  final List<CanvasItem> items;
  final Size canvasSize;
  final CanvasPreset? preset;
  final DateTime updatedAt;
  SavedDrawing({
    required this.id,
    required this.name,
    required this.items,
    required this.canvasSize,
    this.preset,
    required this.updatedAt,
  });
}


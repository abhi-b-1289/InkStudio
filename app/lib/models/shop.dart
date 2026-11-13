import 'package:flutter/material.dart';

class ColorPack {
  final String id;
  final String name;
  final int cost;
  final List<Color> colors;
  const ColorPack({
    required this.id,
    required this.name,
    required this.cost,
    required this.colors,
  });
}

class CanvasTheme {
  final String id;
  final String name;
  final int cost;
  final IconData icon;
  final void Function(Canvas, Size) paint;
  const CanvasTheme({
    required this.id,
    required this.name,
    required this.cost,
    required this.icon,
    required this.paint,
  });
}


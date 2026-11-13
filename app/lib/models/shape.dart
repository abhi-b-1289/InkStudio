import 'dart:math' as math;

import 'package:flutter/material.dart';

enum ShapeType {
  line, arrow, rectangle, roundedRect, circle, ellipse, triangle, rightTriangle,
  diamond, pentagon, hexagon, star, heart, cross,
}

List<Offset> _regular(int n) => List.generate(n, (i) {
      final a = -math.pi / 2 + 2 * math.pi * i / n;
      return Offset(0.5 + 0.5 * math.cos(a), 0.5 + 0.5 * math.sin(a));
    });

List<Offset> _star() => List.generate(10, (i) {
      final a = -math.pi / 2 + math.pi * i / 5;
      final r = i.isEven ? 0.5 : 0.2;
      return Offset(0.5 + r * math.cos(a), 0.5 + r * math.sin(a));
    });

extension ShapeTypeX on ShapeType {
  String get label => switch (this) {
        ShapeType.line => 'Line', ShapeType.arrow => 'Arrow',
        ShapeType.rectangle => 'Rect', ShapeType.roundedRect => 'Rounded',
        ShapeType.circle => 'Circle', ShapeType.ellipse => 'Ellipse', ShapeType.triangle => 'Triangle',
        ShapeType.rightTriangle => 'Right tri', ShapeType.diamond => 'Diamond',
        ShapeType.pentagon => 'Pentagon', ShapeType.hexagon => 'Hexagon',
        ShapeType.star => 'Star', ShapeType.heart => 'Heart', ShapeType.cross => 'Cross',
      };

  IconData get icon => switch (this) {
        ShapeType.line => Icons.horizontal_rule, ShapeType.arrow => Icons.arrow_right_alt,
        ShapeType.rectangle => Icons.crop_square, ShapeType.roundedRect => Icons.rounded_corner,
        ShapeType.circle => Icons.circle_outlined, ShapeType.ellipse => Icons.egg_outlined, ShapeType.triangle => Icons.change_history,
        ShapeType.rightTriangle => Icons.square_foot, ShapeType.diamond => Icons.diamond_outlined,
        ShapeType.pentagon => Icons.pentagon_outlined, ShapeType.hexagon => Icons.hexagon_outlined,
        ShapeType.star => Icons.star_border, ShapeType.heart => Icons.favorite_border, ShapeType.cross => Icons.add,
      };

  bool get isClosed => this != ShapeType.line && this != ShapeType.arrow;
  Size get defaultSize => switch (this) {
        ShapeType.line => const Size(160, 24), ShapeType.arrow => const Size(160, 56),
        ShapeType.rectangle => const Size(140, 100), ShapeType.roundedRect => const Size(140, 100),
        ShapeType.circle => const Size(110, 110), ShapeType.ellipse => const Size(140, 100), ShapeType.triangle => const Size(120, 110),
        ShapeType.rightTriangle => const Size(110, 110), ShapeType.diamond => const Size(120, 120),
        ShapeType.pentagon => const Size(120, 115), ShapeType.hexagon => const Size(130, 115),
        ShapeType.star => const Size(130, 125), ShapeType.heart => const Size(120, 110), ShapeType.cross => const Size(110, 110),
      };

  List<List<Offset>> get polylines {
    switch (this) {
      case ShapeType.line: return const [[Offset(0, 0.5), Offset(1, 0.5)]];
      case ShapeType.arrow: return const [[Offset(0, 0.5), Offset(1, 0.5)], [Offset(0.72, 0.1), Offset(1, 0.5), Offset(0.72, 0.9)]];
      case ShapeType.triangle: return const [[Offset(0.5, 0), Offset(1, 1), Offset(0, 1)]];
      case ShapeType.rightTriangle: return const [[Offset(0, 0), Offset(0, 1), Offset(1, 1)]];
      case ShapeType.diamond: return const [[Offset(0.5, 0), Offset(1, 0.5), Offset(0.5, 1), Offset(0, 0.5)]];
      case ShapeType.pentagon: return [_regular(5)];
      case ShapeType.hexagon: return [_regular(6)];
      case ShapeType.star: return [_star()];
      case ShapeType.cross:
        const a = 1 / 3, b = 2 / 3;
        return const [[Offset(a, 0), Offset(b, 0), Offset(b, a), Offset(1, a), Offset(1, b), Offset(b, b), Offset(b, 1), Offset(a, 1), Offset(a, b), Offset(0, b), Offset(0, a), Offset(a, a)]];
      default: return const [];
    }
  }
}

class ShapeErase {
  final List<Offset> points;
  final double width;

  const ShapeErase({required this.points, required this.width});
}


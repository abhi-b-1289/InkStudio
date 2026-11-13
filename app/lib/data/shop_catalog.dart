import 'package:flutter/material.dart';

import '../models/shop.dart';

final List<ColorPack> allColorPacks = [
  const ColorPack(id: 'default', name: 'Default', cost: 0, colors: [
    Color(0xFF000000), Color(0xFF4B5563), Color(0xFFEF4444), Color(0xFFF97316),
    Color(0xFFEAB308), Color(0xFF22C55E), Color(0xFF06B6D4), Color(0xFF3B82F6),
    Color(0xFF8B5CF6), Color(0xFFEC4899),
  ]),
  const ColorPack(id: 'pastel', name: 'Pastel', cost: 200, colors: [
    Color(0xFFFFB3BA), Color(0xFFFFDFBA), Color(0xFFFFFFBA), Color(0xFFBAFFC9),
    Color(0xFFBAE1FF), Color(0xFFE0BBE4), Color(0xFFFEC8D8), Color(0xFFD4F0F0),
  ]),
  const ColorPack(id: 'neon', name: 'Neon', cost: 300, colors: [
    Color(0xFF39FF14), Color(0xFFFF073A), Color(0xFF0FF0FC), Color(0xFFFE53BB),
    Color(0xFFFFF700), Color(0xFFB026FF), Color(0xFF00FFF7), Color(0xFFFF9A00),
  ]),
];

final List<CanvasTheme> allThemes = [
  CanvasTheme(
      id: 'default',
      name: 'Blank',
      cost: 0,
      icon: Icons.crop_square,
      paint: (c, s) {}),
  CanvasTheme(
      id: 'grid',
      name: 'Grid',
      cost: 150,
      icon: Icons.grid_on,
      paint: (canvas, s) {
        final p = Paint()
          ..color = Colors.black.withValues(alpha: 0.08)
          ..strokeWidth = 1;
        for (double x = 0; x < s.width; x += 24) {
          canvas.drawLine(Offset(x, 0), Offset(x, s.height), p);
        }
        for (double y = 0; y < s.height; y += 24) {
          canvas.drawLine(Offset(0, y), Offset(s.width, y), p);
        }
      }),
  CanvasTheme(
      id: 'dots',
      name: 'Dots',
      cost: 150,
      icon: Icons.grain,
      paint: (canvas, s) {
        final p = Paint()..color = Colors.black.withValues(alpha: 0.12);
        for (double x = 12; x < s.width; x += 22) {
          for (double y = 12; y < s.height; y += 22) {
            canvas.drawCircle(Offset(x, y), 1.2, p);
          }
        }
      }),
  CanvasTheme(
      id: 'kraft',
      name: 'Kraft',
      cost: 300,
      icon: Icons.article_outlined,
      paint: (canvas, s) {
        canvas.drawRect(Offset.zero & s, Paint()..color = const Color(0xFFE8D5A8));
        final p = Paint()
          ..color = Colors.brown.withValues(alpha: 0.05)
          ..strokeWidth = 1;
        for (double y = 0; y < s.height; y += 4) {
          canvas.drawLine(Offset(0, y), Offset(s.width, y), p);
        }
      }),
];


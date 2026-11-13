import 'package:flutter/material.dart';

String hexColor(Color c) {
  final v = c.toARGB32() & 0xFFFFFF;
  return '#${v.toRadixString(16).padLeft(6, '0')}';
}

String hex6(Color c) =>
    (c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase();

String opacityAttr(String attr, Color c) {
  final a = (c.toARGB32() >> 24) & 0xFF;
  return a == 255 ? '' : ' $attr="${(a / 255).toStringAsFixed(3)}"';
}

String formatNum(double v) {
  final s = v.toStringAsFixed(2);
  return s.contains('.') ? s.replaceFirst(RegExp(r'\.?0+$'), '') : s;
}

bool sameColor(Color a, Color b) => a.toARGB32() == b.toARGB32();

String timeAgo(DateTime t) {
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 1) return 'Just now';
  if (d.inMinutes < 60) return '${d.inMinutes} min ago';
  if (d.inHours < 24) return '${d.inHours} h ago';
  return '${d.inDays} d ago';
}


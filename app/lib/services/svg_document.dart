import 'package:flutter/material.dart';

import '../core/formatters.dart';
import '../models/canvas_item.dart';

String buildSvgDocument(List<CanvasItem> items, Size size, {bool background = true}) {
  final w = formatNum(size.width), h = formatNum(size.height);
  final b = StringBuffer()
    ..writeln('<?xml version="1.0" encoding="UTF-8"?>')
    ..writeln('<svg xmlns="http://www.w3.org/2000/svg" width="$w" height="$h" viewBox="0 0 $w $h">');
  if (background) {
    b.writeln('  <rect width="100%" height="100%" fill="#ffffff"/>');
  }
  for (final it in items) {
    b.writeln('  ${it.toSvg()}');
  }
  b.writeln('</svg>');
  return b.toString();
}

String buildTransparentSvgDocument(List<CanvasItem> items, Size size) {
  final w = formatNum(size.width), h = formatNum(size.height);
  final b = StringBuffer()
    ..writeln('<?xml version="1.0" encoding="UTF-8"?>')
    ..writeln(
        '<svg xmlns="http://www.w3.org/2000/svg" width="$w" height="$h" viewBox="0 0 $w $h">');
  for (final it in items) {
    b.writeln('  ${it.toSvg()}');
  }
  b.writeln('</svg>');
  return b.toString();
}


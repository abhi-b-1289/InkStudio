import 'package:flutter/material.dart';

import '../core/formatters.dart';

final List<Color> recentColors = [];

void addRecentColor(Color c) {
  recentColors.removeWhere((e) => sameColor(e, c));
  recentColors.insert(0, c);
  if (recentColors.length > 10) recentColors.removeLast();
}


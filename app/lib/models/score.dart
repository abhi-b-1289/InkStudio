import 'package:flutter/material.dart';

import 'canvas_item.dart';
import 'quest.dart';

class ScoreResult {
  final double percent;
  final int stars;
  final int coinsEarned;
  final bool isPerfect;
  final bool isNewBest;
  final bool isDaily;
  final String label;
  const ScoreResult({
    required this.percent,
    required this.stars,
    required this.coinsEarned,
    required this.isPerfect,
    required this.isNewBest,
    required this.isDaily,
    required this.label,
  });
}

class GalleryEntry {
  final String challengeId;
  final String challengeName;
  final PlayTier tier;
  final double percent;
  final DateTime when;
  final List<CanvasItem> items;
  final Size size;
  const GalleryEntry({
    required this.challengeId,
    required this.challengeName,
    required this.tier,
    required this.percent,
    required this.when,
    required this.items,
    required this.size,
  });
}

String questScoreLabel(double p) => p >= 95
    ? 'Ink Master!'
    : (p >= 90
        ? 'Excellent!'
        : (p >= 80
            ? 'Great!'
            : (p >= 70 ? 'Getting there' : 'Keep practicing')));

Color questScoreColor(double p) => p >= 90
    ? const Color(0xFF16A34A)
    : (p >= 80 ? const Color(0xFFF59E0B) : const Color(0xFFDC2626));


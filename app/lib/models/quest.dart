import 'package:flutter/material.dart';

import 'canvas_item.dart';

enum PlayTier { trace, copy, memory }

extension PlayTierX on PlayTier {
  String get label => switch (this) {
        PlayTier.trace => 'Trace',
        PlayTier.copy => 'Copy',
        PlayTier.memory => 'Memory',
      };
  String get description => switch (this) {
        PlayTier.trace => 'Faint guide behind the canvas',
        PlayTier.copy => 'Reference shown beside the canvas',
        PlayTier.memory => 'Reference shown for 3 seconds, then hidden',
      };
  double get multiplier => switch (this) {
        PlayTier.trace => 0.5,
        PlayTier.copy => 1.0,
        PlayTier.memory => 1.5,
      };
  IconData get icon => switch (this) {
        PlayTier.trace => Icons.visibility_outlined,
        PlayTier.copy => Icons.content_copy_outlined,
        PlayTier.memory => Icons.psychology_outlined,
      };
}

class ChallengePack {
  final String id;
  final String name;
  final String description;
  final int cost;
  final IconData icon;
  final Color color;
  const ChallengePack({
    required this.id,
    required this.name,
    required this.description,
    required this.cost,
    required this.icon,
    required this.color,
  });
}

class QuestChallenge {
  final String id;
  final String name;
  final String packId;
  final int difficulty;
  final bool isBoss;
  final List<CanvasItem> Function(Size) buildReference;
  const QuestChallenge({
    required this.id,
    required this.name,
    required this.packId,
    required this.difficulty,
    required this.buildReference,
    this.isBoss = false,
  });
}


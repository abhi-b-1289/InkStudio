import 'package:flutter/material.dart';

enum PracticeTarget { circle, triangle, star, heart, smiley, wave }

extension PracticeTargetX on PracticeTarget {
  String get label => switch (this) {
        PracticeTarget.circle => 'Circle',
        PracticeTarget.triangle => 'Triangle',
        PracticeTarget.star => 'Star',
        PracticeTarget.heart => 'Heart',
        PracticeTarget.smiley => 'Smiley',
        PracticeTarget.wave => 'Wave',
      };

  IconData get icon => switch (this) {
        PracticeTarget.circle => Icons.circle_outlined,
        PracticeTarget.triangle => Icons.change_history,
        PracticeTarget.star => Icons.star_border,
        PracticeTarget.heart => Icons.favorite_border,
        PracticeTarget.smiley => Icons.sentiment_satisfied_alt,
        PracticeTarget.wave => Icons.waves_rounded,
      };

  String get tip => switch (this) {
        PracticeTarget.circle => 'Trace the faint circle — keep the stroke smooth.',
        PracticeTarget.triangle => 'Three straight sides meeting at sharp corners.',
        PracticeTarget.star => 'Aim for five even points with clean angles.',
        PracticeTarget.heart => 'Two soft bumps on top, pointed at the bottom.',
        PracticeTarget.smiley => 'A round face with two eyes and a curved smile.',
        PracticeTarget.wave => 'One flowing line — keep it loose and even.',
      };
}


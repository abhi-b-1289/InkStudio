import 'package:flutter/material.dart';

import '../models/quest.dart';
import 'quest_references.dart';

final List<ChallengePack> allPacks = [
  const ChallengePack(
      id: 'starter',
      name: 'Starter',
      description: 'Six simple warm-ups',
      cost: 0,
      icon: Icons.play_circle_outline,
      color: Color(0xFF5B5BD6)),
  const ChallengePack(
      id: 'basics',
      name: 'Basics',
      description: 'Square, diamond, house, sun…',
      cost: 300,
      icon: Icons.category_outlined,
      color: Color(0xFF06B6D4)),
  const ChallengePack(
      id: 'nature',
      name: 'Nature',
      description: 'Tree, flower, sparkle, crown',
      cost: 500,
      icon: Icons.eco_outlined,
      color: Color(0xFF22C55E)),
  const ChallengePack(
      id: 'objects',
      name: 'Objects',
      description: 'Rocket, boat, key, lightbulb',
      cost: 700,
      icon: Icons.widgets_outlined,
      color: Color(0xFFF59E0B)),
];

final List<QuestChallenge> allChallenges = [

  QuestChallenge(
      id: 'circle',
      name: 'Circle',
      packId: 'starter',
      difficulty: 1,
      buildReference: circleReference),
  QuestChallenge(
      id: 'triangle',
      name: 'Triangle',
      packId: 'starter',
      difficulty: 1,
      buildReference: triangleReference),
  QuestChallenge(
      id: 'wave',
      name: 'Wave',
      packId: 'starter',
      difficulty: 1,
      buildReference: waveReference),
  QuestChallenge(
      id: 'star',
      name: 'Star',
      packId: 'starter',
      difficulty: 2,
      buildReference: starReference),
  QuestChallenge(
      id: 'heart',
      name: 'Heart',
      packId: 'starter',
      difficulty: 2,
      buildReference: heartReference),
  QuestChallenge(
      id: 'smiley',
      name: 'Smiley',
      packId: 'starter',
      difficulty: 2,
      buildReference: smileyReference),

  QuestChallenge(
      id: 'square',
      name: 'Square',
      packId: 'basics',
      difficulty: 1,
      buildReference: squareReference),
  QuestChallenge(
      id: 'diamond',
      name: 'Diamond',
      packId: 'basics',
      difficulty: 2,
      buildReference: diamondReference),
  QuestChallenge(
      id: 'arrow',
      name: 'Arrow',
      packId: 'basics',
      difficulty: 2,
      buildReference: arrowReference),
  QuestChallenge(
      id: 'house',
      name: 'House',
      packId: 'basics',
      difficulty: 3,
      buildReference: houseReference),
  QuestChallenge(
      id: 'sun',
      name: 'Sun',
      packId: 'basics',
      difficulty: 3,
      buildReference: sunReference),

  QuestChallenge(
      id: 'tree',
      name: 'Tree',
      packId: 'nature',
      difficulty: 2,
      buildReference: treeReference),
  QuestChallenge(
      id: 'flower',
      name: 'Flower',
      packId: 'nature',
      difficulty: 3,
      buildReference: flowerReference),
  QuestChallenge(
      id: 'sparkle',
      name: 'Sparkle',
      packId: 'nature',
      difficulty: 2,
      buildReference: sparkleReference),
  QuestChallenge(
      id: 'crown',
      name: 'Crown',
      packId: 'nature',
      difficulty: 3,
      buildReference: crownReference),

  QuestChallenge(
      id: 'rocket',
      name: 'Rocket',
      packId: 'objects',
      difficulty: 4,
      isBoss: true,
      buildReference: rocketReference),
  QuestChallenge(
      id: 'boat',
      name: 'Boat',
      packId: 'objects',
      difficulty: 3,
      buildReference: boatReference),
  QuestChallenge(
      id: 'key',
      name: 'Key',
      packId: 'objects',
      difficulty: 3,
      buildReference: keyReference),
  QuestChallenge(
      id: 'lightbulb',
      name: 'Lightbulb',
      packId: 'objects',
      difficulty: 3,
      buildReference: lightbulbReference),
];


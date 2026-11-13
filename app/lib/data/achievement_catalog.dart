import '../models/achievement.dart';

const allAchievements = <Achievement>[
  Achievement(
      id: 'first_perfect',
      name: 'First Perfect',
      description: 'Score 99% on any challenge',
      reward: 200),
  Achievement(
      id: 'ten_s',
      name: 'Ten S-Tiers',
      description: 'Earn 10 three-star results',
      reward: 300),
  Achievement(
      id: 'ten_challenges',
      name: 'Renaissance Ink',
      description: 'Play 10 different challenges',
      reward: 500),
  Achievement(
      id: 'week_streak',
      name: 'Week Warrior',
      description: 'Draw 7 days in a row',
      reward: 500),
  Achievement(
      id: 'thirty_stars',
      name: 'Star Collector',
      description: 'Collect 30 stars in total',
      reward: 600),
];


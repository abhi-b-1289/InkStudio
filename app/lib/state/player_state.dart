import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/quest_catalog.dart';
import '../data/shop_catalog.dart';
import '../models/quest.dart';
import '../models/score.dart';

class PlayerState extends ChangeNotifier {
  int _coins = 100;
  int _xp = 0;
  int _streakDays = 0;
  DateTime? _lastPlayed;
  int? _lastDailyDayIndex;

  final Map<String, Map<String, int>> _stars = {};
  final Set<String> _ownedPacks = {'starter'};
  final Set<String> _ownedColorPacks = {'default'};
  final Set<String> _ownedThemes = {'default'};
  final Set<String> _achievements = {};
  final Set<String> _perfects = {};
  final Set<String> _challengesPlayed = {};
  final List<GalleryEntry> _gallery = [];

  int get coins => _coins;
  int get xp => _xp;
  int get level => 1 + _xp ~/ 10;
  int get streakDays => _streakDays;
  List<GalleryEntry> get gallery => List.unmodifiable(_gallery);
  Set<String> get achievements => Set.unmodifiable(_achievements);

  int starsFor(String challengeId, PlayTier tier) =>
      _stars[challengeId]?[tier.name] ?? 0;

  int get totalStars {
    var t = 0;
    for (final m in _stars.values) {
      for (final v in m.values) t += v;
    }
    return t;
  }

  int get totalS {
    var n = 0;
    for (final m in _stars.values) {
      for (final v in m.values) {
        if (v == 3) n++;
      }
    }
    return n;
  }

  bool ownsPack(String id) => _ownedPacks.contains(id);
  bool ownsColorPack(String id) => _ownedColorPacks.contains(id);
  bool ownsTheme(String id) => _ownedThemes.contains(id);

  List<Color> get unlockedColors {
    final out = <Color>[];
    for (final p in allColorPacks) {
      if (_ownedColorPacks.contains(p.id)) out.addAll(p.colors);
    }
    return out;
  }

  double get streakMult {
    if (_streakDays <= 1) return 1.0;
    return 1.0 + 0.05 * math.min(_streakDays - 1, 20);
  }

  void _touchStreak() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (_lastPlayed == null) {
      _streakDays = 1;
    } else {
      final last = DateTime(
          _lastPlayed!.year, _lastPlayed!.month, _lastPlayed!.day);
      final diff = today.difference(last).inDays;
      if (diff == 1) {
        _streakDays++;
      } else if (diff > 1) {
        _streakDays = 1;
      }
    }
    _lastPlayed = now;
  }

  int _starsToCoins(int stars) => stars == 3 ? 100 : (stars == 2 ? 50 : 0);

  ScoreResult awardScore(
      QuestChallenge challenge, PlayTier tier, double percent) {
    final isPerfect = percent >= 99;
    final stars = percent >= 90 ? 3 : (percent >= 80 ? 2 : (percent >= 70 ? 1 : 0));
    final oldStars = starsFor(challenge.id, tier);
    final isNewBest = stars > oldStars;
    final isDaily =
        dailyAvailable && challenge.id == dailyChallenge.id;

    _touchStreak();
    _challengesPlayed.add(challenge.id);

    var earned = 0;
    final baseDelta = _starsToCoins(stars) - _starsToCoins(oldStars);
    if (baseDelta > 0) {
      var v = baseDelta * tier.multiplier * streakMult;
      if (challenge.isBoss) v *= 3;
      if (isDaily) v *= 2;
      earned += v.round();
    }

    final perfectKey = '${challenge.id}:${tier.name}';
    if (isPerfect && _perfects.add(perfectKey)) {
      var v = 50 * tier.multiplier;
      if (challenge.isBoss) v *= 3;
      if (isDaily) v *= 2;
      earned += v.round();
    }

    if (isNewBest) {
      _xp += stars - oldStars;
      _stars.putIfAbsent(challenge.id, () => {})[tier.name] = stars;
    }

    _coins += earned;

    if (isDaily) _lastDailyDayIndex = _dayIndex();

    if (isPerfect) _unlockAchievement('first_perfect', 200);
    if (totalS >= 10) _unlockAchievement('ten_s', 300);
    if (_challengesPlayed.length >= 10) {
      _unlockAchievement('ten_challenges', 500);
    }
    if (_streakDays >= 7) _unlockAchievement('week_streak', 500);
    if (totalStars >= 30) _unlockAchievement('thirty_stars', 600);

    notifyListeners();

    return ScoreResult(
      percent: percent,
      stars: stars,
      coinsEarned: earned,
      isPerfect: isPerfect,
      isNewBest: isNewBest,
      isDaily: isDaily,
      label: questScoreLabel(percent),
    );
  }

  void addToGallery(GalleryEntry entry) {
    _gallery.insert(0, entry);
    if (_gallery.length > 100) _gallery.removeLast();
    notifyListeners();
  }

  void _unlockAchievement(String id, int reward) {
    if (_achievements.add(id)) _coins += reward;
  }

  bool buyPack(String id, int cost) {
    if (_coins < cost || _ownedPacks.contains(id)) return false;
    _coins -= cost;
    _ownedPacks.add(id);
    notifyListeners();
    return true;
  }

  bool buyColorPack(String id, int cost) {
    if (_coins < cost || _ownedColorPacks.contains(id)) return false;
    _coins -= cost;
    _ownedColorPacks.add(id);
    notifyListeners();
    return true;
  }

  bool buyTheme(String id, int cost) {
    if (_coins < cost || _ownedThemes.contains(id)) return false;
    _coins -= cost;
    _ownedThemes.add(id);
    notifyListeners();
    return true;
  }

  int _dayIndex() =>
      DateTime.now().difference(DateTime(2024, 1, 1)).inDays;

  bool get dailyAvailable => _lastDailyDayIndex != _dayIndex();

  QuestChallenge get dailyChallenge =>
      allChallenges[_dayIndex() % allChallenges.length];
}

final PlayerState playerState = PlayerState();


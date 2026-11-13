import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../controllers/canvas_controller.dart';
import '../../core/app_constants.dart';
import '../../data/achievement_catalog.dart';
import '../../models/achievement.dart';
import '../../models/quest.dart';
import '../../models/score.dart';
import '../../painters/quest_painters.dart';
import '../../state/player_state.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: playerState,
      builder: (context, _) {
        final level = playerState.level;
        final xp = playerState.xp;
        final xpInLevel = xp % 10;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [

            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF5B5BD6),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text('$level',
                            style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: Colors.white)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Sketch artist',
                              style: TextStyle(
                                  fontSize: 11,
                                  letterSpacing: 1.2,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white)),
                          const SizedBox(height: 2),
                          Text('Level $level',
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white)),
                          const SizedBox(height: 4),
                          Text('$xpInLevel / 10 XP to next level',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white
                                      .withValues(alpha: 0.85))),
                        ],
                      ),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: xpInLevel / 10,
                      minHeight: 6,
                      backgroundColor: Colors.white.withValues(alpha: 0.3),
                      valueColor: const AlwaysStoppedAnimation(Colors.white),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(spacing: 16, runSpacing: 8, children: [
                    _Stat(label: 'Stars', value: '${playerState.totalStars}'),
                    _Stat(label: 'S-Tier', value: '${playerState.totalS}'),
                    _Stat(
                        label: 'Streak',
                        value: '${playerState.streakDays}d'),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 18),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(4, 0, 4, 10),
                    child: Text('Achievements',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w800)),
                  ),
                  for (final a in allAchievements)
                    _AchRow(
                        achievement: a,
                        unlocked:
                            playerState.achievements.contains(a.id)),
                ],
              ),
            ),
            const SizedBox(height: 18),

            const Padding(
              padding: EdgeInsets.fromLTRB(4, 0, 4, 8),
              child: Text('Gallery',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w800)),
            ),
            if (playerState.gallery.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(children: [
                  Icon(Icons.photo_library_outlined,
                      size: 40, color: cs.primary.withValues(alpha: 0.35)),
                  const SizedBox(height: 8),
                  Text('Earn 3-star results to fill your gallery',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 12, color: cs.onSurfaceVariant)),
                ]),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 180,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.85,
                ),
                itemCount: playerState.gallery.length,
                itemBuilder: (_, i) =>
                    _GalleryTile(entry: playerState.gallery[i]),
              ),
          ],
        );
      },
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 10,
                color: Colors.white.withValues(alpha: 0.8),
                fontWeight: FontWeight.w600)),
        Text(value,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Colors.white)),
      ],
    );
  }
}

class _AchRow extends StatelessWidget {
  final Achievement achievement;
  final bool unlocked;
  const _AchRow({required this.achievement, required this.unlocked});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: unlocked
                ? const Color(0xFFFFF3C4)
                : cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
              unlocked
                  ? Icons.emoji_events_rounded
                  : Icons.lock_outline_rounded,
              size: 18,
              color: unlocked ? kGold : cs.onSurfaceVariant),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(achievement.name,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: unlocked ? null : cs.onSurfaceVariant)),
              Text(achievement.description,
                  style: TextStyle(
                      fontSize: 11, color: cs.onSurfaceVariant)),
            ],
          ),
        ),
        Text('+${achievement.reward}',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: unlocked
                    ? const Color(0xFF16A34A)
                    : cs.onSurfaceVariant)),
      ]),
    );
  }
}

class _GalleryTile extends StatelessWidget {
  final GalleryEntry entry;
  const _GalleryTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      padding: const EdgeInsets.all(8),
      child: Column(children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              color: Colors.white,
              foregroundDecoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.black12),
              ),
              child: CustomPaint(
                painter: _GalleryPainter(entry),
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(entry.challengeName,
            maxLines: 1,
            style: const TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700),
            overflow: TextOverflow.ellipsis),
        Text('${entry.percent.round()}% · ${entry.tier.label}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, color: Colors.black54)),
      ]),
    );
  }
}

class _GalleryPainter extends CustomPainter {
  final GalleryEntry entry;
  _GalleryPainter(this.entry);
  @override
  void paint(Canvas canvas, Size size) {
    if (entry.size.width <= 0) return;
    final scale = math.min(
        size.width / entry.size.width, size.height / entry.size.height);
    final dx = (size.width - entry.size.width * scale) / 2;
    final dy = (size.height - entry.size.height * scale) / 2;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.translate(dx, dy);
    canvas.scale(scale);
    final tmp = CanvasController()..canvasSize = entry.size;
    tmp.loadItems(entry.items);
    QuestCanvasPainter(tmp).paint(canvas, entry.size);
    tmp.dispose();
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _GalleryPainter old) =>
      old.entry != entry;
}


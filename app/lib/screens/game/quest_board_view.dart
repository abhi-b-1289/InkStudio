import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/quest_catalog.dart';
import '../../models/quest.dart';
import '../../state/player_state.dart';
import '../../widgets/game/game_common.dart';
import 'quest_play_page.dart';

class QuestBoardView extends StatelessWidget {
  const QuestBoardView({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: playerState,
      builder: (context, _) {
        final daily = playerState.dailyChallenge;
        final dailyAvailable = playerState.dailyAvailable;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [

            Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => _openTierPicker(context, daily, isDaily: true),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5B5BD6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.calendar_today_rounded,
                          color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('DAILY CHALLENGE',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.6,
                                  color: Colors.white)),
                          const SizedBox(height: 2),
                          Text(daily.name,
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                          Text(
                            dailyAvailable
                                ? 'Win 2× coins — beat your best'
                                : 'Come back tomorrow for 2×',
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withValues(alpha: 0.85)),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded,
                        color: Colors.white),
                  ]),
                ),
              ),
            ),
            const SizedBox(height: 18),
            for (final pack in allPacks) ...[
              _packSection(context, pack),
              const SizedBox(height: 16),
            ],
          ],
        );
      },
    );
  }

  Widget _packSection(BuildContext context, ChallengePack pack) {
    final owned = playerState.ownsPack(pack.id);
    final challenges =
        allChallenges.where((c) => c.packId == pack.id).toList();
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 14,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: pack.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(pack.icon, size: 18, color: pack.color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(pack.name,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w800)),
                  Text(pack.description,
                      style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurfaceVariant)),
                ],
              ),
            ),
            if (!owned)
              FilledButton.tonalIcon(
                style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    minimumSize: const Size(0, 36)),
                onPressed: () => _confirmBuyPack(context, pack),
                icon: const Icon(Icons.lock_open_rounded, size: 14),
                label: Text('${pack.cost}'),
              ),
          ]),
          const SizedBox(height: 12),
          if (owned)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate:
                  const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 130,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.8,
              ),
              itemCount: challenges.length,
              itemBuilder: (_, i) => _ChallengeCard(
                challenge: challenges[i],
                onTap: () => _openTierPicker(context, challenges[i]),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(vertical: 22),
              width: double.infinity,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text('Locked — buy this pack to play',
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmBuyPack(
      BuildContext context, ChallengePack pack) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Unlock ${pack.name}?'),
        content: Text(
            'Spend ${pack.cost} coins to unlock ${pack.description.toLowerCase()}.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Buy (${pack.cost})')),
        ],
      ),
    );
    if (ok == true) {
      final success = playerState.buyPack(pack.id, pack.cost);
      if (!success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Not enough coins')));
      }
    }
  }

  Future<void> _openTierPicker(BuildContext context,
      QuestChallenge challenge, {bool isDaily = false}) async {
    final tier = await showModalBottomSheet<PlayTier>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: [
                Expanded(
                  child: Text(challenge.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w800)),
                ),
                if (challenge.isBoss) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('BOSS · 3× coins',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFEF4444))),
                  ),
                ],
              ]),
              if (isDaily)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text('Daily challenge active — 2× coins',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(ctx).colorScheme.primary)),
                ),
              const SizedBox(height: 16),
              for (final t in PlayTier.values)
                _TierTile(
                  tier: t,
                  stars: playerState.starsFor(challenge.id, t),
                  onTap: () => Navigator.pop(ctx, t),
                ),
            ],
          ),
        ),
      ),
    );
    if (tier != null && context.mounted) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => QuestPlayPage(
          challenge: challenge,
          tier: tier,
          isDaily: isDaily,
        ),
      ));
    }
  }
}

class _TierTile extends StatelessWidget {
  final PlayTier tier;
  final int stars;
  final VoidCallback onTap;
  const _TierTile(
      {required this.tier, required this.stars, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(tier.icon, size: 20, color: cs.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(children: [
                      Text(tier.label,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('${tier.multiplier}×',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: cs.primary)),
                      ),
                    ]),
                    const SizedBox(height: 2),
                    Text(tier.description,
                        style: TextStyle(
                            fontSize: 11,
                            color: cs.onSurfaceVariant)),
                  ],
                ),
              ),
              StarsRow(count: stars, size: 16),
            ]),
          ),
        ),
      ),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  final QuestChallenge challenge;
  final VoidCallback onTap;
  const _ChallengeCard({required this.challenge, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final best = [
      playerState.starsFor(challenge.id, PlayTier.trace),
      playerState.starsFor(challenge.id, PlayTier.copy),
      playerState.starsFor(challenge.id, PlayTier.memory),
    ].reduce(math.max);

    return Material(
      color: cs.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Center(
                  child: ChallengePreview(challenge: challenge, size: 60),
                ),
              ),
              const SizedBox(height: 6),
              Text(challenge.name,
                  maxLines: 1,
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              StarsRow(count: best, size: 11),
            ],
          ),
        ),
      ),
    );
  }
}


import 'package:flutter/material.dart';

import '../../core/app_constants.dart';
import '../../models/quest.dart';
import '../../painters/quest_painters.dart';
import '../../state/player_state.dart';

class CoinPill extends StatelessWidget {
  const CoinPill({super.key});
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: playerState,
      builder: (context, _) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: kGoldBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFFD54F)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.monetization_on, size: 18, color: kGold),
          const SizedBox(width: 4),
          Text('${playerState.coins}',
              style: const TextStyle(
                  fontWeight: FontWeight.w800, color: Color(0xFF8B6914))),
        ]),
      ),
    );
  }
}

class StarsRow extends StatelessWidget {
  final int count;
  final double size;
  const StarsRow({super.key, required this.count, this.size = 14});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
          3,
          (i) => Icon(
                i < count ? Icons.star_rounded : Icons.star_outline_rounded,
                size: size,
                color: i < count ? kGold : Colors.black26,
              )),
    );
  }
}

class ChallengePreview extends StatelessWidget {
  final QuestChallenge challenge;
  final double size;
  const ChallengePreview({super.key, required this.challenge, this.size = 90});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: GuidePainter(
          challenge.buildReference(Size(size, size)),
          kGuideInk,
          opacity: 0.75,
        ),
      ),
    );
  }
}


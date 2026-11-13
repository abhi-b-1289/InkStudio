import 'package:flutter/material.dart';

import '../../state/player_state.dart';

class InkQuestHomeEntry extends StatelessWidget {
  final VoidCallback onOpen;
  const InkQuestHomeEntry({super.key, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: playerState,
      builder: (context, _) {
        return Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: onOpen,
            child: Container(
              margin: const EdgeInsets.fromLTRB(0, 0, 0, 14),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF5B5BD6),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF5B5BD6).withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 200;
                  return Row(children: [
                    Container(
                      width: compact ? 40 : 54,
                      height: compact ? 40 : 54,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(Icons.emoji_events_rounded,
                          size: compact ? 22 : 30, color: Colors.white),
                    ),
                    SizedBox(width: compact ? 10 : 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('InkQuest',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white)),
                          if (!compact) ...[
                            const SizedBox(height: 2),
                            Text(
                              'Beat challenges, earn coins, unlock packs',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.85)),
                            ),
                            const SizedBox(height: 8),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                const Icon(Icons.monetization_on,
                                    size: 14, color: Color(0xFFFFD54F)),
                                const SizedBox(width: 4),
                                Text('${playerState.coins}',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFFFFD54F))),
                                const SizedBox(width: 12),
                                const Icon(Icons.star_rounded,
                                    size: 14, color: Color(0xFFFFD54F)),
                                const SizedBox(width: 4),
                                Text('${playerState.totalStars}',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFFFFD54F))),
                              ]),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (!compact)
                      const Icon(Icons.chevron_right_rounded, color: Colors.white),
                  ]);
                },
              ),
            ),
          ),
        );
      },
    );
  }
}


import 'package:flutter/material.dart';

import '../../core/app_constants.dart';
import '../../data/quest_catalog.dart';
import '../../data/shop_catalog.dart';
import '../../models/quest.dart';
import '../../models/shop.dart';
import '../../painters/quest_painters.dart';
import '../../state/player_state.dart';

class ShopView extends StatelessWidget {
  const ShopView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: playerState,
      builder: (context, _) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            const _SectionHeader(title: 'Challenge packs'),
            const SizedBox(height: 8),
            for (final pack in allPacks.skip(1)) ...[
              _PackShopTile(pack: pack),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 14),
            const _SectionHeader(title: 'Color packs'),
            const SizedBox(height: 8),
            for (final cp in allColorPacks.skip(1)) ...[
              _ColorShopTile(pack: cp),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 14),
            const _SectionHeader(title: 'Canvas themes'),
            const SizedBox(height: 8),
            for (final th in allThemes.skip(1)) ...[
              _ThemeShopTile(theme: th),
              const SizedBox(height: 10),
            ],
          ],
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
      child: Text(title,
          style: const TextStyle(
              fontSize: 17, fontWeight: FontWeight.w800)),
    );
  }
}

class _PackShopTile extends StatelessWidget {
  final ChallengePack pack;
  const _PackShopTile({required this.pack});

  @override
  Widget build(BuildContext context) {
    final owned = playerState.ownsPack(pack.id);
    final cs = Theme.of(context).colorScheme;
    return _ShopRow(
      leading: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: pack.color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(pack.icon, color: pack.color, size: 24),
      ),
      title: pack.name,
      subtitle: pack.description,
      trailing: owned
          ? const Icon(Icons.check_circle, color: Color(0xFF16A34A))
          : _BuyButton(
              cost: pack.cost,
              onBuy: () {
                final ok = playerState.buyPack(pack.id, pack.cost);
                _feedback(context, ok);
              },
            ),
      cs: cs,
    );
  }
}

class _ColorShopTile extends StatelessWidget {
  final ColorPack pack;
  const _ColorShopTile({required this.pack});

  @override
  Widget build(BuildContext context) {
    final owned = playerState.ownsColorPack(pack.id);
    final cs = Theme.of(context).colorScheme;
    return _ShopRow(
      leading: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: SweepGradient(colors: [...pack.colors, pack.colors.first]),
        ),
      ),
      title: pack.name,
      subtitle: '${pack.colors.length} colors',
      trailing: owned
          ? const Icon(Icons.check_circle, color: Color(0xFF16A34A))
          : _BuyButton(
              cost: pack.cost,
              onBuy: () {
                final ok = playerState.buyColorPack(pack.id, pack.cost);
                _feedback(context, ok);
              },
            ),
      cs: cs,
    );
  }
}

class _ThemeShopTile extends StatelessWidget {
  final CanvasTheme theme;
  const _ThemeShopTile({required this.theme});

  @override
  Widget build(BuildContext context) {
    final owned = playerState.ownsTheme(theme.id);
    final cs = Theme.of(context).colorScheme;
    return _ShopRow(
      leading: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black12),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CustomPaint(painter: ThemePainter(theme)),
        ),
      ),
      title: theme.name,
      subtitle: 'Canvas background',
      trailing: owned
          ? const Icon(Icons.check_circle, color: Color(0xFF16A34A))
          : _BuyButton(
              cost: theme.cost,
              onBuy: () {
                final ok = playerState.buyTheme(theme.id, theme.cost);
                _feedback(context, ok);
              },
            ),
      cs: cs,
    );
  }
}

void _feedback(BuildContext context, bool ok) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(ok ? 'Unlocked!' : 'Not enough coins'),
      duration: const Duration(milliseconds: 1200),
    ));
}

class _ShopRow extends StatelessWidget {
  final Widget leading;
  final String title;
  final String subtitle;
  final Widget trailing;
  final ColorScheme cs;
  const _ShopRow({
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Row(children: [
        leading,
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w800)),
              Text(subtitle,
                  style: TextStyle(
                      fontSize: 11, color: cs.onSurfaceVariant)),
            ],
          ),
        ),
        trailing,
      ]),
    );
  }
}

class _BuyButton extends StatelessWidget {
  final int cost;
  final VoidCallback onBuy;
  const _BuyButton({required this.cost, required this.onBuy});

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonal(
      onPressed: onBuy,
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: const Size(0, 38),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.monetization_on, size: 16, color: kGold),
        const SizedBox(width: 4),
        Text('$cost',
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w800)),
      ]),
    );
  }
}


import 'package:flutter/material.dart';

import '../../state/player_state.dart';
import '../../widgets/game/game_common.dart';
import 'profile_view.dart';
import 'quest_board_view.dart';
import 'shop_view.dart';

void openInkQuest(BuildContext context) {
  Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => const GameHomePage()));
}

class GameHomePage extends StatefulWidget {
  const GameHomePage({super.key});
  @override
  State<GameHomePage> createState() => _GameHomePageState();
}

class _GameHomePageState extends State<GameHomePage> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: playerState,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              _tab == 0
                  ? 'InkQuest'
                  : (_tab == 1 ? 'InkShop' : 'Profile'),
            ),
            actions: const [CoinPill(), SizedBox(width: 12)],
          ),
          body: SafeArea(
            child: IndexedStack(
              index: _tab,
              children: const [
                QuestBoardView(),
                ShopView(),
                ProfileView(),
              ],
            ),
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _tab,
            onDestinationSelected: (i) => setState(() => _tab = i),
            destinations: const [
              NavigationDestination(
                  icon: Icon(Icons.flag_outlined),
                  selectedIcon: Icon(Icons.flag_rounded),
                  label: 'Quests'),
              NavigationDestination(
                  icon: Icon(Icons.storefront_outlined),
                  selectedIcon: Icon(Icons.storefront_rounded),
                  label: 'Shop'),
              NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person_rounded),
                  label: 'Profile'),
            ],
          ),
        );
      },
    );
  }
}


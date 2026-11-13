import 'package:flutter/material.dart';

import '../models/canvas_preset.dart';
import '../models/saved_drawing.dart';
import '../state/drawing_store.dart';
import '../widgets/canvas/canvas_size_picker.dart';
import '../widgets/game/inkquest_home_entry.dart';
import '../widgets/home/quick_action_card.dart';
import '../widgets/home/recent_card.dart';
import 'canvas_page.dart';
import 'game/game_home_page.dart';
import 'learn_drawing_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Future<void> _openCanvas([SavedDrawing? drawing, CanvasPreset? preset]) async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => CanvasPage(drawing: drawing, preset: preset),
    ));
    if (mounted) setState(() {});
  }

  Future<void> _newCanvas() async {
    final preset = await showCanvasSizePicker(context);
    if (preset != null && mounted) {
      _openCanvas(null, preset);
    }
  }

  Future<void> _deleteDrawing(SavedDrawing d) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete drawing?'),
        content: const Text('This drawing will be removed from your recent list.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true && mounted) setState(() => savedDrawings.removeWhere((e) => e.id == d.id));
  }

  Future<void> _renameDrawing(SavedDrawing d) async {
    final tc = TextEditingController(text: d.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) {
        String? error;
        bool _isDuplicate(String v) =>
            savedDrawings.any((e) => e.id != d.id && e.name.trim().toLowerCase() == v.toLowerCase());
        return StatefulBuilder(
          builder: (ctx, setS) => AlertDialog(
            title: const Text('Rename drawing'),
            content: TextField(
              controller: tc,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Enter a name',
                errorText: error,
              ),
              onChanged: (v) {
                final t = v.trim();
                setS(() => error = t.isEmpty
                    ? null
                    : _isDuplicate(t)
                        ? 'A drawing with this name already exists'
                        : null);
              },
              onSubmitted: (v) {
                final t = v.trim();
                if (t.isNotEmpty && !_isDuplicate(t)) Navigator.pop(ctx, t);
              },
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              FilledButton(
                onPressed: () {
                  final t = tc.text.trim();
                  if (t.isEmpty || _isDuplicate(t)) return;
                  Navigator.pop(ctx, t);
                },
                child: const Text('Rename'),
              ),
            ],
          ),
        );
      },
    );
    tc.dispose();
    if (newName != null && mounted) setState(() => d.name = newName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('InkStudio')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [

            const Padding(
              padding: EdgeInsets.fromLTRB(4, 4, 4, 14),
              child: Text('What would you like to do?',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1B1B2F))),
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                final cards = <Widget>[
                  QuickActionCard(
                    icon: Icons.brush_rounded,
                    title: 'Draw Now',
                    subtitle: 'Pick size & draw',
                    color: const Color(0xFF5B5BD6),
                    onTap: () => _newCanvas(),
                  ),
                  QuickActionCard(
                    icon: Icons.school_rounded,
                    title: 'Learn Drawing',
                    subtitle: 'Test your skill',
                    color: const Color(0xFFF59E0B),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const LearnDrawingPage()),
                    ),
                  ),
                ];
                if (constraints.maxWidth < 320) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      cards[0],
                      const SizedBox(height: 12),
                      cards[1],
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: cards[0]),
                    const SizedBox(width: 14),
                    Expanded(child: cards[1]),
                  ],
                );
              },
            ),
            const SizedBox(height: 18),

            InkQuestHomeEntry(onOpen: () => openInkQuest(context)),

            const SizedBox(height: 22),
            const Padding(
              padding: EdgeInsets.fromLTRB(4, 0, 4, 10),
              child: Text('Recent Drawings',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1B1B2F))),
            ),
            if (savedDrawings.isEmpty)
              EmptyRecent(onDrawNow: () => _newCanvas())
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final spacing = width >= 620 ? 16.0 : 12.0;
                  final SliverGridDelegate delegate;
                  if (width < 240) {
                    delegate = SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 1,
                      crossAxisSpacing: spacing,
                      mainAxisSpacing: spacing,
                      childAspectRatio: 1.1,
                    );
                  } else if (width < 460) {
                    delegate = SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: spacing,
                      mainAxisSpacing: spacing,
                      childAspectRatio: 0.84,
                    );
                  } else {
                    delegate = SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 165,
                      crossAxisSpacing: spacing,
                      mainAxisSpacing: spacing,
                      childAspectRatio: 0.84,
                    );
                  }
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: delegate,
                    itemCount: savedDrawings.length,
                    itemBuilder: (_, i) {
                      final d = savedDrawings[i];
                      return RecentCard(
                        drawing: d,
                        onTap: () => _openCanvas(d),
                        onDelete: () => _deleteDrawing(d),
                        onRename: () => _renameDrawing(d),
                      );
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}


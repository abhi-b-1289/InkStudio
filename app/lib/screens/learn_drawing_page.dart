import 'package:flutter/material.dart';

import '../controllers/canvas_controller.dart';
import '../models/practice_target.dart';
import '../painters/practice_painters.dart';
import '../services/practice_reference.dart';
import '../services/svg_document.dart';
import '../services/svg_similarity.dart';

Color _scoreColor(double p) => p >= 70
    ? const Color(0xFF16A34A)
    : (p >= 50 ? const Color(0xFFF59E0B) : const Color(0xFFDC2626));

String _scoreLabel(double p) => p >= 85
    ? 'Excellent!'
    : p >= 70
        ? 'Great job!'
        : p >= 50
            ? 'Getting there'
            : 'Keep practicing';

class LearnDrawingPage extends StatefulWidget {
  const LearnDrawingPage({super.key});
  @override
  State<LearnDrawingPage> createState() => _LearnDrawingPageState();
}

class _LearnDrawingPageState extends State<LearnDrawingPage> {
  final controller = CanvasController();
  PracticeTarget _target = PracticeTarget.circle;
  SimilarityResult? _result;
  Size _boardSize = Size.zero;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _pickTarget(PracticeTarget t) {
    if (t == _target) return;
    controller.resetAll();
    setState(() {
      _target = t;
      _result = null;
    });
  }

  void _check() {
    if (controller.items.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Draw along the faint guide first.')));
      return;
    }
    if (_boardSize.width < 20 || _boardSize.height < 20) return;
    final reference = buildSvgDocument(buildPracticeGuide(_target, _boardSize), _boardSize, background: false);
    final user = buildSvgDocument(controller.items, _boardSize, background: false);
    final result = SvgSimilarity.compare(
      reference,
      user,
      tolerance: 0.035,
      normalizeToBounds: true,
      samples: 1200,
    );
    setState(() => _result = result);
  }

  void _clearSketch() {
    controller.resetAll();
    setState(() => _result = null);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Learn Drawing')),
          body: SafeArea(
            child: Column(
              children: [
                SizedBox(
                  height: 54,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
                    itemCount: PracticeTarget.values.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final t = PracticeTarget.values[i];
                      final selected = t == _target;
                      return ChoiceChip(
                        selected: selected,
                        showCheckmark: false,
                        avatar: Icon(t.icon,
                            size: 18, color: selected ? cs.primary : cs.onSurfaceVariant),
                        label: Text(t.label),
                        labelStyle: TextStyle(
                          fontSize: 13,
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                        ),
                        onSelected: (_) => _pickTarget(t),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 2, 20, 2),
                  child: Row(
                    children: [
                      Icon(Icons.lightbulb_outline, size: 16, color: cs.onSurfaceVariant),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _target.tip,
                          style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(child: _buildBoard(cs)),
                _buildControls(cs),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBoard(ColorScheme cs) {
    final result = _result;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B3B7A).withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = constraints.biggest;
            _boardSize = size;
            controller.canvasSize = size;
            final guide = buildPracticeGuide(_target, size);
            return Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: (e) {
                if (_result != null) setState(() => _result = null);
                controller.pointerDown(e.localPosition);
              },
              onPointerMove: (e) => controller.pointerMove(e.localPosition, e.delta),
              onPointerUp: (_) => controller.pointerUp(),
              onPointerCancel: (_) => controller.pointerUp(),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(painter: PracticePainter(controller, guide, cs.primary)),
                  ),
                  if (controller.items.isEmpty)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 18,
                      child: IgnorePointer(
                        child: Text(
                          'Trace the guide',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.primary.withValues(alpha: 0.45),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  if (result != null)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: IgnorePointer(child: _ScoreBadge(result: result)),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildControls(ColorScheme cs) {
    final result = _result;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final showIcons = constraints.maxWidth >= 320;
                  return Row(
                    children: [
                      Expanded(
                        child: showIcons
                            ? OutlinedButton.icon(
                                onPressed: controller.canUndo ? controller.undo : null,
                                icon: const Icon(Icons.undo_rounded, size: 18),
                                label: const Text('Undo'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  minimumSize: const Size(0, 48),
                                ),
                              )
                            : OutlinedButton(
                                onPressed: controller.canUndo ? controller.undo : null,
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  minimumSize: const Size(0, 48),
                                ),
                                child: const Text('Undo'),
                              ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: showIcons
                            ? OutlinedButton.icon(
                                onPressed: controller.items.isEmpty ? null : _clearSketch,
                                icon: const Icon(Icons.restart_alt_rounded, size: 18),
                                label: const Text('Clear'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  minimumSize: const Size(0, 48),
                                ),
                              )
                            : OutlinedButton(
                                onPressed: controller.items.isEmpty ? null : _clearSketch,
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  minimumSize: const Size(0, 48),
                                ),
                                child: const Text('Clear'),
                              ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: showIcons
                            ? FilledButton.icon(
                                onPressed: _check,
                                icon: const Icon(Icons.check_circle_outline, size: 18),
                                label: Text(result == null ? 'Check drawing' : 'Check again'),
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  minimumSize: const Size(0, 48),
                                ),
                              )
                            : FilledButton(
                                onPressed: _check,
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  minimumSize: const Size(0, 48),
                                ),
                                child: Text(result == null ? 'Check drawing' : 'Check again'),
                              ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  final SimilarityResult result;
  const _ScoreBadge({required this.result});

  @override
  Widget build(BuildContext context) {
    final color = _scoreColor(result.percent);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.18), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${result.percent.round()}%',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: color),
          ),
          Text(
            _scoreLabel(result.percent),
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }
}


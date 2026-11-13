import 'package:flutter/material.dart';

import '../../controllers/canvas_controller.dart';
import '../../core/app_constants.dart';
import '../../data/shop_catalog.dart';
import '../../models/quest.dart';
import '../../models/score.dart';
import '../../models/shop.dart';
import '../../painters/quest_painters.dart';
import '../../services/svg_document.dart';
import '../../services/svg_similarity.dart';
import '../../state/player_state.dart';
import '../../widgets/common/h_scroll.dart';
import '../../widgets/game/game_common.dart';

enum _Phase { preview, drawing, done }

class QuestPlayPage extends StatefulWidget {
  final QuestChallenge challenge;
  final PlayTier tier;
  final bool isDaily;
  const QuestPlayPage({
    super.key,
    required this.challenge,
    required this.tier,
    this.isDaily = false,
  });

  @override
  State<QuestPlayPage> createState() => _QuestPlayPageState();
}

class _QuestPlayPageState extends State<QuestPlayPage> {
  final CanvasController controller = CanvasController();
  _Phase _phase = _Phase.drawing;
  int _memoryCountdown = 3;
  Size _boardSize = Size.zero;
  Color _penColor = const Color(0xFF000000);
  double _penSize = 4;
  CanvasTheme _theme = allThemes.first;

  @override
  void initState() {
    super.initState();
    _theme = allThemes.firstWhere(
        (t) => playerState.ownsTheme(t.id),
        orElse: () => allThemes.first);
    if (widget.tier == PlayTier.memory) {
      _phase = _Phase.preview;
      _runMemoryCountdown();
    }
  }

  Future<void> _runMemoryCountdown() async {
    for (var i = 3; i >= 1; i--) {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      setState(() => _memoryCountdown = i);
    }
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    setState(() => _phase = _Phase.drawing);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _check() {
    if (controller.items.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
            content: Text('Draw something first!')));
      return;
    }
    if (_boardSize.width < 20 || _boardSize.height < 20) return;

    final reference = buildTransparentSvgDocument(
        widget.challenge.buildReference(_boardSize), _boardSize);
    final user = buildTransparentSvgDocument(controller.items, _boardSize);
    final result = SvgSimilarity.compare(
      reference,
      user,
      tolerance: 0.035,
      normalizeToBounds: true,
      samples: 1200,
    );

    final score = playerState.awardScore(
        widget.challenge, widget.tier, result.percent);

    if (score.isNewBest && score.stars == 3) {
      playerState.addToGallery(GalleryEntry(
        challengeId: widget.challenge.id,
        challengeName: widget.challenge.name,
        tier: widget.tier,
        percent: score.percent,
        when: DateTime.now(),
        items: List.of(controller.items),
        size: _boardSize,
      ));
    }

    setState(() => _phase = _Phase.done);
    _showResultsSheet(score);
  }

  void _showResultsSheet(ScoreResult score) {
    showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      showDragHandle: false,
      builder: (ctx) {
        final color = questScoreColor(score.percent);
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 18),
                Text('${score.percent.round()}%',
                    style: TextStyle(
                        fontSize: 54,
                        fontWeight: FontWeight.w900,
                        color: color,
                        height: 1)),
                Text(score.label,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: color)),
                const SizedBox(height: 10),
                StarsRow(count: score.stars, size: 32),
                const SizedBox(height: 18),
                if (score.coinsEarned > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: kGoldBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFFFD54F)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.monetization_on,
                          color: kGold, size: 20),
                      const SizedBox(width: 6),
                      Text('+${score.coinsEarned} coins',
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF8B6914))),
                    ]),
                  )
                else
                  Text(
                    score.isNewBest
                        ? 'Reached a new tier!'
                        : 'No new coins — beat your best tier',
                    style: TextStyle(
                        fontSize: 13, color: Colors.grey.shade600),
                  ),
                if (score.isPerfect)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text('PERFECT MATCH · +50 bonus',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: const Color(0xFF16A34A))),
                  ),
                if (score.isDaily)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text('DAILY · double coins applied',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(ctx).colorScheme.primary)),
                  ),
                const SizedBox(height: 20),
                Row(children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.arrow_back_rounded, size: 18),
                      label: const Text('Board'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF5B5BD6),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        minimumSize: const Size(0, 50),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        setState(() {
                          controller.resetAll();
                          _phase = widget.tier == PlayTier.memory
                              ? _Phase.preview
                              : _Phase.drawing;
                          _memoryCountdown = 3;
                        });
                        if (widget.tier == PlayTier.memory) {
                          _runMemoryCountdown();
                        }
                      },
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Retry'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF5B5BD6),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        minimumSize: const Size(0, 50),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.challenge.name,
            maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: const [CoinPill(), SizedBox(width: 12)],
      ),
      body: Column(children: [
        if (widget.isDaily)
          Container(
            width: double.infinity,
            color: const Color(0xFFFFA726).withValues(alpha: 0.15),
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: const Text('DAILY · 2× coins',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: Color(0xFFEF6C00))),
          ),
        Expanded(child: _buildCanvasArea(cs)),
        _buildToolbar(cs),
      ]),
    );
  }

  Widget _buildCanvasArea(ColorScheme cs) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 8)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: LayoutBuilder(builder: (context, constraints) {
          final size = constraints.biggest;
          _boardSize = size;
          controller.canvasSize = size;
          final reference = widget.challenge.buildReference(size);

          return Stack(children: [

            Positioned.fill(
              child: CustomPaint(painter: ThemePainter(_theme)),
            ),

            if (widget.tier == PlayTier.trace && _phase != _Phase.preview)
              Positioned.fill(
                child: CustomPaint(
                  painter:
                      GuidePainter(reference, kGuideInk, opacity: 0.30),
                ),
              ),

            Positioned.fill(
              child: Listener(
                behavior: HitTestBehavior.opaque,
                onPointerDown: _phase == _Phase.drawing
                    ? (e) => controller.pointerDown(e.localPosition)
                    : null,
                onPointerMove: _phase == _Phase.drawing
                    ? (e) => controller.pointerMove(
                        e.localPosition, e.delta)
                    : null,
                onPointerUp: _phase == _Phase.drawing
                    ? (_) => controller.pointerUp()
                    : null,
                onPointerCancel: _phase == _Phase.drawing
                    ? (_) => controller.pointerUp()
                    : null,
                child: CustomPaint(
                  painter: QuestCanvasPainter(controller),
                ),
              ),
            ),

            if (widget.tier == PlayTier.copy && _phase != _Phase.preview)
              Positioned(
                top: 8,
                left: 8,
                child: IgnorePointer(
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: ChallengePreview(
                        challenge: widget.challenge, size: 80),
                  ),
                ),
              ),

            if (widget.tier == PlayTier.memory && _phase == _Phase.preview)
              Positioned.fill(
                child: Container(
                  color: Colors.white,
                  child: Stack(children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: GuidePainter(reference, kGuideInk,
                            opacity: 0.9),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: cs.primary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Memorize! ${_memoryCountdown}s',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 13),
                          ),
                        ),
                      ),
                    ),
                  ]),
                ),
              ),

            if (controller.items.isEmpty &&
                _phase == _Phase.drawing &&
                widget.tier == PlayTier.trace)
              Positioned(
                left: 0,
                right: 0,
                bottom: 16,
                child: IgnorePointer(
                  child: Text('Trace the faint guide',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: cs.primary.withValues(alpha: 0.4))),
                ),
              ),
          ]);
        }),
      ),
    );
  }

  Widget _buildToolbar(ColorScheme cs) {
    final colorOptions = playerState.unlockedColors;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            SizedBox(
              height: 34,
              child: HScroll(
                builder: (scrollController) => ListView.separated(
                  controller: scrollController,
                  scrollDirection: Axis.horizontal,
                  itemCount: colorOptions.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final c = colorOptions[i];
                    final selected = c.toARGB32() == _penColor.toARGB32();
                    return GestureDetector(
                      onTap: () => setState(() => _penColor = c),
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: selected ? cs.primary : Colors.black12,
                              width: selected ? 3 : 1),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(children: [
              Icon(Icons.brush_rounded, size: 18, color: cs.primary),
              Expanded(
                child: Slider(
                  min: 1,
                  max: 40,
                  value: _penSize.clamp(1, 40).toDouble(),
                  onChanged: (v) => setState(() => _penSize = v),
                ),
              ),
              Container(
                width: 40,
                padding: const EdgeInsets.symmetric(vertical: 4),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8)),
                child: Text(_penSize.round().toString(),
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w800)),
              ),
            ]),
            const SizedBox(height: 6),
            LayoutBuilder(
              builder: (context, constraints) {
                final showIcons = constraints.maxWidth >= 320;
                return Row(children: [
                  Expanded(
                    child: showIcons
                        ? OutlinedButton.icon(
                            onPressed: controller.canUndo ? controller.undo : null,
                            icon: const Icon(Icons.undo_rounded, size: 18),
                            label: const Text('Undo'),
                            style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF5B5BD6),
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                minimumSize: const Size(0, 46)),
                          )
                        : OutlinedButton(
                            onPressed: controller.canUndo ? controller.undo : null,
                            style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF5B5BD6),
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                minimumSize: const Size(0, 46)),
                            child: const Text('Undo'),
                          ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: showIcons
                        ? OutlinedButton.icon(
                            onPressed: controller.items.isEmpty
                                ? null
                                : () => setState(controller.clear),
                            icon: const Icon(Icons.delete_outline_rounded, size: 18),
                            label: const Text('Clear'),
                            style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF5B5BD6),
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                minimumSize: const Size(0, 46)),
                          )
                        : OutlinedButton(
                            onPressed: controller.items.isEmpty
                                ? null
                                : () => setState(controller.clear),
                            style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF5B5BD6),
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                minimumSize: const Size(0, 46)),
                            child: const Text('Clear'),
                          ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: showIcons
                        ? FilledButton.icon(
                            onPressed: _phase == _Phase.drawing ? _check : null,
                            icon: const Icon(Icons.check_circle_outline, size: 18),
                            label: const Text('Check'),
                            style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF5B5BD6),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                minimumSize: const Size(0, 46)),
                          )
                        : FilledButton(
                            onPressed: _phase == _Phase.drawing ? _check : null,
                            style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF5B5BD6),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                minimumSize: const Size(0, 46)),
                            child: const Text('Check'),
                          ),
                  ),
                ]);
              },
            ),
          ]),
        ),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    controller.color = _penColor;
    controller.penSize = _penSize;
  }

  @override
  void setState(VoidCallback fn) {
    super.setState(fn);
    controller.color = _penColor;
    controller.penSize = _penSize;
  }
}


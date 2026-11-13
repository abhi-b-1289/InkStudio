import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart' hide ActionChip;

import '../controllers/canvas_controller.dart';
import '../services/download.dart' as dl;
import '../services/png_export.dart';
import '../core/app_constants.dart';
import '../core/formatters.dart';
import '../models/canvas_item.dart';
import '../models/canvas_preset.dart';
import '../models/saved_drawing.dart';
import '../models/shape.dart';
import '../painters/canvas_painters.dart';
import '../state/drawing_store.dart';
import '../widgets/canvas/canvas_size_picker.dart';
import '../widgets/canvas/canvas_widgets.dart';
import '../widgets/canvas/color_picker.dart';
import '../widgets/common/h_scroll.dart';

enum _Prop { stroke, size, rotate }
enum _StrokeProp { width, rotate }

class CanvasPage extends StatefulWidget {

  final SavedDrawing? drawing;

  final CanvasPreset? preset;

  const CanvasPage({super.key, this.drawing, this.preset});
  @override
  State<CanvasPage> createState() => _CanvasPageState();
}

class _CanvasPageState extends State<CanvasPage> {
  final controller = CanvasController();
  final _canvasKey = GlobalKey();
  _Prop _prop = _Prop.stroke;
  _StrokeProp _strokeProp = _StrokeProp.width;
  int _activeDimIdx = 0;
  late final int _drawingId;

  @override
  void initState() {
    super.initState();
    final d = widget.drawing;
    _drawingId = d?.id ?? newDrawingId();
    if (d != null) {
      controller.loadItems(d.items);

      controller.preset = d.preset ?? (d.canvasSize != Size.zero ? findOrMatchPreset(d.canvasSize) : null);
    }
    if (widget.preset != null) controller.preset = widget.preset;
  }

  @override
  void dispose() { controller.dispose(); super.dispose(); }

  void _save() {

    final existing = savedDrawings.firstWhere((e) => e.id == _drawingId, orElse: () => SavedDrawing(id: -1, name: '', items: [], canvasSize: Size.zero, updatedAt: DateTime.now()));
    savedDrawings.removeWhere((e) => e.id == _drawingId);
    if (controller.items.isEmpty) return;
    final name = existing.id == -1 ? 'Drawing ${takeNextDrawingNumber()}' : existing.name;
    savedDrawings.insert(
      0,
      SavedDrawing(
        id: _drawingId,
        name: name,
        items: List.of(controller.items),
        canvasSize: controller.canvasSize == Size.zero ? const Size(320, 480) : controller.canvasSize,
        preset: controller.preset,
        updatedAt: DateTime.now(),
      ),
    );
    if (savedDrawings.length > 50) savedDrawings.removeLast();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return PopScope(
          canPop: true,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) _save();
          },
          child: Scaffold(
            appBar: AppBar(
              title: const Text('InkStudio'),
              actions: [
                if (controller.preset != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _changeCanvasSize(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              controller.preset!.isLandscape
                                  ? Icons.stay_current_landscape_rounded
                                  : Icons.stay_current_portrait_rounded,
                              size: 14,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              controller.preset!.label,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                IconButton(tooltip: 'Undo', visualDensity: VisualDensity.compact, icon: const Icon(Icons.undo_rounded), onPressed: controller.canUndo ? controller.undo : null),
                IconButton(tooltip: 'Redo', visualDensity: VisualDensity.compact, icon: const Icon(Icons.redo_rounded), onPressed: controller.canRedo ? controller.redo : null),
                IconButton(tooltip: 'Export SVG', visualDensity: VisualDensity.compact, icon: const Icon(Icons.ios_share_rounded), onPressed: controller.items.isEmpty ? null : () => _showExportSheet(context)),
                IconButton(tooltip: 'Clear', visualDensity: VisualDensity.compact, icon: const Icon(Icons.delete_outline_rounded), onPressed: controller.items.isEmpty ? null : () => _confirmClear(context)),
                const SizedBox(width: 4),
              ],
            ),
            body: Column(children: [
              Expanded(child: _buildCanvas(context)),
              _buildDock(context),
            ]),
          ),
        );
      },
    );
  }

  Widget _buildCanvas(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final preset = controller.preset;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      child: LayoutBuilder(
        builder: (context, outerConstraints) {

          final Size canvasDim;
          if (preset != null) {
            canvasDim = preset.fitInto(
              Size(outerConstraints.maxWidth, outerConstraints.maxHeight),
              padding: 0,
            );
          } else {
            canvasDim = Size(outerConstraints.maxWidth, outerConstraints.maxHeight);
          }

          return Center(
            child: Container(
              width: canvasDim.width,
              height: canvasDim.height,
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
                child: DragTarget<ShapeType>(
                  onAcceptWithDetails: (details) {
                    final box = _canvasKey.currentContext?.findRenderObject() as RenderBox?;
                    if (box == null) return;
                    controller.addShape(details.data, at: box.globalToLocal(details.offset));
                  },
                  builder: (context, candidates, _) {
                    return Container(
                      key: _canvasKey,
                      color: Colors.white,
                      width: double.infinity,
                      height: double.infinity,
                      foregroundDecoration: candidates.isNotEmpty
                          ? BoxDecoration(
                              border: Border.all(color: cs.primary, width: 3),
                              borderRadius: BorderRadius.circular(22),
                            )
                          : null,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          controller.canvasSize = constraints.biggest;
                          return Listener(
                            behavior: HitTestBehavior.opaque,
                            onPointerDown: (e) => controller.pointerDown(e.localPosition),
                            onPointerMove: (e) => controller.pointerMove(e.localPosition, e.delta),
                            onPointerUp: (_) => controller.pointerUp(),
                            onPointerCancel: (_) => controller.pointerUp(),
                            child: Stack(
                              children: [
                                Positioned.fill(child: CustomPaint(painter: StrokePainter(controller, cs.primary))),
                                if (controller.items.isEmpty)
                                  IgnorePointer(
                                    child: Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.gesture_rounded, size: 44, color: Colors.black.withValues(alpha: 0.12)),
                                          const SizedBox(height: 8),
                                          Text('Draw with your finger or add a shape',
                                              style: TextStyle(color: Colors.black.withValues(alpha: 0.3), fontSize: 14)),
                                          if (preset != null) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              '${preset.label} • ${preset.isLandscape ? "Landscape" : "Portrait"}',
                                              style: TextStyle(color: Colors.black.withValues(alpha: 0.22), fontSize: 12),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDock(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final multiCount = controller.selectedIds.length;
    final hasGroup = controller.items
        .whereType<GroupItem>()
        .any((g) => controller.selectedIds.contains(g.id));

    final Widget contextual = switch (controller.tool) {
      ToolType.pen => _buildPenPanel(context),
      ToolType.eraser => _buildEraserPanel(context),
      ToolType.shapes => _buildShapeTray(context),
      ToolType.select => _buildSelectContextual(context, multiCount, hasGroup),
    };

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.55,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  alignment: Alignment.topCenter,
                  child: contextual,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: ToolButton(icon: Icons.edit_rounded, label: 'Pen', active: controller.tool == ToolType.pen, onTap: () => controller.setTool(ToolType.pen))),
                    Expanded(child: ToolButton(icon: Icons.auto_fix_normal_rounded, label: 'Eraser', active: controller.tool == ToolType.eraser, onTap: () => controller.setTool(ToolType.eraser))),
                    Expanded(child: ToolButton(icon: Icons.category_rounded, label: 'Shapes', active: controller.tool == ToolType.shapes, onTap: () => controller.setTool(ToolType.shapes))),
                    Expanded(child: ToolButton(icon: Icons.near_me_rounded, label: 'Select', active: controller.tool == ToolType.select, onTap: () => controller.setTool(ToolType.select))),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectContextual(
      BuildContext context, int multiCount, bool hasGroup) {
    final cs = Theme.of(context).colorScheme;

    if (multiCount == 0) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.touch_app_outlined, size: 18, color: cs.onSurfaceVariant),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'Tap to select  •  Drag empty space to lasso-select',
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ]),
      );
    }

    if (multiCount == 1) {
      final itemId = controller.selectedIds.first;
      CanvasItem? match;
      for (final it in controller.items) {
        if (controller.idOf(it) == itemId) { match = it; break; }
      }
      if (match is ShapeItem) return _buildShapePanel(context, match);
      if (match is Stroke) return _buildStrokePanel(context, match);
      if (match is GroupItem) return _buildGroupPanel(context, match);
    }

    return _buildMultiSelectPanel(context, multiCount, hasGroup);
  }

  Widget _buildStrokePanel(BuildContext context, Stroke stroke) {
    final cs = Theme.of(context).colorScheme;
    final deg = ((stroke.rotation * 180 / math.pi) % 360 + 360) % 360;

    final double value, min, max;
    final String text;
    final ValueChanged<double> onChanged;
    final IconData icon;
    final Widget? leading;

    switch (_strokeProp) {
      case _StrokeProp.width:
        value = stroke.width; min = 1; max = 60; text = stroke.width.round().toString();
        icon = Icons.line_weight_rounded;
        leading = BrushPreview(size: stroke.width, color: stroke.color);
        onChanged = (v) => controller.updateStroke(stroke.id, width: v, record: false);
      case _StrokeProp.rotate:
        value = deg; min = 0; max = 360; text = '${deg.round()}°';
        icon = Icons.rotate_right_rounded;
        leading = null;
        onChanged = (v) => controller.rotateStrokeTo(stroke.id, v * math.pi / 180, record: false);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 44,
          child: HScroll(
            builder: (scrollController) => ListView(
              controller: scrollController,
              scrollDirection: Axis.horizontal,
              children: [
                StyleTile(
                  label: 'Color',
                  color: stroke.color,
                  onTap: () => showColorPicker(
                    context,
                    title: 'Stroke color',
                    initial: stroke.color,
                    onSelected: (c) => controller.updateStroke(stroke.id, color: c),
                  ),
                ),
                const SizedBox(width: 8),
                IconAction(
                  icon: Icons.rotate_left_rounded,
                  tooltip: '−90°',
                  onTap: () => controller.rotateSelectedBy(-90),
                ),
                const SizedBox(width: 6),
                IconAction(
                  icon: Icons.rotate_right_rounded,
                  tooltip: '+90°',
                  onTap: () => controller.rotateSelectedBy(90),
                ),
                const SizedBox(width: 6),
                IconAction(
                  icon: Icons.copy_rounded,
                  tooltip: 'Duplicate',
                  onTap: () => controller.duplicateStroke(stroke.id),
                ),
                const SizedBox(width: 6),
                IconAction(
                  icon: Icons.delete_outline_rounded,
                  tooltip: 'Delete',
                  destructive: true,
                  onTap: () => controller.deleteStroke(stroke.id),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 300;
            return SizedBox(
              width: double.infinity,
              child: SegmentedButton<_StrokeProp>(
                showSelectedIcon: false,
                style: const ButtonStyle(visualDensity: VisualDensity.compact),
                segments: [
                  ButtonSegment(
                    value: _StrokeProp.width,
                    icon: const Icon(Icons.line_weight_rounded, size: 18),
                    label: compact ? null : const Text('Width'),
                  ),
                  ButtonSegment(
                    value: _StrokeProp.rotate,
                    icon: const Icon(Icons.rotate_right_rounded, size: 18),
                    label: compact ? null : const Text('Rotate'),
                  ),
                ],
                selected: {_strokeProp},
                onSelectionChanged: (v) => setState(() => _strokeProp = v.first),
              ),
            );
          },
        ),
        const SizedBox(height: 4),
        SliderRow(
          leading: leading ?? Icon(icon, size: 20, color: cs.primary),
          value: value, min: min, max: max, text: text,
          onStart: controller.beginEdit,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildGroupPanel(BuildContext context, GroupItem group) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: 44,
      child: HScroll(
        builder: (scrollController) => ListView(
          controller: scrollController,
          scrollDirection: Axis.horizontal,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: Text(
                'Group • ${group.children.length} items',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: cs.primary),
              ),
            ),
            const SizedBox(width: 8),
            IconAction(
              icon: Icons.rotate_left_rounded,
              tooltip: '−90°',
              onTap: () => controller.rotateSelectedBy(-90),
            ),
            const SizedBox(width: 6),
            IconAction(
              icon: Icons.rotate_right_rounded,
              tooltip: '+90°',
              onTap: () => controller.rotateSelectedBy(90),
            ),
            const SizedBox(width: 6),
            IconAction(
              icon: Icons.filter_none,
              tooltip: 'Ungroup',
              onTap: controller.ungroupSelected,
            ),
            const SizedBox(width: 6),
            IconAction(
              icon: Icons.copy_rounded,
              tooltip: 'Duplicate',
              onTap: controller.duplicateMultiSelected,
            ),
            const SizedBox(width: 6),
            IconAction(
              icon: Icons.delete_outline_rounded,
              tooltip: 'Delete',
              destructive: true,
              onTap: controller.deleteMultiSelected,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMultiSelectPanel(BuildContext context, int count, bool hasGroup) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [

        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                count == 1 ? '1 item selected' : '$count selected',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: cs.primary),
              ),
            ),
            const SizedBox(width: 8),
            IconAction(icon: Icons.select_all_rounded, tooltip: 'Select all', onTap: controller.selectAll),
            const SizedBox(width: 6),
            IconAction(icon: Icons.deselect_rounded, tooltip: 'Deselect', onTap: controller.clearSelection),
          ],
        ),
        const SizedBox(height: 10),

        HScroll(
          builder: (scrollController) => SingleChildScrollView(
            controller: scrollController,
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [

                if (count >= 2) ...[
                  ActionChip(
                    icon: Icons.group_work_rounded,
                    label: 'Group',
                    color: cs.primary,
                    onTap: controller.groupSelected,
                  ),
                  const SizedBox(width: 8),
                ],

                if (hasGroup) ...[
                  ActionChip(
                    icon: Icons.filter_none,
                    label: 'Ungroup',
                    color: cs.secondary,
                    onTap: controller.ungroupSelected,
                  ),
                  const SizedBox(width: 8),
                ],

                ActionChip(
                  icon: Icons.rotate_left_rounded,
                  label: '−90°',
                  color: const Color(0xFF8B5CF6),
                  onTap: () => controller.rotateSelectedBy(-90),
                ),
                const SizedBox(width: 8),
                ActionChip(
                  icon: Icons.rotate_right_rounded,
                  label: '+90°',
                  color: const Color(0xFF8B5CF6),
                  onTap: () => controller.rotateSelectedBy(90),
                ),
                const SizedBox(width: 8),

                ActionChip(
                  icon: Icons.copy_rounded,
                  label: 'Duplicate',
                  color: const Color(0xFF22C55E),
                  onTap: controller.duplicateMultiSelected,
                ),
                const SizedBox(width: 8),

                ActionChip(
                  icon: Icons.delete_outline_rounded,
                  label: 'Delete',
                  color: cs.error,
                  onTap: controller.deleteMultiSelected,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPenPanel(BuildContext context) {
    final cur = controller.color;
    final inQuick = kQuickColors.any((c) => sameColor(c, cur));
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 40,
          child: HScroll(
            builder: (scrollController) => ListView(
              controller: scrollController,
              scrollDirection: Axis.horizontal,
              children: [
                RainbowDot(onTap: () => showColorPicker(
                      context,
                      title: 'Pen color',
                      initial: cur,
                      onSelected: controller.setColor,
                    )),
                const SizedBox(width: 10),
                if (!inQuick) ...[
                  Dot(color: cur, selected: true, onTap: () {}),
                  const SizedBox(width: 10),
                ],
                for (final c in kQuickColors) ...[
                  Dot(color: c, selected: sameColor(c, cur), onTap: () => controller.setColor(c)),
                  const SizedBox(width: 10),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        SliderRow(
          leading: BrushPreview(size: controller.size, color: cur),
          value: controller.size, min: 1, max: 60,
          text: controller.size.round().toString(),
          onChanged: (v) => controller.size = v,
        ),
      ],
    );
  }

  Widget _buildEraserPanel(BuildContext context) {
    return SliderRow(
      leading: BrushPreview(size: controller.size, color: Colors.grey.shade400, outline: true),
      value: controller.size, min: 1, max: 60,
      text: controller.size.round().toString(),
      onChanged: (v) => controller.size = v,
    );
  }

  Widget _buildShapeTray(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 72,
          child: HScroll(
            builder: (scrollController) => ListView.separated(
              controller: scrollController,
              scrollDirection: Axis.horizontal,
              itemCount: ShapeType.values.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final t = ShapeType.values[i];
                return LongPressDraggable<ShapeType>(
                  data: t, dragAnchorStrategy: pointerDragAnchorStrategy,
                  feedback: Transform.translate(
                    offset: const Offset(-24, -24),
                    child: Material(color: Colors.transparent, child: Icon(t.icon, size: 48, color: cs.primary)),
                  ),
                  child: ShapeChip(type: t, onTap: () => controller.addShape(t)),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text('Tap to add  •  Long-press & drag onto canvas',
            style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
      ],
    );
  }

  List<ShapeDimensionInfo> _getShapeDimensions(ShapeItem s) {
    switch (s.type) {
      case ShapeType.circle:
        return [
          ShapeDimensionInfo(
            label: 'Radius',
            shortLabel: 'R',
            value: s.size.width / 2,
            min: 5,
            max: 500,
            icon: Icons.radio_button_unchecked,
            onChanged: (r) => controller.updateSelected(
              (x) => x.copyWith(size: Size(r * 2, r * 2)),
              record: false,
            ),
          ),
        ];
      case ShapeType.rectangle:
      case ShapeType.roundedRect:
        return [
          ShapeDimensionInfo(
            label: 'Width',
            shortLabel: 'W',
            value: s.size.width,
            min: 10,
            max: 1000,
            icon: Icons.swap_horiz_rounded,
            onChanged: (w) => controller.updateSelected(
              (x) => x.copyWith(size: Size(w, x.size.height)),
              record: false,
            ),
          ),
          ShapeDimensionInfo(
            label: 'Height',
            shortLabel: 'H',
            value: s.size.height,
            min: 10,
            max: 1000,
            icon: Icons.swap_vert_rounded,
            onChanged: (h) => controller.updateSelected(
              (x) => x.copyWith(size: Size(x.size.width, h)),
              record: false,
            ),
          ),
        ];
      case ShapeType.line:
        return [
          ShapeDimensionInfo(
            label: 'Length',
            shortLabel: 'L',
            value: s.size.width,
            min: 10,
            max: 1000,
            icon: Icons.straighten_rounded,
            onChanged: (l) => controller.updateSelected(
              (x) => x.copyWith(size: Size(l, x.size.height)),
              record: false,
            ),
          ),
        ];
      case ShapeType.arrow:
        return [
          ShapeDimensionInfo(
            label: 'Length',
            shortLabel: 'L',
            value: s.size.width,
            min: 20,
            max: 1000,
            icon: Icons.straighten_rounded,
            onChanged: (l) => controller.updateSelected(
              (x) => x.copyWith(size: Size(l, x.size.height)),
              record: false,
            ),
          ),
          ShapeDimensionInfo(
            label: 'Height',
            shortLabel: 'H',
            value: s.size.height,
            min: 10,
            max: 400,
            icon: Icons.swap_vert_rounded,
            onChanged: (h) => controller.updateSelected(
              (x) => x.copyWith(size: Size(x.size.width, h)),
              record: false,
            ),
          ),
        ];
      case ShapeType.ellipse:
        return [
          ShapeDimensionInfo(
            label: 'Radius X',
            shortLabel: 'Rx',
            value: s.size.width / 2,
            min: 5,
            max: 500,
            icon: Icons.swap_horiz_rounded,
            onChanged: (rx) => controller.updateSelected(
              (x) => x.copyWith(size: Size(rx * 2, x.size.height)),
              record: false,
            ),
          ),
          ShapeDimensionInfo(
            label: 'Radius Y',
            shortLabel: 'Ry',
            value: s.size.height / 2,
            min: 5,
            max: 500,
            icon: Icons.swap_vert_rounded,
            onChanged: (ry) => controller.updateSelected(
              (x) => x.copyWith(size: Size(x.size.width, ry * 2)),
              record: false,
            ),
          ),
        ];
      case ShapeType.triangle:
      case ShapeType.rightTriangle:
        return [
          ShapeDimensionInfo(
            label: 'Base',
            shortLabel: 'B',
            value: s.size.width,
            min: 10,
            max: 1000,
            icon: Icons.swap_horiz_rounded,
            onChanged: (w) => controller.updateSelected(
              (x) => x.copyWith(size: Size(w, x.size.height)),
              record: false,
            ),
          ),
          ShapeDimensionInfo(
            label: 'Height',
            shortLabel: 'H',
            value: s.size.height,
            min: 10,
            max: 1000,
            icon: Icons.swap_vert_rounded,
            onChanged: (h) => controller.updateSelected(
              (x) => x.copyWith(size: Size(x.size.width, h)),
              record: false,
            ),
          ),
        ];
      case ShapeType.diamond:
      case ShapeType.heart:
      case ShapeType.cross:
        return [
          ShapeDimensionInfo(
            label: 'Width',
            shortLabel: 'W',
            value: s.size.width,
            min: 10,
            max: 1000,
            icon: Icons.swap_horiz_rounded,
            onChanged: (w) => controller.updateSelected(
              (x) => x.copyWith(size: Size(w, x.size.height)),
              record: false,
            ),
          ),
          ShapeDimensionInfo(
            label: 'Height',
            shortLabel: 'H',
            value: s.size.height,
            min: 10,
            max: 1000,
            icon: Icons.swap_vert_rounded,
            onChanged: (h) => controller.updateSelected(
              (x) => x.copyWith(size: Size(x.size.width, h)),
              record: false,
            ),
          ),
        ];
      case ShapeType.pentagon:
      case ShapeType.hexagon:
        return [
          ShapeDimensionInfo(
            label: 'Radius',
            shortLabel: 'R',
            value: s.size.width / 2,
            min: 5,
            max: 500,
            icon: Icons.stars_rounded,
            onChanged: (r) => controller.updateSelected(
              (x) => x.copyWith(
                  size: Size(r * 2, r * 2 * (x.type.defaultSize.height / x.type.defaultSize.width))),
              record: false,
            ),
          ),
        ];
      case ShapeType.star:
        return [
          ShapeDimensionInfo(
            label: 'Radius',
            shortLabel: 'R',
            value: s.size.width / 2,
            min: 5,
            max: 500,
            icon: Icons.star_border_rounded,
            onChanged: (r) => controller.updateSelected(
              (x) => x.copyWith(
                  size: Size(r * 2, r * 2 * (x.type.defaultSize.height / x.type.defaultSize.width))),
              record: false,
            ),
          ),
        ];
    }
  }

  Future<void> _showShapeDimensionsDialog(
    BuildContext context,
    ShapeItem s, {
    int initialIndex = 0,
  }) async {
    final dims = _getShapeDimensions(s);
    if (dims.isEmpty) return;
    final controllers = dims.map((d) {
      final ctrl = TextEditingController(text: d.value.round().toString());
      ctrl.selection = TextSelection(baseOffset: 0, extentOffset: ctrl.text.length);
      return ctrl;
    }).toList();

    final cs = Theme.of(context).colorScheme;
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.straighten_rounded, color: cs.primary),
              const SizedBox(width: 8),
              Text('${s.type.label} Measurements'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enter exact measurements in pixels:',
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 16),
                for (var i = 0; i < dims.length; i++) ...[
                  if (i > 0) const SizedBox(height: 12),
                  TextField(
                    controller: controllers[i],
                    autofocus: i == initialIndex,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: dims[i].label,
                      prefixIcon: Icon(dims[i].icon, size: 20),
                      suffixText: 'px',
                      helperText: 'Valid range: ${dims[i].min.round()} – ${dims[i].max.round()} px',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                controller.beginEdit();
                for (var i = 0; i < dims.length; i++) {
                  final val = double.tryParse(controllers[i].text);
                  if (val != null) {
                    dims[i].onChanged(val.clamp(dims[i].min, dims[i].max));
                  }
                }
                Navigator.pop(ctx);
              },
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildShapePanel(BuildContext context, ShapeItem s) {
    final cs = Theme.of(context).colorScheme;
    final deg = ((s.rotation * 180 / math.pi) % 360 + 360) % 360;
    final dims = _getShapeDimensions(s);
    final activeIdx = _activeDimIdx.clamp(0, dims.length - 1);
    final activeDim = dims[activeIdx];

    final String measureSummary;
    if (dims.length == 1) {
      measureSummary = '${dims[0].label}: ${dims[0].value.round()} px';
    } else {
      measureSummary = '${dims.map((d) => "${d.shortLabel}:${d.value.round()}").join("  ")} px';
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [

        SizedBox(
          height: 44,
          child: HScroll(
            builder: (scrollController) => ListView(
              controller: scrollController,
              scrollDirection: Axis.horizontal,
              children: [
                StyleTile(
                  label: 'Outline',
                  color: s.strokeColor,
                  onTap: () => showColorPicker(
                    context,
                    title: 'Outline color',
                    initial: s.strokeColor,
                    onSelected: (c) => controller.updateSelected((x) => x.copyWith(strokeColor: c)),
                  ),
                ),
                if (s.type.isClosed) ...[
                  const SizedBox(width: 8),
                  StyleTile(
                    label: 'Fill',
                    color: s.fillColor,
                    onTap: () => showColorPicker(
                      context,
                      title: 'Fill color',
                      initial: s.fillColor ?? cs.primary,
                      onSelected: (c) => controller.updateSelected((x) => x.copyWith(fillColor: c)),
                      onNone: s.fillColor == null ? null : () => controller.updateSelected((x) => x.copyWith(clearFill: true)),
                    ),
                  ),
                ],
                const SizedBox(width: 8),
                MeasureTile(
                  label: 'Measure',
                  value: measureSummary,
                  icon: Icons.straighten_rounded,
                  onTap: () => _showShapeDimensionsDialog(context, s, initialIndex: activeIdx),
                ),
                const SizedBox(width: 8),
                IconAction(icon: Icons.copy_rounded, tooltip: 'Duplicate', onTap: controller.duplicateSelected),
                const SizedBox(width: 6),
                IconAction(icon: Icons.flip_to_front_rounded, tooltip: 'Bring to front', onTap: controller.bringToFront),
                const SizedBox(width: 6),
                IconAction(icon: Icons.delete_outline_rounded, tooltip: 'Delete', destructive: true, onTap: controller.deleteSelected),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 300;
            return SizedBox(
              width: double.infinity,
              child: SegmentedButton<_Prop>(
                showSelectedIcon: false,
                style: const ButtonStyle(visualDensity: VisualDensity.compact),
                segments: [
                  ButtonSegment(value: _Prop.stroke, icon: const Icon(Icons.line_weight_rounded, size: 18), label: compact ? null : const Text('Stroke')),
                  ButtonSegment(value: _Prop.size, icon: const Icon(Icons.straighten_rounded, size: 18), label: compact ? null : const Text('Size')),
                  ButtonSegment(value: _Prop.rotate, icon: const Icon(Icons.rotate_right_rounded, size: 18), label: compact ? null : const Text('Rotate')),
                ],
                selected: {_prop},
                onSelectionChanged: (v) => setState(() => _prop = v.first),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        if (_prop == _Prop.stroke) ...[
          SliderRow(
            leading: Icon(Icons.line_weight_rounded, size: 20, color: cs.primary),
            value: s.strokeWidth,
            min: 1,
            max: 30,
            text: '${s.strokeWidth.round()} px',
            onStart: controller.beginEdit,
            onChanged: (v) => controller.updateSelected((x) => x.copyWith(strokeWidth: v), record: false),
          ),
        ] else if (_prop == _Prop.rotate) ...[
          SliderRow(
            leading: Icon(Icons.rotate_right_rounded, size: 20, color: cs.primary),
            value: deg,
            min: 0,
            max: 360,
            text: '${deg.round()}°',
            onStart: controller.beginEdit,
            onChanged: (v) => controller.updateSelected((x) => x.copyWith(rotation: v * math.pi / 180), record: false),
          ),
        ] else if (_prop == _Prop.size) ...[

          if (dims.length > 1) ...[
            Row(
              children: [
                for (var i = 0; i < dims.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        if (_activeDimIdx == i) {
                          _showShapeDimensionsDialog(context, s, initialIndex: i);
                        } else {
                          setState(() => _activeDimIdx = i);
                        }
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: activeIdx == i ? cs.primaryContainer : cs.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: activeIdx == i ? cs.primary : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(dims[i].icon, size: 16, color: activeIdx == i ? cs.primary : cs.onSurfaceVariant),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '${dims[i].label}: ${dims[i].value.round()} px',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: activeIdx == i ? FontWeight.bold : FontWeight.w500,
                                  color: activeIdx == i ? cs.onPrimaryContainer : cs.onSurface,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Icon(Icons.edit_rounded, size: 13, color: activeIdx == i ? cs.primary : cs.onSurfaceVariant),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 6),
          ] else ...[
            Center(
              child: InkWell(
                onTap: () => _showShapeDimensionsDialog(context, s, initialIndex: 0),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: cs.primary.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(dims[0].icon, size: 18, color: cs.primary),
                      const SizedBox(width: 8),
                      Text(
                        '${dims[0].label}: ${dims[0].value.round()} px',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: cs.onPrimaryContainer),
                      ),
                      if (s.type == ShapeType.circle) ...[
                        Text(
                          '  (⌀ ${(dims[0].value * 2).round()} px)',
                          style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                        ),
                      ],
                      const SizedBox(width: 8),
                      Icon(Icons.edit_rounded, size: 14, color: cs.primary),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
          ],

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _StepperButton(
                label: '−10',
                onTap: () {
                  controller.beginEdit();
                  activeDim.onChanged((activeDim.value - 10).clamp(activeDim.min, activeDim.max));
                },
              ),
              const SizedBox(width: 6),
              _StepperButton(
                label: '−1',
                onTap: () {
                  controller.beginEdit();
                  activeDim.onChanged((activeDim.value - 1).clamp(activeDim.min, activeDim.max));
                },
              ),
              const SizedBox(width: 10),
              InkWell(
                onTap: () => _showShapeDimensionsDialog(context, s, initialIndex: activeIdx),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: cs.outlineVariant),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${activeDim.label}: ${activeDim.value.round()} px',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.edit_rounded, size: 13, color: cs.primary),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _StepperButton(
                label: '+1',
                onTap: () {
                  controller.beginEdit();
                  activeDim.onChanged((activeDim.value + 1).clamp(activeDim.min, activeDim.max));
                },
              ),
              const SizedBox(width: 6),
              _StepperButton(
                label: '+10',
                onTap: () {
                  controller.beginEdit();
                  activeDim.onChanged((activeDim.value + 10).clamp(activeDim.min, activeDim.max));
                },
              ),
            ],
          ),
          const SizedBox(height: 2),

          SliderRow(
            leading: Icon(activeDim.icon, size: 20, color: cs.primary),
            value: activeDim.value.clamp(activeDim.min, activeDim.max),
            min: activeDim.min,
            max: activeDim.max,
            text: '${activeDim.value.round()} px',
            onStart: controller.beginEdit,
            onChanged: activeDim.onChanged,
          ),
        ],
      ],
    );
  }

  Future<void> _changeCanvasSize(BuildContext context) async {
    final newPreset = await showCanvasSizePicker(context);
    if (newPreset != null) {
      setState(() => controller.preset = newPreset);
    }
  }

  void _showExportSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                'Export Drawing',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.image_rounded),
              title: const Text('Download as PNG'),
              subtitle: const Text('Standard (1x), High Resolution (2x, 4x)'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                Navigator.pop(ctx);
                _showPngResolutionDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.polyline_rounded),
              title: const Text('Download as SVG'),
              subtitle: const Text('Scalable vector graphics (.svg)'),
              trailing: const Icon(Icons.download_rounded, size: 20),
              onTap: () {
                Navigator.pop(ctx);
                _exportSvg(context);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showPngResolutionDialog(BuildContext context) {
    final size = controller.canvasSize;
    if (size == Size.zero || size.width <= 0 || size.height <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Canvas size is empty – draw something first')),
      );
      return;
    }

    final w = size.width.round();
    final h = size.height.round();

    showDialog<void>(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.image_rounded),
            SizedBox(width: 8),
            Text('Download as PNG'),
          ],
        ),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Select resolution quality:',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),
              _buildResolutionTile(
                context: dlgCtx,
                title: 'Standard (1x)',
                dimensions: '$w × $h px',
                icon: Icons.photo_size_select_actual_outlined,
                onTap: () {
                  Navigator.pop(dlgCtx);
                  _exportPng(context, pixelRatio: 1.0, resolutionLabel: 'Standard 1x');
                },
              ),
              const SizedBox(height: 8),
              _buildResolutionTile(
                context: dlgCtx,
                title: 'High Resolution (2x)',
                dimensions: '${w * 2} × ${h * 2} px • Crisp & sharp details',
                badge: 'HD',
                icon: Icons.hd_rounded,
                isRecommended: true,
                onTap: () {
                  Navigator.pop(dlgCtx);
                  _exportPng(context, pixelRatio: 2.0, resolutionLabel: 'High-Res 2x');
                },
              ),
              const SizedBox(height: 8),
              _buildResolutionTile(
                context: dlgCtx,
                title: 'Ultra HD (4x)',
                dimensions: '${w * 4} × ${h * 4} px • Maximum quality for print',
                badge: '4K',
                icon: Icons.high_quality_rounded,
                onTap: () {
                  Navigator.pop(dlgCtx);
                  _exportPng(context, pixelRatio: 4.0, resolutionLabel: 'Ultra HD 4x');
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dlgCtx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildResolutionTile({
    required BuildContext context,
    required String title,
    required String dimensions,
    required IconData icon,
    required VoidCallback onTap,
    bool isRecommended = false,
    String? badge,
  }) {
    final theme = Theme.of(context);
    return Material(
      color: isRecommended
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.45)
          : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isRecommended
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant,
              width: isRecommended ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isRecommended
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontWeight: isRecommended ? FontWeight.bold : FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: isRecommended
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.secondary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              badge,
                              style: TextStyle(
                                color: isRecommended
                                    ? theme.colorScheme.onPrimary
                                    : theme.colorScheme.onSecondary,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dimensions,
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.download_rounded,
                size: 20,
                color: isRecommended
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _exportPng(
    BuildContext context, {
    double pixelRatio = 1.0,
    String resolutionLabel = 'Standard 1x',
  }) async {
    final size = controller.canvasSize;
    if (size == Size.zero || size.width <= 0 || size.height <= 0) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Canvas size is empty – draw something first')),
        );
      }
      return;
    }
    try {
      final bytes = await renderPng(controller.items, size, pixelRatio: pixelRatio);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final scaleTag = pixelRatio == 1.0 ? '' : '_${pixelRatio.toInt()}x';
      await dl.downloadBytes(
        bytes,
        'inkstudio_$timestamp$scaleTag.png',
        mimeType: 'image/png',
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PNG downloaded ($resolutionLabel)')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PNG export failed: $e')),
        );
      }
    }
  }

  Future<void> _exportSvg(BuildContext context) async {
    final size = controller.canvasSize;
    if (size == Size.zero || size.width <= 0 || size.height <= 0) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Canvas size is empty – draw something first')),
        );
      }
      return;
    }
    try {
      final svg = controller.toSvg();
      final bytes = Uint8List.fromList(utf8.encode(svg));
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      await dl.downloadBytes(
        bytes,
        'inkstudio_$timestamp.svg',
        mimeType: 'image/svg+xml',
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('SVG downloaded')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('SVG export failed: $e')),
        );
      }
    }
  }

  Future<void> _confirmClear(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear canvas?'),
        content: const Text('This removes everything you have drawn.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Clear')),
        ],
      ),
    );
    if (ok == true) controller.clear();
  }
}

class ShapeDimensionInfo {
  final String label;
  final String shortLabel;
  final double value;
  final double min;
  final double max;
  final IconData icon;
  final ValueChanged<double> onChanged;

  const ShapeDimensionInfo({
    required this.label,
    required this.shortLabel,
    required this.value,
    required this.min,
    required this.max,
    required this.icon,
    required this.onChanged,
  });
}

class MeasureTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;
  const MeasureTile({super.key, required this.label, required this.value, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(14)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 18, color: cs.primary),
          const SizedBox(width: 6),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: cs.onSurfaceVariant)),
              Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(width: 4),
          Icon(Icons.edit_rounded, size: 13, color: cs.onSurfaceVariant.withValues(alpha: 0.6)),
        ]),
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _StepperButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}


import 'package:flutter/material.dart';

import '../../models/canvas_preset.dart';

Future<CanvasPreset?> showCanvasSizePicker(BuildContext context) {
  return showModalBottomSheet<CanvasPreset>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => const _CanvasSizePickerBody(),
  );
}

class _CanvasSizePickerBody extends StatefulWidget {
  const _CanvasSizePickerBody();
  @override
  State<_CanvasSizePickerBody> createState() => _CanvasSizePickerBodyState();
}

class _CanvasSizePickerBodyState extends State<_CanvasSizePickerBody> {
  late List<CanvasPreset> _presets;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();

    _presets = List.of(kCanvasPresets);
  }

  void _toggleOrientation(int index) {
    setState(() {
      _presets[index] = _presets[index].toggled();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final screenHeight = MediaQuery.sizeOf(context).height;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: screenHeight * 0.75),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [

          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 4),
            child: Row(
              children: [
                Icon(Icons.aspect_ratio_rounded, color: cs.primary, size: 22),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Canvas Size',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1B1B2F),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Pick a canvas ratio — tap the orientation button to flip between landscape and portrait.',
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: 16),

          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              itemCount: _presets.length,
              separatorBuilder: (_, _) => const SizedBox(height: 6),
              itemBuilder: (context, i) {
                final p = _presets[i];
                final selected = i == _selectedIndex;
                final isSquare = (p.aspectRatio - 1.0).abs() < 0.01;
                return _PresetTile(
                  preset: p,
                  selected: selected,
                  showOrientationToggle: !isSquare,
                  onTap: () => setState(() => _selectedIndex = i),
                  onToggleOrientation: () => _toggleOrientation(i),
                );
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                onPressed: () => Navigator.pop(context, _presets[_selectedIndex]),
                icon: const Icon(Icons.check_rounded),
                label: Text(
                  'Use ${_presets[_selectedIndex].label}'
                  '${_presets[_selectedIndex].isLandscape ? " Landscape" : " Portrait"}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PresetTile extends StatelessWidget {
  final CanvasPreset preset;
  final bool selected;
  final bool showOrientationToggle;
  final VoidCallback onTap;
  final VoidCallback onToggleOrientation;

  const _PresetTile({
    required this.preset,
    required this.selected,
    required this.showOrientationToggle,
    required this.onTap,
    required this.onToggleOrientation,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final orientationLabel = preset.isLandscape ? 'Landscape' : 'Portrait';

    return Material(
      color: selected ? cs.primaryContainer.withValues(alpha: 0.5) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? cs.primary : Colors.black.withValues(alpha: 0.06),
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [

              _MiniPreview(preset: preset, selected: selected),
              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      preset.label,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: selected ? cs.primary : const Color(0xFF1B1B2F),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      preset.subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              if (showOrientationToggle) ...[
                const SizedBox(width: 8),
                _OrientationToggle(
                  isLandscape: preset.isLandscape,
                  label: orientationLabel,
                  selected: selected,
                  onTap: onToggleOrientation,
                ),
              ],

              if (selected) ...[
                const SizedBox(width: 8),
                Icon(Icons.check_circle_rounded, color: cs.primary, size: 22),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniPreview extends StatelessWidget {
  final CanvasPreset preset;
  final bool selected;
  const _MiniPreview({required this.preset, required this.selected});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const maxDim = 40.0;
    double w, h;
    if (preset.aspectRatio >= 1) {
      w = maxDim;
      h = maxDim / preset.aspectRatio;
    } else {
      h = maxDim;
      w = maxDim * preset.aspectRatio;
    }

    w = w.clamp(14, maxDim);
    h = h.clamp(14, maxDim);

    return Container(
      width: maxDim,
      height: maxDim,
      alignment: Alignment.center,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: selected ? cs.primary.withValues(alpha: 0.12) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: selected ? cs.primary : Colors.grey.shade400,
            width: selected ? 2 : 1.5,
          ),
        ),
      ),
    );
  }
}

class _OrientationToggle extends StatelessWidget {
  final bool isLandscape;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _OrientationToggle({
    required this.isLandscape,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? cs.primary.withValues(alpha: 0.1) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? cs.primary.withValues(alpha: 0.3) : Colors.grey.shade300,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isLandscape ? Icons.stay_current_landscape_rounded : Icons.stay_current_portrait_rounded,
                size: 16,
                color: selected ? cs.primary : cs.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: selected ? cs.primary : cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 2),
              Icon(Icons.swap_horiz_rounded, size: 14, color: selected ? cs.primary : cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}


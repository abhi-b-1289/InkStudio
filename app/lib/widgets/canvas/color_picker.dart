import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_constants.dart';
import '../../core/formatters.dart';
import '../../state/recent_colors_store.dart';
import 'canvas_widgets.dart';

void showColorPicker(
  BuildContext context, {
  required String title,
  required Color initial,
  required ValueChanged<Color> onSelected,
  VoidCallback? onNone,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    enableDrag: false,
    showDragHandle: true,
    useSafeArea: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (_) => _ColorPickerSheet(title: title, initial: initial, onSelected: onSelected, onNone: onNone),
  );
}

class _ColorPickerSheet extends StatefulWidget {
  final String title;
  final Color initial;
  final ValueChanged<Color> onSelected;
  final VoidCallback? onNone;
  const _ColorPickerSheet({required this.title, required this.initial, required this.onSelected, this.onNone});

  @override
  State<_ColorPickerSheet> createState() => _ColorPickerSheetState();
}

class _ColorPickerSheetState extends State<_ColorPickerSheet> {
  late HSVColor _hsv;
  late final TextEditingController _hexCtrl;
  final FocusNode _hexFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _hsv = HSVColor.fromColor(widget.initial);
    _hexCtrl = TextEditingController(text: hex6(widget.initial));
  }

  @override
  void dispose() { _hexCtrl.dispose(); _hexFocus.dispose(); super.dispose(); }

  void _setHsv(HSVColor c) {
    setState(() => _hsv = c);
    if (!_hexFocus.hasFocus) _hexCtrl.text = hex6(c.toColor());
  }

  void _setColor(Color c) {
    setState(() => _hsv = HSVColor.fromColor(c));
    _hexCtrl.text = hex6(c);
  }

  void _onHexChanged(String v) {
    final h = v.replaceAll('#', '').trim();
    if (h.length == 6) {
      final n = int.tryParse('FF$h', radix: 16);
      if (n != null) setState(() => _hsv = HSVColor.fromColor(Color(n)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cur = _hsv.toColor();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text(widget.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const Spacer(),
              IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
            ]),
            const SizedBox(height: 8),

            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                height: 56,
                child: Row(children: [
                  Expanded(child: Container(color: widget.initial, alignment: Alignment.center,
                      child: Text('Current', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: widget.initial.computeLuminance() > 0.55 ? Colors.black54 : Colors.white70)))),
                  Expanded(child: Container(color: cur, alignment: Alignment.center,
                      child: Text('#${hex6(cur)}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: cur.computeLuminance() > 0.55 ? Colors.black87 : Colors.white)))),
                ]),
              ),
            ),
            const SizedBox(height: 16),
            _SVPicker(hsv: _hsv, onChanged: _setHsv),
            const SizedBox(height: 16),
            _HueBar(hue: _hsv.hue, onChanged: (h) => _setHsv(_hsv.withHue(h))),
            const SizedBox(height: 16),
            TextField(
              controller: _hexCtrl,
              focusNode: _hexFocus,
              maxLength: 6,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[0-9a-fA-F]'))],
              decoration: InputDecoration(
                labelText: 'Hex code', prefixText: '#', counterText: '',
                filled: true,
                fillColor: cs.surfaceContainerHighest,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
              onChanged: _onHexChanged,
            ),
            const SizedBox(height: 16),
            const Text('Palette', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10, runSpacing: 10,
              children: [
                for (final c in kPalette)
                  Dot(color: c, size: 34, selected: sameColor(c, cur), onTap: () => _setColor(c)),
              ],
            ),
            if (recentColors.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Recent', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10, runSpacing: 10,
                children: [
                  for (final c in recentColors)
                    Dot(color: c, size: 34, selected: sameColor(c, cur), onTap: () => _setColor(c)),
                ],
              ),
            ],
            const SizedBox(height: 20),
            Row(children: [
              if (widget.onNone != null) ...[
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () { Navigator.pop(context); widget.onNone!(); },
                  icon: const Icon(Icons.block_rounded, size: 18),
                  label: const Text('No fill'),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () {
                    addRecentColor(cur);
                    Navigator.pop(context);
                    widget.onSelected(cur);
                  },
                  child: const Text('Apply', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

class _SVPicker extends StatelessWidget {
  final HSVColor hsv;
  final ValueChanged<HSVColor> onChanged;
  const _SVPicker({required this.hsv, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      const h = 200.0;
      void update(Offset p) {
        final s = (p.dx / w).clamp(0.0, 1.0).toDouble();
        final v = 1 - (p.dy / h).clamp(0.0, 1.0).toDouble();
        onChanged(hsv.withSaturation(s).withValue(v));
      }

      final hueColor = HSVColor.fromAHSV(1, hsv.hue, 1, 1).toColor();
      return GestureDetector(
        onPanDown: (d) => update(d.localPosition),
        onPanUpdate: (d) => update(d.localPosition),
        child: SizedBox(
          width: w, height: h,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: DecoratedBox(
                    decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.white, hueColor])),
                    child: const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter, end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: hsv.saturation * w - 13,
                top: (1 - hsv.value) * h - 13,
                child: IgnorePointer(
                  child: Container(
                    width: 26, height: 26,
                    decoration: BoxDecoration(
                      color: hsv.toColor(),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 6)],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _HueBar extends StatelessWidget {
  final double hue;
  final ValueChanged<double> onChanged;
  const _HueBar({required this.hue, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      void update(Offset p) => onChanged((p.dx / w).clamp(0.0, 1.0).toDouble() * 360);

      return GestureDetector(
        onPanDown: (d) => update(d.localPosition),
        onPanUpdate: (d) => update(d.localPosition),
        child: SizedBox(
          width: w, height: 30,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(colors: [
                        for (var i = 0; i <= 6; i++) HSVColor.fromAHSV(1, i * 60.0, 1, 1).toColor(),
                      ]),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: hue / 360 * w - 15,
                top: 0,
                child: IgnorePointer(
                  child: Container(
                    width: 30, height: 30,
                    decoration: BoxDecoration(
                      color: HSVColor.fromAHSV(1, hue, 1, 1).toColor(),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 6)],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}


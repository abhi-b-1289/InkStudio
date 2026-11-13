import 'package:flutter/material.dart';

import '../../models/shape.dart';

class Dot extends StatelessWidget {
  final Color color;
  final bool selected;
  final double size;
  final VoidCallback onTap;
  const Dot({super.key, required this.color, required this.selected, required this.onTap, this.size = 36});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: size, height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: selected ? cs.primary : Colors.black12, width: selected ? 3 : 1),
          boxShadow: selected ? [BoxShadow(color: cs.primary.withValues(alpha: 0.35), blurRadius: 8)] : null,
        ),
      ),
    );
  }
}

class RainbowDot extends StatelessWidget {
  final VoidCallback onTap;
  const RainbowDot({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36, height: 36,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: SweepGradient(colors: [
            Color(0xFFFF0000), Color(0xFFFFFF00), Color(0xFF00FF00),
            Color(0xFF00FFFF), Color(0xFF0000FF), Color(0xFFFF00FF), Color(0xFFFF0000),
          ]),
        ),
        child: Center(
          child: Container(
            width: 18, height: 18,
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: const Icon(Icons.add, size: 14, color: Colors.black87),
          ),
        ),
      ),
    );
  }
}

class BrushPreview extends StatelessWidget {
  final double size;
  final Color color;
  final bool outline;
  const BrushPreview({super.key, required this.size, required this.color, this.outline = false});

  @override
  Widget build(BuildContext context) {
    final d = size.clamp(4.0, 30.0).toDouble();
    return SizedBox(
      width: 34, height: 34,
      child: Center(
        child: Container(
          width: d, height: d,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: outline ? Colors.transparent : color,
            border: outline ? Border.all(color: color, width: 2) : Border.all(color: Colors.black12),
          ),
        ),
      ),
    );
  }
}

class SliderRow extends StatelessWidget {
  final Widget leading;
  final double value, min, max;
  final String text;
  final ValueChanged<double> onChanged;
  final VoidCallback? onStart;
  const SliderRow({
    super.key,
    required this.leading, required this.value, required this.min, required this.max,
    required this.text, required this.onChanged, this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        leading,
        Expanded(
          child: Slider(
            min: min, max: max, value: value.clamp(min, max).toDouble(),
            onChangeStart: onStart == null ? null : (_) => onStart!(),
            onChanged: onChanged,
          ),
        ),
        Container(
          width: 52, padding: const EdgeInsets.symmetric(vertical: 6),
          alignment: Alignment.center,
          decoration: BoxDecoration(color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(10)),
          child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}

class StyleTile extends StatelessWidget {
  final String label;
  final Color? color;
  final VoidCallback onTap;
  const StyleTile({super.key, required this.label, required this.color, required this.onTap});

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
          Container(
            width: 24, height: 24,
            decoration: BoxDecoration(
              color: color ?? Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black26),
            ),
            child: color == null ? Icon(Icons.block_rounded, size: 16, color: cs.error) : null,
          ),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}

class IconAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool destructive;
  const IconAction({super.key, required this.icon, required this.tooltip, required this.onTap, this.destructive = false});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fg = destructive ? cs.error : cs.primary;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: destructive ? cs.errorContainer.withValues(alpha: 0.5) : cs.primaryContainer.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: fg),
        ),
      ),
    );
  }
}

class ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const ActionChip({super.key, required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
        ]),
      ),
    );
  }
}

class ShapeChip extends StatelessWidget {
  final ShapeType type;
  final VoidCallback onTap;
  const ShapeChip({super.key, required this.type, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(16), onTap: onTap,
      child: Container(
        width: 66, padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(type.icon, size: 26, color: cs.primary),
            const SizedBox(height: 4),
            Text(type.label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

class ToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const ToolButton({super.key, required this.icon, required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: active ? cs.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 24, color: active ? cs.primary : cs.onSurfaceVariant),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: active ? cs.primary : cs.onSurfaceVariant,
              )),
        ]),
      ),
    );
  }
}


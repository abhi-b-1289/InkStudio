import 'dart:math' as math;

import 'package:flutter/material.dart';

class CanvasPreset {
  final String label;
  final String subtitle;
  final IconData icon;

  final double aspectRatio;

  final bool isLandscape;

  const CanvasPreset({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.aspectRatio,
    required this.isLandscape,
  });

  Size fitInto(Size available, {double padding = 24}) {
    final maxW = available.width - padding * 2;
    final maxH = available.height - padding * 2;
    if (maxW <= 0 || maxH <= 0) return Size(maxW.clamp(1, double.infinity), maxH.clamp(1, double.infinity));

    double w, h;
    if (maxW / maxH > aspectRatio) {

      h = maxH;
      w = h * aspectRatio;
    } else {

      w = maxW;
      h = w / aspectRatio;
    }
    return Size(w.floorToDouble().clamp(1, double.infinity),
        h.floorToDouble().clamp(1, double.infinity));
  }

  CanvasPreset toggled() {
    final newIsLandscape = !isLandscape;
    String newLabel = label;
    if (label.contains(':')) {
      final parts = label.split(':');
      if (parts.length == 2) {
        newLabel = newIsLandscape ? '${parts[1]}:${parts[0]}' : '${parts[0]}:${parts[1]}';

        final a = double.tryParse(parts[0]) ?? 1;
        final b = double.tryParse(parts[1]) ?? 1;
        final larger = math.max(a, b);
        final smaller = math.min(a, b);
        final lStr = larger == larger.roundToDouble() ? larger.round().toString() : larger.toString();
        final sStr = smaller == smaller.roundToDouble() ? smaller.round().toString() : smaller.toString();
        newLabel = newIsLandscape ? '$lStr:$sStr' : '$sStr:$lStr';
      }
    }
    return CanvasPreset(
      label: newLabel,
      subtitle: subtitle,
      icon: icon,
      aspectRatio: 1 / aspectRatio,
      isLandscape: newIsLandscape,
    );
  }
}

const _kPresets = <_RatioInfo>[
  _RatioInfo('1:1',   'Square',                Icons.crop_square_rounded,   1, 1),
  _RatioInfo('16:9',  'Widescreen / Stories',   Icons.crop_16_9_rounded,    16, 9),
  _RatioInfo('4:3',   'Classic / iPad',          Icons.crop_rounded,         4, 3),
  _RatioInfo('3:2',   'Photo / Print',           Icons.photo_rounded,        3, 2),
  _RatioInfo('4:5',   'Portrait / Social',       Icons.crop_portrait_rounded, 4, 5),
  _RatioInfo('21:9',  'Ultra-wide / Cinema',     Icons.panorama_wide_angle_rounded, 21, 9),
  _RatioInfo('A4',    'Standard A4 Sheet',       Icons.description_rounded,  210, 297),
  _RatioInfo('Letter','US Letter Sheet',         Icons.article_rounded,      8.5, 11),
];

class _RatioInfo {
  final String label;
  final String subtitle;
  final IconData icon;
  final double w;
  final double h;
  const _RatioInfo(this.label, this.subtitle, this.icon, this.w, this.h);
}

final List<CanvasPreset> kCanvasPresets = _kPresets.map((r) {
  final landscape = r.w >= r.h;
  return CanvasPreset(
    label: r.label,
    subtitle: r.subtitle,
    icon: r.icon,
    aspectRatio: r.w / r.h,
    isLandscape: landscape,
  );
}).toList();

final CanvasPreset kDefaultPreset = kCanvasPresets.first;

CanvasPreset findOrMatchPreset(Size size) {
  if (size.width <= 0 || size.height <= 0) return kDefaultPreset;
  final ratio = size.width / size.height;
  final isLand = ratio >= 1.0;

  CanvasPreset? bestMatch;
  double minDiff = double.infinity;

  for (final p in kCanvasPresets) {

    for (final candidate in [p, p.toggled()]) {
      final diff = (candidate.aspectRatio - ratio).abs();
      if (diff < minDiff) {
        minDiff = diff;
        bestMatch = candidate;
      }
    }
  }

  if (bestMatch != null && minDiff < 0.035) {
    return bestMatch;
  }

  final label = '${size.width.round()}:${size.height.round()}';
  return CanvasPreset(
    label: label,
    subtitle: isLand ? 'Custom Landscape' : 'Custom Portrait',
    icon: isLand ? Icons.stay_current_landscape_rounded : Icons.stay_current_portrait_rounded,
    aspectRatio: ratio,
    isLandscape: isLand,
  );
}


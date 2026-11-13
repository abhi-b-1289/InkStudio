import 'dart:math' as math;

class Pt {
  final double x, y;
  const Pt(this.x, this.y);
}

class SimilarityResult {
  final double percent;
  final double coverage;
  final double precision;
  const SimilarityResult(this.percent, this.coverage, this.precision);

  @override
  String toString() =>
      'Similarity: ${percent.toStringAsFixed(1)}%  '
      '(coverage ${coverage.toStringAsFixed(1)}%, '
      'accuracy ${precision.toStringAsFixed(1)}%)';
}

class SvgSimilarity {
  static const double maxPercent = 95.0;
  static const double perfectPercent = 99.0;

  static SimilarityResult compare(
    String svgReference,
    String svgUser, {
    double tolerance = 0.03,
    bool normalizeToBounds = false,
    int samples = 1500,
  }) {
    final a = _ParsedSvg.parse(svgReference);
    final b = _ParsedSvg.parse(svgUser);

    final normA = _normalize(a.strokes, normalizeToBounds, a);
    final normB = _normalize(b.strokes, normalizeToBounds, b);
    final pa = _resampleNorm(normA, samples);
    final pb = _resampleNorm(normB, samples);

    if (pa.isEmpty || pb.isEmpty) return const SimilarityResult(0, 0, 0);

    final userGrid = _Grid(pb, tolerance);
    final cap = tolerance * 1.5;
    final recall = _avgScore(pa, userGrid, tolerance, cap);
    final precision = _avgScore(pb, _Grid(pa, tolerance), tolerance, cap);

    final parts = <List<Pt>>[];
    if (normA.length > 1) {
      for (final s in normA) {
        final pts = _evenSamples(s, 32);
        if (pts.isNotEmpty) parts.add(pts);
      }
    } else if (normA.isNotEmpty) {
      final pts = _evenSamples(normA.first, 96);
      if (pts.length >= 8) {
        for (var i = 0; i < 4; i++) {
          final start = pts.length * i ~/ 4;
          final end = pts.length * (i + 1) ~/ 4;
          if (end > start) parts.add(pts.sublist(start, end));
        }
      } else if (pts.isNotEmpty) {
        parts.add(pts);
      }
    }

    var partFactor = 1.0;
    if (parts.length > 1) {
      final covs = [
        for (final pts in parts) _avgScore(pts, userGrid, tolerance, cap)
      ];
      final mean = covs.reduce((x, y) => x + y) / covs.length;
      final weakest = covs.reduce(math.min);
      final completeness = 0.5 * mean + 0.5 * weakest;
      partFactor = 0.4 + 0.6 * completeness;
    }

    final tightTol = tolerance * 0.5;
    final tightRecall = _avgScore(pa, userGrid, tightTol, tolerance);
    final tightPrecision =
        _avgScore(pb, _Grid(pa, tolerance), tightTol, tolerance);
    final identical = tightRecall >= 0.999 &&
        tightPrecision >= 0.999 &&
        partFactor >= 0.995;

    final f = (recall + precision) == 0
        ? 0.0
        : 2 * recall * precision / (recall + precision);
    return SimilarityResult(
      identical
          ? perfectPercent
          : math.min(maxPercent, f * 100 * partFactor),
      identical
          ? perfectPercent
          : math.min(maxPercent, recall * 100 * partFactor),
      identical
          ? perfectPercent
          : math.min(maxPercent, precision * 100),
    );
  }

  static List<List<Pt>> _normalize(
      List<List<Pt>> strokes, bool toBounds, _ParsedSvg svg) {
    if (strokes.isEmpty) return [];
    double ox, oy, scale;
    if (toBounds) {
      double minX = double.infinity, minY = double.infinity;
      double maxX = -double.infinity, maxY = -double.infinity;
      for (final s in strokes) {
        for (final p in s) {
          minX = math.min(minX, p.x);
          minY = math.min(minY, p.y);
          maxX = math.max(maxX, p.x);
          maxY = math.max(maxY, p.y);
        }
      }
      final w = maxX - minX, h = maxY - minY;
      final m = math.max(math.max(w, h), 1e-9);
      scale = 1.0 / m;
      ox = minX - (m - w) / 2;
      oy = minY - (m - h) / 2;
    } else {
      final m = math.max(math.max(svg.vbW, svg.vbH), 1e-9);
      scale = 1.0 / m;
      ox = svg.vbX;
      oy = svg.vbY;
    }

    return [
      for (final s in strokes)
        [for (final p in s) Pt((p.x - ox) * scale, (p.y - oy) * scale)]
    ];
  }

  static List<Pt> _resampleNorm(List<List<Pt>> norm, int samples) {
    if (norm.isEmpty) return [];
    var total = 0.0;
    for (final s in norm) {
      for (var i = 1; i < s.length; i++) total += _dist(s[i - 1], s[i]);
    }
    final out = <Pt>[];
    if (total < 1e-9) {
      for (final s in norm) {
        if (s.isNotEmpty) out.add(s.first);
      }
      return out;
    }
    final step = total / samples;
    for (final s in norm) {
      out.addAll(_samplePath(s, step));
    }
    return out;
  }

  static List<Pt> _evenSamples(List<Pt> s, int minSamples) {
    if (s.isEmpty) return [];
    if (s.length == 1) return [s.first];
    var total = 0.0;
    for (var i = 1; i < s.length; i++) total += _dist(s[i - 1], s[i]);
    if (total < 1e-9) return [s.first];
    final n = math.max(minSamples, (total / 0.002).ceil());
    return _samplePath(s, total / n);
  }

  static List<Pt> _samplePath(List<Pt> s, double step) {
    if (s.isEmpty) return [];
    if (s.length == 1) return [s.first];
    final out = <Pt>[s.first];
    var carry = 0.0;
    for (var i = 1; i < s.length; i++) {
      final p0 = s[i - 1], p1 = s[i];
      final seg = _dist(p0, p1);
      if (seg == 0) continue;
      var d = step - carry;
      while (d <= seg) {
        final t = d / seg;
        out.add(Pt(p0.x + (p1.x - p0.x) * t, p0.y + (p1.y - p0.y) * t));
        d += step;
      }
      carry = seg - (d - step);
    }
    return out;
  }

  static double _avgScore(List<Pt> from, _Grid to, double tol, double cap) {
    double sum = 0;
    for (final p in from) {
      final d = to.nearest(p, cap);
      if (d <= tol) {
        sum += 1;
      } else if (d < cap) {
        sum += 1 - (d - tol) / (cap - tol);
      }
    }
    return sum / from.length;
  }

  static double _dist(Pt a, Pt b) =>
      math.sqrt((a.x - b.x) * (a.x - b.x) + (a.y - b.y) * (a.y - b.y));
}

class _Grid {
  final double cell;
  final Map<int, List<Pt>> map = {};
  _Grid(List<Pt> pts, double cellSize) : cell = math.max(cellSize, 1e-6) {
    for (final p in pts) {
      map.putIfAbsent(_key(_ix(p.x), _ix(p.y)), () => []).add(p);
    }
  }
  int _ix(double v) => (v / cell).floor();
  int _key(int x, int y) => (x + 100000) * 200003 + (y + 100000);

  double nearest(Pt p, double maxDist) {
    final cx = _ix(p.x), cy = _ix(p.y);
    final r = (maxDist / cell).ceil();
    double best = double.infinity;
    for (var dx = -r; dx <= r; dx++) {
      for (var dy = -r; dy <= r; dy++) {
        final list = map[_key(cx + dx, cy + dy)];
        if (list == null) continue;
        for (final q in list) {
          final d = math.sqrt(
              (p.x - q.x) * (p.x - q.x) + (p.y - q.y) * (p.y - q.y));
          if (d < best) best = d;
        }
      }
    }
    return best;
  }
}

class _ParsedSvg {
  double vbX = 0, vbY = 0, vbW = 0, vbH = 0;
  final List<List<Pt>> strokes = [];

  static final _tagRe = RegExp(
      r'<(svg|path|line|rect|circle|ellipse|polyline|polygon)\b([^>]*)>',
      caseSensitive: false);
  static final _attrRe =
      RegExp(r'''([\w:-]+)\s*=\s*(?:"([^"]*)"|'([^']*)')''');

  static _ParsedSvg parse(String src) {
    final r = _ParsedSvg();
    bool haveRoot = false;
    for (final m in _tagRe.allMatches(src)) {
      final tag = m.group(1)!.toLowerCase();
      final attrs = <String, String>{};
      for (final a in _attrRe.allMatches(m.group(2)!)) {
        attrs[a.group(1)!] = a.group(2) ?? a.group(3) ?? '';
      }
      if (tag == 'svg') {
        if (haveRoot) continue;
        haveRoot = true;
        final vb = attrs['viewBox'];
        if (vb != null) {
          final n = _nums(vb);
          if (n.length == 4) {
            r.vbX = n[0];
            r.vbY = n[1];
            r.vbW = n[2];
            r.vbH = n[3];
          }
        }
        if (r.vbW <= 0 || r.vbH <= 0) {
          r.vbW = _num(attrs['width']) ?? 0;
          r.vbH = _num(attrs['height']) ?? 0;
        }
        continue;
      }
      final polys = _shapeToPolylines(tag, attrs);
      final tf = _parseTransform(attrs['transform']);
      for (final pl in polys) {
        r.strokes.add(tf == null ? pl : [for (final p in pl) _apply(tf, p)]);
      }
    }

    if (r.vbW <= 0 || r.vbH <= 0) {
      double minX = double.infinity, minY = double.infinity;
      double maxX = -double.infinity, maxY = -double.infinity;
      for (final s in r.strokes) {
        for (final p in s) {
          minX = math.min(minX, p.x);
          minY = math.min(minY, p.y);
          maxX = math.max(maxX, p.x);
          maxY = math.max(maxY, p.y);
        }
      }
      if (minX.isFinite) {
        r.vbX = minX;
        r.vbY = minY;
        r.vbW = math.max(maxX - minX, 1);
        r.vbH = math.max(maxY - minY, 1);
      } else {
        r.vbW = r.vbH = 1;
      }
    }
    return r;
  }

  static double? _num(String? s) {
    if (s == null) return null;
    final m = RegExp(r'-?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?').firstMatch(s);
    return m == null ? null : double.tryParse(m.group(0)!);
  }

  static List<double> _nums(String s) =>
      RegExp(r'-?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?')
          .allMatches(s)
          .map((m) => double.parse(m.group(0)!))
          .toList();

  static List<List<Pt>> _shapeToPolylines(String tag, Map<String, String> a) {
    double g(String k) => _num(a[k]) ?? 0;
    switch (tag) {
      case 'path':
        return _parsePath(a['d'] ?? '');
      case 'line':
        return [
          [Pt(g('x1'), g('y1')), Pt(g('x2'), g('y2'))]
        ];
      case 'rect':
        final x = g('x'), y = g('y'), w = g('width'), h = g('height');
        return [
          [Pt(x, y), Pt(x + w, y), Pt(x + w, y + h), Pt(x, y + h), Pt(x, y)]
        ];
      case 'circle':
        final fill = (a['fill'] ?? '').trim().toLowerCase();
        if (fill.isNotEmpty && fill != 'none') {
          return [
            [Pt(g('cx'), g('cy'))]
          ];
        }
        return [_ellipse(g('cx'), g('cy'), g('r'), g('r'))];
      case 'ellipse':
        final fill = (a['fill'] ?? '').trim().toLowerCase();
        if (fill.isNotEmpty && fill != 'none') {
          return [
            [Pt(g('cx'), g('cy'))]
          ];
        }
        return [_ellipse(g('cx'), g('cy'), g('rx'), g('ry'))];
      case 'polyline':
      case 'polygon':
        final n = _nums(a['points'] ?? '');
        final pts = <Pt>[
          for (var i = 0; i + 1 < n.length; i += 2) Pt(n[i], n[i + 1])
        ];
        if (tag == 'polygon' && pts.isNotEmpty) pts.add(pts.first);
        return pts.isEmpty ? [] : [pts];
    }
    return [];
  }

  static List<Pt> _ellipse(double cx, double cy, double rx, double ry) => [
        for (var i = 0; i <= 64; i++)
          Pt(cx + rx * math.cos(2 * math.pi * i / 64),
              cy + ry * math.sin(2 * math.pi * i / 64))
      ];

  static final _pathTokRe = RegExp(
      r'([MmLlHhVvCcSsQqTtAaZz])|(-?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?)');

  static List<List<Pt>> _parsePath(String d) {
    final toks = _pathTokRe.allMatches(d).map((m) => m.group(0)!).toList();
    final out = <List<Pt>>[];
    var cur = <Pt>[];
    int i = 0;
    String cmd = '';
    double x = 0, y = 0, sx = 0, sy = 0;
    double lcx = 0, lcy = 0;
    String prev = '';

    bool isCmd(String t) => RegExp(r'^[A-Za-z]$').hasMatch(t);
    double next() => double.parse(toks[i++]);
    bool hasNum() => i < toks.length && !isCmd(toks[i]);

    void flush() {
      if (cur.length > 1) out.add(cur);
      cur = <Pt>[];
    }

    while (i < toks.length) {
      if (isCmd(toks[i])) cmd = toks[i++];
      final rel = cmd == cmd.toLowerCase();
      final c = cmd.toUpperCase();
      if (c == 'Z') {
        if (cur.isNotEmpty) cur.add(Pt(sx, sy));
        x = sx;
        y = sy;
        flush();
        prev = 'Z';
        continue;
      }
      if (!hasNum()) continue;
      switch (c) {
        case 'M':
          var nx = next(), ny = next();
          if (rel) {
            nx += x;
            ny += y;
          }
          flush();
          x = sx = nx;
          y = sy = ny;
          cur.add(Pt(x, y));
          cmd = rel ? 'l' : 'L';
          break;
        case 'L':
          var nx = next(), ny = next();
          if (rel) {
            nx += x;
            ny += y;
          }
          if (cur.isEmpty) cur.add(Pt(x, y));
          x = nx;
          y = ny;
          cur.add(Pt(x, y));
          break;
        case 'H':
          var nx = next();
          if (rel) nx += x;
          if (cur.isEmpty) cur.add(Pt(x, y));
          x = nx;
          cur.add(Pt(x, y));
          break;
        case 'V':
          var ny = next();
          if (rel) ny += y;
          if (cur.isEmpty) cur.add(Pt(x, y));
          y = ny;
          cur.add(Pt(x, y));
          break;
        case 'C':
        case 'S':
          double x1, y1;
          if (c == 'C') {
            x1 = next();
            y1 = next();
            if (rel) {
              x1 += x;
              y1 += y;
            }
          } else {
            if (prev == 'C' || prev == 'S') {
              x1 = 2 * x - lcx;
              y1 = 2 * y - lcy;
            } else {
              x1 = x;
              y1 = y;
            }
          }
          var x2 = next(), y2 = next(), ex = next(), ey = next();
          if (rel) {
            x2 += x;
            y2 += y;
            ex += x;
            ey += y;
          }
          if (cur.isEmpty) cur.add(Pt(x, y));
          for (var s = 1; s <= 24; s++) {
            final t = s / 24, u = 1 - t;
            cur.add(Pt(
                u * u * u * x +
                    3 * u * u * t * x1 +
                    3 * u * t * t * x2 +
                    t * t * t * ex,
                u * u * u * y +
                    3 * u * u * t * y1 +
                    3 * u * t * t * y2 +
                    t * t * t * ey));
          }
          lcx = x2;
          lcy = y2;
          x = ex;
          y = ey;
          break;
        case 'Q':
        case 'T':
          double qx, qy;
          if (c == 'Q') {
            qx = next();
            qy = next();
            if (rel) {
              qx += x;
              qy += y;
            }
          } else {
            if (prev == 'Q' || prev == 'T') {
              qx = 2 * x - lcx;
              qy = 2 * y - lcy;
            } else {
              qx = x;
              qy = y;
            }
          }
          var ex = next(), ey = next();
          if (rel) {
            ex += x;
            ey += y;
          }
          if (cur.isEmpty) cur.add(Pt(x, y));
          for (var s = 1; s <= 20; s++) {
            final t = s / 20, u = 1 - t;
            cur.add(Pt(u * u * x + 2 * u * t * qx + t * t * ex,
                u * u * y + 2 * u * t * qy + t * t * ey));
          }
          lcx = qx;
          lcy = qy;
          x = ex;
          y = ey;
          break;
        case 'A':
          final rx = next(), ry = next(), rot = next();
          final fa = next() != 0, fs = next() != 0;
          var ex = next(), ey = next();
          if (rel) {
            ex += x;
            ey += y;
          }
          if (cur.isEmpty) cur.add(Pt(x, y));
          cur.addAll(_arc(x, y, rx, ry, rot, fa, fs, ex, ey));
          x = ex;
          y = ey;
          break;
        default:
          i++;
      }
      prev = c;
    }
    flush();
    return out;
  }

  static List<Pt> _arc(double x1, double y1, double rx, double ry,
      double phiDeg, bool fa, bool fs, double x2, double y2) {
    if (rx == 0 || ry == 0 || (x1 == x2 && y1 == y2)) return [Pt(x2, y2)];
    rx = rx.abs();
    ry = ry.abs();
    final phi = phiDeg * math.pi / 180;
    final cp = math.cos(phi), sp = math.sin(phi);
    final dx = (x1 - x2) / 2, dy = (y1 - y2) / 2;
    final x1p = cp * dx + sp * dy, y1p = -sp * dx + cp * dy;
    final lam = (x1p * x1p) / (rx * rx) + (y1p * y1p) / (ry * ry);
    if (lam > 1) {
      final s = math.sqrt(lam);
      rx *= s;
      ry *= s;
    }
    final num = rx * rx * ry * ry - rx * rx * y1p * y1p - ry * ry * x1p * x1p;
    final den = rx * rx * y1p * y1p + ry * ry * x1p * x1p;
    var co = math.sqrt(math.max(0, num / den));
    if (fa == fs) co = -co;
    final cxp = co * rx * y1p / ry, cyp = -co * ry * x1p / rx;
    final cx = cp * cxp - sp * cyp + (x1 + x2) / 2;
    final cy = sp * cxp + cp * cyp + (y1 + y2) / 2;
    double ang(double ux, double uy, double vx, double vy) =>
        math.atan2(ux * vy - uy * vx, ux * vx + uy * vy);

    final th1 = ang(1, 0, (x1p - cxp) / rx, (y1p - cyp) / ry);
    var dth = ang((x1p - cxp) / rx, (y1p - cyp) / ry, (-x1p - cxp) / rx,
        (-y1p - cyp) / ry);
    if (!fs && dth > 0) dth -= 2 * math.pi;
    if (fs && dth < 0) dth += 2 * math.pi;
    final n = math.max(8, (dth.abs() / (math.pi / 16)).ceil());
    return [
      for (var s = 1; s <= n; s++)
        () {
          final t = th1 + dth * s / n;
          final ex = rx * math.cos(t), ey = ry * math.sin(t);
          return Pt(cp * ex - sp * ey + cx, sp * ex + cp * ey + cy);
        }()
    ];
  }

  static List<double>? _parseTransform(String? s) {
    if (s == null || s.trim().isEmpty) return null;
    var m = [1.0, 0.0, 0.0, 1.0, 0.0, 0.0];
    List<double> mul(List<double> p, List<double> q) => [
          p[0] * q[0] + p[2] * q[1],
          p[1] * q[0] + p[3] * q[1],
          p[0] * q[2] + p[2] * q[3],
          p[1] * q[2] + p[3] * q[3],
          p[0] * q[4] + p[2] * q[5] + p[4],
          p[1] * q[4] + p[3] * q[5] + p[5],
        ];
    for (final t in RegExp(r'(\w+)\s*\(([^)]*)\)').allMatches(s)) {
      final n = _nums(t.group(2)!);
      List<double>? q;
      switch (t.group(1)) {
        case 'translate':
          q = [1, 0, 0, 1, n.isNotEmpty ? n[0] : 0, n.length > 1 ? n[1] : 0];
          break;
        case 'scale':
          final sx = n.isNotEmpty ? n[0] : 1.0;
          q = [sx, 0, 0, n.length > 1 ? n[1] : sx, 0, 0];
          break;
        case 'rotate':
          final a = (n.isNotEmpty ? n[0] : 0) * math.pi / 180;
          final c = math.cos(a), sn = math.sin(a);
          q = [c, sn, -sn, c, 0, 0];
          if (n.length == 3) {
            final cx = n[1], cy = n[2];
            q = mul(mul([1, 0, 0, 1, cx, cy], q), [1, 0, 0, 1, -cx, -cy]);
          }
          break;
        case 'matrix':
          if (n.length == 6) q = n;
          break;
      }
      if (q != null) m = mul(m, q);
    }
    return m;
  }

  static Pt _apply(List<double> m, Pt p) =>
      Pt(m[0] * p.x + m[2] * p.y + m[4], m[1] * p.x + m[3] * p.y + m[5]);
}


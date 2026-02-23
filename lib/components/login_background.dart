// ─────────────────────────────────────────────────────────────────────────────
// login_background.dart
//
// A self-contained StatefulWidget — drop it anywhere as a background layer.
// Zero external dependencies.
//
// Desktop (side panel):
//   Row(children: [
//     Expanded(flex: 5, child: const LoginBackground()),
//     Expanded(flex: 4, child: YourLoginForm()),
//   ])
//
// Mobile (full-bleed, card on top):
//   Stack(children: [
//     const Positioned.fill(child: LoginBackground()),
//     Center(child: YourLoginForm()),
//   ])
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PUBLIC WIDGET — only export in this file
// ─────────────────────────────────────────────────────────────────────────────
class LoginBackground extends StatefulWidget {
  const LoginBackground({super.key});

  @override
  State<LoginBackground> createState() => _LoginBackgroundState();
}

class _LoginBackgroundState extends State<LoginBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 20),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => CustomPaint(
        painter: _ScenePainter(_ctrl.value),
        child: const SizedBox.expand(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PALETTE  — exact tokens from design_dashboard.dart
// ─────────────────────────────────────────────────────────────────────────────
class _C {
  // Base
  static const bg       = Color(0xFFF7F9FC);
  static const bgWarm   = Color(0xFFF0F4FA);
  static const white    = Colors.white;

  // Neutrals
  static const s50      = Color(0xFFF8FAFC);
  static const s100     = Color(0xFFF1F5F9);
  static const s200     = Color(0xFFE2E8F0);
  static const s300     = Color(0xFFCBD5E1);
  static const s400     = Color(0xFF94A3B8);
  static const s500     = Color(0xFF64748B);

  // Brand
  static const blue     = Color(0xFF2563EB);
  static const blue50   = Color(0xFFEFF6FF);
  static const blue100  = Color(0xFFDBEAFE);
  static const blue200  = Color(0xFFBFDBFE);
  static const teal     = Color(0xFF38BDF8);
  static const ink      = Color(0xFF0F172A);
  static const ink3     = Color(0xFF334155);

  // Stage accents — matching kStages exactly
  static const stage = [
    Color(0xFF64748B), // 0 Init      — slate-500
    Color(0xFF8B5CF6), // 1 Designing — purple
    Color(0xFFF59E0B), // 2 Review    — amber
    Color(0xFF10B981), // 3 Approved  — green
    Color(0xFF2563EB), // 4 Printing  — blue
  ];

  static const stageBg = [
    Color(0xFFF1F5F9), // slate-100
    Color(0xFFF5F3FF), // purple-50
    Color(0xFFFFFBEB), // amber-50
    Color(0xFFECFDF5), // green-50
    Color(0xFFEFF6FF), // blue-50
  ];

  static const stageBorder = [
    Color(0xFFCBD5E1), // slate-300
    Color(0xFFDDD6FE), // purple-200
    Color(0xFFFDE68A), // amber-200
    Color(0xFFA7F3D0), // green-200
    Color(0xFFBFDBFE), // blue-200
  ];

  static const stageLabel = [
    'Initialized',
    'Designing',
    'Awaiting\nApproval',
    'Client\nApproved',
    'Printing',
  ];

  static const stageShort = [
    'INIT', 'DESIGN', 'REVIEW', 'APPROVED', 'PRINT',
  ];

  // Fake task names per stage
  static const taskNames = [
    ['Brand identity', 'Brochure layout', 'Poster A3'],
    ['Hero banner', 'Business cards', 'Social pack'],
    ['Trade show\nbooth wrap', 'Roll-up banner'],
    ['Spring\ncampaign kit', 'Product sheet'],
    ['Vinyl banner', 'Packaging\ninserts', 'Letterhead'],
  ];
}

// ─────────────────────────────────────────────────────────────────────────────
// SCENE CONFIG
// ─────────────────────────────────────────────────────────────────────────────
const _kCardW    = 148.0;
const _kCardH    = 54.0;
const _kCardGap  = 10.0;
const _kColGap   = 22.0;
const _kHeaderH  = 32.0;
const _kColPad   = 10.0;
const _kCorner   = 9.0;
const _kTaskCorner = 6.0;

// How many task cards to show per column
const _kTaskRows = [3, 2, 2, 2, 3];

// ─────────────────────────────────────────────────────────────────────────────
// PAINTER
// ─────────────────────────────────────────────────────────────────────────────
class _ScenePainter extends CustomPainter {
  final double t;
  _ScenePainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    _drawBackground(canvas, size);
    _drawGridLines(canvas, size);

    // Apply a gentle perspective transform to the whole board section
    canvas.save();
    _applyBoardTransform(canvas, size);
    _drawBoard(canvas, size);
    canvas.restore();

    _drawConnectorDots(canvas, size); // dots drawn after restore in screen space
    _drawBrandFooter(canvas, size);
    _drawEdgeFades(canvas, size);
  }

  // ── Background ────────────────────────────────────────────────────────────
  void _drawBackground(Canvas canvas, Size size) {
    final w = size.width, h = size.height;

    // Warm off-white base gradient
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF4F7FB), Color(0xFFF7F9FC), Color(0xFFEFF5FD)],
          stops: [0.0, 0.5, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    // Blue bloom — upper area, very soft
    _radialGlow(canvas,
      cx: w * 0.3, cy: h * 0.15,
      r: w * 0.7,
      color: _C.blue.withOpacity(0.04),
      blur: 90,
    );

    // Teal accent bloom — lower right
    _radialGlow(canvas,
      cx: w * 0.85, cy: h * 0.78,
      r: w * 0.45,
      color: _C.teal.withOpacity(0.035),
      blur: 70,
    );
  }

  void _radialGlow(Canvas canvas, {
    required double cx, required double cy,
    required double r, required Color color, required double blur,
  }) {
    final c = Offset(cx, cy);
    canvas.drawCircle(
      c, r,
      Paint()
        ..shader = RadialGradient(colors: [color, Colors.transparent])
            .createShader(Rect.fromCircle(center: c, radius: r))
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur),
    );
  }

  // ── Subtle grid ───────────────────────────────────────────────────────────
  void _drawGridLines(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    const step = 40.0;
    final p = Paint()..color = _C.s200.withOpacity(0.4)..strokeWidth = 0.5;

    for (double x = 0; x < w; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, h), p);
    }
    for (double y = 0; y < h; y += step) {
      canvas.drawLine(Offset(0, y), Offset(w, y), p);
    }

    // Cross dots at intersections
    final dp = Paint()..color = _C.s300.withOpacity(0.35);
    for (double x = 0; x < w; x += step) {
      for (double y = 0; y < h; y += step) {
        canvas.drawCircle(Offset(x, y), 1.0, dp);
      }
    }
  }

  // ── Perspective transform for the board ───────────────────────────────────
  // A subtle tilt — like viewing the board on a desk at a slight angle.
  void _applyBoardTransform(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    // Slight Y-axis rotation in 2D (skew + scale trick)
    // We'll fake a gentle isometric feel: skew-X very slightly, scale Y down
    final cx = w * 0.5;
    final cy = h * 0.48;
    canvas.translate(cx, cy);
    canvas.transform(
      // 2D approximation of a mild 3D tilt — feels like a 10° X-axis rotation
      // [scaleX, skewY, 0, 0, skewX, scaleY, 0, 0, 0, 0, 1, 0, tx, ty, 0, 1]
      _mat4(
        scaleX: 1.0,
        scaleY: 0.88,   // compress Y slightly → perspective feel
        skewX: 0.0,
        skewY: 0.0,
      ),
    );
    canvas.translate(-cx, -cy);
  }

  Float64List _mat4({
    required double scaleX, required double scaleY,
    required double skewX,  required double skewY,
  }) {
    return Float64List.fromList([
      scaleX, skewY,  0, 0,
      skewX,  scaleY, 0, 0,
      0,      0,      1, 0,
      0,      0,      0, 1,
    ]);
  }

  // ── Board ─────────────────────────────────────────────────────────────────
  void _drawBoard(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    const nCols  = 5;
    final totalW = nCols * _kCardW + (nCols - 1) * _kColGap;

    // Board area: centred horizontally, sits in upper-centre of panel
    final boardLeft = (w - totalW) / 2;
    final boardTop  = h * 0.10;

    // Slow vertical float — entire board breathes
    final floatAmt = math.sin(t * math.pi * 2) * size.height * 0.008;

    for (int col = 0; col < nCols; col++) {
      // Each column has a tiny independent phase offset for organic feel
      final colFloat = floatAmt + math.sin(t * math.pi * 2 + col * 0.4) * 2.5;
      final colX = boardLeft + col * (_kCardW + _kColGap);
      final colY = boardTop  + colFloat;

      _drawColumn(canvas, col, Offset(colX, colY), size);
    }

    // Draw connector lines between column headers in board space
    _drawBoardConnectors(canvas, boardLeft, boardTop + floatAmt, size);
  }

  // ── Single kanban column ──────────────────────────────────────────────────
  void _drawColumn(Canvas canvas, int col, Offset origin, Size size) {
    final accent   = _C.stage[col];
    final stageBg  = _C.stageBg[col];
    final border   = _C.stageBorder[col];
    final taskRows = _kTaskRows[col];
    final colH     = _kHeaderH + _kColPad + taskRows * (_kCardH + _kCardGap) + _kColPad;

    final colRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(origin.dx, origin.dy, _kCardW, colH),
      const Radius.circular(_kCorner),
    );

    // Column shadow
    canvas.drawRRect(
      colRect.shift(const Offset(0, 6)),
      Paint()
        ..color = _C.blue.withOpacity(0.06)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
    );
    canvas.drawRRect(
      colRect.shift(const Offset(0, 2)),
      Paint()
        ..color = _C.s400.withOpacity(0.08)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );

    // Column body
    canvas.drawRRect(
      colRect,
      Paint()..color = _C.s50.withOpacity(0.96),
    );
    canvas.drawRRect(
      colRect,
      Paint()
        ..color = border.withOpacity(0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // ── Column header ────────────────────────────────────────────────────
    final headerRect = RRect.fromRectAndCorners(
      Rect.fromLTWH(origin.dx, origin.dy, _kCardW, _kHeaderH),
      topLeft:  const Radius.circular(_kCorner),
      topRight: const Radius.circular(_kCorner),
    );
    canvas.drawRRect(headerRect, Paint()..color = stageBg);
    canvas.drawRRect(
      headerRect,
      Paint()
        ..color = border.withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // Accent bar — left edge of header
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(origin.dx, origin.dy + 6, 3.0, _kHeaderH - 12),
        topLeft:    const Radius.circular(2),
        bottomLeft: const Radius.circular(2),
      ),
      Paint()..color = accent,
    );

    // Stage name
    _text(
      canvas,
      _C.stageShort[col],
      Offset(origin.dx + 11, origin.dy + 9),
      color: accent,
      size: 9.0,
      weight: FontWeight.w800,
      spacing: 0.5,
    );

    // Task count badge
    final countStr = '${_kTaskRows[col]}';
    final badgeW   = 18.0;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          origin.dx + _kCardW - badgeW - 8,
          origin.dy + (_kHeaderH - 16) / 2,
          badgeW, 16,
        ),
        const Radius.circular(99),
      ),
      Paint()..color = accent.withOpacity(0.12),
    );
    _text(
      canvas,
      countStr,
      Offset(origin.dx + _kCardW - badgeW / 2 - 8 + (countStr.length == 1 ? 5 : 2), origin.dy + 8),
      color: accent.withOpacity(0.9),
      size: 9.5,
      weight: FontWeight.w700,
    );

    // ── Task cards ───────────────────────────────────────────────────────
    for (int row = 0; row < taskRows; row++) {
      final cardOrigin = Offset(
        origin.dx + _kColPad,
        origin.dy + _kHeaderH + _kColPad + row * (_kCardH + _kCardGap),
      );
      final name = row < _C.taskNames[col].length
          ? _C.taskNames[col][row]
          : 'Task ${row + 1}';
      _drawTaskCard(canvas, cardOrigin, col, row, name);
    }
  }

  // ── Single task card ──────────────────────────────────────────────────────
  void _drawTaskCard(Canvas canvas, Offset o, int col, int row, String name) {
    final accent  = _C.stage[col];
    final cardW   = _kCardW - _kColPad * 2;
    final rect    = RRect.fromRectAndRadius(
      Rect.fromLTWH(o.dx, o.dy, cardW, _kCardH),
      const Radius.circular(_kTaskCorner),
    );

    // Card shadow
    canvas.drawRRect(
      rect.shift(const Offset(0, 2)),
      Paint()
        ..color = _C.s400.withOpacity(0.1)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Card body — white with very slight blue tint
    canvas.drawRRect(rect, Paint()..color = Colors.white);

    // Left accent strip
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(o.dx, o.dy + 8, 2.5, _kCardH - 16),
        topLeft:    const Radius.circular(2),
        bottomLeft: const Radius.circular(2),
      ),
      Paint()..color = accent.withOpacity(0.7),
    );

    // Card border
    canvas.drawRRect(
      rect,
      Paint()
        ..color = _C.s200.withOpacity(0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.75,
    );

    // Task name text — 2-line max
    final lines = name.split('\n');
    _text(
      canvas,
      lines[0],
      Offset(o.dx + 10, o.dy + 9),
      color: _C.ink3,
      size: 9.5,
      weight: FontWeight.w600,
    );
    if (lines.length > 1) {
      _text(
        canvas,
        lines[1],
        Offset(o.dx + 10, o.dy + 21),
        color: _C.ink3,
        size: 9.5,
        weight: FontWeight.w600,
      );
    }

    // Bottom row: priority dot + avatar circle
    final priorityColors = [_C.s400, _C.stage[2], _C.stage[0]]; // vary
    final priColor = priorityColors[row % priorityColors.length];

    canvas.drawCircle(
      Offset(o.dx + 10, o.dy + _kCardH - 9),
      3.5,
      Paint()..color = priColor.withOpacity(0.55),
    );

    // Avatar
    final avatarColors = [_C.blue, _C.stage[1], _C.stage[2], _C.stage[3]];
    final avColor = avatarColors[(col + row) % avatarColors.length];
    canvas.drawCircle(
      Offset(o.dx + cardW - 10, o.dy + _kCardH - 9),
      5.5,
      Paint()..color = avColor.withOpacity(0.2),
    );
    canvas.drawCircle(
      Offset(o.dx + cardW - 10, o.dy + _kCardH - 9),
      5.5,
      Paint()
        ..color = avColor.withOpacity(0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // Thin progress bar
    final barY  = o.dy + _kCardH - 17;
    final barW  = cardW - 20;
    final fillF = 0.3 + (col * 0.15 + row * 0.1).clamp(0.0, 0.9);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(o.dx + 10, barY, barW, 2.5),
        const Radius.circular(99),
      ),
      Paint()..color = _C.s200,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(o.dx + 10, barY, barW * fillF, 2.5),
        const Radius.circular(99),
      ),
      Paint()..color = accent.withOpacity(0.55),
    );
  }

  // ── Connector lines between column headers ────────────────────────────────
  void _drawBoardConnectors(Canvas canvas, double boardLeft, double boardTop, Size size) {
    for (int i = 0; i < 4; i++) {
      final x1 = boardLeft + i * (_kCardW + _kColGap) + _kCardW;
      final x2 = boardLeft + (i + 1) * (_kCardW + _kColGap);
      final y  = boardTop + _kHeaderH / 2;
      final mx = (x1 + x2) / 2;

      final path = Path()
        ..moveTo(x1, y)
        ..cubicTo(mx, y - 6, mx, y + 6, x2, y);

      _dashedPath(canvas, path,
        color: _C.s300.withOpacity(0.6),
        strokeW: 1.2,
        dash: 4,
        gap: 3,
      );

      // Arrow tip
      _arrowTip(canvas, Offset(x2, y), color: _C.s400.withOpacity(0.55));
    }
  }

  // ── Travelling dots on connectors — drawn in screen space ─────────────────
  // We compute their approximate position mirroring _applyBoardTransform.
  void _drawConnectorDots(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    const nCols  = 5;
    final totalW = nCols * _kCardW + (nCols - 1) * _kColGap;
    final boardLeft = (w - totalW) / 2;
    final boardTop  = h * 0.10;

    // Replicate transform math: scaleY=0.88 around centre
    final cx = w * 0.5, cy = h * 0.48;

    Offset transform(double px, double py) {
      // Apply scaleY=0.88 around (cx,cy)
      return Offset(px, cy + (py - cy) * 0.88);
    }

    final floatAmt = math.sin(t * math.pi * 2) * h * 0.008;

    for (int i = 0; i < 4; i++) {
      final x1 = boardLeft + i * (_kCardW + _kColGap) + _kCardW;
      final x2 = boardLeft + (i + 1) * (_kCardW + _kColGap);
      final rawY = boardTop + _kHeaderH / 2 + floatAmt;
      final mx   = (x1 + x2) / 2;

      // Stagger each dot
      final dt = ((t * 1.0 + i * 0.25) % 1.0);

      // Bezier on connector path
      final px = _bez(x1, mx, mx, x2, dt);
      final py = _bez(rawY, rawY - 6, rawY + 6, rawY, dt);

      // Apply the perspective Y-scale transform
      final sp = transform(px, py);

      final fade = math.min(dt * 7, math.min((1 - dt) * 7, 1.0));
      final accent = _C.stage[i];

      // Halo
      canvas.drawCircle(
        sp, 9,
        Paint()
          ..color = accent.withOpacity(0.10 * fade)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
      );
      // Ring
      canvas.drawCircle(
        sp, 5.5,
        Paint()
          ..color = accent.withOpacity(0.22 * fade)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
      // Core
      canvas.drawCircle(sp, 3.5,
          Paint()..color = accent.withOpacity(0.85 * fade));
      // Bright centre
      canvas.drawCircle(sp, 1.5,
          Paint()..color = Colors.white.withOpacity(0.9 * fade));
    }
  }

  // ── Brand footer ──────────────────────────────────────────────────────────
  void _drawBrandFooter(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final bx = w * 0.07;
    final lineY = h * 0.86;

    // Separator
    canvas.drawLine(
      Offset(bx, lineY),
      Offset(w * 0.93, lineY),
      Paint()..color = _C.s200..strokeWidth = 1.0,
    );

    // Stage pills breadcrumb
    double px = bx;
    final pillTop = lineY + 10;
    for (int i = 0; i < 5; i++) {
      final acc = _C.stage[i];
      final bg  = _C.stageBg[i];
      final lbl = _C.stageShort[i];
      final tw  = _measureW(lbl, 8.0, FontWeight.w700) + 14;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(px, pillTop, tw, 15),
          const Radius.circular(99),
        ),
        Paint()..color = bg,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(px, pillTop, tw, 15),
          const Radius.circular(99),
        ),
        Paint()
          ..color = acc.withOpacity(0.28)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.75,
      );
      _text(
        canvas, lbl,
        Offset(px + 7, pillTop + 2.5),
        color: acc, size: 8.0, weight: FontWeight.w700, spacing: 0.3,
      );
      px += tw;

      if (i < 4) {
        _text(
          canvas, '  →  ',
          Offset(px, pillTop + 2.5),
          color: _C.s300, size: 8.0, weight: FontWeight.w500,
        );
        px += 20;
      }
    }

    // Logo row
    final logoY = lineY + 30;
    final logoRect = Rect.fromLTWH(bx, logoY, 26, 26);

    // Logo gradient box
    canvas.drawRRect(
      RRect.fromRectAndRadius(logoRect, const Radius.circular(7)),
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF38BDF8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(logoRect),
    );

    // Checkmark on logo
    final lw = 26.0, lh = 26.0, ox = bx, oy = logoY;
    final ckPath = Path()
      ..moveTo(ox + lw * 0.28, oy + lh * 0.52)
      ..lineTo(ox + lw * 0.44, oy + lh * 0.67)
      ..lineTo(ox + lw * 0.76, oy + lh * 0.33);
    canvas.drawPath(
      ckPath,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Wordmark
    _text(
      canvas, 'smooflow',
      Offset(bx + 34, logoY + 3),
      color: _C.ink, size: 14.5, weight: FontWeight.w800, spacing: -0.5,
    );

    // Tagline
    _text(
      canvas, 'Design workflow management',
      Offset(bx + 34, logoY + 17),
      color: _C.s400, size: 9.5, weight: FontWeight.w500, spacing: 0.1,
    );
  }

  // ── Edge fades ────────────────────────────────────────────────────────────
  void _drawEdgeFades(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final rect = Rect.fromLTWH(0, 0, w, h);

    // Right edge → pure white (blends with login form on desktop)
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.transparent,
            Colors.white.withOpacity(0.0),
            Colors.white.withOpacity(0.6),
            Colors.white,
          ],
          stops: const [0.0, 0.6, 0.82, 1.0],
        ).createShader(rect),
    );

    // Top edge
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white.withOpacity(0.45), Colors.transparent],
          stops: const [0.0, 0.15],
        ).createShader(rect),
    );

    // Bottom edge
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.white.withOpacity(0.5), Colors.transparent],
          stops: const [0.0, 0.18],
        ).createShader(rect),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Drawing utilities
  // ─────────────────────────────────────────────────────────────────────────
  void _text(Canvas canvas, String str, Offset pos, {
    required Color color,
    required double size,
    required FontWeight weight,
    double spacing = 0,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: str,
        style: TextStyle(
          color: color, fontSize: size, fontWeight: weight,
          letterSpacing: spacing, height: 1.2,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos);
  }

  double _measureW(String str, double size, FontWeight weight) {
    final tp = TextPainter(
      text: TextSpan(text: str, style: TextStyle(fontSize: size, fontWeight: weight)),
      textDirection: TextDirection.ltr,
    )..layout();
    return tp.width;
  }

  void _dashedPath(Canvas canvas, Path path, {
    required Color color, required double strokeW,
    required double dash, required double gap,
  }) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (final m in path.computeMetrics()) {
      double d = 0;
      bool on = true;
      while (d < m.length) {
        final end = (d + (on ? dash : gap)).clamp(0.0, m.length);
        if (on) canvas.drawPath(m.extractPath(d, end), paint);
        d = end;
        on = !on;
      }
    }
  }

  void _arrowTip(Canvas canvas, Offset tip, {required Color color}) {
    const s = 4.0;
    final path = Path()
      ..moveTo(tip.dx - s, tip.dy - s * 1.3)
      ..lineTo(tip.dx, tip.dy)
      ..lineTo(tip.dx + s, tip.dy - s * 1.3);
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  double _bez(double p0, double p1, double p2, double p3, double t) {
    final m = 1 - t;
    return m*m*m*p0 + 3*m*m*t*p1 + 3*m*t*t*p2 + t*t*t*p3;
  }

  @override
  bool shouldRepaint(_ScenePainter old) => old.t != t;
}
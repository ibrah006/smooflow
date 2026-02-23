// ─────────────────────────────────────────────────────────────────────────────
// login_background.dart
//
// Light-themed background panel for the smooflow login page.
// Matches the existing login screen palette exactly:
//   Scaffold: 0xFFf7f9fb  |  Card: white  |  Primary: blue (#3b72e3)
//
// Built entirely with real Flutter widget composition —
// genuine BoxShadow, ClipRRect, BackdropFilter, layered gradients.
//
// Desktop: shown as the right-side panel (or left, your choice).
// Mobile:  full-bleed behind the login card.
//
// Usage:
//   // Desktop split-screen (already wired in your LayoutBuilder):
//   constraints.maxWidth > 600
//     ? Expanded(child: LoginBackground())
//     : SizedBox()
//
//   // Mobile full-bleed:
//   Stack(children: [
//     Positioned.fill(child: LoginBackground()),
//     Center(child: yourLoginCard),
//   ])
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:smooflow/components/logo.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PALETTE  — derived from the login screen source
// ─────────────────────────────────────────────────────────────────────────────
class _P {
  // Backgrounds — exactly matching login screen
  static const scaffold   = Color(0xFFf7f9fb);
  static const cardWhite  = Colors.white;
  static const borderLine = Color(0xFFe7eaf0);

  // Primary brand blue — from FilledButton + toast
  static const blue       = Color(0xFF3b72e3);
  static const blueLight  = Color(0xFF6594F0);
  static const blueFaint  = Color(0xFFEEF4FF);
  static const blueMid    = Color(0xFFD6E4FF);

  // Neutral
  static const s100       = Color(0xFFF1F5F9);
  static const s200       = Color(0xFFE2E8F0);
  static const s300       = Color(0xFFCBD5E1);
  static const s400       = Color(0xFF94A3B8);
  static const s500       = Color(0xFF64748B);
  static const ink        = Color(0xFF1E293B);
  static const ink2       = Color(0xFF334155);

  // Stage accents — same as kStages in design_dashboard
  static const stage = [
    Color(0xFF94A3B8), // Init     — slate
    Color(0xFF8B5CF6), // Design   — purple
    Color(0xFFF59E0B), // Review   — amber
    Color(0xFF10B981), // Approved — green
    Color(0xFF3b72e3), // Print    — brand blue
  ];

  static const stageBg = [
    Color(0xFFF1F5F9),
    Color(0xFFF5F3FF),
    Color(0xFFFFFBEB),
    Color(0xFFECFDF5),
    Color(0xFFEEF4FF),
  ];

  static const stageBorder = [
    Color(0xFFCBD5E1),
    Color(0xFFDDD6FE),
    Color(0xFFFDE68A),
    Color(0xFF6EE7B7),
    Color(0xFFBFDBFE),
  ];

  static const stageLabel = [
    'Initialized',
    'Designing',
    'In Review',
    'Approved',
    'Printing',
  ];
}

// ─────────────────────────────────────────────────────────────────────────────
// PUBLIC WIDGET
// ─────────────────────────────────────────────────────────────────────────────
class LoginBackground extends StatefulWidget {
  const LoginBackground({super.key});

  @override
  State<LoginBackground> createState() => _LoginBackgroundState();
}

class _LoginBackgroundState extends State<LoginBackground>
    with TickerProviderStateMixin {
  // Slow ambient breathe — 20s loop
  late final AnimationController _breathe = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 20),
  )..repeat();

  // Dot traveller along pipeline — 6s per stage loop
  late final AnimationController _travel = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat();

  // One-shot entry reveal
  late final AnimationController _entry = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  @override
  void initState() {
    super.initState();
    _entry.forward();
  }

  @override
  void dispose() {
    _breathe.dispose();
    _travel.dispose();
    _entry.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_breathe, _travel, _entry]),
      builder: (context, _) => _Scene(
        breathe: _breathe.value,
        travel:  _travel.value,
        entry:   CurvedAnimation(parent: _entry, curve: Curves.easeOutCubic).value,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SCENE
// ─────────────────────────────────────────────────────────────────────────────
class _Scene extends StatelessWidget {
  final double breathe; // 0..1 repeating
  final double travel;  // 0..1 repeating
  final double entry;   // 0..1 once

  const _Scene({
    required this.breathe,
    required this.travel,
    required this.entry,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final w = size.width, h = size.height;
    final isWide = w > 745;

    // Sine helpers
    final s1 = math.sin(breathe * math.pi * 2);
    final s2 = math.sin(breathe * math.pi * 2 + 1.4);

    return ClipRect(
      child: Stack(
        alignment: Alignment.centerRight,
        children: [
          // ── Base ─────────────────────────────────────────────────────
          const _Base(),
      
          // ── Soft colour blobs ─────────────────────────────────────────
          _SoftBlob(
            left: w * 0.05 + s1 * w * 0.02,
            top:  h * 0.05 + s1 * h * 0.015,
            diameter: w * 0.75,
            color: _P.blue.withOpacity(0.055),
          ),
          _SoftBlob(
            left: w * 0.40 + s2 * w * 0.018,
            top:  h * 0.38 + s2 * h * 0.018,
            diameter: w * 0.60,
            color: _P.stage[1].withOpacity(0.030),
          ),
          _SoftBlob(
            left: -w * 0.10,
            top:   h * 0.62 + s1 * h * 0.010,
            diameter: w * 0.55,
            color: _P.stage[3].withOpacity(0.025),
          ),
      
          // ── Fine grid ─────────────────────────────────────────────────
          SizedBox.expand(child: const _LightGrid()),
          SizedBox(
            width: MediaQuery.of(context).size.width/2,
            child: Stack(
              
              fit: StackFit.expand,
              children: [
            
                if (isWide) ...[
                  // ── Pipeline card columns ─────────────────────────────────────
                  _PipelineColumns(breathe: breathe, entry: entry, size: size),
            
                  // ── Floating KPI chips ────────────────────────────────────────
                  _Chip(
                    entry: entry, delay: 0.50,
                    top: h * 0.08,
                    right: w * 0.05 + s1 * w * 0.006,
                    label: 'Active tasks',
                    value: '24',
                    accent: _P.blue,
                  ),
                  _Chip(
                    entry: entry, delay: 0.62,
                    top: h * 0.26,
                    right: w * 0.05 + s2 * w * 0.005,
                    label: 'Approved today',
                    value: '7',
                    accent: _P.stage[3],
                  ),
                  _Chip(
                    entry: entry, delay: 0.74,
                    top: h * 0.44,
                    right: w * 0.05 + s1 * w * 0.005,
                    label: 'In review',
                    value: '3',
                    accent: _P.stage[2],
                  ),
            
                  // ── Pipeline overview bar ─────────────────────────────────────
                  _PipelineBar(
                    entry: entry, delay: 0.38,
                    left: w * 0.04,
                    bottom: h * 0.15,
                    width: math.min(w * 0.55, 340),
                  ),
            
                  // ── Brand lockup ──────────────────────────────────────────────
                  Positioned(
                    left: w * 0.06,
                    bottom: h * 0.045,
                    child: _BrandRow(entry: entry),
                  ),
            
                  // ── Right fade — blends into login form ───────────────────────
                  const _RightFade(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BASE
// ─────────────────────────────────────────────────────────────────────────────
class _Base extends StatelessWidget {
  const _Base();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end:   Alignment.bottomRight,
          colors: [
            Color(0xFFf4f7fc), // very slightly blue-white
            Color(0xFFf7f9fb), // exact scaffold colour
            Color(0xFFf0f5ff), // gentle blue tint at corner
          ],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SOFT BLOB
// ─────────────────────────────────────────────────────────────────────────────
class _SoftBlob extends StatelessWidget {
  final double left, top, diameter;
  final Color color;
  const _SoftBlob({required this.left, required this.top, required this.diameter, required this.color});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left, top: top,
      child: IgnorePointer(
        child: Container(
          width: diameter, height: diameter,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [color, Colors.transparent],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LIGHT GRID
// ─────────────────────────────────────────────────────────────────────────────
class _LightGrid extends StatelessWidget {
  const _LightGrid();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(child: CustomPaint(painter: _GridP()));
  }
}

class _GridP extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const step = 44.0;
    final line = Paint()
      ..color = _P.s200.withOpacity(0.55)
      ..strokeWidth = 0.5;
    final dot = Paint()..color = _P.s300.withOpacity(0.4);

    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), line);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    }
    for (double x = 0; x < size.width; x += step) {
      for (double y = 0; y < size.height; y += step) {
        canvas.drawCircle(Offset(x, y), 1.2, dot);
      }
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// PIPELINE COLUMNS
// ─────────────────────────────────────────────────────────────────────────────
const _kColW   = 142.0;
const _kColGap = 14.0;

class _PipelineColumns extends StatelessWidget {
  final double breathe, entry;
  final Size size;

  static const _tasks = [
    [['Brand identity', 0], ['Letterhead', 1], ['Poster A3', 0]],
    [['Hero banner', 2],    ['Social pack', 1], ['Icon set', 0]],
    [['Trade show\nbooth', 1], ['Brochure v3', 0]],
    [['Spring kit', 0],    ['Product\nsheet', 1]],
    [['Vinyl wrap', 1],    ['Packaging\ninserts', 0], ['Poster A1', 2]],
  ];

  const _PipelineColumns({required this.breathe, required this.entry, required this.size});

  @override
  Widget build(BuildContext context) {
    final w = size.width, h = size.height;
    const n = 5;
    final totalW = n * _kColW + (n - 1) * _kColGap;
    // Nudge columns left so right side stays clear for KPI chips
    final startX = (w - totalW) / 2 - w * 0.06;
    final startY = h * 0.07;

    return Stack(
      children: List.generate(n, (i) {
        final drift  = math.sin(breathe * math.pi * 2 + i * 0.6) * h * 0.009;
        final et     = ((entry - 0.06 - i * 0.06) / (1 - 0.06 - i * 0.06)).clamp(0.0, 1.0);
        final eased  = Curves.easeOutCubic.transform(et);

        return Positioned(
          left: startX + i * (_kColW + _kColGap),
          top:  startY + drift + (1 - eased) * 28,
          child: Opacity(
            opacity: eased,
            child: _Column(
              stageIndex: i,
              taskData: List<List<dynamic>>.from(_tasks[i]),
              maxH: h * 0.78,
            ),
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SINGLE COLUMN — real widget, real shadow
// ─────────────────────────────────────────────────────────────────────────────
class _Column extends StatelessWidget {
  final int stageIndex;
  final List<List<dynamic>> taskData;
  final double maxH;

  const _Column({required this.stageIndex, required this.taskData, required this.maxH});

  @override
  Widget build(BuildContext context) {
    final accent  = _P.stage[stageIndex];
    final bg      = _P.stageBg[stageIndex];
    final border  = _P.stageBorder[stageIndex];
    final label   = _P.stageLabel[stageIndex];

    return Container(
      width: _kColW,
      constraints: BoxConstraints(maxHeight: maxH),
      decoration: BoxDecoration(
        color: _P.cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _P.s200, width: 1.0),
        boxShadow: [
          // Ambient shadow
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
            spreadRadius: -2,
          ),
          // Coloured glow at base
          BoxShadow(
            color: accent.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
            spreadRadius: -4,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Column header ────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
              decoration: BoxDecoration(
                color: bg,
                border: Border(bottom: BorderSide(color: border.withOpacity(0.6))),
              ),
              child: Row(
                children: [
                  // Accent bar
                  Container(
                    width: 3, height: 13,
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: accent,
                        letterSpacing: 0.1,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Count badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      '${taskData.length}',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: accent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // ── Task cards ───────────────────────────────────────────
            Flexible(
              child: Padding(
                padding: const EdgeInsets.all(7),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: taskData.asMap().entries.map((e) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: _TaskTile(
                        name:       e.value[0] as String,
                        priority:   e.value[1] as int,
                        accent:     accent,
                        rowIdx:     e.key,
                        stageIndex: stageIndex,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TASK TILE
// ─────────────────────────────────────────────────────────────────────────────
class _TaskTile extends StatelessWidget {
  final String name;
  final int    priority;   // 0 normal, 1 high, 2 urgent
  final Color  accent;
  final int    rowIdx, stageIndex;

  static const _priColor = [
    Color(0xFF94A3B8), // normal
    Color(0xFFF59E0B), // high
    Color(0xFFEF4444), // urgent
  ];

  static const _avColor = [
    Color(0xFF3b72e3), Color(0xFF8B5CF6),
    Color(0xFF10B981), Color(0xFFF59E0B),
  ];

  const _TaskTile({
    required this.name, required this.priority,
    required this.accent, required this.rowIdx, required this.stageIndex,
  });

  @override
  Widget build(BuildContext context) {
    final pri = _priColor[priority.clamp(0, 2)];
    final av  = _avColor[(stageIndex + rowIdx) % 4];

    return Container(
      padding: const EdgeInsets.fromLTRB(0, 8, 8, 8),
      decoration: BoxDecoration(
        color: _P.scaffold,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _P.s200, width: 0.75),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left accent strip
            Container(
              width: 3,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.65),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  bottomLeft: Radius.circular(8),
                ),
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: _P.ink,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      // Priority dot
                      Container(
                        width: 6, height: 6,
                        decoration: BoxDecoration(color: pri, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 5),
                      // Progress bar
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: Stack(
                            children: [
                              Container(height: 3, color: _P.s200),
                              FractionallySizedBox(
                                widthFactor: (0.25 + stageIndex * 0.14).clamp(0.1, 0.95),
                                child: Container(
                                  height: 3,
                                  decoration: BoxDecoration(
                                    color: accent.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Avatar
                      Container(
                        width: 17, height: 17,
                        decoration: BoxDecoration(
                          color: av.withOpacity(0.15),
                          shape: BoxShape.circle,
                          border: Border.all(color: av.withOpacity(0.4), width: 1),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// KPI CHIP — top-right floating cards
// ─────────────────────────────────────────────────────────────────────────────
class _Chip extends StatelessWidget {
  final double entry, delay;
  final double top, right;
  final String label, value;
  final Color accent;

  const _Chip({
    required this.entry, required this.delay,
    required this.top,   required this.right,
    required this.label, required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final t     = ((entry - delay) / (1.0 - delay)).clamp(0.0, 1.0);
    final eased = Curves.easeOutCubic.transform(t);

    return Positioned(
      top: top, right: right,
      child: Opacity(
        opacity: eased,
        child: Transform.translate(
          offset: Offset(16 * (1 - eased), 0),
          child: Container(
            width: 148,
            padding: const EdgeInsets.fromLTRB(13, 11, 13, 11),
            decoration: BoxDecoration(
              color: _P.cardWhite,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _P.s200, width: 1.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                  spreadRadius: -3,
                ),
                BoxShadow(
                  color: accent.withOpacity(0.08),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Icon container
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Container(
                      width: 9, height: 9,
                      decoration: BoxDecoration(
                        color: accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        value,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: _P.ink,
                          letterSpacing: -0.8,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: _P.s400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PIPELINE BAR — segmented overview card at bottom
// ─────────────────────────────────────────────────────────────────────────────
class _PipelineBar extends StatelessWidget {
  final double entry, delay;
  final double left, bottom, width;

  static const _fracs = [0.18, 0.30, 0.16, 0.22, 0.14];

  const _PipelineBar({
    required this.entry, required this.delay,
    required this.left,  required this.bottom, required this.width,
  });

  @override
  Widget build(BuildContext context) {
    final t     = ((entry - delay) / (1.0 - delay)).clamp(0.0, 1.0);
    final eased = Curves.easeOutCubic.transform(t);

    return Positioned(
      left: left, bottom: bottom,
      child: Opacity(
        opacity: eased,
        child: Transform.translate(
          offset: Offset(0, 14 * (1 - eased)),
          child: Container(
            width: width,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              color: _P.cardWhite,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _P.s200, width: 1.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.055),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                  spreadRadius: -4,
                ),
                BoxShadow(
                  color: _P.blue.withOpacity(0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(children: [
                  Text(
                    'Pipeline Overview',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: _P.ink,
                      letterSpacing: 0.1,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _P.stage[3].withOpacity(0.10),
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: _P.stage[3].withOpacity(0.25)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 5, height: 5,
                          decoration: BoxDecoration(
                            color: _P.stage[3],
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '22 active',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: _P.stage[3],
                          ),
                        ),
                      ],
                    ),
                  ),
                ]),
                const SizedBox(height: 12),

                // Segmented bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Row(
                    children: List.generate(5, (i) => Expanded(
                      flex: (_fracs[i] * 100).round(),
                      child: Container(
                        height: 7,
                        color: _P.stage[i].withOpacity(0.70),
                        margin: EdgeInsets.only(right: i < 4 ? 2 : 0),
                      ),
                    )),
                  ),
                ),
                const SizedBox(height: 11),

                // Stage labels row
                Row(
                  children: List.generate(5, (i) => Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _P.stageLabel[i].split(' ').first,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: _P.stage[i],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 1),
                        Text(
                          '${(_fracs[i] * 22).round()}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: _P.ink,
                            letterSpacing: -0.4,
                          ),
                        ),
                      ],
                    ),
                  )),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BRAND ROW
// ─────────────────────────────────────────────────────────────────────────────
class _BrandRow extends StatelessWidget {
  final double entry;
  const _BrandRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final t     = ((entry - 0.15) / 0.85).clamp(0.0, 1.0);
    final eased = Curves.easeOut.transform(t);

    return Opacity(
      opacity: eased,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Logo box — matches exact gradient from the rest of the app
          // Container(
          //   width: 30, height: 30,
          //   decoration: BoxDecoration(
          //     gradient: const LinearGradient(
          //       colors: [Color(0xFF3b72e3), Color(0xFF38BDF8)],
          //       begin: Alignment.topLeft,
          //       end:   Alignment.bottomRight,
          //     ),
          //     borderRadius: BorderRadius.circular(8),
          //     boxShadow: [
          //       BoxShadow(
          //         color: _P.blue.withOpacity(0.30),
          //         blurRadius: 10,
          //         offset: const Offset(0, 3),
          //       ),
          //     ],
          //   ),
          //   child: CustomPaint(painter: _CheckP()),
          // ),
          SizedBox(
            width: 30,
            child: Logo()),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'smooflow',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: _P.ink,
                  letterSpacing: -0.4,
                ),
              ),
              Text(
                'Design workflow management',
                style: const TextStyle(
                  fontSize: 9.5,
                  color: _P.s400,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CheckP extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final path = Path()
      ..moveTo(w * 0.26, h * 0.52)
      ..lineTo(w * 0.44, h * 0.68)
      ..lineTo(w * 0.77, h * 0.32);
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.115
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// RIGHT FADE — dissolves into scaffold colour so login card blends in
// ─────────────────────────────────────────────────────────────────────────────
class _RightFade extends StatelessWidget {
  const _RightFade();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end:   Alignment.centerRight,
              colors: [
                Colors.transparent,
                Colors.transparent,
                Color(0x20f7f9fb),
                Color(0xDDf7f9fb),
                Color(0xFFf7f9fb),
              ],
              stops: [0.0, 0.50, 0.68, 0.85, 1.0],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TOP + BOTTOM SOFTENERS
// ─────────────────────────────────────────────────────────────────────────────
class _EdgeSoftener extends StatelessWidget {
  const _EdgeSoftener();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Column(
          children: [
            // Top fade
            Container(
              height: 80,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end:   Alignment.bottomCenter,
                  colors: [Color(0xFFf7f9fb), Colors.transparent],
                ),
              ),
            ),
            const Spacer(),
            // Bottom fade
            Container(
              height: 80,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end:   Alignment.topCenter,
                  colors: [Color(0xFFf7f9fb), Colors.transparent],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
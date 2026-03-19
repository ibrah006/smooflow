// ─────────────────────────────────────────────────────────────────────────────
// REPORTS SKELETON
//
// Drop-in replacement for the CircularProgressIndicator in
// DesktopReportsScreen.build(). Mirrors the exact layout of _ReportsBody
// so there is zero layout shift when real data replaces it.
//
// Usage — in _MaterialReportsScreenState.build(), replace:
//
//   _loading
//     ? const Center(child: CircularProgressIndicator(...))
//     : _ReportsBody(...)
//
// with:
//
//   _loading
//     ? const _ReportsSkeleton()
//     : _ReportsBody(...)
// ─────────────────────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────────────────────
// SHIMMER ANIMATION ENGINE
//
// A single AnimationController drives a shared gradient that sweeps left→right
// across every skeleton bone. All bones share one controller via an
// InheritedWidget so there's exactly one ticker in the tree regardless of
// how many bones are rendered.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

class _ShimmerScope extends StatefulWidget {
  final Widget child;
  const _ShimmerScope({required this.child});

  @override
  State<_ShimmerScope> createState() => _ShimmerScopeState();
}

class _ShimmerScopeState extends State<_ShimmerScope>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _ShimmerInherit(controller: _ctrl, child: widget.child);
}

class _ShimmerInherit extends InheritedWidget {
  final AnimationController controller;
  const _ShimmerInherit({required this.controller, required super.child});

  static AnimationController of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_ShimmerInherit>()!
        .controller;
  }

  @override
  bool updateShouldNotify(_ShimmerInherit old) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// BONE — a single shimmer rectangle
//
// width / height fully configurable. borderRadius defaults to 6.
// ─────────────────────────────────────────────────────────────────────────────
class _Bone extends StatelessWidget {
  final double width;
  final double height;
  final double radius;
  final bool expand; // fills parent width when true

  const _Bone({
    this.width = double.infinity,
    required this.height,
    this.radius = 6,
    this.expand = false,
  });

  @override
  Widget build(BuildContext context) {
    final ctrl = _ShimmerInherit.of(context);
    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, __) {
        final t = ctrl.value; // 0 → 1

        // Gradient sweeps from left-of-widget to right-of-widget
        final gradient = LinearGradient(
          begin: Alignment(-2 + t * 4, 0),
          end: Alignment(-1 + t * 4, 0),
          colors: const [
            Color(0xFFE2E8F0), // slate200 base
            Color(0xFFF1F5F9), // slate100 highlight
            Color(0xFFE2E8F0), // slate200 base
          ],
          stops: const [0.0, 0.5, 1.0],
        );

        return Container(
          width: expand ? double.infinity : width,
          height: height,
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(radius),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TOP-LEVEL SKELETON — matches _ReportsBody layout exactly
// ─────────────────────────────────────────────────────────────────────────────
class ReportsSkeleton extends StatelessWidget {
  const ReportsSkeleton();

  @override
  Widget build(BuildContext context) {
    return _ShimmerScope(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── KPI row — 4 cards ────────────────────────────────────────
            Row(
              children: List.generate(
                4,
                (i) => Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: i < 3 ? 12 : 0),
                    child: const _SkeletonKpiCard(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Row 1: Monthly trend (3/5) + Donut (2/5) ────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: _SkeletonCard(child: _SkeletonLineChart()),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: _SkeletonCard(child: _SkeletonDonut()),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Row 2: By Project + By Client ───────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _SkeletonCard(child: _SkeletonBarList(rows: 6)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _SkeletonCard(child: _SkeletonBarList(rows: 5)),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Avg per job ──────────────────────────────────────────────
            _SkeletonCard(child: _SkeletonTableRows(rows: 5)),
            const SizedBox(height: 16),

            // ── Stock health ─────────────────────────────────────────────
            _SkeletonCard(child: _SkeletonStockHealth(rows: 6)),
            const SizedBox(height: 16),

            // ── Top jobs table ────────────────────────────────────────────
            _SkeletonCard(child: _SkeletonTableRows(rows: 8, hasHeader: true)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// KPI CARD SKELETON
// ─────────────────────────────────────────────────────────────────────────────
class _SkeletonKpiCard extends StatelessWidget {
  const _SkeletonKpiCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon badge
          const _Bone(width: 34, height: 34, radius: 8),
          const SizedBox(height: 14),
          // Big number
          const _Bone(width: 80, height: 28, radius: 5),
          const SizedBox(height: 8),
          // Label
          const _Bone(width: 100, height: 13, radius: 4),
          const SizedBox(height: 5),
          // Sub
          const _Bone(width: 120, height: 11, radius: 4),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CARD SHELL SKELETON — mirrors _Card header + divider
// ─────────────────────────────────────────────────────────────────────────────
class _SkeletonCard extends StatelessWidget {
  final Widget child;
  const _SkeletonCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header: icon badge + two text lines
          Row(
            children: const [
              _Bone(width: 28, height: 28, radius: 7),
              SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Bone(width: 160, height: 13, radius: 4),
                  SizedBox(height: 5),
                  _Bone(width: 220, height: 10, radius: 4),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LINE CHART SKELETON — legend chips + axis + line area
// ─────────────────────────────────────────────────────────────────────────────
class _SkeletonLineChart extends StatelessWidget {
  const _SkeletonLineChart();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Legend chips row
        Row(
          children: List.generate(
            4,
            (i) => Padding(
              padding: EdgeInsets.only(right: i < 3 ? 8 : 0),
              child: const _Bone(width: 72, height: 26, radius: 20),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Chart area
        SizedBox(
          height: 180,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Y-axis labels
              SizedBox(
                width: 42,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(
                    5,
                    (_) => const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: _Bone(width: 28, height: 9, radius: 3),
                    ),
                  ),
                ),
              ),
              // Chart area — a rounded rect with horizontal grid stubs
              Expanded(
                child: Stack(
                  children: [
                    // Grid lines
                    Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(
                        5,
                        (_) => Container(
                          height: 1,
                          color: const Color(0xFFF1F5F9),
                        ),
                      ),
                    ),
                    // Fake "line" bones — 3 wavy-ish rectangles at different heights
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 40,
                      child: const _Bone(height: 6, radius: 3),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 90,
                      child: const _Bone(height: 6, radius: 3),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 130,
                      child: const _Bone(height: 6, radius: 3),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // X-axis month labels
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(left: 42),
          child: Row(
            children: List.generate(
              12,
              (i) => Expanded(
                child: Center(child: _Bone(width: 18, height: 9, radius: 3)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DONUT SKELETON — circle + ranked bar list
// ─────────────────────────────────────────────────────────────────────────────
class _SkeletonDonut extends StatelessWidget {
  const _SkeletonDonut();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Donut ring
        const _Bone(width: 150, height: 150, radius: 75),
        const SizedBox(height: 16),
        // Ranked rows
        ...List.generate(
          5,
          (i) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const _Bone(width: 8, height: 8, radius: 4),
                    const SizedBox(width: 7),
                    _Bone(width: 80 + (i % 3) * 20.0, height: 11, radius: 4),
                    const Spacer(),
                    const _Bone(width: 40, height: 11, radius: 4),
                    const SizedBox(width: 8),
                    const _Bone(width: 28, height: 11, radius: 4),
                  ],
                ),
                const SizedBox(height: 5),
                const _Bone(height: 4, radius: 2, expand: true),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HORIZONTAL BAR LIST SKELETON — project / client bars
// ─────────────────────────────────────────────────────────────────────────────
class _SkeletonBarList extends StatelessWidget {
  final int rows;
  const _SkeletonBarList({required this.rows});

  // Vary bar widths so it doesn't look like a grid
  static const _fracs = [0.85, 0.60, 0.72, 0.45, 0.90, 0.55, 0.38, 0.68];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        rows,
        (i) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              const _Bone(width: 8, height: 8, radius: 4),
              const SizedBox(width: 8),
              const _Bone(width: 90, height: 13, radius: 4),
              const SizedBox(width: 8),
              Expanded(
                child: LayoutBuilder(
                  builder:
                      (_, c) => Stack(
                        children: [
                          Container(
                            height: 24,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          _Bone(
                            width: c.maxWidth * _fracs[i % _fracs.length],
                            height: 24,
                            radius: 5,
                          ),
                        ],
                      ),
                ),
              ),
              const SizedBox(width: 6),
              const _Bone(width: 15, height: 15, radius: 4),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STOCK HEALTH SKELETON — label + progress bar per row
// ─────────────────────────────────────────────────────────────────────────────
class _SkeletonStockHealth extends StatelessWidget {
  final int rows;
  const _SkeletonStockHealth({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        rows,
        (_) => Padding(
          padding: const EdgeInsets.only(bottom: 11),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const _Bone(width: 28, height: 18, radius: 4),
                  const SizedBox(width: 8),
                  const _Bone(width: 110, height: 13, radius: 4),
                  const Spacer(),
                  const _Bone(width: 80, height: 11, radius: 4),
                ],
              ),
              const SizedBox(height: 6),
              const _Bone(height: 8, radius: 4, expand: true),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TABLE ROWS SKELETON — efficiency + top jobs table
// ─────────────────────────────────────────────────────────────────────────────
class _SkeletonTableRows extends StatelessWidget {
  final int rows;
  final bool hasHeader;
  const _SkeletonTableRows({required this.rows, this.hasHeader = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasHeader) ...[
          // Column header row
          Row(
            children: List.generate(
              5,
              (i) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i < 4 ? 12 : 0),
                  child: const _Bone(height: 9, radius: 3),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 6),
        ],
        ...List.generate(
          rows,
          (i) => Container(
            margin: const EdgeInsets.only(bottom: 5),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color:
                  i % 2 == 0
                      ? const Color(0xFFF8FAFC)
                      : const Color(0xFFFFFFFF),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Row(
              children: [
                const _Bone(width: 7, height: 7, radius: 4),
                const SizedBox(width: 7),
                // Vary widths slightly per row
                Expanded(
                  flex: 3,
                  child: _Bone(
                    width: 90 + (i % 3) * 20.0,
                    height: 12,
                    radius: 4,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: _Bone(width: 50, height: 12, radius: 4),
                ),
                Expanded(
                  flex: 2,
                  child: _Bone(width: 60, height: 12, radius: 4),
                ),
                Expanded(
                  flex: 2,
                  child: _Bone(width: 55, height: 12, radius: 4),
                ),
                Expanded(
                  flex: 3,
                  child: _Bone(
                    width: 80 + (i % 2) * 30.0,
                    height: 6,
                    radius: 3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

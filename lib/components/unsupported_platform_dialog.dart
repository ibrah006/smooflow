// ─────────────────────────────────────────────────────────────────────────────
// unsupported_platform_dialog.dart
//
// Shows an informative, friendly dialog when a user's role is not supported
// on the platform they logged in from.
//
// Usage — call this right after login resolves and you know the platform:
//
//   import 'package:flutter/foundation.dart' show kIsWeb;
//   import 'package:smooflow/components/unsupported_platform_dialog.dart';
//
//   // Detect current platform
//   final platform = kIsWeb
//       ? SmooflowPlatform.desktop
//       : SmooflowPlatform.mobile;
//
//   // e.g. an "admin" or "manager" just logged in on mobile
//   UnsupportedPlatformDialog.show(
//     context: context,
//     userRole: 'Admin',
//     currentPlatform: platform,
//     onDismiss: () => LoginService.logout(),   // or Navigator.pop, etc.
//   );
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PLATFORM ENUM
// ─────────────────────────────────────────────────────────────────────────────
enum SmooflowPlatform { mobile, desktop }

// ─────────────────────────────────────────────────────────────────────────────
// DIALOG  (stateless — animation is handled by showGeneralDialog)
// ─────────────────────────────────────────────────────────────────────────────
class UnsupportedPlatformDialog extends StatefulWidget {
  final String userRole;
  final SmooflowPlatform currentPlatform;
  final VoidCallback? onDismiss;

  const UnsupportedPlatformDialog({
    super.key,
    required this.userRole,
    required this.currentPlatform,
    this.onDismiss,
  });

  // ── Static launcher ───────────────────────────────────────────────────────
  static Future<void> show({
    required BuildContext context,
    required String userRole,
    required SmooflowPlatform currentPlatform,
    VoidCallback? onDismiss,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Unsupported platform',
      barrierColor: Colors.black.withOpacity(0.35),
      transitionDuration: const Duration(milliseconds: 320),
      transitionBuilder: (ctx, anim, _, child) {
        final curved = CurvedAnimation(
          parent: anim,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
      pageBuilder: (ctx, _, __) => UnsupportedPlatformDialog(
        userRole:        userRole,
        currentPlatform: currentPlatform,
        onDismiss:       onDismiss,
      ),
    );
  }

  @override
  State<UnsupportedPlatformDialog> createState() =>
      _UnsupportedPlatformDialogState();
}

class _UnsupportedPlatformDialogState
    extends State<UnsupportedPlatformDialog>
    with SingleTickerProviderStateMixin {

  // Staggered content reveal
  late final AnimationController _stagger = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );

  @override
  void initState() {
    super.initState();
    // Small delay so the dialog scale animation completes first
    Future.delayed(const Duration(milliseconds: 160), () {
      if (mounted) _stagger.forward();
    });
  }

  @override
  void dispose() {
    _stagger.dispose();
    super.dispose();
  }

  Animation<double> _fade(double start, double end) => CurvedAnimation(
    parent: _stagger,
    curve: Interval(start, end, curve: Curves.easeOut),
  );

  Animation<Offset> _slide(double start, double end) =>
    Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _stagger,
        curve: Interval(start, end, curve: Curves.easeOutCubic),
      ),
    );

  // ── Copy logic ─────────────────────────────────────────────────────────
  SmooflowPlatform get _requiredPlatform =>
    widget.currentPlatform == SmooflowPlatform.mobile
        ? SmooflowPlatform.desktop
        : SmooflowPlatform.mobile;

  String get _requiredPlatformLabel =>
    _requiredPlatform == SmooflowPlatform.desktop ? 'Desktop' : 'Mobile';

  String get _currentPlatformLabel =>
    widget.currentPlatform == SmooflowPlatform.desktop ? 'Desktop' : 'Mobile';

  IconData get _requiredIcon =>
    _requiredPlatform == SmooflowPlatform.desktop
        ? Icons.laptop_mac_outlined
        : Icons.phone_iphone_outlined;

  IconData get _currentIcon =>
    widget.currentPlatform == SmooflowPlatform.desktop
        ? Icons.laptop_mac_outlined
        : Icons.phone_iphone_outlined;

  // Role-specific copy
  String get _headline => 'Desktop access required';

  String get _bodyText {
    final role     = widget.userRole;
    final required = _requiredPlatformLabel.toLowerCase();
    final current  = _currentPlatformLabel.toLowerCase();
    return 'Your $role account is only available on $required. '
        'You\'re currently signed in on $current, which doesn\'t '
        'support the tools and views your role needs.';
  }

  String get _instructionText {
    final required = _requiredPlatformLabel;
    if (_requiredPlatform == SmooflowPlatform.desktop) {
      return 'Open smooflow on a computer or laptop to access your $required workspace.';
    } else {
      return 'Download the smooflow mobile app to access your $required workspace.';
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 40,
                  offset: const Offset(0, 16),
                  spreadRadius: -4,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [

                  // ── Hero illustration strip ─────────────────────────
                  _HeroStrip(
                    currentPlatform:  widget.currentPlatform,
                    requiredPlatform: _requiredPlatform,
                    currentIcon:      _currentIcon,
                    requiredIcon:      _requiredIcon,
                    stagger:          _stagger,
                  ),

                  // ── Body ─────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
                    child: AnimatedBuilder(
                      animation: _stagger,
                      builder: (_, __) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          // Role badge + headline
                          FadeTransition(
                            opacity: _fade(0.0, 0.5),
                            child: SlideTransition(
                              position: _slide(0.0, 0.5),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Role badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEEF4FF),
                                      borderRadius: BorderRadius.circular(99),
                                      border: Border.all(
                                        color: const Color(0xFF3b72e3)
                                            .withOpacity(0.25),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 6, height: 6,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF3b72e3),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          widget.userRole,
                                          style: const TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF3b72e3),
                                            letterSpacing: 0.1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  // Headline
                                  Text(
                                    _headline,
                                    style: textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF1E293B),
                                      letterSpacing: -0.4,
                                      height: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Body copy
                          FadeTransition(
                            opacity: _fade(0.15, 0.60),
                            child: SlideTransition(
                              position: _slide(0.15, 0.60),
                              child: Text(
                                _bodyText,
                                style: const TextStyle(
                                  fontSize: 14,
                                  height: 1.6,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Instruction card
                          FadeTransition(
                            opacity: _fade(0.28, 0.72),
                            child: SlideTransition(
                              position: _slide(0.28, 0.72),
                              child: _InstructionCard(
                                icon:   _requiredIcon,
                                label:  _requiredPlatformLabel,
                                text:   _instructionText,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Actions ───────────────────────────────────────────
                  AnimatedBuilder(
                    animation: _stagger,
                    builder: (_, __) => FadeTransition(
                      opacity: _fade(0.45, 1.0),
                      child: SlideTransition(
                        position: _slide(0.45, 1.0),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(28, 20, 28, 28),
                          child: Row(
                            children: [
                              // Secondary — sign out
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    widget.onDismiss?.call();
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF64748B),
                                    side: const BorderSide(
                                      color: Color(0xFFe7eaf0),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 13),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: const Text(
                                    'Sign out',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),

                              // Primary — understood
                              Expanded(
                                flex: 2,
                                child: FilledButton.icon(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    widget.onDismiss?.call();
                                  },
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFF3b72e3),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 13),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  icon: Icon(
                                    _requiredIcon,
                                    size: 16,
                                  ),
                                  label: Text(
                                    'Open on $_requiredPlatformLabel',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HERO STRIP — visual showing the "blocked" current → required flow
// ─────────────────────────────────────────────────────────────────────────────
class _HeroStrip extends StatelessWidget {
  final SmooflowPlatform currentPlatform;
  final SmooflowPlatform requiredPlatform;
  final IconData currentIcon;
  final IconData requiredIcon;
  final AnimationController stagger;

  const _HeroStrip({
    required this.currentPlatform,
    required this.requiredPlatform,
    required this.currentIcon,
    required this.requiredIcon,
    required this.stagger,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 148,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end:   Alignment.bottomRight,
          colors: [
            Color(0xFFf0f5ff),
            Color(0xFFe8f0fe),
            Color(0xFFf4f7fb),
          ],
        ),
        border: Border(
          bottom: BorderSide(color: Color(0xFFe7eaf0)),
        ),
      ),
      child: Stack(
        children: [
          // Decorative grid dots
          Positioned.fill(
            child: CustomPaint(painter: _DotGridPainter()),
          ),

          // Content
          Center(
            child: AnimatedBuilder(
              animation: stagger,
              builder: (_, __) {
                final t = CurvedAnimation(
                  parent: stagger,
                  curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
                );
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [

                    // Current platform — dimmed / blocked
                    FadeTransition(
                      opacity: Tween<double>(begin: 0, end: 1).animate(t),
                      child: _PlatformNode(
                        icon:    currentIcon,
                        label:   currentPlatform == SmooflowPlatform.desktop
                            ? 'Desktop' : 'Mobile',
                        blocked: true,
                      ),
                    ),

                    // Arrow with "no access" line
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: FadeTransition(
                        opacity: Tween<double>(begin: 0, end: 1).animate(
                          CurvedAnimation(
                            parent: stagger,
                            curve: const Interval(0.2, 0.7,
                                curve: Curves.easeOut),
                          ),
                        ),
                        child: const _BlockedArrow(),
                      ),
                    ),

                    // Required platform — highlighted
                    FadeTransition(
                      opacity: Tween<double>(begin: 0, end: 1).animate(
                        CurvedAnimation(
                          parent: stagger,
                          curve: const Interval(0.3, 0.75,
                              curve: Curves.easeOutCubic),
                        ),
                      ),
                      child: _PlatformNode(
                        icon:    requiredIcon,
                        label:   requiredPlatform == SmooflowPlatform.desktop
                            ? 'Desktop' : 'Mobile',
                        blocked: false,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PLATFORM NODE
// ─────────────────────────────────────────────────────────────────────────────
class _PlatformNode extends StatelessWidget {
  final IconData icon;
  final String   label;
  final bool     blocked;

  const _PlatformNode({
    required this.icon,
    required this.label,
    required this.blocked,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = blocked
        ? const Color(0xFF94A3B8)
        : const Color(0xFF3b72e3);
    final bgColor = blocked
        ? const Color(0xFFF1F5F9)
        : const Color(0xFFEEF4FF);
    final borderColor = blocked
        ? const Color(0xFFE2E8F0)
        : const Color(0xFF3b72e3).withOpacity(0.3);
    final labelColor = blocked
        ? const Color(0xFF94A3B8)
        : const Color(0xFF3b72e3);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            // Icon container
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor, width: 1.5),
                boxShadow: blocked ? null : [
                  BoxShadow(
                    color: const Color(0xFF3b72e3).withOpacity(0.18),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, size: 26, color: iconColor),
            ),

            // Blocked badge
            if (blocked)
              Positioned(
                top: -5, right: -5,
                child: Container(
                  width: 20, height: 20,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ),

            // Required badge
            if (!blocked)
              Positioned(
                top: -5, right: -5,
                child: Container(
                  width: 20, height: 20,
                  decoration: const BoxDecoration(
                    color: Color(0xFF3b72e3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: labelColor,
            letterSpacing: 0.1,
          ),
        ),
        Text(
          blocked ? 'Not supported' : 'Required',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: blocked
                ? const Color(0xFFEF4444)
                : const Color(0xFF3b72e3).withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BLOCKED ARROW — the connector between nodes
// ─────────────────────────────────────────────────────────────────────────────
class _BlockedArrow extends StatelessWidget {
  const _BlockedArrow();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Dashed line + arrow
          CustomPaint(
            size: const Size(48, 20),
            painter: _ArrowPainter(),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFFFCA5A5)),
            ),
            child: const Text(
              'blocked',
              style: TextStyle(
                fontSize: 8.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFFEF4444),
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Dashed line
    const dashW = 4.0, gapW = 3.0;
    double x = 0;
    final midY = size.height / 2;
    while (x < size.width - 10) {
      canvas.drawLine(Offset(x, midY), Offset(x + dashW, midY), paint);
      x += dashW + gapW;
    }

    // Arrow head
    final arrowPaint = Paint()
      ..color = const Color(0xFF94A3B8)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(size.width - 8, midY - 5)
      ..lineTo(size.width, midY)
      ..lineTo(size.width - 8, midY + 5);
    canvas.drawPath(path, arrowPaint);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// INSTRUCTION CARD
// ─────────────────────────────────────────────────────────────────────────────
class _InstructionCard extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   text;

  const _InstructionCard({
    required this.icon,
    required this.label,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFf7f9fb),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFe7eaf0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF4FF),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                color: const Color(0xFF3b72e3).withOpacity(0.2),
              ),
            ),
            child: Icon(icon, size: 18, color: const Color(0xFF3b72e3)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Switch to $label',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                    letterSpacing: 0.1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 12.5,
                    height: 1.5,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DOT GRID PAINTER — background decoration for hero strip
// ─────────────────────────────────────────────────────────────────────────────
class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const step = 20.0;
    final paint = Paint()..color = const Color(0xFF3b72e3).withOpacity(0.06);
    for (double x = step; x < size.width; x += step) {
      for (double y = step; y < size.height; y += step) {
        canvas.drawCircle(Offset(x, y), 1.2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
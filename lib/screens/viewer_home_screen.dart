// ─────────────────────────────────────────────────────────────────────────────
// viewer_pending_screen.dart
//
// Shown to users whose organisation membership is approved but whose role
// has not yet been assigned by an admin.
//
// What it shows:
//   • Warm welcome + their profile (name, email, org)
//   • A 3-step onboarding progress track so they understand exactly where
//     they are in the process (Joined → Role Pending → Active)
//   • A "What happens next" card explaining the process clearly
//   • Refresh button to poll for a role update
//   • Sign-out via avatar tap (same pattern as delivery_dashboard_screen)
//
// Design: identical token system, topbar pattern, avatar menu, logo mark,
// pill badges, border/shadow conventions as every other smooflow screen.
//
// Usage — push immediately after login resolves if role == 'viewer' / null:
//   Navigator.pushAndRemoveUntil(
//     context,
//     MaterialPageRoute(builder: (_) => ViewerPendingScreen(
//       orgName: 'Harrington & Co',
//       onRoleAssigned: () { /* navigate to real dashboard */ },
//     )),
//     (_) => false,
//   );
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smooflow/core/app_routes.dart';
import 'package:smooflow/core/services/login_service.dart';
import 'package:smooflow/screens/login_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TOKENS — byte-for-byte match with every other smooflow screen
// ─────────────────────────────────────────────────────────────────────────────
class _T {
  static const blue      = Color(0xFF2563EB);
  static const blue50    = Color(0xFFEFF6FF);
  static const blue100   = Color(0xFFDBEAFE);
  static const teal      = Color(0xFF38BDF8);
  static const green     = Color(0xFF10B981);
  static const green50   = Color(0xFFECFDF5);
  static const amber     = Color(0xFFF59E0B);
  static const amber50   = Color(0xFFFEF3C7);
  static const red       = Color(0xFFEF4444);
  static const red50     = Color(0xFFFEE2E2);
  static const slate50   = Color(0xFFF8FAFC);
  static const slate100  = Color(0xFFF1F5F9);
  static const slate200  = Color(0xFFE2E8F0);
  static const slate300  = Color(0xFFCBD5E1);
  static const slate400  = Color(0xFF94A3B8);
  static const slate500  = Color(0xFF64748B);
  static const ink       = Color(0xFF0F172A);
  static const ink3      = Color(0xFF334155);
  static const white     = Colors.white;
  static const r         = 8.0;
  static const rLg       = 12.0;
  static const rXl       = 16.0;
}

// ─────────────────────────────────────────────────────────────────────────────
// ROOT SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class ViewerHomeScreen extends StatefulWidget {
  /// The name of the organisation this user has joined.

  /// Called when polling detects that a role has been assigned.
  /// Navigate to the appropriate dashboard here.
  final VoidCallback? onRoleAssigned;

  const ViewerHomeScreen({
    super.key,
    this.onRoleAssigned,
  });

  @override
  State<ViewerHomeScreen> createState() => _ViewerHomeScreenState();
}

class _ViewerHomeScreenState extends State<ViewerHomeScreen>
    with TickerProviderStateMixin {

  final orgName = "My Org";

  // Entry animation controller
  late final AnimationController _entry = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  // Pulse animation for the "pending" step indicator
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  // Spinner for refresh button
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _entry.forward();
  }

  @override
  void dispose() {
    _entry.dispose();
    _pulse.dispose();
    _spin.dispose();
    super.dispose();
  }

  Animation<double> _stagger(double s, double e) => CurvedAnimation(
    parent: _entry,
    curve: Interval(s, e, curve: Curves.easeOutCubic),
  );

  // ── Actions ────────────────────────────────────────────────────────────────
  Future<void> _refresh() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    HapticFeedback.selectionClick();
    _spin.repeat();

    // Replace with your real role-check call, e.g.:
    // final user = await ref.read(authProvider.notifier).refreshUser();
    // if (user.role != null && user.role != 'viewer') {
    //   widget.onRoleAssigned?.call();
    //   return;
    // }
    await Future.delayed(const Duration(milliseconds: 1400));

    _spin.stop();
    _spin.reset();
    if (mounted) setState(() => _refreshing = false);
  }

  Future<void> _signOut() async {
    await LoginService.logout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    }
  }

  void _openUserSheet() {
    final user = LoginService.currentUser;
    if (user == null) return;
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context:         context,
      backgroundColor: Colors.transparent,
      builder: (_) => _UserSheet(
        user:      user,
        orgName:   orgName,
        onSignOut: _signOut,
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final mq   = MediaQuery.of(context);
    final user = LoginService.currentUser;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: _T.slate50,
        body: Column(
          children: [
            // ── Status bar padding + topbar ──────────────────────────
            Container(
              color: _T.white,
              padding: EdgeInsets.only(top: mq.padding.top),
              child: _Topbar(
                user:        user,
                orgName:     orgName,
                onAvatarTap: _openUserSheet,
              ),
            ),

            // ── Scrollable body ───────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                    20, 24, 20, 24 + mq.padding.bottom),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // ── Hero welcome card ─────────────────────────────
                    _FadeSlide(
                      anim: _stagger(0.0, 0.5),
                      child: _WelcomeCard(
                        user:    user,
                        orgName: orgName,
                        pulse:   _pulse,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Onboarding progress track ─────────────────────
                    _FadeSlide(
                      anim: _stagger(0.12, 0.60),
                      child: _ProgressTrack(pulse: _pulse),
                    ),
                    const SizedBox(height: 16),

                    // ── What happens next ─────────────────────────────
                    _FadeSlide(
                      anim: _stagger(0.24, 0.72),
                      child: _WhatNextCard(),
                    ),
                    const SizedBox(height: 16),

                    // ── Organisation card ─────────────────────────────
                    _FadeSlide(
                      anim: _stagger(0.34, 0.82),
                      child: _OrgCard(orgName: orgName),
                    ),
                    const SizedBox(height: 28),

                    // ── Refresh CTA ───────────────────────────────────
                    _FadeSlide(
                      anim: _stagger(0.44, 0.92),
                      child: _RefreshButton(
                        refreshing: _refreshing,
                        spin:       _spin,
                        onTap:      _refresh,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ── Sign out (soft, secondary) ────────────────────
                    _FadeSlide(
                      anim: _stagger(0.50, 1.0),
                      child: Center(
                        child: TextButton(
                          onPressed: _signOut,
                          style: TextButton.styleFrom(
                            foregroundColor: _T.slate400,
                          ),
                          child: const Text(
                            'Sign out',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
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
// TOPBAR — identical to delivery_dashboard_screen._Topbar
// ─────────────────────────────────────────────────────────────────────────────
class _Topbar extends StatelessWidget {
  final dynamic      user;
  final String       orgName;
  final VoidCallback onAvatarTap;

  const _Topbar({
    required this.user,
    required this.orgName,
    required this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: const BoxDecoration(
        color: _T.white,
        border: Border(bottom: BorderSide(color: _T.slate200)),
      ),
      child: Row(
        children: [
          // Logo
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_T.blue, _T.teal],
                begin: Alignment.topLeft,
                end:   Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(child: _Logo(size: 17)),
          ),
          const SizedBox(width: 10),

          // Title area
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'smooflow',
                  style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w800,
                    color: _T.ink, letterSpacing: -0.4),
                ),
                Text(
                  orgName,
                  style: const TextStyle(
                    fontSize: 10.5, color: _T.slate400,
                    fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Pending badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _T.amber50,
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: _T.amber.withOpacity(0.35)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 5, height: 5,
                decoration: const BoxDecoration(
                    color: _T.amber, shape: BoxShape.circle),
              ),
              const SizedBox(width: 5),
              const Text(
                'Pending',
                style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w700,
                    color: _T.amber),
              ),
            ]),
          ),
          const SizedBox(width: 10),

          // Avatar
          if (user != null)
            GestureDetector(
              onTap: onAvatarTap,
              child: Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  color: _T.slate100,
                  shape: BoxShape.circle,
                  border: Border.all(color: _T.slate300, width: 1.5),
                ),
                child: Center(
                  child: Text(
                    _initials(user.initials as String),
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w800,
                        color: _T.slate500),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WELCOME HERO CARD
// ─────────────────────────────────────────────────────────────────────────────
class _WelcomeCard extends StatelessWidget {
  final dynamic  user;
  final String   orgName;
  final AnimationController pulse;

  const _WelcomeCard({
    required this.user,
    required this.orgName,
    required this.pulse,
  });

  @override
  Widget build(BuildContext context) {
    final name = user?.name as String? ?? 'there';
    final firstName = name.split(' ').first;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        // Subtle gradient header — same convention as login background
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end:   Alignment.bottomRight,
          colors: [Color(0xFFEFF6FF), Color(0xFFF0FDF4)],
        ),
        borderRadius: BorderRadius.circular(_T.rXl),
        border: Border.all(color: _T.slate200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: large avatar + org join badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Large avatar
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  color: _T.blue50,
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: _T.blue.withOpacity(0.25), width: 2),
                ),
                child: Center(
                  child: Text(
                    user != null
                        ? _initials(user.initials as String)
                        : '?',
                    style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800,
                      color: _T.blue, letterSpacing: -0.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome, $firstName!',
                      style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w800,
                        color: _T.ink, letterSpacing: -0.5, height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Org joined pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _T.green50,
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(
                            color: _T.green.withOpacity(0.3)),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.check_rounded,
                            size: 11, color: _T.green),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Joined $orgName',
                            style: const TextStyle(
                              fontSize: 10.5, fontWeight: FontWeight.w700,
                              color: _T.green,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: _T.slate200),
          const SizedBox(height: 14),

          // Status message
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pulsing amber dot
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: AnimatedBuilder(
                  animation: pulse,
                  builder: (_, __) => Container(
                    width: 9, height: 9,
                    decoration: BoxDecoration(
                      color: _T.amber
                          .withOpacity(0.5 + pulse.value * 0.5),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _T.amber.withOpacity(
                              0.2 + pulse.value * 0.3),
                          blurRadius: 6 + pulse.value * 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your role is being set up',
                      style: TextStyle(
                        fontSize: 13.5, fontWeight: FontWeight.w700,
                        color: _T.ink3),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'An admin is reviewing your account and will assign a role shortly. You\'ll have full access once that\'s done.',
                      style: TextStyle(
                        fontSize: 13, height: 1.55,
                        color: _T.slate500,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ONBOARDING PROGRESS TRACK
// ─────────────────────────────────────────────────────────────────────────────
class _ProgressTrack extends StatelessWidget {
  final AnimationController pulse;
  const _ProgressTrack({required this.pulse});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _T.white,
        borderRadius: BorderRadius.circular(_T.rXl),
        border: Border.all(color: _T.slate200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your onboarding',
            style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w700,
              color: _T.slate400, letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 16),

          // Steps
          _Step(
            index:  1,
            icon:   Icons.person_add_outlined,
            label:  'Request sent',
            sub:    'You applied to join the organisation',
            state:  _StepState.done,
            pulse:  pulse,
            isLast: false,
          ),
          _Step(
            index:  2,
            icon:   Icons.how_to_reg_outlined,
            label:  'User approved',
            sub:    'Your request was accepted',
            state:  _StepState.done,
            pulse:  pulse,
            isLast: false,
          ),
          _Step(
            index:  3,
            icon:   Icons.manage_accounts_outlined,
            label:  'Role assignment',
            sub:    'An admin is setting up your role',
            state:  _StepState.active,
            pulse:  pulse,
            isLast: false,
          ),
          _Step(
            index:  4,
            icon:   Icons.rocket_launch_outlined,
            label:  'You\'re all set',
            sub:    'Full access to your workspace',
            state:  _StepState.upcoming,
            pulse:  pulse,
            isLast: true,
          ),
        ],
      ),
    );
  }
}

enum _StepState { done, active, upcoming }

class _Step extends StatelessWidget {
  final int       index;
  final IconData  icon;
  final String    label, sub;
  final _StepState state;
  final AnimationController pulse;
  final bool      isLast;

  const _Step({
    required this.index, required this.icon, required this.label,
    required this.sub, required this.state, required this.pulse,
    required this.isLast,
  });

  Color get _color => switch (state) {
    _StepState.done     => _T.green,
    _StepState.active   => _T.amber,
    _StepState.upcoming => _T.slate300,
  };

  Color get _bg => switch (state) {
    _StepState.done     => _T.green50,
    _StepState.active   => _T.amber50,
    _StepState.upcoming => _T.slate100,
  };

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Left column: icon + connector line ───────────────────────
        Column(
          children: [
            // Icon circle
            if (state == _StepState.active)
              AnimatedBuilder(
                animation: pulse,
                builder: (_, child) => Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: _bg,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _color.withOpacity(
                          0.4 + pulse.value * 0.4),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _color.withOpacity(
                            0.12 + pulse.value * 0.18),
                        blurRadius: 10 + pulse.value * 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: child,
                ),
                child: Icon(
                  state == _StepState.done
                      ? Icons.check_rounded
                      : icon,
                  size: 18,
                  color: _color,
                ),
              )
            else
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: _bg,
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: _color.withOpacity(0.3), width: 1.5),
                ),
                child: Icon(
                  state == _StepState.done
                      ? Icons.check_rounded
                      : icon,
                  size: 18,
                  color: _color,
                ),
              ),

            // Connector line
            if (!isLast)
              Container(
                width: 1.5,
                height: 28,
                margin: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: state == _StepState.done
                      ? _T.green.withOpacity(0.35)
                      : _T.slate200,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
          ],
        ),
        const SizedBox(width: 14),

        // ── Right column: label + sub ────────────────────────────────
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(
                top: 8, bottom: isLast ? 0 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: state == _StepState.upcoming
                          ? FontWeight.w500
                          : FontWeight.w700,
                      color: state == _StepState.upcoming
                          ? _T.slate400
                          : _T.ink3,
                    ),
                  ),
                  if (state == _StepState.active) ...[
                    const SizedBox(width: 7),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: _T.amber50,
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(
                            color: _T.amber.withOpacity(0.4)),
                      ),
                      child: const Text(
                        'Now',
                        style: TextStyle(
                            fontSize: 9.5, fontWeight: FontWeight.w800,
                            color: _T.amber),
                      ),
                    ),
                  ],
                  if (state == _StepState.done) ...[
                    const SizedBox(width: 7),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: _T.green50,
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(
                            color: _T.green.withOpacity(0.3)),
                      ),
                      child: const Text(
                        'Done',
                        style: TextStyle(
                            fontSize: 9.5, fontWeight: FontWeight.w800,
                            color: _T.green),
                      ),
                    ),
                  ],
                ]),
                const SizedBox(height: 2),
                Text(
                  sub,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.45,
                    color: state == _StepState.upcoming
                        ? _T.slate300
                        : _T.slate500,
                    fontWeight: FontWeight.w400,
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

// ─────────────────────────────────────────────────────────────────────────────
// WHAT HAPPENS NEXT CARD
// ─────────────────────────────────────────────────────────────────────────────
class _WhatNextCard extends StatelessWidget {
  const _WhatNextCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _T.white,
        borderRadius: BorderRadius.circular(_T.rXl),
        border: Border.all(color: _T.slate200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: _T.blue50,
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(
                  Icons.info_outline_rounded, size: 16, color: _T.blue),
            ),
            const SizedBox(width: 10),
            const Text(
              'What happens next?',
              style: TextStyle(
                fontSize: 13.5, fontWeight: FontWeight.w700,
                color: _T.ink3),
            ),
          ]),
          const SizedBox(height: 14),
          const Divider(height: 1, color: _T.slate100),
          const SizedBox(height: 14),

          // Items
          _NextItem(
            icon:  Icons.notifications_outlined,
            title: 'You\'ll be notified',
            body:  'As soon as an admin assigns your role, you\'ll be able to access your full workspace automatically.',
          ),
          const SizedBox(height: 12),
          _NextItem(
            icon:  Icons.lock_open_outlined,
            title: 'No action required',
            body:  'You don\'t need to do anything. Just check back here or tap Refresh to see if your role has been set.',
          ),
          const SizedBox(height: 12),
          _NextItem(
            icon:  Icons.support_agent_outlined,
            title: 'Questions?',
            body:  'Contact your organisation admin directly if you believe there\'s been a delay.',
          ),
        ],
      ),
    );
  }
}

class _NextItem extends StatelessWidget {
  final IconData icon;
  final String   title, body;
  const _NextItem({
    required this.icon, required this.title, required this.body});

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 30, height: 30,
        decoration: BoxDecoration(
          color: _T.slate100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 15, color: _T.slate500),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 12.5, fontWeight: FontWeight.w700,
                    color: _T.ink3)),
            const SizedBox(height: 2),
            Text(body,
                style: const TextStyle(
                    fontSize: 12, height: 1.5,
                    color: _T.slate500,
                    fontWeight: FontWeight.w400)),
          ],
        ),
      ),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// ORGANISATION CARD
// ─────────────────────────────────────────────────────────────────────────────
class _OrgCard extends StatelessWidget {
  final String orgName;
  const _OrgCard({required this.orgName});

  @override
  Widget build(BuildContext context) {
    final user = LoginService.currentUser;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _T.white,
        borderRadius: BorderRadius.circular(_T.rXl),
        border: Border.all(color: _T.slate200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(children: [
        // Org logo placeholder
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: _T.slate100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _T.slate200),
          ),
          child: Center(
            child: Text(
              orgName.isNotEmpty ? orgName[0].toUpperCase() : 'O',
              style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.w800,
                color: _T.slate500),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                orgName,
                style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700,
                  color: _T.ink, letterSpacing: -0.2),
              ),
              const SizedBox(height: 3),
              if (user != null)
                Text(
                  user.email as String,
                  style: const TextStyle(
                    fontSize: 11.5, color: _T.slate400,
                    fontWeight: FontWeight.w400),
                ),
            ],
          ),
        ),
        // Membership confirmed pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: _T.green50,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: _T.green.withOpacity(0.3)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.check_rounded, size: 11, color: _T.green),
            const SizedBox(width: 4),
            const Text(
              'Member',
              style: TextStyle(
                fontSize: 10.5, fontWeight: FontWeight.w700,
                color: _T.green),
            ),
          ]),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// REFRESH BUTTON
// ─────────────────────────────────────────────────────────────────────────────
class _RefreshButton extends StatelessWidget {
  final bool              refreshing;
  final AnimationController spin;
  final VoidCallback      onTap;

  const _RefreshButton({
    required this.refreshing,
    required this.spin,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color:        Colors.transparent,
      borderRadius: BorderRadius.circular(_T.rLg),
      child: InkWell(
        onTap:        refreshing ? null : onTap,
        borderRadius: BorderRadius.circular(_T.rLg),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width:   double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            color: refreshing ? _T.slate100 : _T.blue,
            borderRadius: BorderRadius.circular(_T.rLg),
            boxShadow: refreshing ? null : [
              BoxShadow(
                color: _T.blue.withOpacity(0.25),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Spinning refresh icon
              AnimatedBuilder(
                animation: spin,
                builder: (_, child) => Transform.rotate(
                  angle: spin.value * math.pi * 2,
                  child: child,
                ),
                child: Icon(
                  Icons.refresh_rounded,
                  size: 18,
                  color: refreshing ? _T.slate400 : Colors.white,
                ),
              ),
              const SizedBox(width: 9),
              Text(
                refreshing ? 'Checking…' : 'Check for role update',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: refreshing ? _T.slate400 : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// USER SHEET — same as delivery_dashboard_screen._UserSheet
// ─────────────────────────────────────────────────────────────────────────────
class _UserSheet extends StatelessWidget {
  final dynamic      user;
  final String       orgName;
  final VoidCallback onSignOut;

  const _UserSheet({
    required this.user,
    required this.orgName,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return Container(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + mq.padding.bottom),
      decoration: const BoxDecoration(
        color: _T.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 14),
              width: 36, height: 4,
              decoration: BoxDecoration(
                  color: _T.slate200,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),

          // Profile row
          Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Container(
              width: 50, height: 50,
              decoration: BoxDecoration(
                color: _T.slate100,
                shape: BoxShape.circle,
                border: Border.all(color: _T.slate300, width: 2),
              ),
              child: Center(
                child: Text(
                  _initials(user.initials as String),
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w800,
                      color: _T.slate500),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.name as String,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700,
                          color: _T.ink, letterSpacing: -0.2)),
                  const SizedBox(height: 2),
                  Text(user.email as String,
                      style: const TextStyle(
                          fontSize: 12, color: _T.slate400)),
                ],
              ),
            ),
            // Viewer / pending badge
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: _T.amber50,
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: _T.amber.withOpacity(0.3)),
              ),
              child: const Text(
                'VIEWER',
                style: TextStyle(
                    fontSize: 9.5, fontWeight: FontWeight.w700,
                    color: _T.amber, letterSpacing: 0.5),
              ),
            ),
          ]),
          const SizedBox(height: 12),

          // Org row
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: _T.slate50,
              borderRadius: BorderRadius.circular(_T.rLg),
              border: Border.all(color: _T.slate200),
            ),
            child: Row(children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: _T.slate100,
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(color: _T.slate200),
                ),
                child: Center(
                  child: Text(
                    orgName.isNotEmpty ? orgName[0].toUpperCase() : 'O',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w800,
                        color: _T.slate500),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(orgName,
                        style: const TextStyle(
                            fontSize: 12.5, fontWeight: FontWeight.w600,
                            color: _T.ink3),
                        overflow: TextOverflow.ellipsis),
                    const Text('Member · Role pending',
                        style: TextStyle(
                            fontSize: 11, color: _T.slate400)),
                  ],
                ),
              ),
              Container(
                width: 6, height: 6,
                decoration: const BoxDecoration(
                    color: _T.amber, shape: BoxShape.circle),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: _T.slate100),
          const SizedBox(height: 12),

          // Sign out
          Material(
            color: _T.red50,
            borderRadius: BorderRadius.circular(_T.rLg),
            child: InkWell(
              onTap: () async {
                Navigator.of(context).pop();
                onSignOut();

                await LoginService.logout();

                AppRoutes.navigateAndRemoveUntil(context, AppRoutes.login);
              },
              borderRadius: BorderRadius.circular(_T.rLg),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(_T.rLg),
                  border: Border.all(color: _T.red.withOpacity(0.2)),
                ),
                child: Row(children: [
                  const Icon(Icons.logout_rounded,
                      size: 18, color: _T.red),
                  const SizedBox(width: 12),
                  const Text('Sign out',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600,
                          color: _T.red)),
                  const Spacer(),
                  Icon(Icons.arrow_forward_ios_rounded,
                      size: 12,
                      color: _T.red.withOpacity(0.5)),
                ]),
              ),
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ANIMATION WRAPPER
// ─────────────────────────────────────────────────────────────────────────────
class _FadeSlide extends StatelessWidget {
  final Animation<double> anim;
  final Widget            child;
  const _FadeSlide({required this.anim, required this.child});

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: anim,
    child: child,
    builder: (_, c) => FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.06), end: Offset.zero,
        ).animate(anim),
        child: c,
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// LOGO — identical to every other screen in the project
// ─────────────────────────────────────────────────────────────────────────────
class _Logo extends StatelessWidget {
  final double size;
  const _Logo({required this.size});
  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size(size, size), painter: _LogoPainter());
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final p = Paint()..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.19, h * 0.66), w * 0.065,
        p..color = Colors.white.withOpacity(0.5));
    canvas.drawCircle(Offset(w * 0.48, h * 0.34), w * 0.065,
        p..color = Colors.white.withOpacity(0.7));
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.19, h * 0.66)
        ..cubicTo(w * 0.19, h * 0.66, w * 0.30, h * 0.34, w * 0.48, h * 0.34)
        ..cubicTo(w * 0.66, h * 0.34, w * 0.64, h * 0.66, w * 0.81, h * 0.55),
      Paint()
        ..color = Colors.white.withOpacity(0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.055
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.35, h * 0.51)
        ..lineTo(w * 0.48, h * 0.65)
        ..lineTo(w * 0.81, h * 0.33),
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.077
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }
  @override
  bool shouldRepaint(_) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────────────────────────────────────────
String _initials(String raw) {
  final parts = raw.trim().split(RegExp(r'\s+'));
  if (parts.length >= 2) {
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
  return raw.isNotEmpty ? raw[0].toUpperCase() : '?';
}
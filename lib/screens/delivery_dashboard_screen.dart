// ─────────────────────────────────────────────────────────────────────────────
// delivery_dashboard_screen.dart
//
// Mobile dashboard for the smooflow Delivery department.
//
// What it does:
//   • Watches TaskStatus.delivery → shown in Queue tab (urgent-first sort)
//   • Watches TaskStatus.delivered → shown in Done tab
//   • Swipe right on any queue card → triggers delivery confirmation
//   • Tap "Mark Delivered" button → same bottom-sheet confirmation
//   • Skeleton shimmer while data loads on first open
//   • Staggered fade-slide card entry animation
//   • Pull-to-refresh with haptic feedback
//   • Tap avatar → user sheet with sign-out
//
// Design: token-identical to admin_desktop_dashboard.dart.
//   slate50 canvas · white cards · blue primary · ink dark · same radii/shadows
//
// Usage:
//   Navigator.pushAndRemoveUntil(
//     context,
//     MaterialPageRoute(builder: (_) => const DeliveryDashboardScreen()),
//     (_) => false,
//   );
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/components/logo.dart';
import 'package:smooflow/core/models/project.dart';
import 'package:smooflow/core/models/task.dart';
import 'package:smooflow/core/services/login_service.dart';
import 'package:smooflow/enums/task_priority.dart';
import 'package:smooflow/enums/task_status.dart';
import 'package:smooflow/providers/project_provider.dart';
import 'package:smooflow/providers/task_provider.dart';
import 'package:smooflow/screens/login_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TOKENS — byte-for-byte match with admin_desktop_dashboard.dart
// ─────────────────────────────────────────────────────────────────────────────
class _T {
  static const blue      = Color(0xFF2563EB);
  static const blue50    = Color(0xFFEFF6FF);
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
// PRIORITY HELPERS
// ─────────────────────────────────────────────────────────────────────────────
Color  _priColor(TaskPriority p) => switch (p) {
  TaskPriority.urgent => _T.red,
  TaskPriority.high   => _T.amber,
  TaskPriority.normal => _T.slate300,
};
Color  _priBg(TaskPriority p) => switch (p) {
  TaskPriority.urgent => _T.red50,
  TaskPriority.high   => _T.amber50,
  TaskPriority.normal => _T.slate100,
};
String _priLabel(TaskPriority p) => switch (p) {
  TaskPriority.urgent => 'Urgent',
  TaskPriority.high   => 'High',
  TaskPriority.normal => 'Normal',
};
int _priOrder(TaskPriority p) => switch (p) {
  TaskPriority.urgent => 0,
  TaskPriority.high   => 1,
  TaskPriority.normal => 2,
};

// ─────────────────────────────────────────────────────────────────────────────
// ROOT SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class DeliveryDashboardScreen extends ConsumerStatefulWidget {
  const DeliveryDashboardScreen({super.key});

  @override
  ConsumerState<DeliveryDashboardScreen> createState() =>
      _DeliveryDashboardScreenState();
}

class _DeliveryDashboardScreenState
    extends ConsumerState<DeliveryDashboardScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);
  bool _loading    = true;
  bool _refreshing = false;

  // ── Derived lists ──────────────────────────────────────────────────────────
  List<Task> get _queue =>
      ref.watch(taskNotifierProvider).tasks
          .where((t) => t.status == TaskStatus.delivery)
          .toList()
        ..sort((a, b) {
          final po = _priOrder(a.priority).compareTo(_priOrder(b.priority));
          if (po != 0) return po;
          if (a.dueDate != null && b.dueDate != null) {
            return a.dueDate!.compareTo(b.dueDate!);
          }
          return 0;
        });

  List<Task> get _done =>
      ref.watch(taskNotifierProvider).tasks
          .where((t) => t.status == TaskStatus.delivery)
          .toList()
        ..sort((a, b) =>
            (b.dueDate ?? DateTime(0)).compareTo(a.dueDate ?? DateTime(0)));

  List<Project> get _projects => ref.watch(projectNotifierProvider);

  Project? _proj(String? id) => id == null
      ? null
      : _projects.cast<Project?>()
            .firstWhere((p) => p?.id == id, orElse: () => null);

  // ── Lifecycle ──────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    await Future.wait([
      ref.read(taskNotifierProvider.notifier).loadAll(),
      ref.read(projectNotifierProvider.notifier)
          .load(projectsLastAddedLocal: null),
    ]);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _refresh() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    HapticFeedback.selectionClick();
    await _load();
    if (mounted) setState(() => _refreshing = false);
  }

  // ── Deliver ────────────────────────────────────────────────────────────────
  void _openSheet(Task task) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context:            context,
      isScrollControlled: true,
      backgroundColor:    Colors.transparent,
      builder: (_) => _DeliverSheet(
        task:    task,
        project: _proj(task.projectId),
        onConfirm: () async {
          Navigator.of(context).pop();
          HapticFeedback.mediumImpact();
          // await ref
          //     .read(taskNotifierProvider.notifier)
          //     .updateTaskStatus(taskId: task.id, status: TaskStatus.delivery);
          if (mounted) _tabs.animateTo(1);
        },
      ),
    );
  }

  // ── Sign out ───────────────────────────────────────────────────────────────
  Future<void> _signOut() async {
    await LoginService.logout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final mq    = MediaQuery.of(context);
    final user  = LoginService.currentUser;
    final queue = _queue;
    final done  = _done;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: _T.slate50,
        body: Column(
          children: [

            // ── Status bar + topbar (white) ──────────────────────────
            Container(
              color: _T.white,
              padding: EdgeInsets.only(top: mq.padding.top),
              child: _Topbar(
                user:       user,
                queueCount: queue.length,
                onAvatarTap: () => _openUserSheet(context, user),
              ),
            ),

            SizedBox(height: 15),

            // ── Stats strip ──────────────────────────────────────────
            _StatsStrip(
              queueCount:   queue.length,
              urgentCount:  queue.where((t) => t.priority == TaskPriority.urgent).length,
              doneCount:    done.length,
              loading:      _loading,
            ),

            // ── Tab bar ───────────────────────────────────────────────
            _SmooTabBar(
              controller: _tabs,
              queueCount: queue.length,
              doneCount:  done.length,
            ),

            // ── Content ───────────────────────────────────────────────
            Expanded(
              child: _loading
                  ? const _SkeletonList()
                  : TabBarView(
                      controller: _tabs,
                      physics: const BouncingScrollPhysics(),
                      children: [
                        // Queue
                        RefreshIndicator(
                          onRefresh:       _refresh,
                          color:           _T.blue,
                          backgroundColor: _T.white,
                          strokeWidth:     2.5,
                          displacement:    20,
                          child: queue.isEmpty
                              ? const _EmptyState(
                                  icon:      Icons.inventory_2_outlined,
                                  iconBg:    _T.green50,
                                  iconColor: _T.green,
                                  title:     'All caught up!',
                                  body:
                                      'No delivery jobs waiting.\nPull down to check for updates.',
                                )
                              : ListView.builder(
                                  padding: EdgeInsets.fromLTRB(
                                      16, 14, 16, 20 + mq.padding.bottom),
                                  itemCount: queue.length,
                                  itemBuilder: (_, i) => _AnimatedCard(
                                    index: i,
                                    child: _QueueCard(
                                      task:      queue[i],
                                      project:   _proj(queue[i].projectId),
                                      onDeliver: () => _openSheet(queue[i]),
                                    ),
                                  ),
                                ),
                        ),

                        // Done
                        RefreshIndicator(
                          onRefresh:       _refresh,
                          color:           _T.blue,
                          backgroundColor: _T.white,
                          strokeWidth:     2.5,
                          child: done.isEmpty
                              ? const _EmptyState(
                                  icon:      Icons.local_shipping_outlined,
                                  iconBg:    _T.slate100,
                                  iconColor: _T.slate400,
                                  title:     'Nothing delivered yet',
                                  body:
                                      'Completed deliveries will\nappear here.',
                                )
                              : ListView.builder(
                                  padding: EdgeInsets.fromLTRB(
                                      16, 14, 16, 20 + mq.padding.bottom),
                                  itemCount: done.length,
                                  itemBuilder: (_, i) => _AnimatedCard(
                                    index: i,
                                    child: _DoneCard(
                                      task:    done[i],
                                      project: _proj(done[i].projectId),
                                    ),
                                  ),
                                ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _openUserSheet(BuildContext context, dynamic user) {
    if (user == null) return;
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context:         context,
      backgroundColor: Colors.transparent,
      builder: (_) => _UserSheet(user: user, onSignOut: _signOut),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TOPBAR
// ─────────────────────────────────────────────────────────────────────────────
class _Topbar extends StatelessWidget {
  final dynamic      user;
  final int          queueCount;
  final VoidCallback onAvatarTap;

  const _Topbar({
    required this.user,
    required this.queueCount,
    required this.onAvatarTap,
  });

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Morning';
    if (h < 17) return 'Afternoon';
    return 'Evening';
  }

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
          Logo(size: 34),
          const SizedBox(width: 10),

          // Greeting + subtitle
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(children: [
                    TextSpan(
                      text: _greeting,
                      style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700,
                        color: _T.ink, letterSpacing: -0.3),
                    ),
                    if (user != null)
                      TextSpan(
                        text: ', ${user.nameShort}',
                        style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700,
                          color: _T.blue, letterSpacing: -0.3),
                      ),
                  ]),
                ),
                const Text(
                  'Delivery Dashboard',
                  style: TextStyle(fontSize: 10.5, color: _T.slate400,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),

          // Pending pill
          if (queueCount > 0) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _T.blue,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 5, height: 5,
                    decoration: const BoxDecoration(
                        color: Colors.white, shape: BoxShape.circle)),
                const SizedBox(width: 5),
                Text('$queueCount',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ]),
            ),
            const SizedBox(width: 10),
          ],

          // Avatar
          if (user != null)
            GestureDetector(
              onTap: onAvatarTap,
              child: Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  color: _T.amber.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: _T.amber.withOpacity(0.4), width: 1.5),
                ),
                child: Center(
                  child: Text(
                    (user.initials as String).isNotEmpty
                        ? (user.initials as String)
                            .substring(0, math.min(2, (user.initials as String).length))
                        : 'D',
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w800,
                        color: _T.amber),
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
// USER SHEET
// ─────────────────────────────────────────────────────────────────────────────
class _UserSheet extends StatelessWidget {
  final dynamic      user;
  final VoidCallback onSignOut;
  const _UserSheet({required this.user, required this.onSignOut});

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
                  color: _T.slate200, borderRadius: BorderRadius.circular(2)),
            ),
          ),

          // Profile row
          Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Container(
              width: 50, height: 50,
              decoration: BoxDecoration(
                color: _T.amber.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(color: _T.amber.withOpacity(0.4), width: 2),
              ),
              child: Center(
                child: Text(
                  (user.initials as String).isNotEmpty
                      ? (user.initials as String)
                          .substring(0, math.min(2, (user.initials as String).length))
                      : 'D',
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w800,
                      color: _T.amber),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(user.name as String,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                        color: _T.ink, letterSpacing: -0.2)),
                const SizedBox(height: 2),
                Text(user.email as String,
                    style: const TextStyle(fontSize: 12, color: _T.slate400)),
              ]),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: _T.amber50,
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: _T.amber.withOpacity(0.3)),
              ),
              child: Text(
                (user.role as String).toUpperCase(),
                style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700,
                    color: _T.amber, letterSpacing: 0.5),
              ),
            ),
          ]),
          const SizedBox(height: 18),
          const Divider(height: 1, color: _T.slate100),
          const SizedBox(height: 12),

          // Sign out button
          Material(
            color: _T.red50,
            borderRadius: BorderRadius.circular(_T.rLg),
            child: InkWell(
              onTap: () {
                Navigator.of(context).pop();
                onSignOut();
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
                  const Icon(Icons.logout_rounded, size: 18, color: _T.red),
                  const SizedBox(width: 12),
                  const Text('Sign out',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                          color: _T.red)),
                  const Spacer(),
                  Icon(Icons.arrow_forward_ios_rounded,
                      size: 12, color: _T.red.withOpacity(0.5)),
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
// STATS STRIP
// ─────────────────────────────────────────────────────────────────────────────
class _StatsStrip extends StatelessWidget {
  final int  queueCount, urgentCount, doneCount;
  final bool loading;
  const _StatsStrip({
    required this.queueCount, required this.urgentCount,
    required this.doneCount,  required this.loading,
  });

  @override
  Widget build(BuildContext context) => Container(
    color: _T.white,
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
    child: Row(children: [
      _Stat(
        value: loading ? '–' : '$queueCount',
        label: 'In Queue',
        color: _T.blue, bg: _T.blue50,
        icon: Icons.inbox_outlined,
      ),
      const SizedBox(width: 10),
      _Stat(
        value: loading ? '–' : '$urgentCount',
        label: 'Urgent',
        color: urgentCount > 0 ? _T.red : _T.slate400,
        bg:    urgentCount > 0 ? _T.red50 : _T.slate100,
        icon: Icons.priority_high_rounded,
      ),
      const SizedBox(width: 10),
      _Stat(
        value: loading ? '–' : '$doneCount',
        label: 'Delivered',
        color: _T.green, bg: _T.green50,
        icon: Icons.check_circle_outline_rounded,
      ),
    ]),
  );
}

class _Stat extends StatelessWidget {
  final String value, label;
  final Color  color, bg;
  final IconData icon;
  const _Stat({required this.value, required this.label,
      required this.color, required this.bg, required this.icon});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.fromLTRB(11, 10, 11, 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(_T.rLg),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Row(children: [
        Container(
          width: 30, height: 30,
          decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(7)),
          child: Icon(icon, size: 15, color: color),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(value,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
                      color: color, letterSpacing: -0.8, height: 1.0)),
              Text(label,
                  style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600,
                      color: _T.slate500)),
            ],
          ),
        ),
      ]),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB BAR
// ─────────────────────────────────────────────────────────────────────────────
class _SmooTabBar extends StatelessWidget {
  final TabController controller;
  final int queueCount, doneCount;
  const _SmooTabBar({
    required this.controller,
    required this.queueCount,
    required this.doneCount,
  });

  @override
  Widget build(BuildContext context) => Container(
    color: _T.white,
    child: TabBar(
      controller:            controller,
      labelColor:            _T.blue,
      unselectedLabelColor:  _T.slate400,
      labelStyle:            const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
      unselectedLabelStyle:  const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500),
      indicator: const UnderlineTabIndicator(
        borderSide: BorderSide(color: _T.blue, width: 2.5),
        insets: EdgeInsets.symmetric(horizontal: 0),
      ),
      indicatorSize: TabBarIndicatorSize.label,
      dividerColor:  _T.slate200,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      tabs: [
        Tab(child: _TabBadge('Queue', queueCount, _T.blue)),
        Tab(child: _TabBadge('Done', doneCount, _T.green)),
      ],
    ),
  );
}

class _TabBadge extends StatelessWidget {
  final String label;
  final int    count;
  final Color  badgeColor;
  const _TabBadge(this.label, this.count, this.badgeColor);

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(label),
      if (count > 0) ...[
        const SizedBox(width: 7),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
              color: badgeColor, borderRadius: BorderRadius.circular(99)),
          child: Text('$count',
              style: const TextStyle(fontSize: 10,
                  fontWeight: FontWeight.w800, color: Colors.white)),
        ),
      ],
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// ANIMATED CARD WRAPPER — staggered entry
// ─────────────────────────────────────────────────────────────────────────────
class _AnimatedCard extends StatefulWidget {
  final int    index;
  final Widget child;
  const _AnimatedCard({required this.index, required this.child});

  @override
  State<_AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<_AnimatedCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac = AnimationController(
    vsync: this, duration: const Duration(milliseconds: 400));

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: widget.index * 60), () {
      if (mounted) _ac.forward();
    });
  }

  @override
  void dispose() { _ac.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _ac,
    child: widget.child,
    builder: (_, child) => FadeTransition(
      opacity: CurvedAnimation(parent: _ac, curve: Curves.easeOut),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.06), end: Offset.zero,
        ).animate(CurvedAnimation(parent: _ac, curve: Curves.easeOutCubic)),
        child: child,
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// QUEUE CARD  — swipeable
// ─────────────────────────────────────────────────────────────────────────────
class _QueueCard extends StatefulWidget {
  final Task     task;
  final Project? project;
  final VoidCallback onDeliver;
  const _QueueCard({
    required this.task,
    required this.project,
    required this.onDeliver,
  });

  @override
  State<_QueueCard> createState() => _QueueCardState();
}

class _QueueCardState extends State<_QueueCard> {
  double _dx      = 0;
  bool   _fired   = false;
  static const _threshold = 90.0;

  bool get _overdue =>
      widget.task.dueDate != null &&
      widget.task.dueDate!.isBefore(DateTime.now());

  int get _daysDelta {
    if (widget.task.dueDate == null) return 999;
    return widget.task.dueDate!.difference(DateTime.now()).inDays;
  }

  @override
  Widget build(BuildContext context) {
    final task   = widget.task;
    final priC   = _priColor(task.priority);
    final pct    = (_dx / _threshold).clamp(0.0, 1.0);
    final passed = pct >= 1.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        child: Stack(
          children: [
            // ── Swipe reveal background ───────────────────────────────
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: passed ? _T.green : _T.green.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(_T.rXl),
                ),
                padding: const EdgeInsets.only(left: 24),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Opacity(
                    opacity: pct,
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(
                        passed
                            ? Icons.check_circle_rounded
                            : Icons.check_circle_outline_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        passed ? 'Release to confirm' : 'Delivered',
                        style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700,
                          color: Colors.white),
                      ),
                    ]),
                  ),
                ),
              ),
            ),

            // ── Draggable card ────────────────────────────────────────
            GestureDetector(
              onHorizontalDragUpdate: (d) {
                if (_fired) return;
                setState(() {
                  _dx = math.max(0, _dx + d.delta.dx);
                });
                // Haptic at 50% and 100%
                if (_dx >= _threshold * 0.5 && _dx - d.delta.dx < _threshold * 0.5) {
                  HapticFeedback.selectionClick();
                }
                if (_dx >= _threshold && _dx - d.delta.dx < _threshold) {
                  HapticFeedback.mediumImpact();
                }
              },
              onHorizontalDragEnd: (_) {
                if (_dx >= _threshold && !_fired) {
                  _fired = true;
                  widget.onDeliver();
                }
                setState(() => _dx = 0);
              },
              child: Transform.translate(
                offset: Offset(
                    (_dx * 0.9).clamp(0.0, _threshold * 1.3), 0),
                child: _CardBody(
                  task:    task,
                  project: widget.project,
                  priC:    priC,
                  overdue: _overdue,
                  daysDelta: _daysDelta,
                  swipePct: pct,
                  onDeliver: widget.onDeliver,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardBody extends StatelessWidget {
  final Task     task;
  final Project? project;
  final Color    priC;
  final bool     overdue;
  final int      daysDelta;
  final double   swipePct;
  final VoidCallback onDeliver;

  const _CardBody({
    required this.task, required this.project, required this.priC,
    required this.overdue, required this.daysDelta, required this.swipePct,
    required this.onDeliver,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _T.white,
        borderRadius: BorderRadius.circular(_T.rXl),
        border: Border.all(
          color: task.priority == TaskPriority.urgent
              ? _T.red.withOpacity(0.35)
              : _T.slate200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          if (task.priority == TaskPriority.urgent)
            BoxShadow(
              color: _T.red.withOpacity(0.08),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_T.rXl),
        child: IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            // Priority accent bar
            Container(width: 4, color: priC),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // ── Top row: priority + swipe hint + due ─────────
                    Row(children: [
                      // Priority pill
                      _Pill(
                        label: _priLabel(task.priority),
                        color: priC,
                        bg:    _priBg(task.priority),
                      ),
                      const SizedBox(width: 6),
                      // Swipe hint — fades out as user swipes
                      Opacity(
                        opacity: (1 - swipePct * 3).clamp(0.0, 1.0),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.swipe_right_outlined,
                              size: 12, color: _T.slate300),
                          const SizedBox(width: 3),
                          const Text('swipe',
                              style: TextStyle(
                                  fontSize: 10, color: _T.slate300,
                                  fontWeight: FontWeight.w500)),
                        ]),
                      ),
                      const Spacer(),
                      if (task.dueDate != null)
                        _DueBadge(delta: daysDelta, overdue: overdue),
                    ]),
                    const SizedBox(height: 11),

                    // ── Task name ────────────────────────────────────
                    Text(
                      task.name,
                      style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700,
                        color: _T.ink, letterSpacing: -0.4, height: 1.3,
                      ),
                    ),

                    // ── Project ──────────────────────────────────────
                    if (project != null) ...[
                      const SizedBox(height: 7),
                      Row(children: [
                        Container(
                          width: 7, height: 7,
                          decoration: BoxDecoration(
                              color: project!.color, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 6),
                        Text(project!.name,
                            style: const TextStyle(fontSize: 12,
                                color: _T.slate500, fontWeight: FontWeight.w500)),
                      ]),
                    ],

                    const SizedBox(height: 14),
                    const Divider(height: 1, color: _T.slate100),
                    const SizedBox(height: 13),

                    // ── CTA ──────────────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton.icon(
                        onPressed: onDeliver,
                        style: FilledButton.styleFrom(
                          backgroundColor: _T.blue,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(_T.r)),
                        ),
                        icon: const Icon(Icons.local_shipping_outlined, size: 18),
                        label: const Text('Mark as Delivered',
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DONE CARD
// ─────────────────────────────────────────────────────────────────────────────
class _DoneCard extends StatelessWidget {
  final Task     task;
  final Project? project;
  const _DoneCard({required this.task, required this.project});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _T.white,
        borderRadius: BorderRadius.circular(_T.rLg),
        border: Border.all(color: _T.slate200),
      ),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: _T.green50, shape: BoxShape.circle,
            border: Border.all(color: _T.green.withOpacity(0.25)),
          ),
          child: const Icon(Icons.check_rounded, size: 20, color: _T.green),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(task.name,
                style: const TextStyle(fontSize: 13.5,
                    fontWeight: FontWeight.w600, color: _T.ink3)),
            if (project != null) ...[
              const SizedBox(height: 4),
              Row(children: [
                Container(width: 6, height: 6,
                    decoration: BoxDecoration(
                        color: project!.color, shape: BoxShape.circle)),
                const SizedBox(width: 5),
                Text(project!.name,
                    style: const TextStyle(fontSize: 11.5,
                        color: _T.slate400, fontWeight: FontWeight.w500)),
              ]),
            ],
          ]),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: _T.green50,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: _T.green.withOpacity(0.3)),
          ),
          child: const Text('Delivered',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                  color: _T.green)),
        ),
      ]),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// DELIVER CONFIRMATION SHEET
// ─────────────────────────────────────────────────────────────────────────────
class _DeliverSheet extends StatefulWidget {
  final Task     task;
  final Project? project;
  final Future<void> Function() onConfirm;
  const _DeliverSheet({
    required this.task, required this.project, required this.onConfirm});

  @override
  State<_DeliverSheet> createState() => _DeliverSheetState();
}

class _DeliverSheetState extends State<_DeliverSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 280))..forward();
  bool _saving = false;

  @override
  void dispose() { _ac.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final task  = widget.task;
    final proj  = widget.project;
    final priC  = _priColor(task.priority);
    final mq    = MediaQuery.of(context);

    return AnimatedBuilder(
      animation: _ac,
      builder: (_, child) => FadeTransition(
        opacity: CurvedAnimation(parent: _ac, curve: Curves.easeOut),
        child: child,
      ),
      child: Container(
        padding: EdgeInsets.fromLTRB(22, 0, 22, 24 + mq.padding.bottom),
        decoration: const BoxDecoration(
          color: _T.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 14),
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: _T.slate200, borderRadius: BorderRadius.circular(2)),
              ),
            ),

            // Icon
            Container(
              width: 68, height: 68,
              decoration: BoxDecoration(
                color: _T.green50, shape: BoxShape.circle,
                border: Border.all(color: _T.green.withOpacity(0.2), width: 2),
              ),
              child: const Icon(Icons.local_shipping_outlined,
                  size: 30, color: _T.green),
            ),
            const SizedBox(height: 14),

            const Text('Confirm Delivery',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
                    color: _T.ink, letterSpacing: -0.4)),
            const SizedBox(height: 6),
            const Text(
              'Mark this job as delivered?\nThis cannot be undone.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.5, height: 1.55, color: _T.slate500),
            ),
            const SizedBox(height: 20),

            // Task card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _T.slate50,
                borderRadius: BorderRadius.circular(_T.rLg),
                border: Border.all(color: _T.slate200),
              ),
              child: IntrinsicHeight(
                child: Row(crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                  Container(
                    width: 3, margin: const EdgeInsets.only(right: 13),
                    decoration: BoxDecoration(
                        color: priC, borderRadius: BorderRadius.circular(2)),
                  ),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(task.name,
                          style: const TextStyle(fontSize: 14.5,
                              fontWeight: FontWeight.w700, color: _T.ink,
                              letterSpacing: -0.2)),
                      if (proj != null) ...[
                        const SizedBox(height: 6),
                        Row(children: [
                          Container(width: 6, height: 6,
                              decoration: BoxDecoration(
                                  color: proj!.color, shape: BoxShape.circle)),
                          const SizedBox(width: 6),
                          Text(proj!.name,
                              style: const TextStyle(fontSize: 12,
                                  color: _T.slate500, fontWeight: FontWeight.w500)),
                        ]),
                      ],
                    ]),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: _Pill(
                      label: _priLabel(task.priority),
                      color: priC, bg: _priBg(task.priority),
                    ),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 22),

            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _saving ? null : () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _T.slate500,
                    side: const BorderSide(color: _T.slate200),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(_T.r)),
                  ),
                  child: const Text('Cancel',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: _saving ? null : () async {
                    setState(() => _saving = true);
                    await widget.onConfirm();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: _T.green,
                    disabledBackgroundColor: _T.slate200,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(_T.r)),
                  ),
                  icon: _saving
                      ? const SizedBox(width: 16, height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.white))
                      : const Icon(Icons.check_rounded, size: 18),
                  label: Text(_saving ? 'Saving…' : 'Yes, Delivered',
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700)),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SKELETON LOADING
// ─────────────────────────────────────────────────────────────────────────────
class _SkeletonList extends StatefulWidget {
  const _SkeletonList();

  @override
  State<_SkeletonList> createState() => _SkeletonListState();
}

class _SkeletonListState extends State<_SkeletonList>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900))
    ..repeat(reverse: true);

  @override
  void dispose() { _ac.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ac,
      builder: (_, __) {
        final opacity = 0.35 + _ac.value * 0.45;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          children: List.generate(3,
            (i) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _SkeletonCard(opacity: opacity),
            )),
        );
      },
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  final double opacity;
  const _SkeletonCard({required this.opacity});

  Widget _bone(double w, double h, {double r = 6, bool fill = false}) =>
      Container(
        width: fill ? null : w,
        height: h,
        decoration: BoxDecoration(
          color: _T.slate200.withOpacity(opacity),
          borderRadius: BorderRadius.circular(r),
        ),
      );

  @override
  Widget build(BuildContext context) => Container(
    height: 154,
    decoration: BoxDecoration(
      color: _T.white,
      borderRadius: BorderRadius.circular(_T.rXl),
      border: Border.all(color: _T.slate200),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(_T.rXl),
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(width: 4, color: _T.slate200.withOpacity(opacity)),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                _bone(60, 20), const Spacer(), _bone(70, 20),
              ]),
              const SizedBox(height: 12),
              _bone(0, 16, fill: true),
              const SizedBox(height: 8),
              _bone(130, 13),
              const Spacer(),
              _bone(0, 46, r: _T.r, fill: true),
            ]),
          ),
        ),
      ]),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// EMPTY STATE
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final Color    iconBg, iconColor;
  final String   title, body;
  const _EmptyState({
    required this.icon, required this.iconBg, required this.iconColor,
    required this.title, required this.body,
  });

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.symmetric(horizontal: 36),
    children: [
      const SizedBox(height: 80),
      Center(
        child: Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            color: iconBg, shape: BoxShape.circle,
            border: Border.all(color: iconColor.withOpacity(0.2), width: 2),
          ),
          child: Icon(icon, size: 36, color: iconColor),
        ),
      ),
      const SizedBox(height: 20),
      Text(title, textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
              color: _T.ink, letterSpacing: -0.4)),
      const SizedBox(height: 8),
      Text(body, textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, height: 1.6, color: _T.slate400)),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED MICRO WIDGETS
// ─────────────────────────────────────────────────────────────────────────────
class _Pill extends StatelessWidget {
  final String label;
  final Color  color, bg;
  const _Pill({required this.label, required this.color, required this.bg});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: bg, borderRadius: BorderRadius.circular(99),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 5, height: 5,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 5),
      Text(label,
          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700,
              color: color)),
    ]),
  );
}

class _DueBadge extends StatelessWidget {
  final int  delta;
  final bool overdue;
  const _DueBadge({required this.delta, required this.overdue});

  @override
  Widget build(BuildContext context) {
    final String text;
    final Color  bg, fg;
    if (overdue) {
      text = delta.abs() == 0 ? 'Due today' : '${delta.abs()}d overdue';
      bg = _T.red; fg = Colors.white;
    } else if (delta <= 0) {
      text = 'Due today'; bg = _T.amber50; fg = _T.amber;
    } else if (delta <= 2) {
      text = 'Due in ${delta}d'; bg = _T.amber50; fg = _T.amber;
    } else {
      text = 'Due in ${delta}d'; bg = _T.slate100; fg = _T.slate500;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(text,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LOGO — same _LogoPainter used in every screen in the project
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
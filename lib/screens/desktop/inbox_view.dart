// ═════════════════════════════════════════════════════════════════════════════
// SMOOFLOW — INBOX VIEW
// ═════════════════════════════════════════════════════════════════════════════
// v3 changes
//  • InboxItem.message REMOVED — all data now lives on TaskActivity.metadata
//  • _InboxItemRow handles 3 scenarios from a single TaskActivity:
//      Scenario A — stage change only      (fromStage/toStage set, no message)
//      Scenario B — stage change + message  (both metadata blocks set)
//      Scenario C — message only            (message metadata set, no stage data)
//  • _accentFor / _iconFor / _BadgedAvatar updated accordingly
//  • Stage pill order fixed: from → arrow → to  (was reversed)
// ═════════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/core/models/task_activity.dart';
import 'package:smooflow/core/services/login_service.dart';
import 'package:smooflow/data/inbox_item.dart';
import 'package:smooflow/enums/task_priority.dart';
import 'package:smooflow/enums/task_status.dart';
import 'package:smooflow/helpers/task_component_helper.dart';
import 'package:smooflow/providers/inbox_provider.dart';
import 'package:smooflow/providers/task_provider.dart';
import 'package:smooflow/screens/desktop/components/avatar_widget.dart';
import 'package:smooflow/screens/desktop/components/detail_panel.dart';
import 'package:smooflow/screens/desktop/components/priority_pill.dart';
import 'package:smooflow/screens/desktop/constants.dart';
import 'package:timeago/timeago.dart' as timeago;

// ─────────────────────────────────────────────────────────────────────────────
// DESIGN TOKENS
// ─────────────────────────────────────────────────────────────────────────────
class _T {
  static const blue = Color(0xFF2563EB);
  static const blueHover = Color(0xFF1D4ED8);
  static const blue100 = Color(0xFFDBEAFE);
  static const blue50 = Color(0xFFEFF6FF);
  static const teal = Color(0xFF38BDF8);
  static const green = Color(0xFF10B981);
  static const green50 = Color(0xFFECFDF5);
  static const amber = Color(0xFFF59E0B);
  static const amber50 = Color(0xFFFEF3C7);
  static const red = Color(0xFFEF4444);
  static const red50 = Color(0xFFFEE2E2);
  static const purple = Color(0xFF8B5CF6);
  static const purple50 = Color(0xFFF3E8FF);
  static const indigo = Color(0xFF6366F1);
  static const indigo50 = Color(0xFFEEF2FF);
  static const slate50 = Color(0xFFF8FAFC);
  static const slate100 = Color(0xFFF1F5F9);
  static const slate200 = Color(0xFFE2E8F0);
  static const slate300 = Color(0xFFCBD5E1);
  static const slate400 = Color(0xFF94A3B8);
  static const slate500 = Color(0xFF64748B);
  static const ink = Color(0xFF0F172A);
  static const ink2 = Color(0xFF1E293B);
  static const ink3 = Color(0xFF334155);
  static const white = Colors.white;
  static const r = 8.0;
  static const rLg = 12.0;
  static const rXl = 16.0;
  static const detailW = 600.0;
  static const topbarH = 60.0;
}

// ─────────────────────────────────────────────────────────────────────────────
// SCENARIO RESOLVER
// All three situations are derived purely from TaskActivity data —
// no InboxItem.message reference anywhere.
// ─────────────────────────────────────────────────────────────────────────────
enum _Scenario { stageOnly, stageAndMessage, messageOnly }

extension _ActivityScenario on TaskActivity {
  /// True when the activity carries a stage transition.
  bool get _hasStageChange =>
      (type == ActivityType.stageForward ||
          type == ActivityType.stageBackward) &&
      fromStage.isNotEmpty &&
      toStage.isNotEmpty;

  /// True when the activity metadata includes an inline comment.
  bool get _hasMessage => message != null && message!.isNotEmpty;

  _Scenario get scenario {
    if (_hasStageChange && _hasMessage) return _Scenario.stageAndMessage;
    if (_hasStageChange) return _Scenario.stageOnly;
    return _Scenario.messageOnly;
  }

  /// Scenario B only: true when the stage actor and the comment author
  /// are the same person. Falls back to true when authorId is absent.
  bool get isSameActor =>
      authorId == null || authorId!.isEmpty || authorId == actorId;

  /// Derives display initials from the comment author's name string,
  /// since authorInitials is not stored in metadata — only authorName is.
  String get authorInitials {
    final name = (authorName ?? '').trim();
    if (name.isEmpty) return '?';
    final parts = name.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return parts.first[0].toUpperCase();
  }

  /// Display name for the comment author, with "You" substitution.
  String authorDisplayName(String currentUserId) {
    if (authorId == currentUserId) return 'You';
    return authorName ?? 'Someone';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ACCENT & ICON HELPERS
// Stage changes drive the accent when present; message-only defaults to purple.
// ─────────────────────────────────────────────────────────────────────────────
Color _accentFor(TaskActivity activity) {
  switch (activity.type) {
    case ActivityType.stageForward:
      return _T.green;
    case ActivityType.stageBackward:
      return _T.amber;
    case ActivityType.printerAssigned:
      return _T.blue;
    case ActivityType.priorityChanged:
      return _T.red;
    case ActivityType.assigneeAdded:
      return _T.indigo;
    case ActivityType.taskCompleted:
      return _T.green;
    default:
      return _T.purple; // message-only or unknown
  }
}

IconData _iconFor(TaskActivity activity) {
  switch (activity.type) {
    case ActivityType.stageForward:
      return Icons.trending_up_rounded;
    case ActivityType.stageBackward:
      return Icons.trending_down_rounded;
    case ActivityType.printerAssigned:
      return Icons.print_rounded;
    case ActivityType.priorityChanged:
      return Icons.flag_rounded;
    case ActivityType.assigneeAdded:
      return Icons.person_add_rounded;
    case ActivityType.taskCompleted:
      return Icons.check_circle_rounded;
    default:
      return Icons.chat_bubble_rounded;
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// INBOX VIEW
// ═════════════════════════════════════════════════════════════════════════════
class InboxView extends ConsumerStatefulWidget {
  const InboxView({super.key});

  @override
  ConsumerState<InboxView> createState() => _InboxViewState();
}

class _InboxViewState extends ConsumerState<InboxView> {
  InboxItem? _selectedItem;
  final ScrollController _scroll = ScrollController();
  bool _isLoadingInbox = true;
  bool _isCheckingNew = false;

  Future<void> initializeInbox() async {
    await Future.microtask(() async {
      if (!_scroll.hasClients) return;
      final maxScrollExtent = _scroll.position.maxScrollExtent;
      if (maxScrollExtent == 0) {
        final newCount =
            await ref.read(inboxNotifierProvider.notifier).fetchRecentInbox();
        if (newCount > 0) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _isLoadingInbox = true);
            initializeInbox().then((_) {
              if (mounted) setState(() => _isLoadingInbox = false);
            });
          });
        }
      }
    });
  }

  Future<void> _checkForNewItems() async {
    if (_isCheckingNew) return;
    setState(() => _isCheckingNew = true);
    await ref.read(inboxNotifierProvider.notifier).fetchRecentInbox();
    if (mounted) setState(() => _isCheckingNew = false);
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      initializeInbox().then((_) {
        if (mounted) setState(() => _isLoadingInbox = false);
      });
    });
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200) {
      final s = ref.read(inboxNotifierProvider);
      if (!s.isLoading && s.hasMore) {
        ref.read(inboxNotifierProvider.notifier).fetchRecentInbox();
      }
    }
  }

  void _onItemTap(InboxItem item) {
    setState(() => _selectedItem = item);
    if (!item.isSeen) {
      ref
          .read(inboxNotifierProvider.notifier)
          .markActivitySeen(item.activity!.id);
    }
  }

  void _closeDetail() => setState(() => _selectedItem = null);

  Widget _detailPanel() {
    final task =
        _selectedItem == null
            ? null
            : ref.read(taskByIdProviderSimple(_selectedItem!.taskId));
    return AnimatedContainer(
      duration: const Duration(milliseconds: 130),
      width: task != null ? kDetailWidth : 0,
      child:
          task == null
              ? const SizedBox()
              : DetailPanel(
                task: task,
                onClose: _closeDetail,
                onAdvance: () {},
                showFooter: false,
              ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inboxState = ref.watch(inboxNotifierProvider);

    return Row(
      children: [
        Expanded(
          child: Container(
            color: _T.slate50,
            child: Column(
              children: [
                _InboxHeader(
                  unseenCount: inboxState.unseenCount,
                  onRefresh: _checkForNewItems,
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child:
                      _isCheckingNew
                          ? const _NewContentBanner()
                          : const SizedBox.shrink(),
                ),
                Expanded(
                  child:
                      inboxState.items.isEmpty && !_isLoadingInbox
                          ? const _EmptyState()
                          : ListView.builder(
                            controller: _scroll,
                            padding: const EdgeInsets.only(
                              top: 8,
                              bottom: 24,
                              left: 12,
                              right: 12,
                            ),
                            itemCount: inboxState.items.length + 1,
                            itemBuilder: (context, index) {
                              if (index == inboxState.items.length) {
                                if (inboxState.isLoading) {
                                  return const _LoadingMoreIndicator();
                                }
                                if (!inboxState.hasMore) {
                                  return const _EndOfInboxWidget();
                                }
                                return const SizedBox.shrink();
                              }

                              final item = inboxState.items[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: _InboxItemRow(
                                  item: item,
                                  isSelected: _selectedItem?.id == item.id,
                                  onTap: () => _onItemTap(item),
                                  onMarkRead: () {
                                    if (!item.isSeen) {
                                      ref
                                          .read(inboxNotifierProvider.notifier)
                                          .markActivitySeen(item.activity!.id);
                                    }
                                  },
                                ),
                              );
                            },
                          ),
                ),
              ],
            ),
          ),
        ),
        _detailPanel(),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// INBOX HEADER
// ═════════════════════════════════════════════════════════════════════════════
class _InboxHeader extends StatelessWidget {
  final int unseenCount;
  final VoidCallback onRefresh;
  const _InboxHeader({required this.unseenCount, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _T.topbarH,
      decoration: const BoxDecoration(
        color: _T.white,
        border: Border(bottom: BorderSide(color: _T.slate200)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: _T.blue50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.notifications_outlined,
              size: 16,
              color: _T.blue,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Inbox',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _T.ink,
            ),
          ),
          if (unseenCount > 0) ...[
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _T.blue,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                '$unseenCount',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
          const Spacer(),
          _HeaderIconButton(
            icon: Icons.refresh_rounded,
            tooltip: 'Check for new',
            onTap: onRefresh,
          ),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  State<_HeaderIconButton> createState() => _HeaderIconButtonState();
}

class _HeaderIconButtonState extends State<_HeaderIconButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: _hovered ? _T.slate100 : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              widget.icon,
              size: 16,
              color: _hovered ? _T.ink2 : _T.slate400,
            ),
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// NEW CONTENT BANNER
// ═════════════════════════════════════════════════════════════════════════════
class _NewContentBanner extends StatelessWidget {
  const _NewContentBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: _T.blue50,
        border: Border(
          top: BorderSide(color: _T.blue.withOpacity(0.15)),
          bottom: BorderSide(color: _T.blue.withOpacity(0.15)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: _T.blue.withOpacity(0.6),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Checking for new activity…',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: _T.blue.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// INBOX ITEM ROW — unified card for all 3 scenarios
// ═════════════════════════════════════════════════════════════════════════════
class _InboxItemRow extends StatefulWidget {
  final InboxItem item;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onMarkRead;

  const _InboxItemRow({
    super.key,
    required this.item,
    required this.isSelected,
    required this.onTap,
    required this.onMarkRead,
  });

  @override
  State<_InboxItemRow> createState() => _InboxItemRowState();
}

class _InboxItemRowState extends State<_InboxItemRow>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  late final AnimationController _expandCtrl;
  late final Animation<double> _expandAnim;

  @override
  void initState() {
    super.initState();
    _expandCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _expandAnim = CurvedAnimation(parent: _expandCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _expandCtrl.dispose();
    super.dispose();
  }

  void _onEnter() {
    setState(() => _hovered = true);
    _expandCtrl.forward();
  }

  void _onExit() {
    setState(() => _hovered = false);
    _expandCtrl.reverse();
  }

  TaskActivity get _activity => widget.item.activity!;
  bool get _isUnread => !widget.item.isSeen;

  @override
  Widget build(BuildContext context) {
    final activity = _activity;
    final scenario = activity.scenario;
    final accent = _accentFor(activity);
    final isUnread = _isUnread;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => _onEnter(),
      onExit: (_) => _onExit(),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color:
                widget.isSelected
                    ? accent.withOpacity(0.06)
                    : isUnread
                    ? _T.blue50.withOpacity(0.6)
                    : _T.white,
            borderRadius: BorderRadius.circular(_T.rLg),
            border: Border.all(
              color:
                  widget.isSelected
                      ? accent.withOpacity(0.35)
                      : isUnread
                      ? _T.blue100.withOpacity(0.6)
                      : _hovered
                      ? _T.slate200
                      : _T.slate200.withOpacity(0.7),
              width: widget.isSelected ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color:
                    widget.isSelected
                        ? accent.withOpacity(0.08)
                        : _hovered
                        ? const Color(0x0F0F172A)
                        : const Color(0x080F172A),
                blurRadius: _hovered ? 8 : 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Left accent bar ──────────────────────────────────────
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 3.5,
                  decoration: BoxDecoration(
                    color:
                        widget.isSelected || _hovered
                            ? accent
                            : isUnread
                            ? accent.withOpacity(0.5)
                            : _T.slate200,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(_T.rLg),
                      bottomLeft: Radius.circular(_T.rLg),
                    ),
                  ),
                ),

                // ── Main content ─────────────────────────────────────────
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Avatar · actor · verb · time · unread dot
                        _buildHeader(activity, accent, isUnread, scenario),

                        const SizedBox(height: 10),

                        // 2. Task name
                        _buildTaskName(activity, accent),

                        const SizedBox(height: 8),

                        // 3. Content block (varies by scenario)
                        _buildContentBlock(activity, scenario),

                        // 4. Hover quick-actions
                        _buildQuickActions(scenario, isUnread),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── 1. HEADER ─────────────────────────────────────────────────────────────
  Widget _buildHeader(
    TaskActivity activity,
    Color accent,
    bool isUnread,
    _Scenario scenario,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BadgedAvatar(activity: activity, accent: accent, scenario: scenario),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderText(activity, scenario),
              const SizedBox(height: 2),
              Text(
                timeago.format(activity.updatedAt),
                style: const TextStyle(fontSize: 11, color: _T.slate400),
              ),
            ],
          ),
        ),
        if (isUnread)
          Container(
            width: 7,
            height: 7,
            margin: const EdgeInsets.only(top: 4),
            decoration: const BoxDecoration(
              color: _T.blue,
              shape: BoxShape.circle,
            ),
          ),
      ],
    );
  }

  // Actor name + context-appropriate verb
  Widget _buildHeaderText(TaskActivity activity, _Scenario scenario) {
    final isSelf = activity.actorId == LoginService.currentUser!.id;
    final actorName = isSelf ? 'You' : activity.actorName;

    final String verb;
    switch (scenario) {
      case _Scenario.stageOnly:
        verb = _stageVerb(activity.type);
        break;
      case _Scenario.stageAndMessage:
        verb = '${_stageVerbShort(activity.type)} & commented';
        break;
      case _Scenario.messageOnly:
        verb = 'commented';
        break;
    }

    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: const TextStyle(fontSize: 12.5, color: _T.ink2, height: 1.3),
        children: [
          TextSpan(
            text: actorName,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          TextSpan(
            text: '  $verb',
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: _T.slate500,
            ),
          ),
        ],
      ),
    );
  }

  // ── 2. TASK NAME ──────────────────────────────────────────────────────────
  Widget _buildTaskName(TaskActivity activity, Color accent) {
    return Row(
      children: [
        Container(
          width: 5,
          height: 5,
          margin: const EdgeInsets.only(right: 7, top: 1),
          decoration: BoxDecoration(
            color: accent.withOpacity(0.5),
            shape: BoxShape.circle,
          ),
        ),
        Expanded(
          child: Text(
            activity.taskName,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: widget.isSelected ? accent : _T.ink,
              height: 1.3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ── 3. CONTENT BLOCK ──────────────────────────────────────────────────────
  Widget _buildContentBlock(TaskActivity activity, _Scenario scenario) {
    switch (scenario) {
      // ── Scenario A: stage only ───────────────────────────────────────────
      case _Scenario.stageOnly:
        return _buildStageTransition(activity);

      // ── Scenario B: stage + message ──────────────────────────────────────
      case _Scenario.stageAndMessage:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStageTransition(activity),
            const SizedBox(height: 8),
            // Inline section label separating the two blocks
            Row(
              children: [
                Container(
                  width: 3,
                  height: 3,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: const BoxDecoration(
                    color: _T.slate300,
                    shape: BoxShape.circle,
                  ),
                ),
                const Text(
                  'COMMENT',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: _T.slate400,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(child: Container(height: 1, color: _T.slate100)),
              ],
            ),
            const SizedBox(height: 6),
            _buildMessageBubble(activity.message!),
          ],
        );

      // ── Scenario C: message only ─────────────────────────────────────────
      case _Scenario.messageOnly:
        return _buildMessageBubble(activity.message!);
    }
  }

  // Stage transition pill: FROM → arrow → TO
  Widget _buildStageTransition(TaskActivity activity) {
    // Non-stage activity types fall through to generic preview
    if (activity.type != ActivityType.stageForward &&
        activity.type != ActivityType.stageBackward) {
      return _buildGenericPreview(activity);
    }

    final isForward = activity.type == ActivityType.stageForward;
    final fromHelper = TaskComponentHelper.get(
      TaskStatus.values.byName(activity.fromStage),
    );
    final toHelper = TaskComponentHelper.get(
      TaskStatus.values.byName(activity.toStage),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // FROM — always muted slate (where it came from)
        _MiniStagePill(
          label: fromHelper.label,
          color: _T.slate500,
          bg: _T.slate100,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 7),
          child: Icon(
            isForward ? Icons.arrow_forward_rounded : Icons.arrow_back_rounded,
            size: 13,
            color: _T.slate300,
          ),
        ),
        // TO — colored (where it is now)
        _MiniStagePill(
          label: toHelper.label,
          color: isForward ? _T.green : _T.amber,
          bg: isForward ? _T.green50 : _T.amber50,
        ),
      ],
    );
  }

  // Generic preview for non-stage activity types
  Widget _buildGenericPreview(TaskActivity activity) {
    switch (activity.type) {
      case ActivityType.printerAssigned:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: _T.blue50,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: _T.blue.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.print_rounded, size: 12, color: _T.blue),
              const SizedBox(width: 5),
              Text(
                activity.printerNickname ?? activity.printerName ?? '',
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: _T.blue,
                ),
              ),
            ],
          ),
        );

      case ActivityType.assigneeAdded:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person_add_rounded, size: 12, color: _T.indigo),
            const SizedBox(width: 5),
            Text(
              'Assigned to ${activity.addedUserName}',
              style: const TextStyle(fontSize: 12, color: _T.slate500),
            ),
          ],
        );

      case ActivityType.priorityChanged:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _MiniPriorityChip(priority: activity.fromPriority ?? 2),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: Icon(
                Icons.arrow_forward_rounded,
                size: 11,
                color: _T.slate300,
              ),
            ),
            _MiniPriorityChip(priority: activity.toPriority ?? 2),
          ],
        );

      default:
        return Text(
          activity.taskDescription ?? '',
          style: const TextStyle(fontSize: 12, color: _T.slate400, height: 1.4),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        );
    }
  }

  // Message bubble — used in both Scenario B and C
  Widget _buildMessageBubble(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: _T.purple50.withOpacity(0.5),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(2),
          topRight: Radius.circular(7),
          bottomLeft: Radius.circular(7),
          bottomRight: Radius.circular(7),
        ),
        border: Border.all(color: _T.purple.withOpacity(0.15)),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, color: _T.ink3, height: 1.5),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  // ── 4. HOVER QUICK-ACTIONS ────────────────────────────────────────────────
  Widget _buildQuickActions(_Scenario scenario, bool isUnread) {
    // Show "Reply" only when there's actually a message to reply to
    final hasMessage =
        scenario == _Scenario.stageAndMessage ||
        scenario == _Scenario.messageOnly;

    return SizeTransition(
      sizeFactor: _expandAnim,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          const Divider(height: 1, color: _T.slate100),
          const SizedBox(height: 8),
          Row(
            children: [
              _QuickActionChip(
                icon: Icons.open_in_new_rounded,
                label: 'View task',
                color: _T.blue,
                bg: _T.blue50,
                onTap: widget.onTap,
              ),
              if (hasMessage) ...[
                const SizedBox(width: 6),
                _QuickActionChip(
                  icon: Icons.reply_rounded,
                  label: 'Reply',
                  color: _T.purple,
                  bg: _T.purple50,
                  onTap: () {},
                ),
              ],
              if (isUnread) ...[
                const SizedBox(width: 6),
                _QuickActionChip(
                  icon: Icons.done_all_rounded,
                  label: 'Mark read',
                  color: _T.slate500,
                  bg: _T.slate100,
                  onTap: widget.onMarkRead,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ── Verb helpers ──────────────────────────────────────────────────────────
  String _stageVerb(ActivityType type) {
    switch (type) {
      case ActivityType.stageForward:
        return 'advanced the task';
      case ActivityType.stageBackward:
        return 'moved task back';
      case ActivityType.taskCompleted:
        return 'completed the task';
      default:
        return 'updated the task';
    }
  }

  String _stageVerbShort(ActivityType type) {
    switch (type) {
      case ActivityType.stageForward:
        return 'advanced';
      case ActivityType.stageBackward:
        return 'moved back';
      case ActivityType.taskCompleted:
        return 'completed';
      default:
        return 'updated';
    }
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// BADGED AVATAR
// Primary badge (bottom-right): activity-type icon.
// Secondary dot (top-right, Scenario B only): purple to signal message present.
// ═════════════════════════════════════════════════════════════════════════════
class _BadgedAvatar extends StatelessWidget {
  final TaskActivity activity;
  final Color accent;
  final _Scenario scenario;

  const _BadgedAvatar({
    required this.activity,
    required this.accent,
    required this.scenario,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 36,
      child: Stack(
        children: [
          AvatarWidget(
            initials: activity.actorInitials,
            color: activity.actorColor ?? _T.ink3,
            size: 34,
          ),

          // Primary badge — activity type icon
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 15,
              height: 15,
              decoration: BoxDecoration(
                color: accent,
                shape: BoxShape.circle,
                border: Border.all(color: _T.white, width: 1.5),
              ),
              child: Icon(_iconFor(activity), size: 8, color: Colors.white),
            ),
          ),

          // Secondary dot — only for Scenario B (stage + message)
          // Purple to hint that a comment is also attached.
          if (scenario == _Scenario.stageAndMessage)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: _T.purple,
                  shape: BoxShape.circle,
                  border: Border.all(color: _T.white, width: 1.5),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// QUICK ACTION CHIP
// ─────────────────────────────────────────────────────────────────────────────
class _QuickActionChip extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bg;
  final VoidCallback onTap;

  const _QuickActionChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.bg,
    required this.onTap,
  });

  @override
  State<_QuickActionChip> createState() => _QuickActionChipState();
}

class _QuickActionChipState extends State<_QuickActionChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: _hovered ? widget.color : widget.bg,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: _hovered ? widget.color : widget.color.withOpacity(0.2),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 11,
                color: _hovered ? Colors.white : widget.color,
              ),
              const SizedBox(width: 5),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _hovered ? Colors.white : widget.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// END OF INBOX
// ═════════════════════════════════════════════════════════════════════════════
class _EndOfInboxWidget extends StatelessWidget {
  const _EndOfInboxWidget();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_T.slate200.withOpacity(0), _T.slate200],
                    ),
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 14),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _T.white,
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: _T.slate200),
                  boxShadow: [
                    BoxShadow(
                      color: _T.ink.withOpacity(0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        color: _T.slate100,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.done_all_rounded,
                        size: 11,
                        color: _T.slate400,
                      ),
                    ),
                    const SizedBox(width: 7),
                    const Text(
                      'No older notifications',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _T.slate400,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_T.slate200, _T.slate200.withOpacity(0)],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            "You've seen everything — you're all caught up.",
            style: TextStyle(
              fontSize: 11.5,
              color: _T.slate300,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// SKELETON LIST
// ═════════════════════════════════════════════════════════════════════════════
class _SkeletonList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      itemCount: 5,
      itemBuilder:
          (_, i) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _SkeletonRow(index: i),
          ),
    );
  }
}

class _SkeletonRow extends StatefulWidget {
  final int index;
  const _SkeletonRow({required this.index});

  @override
  State<_SkeletonRow> createState() => _SkeletonRowState();
}

class _SkeletonRowState extends State<_SkeletonRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final opacity = 0.4 + (_anim.value * 0.35);
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(opacity),
            borderRadius: BorderRadius.circular(_T.rLg),
            border: Border.all(color: _T.slate200.withOpacity(0.7)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 3.5,
                height: 64,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: _T.slate200.withOpacity(opacity),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              Container(
                width: 34,
                height: 34,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: _T.slate200.withOpacity(opacity),
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _shimmer(opacity, w: 140, h: 11),
                    const SizedBox(height: 7),
                    _shimmer(opacity, w: 200, h: 13),
                    const SizedBox(height: 9),
                    _shimmer(opacity, w: 110, h: 22, r: 6),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _shimmer(
    double opacity, {
    required double w,
    required double h,
    double r = 4,
  }) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: _T.slate200.withOpacity(opacity),
        borderRadius: BorderRadius.circular(r),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// LOADING MORE / EMPTY STATE
// ═════════════════════════════════════════════════════════════════════════════
class _LoadingMoreIndicator extends StatelessWidget {
  const _LoadingMoreIndicator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: _T.slate300,
            ),
          ),
          const SizedBox(width: 9),
          const Text(
            'Loading older activity…',
            style: TextStyle(fontSize: 12, color: _T.slate400),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: _T.slate100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              size: 32,
              color: _T.slate300,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No updates yet',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: _T.slate400,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Task activity will appear here',
            style: TextStyle(fontSize: 12, color: _T.slate300),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// MINI SHARED COMPONENTS
// ═════════════════════════════════════════════════════════════════════════════
class _MiniStagePill extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;
  const _MiniStagePill({
    required this.label,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _MiniPriorityChip extends StatelessWidget {
  final int priority;
  const _MiniPriorityChip({required this.priority});

  @override
  Widget build(BuildContext context) {
    final p =
        priority <= 0 || priority > TaskPriority.values.length
            ? TaskPriority.normal
            : TaskPriority.values[priority - 1];
    Color color;
    switch (p) {
      case TaskPriority.normal:
        color = _T.slate500;
        break;
      case TaskPriority.high:
        color = _T.amber;
        break;
      case TaskPriority.urgent:
        color = _T.red;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        p.name[0].toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

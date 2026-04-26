// ═════════════════════════════════════════════════════════════════════════════
// COMPLETE DETAIL PANEL COMPONENTS
// ═════════════════════════════════════════════════════════════════════════════
// All missing components to complete the comprehensive detail panel:
// 1. TaskContextCard - Full task metadata display
// 2. SectionTitle - Consistent section headers
// 3. ActivityTimeline - Recent activities for the task
// 4. MessageAttachments - File attachments display
// 5. PrinterDetailCard - Printer information
// 6. DetailFooter - Action buttons
// ═════════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/core/models/message.dart';
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

// Design tokens (same as before)
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
// ACCENT COLOR HELPER
// Returns the accent color for a given inbox item (used on the left bar & icon)
// ─────────────────────────────────────────────────────────────────────────────
Color _accentFor(InboxItem item) {
  if (item.type == InboxItemType.message) return _T.purple;
  switch (item.activity!.type) {
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
      return _T.slate400;
  }
}

IconData _iconFor(InboxItem item) {
  if (item.type == InboxItemType.message) return Icons.chat_bubble_rounded;
  switch (item.activity!.type) {
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
      return Icons.notifications_rounded;
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
  bool _isLoadingInbox = false;
  bool _isCheckingNew = false; // top-of-list "checking for new" indicator

  Future<void> initializeInbox() async {
    await Future.microtask(() async {
      if (!_scroll.hasClients) return;
      final maxScrollExtent = _scroll.position.maxScrollExtent;
      if (maxScrollExtent == 0) {
        final newInboxCount =
            await ref.read(inboxNotifierProvider.notifier).fetchRecentInbox();
        if (newInboxCount > 0) {
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

  /// Pulls new inbox items from the top (e.g. after a manual refresh or
  /// returning to the view). Shows the top banner while in-flight.
  Future<void> _checkForNewItems() async {
    if (_isCheckingNew) return;
    setState(() => _isCheckingNew = true);
    // Replace with your actual "fetch latest" call:
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
    // Bottom pagination
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200) {
      final inboxState = ref.read(inboxNotifierProvider);
      if (!inboxState.isLoading && inboxState.hasMore) {
        ref.read(inboxNotifierProvider.notifier).fetchRecentInbox();
      }
    }
  }

  void _onItemTap(InboxItem item) {
    setState(() => _selectedItem = item);
    if (item.type == InboxItemType.activity && !item.isSeen) {
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
                // ── Header ──────────────────────────────────────────────────
                _InboxHeader(
                  unseenCount: inboxState.unseenCount,
                  onRefresh: _checkForNewItems,
                ),

                // ── Top "checking for new" banner ────────────────────────────
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child:
                      _isCheckingNew
                          ? const _NewContentBanner()
                          : const SizedBox.shrink(),
                ),

                // ── List ─────────────────────────────────────────────────────
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
                            itemCount:
                                inboxState.items.length +
                                1, // +1 for end / loading footer
                            itemBuilder: (context, index) {
                              // Footer slot
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
                              final isSelected = _selectedItem?.id == item.id;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: _InboxItemRow(
                                  item: item,
                                  isSelected: isSelected,
                                  onTap: () => _onItemTap(item),
                                  onMarkRead: () {
                                    if (!item.isSeen &&
                                        item.type == InboxItemType.activity) {
                                      ref
                                          .read(inboxNotifierProvider.notifier)
                                          .markActivitySeen(item.activity!.id);
                                    }
                                  },
                                  onViewTask: () {
                                    // Navigate to full task
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
          // Refresh button
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
// NEW CONTENT BANNER  (top of list, while fetching new items)
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
// REDESIGNED INBOX ITEM ROW
// ═════════════════════════════════════════════════════════════════════════════
class _InboxItemRow extends StatefulWidget {
  final InboxItem item;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onMarkRead;
  final VoidCallback onViewTask;

  const _InboxItemRow({
    super.key,
    required this.item,
    required this.isSelected,
    required this.onTap,
    required this.onMarkRead,
    required this.onViewTask,
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
      duration: const Duration(milliseconds: 160),
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

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final accent = _accentFor(item);
    final isUnread = !item.isSeen;

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
                    : _hovered
                    ? _T.white
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
                // ── Left accent bar ────────────────────────────────────────
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

                // ── Main content ───────────────────────────────────────────
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Row 1: avatar · actor+verb · timestamp · unread dot
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Avatar with activity-type icon badge
                            _BadgedAvatar(item: item, accent: accent),
                            const SizedBox(width: 10),

                            // Actor + verb
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildHeaderText(item, accent),
                                  const SizedBox(height: 2),
                                  Text(
                                    timeago.format(item.timestamp),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: _T.slate400,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Unread dot
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
                        ),

                        const SizedBox(height: 10),

                        // Row 2: Task name
                        Row(
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
                                item.type == InboxItemType.activity
                                    ? item.activity!.taskName
                                    : 'TASK-${item.message!.taskId}',
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
                        ),

                        const SizedBox(height: 8),

                        // Row 3: Activity or message preview
                        if (item.type == InboxItemType.activity)
                          _buildActivityPreview(item.activity!, accent)
                        else
                          _buildMessagePreview(item.message!),

                        // Row 4: hover-reveal quick actions
                        SizeTransition(
                          sizeFactor: _expandAnim,
                          child: Column(
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
                                    onTap: widget.onViewTask,
                                  ),
                                  const SizedBox(width: 6),
                                  if (item.type == InboxItemType.message)
                                    _QuickActionChip(
                                      icon: Icons.reply_rounded,
                                      label: 'Reply',
                                      color: _T.purple,
                                      bg: _T.purple50,
                                      onTap: () {},
                                    ),
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
                        ),
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

  Widget _buildHeaderText(InboxItem item, Color accent) {
    if (item.type == InboxItemType.activity) {
      final activity = item.activity!;
      final actorName =
          activity.actorId == LoginService.currentUser!.id
              ? 'You'
              : activity.actorName;
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
              text: ' ${_getActivityVerb(activity.type)}',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: _T.slate500,
              ),
            ),
          ],
        ),
      );
    } else {
      final authorName =
          item.message!.authorId == LoginService.currentUser!.id
              ? 'You'
              : item.message!.authorName;
      return RichText(
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        text: TextSpan(
          style: const TextStyle(fontSize: 12.5, color: _T.ink2, height: 1.3),
          children: [
            TextSpan(
              text: authorName,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const TextSpan(
              text: ' commented',
              style: TextStyle(fontWeight: FontWeight.w500, color: _T.slate500),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildActivityPreview(TaskActivity activity, Color accent) {
    late TaskComponentHelper fromHelper, toHelper;
    if (activity.type == ActivityType.stageBackward ||
        activity.type == ActivityType.stageForward) {
      fromHelper = TaskComponentHelper.get(
        TaskStatus.values.byName(activity.fromStage),
      );
      toHelper = TaskComponentHelper.get(
        TaskStatus.values.byName(activity.toStage),
      );
    }

    switch (activity.type) {
      case ActivityType.stageForward:
      case ActivityType.stageBackward:
        final isForward = activity.type == ActivityType.stageForward;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _MiniStagePill(
              label: fromHelper.label,
              color: _T.slate500,
              bg: _T.slate100,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 7),
              child: Icon(
                isForward
                    ? Icons.arrow_forward_rounded
                    : Icons.arrow_back_rounded,
                size: 13,
                color: _T.slate300,
              ),
            ),
            _MiniStagePill(
              label: toHelper.label,
              color: isForward ? _T.green : _T.amber,
              bg: isForward ? _T.green50 : _T.amber50,
            ),
          ],
        );

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

  Widget _buildMessagePreview(Message message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: _T.slate50,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: _T.slate200),
      ),
      child: Text(
        message.message,
        style: const TextStyle(fontSize: 12, color: _T.ink3, height: 1.5),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  String _getActivityVerb(ActivityType type) {
    switch (type) {
      case ActivityType.stageForward:
        return 'advanced the task';
      case ActivityType.stageBackward:
        return 'moved task back';
      case ActivityType.printerAssigned:
        return 'started production';
      case ActivityType.assigneeAdded:
        return 'assigned someone';
      case ActivityType.priorityChanged:
        return 'changed priority';
      case ActivityType.dueDateChanged:
        return 'updated due date';
      case ActivityType.taskCompleted:
        return 'completed the task';
      default:
        return 'updated the task';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BADGED AVATAR
// Avatar with a small activity-type icon badge in the bottom-right
// ─────────────────────────────────────────────────────────────────────────────
class _BadgedAvatar extends StatelessWidget {
  final InboxItem item;
  final Color accent;

  const _BadgedAvatar({required this.item, required this.accent});

  @override
  Widget build(BuildContext context) {
    final initials =
        item.type == InboxItemType.activity
            ? item.activity!.actorInitials
            : item.message!.authorInitials;
    final color =
        item.type == InboxItemType.activity
            ? (item.activity!.actorColor ?? _T.ink3)
            : (item.message!.authorColor ?? _T.ink3);

    return SizedBox(
      width: 36,
      height: 36,
      child: Stack(
        children: [
          AvatarWidget(initials: initials, color: color, size: 34),
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
              child: Icon(_iconFor(item), size: 8, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// QUICK ACTION CHIP  (appears on hover)
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
// END OF INBOX WIDGET
// ═════════════════════════════════════════════════════════════════════════════
class _EndOfInboxWidget extends StatelessWidget {
  const _EndOfInboxWidget();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 8),
      child: Column(
        children: [
          // Dotted divider line
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
                      decoration: BoxDecoration(
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

          // Sub-copy
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
// SKELETON / SHIMMER LOADING LIST
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
              // accent bar
              Container(
                width: 3.5,
                height: 64,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: _T.slate200.withOpacity(opacity),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              // avatar
              Container(
                width: 34,
                height: 34,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: _T.slate200.withOpacity(opacity),
                  shape: BoxShape.circle,
                ),
              ),
              // text lines
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _shimmerLine(opacity, width: 140, height: 11),
                    const SizedBox(height: 7),
                    _shimmerLine(opacity, width: 200, height: 13),
                    const SizedBox(height: 9),
                    _shimmerLine(opacity, width: 110, height: 22, radius: 6),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _shimmerLine(
    double opacity, {
    required double width,
    required double height,
    double radius = 4,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: _T.slate200.withOpacity(opacity),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// LOADING MORE INDICATOR (bottom pagination)
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

// ═════════════════════════════════════════════════════════════════════════════
// EMPTY STATE
// ═════════════════════════════════════════════════════════════════════════════
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
// MINI PILL / CHIP HELPERS (unchanged from original)
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

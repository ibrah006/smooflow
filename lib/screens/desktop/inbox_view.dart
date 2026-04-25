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

class InboxView extends ConsumerStatefulWidget {
  const InboxView({super.key});

  @override
  ConsumerState<InboxView> createState() => _InboxViewState();
}

class _InboxViewState extends ConsumerState<InboxView> {
  InboxItem? _selectedItem;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Load inbox on mount
    Future.microtask(
      () => ref.read(inboxNotifierProvider.notifier).fetchRecentInbox(),
    );

    // Infinite scroll
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final inboxState = ref.read(inboxNotifierProvider);
      if (!inboxState.isLoading && inboxState.hasMore) {
        ref.read(inboxNotifierProvider.notifier).fetchRecentInbox();
      }
    }
  }

  void _onItemTap(InboxItem item) {
    setState(() => _selectedItem = item);

    // Mark as seen if it's an activity
    if (item.type == InboxItemType.activity && !item.isSeen) {
      ref
          .read(inboxNotifierProvider.notifier)
          .markActivitySeen(item.activity!.id);
    }
  }

  void _closeDetail() {
    setState(() => _selectedItem = null);
  }

  _detailPanel() {
    final task =
        _selectedItem == null
            ? null
            : ref.read(taskByIdProviderSimple(_selectedItem!.taskId));

    return AnimatedContainer(
      duration: Duration(milliseconds: 130),
      width: task != null ? kDetailWidth : 0,
      child:
          task == null
              ? SizedBox()
              : DetailPanel(
                task: task,
                onClose: _closeDetail,
                onAdvance: () {}, //_advanceTask(_selectedTask!),
              ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inboxState = ref.watch(inboxNotifierProvider);

    return Row(
      children: [
        // Inbox list
        Expanded(
          child: Container(
            decoration: const BoxDecoration(
              color: _T.white,
              border: Border(right: BorderSide(color: _T.slate200)),
            ),
            child: Column(
              children: [
                // Header
                _InboxHeader(unseenCount: inboxState.unseenCount),

                // List
                Expanded(
                  child:
                      inboxState.isLoading && inboxState.items.isEmpty
                          ? const _LoadingState()
                          : inboxState.items.isEmpty
                          ? const _EmptyState()
                          : ListView.builder(
                            controller: _scrollController,
                            itemCount:
                                inboxState.items.length +
                                (inboxState.isLoading ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index >= inboxState.items.length) {
                                return const _LoadingMoreIndicator();
                              }

                              final item = inboxState.items[index];
                              final isSelected = _selectedItem?.id == item.id;

                              return _InboxItemRow(
                                item: item,
                                isSelected: isSelected,
                                onTap: () => _onItemTap(item),
                                onQuickAction: (action) {
                                  if (action == 'view') {
                                    // Navigate to full task
                                  } else if (action == 'reply') {
                                    // Open reply composer
                                  }
                                },
                              );
                            },
                          ),
                ),
              ],
            ),
          ),
        ),

        // Detail panel
        _detailPanel(),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// INBOX HEADER
// ─────────────────────────────────────────────────────────────────────────────

class _InboxHeader extends StatelessWidget {
  final int unseenCount;

  const _InboxHeader({required this.unseenCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _T.topbarH,
      decoration: const BoxDecoration(
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
            'Your Inbox',
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
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Activity INBOX ITEM ROW
// Shows richer preview with project context, assignees, and quick actions
// ─────────────────────────────────────────────────────────────────────────────

class _InboxItemRow extends StatefulWidget {
  final InboxItem item;
  final bool isSelected;
  final VoidCallback onTap;
  final Function(String action) onQuickAction;

  const _InboxItemRow({
    super.key,
    required this.item,
    required this.isSelected,
    required this.onTap,
    required this.onQuickAction,
  });

  @override
  State<_InboxItemRow> createState() => _InboxItemRowState();
}

class _InboxItemRowState extends State<_InboxItemRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            color:
                widget.isSelected
                    ? _T.blue50
                    : _hovered
                    ? _T.slate50
                    : _T.white,
            border: Border(
              left: BorderSide(
                color: widget.isSelected ? _T.blue : Colors.transparent,
                width: 3,
              ),
              bottom: const BorderSide(color: _T.slate100),
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Project label
              // Row(
              //   children: [
              //     Container(
              //       width: 7.5,
              //       height: 7.5,
              //       margin: const EdgeInsets.only(right: 5),
              //       decoration: BoxDecoration(
              //         color: item.isSeen ? Colors.transparent : _T.blue,
              //         borderRadius: BorderRadius.circular(3),
              //       ),
              //     ),
              //     Text(
              //       "Project",
              //       style: TextStyle(
              //         fontSize: 12,
              //         fontWeight: FontWeight.w500,
              //         color: _hovered ? _T.ink3 : _T.slate400,
              //       ),
              //     ),
              //   ],
              // ),
              // SizedBox(height: 5),

              // Top row: Actor, timestamp, unseen dot
              Row(
                children: [
                  // Actor avatar
                  _buildAvatar(item),
                  const SizedBox(width: 10),

                  // Actor name & action
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeaderText(item),
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

                  // Unseen indicator
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      color: item.isSeen ? Colors.transparent : _T.blue,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Task name with project pill
              Row(
                children: [
                  // Project indicator dot
                  if (item.type == InboxItemType.activity)
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: _T.indigo, // Would be project color
                        shape: BoxShape.circle,
                      ),
                    ),

                  Expanded(
                    child: Text(
                      item.type == InboxItemType.activity
                          ? item.activity!.taskName
                          : 'TASK-${item.message!.taskId}',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: widget.isSelected ? _T.blue : _T.ink,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Activity-specific rich preview
              if (item.type == InboxItemType.activity)
                _buildActivityPreview(item.activity!)
              else
                _buildMessagePreview(item.message!),

              // Bottom row: metadata & quick actions
              // if (_hovered || widget.isSelected) ...[
              //   const SizedBox(height: 10),
              //   Row(
              //     children: [
              //       // Task metadata chips
              //       if (item.type == InboxItemType.activity) ...[
              //         _MetadataPill(
              //           icon: Icons.flag_outlined,
              //           label: _getPriorityName(item.activity!.taskPriority),
              //           color: _getPriorityColor(item.activity!.taskPriority),
              //         ),
              //         const SizedBox(width: 6),
              //         if (item.activity!.taskDueDate != null)
              //           _MetadataPill(
              //             icon: Icons.calendar_today_outlined,
              //             label: _formatShortDate(item.activity!.taskDueDate!),
              //             color: _T.slate500,
              //           ),
              //       ],

              //       const Spacer(),

              //       // Quick actions
              //       _QuickActionButton(
              //         icon: Icons.open_in_new_rounded,
              //         tooltip: 'View task',
              //         onTap: () => widget.onQuickAction('view'),
              //       ),

              //       if (item.type == InboxItemType.message)
              //         _QuickActionButton(
              //           icon: Icons.reply_rounded,
              //           tooltip: 'Reply',
              //           onTap: () => widget.onQuickAction('reply'),
              //         ),
              //     ],
              //   ),
              // ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(InboxItem item) {
    if (item.type == InboxItemType.activity) {
      return AvatarWidget(
        initials: item.activity!.actorInitials,
        color: item.activity!.actorColor ?? _T.ink3,
        size: 32,
      );
    } else {
      return AvatarWidget(
        initials: item.message!.authorInitials,
        color: item.message!.authorColor ?? _T.ink3,
        size: 32,
      );
    }
  }

  Widget _buildHeaderText(InboxItem item) {
    late final String authorName;

    if (item.type == InboxItemType.activity) {
      final activity = item.activity!;

      authorName =
          activity.actorId == LoginService.currentUser!.id
              ? "You"
              : activity.actorName;

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
            TextSpan(
              text: ' ${_getActivityVerb(activity.type)}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    } else {
      authorName =
          item.message!.authorId == LoginService.currentUser!.id
              ? "You"
              : item.message!.authorName;

      return Text(
        '${authorName} commented',
        style: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: _T.ink2,
        ),
      );
    }
  }

  Widget _buildActivityPreview(TaskActivity activity) {
    late final TaskComponentHelper fromStatusHelper;
    late final TaskComponentHelper toStatusHelper;
    if (activity.type == ActivityType.stageBackward ||
        activity.type == ActivityType.stageForward) {
      fromStatusHelper = TaskComponentHelper.get(
        TaskStatus.values.byName(activity.fromStage),
      );
      toStatusHelper = TaskComponentHelper.get(
        TaskStatus.values.byName(activity.toStage),
      );
    }

    switch (activity.type) {
      case ActivityType.stageForward:
      case ActivityType.stageBackward:
        return Row(
          children: [
            _MiniStagePill(
              label: fromStatusHelper.label,
              color: _T.slate500,
              bg: _T.slate100,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Icon(
                activity.type == ActivityType.stageForward
                    ? Icons.arrow_forward
                    : Icons.arrow_back,
                size: 14,
                color: _T.slate300,
              ),
            ),
            _MiniStagePill(
              label: toStatusHelper.label,
              color:
                  activity.type == ActivityType.stageForward
                      ? _T.green
                      : _T.amber,
              bg:
                  activity.type == ActivityType.stageForward
                      ? _T.green50
                      : _T.amber50,
            ),
          ],
        );

      case ActivityType.printerAssigned:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _T.blue50,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: _T.blue.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.print_rounded, size: 14, color: _T.blue),
              const SizedBox(width: 6),
              Text(
                activity.printerNickname ?? activity.printerName ?? '',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _T.blue,
                ),
              ),
            ],
          ),
        );

      case ActivityType.assigneeAdded:
        return Text(
          'Assigned to ${activity.addedUserName}',
          style: const TextStyle(fontSize: 12, color: _T.slate500),
        );

      case ActivityType.priorityChanged:
        return Row(
          children: [
            Text(
              'Priority: ',
              style: const TextStyle(fontSize: 12, color: _T.slate400),
            ),
            _MiniPriorityChip(priority: activity.fromPriority ?? 2),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: Icon(Icons.arrow_forward, size: 12, color: _T.slate300),
            ),
            _MiniPriorityChip(priority: activity.toPriority ?? 2),
          ],
        );

      default:
        return Text(
          activity.taskDescription ?? '',
          style: const TextStyle(fontSize: 12, color: _T.slate500, height: 1.4),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        );
    }
  }

  Widget _buildMessagePreview(Message message) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _T.slate50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _T.slate200),
      ),
      child: Text(
        message.message,
        style: const TextStyle(fontSize: 12.5, color: _T.ink3, height: 1.5),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  String _getActivityVerb(ActivityType type) {
    switch (type) {
      case ActivityType.stageForward:
        return 'progressed';
      case ActivityType.stageBackward:
        return 'moved back';
      case ActivityType.printerAssigned:
        return 'started production job';
      case ActivityType.assigneeAdded:
        return 'assigned';
      case ActivityType.priorityChanged:
        return 'changed priority of';
      case ActivityType.dueDateChanged:
        return 'updated due date for';
      case ActivityType.taskCompleted:
        return 'completed';
      default:
        return 'updated';
    }
  }

  String _formatStage(String stage) => stage
      .split('_')
      .map((w) => w[0].toUpperCase() + w.substring(1))
      .join(' ');

  String _getPriorityName(int p) {
    if (p <= 0 || p > TaskPriority.values.length) return 'Normal';
    return TaskPriority.values[p - 1].name[0].toUpperCase() +
        TaskPriority.values[p - 1].name.substring(1);
  }

  Color _getPriorityColor(int p) {
    if (p <= 0 || p > TaskPriority.values.length) return _T.slate500;
    final priority = TaskPriority.values[p - 1];
    switch (priority) {
      case TaskPriority.normal:
        return _T.slate500;
      case TaskPriority.high:
        return _T.amber;
      case TaskPriority.urgent:
        return _T.red;
    }
  }

  String _formatShortDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays < 1) return 'Today';
    if (diff.inDays < 2) return 'Tomorrow';
    return '${dt.month}/${dt.day}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LOADING & EMPTY STATES
// ─────────────────────────────────────────────────────────────────────────────

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator(strokeWidth: 2));
  }
}

class _LoadingMoreIndicator extends StatelessWidget {
  const _LoadingMoreIndicator();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(20),
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
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
              Icons.notifications_outlined,
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
            'Activity will appear here',
            style: TextStyle(fontSize: 12, color: _T.slate300),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MINI COMPONENTS FOR INBOX PREVIEW
// ─────────────────────────────────────────────────────────────────────────────

class _ActivityTypeBadge extends StatelessWidget {
  final InboxItem item;

  const _ActivityTypeBadge({required this.item});

  @override
  Widget build(BuildContext context) {
    if (item.type == InboxItemType.message) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: _T.purple50,
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Icon(
          Icons.chat_bubble_outline,
          size: 11,
          color: _T.purple,
        ),
      );
    }

    IconData icon;
    Color color;
    Color bg;

    switch (item.activity!.type) {
      case ActivityType.stageForward:
        icon = Icons.trending_up;
        color = _T.green;
        bg = _T.green50;
        break;
      case ActivityType.stageBackward:
        icon = Icons.trending_down;
        color = _T.amber;
        bg = _T.amber50;
        break;
      case ActivityType.printerAssigned:
        icon = Icons.print_rounded;
        color = _T.blue;
        bg = _T.blue50;
        break;
      case ActivityType.priorityChanged:
        icon = Icons.flag_outlined;
        color = _T.red;
        bg = _T.red50;
        break;
      default:
        icon = Icons.notifications_none;
        color = _T.slate500;
        bg = _T.slate100;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(icon, size: 11, color: color),
    );
  }
}

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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
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

class _MetadataPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MetadataPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: _T.slate100,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  State<_QuickActionButton> createState() => _QuickActionButtonState();
}

class _QuickActionButtonState extends State<_QuickActionButton> {
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
            duration: const Duration(milliseconds: 100),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _hovered ? _T.blue50 : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              widget.icon,
              size: 14,
              color: _hovered ? _T.blue : _T.slate400,
            ),
          ),
        ),
      ),
    );
  }
}

class _ActivityDetailPanel extends ConsumerWidget {
  final InboxItem item;
  final VoidCallback onClose;

  const _ActivityDetailPanel({required this.item, required this.onClose});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: _T.detailW,
      decoration: const BoxDecoration(
        color: _T.white,
        border: Border(left: BorderSide(color: _T.slate200)),
      ),
      child: Column(
        children: [
          // Header
          _DetailHeader(onClose: onClose),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child:
                  item.type == InboxItemType.activity
                      ? _ActivityDetailContent(activity: item.activity!)
                      : _MessageDetailContent(message: item.message!),
            ),
          ),

          // Footer action
          _DetailFooter(item: item),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DETAIL HEADER
// ─────────────────────────────────────────────────────────────────────────────

class _DetailHeader extends StatelessWidget {
  final VoidCallback onClose;

  const _DetailHeader({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _T.topbarH,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _T.slate200)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: onClose,
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  border: Border.all(color: _T.slate200),
                  borderRadius: BorderRadius.circular(_T.r),
                ),
                child: const Icon(Icons.close, size: 13, color: _T.slate400),
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'ACTIVITY',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
              color: _T.slate400,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ACTIVITY DETAIL CONTENT
// ─────────────────────────────────────────────────────────────────────────────

class _ActivityDetailContent extends StatelessWidget {
  final TaskActivity activity;

  const _ActivityDetailContent({required this.activity});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Activity header with avatar
        Row(
          children: [
            AvatarWidget(
              initials: activity.actorInitials,
              color: activity.actorColor ?? _T.ink3,
              size: 48,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.actorName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _T.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _getActivityDescription(activity),
                    style: const TextStyle(fontSize: 12.5, color: _T.slate500),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 6),

        // Timestamp
        Text(
          _formatTimestamp(activity.updatedAt),
          style: const TextStyle(fontSize: 11.5, color: _T.slate400),
        ),

        const SizedBox(height: 24),

        // Activity visual
        _ActivityVisual(activity: activity),

        const SizedBox(height: 24),

        // Task info card
        _TaskInfoCard(
          taskName: activity.taskName,
          taskDescription: activity.taskDescription,
          taskPriority: activity.taskPriority,
          taskDueDate: activity.taskDueDate,
          taskStatus: activity.taskStatus,
        ),
      ],
    );
  }

  String _getActivityDescription(TaskActivity activity) {
    switch (activity.type) {
      case ActivityType.stageForward:
        return 'Moved task forward in the pipeline';
      case ActivityType.stageBackward:
        return 'Moved task back to previous stage';
      case ActivityType.printerAssigned:
        return 'Assigned task to a printer';
      case ActivityType.assigneeAdded:
        return 'Assigned ${activity.addedUserName} to task';
      case ActivityType.priorityChanged:
        return 'Changed task priority';
      case ActivityType.dueDateChanged:
        return 'Updated task due date';
      case ActivityType.taskCompleted:
        return 'Marked task as completed';
      default:
        return 'Updated task';
    }
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';

    // Format as date
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ACTIVITY VISUAL
// Large visual representation of what happened
// ─────────────────────────────────────────────────────────────────────────────

class _ActivityVisual extends StatelessWidget {
  final TaskActivity activity;

  const _ActivityVisual({required this.activity});

  @override
  Widget build(BuildContext context) {
    switch (activity.type) {
      case ActivityType.stageForward:
      case ActivityType.stageBackward:
        return _StageChangeVisual(
          fromStage: activity.fromStage,
          toStage: activity.toStage,
          isForward: activity.type == ActivityType.stageForward,
        );

      case ActivityType.printerAssigned:
        return _PrinterAssignedVisual(
          printerName: activity.printerName ?? '',
          printerNickname: activity.printerNickname ?? '',
        );

      case ActivityType.priorityChanged:
        return _PriorityChangeVisual(
          fromPriority: activity.fromPriority ?? 1,
          toPriority: activity.toPriority ?? 1,
        );

      default:
        return const SizedBox.shrink();
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STAGE CHANGE VISUAL
// ─────────────────────────────────────────────────────────────────────────────

class _StageChangeVisual extends StatelessWidget {
  final String fromStage;
  final String toStage;
  final bool isForward;

  const _StageChangeVisual({
    required this.fromStage,
    required this.toStage,
    required this.isForward,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _T.slate50,
        borderRadius: BorderRadius.circular(_T.rLg),
        border: Border.all(color: _T.slate200),
      ),
      child: Row(
        children: [
          Expanded(
            child: _StageBox(
              label: _formatStage(fromStage),
              color: _T.slate400,
              bg: _T.slate100,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Icon(
              isForward
                  ? Icons.arrow_forward_rounded
                  : Icons.arrow_back_rounded,
              size: 20,
              color: isForward ? _T.green : _T.amber,
            ),
          ),
          Expanded(
            child: _StageBox(
              label: _formatStage(toStage),
              color: isForward ? _T.green : _T.amber,
              bg: isForward ? _T.green50 : _T.amber50,
            ),
          ),
        ],
      ),
    );
  }

  String _formatStage(String stage) {
    return stage
        .split('_')
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }
}

class _StageBox extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;

  const _StageBox({required this.label, required this.color, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(_T.r),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PRINTER ASSIGNED VISUAL
// ─────────────────────────────────────────────────────────────────────────────

class _PrinterAssignedVisual extends StatelessWidget {
  final String printerName;
  final String printerNickname;

  const _PrinterAssignedVisual({
    required this.printerName,
    required this.printerNickname,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _T.blue50,
        borderRadius: BorderRadius.circular(_T.rLg),
        border: Border.all(color: _T.blue.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _T.blue.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.print_rounded, size: 24, color: _T.blue),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  printerName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _T.blue,
                  ),
                ),
                if (printerNickname.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    printerNickname,
                    style: TextStyle(
                      fontSize: 12,
                      color: _T.blue.withOpacity(0.7),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _T.green,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, size: 12, color: Colors.white),
                SizedBox(width: 4),
                Text(
                  'Assigned',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
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
// PRIORITY CHANGE VISUAL
// ─────────────────────────────────────────────────────────────────────────────

class _PriorityChangeVisual extends StatelessWidget {
  final int fromPriority;
  final int toPriority;

  const _PriorityChangeVisual({
    required this.fromPriority,
    required this.toPriority,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _T.slate50,
        borderRadius: BorderRadius.circular(_T.rLg),
        border: Border.all(color: _T.slate200),
      ),
      child: Row(
        children: [
          Expanded(
            child: PriorityPill(priority: _priorityFromInt(fromPriority)),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Icon(
              Icons.arrow_forward_rounded,
              size: 18,
              color: _T.slate300,
            ),
          ),
          Expanded(child: PriorityPill(priority: _priorityFromInt(toPriority))),
        ],
      ),
    );
  }

  TaskPriority _priorityFromInt(int p) {
    if (p <= 0 || p > TaskPriority.values.length) {
      return TaskPriority.normal;
    }
    return TaskPriority.values[p - 1];
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TASK INFO CARD
// ─────────────────────────────────────────────────────────────────────────────

class _TaskInfoCard extends StatelessWidget {
  final String taskName;
  final String? taskDescription;
  final int taskPriority;
  final DateTime? taskDueDate;
  final String taskStatus;

  const _TaskInfoCard({
    required this.taskName,
    this.taskDescription,
    required this.taskPriority,
    this.taskDueDate,
    required this.taskStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: _T.slate200),
        borderRadius: BorderRadius.circular(_T.rLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: _T.slate100)),
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: _T.indigo50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.assignment_outlined,
                    size: 13,
                    color: _T.indigo,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Task Details',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: _T.ink2,
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  taskName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _T.ink,
                    height: 1.4,
                  ),
                ),

                if (taskDescription != null && taskDescription!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    taskDescription!,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: _T.slate500,
                      height: 1.5,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                const SizedBox(height: 12),
                const Divider(height: 1, color: _T.slate100),
                const SizedBox(height: 12),

                // Metadata grid
                Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  children: [
                    _MetaChip(
                      icon: Icons.flag_outlined,
                      label: 'Priority',
                      value: _getPriorityLabel(taskPriority),
                      color: _getPriorityColor(taskPriority),
                    ),
                    if (taskDueDate != null)
                      _MetaChip(
                        icon: Icons.calendar_today_outlined,
                        label: 'Due',
                        value: _formatDate(taskDueDate!),
                        color: _T.slate500,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getPriorityLabel(int p) {
    if (p <= 0 || p > TaskPriority.values.length) return 'Normal';
    return TaskPriority.values[p - 1].name[0].toUpperCase() +
        TaskPriority.values[p - 1].name.substring(1);
  }

  Color _getPriorityColor(int p) {
    if (p <= 0 || p > TaskPriority.values.length) return _T.slate500;
    final priority = TaskPriority.values[p - 1];
    switch (priority) {
      case TaskPriority.normal:
        return _T.slate500;
      case TaskPriority.high:
        return _T.amber;
      case TaskPriority.urgent:
        return _T.red;
    }
  }

  String _formatDate(DateTime dt) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}';
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MetaChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: _T.slate400),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 11.5, color: _T.slate400),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MESSAGE DETAIL CONTENT
// ─────────────────────────────────────────────────────────────────────────────

class _MessageDetailContent extends StatelessWidget {
  final Message message;

  const _MessageDetailContent({required this.message});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Message author
        Row(
          children: [
            AvatarWidget(
              initials: message.authorInitials,
              color: message.authorColor ?? _T.ink3,
              size: 48,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.authorName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _T.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Posted a message',
                    style: TextStyle(fontSize: 12.5, color: _T.slate500),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 18),

        // Message content
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _T.slate50,
            borderRadius: BorderRadius.circular(_T.rLg),
            border: Border.all(color: _T.slate200),
          ),
          child: Text(
            message.message,
            style: const TextStyle(fontSize: 13.5, color: _T.ink2, height: 1.6),
          ),
        ),

        const SizedBox(height: 18),

        // Task reference
        Text(
          'TASK-${message.taskId}',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: _T.slate400,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DETAIL FOOTER
// ─────────────────────────────────────────────────────────────────────────────

class _DetailFooter extends StatelessWidget {
  final InboxItem item;

  const _DetailFooter({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: _T.slate200)),
      ),
      padding: const EdgeInsets.all(16),
      child: _ViewTaskButton(taskId: item.taskId),
    );
  }
}

class _ViewTaskButton extends StatefulWidget {
  final int taskId;

  const _ViewTaskButton({required this.taskId});

  @override
  State<_ViewTaskButton> createState() => _ViewTaskButtonState();
}

class _ViewTaskButtonState extends State<_ViewTaskButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () {
          // Navigate to task detail
          // Navigator.of(context).push(...)
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: _hovered ? _T.blueHover : _T.blue,
            borderRadius: BorderRadius.circular(_T.r),
            boxShadow: [
              BoxShadow(
                color: _T.blue.withOpacity(0.25),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.open_in_new_rounded, size: 15, color: Colors.white),
              SizedBox(width: 8),
              Text(
                'View Full Task',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

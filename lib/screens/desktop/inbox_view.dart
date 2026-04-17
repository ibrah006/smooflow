// ═════════════════════════════════════════════════════════════════════════════
// INBOX VIEW - Main Screen
// ═════════════════════════════════════════════════════════════════════════════
// FILE: lib/screens/desktop/inbox_view.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/constants.dart';
import 'package:smooflow/core/models/message.dart';
import 'package:smooflow/core/models/task_activity.dart';
import 'package:smooflow/data/inbox_item.dart';
import 'package:smooflow/enums/task_priority.dart';
import 'package:smooflow/enums/task_status.dart';
import 'package:smooflow/providers/inbox_provider.dart';
import 'package:smooflow/screens/desktop/components/avatar_widget.dart';
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
  static const sidebarW = 220.0;
  static const topbarH = 52.0;
  static const detailW = 420.0;
  static const r = 8.0;
  static const rLg = 12.0;
  static const rXl = 16.0;
}

// ─────────────────────────────────────────────────────────────────────────────
// INBOX VIEW
// ─────────────────────────────────────────────────────────────────────────────

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
      () => ref.read(inboxNotifierProvider.notifier).fetchInbox(),
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
        ref.read(inboxNotifierProvider.notifier).fetchInbox();
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

  @override
  Widget build(BuildContext context) {
    // final inboxState = ref.watch(inboxNotifierProvider);

    final inboxState = InboxState(items: sampleInboxItems);

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
        // if (_selectedItem != null)
        _ActivityDetailPanel(
          item: _selectedItem,
          onClose: _closeDetail,
          isSelected: _selectedItem != null,
        ),
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
            child: const Icon(Icons.inbox_rounded, size: 16, color: _T.blue),
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
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// INBOX ITEM ROW
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
              // Top row: Actor, timestamp, unseen dot
              Row(
                children: [
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

                  // Activity type badge
                  _ActivityTypeBadge(item: item),
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
              if (_hovered || widget.isSelected) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    // Task metadata chips
                    if (item.type == InboxItemType.activity) ...[
                      _MetadataPill(
                        icon: Icons.flag_outlined,
                        label: _getPriorityName(item.activity!.taskPriority),
                        color: _getPriorityColor(item.activity!.taskPriority),
                      ),
                      const SizedBox(width: 6),
                      if (item.activity!.taskDueDate != null)
                        _MetadataPill(
                          icon: Icons.calendar_today_outlined,
                          label: _formatShortDate(item.activity!.taskDueDate!),
                          color: _T.slate500,
                        ),
                    ],

                    const Spacer(),

                    // Quick actions
                    _QuickActionButton(
                      icon: Icons.open_in_new_rounded,
                      tooltip: 'View task',
                      onTap: () => widget.onQuickAction('view'),
                    ),

                    if (item.type == InboxItemType.message)
                      _QuickActionButton(
                        icon: Icons.reply_rounded,
                        tooltip: 'Reply',
                        onTap: () => widget.onQuickAction('reply'),
                      ),
                  ],
                ),
              ],
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
    if (item.type == InboxItemType.activity) {
      final activity = item.activity!;
      return RichText(
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        text: TextSpan(
          style: const TextStyle(fontSize: 12.5, color: _T.ink2, height: 1.3),
          children: [
            TextSpan(
              text: activity.actorName,
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
      return Text(
        '${item.message!.authorName} commented',
        style: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: _T.ink2,
        ),
      );
    }
  }

  Widget _buildActivityPreview(TaskActivity activity) {
    switch (activity.type) {
      case ActivityType.stageForward:
      case ActivityType.stageBackward:
        return Row(
          children: [
            _MiniStagePill(
              label: _formatStage(activity.fromStage),
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
              label: _formatStage(activity.toStage),
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
        return 'assigned printer to';
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

// ─────────────────────────────────────────────────────────────────────────────
// STAGE PILL (mini)
// ─────────────────────────────────────────────────────────────────────────────

class _StagePill extends StatelessWidget {
  final String label;
  final bool isFrom;

  const _StagePill({required this.label, required this.isFrom});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: isFrom ? _T.slate100 : _T.blue50,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: isFrom ? _T.slate200 : _T.blue.withOpacity(0.3),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: isFrom ? _T.slate500 : _T.blue,
        ),
      ),
    );
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
              Icons.inbox_rounded,
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

// ═════════════════════════════════════════════════════════════════════════════
// Inbox/Activity DETAIL PANEL
// ═════════════════════════════════════════════════════════════════════════════
// Features:
// 1. Full task context (project, assignees, dates, specs)
// 2. Activity timeline (related activities for this task)
// 3. Contextual actions (Reply, Progress, Reassign, etc.)
// 4. File attachments for messages
// 5. Inline compose for replies
// 6. Task progression controls
// 7. Assignee management
// 8. Related tasks/dependencies
// ═════════════════════════════════════════════════════════════════════════════

class _ActivityDetailPanel extends ConsumerStatefulWidget {
  final InboxItem? item;
  final VoidCallback onClose;
  final bool isSelected;

  const _ActivityDetailPanel({
    super.key,
    required this.item,
    required this.onClose,
    required this.isSelected,
  });

  @override
  ConsumerState<_ActivityDetailPanel> createState() =>
      _ComprehensiveDetailPanelState();
}

class _ComprehensiveDetailPanelState
    extends ConsumerState<_ActivityDetailPanel> {
  final TextEditingController _replyController = TextEditingController();
  bool _isReplying = false;
  bool _isSendingReply = false;

  // Simulated task data - would come from providers
  TaskStatus? _currentTaskStatus;
  List<String> _assignees = [];

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  void _startReply() {
    setState(() => _isReplying = true);
  }

  void _cancelReply() {
    setState(() {
      _isReplying = false;
      _replyController.clear();
    });
  }

  Future<void> _sendReply() async {
    if (_replyController.text.trim().isEmpty) return;

    setState(() => _isSendingReply = true);

    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    // TODO: Actual API call to send message
    // await ref.read(messageNotifierProvider.notifier).sendMessage(...)

    if (mounted) {
      setState(() {
        _isSendingReply = false;
        _isReplying = false;
        _replyController.clear();
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Reply sent!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      width: widget.isSelected ? _T.detailW : 0,
      child:
          widget.item == null
              ? const SizedBox()
              : Container(
                decoration: const BoxDecoration(
                  color: _T.white,
                  border: Border(left: BorderSide(color: _T.slate200)),
                ),
                child: Column(
                  children: [
                    // Header with close and actions
                    _DetailHeader(item: widget.item!, onClose: widget.onClose),

                    // Scrollable content
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Main content based on type
                            if (widget.item!.type == InboxItemType.activity)
                              _ActivityFullDetail(
                                activity: widget.item!.activity!,
                              )
                            else
                              _MessageFullDetail(
                                message: widget.item!.message!,
                              ),

                            const SizedBox(height: 24),

                            // Task context card
                            _TaskContextCard(item: widget.item!),

                            const SizedBox(height: 20),

                            // Recent activity timeline for this task
                            const _SectionTitle('Recent Activity'),
                            const SizedBox(height: 12),
                            _ActivityTimeline(taskId: widget.item!.taskId),

                            const SizedBox(height: 20),

                            // Related information
                            if (widget.item!.type == InboxItemType.activity &&
                                widget.item!.activity!.type ==
                                    ActivityType.printerAssigned) ...[
                              const _SectionTitle('Printer Details'),
                              const SizedBox(height: 12),
                              _PrinterDetailCard(
                                activity: widget.item!.activity!,
                              ),
                              const SizedBox(height: 20),
                            ],

                            // Message attachments
                            if (widget.item!.type == InboxItemType.message) ...[
                              const _SectionTitle('Discussion'),
                              const SizedBox(height: 12),
                              _MessageAttachments(
                                message: widget.item!.message!,
                              ),
                              const SizedBox(height: 20),
                            ],
                          ],
                        ),
                      ),
                    ),

                    // Footer with actions
                    _DetailFooter(
                      item: widget.item!,
                      isReplying: _isReplying,
                      isSendingReply: _isSendingReply,
                      replyController: _replyController,
                      onStartReply: _startReply,
                      onCancelReply: _cancelReply,
                      onSendReply: _sendReply,
                    ),
                  ],
                ),
              ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DETAIL HEADER with context actions
// ─────────────────────────────────────────────────────────────────────────────

class _DetailHeader extends StatelessWidget {
  final InboxItem item;
  final VoidCallback onClose;

  const _DetailHeader({required this.item, required this.onClose});

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
          // Close button
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: onClose,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  border: Border.all(color: _T.slate200),
                  borderRadius: BorderRadius.circular(_T.r),
                ),
                child: const Icon(Icons.close, size: 14, color: _T.slate400),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Type badge
          _TypeBadge(item: item),
          const SizedBox(width: 10),

          // Task ID
          Text(
            'TASK-${item.taskId}',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              color: _T.slate400,
            ),
          ),

          const Spacer(),

          // More actions
          _HeaderActionButton(
            icon: Icons.more_vert,
            tooltip: 'More options',
            onTap: () {
              // Show options menu
            },
          ),
        ],
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final InboxItem item;

  const _TypeBadge({required this.item});

  @override
  Widget build(BuildContext context) {
    if (item.type == InboxItemType.message) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _T.purple50,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.chat_bubble_outline, size: 12, color: _T.purple),
            const SizedBox(width: 5),
            const Text(
              'MESSAGE',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: _T.purple,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _T.blue50,
        borderRadius: BorderRadius.circular(5),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.notifications_active_outlined, size: 12, color: _T.blue),
          SizedBox(width: 5),
          Text(
            'ACTIVITY',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: _T.blue,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderActionButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _HeaderActionButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  State<_HeaderActionButton> createState() => _HeaderActionButtonState();
}

class _HeaderActionButtonState extends State<_HeaderActionButton> {
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
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: _hovered ? _T.slate100 : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: _hovered ? _T.slate200 : Colors.transparent,
              ),
            ),
            child: Icon(
              widget.icon,
              size: 16,
              color: _hovered ? _T.ink3 : _T.slate400,
            ),
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// COMPREHENSIVE DETAIL PANEL - Part 2
// Visual Components, Task Context, Timeline, Actions
// ═════════════════════════════════════════════════════════════════════════════

// ─────────────────────────────────────────────────────────────────────────────
// LARGE VISUAL COMPONENTS (Enhanced from before)
// ─────────────────────────────────────────────────────────────────────────────

class _LargeStageChangeVisual extends StatelessWidget {
  final String fromStage;
  final String toStage;
  final bool isForward;

  const _LargeStageChangeVisual({
    required this.fromStage,
    required this.toStage,
    required this.isForward,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors:
              isForward
                  ? [_T.green50, _T.green50.withOpacity(0.3)]
                  : [_T.amber50, _T.amber50.withOpacity(0.3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(_T.rLg),
        border: Border.all(
          color:
              isForward ? _T.green.withOpacity(0.3) : _T.amber.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _StageVisualization(
                  stage: fromStage,
                  label: 'FROM',
                  isHighlight: false,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    Icon(
                      isForward
                          ? Icons.arrow_forward_rounded
                          : Icons.arrow_back_rounded,
                      size: 28,
                      color: isForward ? _T.green : _T.amber,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isForward ? 'FORWARD' : 'BACKWARD',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: isForward ? _T.green : _T.amber,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _StageVisualization(
                  stage: toStage,
                  label: 'TO',
                  isHighlight: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StageVisualization extends StatelessWidget {
  final String stage;
  final String label;
  final bool isHighlight;

  const _StageVisualization({
    required this.stage,
    required this.label,
    required this.isHighlight,
  });

  @override
  Widget build(BuildContext context) {
    final si = kStages.firstWhere(
      (s) => s.stage.name.toLowerCase() == stage.toLowerCase(),
      orElse: () => kStages.first,
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isHighlight ? si.bg : _T.slate50,
        borderRadius: BorderRadius.circular(_T.r),
        border: Border.all(
          color: isHighlight ? si.color.withOpacity(0.4) : _T.slate200,
          width: isHighlight ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: isHighlight ? si.color : _T.slate400,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Icon(si., size: 24, color: isHighlight ? si.color : _T.slate400),
          const SizedBox(height: 8),
          Text(
            si.label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isHighlight ? si.color : _T.slate500,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _LargePrinterVisual extends StatelessWidget {
  final String printerName;
  final String printerNickname;

  const _LargePrinterVisual({
    required this.printerName,
    required this.printerNickname,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_T.blue50, _T.blue50.withOpacity(0.3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(_T.rLg),
        border: Border.all(color: _T.blue.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: _T.blue.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(color: _T.blue.withOpacity(0.3), width: 2),
            ),
            child: const Icon(Icons.print_rounded, size: 32, color: _T.blue),
          ),
          const SizedBox(height: 16),
          Text(
            printerName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _T.blue,
            ),
          ),
          if (printerNickname.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              printerNickname,
              style: TextStyle(fontSize: 13, color: _T.blue.withOpacity(0.7)),
            ),
          ],
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _T.green,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, size: 14, color: Colors.white),
                SizedBox(width: 6),
                Text(
                  'Printer Assigned',
                  style: TextStyle(
                    fontSize: 12,
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

class _LargePriorityChangeVisual extends StatelessWidget {
  final int fromPriority;
  final int toPriority;

  const _LargePriorityChangeVisual({
    required this.fromPriority,
    required this.toPriority,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _T.slate50,
        borderRadius: BorderRadius.circular(_T.rLg),
        border: Border.all(color: _T.slate200),
      ),
      child: Row(
        children: [
          Expanded(child: _PriorityCard(priority: fromPriority, label: 'FROM')),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Icon(
              Icons.arrow_forward_rounded,
              size: 24,
              color: _T.slate300,
            ),
          ),
          Expanded(
            child: _PriorityCard(
              priority: toPriority,
              label: 'TO',
              isHighlight: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _PriorityCard extends StatelessWidget {
  final int priority;
  final String label;
  final bool isHighlight;

  const _PriorityCard({
    required this.priority,
    required this.label,
    this.isHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final p =
        priority <= 0 || priority > TaskPriority.values.length
            ? TaskPriority.normal
            : TaskPriority.values[priority - 1];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isHighlight ? _getPriorityBg(p) : _T.white,
        borderRadius: BorderRadius.circular(_T.r),
        border: Border.all(
          color:
              isHighlight ? _getPriorityColor(p).withOpacity(0.4) : _T.slate200,
          width: isHighlight ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: isHighlight ? _getPriorityColor(p) : _T.slate400,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Icon(
            Icons.flag_outlined,
            size: 24,
            color: isHighlight ? _getPriorityColor(p) : _T.slate400,
          ),
          const SizedBox(height: 8),
          Text(
            p.name[0].toUpperCase() + p.name.substring(1),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isHighlight ? _getPriorityColor(p) : _T.slate500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(TaskPriority p) {
    switch (p) {
      case TaskPriority.normal:
        return _T.slate500;
      case TaskPriority.high:
        return _T.amber;
      case TaskPriority.urgent:
        return _T.red;
    }
  }

  Color _getPriorityBg(TaskPriority p) {
    switch (p) {
      case TaskPriority.normal:
        return _T.slate50;
      case TaskPriority.high:
        return _T.amber50;
      case TaskPriority.urgent:
        return _T.red50;
    }
  }
}

class _AssigneeAddedVisual extends StatelessWidget {
  final String userName;

  const _AssigneeAddedVisual({required this.userName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _T.purple50,
        borderRadius: BorderRadius.circular(_T.rLg),
        border: Border.all(color: _T.purple.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.person_add_outlined, size: 48, color: _T.purple),
          const SizedBox(height: 12),
          const Text(
            'Assigned To',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _T.purple,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            userName,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _T.purple,
            ),
          ),
        ],
      ),
    );
  }
}

class _DueDateChangeVisual extends StatelessWidget {
  final String? from;
  final String? to;

  const _DueDateChangeVisual({this.from, this.to});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _T.indigo50,
        borderRadius: BorderRadius.circular(_T.rLg),
        border: Border.all(color: _T.indigo.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Expanded(child: _DateCard(date: from, label: 'FROM')),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Icon(
              Icons.arrow_forward_rounded,
              size: 20,
              color: _T.indigo,
            ),
          ),
          Expanded(child: _DateCard(date: to, label: 'TO', isHighlight: true)),
        ],
      ),
    );
  }
}

class _DateCard extends StatelessWidget {
  final String? date;
  final String label;
  final bool isHighlight;

  const _DateCard({this.date, required this.label, this.isHighlight = false});

  @override
  Widget build(BuildContext context) {
    final dt = date != null ? DateTime.parse(date!) : null;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isHighlight ? _T.white : _T.indigo.withOpacity(0.1),
        borderRadius: BorderRadius.circular(_T.r),
        border: Border.all(
          color:
              isHighlight
                  ? _T.indigo.withOpacity(0.4)
                  : _T.indigo.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: isHighlight ? _T.indigo : _T.indigo.withOpacity(0.7),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Icon(
            Icons.calendar_today_outlined,
            size: 20,
            color: isHighlight ? _T.indigo : _T.indigo.withOpacity(0.7),
          ),
          const SizedBox(height: 6),
          Text(
            dt != null ? '${dt.month}/${dt.day}/${dt.year}' : '—',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: isHighlight ? _T.indigo : _T.indigo.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MESSAGE FULL DETAIL
// ─────────────────────────────────────────────────────────────────────────────

class _MessageFullDetail extends StatelessWidget {
  final Message message;

  const _MessageFullDetail({required this.message});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Author info
        Row(
          children: [
            AvatarWidget(
              initials: message.authorInitials,
              color: message.authorColor ?? _T.ink3,
              size: 52,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.authorName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _T.ink,
                    ),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    'Posted a new message',
                    style: TextStyle(fontSize: 13, color: _T.slate500),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // Timestamp
        Row(
          children: [
            const Icon(Icons.access_time, size: 13, color: _T.slate400),
            const SizedBox(width: 6),
            Text(
              _formatTimestamp(message.date),
              style: const TextStyle(fontSize: 12, color: _T.slate400),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Message content
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _T.slate50,
            borderRadius: BorderRadius.circular(_T.rLg),
            border: Border.all(color: _T.slate200),
          ),
          child: Text(
            message.message,
            style: const TextStyle(fontSize: 14, color: _T.ink2, height: 1.6),
          ),
        ),
      ],
    );
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60)
      return '${diff.inMinutes} minute${diff.inMinutes == 1 ? '' : 's'} ago';
    if (diff.inHours < 24)
      return '${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} ago';

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
    final time =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year} at $time';
  }
}

// Continue in final part...

// ─────────────────────────────────────────────────────────────────────────────
// ACTIVITY FULL DETAIL
// ─────────────────────────────────────────────────────────────────────────────

class _ActivityFullDetail extends StatelessWidget {
  final TaskActivity activity;

  const _ActivityFullDetail({required this.activity});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Actor information
        Row(
          children: [
            AvatarWidget(
              initials: activity.actorInitials,
              color: activity.actorColor ?? _T.ink3,
              size: 52,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.actorName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _T.ink,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _getActivityFullDescription(activity),
                    style: const TextStyle(
                      fontSize: 13,
                      color: _T.slate500,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // Timestamp
        Row(
          children: [
            const Icon(Icons.access_time, size: 13, color: _T.slate400),
            const SizedBox(width: 6),
            Text(
              _formatFullTimestamp(activity.createdAt),
              style: const TextStyle(fontSize: 12, color: _T.slate400),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Large visual for the activity
        _buildActivityVisual(activity),
      ],
    );
  }

  Widget _buildActivityVisual(TaskActivity activity) {
    switch (activity.type) {
      case ActivityType.stageForward:
      case ActivityType.stageBackward:
        return _LargeStageChangeVisual(
          fromStage: activity.fromStage,
          toStage: activity.toStage,
          isForward: activity.type == ActivityType.stageForward,
        );

      case ActivityType.printerAssigned:
        return _LargePrinterVisual(
          printerName: activity.printerName ?? '',
          printerNickname: activity.printerNickname ?? '',
        );

      case ActivityType.priorityChanged:
        return _LargePriorityChangeVisual(
          fromPriority: activity.fromPriority ?? 2,
          toPriority: activity.toPriority ?? 2,
        );

      case ActivityType.assigneeAdded:
        return _AssigneeAddedVisual(userName: activity.addedUserName);

      case ActivityType.dueDateChanged:
        return _DueDateChangeVisual(
          from: activity.metadata?['fromDueDate'],
          to: activity.metadata?['toDueDate'],
        );

      default:
        return const SizedBox.shrink();
    }
  }

  String _getActivityFullDescription(TaskActivity activity) {
    switch (activity.type) {
      case ActivityType.stageForward:
        return 'Progressed this task forward in the workflow pipeline';
      case ActivityType.stageBackward:
        return 'Moved this task back to a previous stage for revision';
      case ActivityType.printerAssigned:
        return 'Assigned this task to a printer and started production';
      case ActivityType.assigneeAdded:
        return 'Assigned ${activity.addedUserName} to work on this task';
      case ActivityType.priorityChanged:
        return 'Updated the task priority level';
      case ActivityType.dueDateChanged:
        return 'Changed the due date for this task';
      case ActivityType.taskCompleted:
        return 'Marked this task as completed';
      default:
        return 'Made changes to this task';
    }
  }

  String _formatFullTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60)
      return '${diff.inMinutes} minute${diff.inMinutes == 1 ? '' : 's'} ago';
    if (diff.inHours < 24)
      return '${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} ago';
    if (diff.inDays < 7)
      return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';

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
    final time =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year} at $time';
  }
}

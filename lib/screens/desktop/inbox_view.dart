// ═════════════════════════════════════════════════════════════════════════════
// INBOX VIEW - Main Screen
// ═════════════════════════════════════════════════════════════════════════════
// FILE: lib/screens/desktop/inbox_view.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/core/models/message.dart';
import 'package:smooflow/core/models/task_activity.dart';
import 'package:smooflow/data/inbox_item.dart';
import 'package:smooflow/enums/task_priority.dart';
import 'package:smooflow/providers/inbox_provider.dart';
import 'package:smooflow/screens/desktop/components/avatar_widget.dart';
import 'package:smooflow/screens/desktop/components/priority_pill.dart';
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
    Future.microtask(() => ref.read(inboxProvider.notifier).fetchInbox());

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
      final inboxState = ref.read(inboxProvider);
      if (!inboxState.isLoading && inboxState.hasMore) {
        ref.read(inboxProvider.notifier).fetchInbox();
      }
    }
  }

  void _onItemTap(InboxItem item) {
    setState(() => _selectedItem = item);

    // Mark as seen if it's an activity
    if (item.type == InboxItemType.activity && !item.isSeen) {
      ref.read(inboxProvider.notifier).markActivitySeen(item.activity!.id);
    }
  }

  void _closeDetail() {
    setState(() => _selectedItem = null);
  }

  @override
  Widget build(BuildContext context) {
    final inboxState = ref.watch(inboxProvider);

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
                              );
                            },
                          ),
                ),
              ],
            ),
          ),
        ),

        // Detail panel
        if (_selectedItem != null)
          _ActivityDetailPanel(item: _selectedItem!, onClose: _closeDetail),
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

  const _InboxItemRow({
    required this.item,
    required this.isSelected,
    required this.onTap,
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Unseen indicator dot
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 6, right: 12),
                decoration: BoxDecoration(
                  color: item.isSeen ? Colors.transparent : _T.blue,
                  shape: BoxShape.circle,
                ),
              ),

              // Actor avatar
              _buildAvatar(item),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header line
                    Row(
                      children: [
                        Expanded(child: _buildHeaderText(item)),
                        const SizedBox(width: 8),
                        Text(
                          timeago.format(item.timestamp),
                          style: const TextStyle(
                            fontSize: 11,
                            color: _T.slate400,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // Task name
                    Text(
                      item.type == InboxItemType.activity
                          ? item.activity!.taskName
                          : 'TASK-${item.message!.taskId}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: widget.isSelected ? _T.blue : _T.ink2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Activity-specific content
                    if (item.type == InboxItemType.activity) ...[
                      const SizedBox(height: 2),
                      _buildActivityContent(item.activity!),
                    ],

                    // Message preview
                    if (item.type == InboxItemType.message) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.message!.message,
                        style: const TextStyle(
                          fontSize: 12,
                          color: _T.slate500,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
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
        size: 34,
      );
    } else {
      return AvatarWidget(
        initials: item.message!.authorInitials,
        color: item.message!.authorColor ?? _T.ink3,
        size: 34,
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
          style: const TextStyle(fontSize: 12.5, color: _T.ink3),
          children: [
            TextSpan(
              text: activity.actorName,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(text: ' ${_getActivityVerb(activity.type)}'),
          ],
        ),
      );
    } else {
      return Text(
        item.message!.authorName,
        style: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: _T.ink3,
        ),
      );
    }
  }

  Widget _buildActivityContent(TaskActivity activity) {
    switch (activity.type) {
      case ActivityType.stageForward:
      case ActivityType.stageBackward:
        return Row(
          children: [
            _StagePill(label: _formatStage(activity.fromStage), isFrom: true),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: Icon(Icons.arrow_forward, size: 12, color: _T.slate300),
            ),
            _StagePill(label: _formatStage(activity.toStage), isFrom: false),
          ],
        );

      case ActivityType.printerAssigned:
        return Row(
          children: [
            const Icon(Icons.print_rounded, size: 13, color: _T.blue),
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
        );

      default:
        return const SizedBox.shrink();
    }
  }

  String _getActivityVerb(ActivityType type) {
    switch (type) {
      case ActivityType.stageForward:
        return 'moved task forward';
      case ActivityType.stageBackward:
        return 'moved task back';
      case ActivityType.printerAssigned:
        return 'assigned printer';
      case ActivityType.assigneeAdded:
        return 'assigned task';
      case ActivityType.priorityChanged:
        return 'changed priority';
      case ActivityType.dueDateChanged:
        return 'changed due date';
      case ActivityType.taskCompleted:
        return 'completed task';
      default:
        return 'updated task';
    }
  }

  String _formatStage(String stage) {
    return stage
        .split('_')
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
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
// ACTIVITY DETAIL PANEL
// ═════════════════════════════════════════════════════════════════════════════
// Continuation of inbox_view.dart

// ─────────────────────────────────────────────────────────────────────────────
// ACTIVITY DETAIL PANEL
// Focused view showing essential task info + activity context
// ─────────────────────────────────────────────────────────────────────────────

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
          _formatTimestamp(activity.createdAt),
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

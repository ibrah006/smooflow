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

class _InboxViewState extends ConsumerState<InboxView>
    with WidgetsBindingObserver {
  InboxItem? _selectedItem;
  final ScrollController _scroll = ScrollController();

  // Only for INITIAL messages is loading
  bool _isLoadingInbox = true;

  Future<void> initializeInbox() async {
    await Future.microtask(() async {
      if (!_scroll.hasClients) return;

      final maxScrollExtent = _scroll.position.maxScrollExtent;

      // If no scrolling possible → content too small
      if (maxScrollExtent == 0) {
        final newInboxCount =
            await ref.read(inboxNotifierProvider.notifier).fetchRecentInbox();

        if (newInboxCount > 0) {
          // Schedule again after next frame
          WidgetsBinding.instance.addPostFrameCallback((_) {
            // To ensure contents fill the view port height
            initializeInbox();
          });
        }
      }
    });
  }

  @override
  void initState() {
    super.initState();

    // Load inbox on mount
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print(
        "[Inbox View, initState] inbox scroll has clients: ${_scroll.hasClients}",
      );

      initializeInbox().then((value) {
        if (mounted)
          setState(() {
            _isLoadingInbox = false;
          });
      });
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
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
                showFooter: false,
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
                      inboxState.items.isEmpty && !_isLoadingInbox
                          ? const _EmptyState()
                          : ListView.builder(
                            controller: _scroll,
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

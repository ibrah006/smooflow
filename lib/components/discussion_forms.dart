// ─────────────────────────────────────────────────────────────────────────────
// DISCUSSION PANEL
//
// Two components:
//
//  1. _DiscussionPreviewStrip  — compact strip shown in the detail panel body
//     (non-admin only). Shows last message + unread count. Tapping "Open
//     Discussion" slides the sheet up.
//
//  2. _DiscussionSheet  — full discussion drawer that slides up from the
//     bottom of the detail panel. Constrained to the panel's own bounds.
//     Desktop-tailored: no drag handle, no global scrim, sharp header,
//     proper compose area.
//
// Usage — wrap the detail panel's Column in a Stack and add:
//
//   Stack(
//     children: [
//       Column(children: [ ...existing panel content... ]),
//       if (!isAdmin)
//         _DiscussionSheet(
//           taskId:   task.id,
//           isOpen:   _discussionOpen,
//           onClose:  () => setState(() => _discussionOpen = false),
//         ),
//     ],
//   )
//
// And add the strip inside the scrollable body (above the footer section):
//
//   if (!isAdmin)
//     _DiscussionPreviewStrip(
//       lastMessage: ...,          // wire from your message provider
//       unreadCount: ...,
//       onOpen: () => setState(() => _discussionOpen = true),
//     ),
// ─────────────────────────────────────────────────────────────────────────────

import 'package:card_loading/card_loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/core/models/message.dart';
import 'package:smooflow/core/repositories/task_repo.dart';
import 'package:smooflow/core/services/login_service.dart';
import 'package:smooflow/providers/message_provider.dart';
import 'package:smooflow/providers/task_provider.dart';
import 'package:smooflow/screens/desktop/components/avatar_widget.dart';
import 'package:visibility_detector/visibility_detector.dart';

// ─────────────────────────────────────────────────────────────────────────────
// LOCAL DESIGN TOKENS  (mirrors _T from detail_panel.dart)
// ─────────────────────────────────────────────────────────────────────────────
class _T {
  static const blue = Color(0xFF2563EB);
  static const blueHover = Color(0xFF1D4ED8);
  static const blue50 = Color(0xFFEFF6FF);
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
  static const topbarH = 52.0;
  static const r = 8.0;
  static const rLg = 12.0;
}

// ─────────────────────────────────────────────────────────────────────────────
// COMPACT PREVIEW STRIP
//
// Shown in the scrollable body of the detail panel (non-admin only).
// Displays the last message author + truncated body, optional unread badge,
// and an "Open Discussion" action button.
//
// When there are no messages yet, shows an empty-state prompt instead.
// ─────────────────────────────────────────────────────────────────────────────
class DiscussionPreviewStrip extends ConsumerStatefulWidget {
  final int taskId;

  /// Number of unread messages. 0 hides the badge.
  final int unreadCount;

  /// Called when the user taps "Open Discussion".
  final VoidCallback onOpen;

  const DiscussionPreviewStrip({
    super.key,
    required this.unreadCount,
    required this.onOpen,
    required this.taskId,
  });

  @override
  ConsumerState<DiscussionPreviewStrip> createState() =>
      _DiscussionPreviewStripState();
}

class _DiscussionPreviewStripState
    extends ConsumerState<DiscussionPreviewStrip> {
  bool _hovered = false;

  // Is loading
  bool _isLoading = false;

  @override
  initState() {
    super.initState();

    Future.microtask(() async {
      //   setState(() {
      //     _isLoading = true;
      //   });

      //   final task = ref.read(taskByIdProviderSimple(widget.taskId));
      //   final messages = ref.read(messagesByTaskProvider(widget.taskId));

      //   final lastMessageId = messages.lastOrNull?.id;
      //   if (lastMessageId != task!.lastMessageId) {
      //     // Need to fetch the recent messages to update the preview
      //     await ref
      //         .read(messageNotifierProvider.notifier)
      //         .getMessagesAfter(afterMessageId: lastMessageId, taskId: task.id);
      //   }

      //   if (mounted)
      //     setState(() {
      //       _isLoading = false;
      //     });
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(messageNotifierProvider).isLoading;

    // First message in the state's list is the last one because that is the order as returned from the server
    final lastMessage =
        ref.watch(messagesByTaskProvider(widget.taskId)).firstOrNull;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section label row
          Row(
            children: [
              const Text(
                'DISCUSSION',
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  color: _T.slate400,
                ),
              ),
              if (isLoading)
                CardLoading(
                  height: 14,
                  width: 25,
                  margin: EdgeInsets.only(left: 7),
                  borderRadius: BorderRadius.circular(20),
                )
              else if (widget.unreadCount > 0) ...[
                const SizedBox(width: 7),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: _T.blue,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    '${widget.unreadCount}',
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),

          // Card
          MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) => setState(() => _hovered = true),
            onExit: (_) => setState(() => _hovered = false),
            child: GestureDetector(
              onTap: widget.onOpen,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                decoration: BoxDecoration(
                  color: _hovered ? _T.slate50 : _T.white,
                  borderRadius: BorderRadius.circular(_T.rLg),
                  border: Border.all(
                    color: _hovered ? _T.slate300 : _T.slate200,
                  ),
                ),
                child:
                    isLoading
                        ? const _DiscussionLoadingPreview()
                        : lastMessage == null
                        ? _EmptyDiscussionPreview(hovered: _hovered)
                        : _LastMessagePreview(
                          lastMessage: lastMessage,
                          unreadCount: widget.unreadCount,
                          hovered: _hovered,
                        ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DiscussionLoadingPreview extends StatefulWidget {
  const _DiscussionLoadingPreview();

  @override
  State<_DiscussionLoadingPreview> createState() =>
      _DiscussionLoadingPreviewState();
}

class _DiscussionLoadingPreviewState extends State<_DiscussionLoadingPreview>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _shimmer;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _shimmer = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmer,
      builder: (_, __) {
        final t = (_shimmer.value * 2 - 1).abs(); // 0→1→0 ping-pong
        final shimmerColor = Color.lerp(_T.slate100, _T.slate200, t)!;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar placeholder
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: shimmerColor,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Author name bar
                    Container(
                      height: 10,
                      width: 90,
                      decoration: BoxDecoration(
                        color: shimmerColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Message line 1
                    Container(
                      height: 9,
                      decoration: BoxDecoration(
                        color: shimmerColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Message line 2 (shorter)
                    Container(
                      height: 9,
                      width: 120,
                      decoration: BoxDecoration(
                        color: shimmerColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Empty state inside the preview card
class _EmptyDiscussionPreview extends StatelessWidget {
  final bool hovered;
  const _EmptyDiscussionPreview({required this.hovered});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _T.slate100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.chat_bubble_outline_rounded,
              size: 15,
              color: _T.slate400,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'No messages yet',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: _T.ink3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Start the discussion for this task',
                  style: const TextStyle(fontSize: 11, color: _T.slate400),
                ),
              ],
            ),
          ),
          _OpenChevron(hovered: hovered),
        ],
      ),
    );
  }
}

// Last message preview inside the card
class _LastMessagePreview extends StatelessWidget {
  final Message lastMessage;
  final int unreadCount;
  final bool hovered;

  const _LastMessagePreview({
    required this.lastMessage,
    required this.unreadCount,
    required this.hovered,
  });

  String _relativeTime(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          AvatarWidget(
            initials: lastMessage.authorInitials,
            color: lastMessage.authorColor ?? _T.ink3,
            size: 30,
          ),
          const SizedBox(width: 10),

          // Author + message
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      lastMessage.userId == LoginService.currentUser!.id
                          ? "You"
                          : lastMessage.authorName,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _T.ink2,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _relativeTime(lastMessage.date),
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: _T.slate400,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  lastMessage.message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: _T.slate500,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),
          _OpenChevron(hovered: hovered),
        ],
      ),
    );
  }
}

// Shared "open" chevron used in both preview states
class _OpenChevron extends StatelessWidget {
  final bool hovered;
  const _OpenChevron({required this.hovered});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: hovered ? _T.slate100 : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: hovered ? _T.slate200 : Colors.transparent),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(6)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Open',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: hovered ? _T.ink3 : _T.slate500,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_up_rounded,
              size: 13,
              color: hovered ? _T.ink3 : _T.slate400,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DISCUSSION SHEET
//
// Slides up from the bottom of the detail panel. The panel must be wrapped
// in a Stack with clipBehavior: Clip.hardEdge so the sheet is clipped to the
// panel bounds.
//
// The sheet covers ~72% of the panel height. It has:
//   • A drag-less desktop header with task ID + close button
//   • A scrollable message list (newest at bottom)
//   • A compose area (text field + send button)
//
// The outer Stack in DetailPanel should look like:
//
//   Stack(
//     clipBehavior: Clip.hardEdge,
//     children: [
//       Column(children: [...existing panel...]),
//       DiscussionSheet(
//         taskId:   widget.task.id,
//         isOpen:   _discussionOpen,
//         messages: _messages,           // wire from provider
//         onClose:  () => setState(() => _discussionOpen = false),
//         onSend:   (text) { /* call provider */ },
//       ),
//     ],
//   )
// ─────────────────────────────────────────────────────────────────────────────
class _MessageList extends ConsumerStatefulWidget {
  final List<Message> messages;
  final ScrollController scroll;
  final bool isMessagesInitLoading;

  const _MessageList({
    required this.messages,
    required this.scroll,
    required this.isMessagesInitLoading,
  });

  @override
  ConsumerState<_MessageList> createState() => _MessageListState();
}

class _MessageListState extends ConsumerState<_MessageList>
    with SingleTickerProviderStateMixin {
  bool _isLoadingMessagesAfter = false;
  bool _isLoadingMessagesBefore = false;

  // Animation for newly loaded messages
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  final Map<int, bool> _newlyLoadedIds = {};

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
  }

  @override
  void didUpdateWidget(_MessageList oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Detect newly loaded messages and animate them in
    if (widget.messages.length > oldWidget.messages.length) {
      final newMessages =
          widget.messages
              .where((m) => !oldWidget.messages.any((om) => om.id == m.id))
              .toList();

      for (final msg in newMessages) {
        _newlyLoadedIds[msg.id] = true;
      }

      _fadeController.reset();
      _fadeController.forward().then((_) {
        // Clean up after animation
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            setState(() => _newlyLoadedIds.clear());
          }
        });
      });
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  bool _isSameAuthorAsPrevious(int i) {
    if (i == widget.messages.length - 1) return false;
    return widget.messages[i].authorName == widget.messages[i + 1].authorName;
  }

  String _fmtTime(DateTime t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> getMessagesAfter(Message message) async {
    if (_isLoadingMessagesAfter) return;

    final task = ref.read(taskByIdProviderSimple(message.taskId))!;

    if (task.lastMessageId == null || message.id >= task.lastMessageId!) {
      return;
    }

    setState(() => _isLoadingMessagesAfter = true);

    try {
      await ref
          .read(messageNotifierProvider.notifier)
          .getMessagesAfter(taskId: message.taskId, afterMessageId: message.id);
    } finally {
      if (mounted) {
        setState(() => _isLoadingMessagesAfter = false);
      }
    }
  }

  Future<void> getMessagesBefore(Message message) async {
    if (_isLoadingMessagesBefore) return;

    final task = ref.read(taskByIdProviderSimple(message.taskId))!;

    if (task.firstMessageId == null || message.id <= task.firstMessageId!) {
      return;
    }

    setState(() => _isLoadingMessagesBefore = true);

    try {
      await ref
          .read(messageNotifierProvider.notifier)
          .getMessagesBefore(
            taskId: message.taskId,
            beforeMessageId: message.id,
          );
    } finally {
      if (mounted) {
        setState(() => _isLoadingMessagesBefore = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Initial loading state
    if (widget.isMessagesInitLoading) {
      return _SkeletonMessageList();
    }

    // Empty state
    if (widget.messages.isEmpty) {
      return _EmptyMessageList();
    }

    // Messages loaded - show with loading indicators for pagination
    return Stack(
      children: [
        ListView.builder(
          controller: widget.scroll,
          reverse: true,
          padding: EdgeInsets.only(
            top: _isLoadingMessagesBefore ? 60 : 12,
            bottom: _isLoadingMessagesAfter ? 60 : 12,
          ),
          itemCount: widget.messages.length,
          itemBuilder: (_, i) {
            final msg = widget.messages[i];
            final grouped = _isSameAuthorAsPrevious(i);
            final isLast = i == 0;
            final isNewlyLoaded = _newlyLoadedIds.containsKey(msg.id);

            return VisibilityDetector(
              key: Key(msg.id.toString()),
              onVisibilityChanged: (info) {
                if (info.visibleFraction > 0) {
                  if (i == 0) {
                    // Last message - load newer
                    getMessagesAfter(msg);
                  }
                  if (i == widget.messages.length - 1) {
                    // First message - load older
                    getMessagesBefore(msg);
                  }
                }
              },
              child:
                  isNewlyLoaded
                      ? FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.1),
                            end: Offset.zero,
                          ).animate(_fadeAnimation),
                          child: _MessageRow(
                            message: msg,
                            grouped: grouped,
                            isLast: isLast,
                            fmtTime: _fmtTime(msg.date),
                          ),
                        ),
                      )
                      : _MessageRow(
                        message: msg,
                        grouped: grouped,
                        isLast: isLast,
                        fmtTime: _fmtTime(msg.date),
                      ),
            );
          },
        ),

        // Loading indicator at bottom (newer messages)
        if (_isLoadingMessagesAfter)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _LoadingIndicator(
              label: 'Loading newer messages',
              position: _LoadingPosition.bottom,
            ),
          ),

        // Loading indicator at top (older messages)
        if (_isLoadingMessagesBefore)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _LoadingIndicator(
              label: 'Loading older messages',
              position: _LoadingPosition.top,
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LOADING POSITION ENUM
// ─────────────────────────────────────────────────────────────────────────────

enum _LoadingPosition { top, bottom }

// ─────────────────────────────────────────────────────────────────────────────
// LOADING INDICATOR
// Inline spinner shown while loading more messages
// ─────────────────────────────────────────────────────────────────────────────

class _LoadingIndicator extends StatefulWidget {
  final String label;
  final _LoadingPosition position;

  const _LoadingIndicator({required this.label, required this.position});

  @override
  State<_LoadingIndicator> createState() => _LoadingIndicatorState();
}

class _LoadingIndicatorState extends State<_LoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: _controller, curve: Curves.easeOut),
      child: SlideTransition(
        position: Tween<Offset>(
          begin:
              widget.position == _LoadingPosition.top
                  ? const Offset(0, -0.3)
                  : const Offset(0, 0.3),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
        ),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin:
                  widget.position == _LoadingPosition.top
                      ? Alignment.topCenter
                      : Alignment.bottomCenter,
              end:
                  widget.position == _LoadingPosition.top
                      ? Alignment.bottomCenter
                      : Alignment.topCenter,
              colors: [_T.white, _T.white.withOpacity(0.0)],
            ),
          ),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: _T.slate50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _T.slate200),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(_T.blue),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.label,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: _T.slate500,
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
// SKELETON MESSAGE LIST
// Initial loading state with shimmer effect
// ─────────────────────────────────────────────────────────────────────────────

class _SkeletonMessageList extends StatefulWidget {
  @override
  State<_SkeletonMessageList> createState() => _SkeletonMessageListState();
}

class _SkeletonMessageListState extends State<_SkeletonMessageList>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: 8, // Show 8 skeleton messages
      itemBuilder: (_, i) {
        // Vary skeleton sizes for realism
        final isGrouped = i % 3 != 0; // Group some messages
        final hasLongText = i % 2 == 0;

        return _SkeletonMessageRow(
          shimmerAnimation: _shimmerController,
          grouped: isGrouped,
          hasLongText: hasLongText,
          delay: i * 50, // Stagger animation
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SKELETON MESSAGE ROW
// Individual skeleton message with shimmer
// ─────────────────────────────────────────────────────────────────────────────

class _SkeletonMessageRow extends StatefulWidget {
  final AnimationController shimmerAnimation;
  final bool grouped;
  final bool hasLongText;
  final int delay;

  const _SkeletonMessageRow({
    required this.shimmerAnimation,
    required this.grouped,
    required this.hasLongText,
    required this.delay,
  });

  @override
  State<_SkeletonMessageRow> createState() => _SkeletonMessageRowState();
}

class _SkeletonMessageRowState extends State<_SkeletonMessageRow> {
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Staggered fade-in
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        setState(() {
          _fadeAnimation = CurvedAnimation(
            parent: widget.shimmerAnimation,
            curve: const Interval(0, 0.3, curve: Curves.easeOut),
          );
        });
      }
    });

    _fadeAnimation = const AlwaysStoppedAnimation(0);
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, widget.grouped ? 2 : 10, 16, 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar or spacer
            SizedBox(
              width: 30,
              child:
                  widget.grouped
                      ? const SizedBox()
                      : _ShimmerBox(
                        animation: widget.shimmerAnimation,
                        width: 30,
                        height: 30,
                        borderRadius: 15,
                      ),
            ),
            const SizedBox(width: 10),

            // Message content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!widget.grouped)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          _ShimmerBox(
                            animation: widget.shimmerAnimation,
                            width: 80,
                            height: 12,
                            borderRadius: 4,
                          ),
                          const SizedBox(width: 8),
                          _ShimmerBox(
                            animation: widget.shimmerAnimation,
                            width: 40,
                            height: 10,
                            borderRadius: 3,
                          ),
                        ],
                      ),
                    ),
                  _ShimmerBox(
                    animation: widget.shimmerAnimation,
                    width: double.infinity,
                    height: 13,
                    borderRadius: 4,
                  ),
                  if (widget.hasLongText) ...[
                    const SizedBox(height: 4),
                    _ShimmerBox(
                      animation: widget.shimmerAnimation,
                      width: double.infinity,
                      height: 13,
                      borderRadius: 4,
                    ),
                    const SizedBox(height: 4),
                    _ShimmerBox(
                      animation: widget.shimmerAnimation,
                      width: 200,
                      height: 13,
                      borderRadius: 4,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHIMMER BOX
// Reusable shimmer effect component
// ─────────────────────────────────────────────────────────────────────────────

class _ShimmerBox extends StatelessWidget {
  final AnimationController animation;
  final double width;
  final double height;
  final double borderRadius;

  const _ShimmerBox({
    required this.animation,
    required this.width,
    required this.height,
    required this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              stops:
                  [
                    animation.value - 0.3,
                    animation.value,
                    animation.value + 0.3,
                  ].map((v) => v.clamp(0.0, 1.0)).toList(),
              colors: const [_T.slate100, _T.slate200, _T.slate100],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// IMPROVED EMPTY STATE
// Enhanced with better visual hierarchy
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyMessageList extends StatefulWidget {
  @override
  State<_EmptyMessageList> createState() => _EmptyMessageListState();
}

class _EmptyMessageListState extends State<_EmptyMessageList>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _T.blue50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _T.blue.withOpacity(0.1),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 26,
                  color: _T.blue,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'No messages yet',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _T.ink2,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Start the conversation below',
                style: TextStyle(fontSize: 12, color: _T.slate400),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MESSAGE ROW
// ─────────────────────────────────────────────────────────────────────────────
class _MessageRow extends StatefulWidget {
  final Message message;
  final bool grouped;
  final bool isLast;
  final String fmtTime;

  const _MessageRow({
    required this.message,
    required this.grouped,
    required this.isLast,
    required this.fmtTime,
  });

  @override
  State<_MessageRow> createState() => _MessageRowState();
}

class _MessageRowState extends State<_MessageRow> {
  bool _hovered = false;

  final GlobalKey _widgetKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    if (widget.isLast)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final RenderBox renderBox =
            _widgetKey.currentContext?.findRenderObject() as RenderBox;
        final height = renderBox.size.height;
        print("Widget Height for last msg: $height");
      });
  }

  @override
  Widget build(BuildContext context) {
    final msg = widget.message;

    return InkWell(
      key: _widgetKey,
      onTap: () {
        print(
          "tapped message user, ${{"user": msg.authorName, "userId": msg.userId}}",
        );
      },
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Container(
          color: _hovered ? _T.slate50 : Colors.transparent,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 80),
            padding: EdgeInsets.fromLTRB(
              16,
              widget.grouped ? 2 : 10,
              16,
              widget.isLast ? 4 : 0,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar column — either avatar or spacer for grouped messages
                SizedBox(
                  width: 30,
                  child:
                      widget.grouped
                          ? Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: AnimatedOpacity(
                              opacity: _hovered ? 1.0 : 0.0,
                              duration: const Duration(milliseconds: 100),
                              child: Text(
                                widget.fmtTime,
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: _T.slate300,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )
                          : AvatarWidget(
                            initials: msg.authorInitials,
                            color: msg.authorColor ?? _T.ink3,
                            size: 30,
                          ),
                ),
                const SizedBox(width: 10),

                // Message content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!widget.grouped)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                msg.userId == LoginService.currentUser!.id
                                    ? 'You'
                                    : msg.authorName,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: _T.ink2,
                                ),
                              ),
                              const SizedBox(width: 7),
                              Text(
                                widget.fmtTime,
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  color: _T.slate400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      Text(
                        msg.message,
                        style: const TextStyle(
                          fontSize: 13,
                          color: _T.ink3,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COMPOSE BAR
//
// Desktop-appropriate: single-line text field that expands to multiline
// (max 4 lines) as the user types. Send on Enter (not Shift+Enter).
// Shift+Enter inserts a newline.
// ─────────────────────────────────────────────────────────────────────────────
class _ComposeBar extends StatefulWidget {
  final TextEditingController compose;
  final bool sending;
  final VoidCallback onSend;

  const _ComposeBar({
    required this.compose,
    required this.sending,
    required this.onSend,
  });

  @override
  State<_ComposeBar> createState() => _ComposeBarState();
}

class _ComposeBarState extends State<_ComposeBar> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.compose.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final hasText = widget.compose.text.trim().isNotEmpty;
    if (hasText != _hasText) setState(() => _hasText = hasText);
  }

  @override
  void dispose() {
    widget.compose.removeListener(_onTextChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _T.slate50,
        border: Border(top: BorderSide(color: _T.slate200)),
      ),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Text field
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: _T.white,
                borderRadius: BorderRadius.circular(_T.r),
                border: Border.all(color: _T.slate200),
              ),
              child: KeyboardListener(
                focusNode: FocusNode(skipTraversal: true),
                onKeyEvent: (event) {
                  // Enter without shift = send
                  // Shift+Enter = newline (default behavior)
                },
                child: TextField(
                  controller: widget.compose,
                  maxLines: 4,
                  minLines: 1,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  style: const TextStyle(
                    fontSize: 13,
                    color: _T.ink2,
                    height: 1.45,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Write a message…',
                    hintStyle: TextStyle(fontSize: 13, color: _T.slate300),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Send button
          _SendButton(
            enabled: _hasText && !widget.sending,
            sending: widget.sending,
            onTap: widget.onSend,
          ),
        ],
      ),
    );
  }
}

class _SendButton extends StatefulWidget {
  final bool enabled;
  final bool sending;
  final VoidCallback onTap;

  const _SendButton({
    required this.enabled,
    required this.sending,
    required this.onTap,
  });

  @override
  State<_SendButton> createState() => _SendButtonState();
}

class _SendButtonState extends State<_SendButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final Color bg =
        widget.enabled ? (_hovered ? _T.blueHover : _T.blue) : _T.slate100;

    return MouseRegion(
      cursor:
          widget.enabled
              ? SystemMouseCursors.click
              : SystemMouseCursors.forbidden,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.enabled ? widget.onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(_T.r),
          ),
          child:
              widget.sending
                  ? const Center(
                    child: SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                  )
                  : Icon(
                    Icons.send_rounded,
                    size: 15,
                    color: widget.enabled ? Colors.white : _T.slate300,
                  ),
        ),
      ),
    );
  }
}

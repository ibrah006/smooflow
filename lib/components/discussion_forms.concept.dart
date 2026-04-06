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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/providers/message_provider.dart';
import 'package:smooflow/providers/task_provider.dart';
import 'package:smooflow/screens/desktop/components/avatar_widget.dart';

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
// MESSAGE MODEL  — replace with your real model once the provider is wired
// ─────────────────────────────────────────────────────────────────────────────
class DiscussionMessage {
  final String id;
  final String authorName;
  final String authorInitials;
  final Color authorColor;
  final String body;
  final DateTime sentAt;
  final bool isOwn;

  const DiscussionMessage({
    required this.id,
    required this.authorName,
    required this.authorInitials,
    required this.authorColor,
    required this.body,
    required this.sentAt,
    required this.isOwn,
  });
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
  /// The most recent message, or null if no messages yet.
  final DiscussionMessage? lastMessage;

  final int taskId;

  /// Number of unread messages. 0 hides the badge.
  final int unreadCount;

  /// Called when the user taps "Open Discussion".
  final VoidCallback onOpen;

  const DiscussionPreviewStrip({
    super.key,
    required this.lastMessage,
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

  @override
  initState() {
    super.initState();

    Future.microtask(() {
      final task = ref.read(taskByIdProviderSimple(widget.taskId));
      final messages = ref.read(messagesByTaskProvider(widget.taskId));

      if (messages.last.id != task!.lastMessageId) {
        // Need to fetch the recent messages to update the preview
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
              if (widget.unreadCount > 0) ...[
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
                    widget.lastMessage == null
                        ? _EmptyDiscussionPreview(hovered: _hovered)
                        : _LastMessagePreview(
                          lastMessage: widget.lastMessage!,
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
  final DiscussionMessage lastMessage;
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
            color: lastMessage.authorColor,
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
                      lastMessage.authorName,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _T.ink2,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _relativeTime(lastMessage.sentAt),
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: _T.slate400,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  lastMessage.body,
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
class DiscussionSheet extends StatefulWidget {
  final int taskId;
  final bool isOpen;
  final List<DiscussionMessage> messages;
  final VoidCallback onClose;
  final ValueChanged<String> onSend;

  const DiscussionSheet({
    super.key,
    required this.taskId,
    required this.isOpen,
    required this.messages,
    required this.onClose,
    required this.onSend,
  });

  @override
  State<DiscussionSheet> createState() => _DiscussionSheetState();
}

class _DiscussionSheetState extends State<DiscussionSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  final TextEditingController _compose = TextEditingController();
  final ScrollController _scroll = ScrollController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);

    if (widget.isOpen) _ctrl.value = 1.0;
  }

  @override
  void didUpdateWidget(DiscussionSheet old) {
    super.didUpdateWidget(old);
    if (widget.isOpen != old.isOpen) {
      if (widget.isOpen) {
        _ctrl.duration = const Duration(milliseconds: 300);
        _ctrl.forward().then((_) => _scrollToBottom());
      } else {
        _ctrl.duration = const Duration(milliseconds: 220);
        _ctrl.reverse();
      }
    }
    // Scroll to bottom when new messages arrive while open
    if (widget.messages.length != old.messages.length && widget.isOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _compose.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scroll.hasClients) {
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _send() async {
    final text = _compose.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    _compose.clear();
    widget.onSend(text);
    await Future.delayed(const Duration(milliseconds: 100));
    if (mounted) setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    // Don't render anything when fully closed and animation is complete
    if (!widget.isOpen && !_ctrl.isAnimating && _ctrl.value == 0.0) {
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: _SheetSurface(
              taskId: widget.taskId,
              messages: widget.messages,
              scroll: _scroll,
              compose: _compose,
              sending: _sending,
              onClose: widget.onClose,
              onSend: _send,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHEET SURFACE — the visual sheet body
// ─────────────────────────────────────────────────────────────────────────────
class _SheetSurface extends StatelessWidget {
  final int taskId;
  final List<DiscussionMessage> messages;
  final ScrollController scroll;
  final TextEditingController compose;
  final bool sending;
  final VoidCallback onClose;
  final VoidCallback onSend;

  const _SheetSurface({
    required this.taskId,
    required this.messages,
    required this.scroll,
    required this.compose,
    required this.sending,
    required this.onClose,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.74,
      child: Container(
        decoration: BoxDecoration(
          color: _T.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
          border: Border.all(color: _T.slate200),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withOpacity(0.10),
              blurRadius: 24,
              offset: const Offset(0, -6),
            ),
            BoxShadow(
              color: const Color(0xFF0F172A).withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, -1),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
          child: Column(
            children: [
              _SheetHeader(taskId: taskId, onClose: onClose),
              Expanded(child: _MessageList(messages: messages, scroll: scroll)),
              _ComposeBar(compose: compose, sending: sending, onSend: onSend),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHEET HEADER
//
// Desktop-appropriate: no drag handle. A top hairline accent strip (2px blue)
// anchors the eye. Title on left, close button on right.
// ─────────────────────────────────────────────────────────────────────────────
class _SheetHeader extends StatelessWidget {
  final int taskId;
  final VoidCallback onClose;

  const _SheetHeader({required this.taskId, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Blue top accent strip
        Container(height: 2.5, color: _T.blue),

        // Header row
        Container(
          height: _T.topbarH,
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: _T.slate100)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon + label
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: _T.blue50,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 13,
                  color: _T.blue,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Discussion',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _T.ink,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: _T.slate100,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  'TASK-$taskId',
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                    color: _T.slate500,
                  ),
                ),
              ),

              const Spacer(),

              // Close button — chevron down (collapsed metaphor)
              _CloseButton(onClose: onClose),
            ],
          ),
        ),
      ],
    );
  }
}

class _CloseButton extends StatefulWidget {
  final VoidCallback onClose;
  const _CloseButton({required this.onClose});

  @override
  State<_CloseButton> createState() => _CloseButtonState();
}

class _CloseButtonState extends State<_CloseButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onClose,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: _hovered ? _T.slate100 : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(
              color: _hovered ? _T.slate200 : Colors.transparent,
            ),
          ),
          child: Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 16,
            color: _hovered ? _T.ink3 : _T.slate400,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MESSAGE LIST
//
// Newest message at bottom (chat convention).
// Groups messages by author when consecutive — only shows avatar + name on
// the first message of a run, subsequent ones from the same author are
// indented (like Slack/Linear's threading).
// Empty state shown when no messages exist yet.
// ─────────────────────────────────────────────────────────────────────────────
class _MessageList extends StatelessWidget {
  final List<DiscussionMessage> messages;
  final ScrollController scroll;

  const _MessageList({required this.messages, required this.scroll});

  bool _isSameAuthorAsPrevious(int i) {
    if (i == 0) return false;
    return messages[i].authorName == messages[i - 1].authorName;
  }

  String _fmtTime(DateTime t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return _EmptyMessageList();
    }

    return ListView.builder(
      controller: scroll,
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: messages.length,
      itemBuilder: (_, i) {
        final msg = messages[i];
        final grouped = _isSameAuthorAsPrevious(i);
        final isLast = i == messages.length - 1;

        return _MessageRow(
          message: msg,
          grouped: grouped,
          isLast: isLast,
          fmtTime: _fmtTime(msg.sentAt),
        );
      },
    );
  }
}

class _EmptyMessageList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _T.slate100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.chat_bubble_outline_rounded,
              size: 20,
              color: _T.slate300,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'No messages yet',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _T.slate400,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Start the conversation below',
            style: TextStyle(fontSize: 11.5, color: _T.slate300),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MESSAGE ROW
// ─────────────────────────────────────────────────────────────────────────────
class _MessageRow extends StatefulWidget {
  final DiscussionMessage message;
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

  @override
  Widget build(BuildContext context) {
    final msg = widget.message;

    return MouseRegion(
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
                          color: msg.authorColor,
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
                              msg.isOwn ? 'You' : msg.authorName,
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
                      msg.body,
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

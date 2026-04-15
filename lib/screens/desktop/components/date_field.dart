// ─────────────────────────────────────────────────────────────────────────────
// DATE FIELD  — type a date OR pick from a positioned calendar popup.
//
// Signature change from original:
//   • Added `onChange` (ValueChanged<DateTime?>) — called on both pick & type.
//     The original `onPick` handler is replaced by this single callback.
//   • `onClear` kept as-is.
//
// Border/color tokens are identical to the original _SmooField style used
// throughout the app. The only visual additions are the right-side icon
// buttons and the calendar popup.
//
// Suggestion: when the field is actively focused (typing mode), consider
// using a solid `_T.blue` border (no opacity) instead of withOpacity(0.55)
// so it visually matches how _SmooField behaves on focus — clearer active
// state without changing the "filled" or "idle" appearances at all.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TOKENS — unchanged
// ─────────────────────────────────────────────────────────────────────────────
class _T {
  static const blue = Color(0xFF2563EB);
  static const blueHover = Color(0xFF1D4ED8);
  static const blue100 = Color(0xFFDBEAFE);
  static const blue50 = Color(0xFFEFF6FF);
  static const green = Color(0xFF10B981);
  static const green50 = Color(0xFFECFDF5);
  static const amber = Color(0xFFF59E0B);
  static const amber50 = Color(0xFFFEF3C7);
  static const red = Color(0xFFEF4444);
  static const red50 = Color(0xFFFEE2E2);
  static const purple = Color(0xFF8B5CF6);
  static const purple50 = Color(0xFFF3E8FF);
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
}

class DateField extends StatefulWidget {
  final DateTime? value;

  /// Called whenever the date changes — from a calendar pick OR a typed entry.
  /// Receives null when the field is cleared.
  final ValueChanged<DateTime?> onChange;

  final VoidCallback onClear;

  final bool allowKbInput;

  const DateField({
    required this.value,
    required this.onChange,
    required this.onClear,
    this.allowKbInput = true,
  });

  /// Shared formatter — "Jan 15, 2025"
  static String format(DateTime d) {
    const months = [
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
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  @override
  State<DateField> createState() => _DateFieldState();
}

class _DateFieldState extends State<DateField> {
  bool _hovered = false;
  bool _typingMode = false;
  bool _calendarOpen = false;

  final _textCtrl = TextEditingController();
  final _focusNode = FocusNode();
  final _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  // Calendar popup is ~300 px tall; use to decide above/below.
  static const double _kCalendarH = 316.0;
  static const double _kGap = 6.0;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _syncText();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(DateField old) {
    super.didUpdateWidget(old);
    if (widget.value != old.value) _syncText();
  }

  @override
  void dispose() {
    _removeOverlay();
    _textCtrl.dispose();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _syncText() {
    _textCtrl.text =
        widget.value != null ? DateField.format(widget.value!) : '';
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus && _typingMode) _commitTyped();
  }

  // ── Typed input ───────────────────────────────────────────────────────────

  void _commitTyped() {
    if (!mounted) return;
    final raw = _textCtrl.text.trim();
    if (raw.isEmpty) {
      widget.onChange(null);
    } else {
      final parsed = _tryParse(raw);
      if (parsed != null) {
        widget.onChange(parsed);
      } else {
        // Bad input — restore previous value silently.
        _syncText();
      }
    }
    setState(() => _typingMode = false);
  }

  /// Accepts two formats:
  ///   • "Jan 15, 2025"  (canonical — matches the field's own output)
  ///   • "01/15/2025"    (MM/DD/YYYY — common secondary format)
  DateTime? _tryParse(String s) {
    const months = {
      'jan': 1,
      'feb': 2,
      'mar': 3,
      'apr': 4,
      'may': 5,
      'jun': 6,
      'jul': 7,
      'aug': 8,
      'sep': 9,
      'oct': 10,
      'nov': 11,
      'dec': 12,
    };

    // "Jan 15, 2025" or "Jan 15 2025"
    final re = RegExp(r'^([a-zA-Z]{3})\s+(\d{1,2}),?\s+(\d{4})$');
    final m = re.firstMatch(s);
    if (m != null) {
      final mo = months[m.group(1)!.toLowerCase()];
      final d = int.tryParse(m.group(2)!);
      final y = int.tryParse(m.group(3)!);
      if (mo != null && d != null && y != null) {
        try {
          return DateTime(y, mo, d);
        } catch (_) {}
      }
    }

    // "01/15/2025"
    final slash = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})$');
    final sm = slash.firstMatch(s);
    if (sm != null) {
      final mo = int.tryParse(sm.group(1)!);
      final d = int.tryParse(sm.group(2)!);
      final y = int.tryParse(sm.group(3)!);
      if (mo != null && d != null && y != null) {
        try {
          return DateTime(y, mo, d);
        } catch (_) {}
      }
    }

    return null;
  }

  // ── Calendar overlay ──────────────────────────────────────────────────────

  void _toggleCalendar() {
    if (_calendarOpen) {
      _closeCalendar();
      return;
    }

    // Measure available space below the field to decide positioning.
    final box = context.findRenderObject() as RenderBox?;
    bool showAbove = false;
    if (box != null) {
      final pos = box.localToGlobal(Offset.zero);
      final screenH = MediaQuery.of(context).size.height;
      final spaceBelow = screenH - pos.dy - box.size.height;
      showAbove = spaceBelow < _kCalendarH + _kGap + 16;
    }

    // Exit typing mode when switching to calendar.
    if (_typingMode) setState(() => _typingMode = false);
    setState(() => _calendarOpen = true);

    _overlayEntry = OverlayEntry(
      builder:
          (_) => _CalendarPopup(
            layerLink: _layerLink,
            showAbove: showAbove,
            selectedDate: widget.value,
            onPick: (d) {
              widget.onChange(d);
              _closeCalendar();
            },
            onDismiss: _closeCalendar,
          ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _closeCalendar() {
    _removeOverlay();
    if (mounted) setState(() => _calendarOpen = false);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  // ── Typing mode entry ─────────────────────────────────────────────────────

  void _enterTypingMode() {
    _closeCalendar();

    if (widget.allowKbInput) {
      setState(() => _typingMode = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focusNode.requestFocus();
      });
    } else {
      _toggleCalendar();
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final filled = widget.value != null;
    final active = _typingMode || _calendarOpen;

    return CompositedTransformTarget(
      link: _layerLink,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          // ── Border — identical token values to original ─────────────────
          decoration: BoxDecoration(
            color: filled || _hovered || active ? _T.white : _T.slate50,
            borderRadius: BorderRadius.circular(_T.r),
            border: Border.all(
              color:
                  active
                      ? _T.blue.withOpacity(0.55)
                      : filled
                      ? _T.blue.withOpacity(0.45)
                      : _T.slate200,
              width: filled || active ? 1.5 : 1,
            ),
          ),
          child: _typingMode ? _buildTyping() : _buildDisplay(filled),
        ),
      ),
    );
  }

  // ── Display mode ──────────────────────────────────────────────────────────
  Widget _buildDisplay(bool filled) {
    return Row(
      children: [
        // Tappable text area → enters typing mode.
        Expanded(
          child: MouseRegion(
            cursor:
                widget.allowKbInput
                    ? SystemMouseCursors.text
                    : SystemMouseCursors.click,
            child: GestureDetector(
              onTap: _enterTypingMode,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.event_outlined,
                      size: 15,
                      color: filled ? _T.blue : _T.slate400,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        filled
                            ? DateField.format(widget.value!)
                            : '${!widget.allowKbInput ? 'Tap to ' : 'Type or '}pick a date…',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              filled ? FontWeight.w500 : FontWeight.w400,
                          color: filled ? _T.ink : _T.slate300,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Right-side actions.
        if (filled) ...[
          _FieldDivider(),
          _FieldIconBtn(
            icon: Icons.close_rounded,
            size: 14,
            color: _T.slate400,
            onTap: () {
              widget.onClear();
              _closeCalendar();
            },
          ),
        ] else ...[
          _FieldDivider(),
          _FieldIconBtn(
            icon:
                _calendarOpen
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.calendar_month_outlined,
            size: _calendarOpen ? 16 : 15,
            color: _calendarOpen ? _T.blue : _T.slate400,
            onTap: _toggleCalendar,
          ),
        ],
      ],
    );
  }

  // ── Typing mode ───────────────────────────────────────────────────────────
  Widget _buildTyping() {
    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Icon(Icons.edit_calendar_outlined, size: 14, color: _T.blue),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: _textCtrl,
            focusNode: _focusNode,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: _T.ink,
            ),
            decoration: const InputDecoration(
              // Format hint lives right in the placeholder — always visible
              // before the user starts typing.
              hintText: 'e.g. Jan 15, 2025',
              hintStyle: TextStyle(
                fontSize: 13,
                color: _T.slate300,
                fontWeight: FontWeight.w400,
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 12),
            ),
            onSubmitted: (_) => _commitTyped(),
          ),
        ),
        // Format badge — subtle reminder, never intrusive.
        Padding(
          padding: const EdgeInsets.only(right: 6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _T.slate100,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'Mon DD, YYYY',
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                color: _T.slate400,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
        _FieldDivider(),
        // Switch to calendar while still in typing mode.
        _FieldIconBtn(
          icon: Icons.calendar_month_outlined,
          size: 15,
          color: _T.slate400,
          onTap: _toggleCalendar,
        ),
        // Confirm typed value.
        _FieldIconBtn(
          icon: Icons.check_rounded,
          size: 15,
          color: _T.green,
          onTap: _commitTyped,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FIELD HELPERS — thin divider + icon button inside the field row
// ─────────────────────────────────────────────────────────────────────────────

class _FieldDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 20, color: _T.slate100);
}

class _FieldIconBtn extends StatefulWidget {
  final IconData icon;
  final double size;
  final Color color;
  final VoidCallback onTap;
  const _FieldIconBtn({
    required this.icon,
    required this.size,
    required this.color,
    required this.onTap,
  });
  @override
  State<_FieldIconBtn> createState() => _FieldIconBtnState();
}

class _FieldIconBtnState extends State<_FieldIconBtn> {
  bool _hov = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: SystemMouseCursors.click,
    onEnter: (_) => setState(() => _hov = true),
    onExit: (_) => setState(() => _hov = false),
    child: GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: 36,
        height: 42,
        decoration: BoxDecoration(
          color: _hov ? _T.slate50 : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          widget.icon,
          size: widget.size,
          color: _hov ? _T.ink3 : widget.color,
        ),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// CALENDAR POPUP  — positioned overlay anchored to the field via LayerLink.
//
// showAbove=false → follower top-left aligns to field bottom-left (default).
// showAbove=true  → follower bottom-left aligns to field top-left.
// A 6 px gap is applied via the offset in both cases.
// ─────────────────────────────────────────────────────────────────────────────

class _CalendarPopup extends StatefulWidget {
  final LayerLink layerLink;
  final bool showAbove;
  final DateTime? selectedDate;
  final ValueChanged<DateTime> onPick;
  final VoidCallback onDismiss;

  const _CalendarPopup({
    required this.layerLink,
    required this.showAbove,
    required this.selectedDate,
    required this.onPick,
    required this.onDismiss,
  });

  @override
  State<_CalendarPopup> createState() => _CalendarPopupState();
}

class _CalendarPopupState extends State<_CalendarPopup> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    final ref = widget.selectedDate ?? DateTime.now();
    _month = DateTime(ref.year, ref.month);
  }

  void _prev() =>
      setState(() => _month = DateTime(_month.year, _month.month - 1));

  void _next() =>
      setState(() => _month = DateTime(_month.year, _month.month + 1));

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    // Monday-first week: Monday=1 → pad=0, Sunday=7 → pad=6
    final startPad = (DateTime(_month.year, _month.month, 1).weekday - 1) % 7;

    return Stack(
      children: [
        // ── Full-screen dismiss barrier ──────────────────────────────────────
        Positioned.fill(
          child: GestureDetector(
            onTap: widget.onDismiss,
            behavior: HitTestBehavior.translucent,
          ),
        ),

        // ── Anchored popup ───────────────────────────────────────────────────
        CompositedTransformFollower(
          link: widget.layerLink,
          showWhenUnlinked: false,
          targetAnchor:
              widget.showAbove ? Alignment.topRight : Alignment.bottomRight,
          followerAnchor:
              widget.showAbove ? Alignment.bottomRight : Alignment.topRight,
          offset: Offset(0, widget.showAbove ? -6 : 6),
          child: Material(
            elevation: 0,
            color: Colors.transparent,
            child: Container(
              width: 272,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _T.white,
                borderRadius: BorderRadius.circular(_T.rLg),
                border: Border.all(color: _T.slate200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.09),
                    blurRadius: 20,
                    spreadRadius: 0,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Month / year header ────────────────────────────────────
                  Row(
                    children: [
                      _CalNavBtn(
                        icon: Icons.chevron_left_rounded,
                        onTap: _prev,
                      ),
                      Expanded(
                        child: Text(
                          _monthLabel(_month),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _T.ink,
                          ),
                        ),
                      ),
                      _CalNavBtn(
                        icon: Icons.chevron_right_rounded,
                        onTap: _next,
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // ── Day-of-week headers — Mon-first ─────────────────────────
                  Row(
                    children:
                        ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su']
                            .map(
                              (lbl) => Expanded(
                                child: Center(
                                  child: Text(
                                    lbl,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: _T.slate400,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                  ),

                  const SizedBox(height: 4),

                  // ── Day grid ─────────────────────────────────────────────────
                  _buildGrid(today, daysInMonth, startPad),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGrid(DateTime today, int daysInMonth, int startPad) {
    final cells = <Widget>[
      // Leading empty cells
      for (int i = 0; i < startPad; i++) const SizedBox(),

      // Day cells
      for (int day = 1; day <= daysInMonth; day++)
        _DayCell(
          day: day,
          isToday:
              today.year == _month.year &&
              today.month == _month.month &&
              today.day == day,
          isSelected:
              widget.selectedDate != null &&
              widget.selectedDate!.year == _month.year &&
              widget.selectedDate!.month == _month.month &&
              widget.selectedDate!.day == day,
          onTap: () => widget.onPick(DateTime(_month.year, _month.month, day)),
        ),
    ];

    // Pad last row to a full 7
    while (cells.length % 7 != 0) cells.add(const SizedBox());

    return Column(
      children: [
        for (int r = 0; r < cells.length; r += 7) ...[
          Row(
            children:
                cells.sublist(r, r + 7).map((c) => Expanded(child: c)).toList(),
          ),
          if (r + 7 < cells.length) const SizedBox(height: 2),
        ],
      ],
    );
  }

  static String _monthLabel(DateTime d) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[d.month - 1]} ${d.year}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CALENDAR NAVIGATION BUTTON
// ─────────────────────────────────────────────────────────────────────────────
class _CalNavBtn extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CalNavBtn({required this.icon, required this.onTap});
  @override
  State<_CalNavBtn> createState() => _CalNavBtnState();
}

class _CalNavBtnState extends State<_CalNavBtn> {
  bool _hov = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: SystemMouseCursors.click,
    onEnter: (_) => setState(() => _hov = true),
    onExit: (_) => setState(() => _hov = false),
    child: GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: _hov ? _T.slate100 : Colors.white,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(widget.icon, size: 16, color: _hov ? _T.ink3 : _T.slate400),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// DAY CELL
// ─────────────────────────────────────────────────────────────────────────────
class _DayCell extends StatefulWidget {
  final int day;
  final bool isToday, isSelected;
  final VoidCallback onTap;
  const _DayCell({
    required this.day,
    required this.isToday,
    required this.isSelected,
    required this.onTap,
  });
  @override
  State<_DayCell> createState() => _DayCellState();
}

class _DayCellState extends State<_DayCell> {
  bool _hov = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: SystemMouseCursors.click,
    onEnter: (_) => setState(() => _hov = true),
    onExit: (_) => setState(() => _hov = false),
    child: GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        height: 30,
        margin: const EdgeInsets.all(1.5),
        decoration: BoxDecoration(
          color:
              widget.isSelected
                  ? _T.blue
                  : _hov
                  ? _T.slate100
                  : widget.isToday
                  ? _T.blue50
                  : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border:
              widget.isToday && !widget.isSelected
                  ? Border.all(color: _T.blue.withOpacity(0.3))
                  : null,
        ),
        child: Center(
          child: Text(
            '${widget.day}',
            style: TextStyle(
              fontSize: 12,
              fontWeight:
                  widget.isSelected || widget.isToday
                      ? FontWeight.w700
                      : FontWeight.w500,
              color:
                  widget.isSelected
                      ? Colors.white
                      : widget.isToday
                      ? _T.blue
                      : _T.ink3,
            ),
          ),
        ),
      ),
    ),
  );
}

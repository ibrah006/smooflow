import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─────────────────────────────────────────────────────────────────────────────
// GhostTextField — four modes
//
//   singleLine   — fixed one line, scrolls horizontally.
//                  Enter = submit. Task titles, short labels.
//
//   label        — wraps visually when content is too wide but NO manual line
//                  breaks (Enter = submit, newlines stripped from paste).
//                  Long client names, project headings inside constrained widgets.
//
//   multiline    — wraps AND allows manual newlines.
//                  Enter = new line. Descriptions, notes.
//
//   inline       — width shrink-wraps to text content. Never wraps to a new line.
//                  Enter = submit. Grows and shrinks as the user types.
//                  Constrained by [inlineMinWidth] and [inlineMaxWidth].
//                  Good for editable tags, column headers, chip labels.
// ─────────────────────────────────────────────────────────────────────────────

enum GhostFieldMode { singleLine, label, multiline, inline }

// Strips \n and \r from any typed or pasted input.
class _NoNewlineFormatter extends TextInputFormatter {
  const _NoNewlineFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final cleaned = newValue.text.replaceAll(RegExp(r'[\n\r]'), '');
    if (cleaned == newValue.text) return newValue;
    return newValue.copyWith(
      text: cleaned,
      selection: TextSelection.collapsed(offset: cleaned.length),
    );
  }
}

class GhostTextField extends StatefulWidget {
  final String initialText;
  final TextStyle style;
  final String? hint;
  final GhostFieldMode mode;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onEditingComplete;
  final Function(String newValue) onSubmitted;
  final bool isDecimalOnlyField;

  /// [inline] mode only — minimum field width when empty or very short.
  /// Defaults to 50.0.
  final double inlineMinWidth;

  /// [inline] mode only — maximum field width before the text is clipped
  /// and scrolls horizontally. Defaults to 500.0.
  final double inlineMaxWidth;

  const GhostTextField({
    super.key,
    required this.initialText,
    required this.style,
    required this.onSubmitted,
    this.hint,
    this.mode = GhostFieldMode.singleLine,
    this.keyboardType,
    this.onChanged,
    this.onEditingComplete,
    this.inlineMinWidth = 20.0,
    this.inlineMaxWidth = 80.0,
    this.isDecimalOnlyField = false,
  });

  @override
  State<GhostTextField> createState() => _GhostTextFieldState();
}

class _GhostTextFieldState extends State<GhostTextField> {
  late final TextEditingController _controller;
  final _focus = FocusNode();
  bool _hovered = false;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
    _focus.addListener(() => setState(() => _focused = _focus.hasFocus));
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  // ── Visual state ────────────────────────────────────────────────────────────

  Color get _fill {
    if (_focused) return _T.white;
    if (_hovered) return _T.slate100;
    return Colors.white;
  }

  Border get _border {
    if (_focused) return Border.all(color: _T.slate300);
    if (_hovered) return Border.all(color: _T.slate200);
    return Border.all(color: Colors.white);
  }

  List<BoxShadow> get _shadow =>
      _focused
          ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ]
          : const [];

  // ── Mode-derived TextField properties ──────────────────────────────────────

  int? get _maxLines => switch (widget.mode) {
    GhostFieldMode.singleLine => 1,
    GhostFieldMode.inline => 1, // never wraps — width scrolls instead
    GhostFieldMode.label => null,
    GhostFieldMode.multiline => null,
  };

  TextInputType get _keyboardType {
    if (widget.keyboardType != null) return widget.keyboardType!;
    return widget.mode == GhostFieldMode.multiline
        ? TextInputType.multiline
        : TextInputType.text;
  }

  TextInputAction get _inputAction => switch (widget.mode) {
    GhostFieldMode.multiline => TextInputAction.newline,
    _ => TextInputAction.done,
  };

  List<TextInputFormatter> get _formatters {
    final List<TextInputFormatter> fs = [
      if (widget.isDecimalOnlyField)
        FilteringTextInputFormatter.allow(
          RegExp(r'^\d*\.?\d{0,}$'), // only digits and optional single dot
        ),
    ];

    if (widget.mode == GhostFieldMode.label ||
        widget.mode == GhostFieldMode.inline) {
      fs.add(_NoNewlineFormatter());
    }

    return fs;
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final fontSize = widget.style.fontSize ?? 14;
    final vPad = (fontSize * 0.35).clamp(4.0, 10.0);

    final field = TextField(
      controller: _controller,
      focusNode: _focus,
      minLines: 1,
      maxLines: _maxLines,
      keyboardType: _keyboardType,
      textInputAction: _inputAction,
      inputFormatters: _formatters,
      onSubmitted: widget.onSubmitted,
      onTapUpOutside: (_) => widget.onSubmitted(_controller.text),
      onChanged: (v) {
        // Rebuild on every keystroke so IntrinsicWidth re-measures
        if (widget.mode == GhostFieldMode.inline) setState(() {});
        widget.onChanged?.call(v);
      },
      onEditingComplete: widget.onEditingComplete,
      style: widget.style,
      cursorColor: _T.blue,
      cursorWidth: 1.5,
      decoration: InputDecoration(
        hintText: widget.hint,
        hintStyle: widget.style.copyWith(color: _T.slate300),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: vPad),
      ),
    );

    final decoration = BoxDecoration(
      color: _fill,
      borderRadius: BorderRadius.circular(6),
      border: _border,
      boxShadow: _shadow,
    );

    return MouseRegion(
      cursor: SystemMouseCursors.text,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child:
          widget.mode == GhostFieldMode.inline
              ? _InlineWrapper(
                minWidth: widget.inlineMinWidth,
                maxWidth: widget.inlineMaxWidth,
                decoration: decoration,
                child: field,
              )
              : AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                curve: Curves.easeOut,
                decoration: decoration,
                child: field,
              ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _InlineWrapper
//
// Uses IntrinsicWidth so the container hugs the text content width.
// ConstrainedBox enforces the min/max limits.
//
// IntrinsicWidth works by doing a two-pass layout:
//   1. Measure the unconstrained intrinsic width of the child (the text).
//   2. Constrain the child to exactly that width.
// This makes the container grow and shrink with every keystroke.
//
// Important: IntrinsicWidth is slightly more expensive than a fixed-width
// widget, but for a single editable label it's entirely negligible.
// ─────────────────────────────────────────────────────────────────────────────
class _InlineWrapper extends StatelessWidget {
  final double minWidth;
  final double maxWidth;
  final BoxDecoration decoration;
  final Widget child;

  const _InlineWrapper({
    required this.minWidth,
    required this.maxWidth,
    required this.decoration,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicWidth(
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: minWidth, maxWidth: maxWidth),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          decoration: decoration,
          child: child,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DESIGN TOKENS
// ─────────────────────────────────────────────────────────────────────────────
class _T {
  static const blue = Color(0xFF2563EB);
  static const slate100 = Color(0xFFF1F5F9);
  static const slate200 = Color(0xFFE2E8F0);
  static const slate300 = Color(0xFFCBD5E1);
  static const white = Colors.white;
}

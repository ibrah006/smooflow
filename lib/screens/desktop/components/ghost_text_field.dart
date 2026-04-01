import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─────────────────────────────────────────────────────────────────────────────
// GhostTextField
//
// Three modes via the [mode] parameter:
//
//   GhostFieldMode.singleLine   — one line, scrolls horizontally.
//                                 Enter = submit. Good for task titles.
//
//   GhostFieldMode.label        — wraps visually when content is too wide,
//                                 but the user CANNOT insert manual line breaks
//                                 (Enter = submit, newlines stripped from paste).
//                                 Good for long-ish labels inside constrained
//                                 parent widgets (client name, project heading…).
//
//   GhostFieldMode.multiline    — wraps AND allows manual newlines.
//                                 Enter = new line. Good for descriptions.
// ─────────────────────────────────────────────────────────────────────────────

enum GhostFieldMode { singleLine, label, multiline }

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

  const GhostTextField({
    super.key,
    required this.initialText,
    required this.style,
    required this.onSubmitted,
    this.hint,
    this.mode = GhostFieldMode.label,
    this.keyboardType,
    this.onChanged,
    this.onEditingComplete,
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
    return Colors.transparent;
  }

  Border get _border {
    if (_focused) return Border.all(color: _T.slate300);
    if (_hovered) return Border.all(color: _T.slate200);
    return Border.all(color: Colors.transparent);
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

  int? get _maxLines {
    switch (widget.mode) {
      case GhostFieldMode.singleLine:
        return 1; // fixed one line, horizontal scroll
      case GhostFieldMode.label:
      case GhostFieldMode.multiline:
        return null; // uncapped — grows with content
    }
  }

  int get _minLines => 1;

  TextInputType get _keyboardType {
    if (widget.keyboardType != null) return widget.keyboardType!;
    // multiline mode needs the multiline keyboard so the IME shows a return key
    return widget.mode == GhostFieldMode.multiline
        ? TextInputType.multiline
        : TextInputType.text;
  }

  TextInputAction get _inputAction {
    switch (widget.mode) {
      case GhostFieldMode.singleLine:
      case GhostFieldMode.label:
        return TextInputAction.done; // Enter submits — no line break
      case GhostFieldMode.multiline:
        return TextInputAction.newline;
    }
  }

  List<TextInputFormatter> get _formatters {
    // label mode: silently strip any \n the user tries to type or paste
    if (widget.mode == GhostFieldMode.label) {
      return const [_NoNewlineFormatter()];
    }
    return const [];
  }

  @override
  Widget build(BuildContext context) {
    final fontSize = widget.style.fontSize ?? 14;
    final vPad = (fontSize * 0.35).clamp(4.0, 10.0);

    return MouseRegion(
      cursor: SystemMouseCursors.text,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: _fill,
          borderRadius: BorderRadius.circular(6),
          border: _border,
          boxShadow: _shadow,
        ),
        child: TextField(
          controller: _controller,
          focusNode: _focus,
          minLines: _minLines,
          maxLines: _maxLines,
          keyboardType: _keyboardType,
          textInputAction: _inputAction,
          inputFormatters: _formatters,
          onSubmitted: widget.onSubmitted,
          onTapUpOutside: (_) => widget.onSubmitted(_controller.text),
          onChanged: widget.onChanged,
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

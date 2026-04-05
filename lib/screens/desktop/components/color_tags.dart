// ─────────────────────────────────────────────────────────────────────────────
// COLOR TAGS — detail_panel.dart addition
//
// Placement in DetailPanel.build():
//   After the project name row, before const SizedBox(height: 18):
//
//   _ColorTagsRow(
//     tags: _tags,
//     onChanged: (updated) => setState(() => _tags = updated),
//   ),
//   const SizedBox(height: 14),
//
// State in __DetailPanelState:
//   List<_ColorTag> _tags = [];
//
// Wire persistence in _onTagsChanged() — call your task update provider.
// ─────────────────────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────────────────────
// MODEL
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

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
  static const detailW = 400.0;
  static const r = 8.0;
  static const rLg = 12.0;
  static const rXl = 16.0;
}

class ColorTag {
  final String id;
  final String label;
  final TagColor color;

  const ColorTag({required this.id, required this.label, required this.color});

  ColorTag copyWith({String? label, TagColor? color}) =>
      ColorTag(id: id, label: label ?? this.label, color: color ?? this.color);
}

// Curated palette — saturated enough to read on white, restrained enough
// not to clash with the panel's blue/green/amber system colours.
enum TagColor { rose, orange, amber, lime, teal, sky, violet, pink, slate }

extension _TagColorX on TagColor {
  Color get fg =>
      const {
        TagColor.rose: Color(0xFFE11D48),
        TagColor.orange: Color(0xFFEA580C),
        TagColor.amber: Color(0xFFD97706),
        TagColor.lime: Color(0xFF65A30D),
        TagColor.teal: Color(0xFF0D9488),
        TagColor.sky: Color(0xFF0284C7),
        TagColor.violet: Color(0xFF7C3AED),
        TagColor.pink: Color(0xFFDB2777),
        TagColor.slate: Color(0xFF475569),
      }[this]!;

  Color get bg =>
      const {
        TagColor.rose: Color(0xFFFFF1F2),
        TagColor.orange: Color(0xFFFFF7ED),
        TagColor.amber: Color(0xFFFEF3C7),
        TagColor.lime: Color(0xFFF7FEE7),
        TagColor.teal: Color(0xFFF0FDFA),
        TagColor.sky: Color(0xFFEFF6FF),
        TagColor.violet: Color(0xFFF5F3FF),
        TagColor.pink: Color(0xFFFDF2F8),
        TagColor.slate: Color(0xFFF1F5F9),
      }[this]!;

  Color get border => fg.withOpacity(0.25);

  Color get dot => fg;

  String get name => toString().split('.').last;
}

// ─────────────────────────────────────────────────────────────────────────────
// _ColorTagsRow  — the main composable widget
// ─────────────────────────────────────────────────────────────────────────────
class ColorTagsRow extends StatefulWidget {
  final List<ColorTag> tags;
  final ValueChanged<List<ColorTag>> onChanged;

  const ColorTagsRow({super.key, required this.tags, required this.onChanged});

  @override
  State<ColorTagsRow> createState() => _ColorTagsRowState();
}

class _ColorTagsRowState extends State<ColorTagsRow> {
  // Which tag is in rename mode
  String? _editingId;
  final _editCtrl = TextEditingController();
  final _editFocus = FocusNode();

  // Whether the color picker popover is open and for which tag
  String? _pickerOpenId;

  // Add-tag input state
  bool _addingNew = false;
  final _addCtrl = TextEditingController();
  final _addFocus = FocusNode();
  TagColor _pendingColor = TagColor.sky;

  @override
  void dispose() {
    _editCtrl.dispose();
    _editFocus.dispose();
    _addCtrl.dispose();
    _addFocus.dispose();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  void _startEdit(ColorTag tag) {
    setState(() {
      _editingId = tag.id;
      _pickerOpenId = null;
    });
    _editCtrl.text = tag.label;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _editFocus.requestFocus();
      _editCtrl.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _editCtrl.text.length,
      );
    });
  }

  void _commitEdit(String tagId) {
    final label = _editCtrl.text.trim();
    if (label.isEmpty) {
      _deleteTag(tagId);
      return;
    }
    final updated =
        widget.tags.map((t) {
          return t.id == tagId ? t.copyWith(label: label) : t;
        }).toList();
    widget.onChanged(updated);
    setState(() => _editingId = null);
  }

  void _deleteTag(String tagId) {
    widget.onChanged(widget.tags.where((t) => t.id != tagId).toList());
    setState(() {
      _editingId = null;
      _pickerOpenId = null;
    });
  }

  void _changeColor(String tagId, TagColor color) {
    final updated =
        widget.tags.map((t) {
          return t.id == tagId ? t.copyWith(color: color) : t;
        }).toList();
    widget.onChanged(updated);
    setState(() => _pickerOpenId = null);
  }

  void _startAdding() {
    setState(() {
      _addingNew = true;
      _pendingColor = TagColor.sky;
      _addCtrl.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _addFocus.requestFocus(),
    );
  }

  void _commitAdd() {
    final label = _addCtrl.text.trim();
    if (label.isNotEmpty) {
      final newTag = ColorTag(
        id: '${DateTime.now().millisecondsSinceEpoch}',
        label: label,
        color: _pendingColor,
      );
      widget.onChanged([...widget.tags, newTag]);
    }
    setState(() => _addingNew = false);
    _addCtrl.clear();
  }

  void _cancelAdd() {
    setState(() => _addingNew = false);
    _addCtrl.clear();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // Existing tags
          ...widget.tags.map((tag) {
            final isEditing = _editingId == tag.id;
            final isPickerOpen = _pickerOpenId == tag.id;

            return isEditing
                ? _TagEditChip(
                  tag: tag,
                  controller: _editCtrl,
                  focusNode: _editFocus,
                  onSubmit: () => _commitEdit(tag.id),
                  onDelete: () => _deleteTag(tag.id),
                )
                : _TagChip(
                  tag: tag,
                  isPickerOpen: isPickerOpen,
                  onTap: () => _startEdit(tag),
                  onColorDotTap:
                      () => setState(
                        () => _pickerOpenId = isPickerOpen ? null : tag.id,
                      ),
                  onColorPick: (c) => _changeColor(tag.id, c),
                  onDelete: () => _deleteTag(tag.id),
                );
          }),

          // New-tag input
          if (_addingNew)
            _NewTagChip(
              controller: _addCtrl,
              focusNode: _addFocus,
              selectedColor: _pendingColor,
              onColorPick: (c) => setState(() => _pendingColor = c),
              onSubmit: _commitAdd,
              onCancel: _cancelAdd,
            ),

          // Add button
          if (!_addingNew) _AddTagButton(onTap: _startAdding),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _TagChip  — display state of a tag
// ─────────────────────────────────────────────────────────────────────────────
class _TagChip extends StatefulWidget {
  final ColorTag tag;
  final bool isPickerOpen;
  final VoidCallback onTap;
  final VoidCallback onColorDotTap;
  final ValueChanged<TagColor> onColorPick;
  final VoidCallback onDelete;

  const _TagChip({
    required this.tag,
    required this.isPickerOpen,
    required this.onTap,
    required this.onColorDotTap,
    required this.onColorPick,
    required this.onDelete,
  });

  @override
  State<_TagChip> createState() => _TagChipState();
}

class _TagChipState extends State<_TagChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.tag.color;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 130),
              padding: const EdgeInsets.only(
                left: 4,
                right: 6,
                top: 4,
                bottom: 4,
              ),
              decoration: BoxDecoration(
                color: _hovered ? c.bg : c.bg.withOpacity(0.75),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: _hovered ? c.border.withOpacity(0.5) : c.border,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Color dot — opens picker
                  GestureDetector(
                    onTap: widget.onColorDotTap,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 5),
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: c.dot,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: c.fg.withOpacity(0.3),
                              blurRadius: 3,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Label
                  Text(
                    widget.tag.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: c.fg,
                      letterSpacing: 0.1,
                    ),
                  ),
                  // Delete — only on hover
                  AnimatedSize(
                    duration: const Duration(milliseconds: 120),
                    child:
                        _hovered
                            ? Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: GestureDetector(
                                onTap: widget.onDelete,
                                behavior: HitTestBehavior.opaque,
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 11,
                                  color: c.fg.withOpacity(0.6),
                                ),
                              ),
                            )
                            : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Inline color picker popover
        if (widget.isPickerOpen)
          _ColorPickerPopover(
            current: widget.tag.color,
            onPick: widget.onColorPick,
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _TagEditChip  — rename mode: text field with same visual footprint as tag
// ─────────────────────────────────────────────────────────────────────────────
class _TagEditChip extends StatelessWidget {
  final ColorTag tag;
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSubmit;
  final VoidCallback onDelete;

  const _TagEditChip({
    required this.tag,
    required this.controller,
    required this.focusNode,
    required this.onSubmit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final c = tag.color;
    return Container(
      constraints: const BoxConstraints(minWidth: 60, maxWidth: 160),
      padding: const EdgeInsets.only(left: 6, right: 6, top: 3, bottom: 3),
      decoration: BoxDecoration(
        color: c.bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: c.fg.withOpacity(0.45), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: c.fg.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IntrinsicWidth(
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          onSubmitted: (_) => onSubmit(),
          onTapUpOutside: (_) => onSubmit(),
          maxLines: 1,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: c.fg,
          ),
          cursorColor: c.fg,
          cursorWidth: 1.5,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.zero,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            hintText: 'Label…',
            hintStyle: TextStyle(fontSize: 11, color: c.fg.withOpacity(0.4)),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _NewTagChip  — new tag creation state
// ─────────────────────────────────────────────────────────────────────────────
class _NewTagChip extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final TagColor selectedColor;
  final ValueChanged<TagColor> onColorPick;
  final VoidCallback onSubmit;
  final VoidCallback onCancel;

  const _NewTagChip({
    required this.controller,
    required this.focusNode,
    required this.selectedColor,
    required this.onColorPick,
    required this.onSubmit,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final c = selectedColor;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          constraints: const BoxConstraints(minWidth: 80, maxWidth: 180),
          padding: const EdgeInsets.only(left: 6, right: 6, top: 3, bottom: 3),
          decoration: BoxDecoration(
            color: c.bg,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: c.fg.withOpacity(0.45), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: c.fg.withOpacity(0.08),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Color dot (non-interactive here — picker is below)
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(right: 5),
                decoration: BoxDecoration(color: c.dot, shape: BoxShape.circle),
              ),
              IntrinsicWidth(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  onSubmitted: (_) => onSubmit(),
                  onTapUpOutside: (_) => onCancel(),
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: c.fg,
                  ),
                  cursorColor: c.fg,
                  cursorWidth: 1.5,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    hintText: 'Tag name…',
                    hintStyle: TextStyle(
                      fontSize: 11,
                      color: c.fg.withOpacity(0.4),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Color picker always open while creating
        _ColorPickerPopover(current: selectedColor, onPick: onColorPick),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ColorPickerPopover
// A compact horizontal swatch row that appears beneath a tag.
// ─────────────────────────────────────────────────────────────────────────────
class _ColorPickerPopover extends StatelessWidget {
  final TagColor current;
  final ValueChanged<TagColor> onPick;

  const _ColorPickerPopover({required this.current, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
      decoration: BoxDecoration(
        color: _T.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _T.slate200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children:
            TagColor.values.map((c) {
              final selected = c == current;
              return GestureDetector(
                onTap: () => onPick(c),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 110),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: selected ? 18 : 14,
                  height: selected ? 18 : 14,
                  decoration: BoxDecoration(
                    color: c.dot,
                    shape: BoxShape.circle,
                    border:
                        selected
                            ? Border.all(color: c.fg, width: 2)
                            : Border.all(color: Colors.transparent),
                    boxShadow:
                        selected
                            ? [
                              BoxShadow(
                                color: c.fg.withOpacity(0.4),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ]
                            : null,
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _AddTagButton
// ─────────────────────────────────────────────────────────────────────────────
class _AddTagButton extends StatefulWidget {
  final VoidCallback onTap;
  const _AddTagButton({required this.onTap});

  @override
  State<_AddTagButton> createState() => _AddTagButtonState();
}

class _AddTagButtonState extends State<_AddTagButton> {
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
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _hovered ? _T.slate100 : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: _hovered ? _T.slate300 : _T.slate200,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add_rounded,
                size: 12,
                color: _hovered ? _T.ink3 : _T.slate400,
              ),
              const SizedBox(width: 3),
              Text(
                'Add tag',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: _hovered ? _T.ink3 : _T.slate400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:smooflow/core/models/task.dart';
import 'package:smooflow/screens/desktop/components/detail_panel.dart';
import 'package:smooflow/screens/desktop/components/ghost_text_field.dart';

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
  static const r = 8.0;
  static const rLg = 12.0;
  static const rXl = 16.0;
}

class PrinterStub {
  final String id;
  final String name;
  final String nickname;
  final bool isAvailable;
  final String statusLabel;
  final Color statusColor;
  final Color statusBackgroundColor;

  const PrinterStub({
    required this.id,
    required this.name,
    required this.nickname,
    required this.isAvailable,
    required this.statusLabel,
    required this.statusColor,
    required this.statusBackgroundColor,
  });
}

class PrinterRow extends StatefulWidget {
  final PrinterStub printer;
  final bool isSelected;
  final VoidCallback? onTap;

  const PrinterRow({
    required this.printer,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<PrinterRow> createState() => _PrinterRowState();
}

class _PrinterRowState extends State<PrinterRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onTap == null;
    final selected = widget.isSelected;
    final p = widget.printer;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: MouseRegion(
        cursor:
            disabled ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color:
                  disabled
                      ? _T.slate50
                      : selected
                      ? _T.blue50
                      : _hovered
                      ? const Color(0xFFF8FBFF)
                      : _T.white,
              borderRadius: BorderRadius.circular(_T.r),
              border: Border.all(
                color:
                    selected
                        ? _T.blue.withOpacity(0.45)
                        : disabled
                        ? _T.slate100
                        : _hovered
                        ? _T.slate300
                        : _T.slate200,
                width: selected ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              children: [
                // Printer icon badge
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color:
                        disabled
                            ? _T.slate100
                            : selected
                            ? _T.blue.withOpacity(0.12)
                            : _T.slate100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.print_outlined,
                    size: 16,
                    color:
                        disabled
                            ? _T.slate300
                            : selected
                            ? _T.blue
                            : _T.slate500,
                  ),
                ),
                const SizedBox(width: 10),
                // Name + nickname
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: disabled ? _T.slate400 : _T.ink,
                        ),
                      ),
                      if (p.nickname.isNotEmpty) ...[
                        const SizedBox(height: 1),
                        Text(
                          p.nickname,
                          style: const TextStyle(
                            fontSize: 11,
                            color: _T.slate400,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Status pill
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: p.statusBackgroundColor,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: p.statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        p.statusLabel,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: p.statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
                if (selected) ...[
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 16,
                    color: _T.blue,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PRINT SPECIFICATIONS CARD  (unchanged)
// ─────────────────────────────────────────────────────────────────────────────
class PrintSpecItem {
  String id;
  String ref;
  double width;
  double height;
  int qty;
  String unit;

  PrintSpecItem({
    required this.id,
    required this.ref,
    required this.width,
    required this.height,
    required this.qty,
    this.unit = 'cm',
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'ref': ref,
    'w': width,
    'h': height,
    'qty': qty,
    'u': unit,
  };

  factory PrintSpecItem.fromMap(Map<String, dynamic> map) => PrintSpecItem(
    id: map['id'] ?? UniqueKey().toString(),
    ref: map['ref'] ?? '',
    width: (map['w'] as num?)?.toDouble() ?? 0.0,
    height: (map['h'] as num?)?.toDouble() ?? 0.0,
    qty: map['qty'] as int? ?? 1,
    unit: map['u'] ?? 'cm',
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// NEW CORPORATE INLINE MULTI-SIZE EDITOR
// ─────────────────────────────────────────────────────────────────────────────
class PrintSpecsEditor extends StatefulWidget {
  final Task task;
  final Function(List<PrintSpecItem> specs, bool sharedRef) onUpdate;

  const PrintSpecsEditor({required this.task, required this.onUpdate});

  @override
  State<PrintSpecsEditor> createState() => _PrintSpecsEditorState();
}

class _PrintSpecsEditorState extends State<PrintSpecsEditor> {
  bool _sharedRef = true;
  List<PrintSpecItem> _items = [];

  @override
  void initState() {
    super.initState();
    _initSpecs();
  }

  @override
  void didUpdateWidget(covariant PrintSpecsEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.task.id != widget.task.id) {
      _initSpecs();
    }
  }

  void _initSpecs() {
    final sizeStr = widget.task.size ?? '';
    if (sizeStr.trim().startsWith('[')) {
      try {
        final List<dynamic> decoded = jsonDecode(sizeStr);
        _items = decoded.map((e) => PrintSpecItem.fromMap(e)).toList();

        // Auto-detect if they share a ref
        if (_items.isNotEmpty) {
          final firstRef = _items.first.ref;
          _sharedRef = _items.every((item) => item.ref == firstRef);
        } else {
          _sharedRef = true;
        }
        return;
      } catch (_) {}
    }

    // Fallback: migrate legacy simple string representation
    final s = getSize(widget.task.size);
    final u = getUnit(widget.task.size ?? '');
    _items = [
      PrintSpecItem(
        id: UniqueKey().toString(),
        ref: widget.task.ref ?? '',
        width: s.width,
        height: s.height,
        qty: widget.task.quantity ?? 1,
        unit: u.isEmpty ? 'cm' : u,
      ),
    ];
  }

  void _notifyChange() {
    widget.onUpdate(_items, _sharedRef);
  }

  String _fmtNum(double n) =>
      n == n.toInt() ? n.toInt().toString() : n.toString();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _T.slate50.withOpacity(0.5),
        borderRadius: BorderRadius.circular(_T.rLg),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Shared Ref Toggle ──
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () {
                setState(() => _sharedRef = !_sharedRef);
                if (_sharedRef && _items.isNotEmpty) {
                  final masterRef = _items.first.ref;
                  for (var item in _items) {
                    item.ref = masterRef;
                  }
                }
                _notifyChange();
              },
              child: Row(
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 150),
                    child: Icon(
                      _sharedRef
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      key: ValueKey(_sharedRef),
                      color: _sharedRef ? _T.blue : _T.slate400,
                      size: 15,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Use a single reference for all sizes',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _T.slate500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Master Shared Reference Field ──
          if (_sharedRef) ...[
            Container(
              padding: const EdgeInsets.only(left: 2, bottom: 8),
              child: Row(
                children: [
                  const Text(
                    'Ref:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _T.slate400,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GhostTextField(
                      onEditingComplete: _notifyChange,
                      key: ValueKey(
                        'master_ref_${_items.isNotEmpty ? _items.first.id : ''}',
                      ),
                      initialText: _items.isNotEmpty ? _items.first.ref : '',
                      onSubmitted: (val) {
                        for (var item in _items) {
                          item.ref = val;
                        }
                        _notifyChange();
                      },
                      mode: GhostFieldMode.inline,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'monospace',
                        color: _T.ink3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: _T.slate200),
            const SizedBox(height: 8),
          ],

          // ── Table Headers ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              children: [
                if (!_sharedRef)
                  const Expanded(
                    flex: 3,
                    child: Text(
                      'REF',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: _T.slate400,
                      ),
                    ),
                  ),
                const Expanded(
                  flex: 4,
                  child: Text(
                    'SIZE (W × H cm)',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: _T.slate400,
                    ),
                  ),
                ),
                const Expanded(
                  flex: 2,
                  child: Text(
                    'QTY',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: _T.slate400,
                    ),
                  ),
                ),
                const SizedBox(width: 28), // delete placeholder
              ],
            ),
          ),

          // ── Table Rows ──
          ..._items.asMap().entries.map((e) {
            final index = e.key;
            final item = e.value;
            return _SpecRowInline(
              key: ValueKey(item.id),
              item: item,
              sharedRef: _sharedRef,
              onUpdate: () => _notifyChange(),
              onDelete: () {
                setState(() => _items.removeAt(index));
                _notifyChange();
              },
            );
          }),

          // ── Add Item Button ──
          const SizedBox(height: 4),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _items.add(
                    PrintSpecItem(
                      id: UniqueKey().toString(),
                      ref:
                          _sharedRef && _items.isNotEmpty
                              ? _items.first.ref
                              : '',
                      width: 0,
                      height: 0,
                      qty: 1,
                    ),
                  );
                });
                _notifyChange();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: _T.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        size: 12,
                        color: _T.blue,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Add another size',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: _T.blue,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpecRowInline extends StatefulWidget {
  final PrintSpecItem item;
  final bool sharedRef;
  final VoidCallback onUpdate;
  final VoidCallback onDelete;

  const _SpecRowInline({
    super.key,
    required this.item,
    required this.sharedRef,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  State<_SpecRowInline> createState() => _SpecRowInlineState();
}

class _SpecRowInlineState extends State<_SpecRowInline> {
  bool _hovered = false;

  String _fmt(double n) => n == n.toInt() ? n.toInt().toString() : n.toString();

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        decoration: BoxDecoration(
          color: _hovered ? _T.white : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: _hovered ? _T.slate200 : Colors.white),
        ),
        child: Row(
          children: [
            // Internal Item Ref (Hidden if shared)
            if (!widget.sharedRef)
              Expanded(
                flex: 3,
                child: GhostTextField(
                  key: ValueKey('${widget.item.id}_ref'),
                  initialText: widget.item.ref,
                  onSubmitted: (v) {
                    widget.item.ref = v;
                    widget.onUpdate();

                    print("[internal ref] - on submitted");
                  },
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontFamily: 'monospace',
                    color: _T.ink3,
                  ),
                  mode: GhostFieldMode.inline,
                ),
              ),

            // Width x Height
            Expanded(
              flex: 4,
              child: Row(
                children: [
                  GhostTextField(
                    key: ValueKey('${widget.item.id}_w'),
                    initialText: _fmt(widget.item.width),
                    onSubmitted: (v) {
                      widget.item.width = double.tryParse(v) ?? 0;
                      widget.onUpdate();
                    },
                    onEditingComplete: () {
                      print("on width editing complete");
                    },
                    isDecimalOnlyField: true,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _T.ink,
                    ),
                    mode: GhostFieldMode.inline,
                    inlineMinWidth: 24,
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      '×',
                      style: TextStyle(color: _T.slate400, fontSize: 13),
                    ),
                  ),
                  GhostTextField(
                    key: ValueKey('${widget.item.id}_h'),
                    initialText: _fmt(widget.item.height),
                    onSubmitted: (v) {
                      widget.item.height = double.tryParse(v) ?? 0;
                      widget.onUpdate();
                    },
                    isDecimalOnlyField: true,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _T.ink,
                    ),
                    mode: GhostFieldMode.inline,
                    inlineMinWidth: 24,
                  ),
                ],
              ),
            ),

            // Quantity
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  GhostTextField(
                    key: ValueKey('${widget.item.id}_qty'),
                    initialText: widget.item.qty.toString(),
                    onSubmitted: (v) {
                      widget.item.qty = int.tryParse(v) ?? 0;
                      widget.onUpdate();
                    },
                    isDecimalOnlyField: true,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _T.ink,
                    ),
                    mode: GhostFieldMode.inline,
                    inlineMinWidth: 20,
                  ),
                  const SizedBox(width: 2),
                  const Text(
                    'pcs',
                    style: TextStyle(fontSize: 11, color: _T.slate400),
                  ),
                ],
              ),
            ),

            // Delete Action
            SizedBox(
              width: 28,
              child: AnimatedOpacity(
                opacity: _hovered ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 150),
                child: IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 14,
                    color: _T.slate400,
                  ),
                  hoverColor: _T.red50,
                  color: _T.red,
                  onPressed: widget.onDelete,
                  splashRadius: 16,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

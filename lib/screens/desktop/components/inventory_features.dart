import 'package:flutter/material.dart';
import 'package:smooflow/core/models/material.dart';
import 'package:smooflow/screens/desktop/components/dialog_buttons.dart';
import 'package:smooflow/screens/desktop/components/field_label.dart';
import 'package:smooflow/screens/desktop/components/num_field.dart';
import 'package:smooflow/screens/desktop/components/smoofield.dart';
import 'package:smooflow/screens/desktop/components/stock_pill.dart';
import 'package:smooflow/screens/desktop/helpers/fmt_stock.dart';

// ─────────────────────────────────────────────────────────────────────────────
// INVENTORY FEATURE ADDITIONS
//
// Drop these into manage_materials_screen.dart.
//
// 1. WriteOffDialog          — write-off / manual adjustment with reason codes
// 2. StockAdjustDialog       — enhanced "Receive Batch" with supplier + PO
// 3. MaterialListTile        — quick "Receive" action on hover (replace existing)
// 4. ReorderPointField       — reusable field widget for create + edit panels
// 5. StockThresholdsCard     — replaces the plain NumField in _CreatePanel
//                               to show both minStock and reorderPoint together
// 6. WriteOffReasonChip      — internal chip for reason picker
// 7. BatchTagChip            — structured note parser/renderer for supplier+PO
//
// WIRING NOTES
// ─────────────────────────────────────────────────────────────────────────────
// Write-off:
//   In _DetailPanelState, add _showWriteOffDialog() and call it from a new
//   "Write Off" ghost button next to "Receive Batch" in the detail topbar.
//
// Quick receive from list:
//   Replace MaterialListTile with the version below. Pass an onQuickReceive
//   callback from _MaterialListPanel → _ManageMaterialsScreenState which
//   calls _showQuickStockInDialog(material).
//
// Reorder point:
//   Add a reorderPoint field to MaterialModel.create() and save it.
//   The StockThresholdsCard replaces the single NumField in _CreatePanel.
// ─────────────────────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────────────────────
// 1. WRITE-OFF DIALOG
//
// Reason codes model real-world stock discrepancies:
//   Damaged       — physically broken/unusable material
//   Wastage       — off-cuts, print waste, setup material
//   Correction    — fixing a data entry error (over/under-counted)
//   Expired       — past shelf life (inks, adhesives)
//   Other         — free-form
//
// The reason + note are stored in the transaction note field using a
// structured prefix:  "[WRITEOFF:Damaged] operator note here"
// This keeps the model unchanged while making the reason queryable.
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
  static const ink3 = Color(0xFF334155);
  static const white = Colors.white;
  static const r = 8.0;
  static const rLg = 12.0;
  static const rXl = 16.0;
}

enum _WriteOffReason { damaged, wastage, correction, expired, other }

extension _WriteOffReasonX on _WriteOffReason {
  String get label => switch (this) {
    _WriteOffReason.damaged => 'Damaged',
    _WriteOffReason.wastage => 'Wastage',
    _WriteOffReason.correction => 'Correction',
    _WriteOffReason.expired => 'Expired',
    _WriteOffReason.other => 'Other',
  };

  String get sublabel => switch (this) {
    _WriteOffReason.damaged => 'Broken or unusable',
    _WriteOffReason.wastage => 'Off-cuts, setup, trim',
    _WriteOffReason.correction => 'Fix a stock count error',
    _WriteOffReason.expired => 'Past shelf life',
    _WriteOffReason.other => 'Specify in notes',
  };

  IconData get icon => switch (this) {
    _WriteOffReason.damaged => Icons.broken_image_outlined,
    _WriteOffReason.wastage => Icons.delete_sweep_outlined,
    _WriteOffReason.correction => Icons.edit_note_rounded,
    _WriteOffReason.expired => Icons.hourglass_disabled_outlined,
    _WriteOffReason.other => Icons.more_horiz_rounded,
  };

  Color get color => switch (this) {
    _WriteOffReason.damaged => _T.red,
    _WriteOffReason.wastage => _T.amber,
    _WriteOffReason.correction => _T.blue,
    _WriteOffReason.expired => _T.purple,
    _WriteOffReason.other => _T.slate500,
  };

  Color get bg => switch (this) {
    _WriteOffReason.damaged => _T.red50,
    _WriteOffReason.wastage => _T.amber50,
    _WriteOffReason.correction => _T.blue50,
    _WriteOffReason.expired => _T.purple50,
    _WriteOffReason.other => _T.slate100,
  };

  /// Encodes reason into the note field so it's queryable without model changes
  String encode(String? userNote) {
    final tag = '[WRITEOFF:${label.toUpperCase()}]';
    return userNote != null && userNote.isNotEmpty ? '$tag $userNote' : tag;
  }
}

class WriteOffDialog extends StatefulWidget {
  final MaterialModel material;

  /// onConfirm receives the quantity to deduct and the encoded note string.
  final void Function(double qty, String note) onConfirm;

  const WriteOffDialog({required this.material, required this.onConfirm});

  @override
  State<WriteOffDialog> createState() => WriteOffDialogState();
}

class WriteOffDialogState extends State<WriteOffDialog> {
  final _qtyCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  _WriteOffReason? _reason;
  bool _submitted = false;

  bool get _qtyOk {
    final v = double.tryParse(_qtyCtrl.text.trim());
    return v != null && v > 0;
  }

  bool get _reasonOk => _reason != null;
  bool get _formOk => _qtyOk && _reasonOk;

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.material;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 480,
        decoration: BoxDecoration(
          color: _T.white,
          borderRadius: BorderRadius.circular(_T.rXl),
          border: Border.all(color: _T.slate200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 16, 0),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: _T.red50,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: _T.red.withOpacity(0.2)),
                    ),
                    child: const Icon(
                      Icons.remove_circle_outline_rounded,
                      size: 15,
                      color: _T.red,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Write Off Stock',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _T.ink,
                            letterSpacing: -0.1,
                          ),
                        ),
                        Text(
                          m.name,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: _T.slate400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  DialogCloseButton(onTap: () => Navigator.of(context).pop()),
                ],
              ),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Divider(height: 1, color: _T.slate100),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Current stock chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      color: _T.slate50,
                      borderRadius: BorderRadius.circular(_T.r),
                      border: Border.all(color: _T.slate200),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.inventory_2_outlined,
                          size: 14,
                          color: _T.slate400,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Current stock',
                          style: TextStyle(fontSize: 12, color: _T.slate400),
                        ),
                        const Spacer(),
                        Text(
                          '${fmtStock(m.currentStock)} ${m.unitShort}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _T.ink3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Reason picker
                  Row(
                    children: [
                      const Text(
                        'Reason',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _T.ink3,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        '*',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _T.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // 3 + 2 grid of reason chips
                  Column(
                    children: [
                      Row(
                        children:
                            _WriteOffReason.values
                                .take(3)
                                .map(
                                  (r) => Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.only(
                                        right:
                                            r == _WriteOffReason.correction
                                                ? 0
                                                : 8,
                                      ),
                                      child: WriteOffReasonChip(
                                        reason: r,
                                        selected: _reason == r,
                                        onTap:
                                            () => setState(() => _reason = r),
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          ..._WriteOffReason.values
                              .skip(3)
                              .map(
                                (r) => Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                      right: r == _WriteOffReason.other ? 0 : 8,
                                    ),
                                    child: WriteOffReasonChip(
                                      reason: r,
                                      selected: _reason == r,
                                      onTap: () => setState(() => _reason = r),
                                    ),
                                  ),
                                ),
                              ),
                          // Empty spacer to keep layout balanced
                          const Expanded(child: SizedBox()),
                          const Expanded(child: SizedBox()),
                        ],
                      ),
                    ],
                  ),

                  if (_submitted && !_reasonOk) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: const [
                        Icon(
                          Icons.error_outline_rounded,
                          size: 11,
                          color: _T.red,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Please select a reason',
                          style: TextStyle(
                            fontSize: 11,
                            color: _T.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Quantity
                  NumField(
                    controller: _qtyCtrl,
                    label: 'Quantity to write off',
                    hint: 'e.g. 5',
                    required: true,
                    suffix: m.unitShort,
                    onChanged: (_) => setState(() {}),
                    error:
                        _submitted && !_qtyOk ? 'Enter a valid quantity' : null,
                  ),
                  const SizedBox(height: 14),

                  // Note
                  SmooField(
                    controller: _noteCtrl,
                    label: 'Note',
                    hint: 'Optional — additional context',
                    icon: Icons.notes_rounded,
                  ),
                ],
              ),
            ),

            // ── Footer ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: DialogGhostButton(
                      label: 'Cancel',
                      onTap: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: _DialogPrimaryButton(
                      label: 'Confirm Write-Off',
                      icon: Icons.remove_circle_outline_rounded,
                      color: _T.red,
                      hoverColor: const Color(0xFFDC2626),
                      onTap: () {
                        setState(() => _submitted = true);
                        if (!_formOk) return;
                        final note = _reason!.encode(
                          _noteCtrl.text.trim().isEmpty
                              ? null
                              : _noteCtrl.text.trim(),
                        );
                        widget.onConfirm(
                          double.parse(_qtyCtrl.text.trim()),
                          note,
                        );
                      },
                    ),
                  ),
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
// WRITE-OFF REASON CHIP
// ─────────────────────────────────────────────────────────────────────────────
class WriteOffReasonChip extends StatefulWidget {
  final _WriteOffReason reason;
  final bool selected;
  final VoidCallback onTap;

  const WriteOffReasonChip({
    required this.reason,
    required this.selected,
    required this.onTap,
  });

  @override
  State<WriteOffReasonChip> createState() => WriteOffReasonChipState();
}

class WriteOffReasonChipState extends State<WriteOffReasonChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final r = widget.reason;
    final active = widget.selected;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: active ? r.bg : (_hovered ? _T.slate50 : _T.white),
            borderRadius: BorderRadius.circular(_T.r),
            border: Border.all(
              color: active ? r.color.withOpacity(0.45) : _T.slate200,
              width: active ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(r.icon, size: 13, color: active ? r.color : _T.slate400),
                  const Spacer(),
                  AnimatedOpacity(
                    opacity: active ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 130),
                    child: Icon(
                      Icons.check_circle_rounded,
                      size: 11,
                      color: r.color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                r.label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: active ? r.color : _T.ink3,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                r.sublabel,
                style: TextStyle(
                  fontSize: 9.5,
                  color: active ? r.color.withOpacity(0.65) : _T.slate400,
                  height: 1.3,
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
// 2. ENHANCED STOCK-IN DIALOG
//
// Extends the original StockAdjustDialog with:
//   • Supplier name field
//   • PO / reference number field
//   • Expiry date (optional, for inks/adhesives)
//   • Cost per unit (optional, for valuation)
//
// All extra fields are packed into the notes field as a structured JSON-like
// prefix so the model doesn't change:
//   [BATCH:supplier="Acme",po="PO-2024-001",cost=12.50,expiry="2025-06-01"] note
//
// A BatchTagChip widget below this parses and renders these tags.
// ─────────────────────────────────────────────────────────────────────────────
class StockAdjustDialog extends StatefulWidget {
  final MaterialModel material;
  final void Function(double qty, String? note) onConfirm;

  const StockAdjustDialog({required this.material, required this.onConfirm});

  @override
  State<StockAdjustDialog> createState() => StockAdjustDialogState();
}

class StockAdjustDialogState extends State<StockAdjustDialog> {
  final _qtyCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _supplierCtrl = TextEditingController();
  final _poCtrl = TextEditingController();
  final _costCtrl = TextEditingController();

  DateTime? _expiryDate;
  bool _submitted = false;

  bool get _qtyOk {
    final v = double.tryParse(_qtyCtrl.text.trim());
    return v != null && v > 0;
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _noteCtrl.dispose();
    _supplierCtrl.dispose();
    _poCtrl.dispose();
    _costCtrl.dispose();
    super.dispose();
  }

  String? _buildNote() {
    final supplier = _supplierCtrl.text.trim();
    final po = _poCtrl.text.trim();
    final cost = _costCtrl.text.trim();
    final note = _noteCtrl.text.trim();
    final expiry =
        _expiryDate != null
            ? '${_expiryDate!.year}-'
                '${_expiryDate!.month.toString().padLeft(2, '0')}-'
                '${_expiryDate!.day.toString().padLeft(2, '0')}'
            : null;

    final tags = <String>[];
    if (supplier.isNotEmpty) tags.add('supplier="$supplier"');
    if (po.isNotEmpty) tags.add('po="$po"');
    if (cost.isNotEmpty) tags.add('cost=$cost');
    if (expiry != null) tags.add('expiry="$expiry"');

    if (tags.isEmpty && note.isEmpty) return null;
    final prefix = tags.isNotEmpty ? '[BATCH:${tags.join(',')}]' : '';
    return note.isNotEmpty ? '$prefix $note'.trim() : prefix;
  }

  Future<void> _pickExpiry() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder:
          (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
              colorScheme: const ColorScheme.light(
                primary: _T.blue,
                onPrimary: Colors.white,
                surface: _T.white,
                onSurface: _T.ink,
              ),
            ),
            child: child!,
          ),
    );
    if (picked != null) setState(() => _expiryDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.material;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 480,
        decoration: BoxDecoration(
          color: _T.white,
          borderRadius: BorderRadius.circular(_T.rXl),
          border: Border.all(color: _T.slate200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 16, 0),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: _T.green50,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: _T.green.withOpacity(0.2)),
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      size: 15,
                      color: _T.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Receive Batch',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _T.ink,
                            letterSpacing: -0.1,
                          ),
                        ),
                        Text(
                          m.name,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: _T.slate400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  DialogCloseButton(onTap: () => Navigator.of(context).pop()),
                ],
              ),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Divider(height: 1, color: _T.slate100),
            ),

            // Scrollable body — dialog can get tall with all fields
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 520),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Current stock chip
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 11,
                      ),
                      decoration: BoxDecoration(
                        color: _T.slate50,
                        borderRadius: BorderRadius.circular(_T.r),
                        border: Border.all(color: _T.slate200),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.inventory_2_outlined,
                            size: 14,
                            color: _T.slate400,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Current stock',
                            style: TextStyle(fontSize: 12, color: _T.slate400),
                          ),
                          const Spacer(),
                          Text(
                            '${fmtStock(m.currentStock)} ${m.unitShort}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _T.ink3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Quantity (required) ──────────────────────────────
                    NumField(
                      controller: _qtyCtrl,
                      label: m.unitLong,
                      hint: 'e.g. 50',
                      required: true,
                      suffix: m.unitShort,
                      onChanged: (_) => setState(() {}),
                      error:
                          _submitted && !_qtyOk
                              ? 'Enter a valid quantity'
                              : null,
                    ),
                    const SizedBox(height: 16),

                    // ── Section divider: Supplier info ───────────────────
                    _SectionDividerLabel('Supplier & Order'),
                    const SizedBox(height: 10),

                    // Supplier name + PO on same row
                    Row(
                      children: [
                        Expanded(
                          child: SmooField(
                            controller: _supplierCtrl,
                            label: 'Supplier',
                            hint: 'e.g. Avery Dennison',
                            icon: Icons.business_outlined,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: SmooField(
                            controller: _poCtrl,
                            label: 'PO / Reference',
                            hint: 'e.g. PO-2024-001',
                            icon: Icons.tag_rounded,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Cost per unit + expiry date on same row
                    Row(
                      children: [
                        Expanded(
                          child: NumField(
                            controller: _costCtrl,
                            label: 'Cost per unit',
                            hint: 'e.g. 12.50',
                            required: false,
                            suffix: m.unitShort,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _ExpiryDateField(
                            value: _expiryDate,
                            onTap: _pickExpiry,
                            onClear: () => setState(() => _expiryDate = null),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ── Note ─────────────────────────────────────────────
                    SmooField(
                      controller: _noteCtrl,
                      label: 'Note',
                      hint: 'Optional — condition, delivery notes, etc.',
                      icon: Icons.notes_rounded,
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
            ),

            // ── Footer ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: DialogGhostButton(
                      label: 'Cancel',
                      onTap: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: _DialogPrimaryButton(
                      label: 'Confirm Receipt',
                      icon: Icons.add_rounded,
                      color: _T.green,
                      hoverColor: const Color(0xFF059669),
                      onTap: () {
                        setState(() => _submitted = true);
                        if (!_qtyOk) return;
                        widget.onConfirm(
                          double.parse(_qtyCtrl.text.trim()),
                          _buildNote(),
                        );
                      },
                    ),
                  ),
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
// EXPIRY DATE FIELD
// ─────────────────────────────────────────────────────────────────────────────
class _ExpiryDateField extends StatefulWidget {
  final DateTime? value;
  final VoidCallback onTap;
  final VoidCallback onClear;

  const _ExpiryDateField({
    required this.value,
    required this.onTap,
    required this.onClear,
  });

  @override
  State<_ExpiryDateField> createState() => _ExpiryDateFieldState();
}

class _ExpiryDateFieldState extends State<_ExpiryDateField> {
  bool _hovered = false;

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';

  bool get _expiringSoon {
    if (widget.value == null) return false;
    return widget.value!.difference(DateTime.now()).inDays <= 90;
  }

  @override
  Widget build(BuildContext context) {
    final hasValue = widget.value != null;
    final Color borderColor =
        hasValue
            ? (_expiringSoon ? _T.amber : _T.green).withOpacity(0.45)
            : (_hovered ? _T.blue : _T.slate200);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FieldLabel('Expiry date', optional: true),
        const SizedBox(height: 7),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 130),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color:
                    hasValue
                        ? (_expiringSoon ? _T.amber50 : _T.green50)
                        : (_hovered ? _T.white : _T.slate50),
                borderRadius: BorderRadius.circular(_T.r),
                border: Border.all(
                  color: borderColor,
                  width: hasValue ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_month_outlined,
                    size: 14,
                    color:
                        hasValue
                            ? (_expiringSoon ? _T.amber : _T.green)
                            : _T.slate400,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      hasValue ? _fmt(widget.value!) : 'No expiry',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            hasValue ? FontWeight.w500 : FontWeight.w400,
                        color:
                            hasValue
                                ? (_expiringSoon ? _T.amber : _T.green)
                                : _T.slate300,
                      ),
                    ),
                  ),
                  if (hasValue)
                    GestureDetector(
                      onTap: widget.onClear,
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Icon(
                          Icons.close_rounded,
                          size: 13,
                          color: _expiringSoon ? _T.amber : _T.green,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BATCH TAG CHIP — parses [BATCH:...] prefix and renders structured metadata
//
// Use this in _BatchDetailPanel to display supplier/PO/cost/expiry
// from the notes field in a clean visual format instead of raw text.
//
// Usage:
//   if (batch.notes != null)
//     BatchTagChip.fromNote(batch.notes!)
// ─────────────────────────────────────────────────────────────────────────────
class _BatchMetaCard extends StatelessWidget {
  final String? supplier;
  final String? po;
  final String? cost;
  final String? expiry;
  final String unitShort;

  const _BatchMetaCard({
    required this.supplier,
    required this.po,
    required this.cost,
    required this.expiry,
    required this.unitShort,
  });

  /// Parses a note string and returns a _BatchMetaCard if tags are present.
  static _BatchMetaCard? fromNote(String note, String unitShort) {
    final match = RegExp(r'\[BATCH:([^\]]+)\]').firstMatch(note);
    if (match == null) return null;
    final raw = match.group(1)!;
    String? get(String key) {
      final m = RegExp('$key="([^"]+)"').firstMatch(raw);
      if (m != null) return m.group(1);
      final m2 = RegExp('$key=([^,]+)').firstMatch(raw);
      return m2?.group(1);
    }

    return _BatchMetaCard(
      supplier: get('supplier'),
      po: get('po'),
      cost: get('cost'),
      expiry: get('expiry'),
      unitShort: unitShort,
    );
  }

  bool get _hasAny =>
      supplier != null || po != null || cost != null || expiry != null;

  bool get _isExpiringSoon {
    if (expiry == null) return false;
    try {
      final parts = expiry!.split('-');
      final d = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
      return d.difference(DateTime.now()).inDays <= 90;
    } catch (_) {
      return false;
    }
  }

  bool get _isExpired {
    if (expiry == null) return false;
    try {
      final parts = expiry!.split('-');
      final d = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
      return d.isBefore(DateTime.now());
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasAny) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _T.white,
        borderRadius: BorderRadius.circular(_T.rLg),
        border: Border.all(color: _T.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: _T.slate100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.business_outlined,
                  size: 11,
                  color: _T.slate500,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'BATCH INFO',
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.7,
                  color: _T.slate400,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Meta rows
          if (supplier != null)
            _MetaRow(
              icon: Icons.business_outlined,
              label: 'Supplier',
              value: supplier!,
            ),
          if (po != null) ...[
            if (supplier != null) const SizedBox(height: 8),
            _MetaRow(
              icon: Icons.tag_rounded,
              label: 'PO / Ref',
              value: po!,
              mono: true,
            ),
          ],
          if (cost != null) ...[
            if (supplier != null || po != null) const SizedBox(height: 8),
            _MetaRow(
              icon: Icons.payments_outlined,
              label: 'Cost',
              value: '${cost!} / $unitShort',
            ),
          ],
          if (expiry != null) ...[
            if (supplier != null || po != null || cost != null)
              const SizedBox(height: 8),
            _MetaRow(
              icon: Icons.calendar_month_outlined,
              label: 'Expiry',
              value: expiry!.replaceAllMapped(
                RegExp(r'(\d{4})-(\d{2})-(\d{2})'),
                (m) => '${m[3]}/${m[2]}/${m[1]}',
              ),
              valueColor:
                  _isExpired
                      ? _T.red
                      : _isExpiringSoon
                      ? _T.amber
                      : _T.green,
              valueSuffix:
                  _isExpired
                      ? ' · Expired'
                      : _isExpiringSoon
                      ? ' · Expiring soon'
                      : null,
            ),
          ],
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final String? valueSuffix;
  final bool mono;

  const _MetaRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.valueSuffix,
    this.mono = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 12, color: _T.slate400),
        const SizedBox(width: 8),
        SizedBox(
          width: 68,
          child: Text(
            label,
            style: const TextStyle(fontSize: 11.5, color: _T.slate400),
          ),
        ),
        Expanded(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? _T.ink3,
                    fontFamily: mono ? 'monospace' : null,
                  ),
                ),
                if (valueSuffix != null)
                  TextSpan(
                    text: valueSuffix,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: valueColor ?? _T.slate400,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. MATERIAL LIST TILE WITH QUICK-RECEIVE HOVER ACTION
//
// Replaces the existing MaterialListTile.
// On hover, a ghost "Receive" button appears on the right — one tap opens
// the stock-in dialog without having to first open the detail panel.
// ─────────────────────────────────────────────────────────────────────────────
class MaterialListTile extends StatefulWidget {
  final MaterialModel material;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onQuickReceive;

  const MaterialListTile({
    required this.material,
    required this.isSelected,
    required this.onTap,
    required this.onQuickReceive,
  });

  @override
  State<MaterialListTile> createState() => MaterialListTileState();
}

class MaterialListTileState extends State<MaterialListTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final m = widget.material;
    final selected = widget.isSelected;

    final Color stockColor;
    final Color stockBg;
    final String stockLabel;
    if (m.isCriticalStock) {
      stockColor = _T.red;
      stockBg = _T.red50;
      stockLabel = 'Out of stock';
    } else if (m.isLowStock) {
      stockColor = _T.amber;
      stockBg = _T.amber50;
      stockLabel = 'Low stock';
    } else {
      stockColor = _T.green;
      stockBg = _T.green50;
      stockLabel = 'In stock';
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          decoration: BoxDecoration(
            color:
                selected
                    ? _T.blue50
                    : _hovered
                    ? _T.slate50
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(_T.r),
            border: Border.all(
              color: selected ? _T.blue.withOpacity(0.35) : _T.slate200,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              // Icon badge
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: selected ? _T.blue.withOpacity(0.10) : _T.slate100,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  Icons.layers_outlined,
                  size: 15,
                  color: selected ? _T.blue : _T.slate500,
                ),
              ),
              const SizedBox(width: 10),

              // Name + stock amount
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m.name,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: selected ? _T.blue : _T.ink,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          '${fmtStock(m.currentStock)} ${m.unitShort}',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: _T.slate400,
                          ),
                        ),
                        // Reorder point warning — shown when stock is at
                        // or below reorder point but not yet critically low
                        if (m.isLowStock &&
                            // m.currentStock <= m.reorderPoint! &&
                            !m.isCriticalStock) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: _T.amber50,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Reorder',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: _T.amber,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Right side: stock pill OR quick-receive button
              // Quick-receive appears on hover, pill otherwise
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 140),
                child:
                    _hovered && !selected
                        ? _QuickReceiveButton(
                          key: const ValueKey('receive'),
                          onTap: widget.onQuickReceive,
                        )
                        : StockPill(
                          key: const ValueKey('pill'),
                          label: stockLabel,
                          color: stockColor,
                          bg: stockBg,
                          collapsed: !_hovered && !selected,
                        ),
              ),

              if (selected) ...[
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: _T.blue,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickReceiveButton extends StatefulWidget {
  final VoidCallback onTap;
  const _QuickReceiveButton({super.key, required this.onTap});

  @override
  State<_QuickReceiveButton> createState() => _QuickReceiveButtonState();
}

class _QuickReceiveButtonState extends State<_QuickReceiveButton> {
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
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: _hovered ? _T.green : _T.green50,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: _hovered ? _T.green : _T.green.withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add_rounded,
                size: 11,
                color: _hovered ? _T.white : _T.green,
              ),
              const SizedBox(width: 4),
              Text(
                'Receive',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: _hovered ? _T.white : _T.green,
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
// 4. STOCK THRESHOLDS CARD
//
// Replaces the single NumField for minStockLevel in _CreatePanel and any
// edit flow. Shows both minStock and reorderPoint together with a visual
// explanation of what each means.
// ─────────────────────────────────────────────────────────────────────────────
class StockThresholdsCard extends StatelessWidget {
  final TextEditingController minStockCtrl;
  final TextEditingController reorderCtrl;
  final String? unit;

  const StockThresholdsCard({
    required this.minStockCtrl,
    required this.reorderCtrl,
    this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Reorder point — upper threshold, triggers "time to order"
        NumField(
          controller: reorderCtrl,
          label: 'Reorder Point',
          hint: 'e.g. 20',
          required: false,
          suffix: unit,
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: _T.blue50,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: const [
              Icon(Icons.info_outline_rounded, size: 11, color: _T.blue),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'When stock drops to this level, a "Reorder" badge appears '
                  'on the material — signal to place a new order.',
                  style: TextStyle(fontSize: 11, color: _T.blue, height: 1.4),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Min stock level — lower threshold, triggers "critical" status
        NumField(
          controller: minStockCtrl,
          label: 'Minimum Stock Level',
          hint: 'e.g. 5',
          required: false,
          suffix: unit,
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: _T.amber50,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: const [
              Icon(Icons.warning_amber_outlined, size: 11, color: _T.amber),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'When stock falls to this level, the material is marked '
                  '"Low stock" or "Out of stock" and highlighted in red.',
                  style: TextStyle(fontSize: 11, color: _T.amber, height: 1.4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED HELPERS
// ─────────────────────────────────────────────────────────────────────────────

// Section divider label inside a dialog body — matches _DetailSectionTitle
class _SectionDividerLabel extends StatelessWidget {
  final String text;
  const _SectionDividerLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          text.toUpperCase(),
          style: const TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: _T.slate400,
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(child: Divider(height: 1, color: _T.slate100)),
      ],
    );
  }
}

// ── Updated _DialogPrimaryButton — accepts custom color for write-off (red)
// Replace the existing _DialogPrimaryButton with this version.
class _DialogPrimaryButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  final Color hoverColor;

  const _DialogPrimaryButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.color = const Color(0xFF2563EB), // _T.blue
    this.hoverColor = const Color(0xFF1D4ED8), // _T.blueHover
  });

  @override
  State<_DialogPrimaryButton> createState() => _DialogPrimaryButtonState();
}

class _DialogPrimaryButtonState extends State<_DialogPrimaryButton> {
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
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: _hovered ? widget.hoverColor : widget.color,
            borderRadius: BorderRadius.circular(_T.r),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, size: 14, color: Colors.white),
              const SizedBox(width: 7),
              Text(
                widget.label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
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

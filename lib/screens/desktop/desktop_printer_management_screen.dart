// ─────────────────────────────────────────────────────────────────────────────
// manage_printers_screen.dart
//
// Desktop master-detail screen for managing printers.
//
// LAYOUT
// ──────
//   Topbar (58 px, white, slate200 bottom border)
//   └── Body: horizontal split
//       ├── LEFT  (380 px fixed) — searchable printer list
//       └── RIGHT (flexible)     — create / edit form panel
//                                  idle pane when nothing is selected
//
// DESIGN SYSTEM
// ─────────────
//   Identical token class _T, _SectionCard anatomy (rXl, shadow, icon-header,
//   slate100 divider), _SmooField (focus-animated border), _FieldLabel
//   (required * / Optional badge), FilledButton.icon / OutlinedButton CTAs —
//   all copied verbatim from create_task_screen.dart.
//
// DATA LOGIC
// ──────────
//   _savePrinter / _confirmDelete bodies lifted from add_printer_screen.dart.
//   Zero logic changes; only presentation layer is new.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/core/models/printer.dart';
import 'package:smooflow/providers/printer_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TOKENS  — identical to create_task_screen.dart
// ─────────────────────────────────────────────────────────────────────────────
class _T {
  static const blue      = Color(0xFF2563EB);
  static const blueHover = Color(0xFF1D4ED8);
  static const blue100   = Color(0xFFDBEAFE);
  static const blue50    = Color(0xFFEFF6FF);
  static const green     = Color(0xFF10B981);
  static const green50   = Color(0xFFECFDF5);
  static const amber     = Color(0xFFF59E0B);
  static const amber50   = Color(0xFFFEF3C7);
  static const red       = Color(0xFFEF4444);
  static const red50     = Color(0xFFFEE2E2);
  static const purple    = Color(0xFF8B5CF6);
  static const purple50  = Color(0xFFF3E8FF);
  static const slate50   = Color(0xFFF8FAFC);
  static const slate100  = Color(0xFFF1F5F9);
  static const slate200  = Color(0xFFE2E8F0);
  static const slate300  = Color(0xFFCBD5E1);
  static const slate400  = Color(0xFF94A3B8);
  static const slate500  = Color(0xFF64748B);
  static const ink       = Color(0xFF0F172A);
  static const ink2      = Color(0xFF1E293B);
  static const ink3      = Color(0xFF334155);
  static const white     = Colors.white;
  static const r         = 8.0;
  static const rLg       = 12.0;
  static const rXl       = 16.0;
}

// ─────────────────────────────────────────────────────────────────────────────
// STATUS HELPERS
// ─────────────────────────────────────────────────────────────────────────────
Color     _sColor(PrinterStatus s) => switch (s) {
  PrinterStatus.active      => _T.green,
  PrinterStatus.maintenance => _T.amber,
  _                         => _T.slate400,
};
Color     _sBg(PrinterStatus s) => switch (s) {
  PrinterStatus.active      => _T.green50,
  PrinterStatus.maintenance => _T.amber50,
  _                         => _T.slate100,
};
IconData  _sIcon(PrinterStatus s) => switch (s) {
  PrinterStatus.active      => Icons.check_circle_outline_rounded,
  PrinterStatus.maintenance => Icons.build_outlined,
  _                         => Icons.power_off_outlined,
};
String    _sLabel(PrinterStatus s) => switch (s) {
  PrinterStatus.active      => 'Active',
  PrinterStatus.maintenance => 'Maintenance',
  _                         => 'Offline',
};

// ─────────────────────────────────────────────────────────────────────────────
// ROOT SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class DesktopPrinterManagementScreen extends ConsumerStatefulWidget {
  const DesktopPrinterManagementScreen({super.key});

  @override
  ConsumerState<DesktopPrinterManagementScreen> createState() =>
      _DesktopManagePrintersScreenState();
}

class _DesktopManagePrintersScreenState
    extends ConsumerState<DesktopPrinterManagementScreen> {
  Printer? _selected;
  bool     _showCreate = false;

  final _searchCtrl = TextEditingController();
  String get _q => _searchCtrl.text.trim().toLowerCase();

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  void _selectPrinter(Printer p) =>
      setState(() { _selected = p; _showCreate = false; });

  void _openCreate() =>
      setState(() { _selected = null; _showCreate = true; });

  void _closePanel() =>
      setState(() { _selected = null; _showCreate = false; });

  @override
  Widget build(BuildContext context) {
    final all      = ref.watch(printerNotifierProvider).printers;
    final filtered = _q.isEmpty
        ? all
        : all.where((p) =>
            p.name.toLowerCase().contains(_q) ||
            p.nickname.toLowerCase().contains(_q)).toList();

    final showPanel = _selected != null || _showCreate;

    return Scaffold(
      backgroundColor: _T.slate50,
      body: Column(children: [
        _Topbar(onAdd: _openCreate),
        Expanded(child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── LEFT: printer list ───────────────────────────────────────
            SizedBox(
              width: 380,
              child: Container(
                decoration: const BoxDecoration(
                  color: _T.white,
                  border: Border(right: BorderSide(color: _T.slate200)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [

                    // List subheader
                    Container(
                      height: 52,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: _T.slate200)),
                      ),
                      child: Row(children: [
                        Text(
                          '${all.length} Printer${all.length == 1 ? '' : 's'}',
                          style: const TextStyle(
                            fontSize:   12.5,
                            fontWeight: FontWeight.w700,
                            color:      _T.ink3,
                          ),
                        ),
                        const Spacer(),
                        // Free / busy count pills
                        _MiniPill(
                          label: '${all.where((p) => p.status == PrinterStatus.active && !p.isBusy).length} free',
                          color: _T.green, bg: _T.green50,
                        ),
                        const SizedBox(width: 6),
                        _MiniPill(
                          label: '${all.where((p) => p.isBusy).length} busy',
                          color: _T.blue, bg: _T.blue50,
                        ),
                      ]),
                    ),

                    // Search
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                      child: _SearchBar(
                        controller: _searchCtrl,
                        onChanged:  (_) => setState(() {}),
                      ),
                    ),

                    // Rows
                    Expanded(
                      child: filtered.isEmpty
                          ? _EmptyListState(hasSearch: _q.isNotEmpty)
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 4),
                              itemBuilder: (_, i) {
                                final p = filtered[i];
                                return _PrinterListTile(
                                  printer:    p,
                                  isSelected: _selected?.id == p.id,
                                  onTap: () => _selectPrinter(p),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),

            // ── RIGHT: form or idle pane ─────────────────────────────────
            Expanded(
              child: showPanel
                  ? _FormPanel(
                      key:       ValueKey(_selected?.id ?? 'new'),
                      printer:   _selected,
                      onClose:   _closePanel,
                      onSaved:   _closePanel,
                      onDeleted: _closePanel,
                    )
                  : const _IdlePane(),
            ),
          ],
        )),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TOPBAR  — matches create_task_screen.dart exactly (58 px, back btn, icon)
// ─────────────────────────────────────────────────────────────────────────────
class _Topbar extends StatelessWidget {
  final VoidCallback onAdd;
  const _Topbar({required this.onAdd});

  @override
  Widget build(BuildContext context) => Container(
    height: 58,
    padding: const EdgeInsets.symmetric(horizontal: 20),
    decoration: const BoxDecoration(
      color:  _T.white,
      border: Border(bottom: BorderSide(color: _T.slate200)),
    ),
    child: Row(children: [
      // Back
      Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(_T.r),
        child: InkWell(
          onTap:        () => Navigator.of(context).maybePop(),
          borderRadius: BorderRadius.circular(_T.r),
          child: Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color:        _T.slate100,
              borderRadius: BorderRadius.circular(_T.r),
              border:       Border.all(color: _T.slate200),
            ),
            child: const Icon(Icons.arrow_back_rounded,
                size: 17, color: _T.ink3),
          ),
        ),
      ),
      const SizedBox(width: 14),

      // Icon badge
      Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          color:        _T.blue50,
          borderRadius: BorderRadius.circular(9),
          border:       Border.all(color: _T.blue.withOpacity(0.2)),
        ),
        child: const Icon(Icons.print_rounded, size: 16, color: _T.blue),
      ),
      const SizedBox(width: 12),

      // Dual-line title
      const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Manage Printers',
              style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w700,
                color: _T.ink, letterSpacing: -0.2)),
          Text('Configure and add production printers',
              style: TextStyle(
                fontSize: 10.5, color: _T.slate400,
                fontWeight: FontWeight.w500)),
        ],
      ),

      const Spacer(),

      // Add printer CTA
      FilledButton.icon(
        onPressed: onAdd,
        style: FilledButton.styleFrom(
          backgroundColor: _T.blue,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_T.r)),
          textStyle: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w700),
        ),
        icon:  const Icon(Icons.add_rounded, size: 16),
        label: const Text('Add Printer'),
      ),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// PRINTER LIST TILE
// ─────────────────────────────────────────────────────────────────────────────
class _PrinterListTile extends StatefulWidget {
  final Printer  printer;
  final bool     isSelected;
  final VoidCallback onTap;
  const _PrinterListTile({
    required this.printer,
    required this.isSelected,
    required this.onTap,
  });
  @override
  State<_PrinterListTile> createState() => _PrinterListTileState();
}

class _PrinterListTileState extends State<_PrinterListTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final p        = widget.printer;
    final selected = widget.isSelected;

    final Color dotColor;
    final Color dotBg;
    final String statusText;
    if (p.isBusy) {
      dotColor = _T.blue; dotBg = _T.blue50; statusText = 'Busy';
    } else {
      dotColor = _sColor(p.status);
      dotBg    = _sBg(p.status);
      statusText = _sLabel(p.status);
    }

    return MouseRegion(
      cursor:  SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          decoration: BoxDecoration(
            color: selected
                  ? _T.blue50
                  : _hovered ? _T.slate50 : Colors.transparent,
            borderRadius: BorderRadius.circular(_T.r),
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 130),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(_T.r),
              border: Border.all(
                color: selected
                    ? _T.blue.withOpacity(0.35)
                    : _hovered ? _T.slate200 : _T.slate200,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(children: [
              // Icon
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: selected
                      ? _T.blue.withOpacity(0.10)
                      : _T.slate100,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(Icons.print_outlined,
                    size: 17,
                    color: selected ? _T.blue : _T.slate500),
              ),
              const SizedBox(width: 12),
          
              // Name + nickname
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.name,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize:   13,
                          fontWeight: FontWeight.w600,
                          color:      selected ? _T.blue : _T.ink,
                        )),
                    Text(p.nickname,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 11.5, color: _T.slate400)),
                  ],
                ),
              ),
          
              // Status pill
              _StatusPill(label: statusText, color: dotColor, bg: dotBg),
          
              if (selected) ...[
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right_rounded,
                    size: 16, color: _T.blue),
              ],
            ]),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// IDLE PANE
// ─────────────────────────────────────────────────────────────────────────────
class _IdlePane extends StatelessWidget {
  const _IdlePane();

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 56, height: 56,
        decoration: BoxDecoration(
          color:        _T.slate100,
          borderRadius: BorderRadius.circular(14),
          border:       Border.all(color: _T.slate200),
        ),
        child: const Icon(Icons.print_outlined,
            size: 26, color: _T.slate400),
      ),
      const SizedBox(height: 14),
      const Text('Select a printer to view details',
          style: TextStyle(
            fontSize:   13.5,
            fontWeight: FontWeight.w600,
            color:      _T.slate400,
          )),
      const SizedBox(height: 4),
      const Text('or click Add Printer to create a new one',
          style: TextStyle(fontSize: 12, color: _T.slate300)),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// FORM PANEL  — create or edit, right-hand side
// ─────────────────────────────────────────────────────────────────────────────
class _FormPanel extends ConsumerStatefulWidget {
  final Printer?     printer;
  final VoidCallback onClose, onSaved, onDeleted;

  const _FormPanel({
    super.key,
    required this.printer,
    required this.onClose,
    required this.onSaved,
    required this.onDeleted,
  });

  @override
  ConsumerState<_FormPanel> createState() => _FormPanelState();
}

class _FormPanelState extends ConsumerState<_FormPanel> {
  late TextEditingController _nameCtrl;
  late TextEditingController _nickCtrl;
  late TextEditingController _locCtrl;

  PrinterStatus _status    = PrinterStatus.active;
  bool          _submitted = false;
  bool          _saving    = false;

  bool get _isEditing => widget.printer != null;
  bool get _nameOk    => _nameCtrl.text.trim().isNotEmpty;
  bool get _nickOk    => _nickCtrl.text.trim().isNotEmpty;
  bool get _formOk    => _nameOk && _nickOk;

  @override
  void initState() {
    super.initState();

    Future.microtask(() async{
      await ref.watch(printerNotifierProvider.notifier).fetchPrinters();
    });

    _nameCtrl = TextEditingController(text: widget.printer?.name     ?? '');
    _nickCtrl = TextEditingController(text: widget.printer?.nickname ?? '');
    _locCtrl  = TextEditingController(text: widget.printer?.location ?? '');
    if (_isEditing) _status = widget.printer!.status;
    for (final c in [_nameCtrl, _nickCtrl, _locCtrl]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _nickCtrl.dispose(); _locCtrl.dispose();
    super.dispose();
  }

  // ── Data logic — verbatim from add_printer_screen.dart ────────────────────

  void _savePrinter() async {
    setState(() => _submitted = true);
    if (!_formOk) return;

    setState(() => _saving = true);

    if (_isEditing) {
      try {
        await ref.read(printerNotifierProvider.notifier).updatePrinter(
          widget.printer!.id,
          name:     _nameCtrl.text,
          nickname: _nickCtrl.text,
          location: _locCtrl.text,
          status:   _status,
        );
      } catch (e) {
        _snack('Failed to update printer. Please try again.', isError: true);
        setState(() => _saving = false);
        return;
      }
      _snack('Printer updated successfully', isError: false);
      setState(() => _saving = false);
      widget.onSaved();
      return;
    }

    await ref.read(printerNotifierProvider.notifier).createPrinter(
      name:     _nameCtrl.text,
      nickname: _nickCtrl.text,
      location: _locCtrl.text,
    );
    _snack('Printer added', isError: false);
    setState(() => _saving = false);
    widget.onSaved();
  }

  void _confirmDelete() {
    showDialog<void>(
      context:      context,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (_) => _DeleteDialog(
        printerName: widget.printer?.name ?? 'this printer',
        onConfirm: () {
          Navigator.of(context).pop();
          // TODO: await ref.read(printerNotifierProvider.notifier)
          //           .deletePrinter(widget.printer!.id);
          _snack('Printer deleted', isError: false);
          widget.onDeleted();
        },
      ),
    );
  }

  void _snack(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(
          isError
              ? Icons.error_outline_rounded
              : Icons.check_circle_outline_rounded,
          size: 15, color: Colors.white,
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(msg,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w500))),
      ]),
      backgroundColor: _T.ink,
      behavior:        SnackBarBehavior.floating,
      margin:          const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_T.r)),
      duration: const Duration(seconds: 4),
    ));
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    print("we're at the build");
    return Container(
      decoration: const BoxDecoration(
        color:  _T.slate50,
        border: Border(left: BorderSide(color: _T.slate200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [

          // ── Panel topbar — mirrors the screen topbar height & style ────
          Container(
            height: 58,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: const BoxDecoration(
              color:  _T.white,
              border: Border(bottom: BorderSide(color: _T.slate200)),
            ),
            child: Row(children: [
              // Close
              Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(_T.r),
                child: InkWell(
                  onTap:        widget.onClose,
                  borderRadius: BorderRadius.circular(_T.r),
                  child: Container(
                    width: 34, height: 34,
                    decoration: BoxDecoration(
                      color:        _T.slate100,
                      borderRadius: BorderRadius.circular(_T.r),
                      border:       Border.all(color: _T.slate200),
                    ),
                    child: const Icon(Icons.close_rounded,
                        size: 17, color: _T.ink3),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Dual-line title
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isEditing
                          ? _nameCtrl.text.isNotEmpty
                              ? _nameCtrl.text
                              : 'Printer Details'
                          : 'New Printer',
                      style: const TextStyle(
                        fontSize:   15,
                        fontWeight: FontWeight.w700,
                        color:      _T.ink,
                        letterSpacing: -0.2,
                      ),
                    ),
                    Text(
                      _isEditing
                          ? 'Edit printer settings'
                          : 'Configure and add to fleet',
                      style: const TextStyle(
                        fontSize:   10.5,
                        color:      _T.slate400,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Live status badge (edit only)
              if (_isEditing) ...[
                _StatusPill(
                  label:  widget.printer!.isBusy
                      ? 'Busy'
                      : _sLabel(widget.printer!.status),
                  color:  widget.printer!.isBusy
                      ? _T.blue
                      : _sColor(widget.printer!.status),
                  bg:     widget.printer!.isBusy
                      ? _T.blue50
                      : _sBg(widget.printer!.status),
                ),
                const SizedBox(width: 12),
              ],

              // Delete (edit only)
              if (_isEditing)
                Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(_T.r),
                  child: InkWell(
                    onTap:        _confirmDelete,
                    borderRadius: BorderRadius.circular(_T.r),
                    child: Container(
                      width: 34, height: 34,
                      decoration: BoxDecoration(
                        color:        _T.red50,
                        borderRadius: BorderRadius.circular(_T.r),
                        border: Border.all(
                            color: _T.red.withOpacity(0.25)),
                      ),
                      child: const Icon(Icons.delete_outline_rounded,
                          size: 17, color: _T.red),
                    ),
                  ),
                ),
            ]),
          ),

          // ── Scrollable form ────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 28, 28, 40),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // Page heading
                    Text(
                      _isEditing ? 'Printer Details' : 'New Printer',
                      style: const TextStyle(
                        fontSize:   22,
                        fontWeight: FontWeight.w800,
                        color:      _T.ink,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isEditing
                          ? 'Update status or review printer information.'
                          : 'Fill in the printer details below. Required fields are marked *.',
                      style: const TextStyle(
                          fontSize: 13, color: _T.slate400,
                          fontWeight: FontWeight.w400),
                    ),
                    const SizedBox(height: 24),

                    // ── Section 1: Printer Details ─────────────────────
                    _SectionCard(
                      icon:      Icons.print_outlined,
                      iconColor: _T.blue,
                      iconBg:    _T.blue50,
                      title:     'Printer Details',
                      subtitle:  'Model name, nickname and location',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SmooField(
                            controller: _nameCtrl,
                            label:      'Printer Name',
                            hint:       'e.g. Epson SureColor P8000',
                            icon:       Icons.print_outlined,
                            required:   true,
                            readOnly:   _isEditing,
                            error: _submitted && !_nameOk
                                ? 'Printer name is required'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          _SmooField(
                            controller: _nickCtrl,
                            label:      'Nickname',
                            hint:       'e.g. Large Format A',
                            icon:       Icons.label_outline_rounded,
                            required:   true,
                            readOnly:   _isEditing,
                            error: _submitted && !_nickOk
                                ? 'Nickname is required'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          _SmooField(
                            controller: _locCtrl,
                            label:      'Location',
                            hint:       'e.g. Section A',
                            icon:       Icons.location_on_outlined,
                            required:   false,
                            readOnly:   _isEditing,
                          ),
                          // Read-only stats in edit mode
                          if (_isEditing) ...[
                            const SizedBox(height: 16),
                            Row(children: [
                              Expanded(
                                child: _StatCell(
                                  label: 'Jobs Completed',
                                  value: widget.printer!.totalJobsCompleted
                                      .toString(),
                                  icon:  Icons.check_circle_outline_rounded,
                                  color: _T.green,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _StatCell(
                                  label: 'Current Task',
                                  value: widget.printer!.currentJobId
                                          ?.toString() ?? '—',
                                  icon:  Icons.assignment_outlined,
                                  color: widget.printer!.isBusy
                                      ? _T.blue
                                      : _T.slate400,
                                ),
                              ),
                            ]),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Section 2: Operational Status ──────────────────
                    _SectionCard(
                      icon:      _sIcon(_status),
                      iconColor: _sColor(_status),
                      iconBg:    _sBg(_status),
                      title:     'Operational Status',
                      subtitle:  'Set the current state of this printer',
                      child: Column(children: [
                        _StatusOptionTile(
                          status:  PrinterStatus.active,
                          current: _status,
                          label:   'Active',
                          sub:     'Ready to receive print jobs',
                          onTap: () => setState(
                              () => _status = PrinterStatus.active),
                        ),
                        const SizedBox(height: 10),
                        _StatusOptionTile(
                          status:  PrinterStatus.maintenance,
                          current: _status,
                          label:   'Maintenance',
                          sub:     'Under service — not accepting jobs',
                          onTap: () => setState(
                              () => _status = PrinterStatus.maintenance),
                        ),
                        const SizedBox(height: 10),
                        _StatusOptionTile(
                          status:  PrinterStatus.offline,
                          current: _status,
                          label:   'Offline',
                          sub:     'Powered off or unreachable',
                          onTap: () => setState(
                              () => _status = PrinterStatus.offline),
                        ),
                      ]),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Action bar — same pattern as create_task_screen.dart ───────
          Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            decoration: const BoxDecoration(
              color:  _T.white,
              border: Border(top: BorderSide(color: _T.slate200)),
            ),
            child: Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _saving ? null : widget.onClose,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _T.slate500,
                    side: const BorderSide(color: _T.slate200),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(_T.r)),
                  ),
                  child: const Text('Cancel',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: _saving ? null : _savePrinter,
                  style: FilledButton.styleFrom(
                    backgroundColor:         _T.blue,
                    disabledBackgroundColor: _T.slate200,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(_T.r)),
                  ),
                  icon: _saving
                      ? const SizedBox(
                          width: 15, height: 15,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.white))
                      : Icon(
                          _isEditing
                              ? Icons.check_rounded
                              : Icons.add_rounded,
                          size: 17),
                  label: Text(
                    _saving
                        ? (_isEditing ? 'Saving…' : 'Adding…')
                        : (_isEditing ? 'Save Changes' : 'Add Printer'),
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SECTION CARD — verbatim from create_task_screen.dart
// rXl radius, 0.03 shadow, icon-header (34×34), slate100 divider, padded body
// ─────────────────────────────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final IconData icon;
  final Color    iconColor, iconBg;
  final String   title, subtitle;
  final Widget   child;

  const _SectionCard({
    required this.icon,      required this.iconColor, required this.iconBg,
    required this.title,     required this.subtitle,  required this.child,
  });

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: _T.white,
      borderRadius: BorderRadius.circular(_T.rXl),
      border: Border.all(color: _T.slate200),
      boxShadow: [
        BoxShadow(
          color:      Colors.black.withOpacity(0.03),
          blurRadius: 14,
          offset:     const Offset(0, 3),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
          child: Row(children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                color:        iconBg,
                borderRadius: BorderRadius.circular(9),
                border:       Border.all(color: iconColor.withOpacity(0.2)),
              ),
              child: Icon(icon, size: 16, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                        fontSize:   14,
                        fontWeight: FontWeight.w700,
                        color:      _T.ink,
                        letterSpacing: -0.2,
                      )),
                  Text(subtitle,
                      style: const TextStyle(
                        fontSize:   11.5,
                        color:      _T.slate400,
                        fontWeight: FontWeight.w400,
                      )),
                ],
              ),
            ),
          ]),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child:   Divider(height: 1, color: _T.slate100),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child:   child,
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// SMOO FIELD — focus-animated border, verbatim from create_task_screen.dart
// Adds readOnly mode that renders a static info row (no disabled TextField).
// ─────────────────────────────────────────────────────────────────────────────
class _SmooField extends StatefulWidget {
  final TextEditingController controller;
  final String                label, hint;
  final IconData              icon;
  final bool                  required;
  final bool                  readOnly;
  final String?               error;

  const _SmooField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.required = false,
    this.readOnly = false,
    this.error,
  });

  @override
  State<_SmooField> createState() => _SmooFieldState();
}

class _SmooFieldState extends State<_SmooField> {
  final _focus   = FocusNode();
  bool  _focused = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() => _focused = _focus.hasFocus));
  }

  @override
  void dispose() { _focus.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    // Read-only → static display row (edit mode)
    if (widget.readOnly) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldLabel(widget.label),
          const SizedBox(height: 7),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color:        _T.slate50,
              borderRadius: BorderRadius.circular(_T.r),
              border:       Border.all(color: _T.slate200),
            ),
            child: Row(children: [
              Icon(widget.icon, size: 16, color: _T.slate400),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.controller.text.isNotEmpty
                      ? widget.controller.text
                      : widget.hint,
                  style: TextStyle(
                    fontSize:   13,
                    fontWeight: FontWeight.w500,
                    color: widget.controller.text.isNotEmpty
                        ? _T.ink3
                        : _T.slate300,
                  ),
                ),
              ),
            ]),
          ),
        ],
      );
    }

    final hasError = widget.error != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.required)
          _FieldLabel.required(widget.label)
        else
          _FieldLabel(widget.label, optional: true),
        const SizedBox(height: 7),
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: _focused ? _T.white : _T.slate50,
            borderRadius: BorderRadius.circular(_T.r),
            border: Border.all(
              color: hasError
                  ? _T.red
                  : (_focused ? _T.blue : _T.slate200),
              width: (_focused || hasError) ? 1.5 : 1,
            ),
          ),
          child: TextField(
            controller: widget.controller,
            focusNode:  _focus,
            style: const TextStyle(
                fontSize: 13, color: _T.ink, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              hintText:  widget.hint,
              hintStyle: const TextStyle(fontSize: 13, color: _T.slate300),
              prefixIcon: Icon(widget.icon, size: 16, color: _T.slate400),
              border:         InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                  vertical: 13, horizontal: 12),
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Row(children: [
              const Icon(Icons.error_outline_rounded,
                  size: 11, color: _T.red),
              const SizedBox(width: 4),
              Text(widget.error!,
                  style: const TextStyle(
                      fontSize: 11, color: _T.red,
                      fontWeight: FontWeight.w500)),
            ]),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STATUS OPTION TILE — same anatomy as _PriorityPicker chips in create_task
// ─────────────────────────────────────────────────────────────────────────────
class _StatusOptionTile extends StatelessWidget {
  final PrinterStatus status, current;
  final String        label, sub;
  final VoidCallback  onTap;

  const _StatusOptionTile({
    required this.status, required this.current,
    required this.label,  required this.sub,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final active = status == current;
    final color  = _sColor(status);
    final bg     = _sBg(status);
    final icon   = _sIcon(status);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: active ? bg : _T.white,
          borderRadius: BorderRadius.circular(_T.rLg),
          border: Border.all(
            color: active ? color.withOpacity(0.5) : _T.slate200,
            width: active ? 1.5 : 1,
          ),
          boxShadow: active
              ? [BoxShadow(
                  color:      color.withOpacity(0.10),
                  blurRadius: 10,
                  offset:     const Offset(0, 3))]
              : null,
        ),
        child: Row(children: [
          // Coloured icon badge
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: active
                  ? color.withOpacity(0.15)
                  : _T.slate100,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 16,
                color: active ? color : _T.slate400),
          ),
          const SizedBox(width: 12),

          // Label + sub
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                      fontSize:   13,
                      fontWeight: FontWeight.w700,
                      color:      active ? color : _T.ink3,
                    )),
                const SizedBox(height: 2),
                Text(sub,
                    style: const TextStyle(
                        fontSize: 11.5, color: _T.slate400)),
              ],
            ),
          ),

          // Check icon
          AnimatedOpacity(
            opacity:  active ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 150),
            child: Icon(Icons.check_circle_rounded,
                size: 20, color: color),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STAT CELL — compact read-only metric box (edit mode only)
// ─────────────────────────────────────────────────────────────────────────────
class _StatCell extends StatelessWidget {
  final String   label, value;
  final IconData icon;
  final Color    color;
  const _StatCell({
    required this.label, required this.value,
    required this.icon,  required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color:        _T.slate50,
      borderRadius: BorderRadius.circular(_T.r),
      border:       Border.all(color: _T.slate200),
    ),
    child: Row(children: [
      Container(
        width: 30, height: 30,
        decoration: BoxDecoration(
          color:        color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Icon(icon, size: 14, color: color),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: const TextStyle(
                fontSize:      10,
                fontWeight:    FontWeight.w600,
                color:         _T.slate400,
                letterSpacing: 0.3,
              )),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(
                fontSize:   14,
                fontWeight: FontWeight.w700,
                color:      _T.ink3,
              )),
        ]),
      ),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// DELETE DIALOG — desktop centered dialog (not bottom sheet)
// ─────────────────────────────────────────────────────────────────────────────
class _DeleteDialog extends StatelessWidget {
  final String       printerName;
  final VoidCallback onConfirm;
  const _DeleteDialog({
    required this.printerName, required this.onConfirm});

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: Colors.transparent,
    child: Container(
      width: 400,
      decoration: BoxDecoration(
        color:        _T.white,
        borderRadius: BorderRadius.circular(_T.rXl),
        border:       Border.all(color: _T.slate200),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withOpacity(0.10),
            blurRadius: 24,
            offset:     const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 16, 0),
            child: Row(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color:  _T.red50,
                  shape:  BoxShape.circle,
                  border: Border.all(color: _T.red.withOpacity(0.2)),
                ),
                child: const Icon(Icons.delete_outline_rounded,
                    size: 18, color: _T.red),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Delete Printer',
                        style: TextStyle(
                          fontSize:   16,
                          fontWeight: FontWeight.w700,
                          color:      _T.ink,
                        )),
                    Text('This action cannot be undone',
                        style: TextStyle(
                            fontSize: 12, color: _T.slate400)),
                  ],
                ),
              ),
              Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(_T.r),
                child: InkWell(
                  onTap:        () => Navigator.of(context).pop(),
                  borderRadius: BorderRadius.circular(_T.r),
                  child: Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      border:       Border.all(color: _T.slate200),
                      borderRadius: BorderRadius.circular(_T.r),
                    ),
                    child: const Icon(Icons.close_rounded,
                        size: 15, color: _T.slate400),
                  ),
                ),
              ),
            ]),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child:   Divider(height: 1, color: _T.slate100),
          ),

          // Printer name chip
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              width:   double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color:        _T.slate50,
                borderRadius: BorderRadius.circular(_T.r),
                border:       Border.all(color: _T.slate200),
              ),
              child: Row(children: [
                const Icon(Icons.print_outlined,
                    size: 15, color: _T.slate400),
                const SizedBox(width: 10),
                Text(printerName,
                    style: const TextStyle(
                      fontSize:   13,
                      fontWeight: FontWeight.w600,
                      color:      _T.ink3,
                    )),
              ]),
            ),
          ),

          // Buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _T.slate500,
                    side: const BorderSide(color: _T.slate200),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(_T.r)),
                  ),
                  child: const Text('Cancel',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: onConfirm,
                  style: FilledButton.styleFrom(
                    backgroundColor: _T.red,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(_T.r)),
                  ),
                  icon:  const Icon(Icons.delete_outline_rounded,
                      size: 17),
                  label: const Text('Delete Printer',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700)),
                ),
              ),
            ]),
          ),
        ],
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED SMALL COMPONENTS
// ─────────────────────────────────────────────────────────────────────────────

// Status pill — dot + label
class _StatusPill extends StatelessWidget {
  final String label;
  final Color  color, bg;
  const _StatusPill({required this.label, required this.color, required this.bg});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
        color: bg, borderRadius: BorderRadius.circular(99)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
          width: 5, height: 5,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 5),
      Text(label,
          style: TextStyle(
            fontSize:   11,
            fontWeight: FontWeight.w700,
            color:      color,
          )),
    ]),
  );
}

// Mini count pill used in the list subheader
class _MiniPill extends StatelessWidget {
  final String label;
  final Color  color, bg;
  const _MiniPill({required this.label, required this.color, required this.bg});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
        color: bg, borderRadius: BorderRadius.circular(99)),
    child: Text(label,
        style: TextStyle(
          fontSize:   10.5,
          fontWeight: FontWeight.w700,
          color:      color,
        )),
  );
}

// Search bar
class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String>  onChanged;
  const _SearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) => Container(
    height: 36,
    decoration: BoxDecoration(
      color:        _T.slate50,
      borderRadius: BorderRadius.circular(_T.r),
      border:       Border.all(color: _T.slate200),
    ),
    child: TextField(
      controller: controller,
      onChanged:  onChanged,
      style: const TextStyle(fontSize: 13, color: _T.ink),
      decoration: InputDecoration(
        hintText:  'Search printers…',
        hintStyle: const TextStyle(fontSize: 13, color: _T.slate300),
        prefixIcon: const Icon(Icons.search_rounded,
            size: 15, color: _T.slate400),
        suffixIcon: controller.text.isNotEmpty
            ? GestureDetector(
                onTap: () { controller.clear(); onChanged(''); },
                child: const Icon(Icons.close_rounded,
                    size: 14, color: _T.slate400))
            : null,
        border:         InputBorder.none,
        isDense:        true,
        contentPadding: const EdgeInsets.symmetric(vertical: 9),
      ),
    ),
  );
}

// Empty list state
class _EmptyListState extends StatelessWidget {
  final bool hasSearch;
  const _EmptyListState({required this.hasSearch});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(
        hasSearch
            ? Icons.search_off_rounded
            : Icons.print_disabled_outlined,
        size:  28,
        color: _T.slate300,
      ),
      const SizedBox(height: 10),
      Text(
        hasSearch ? 'No results' : 'No printers yet',
        style: const TextStyle(
          fontSize:   13,
          fontWeight: FontWeight.w600,
          color:      _T.slate400,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        hasSearch
            ? 'Try a different search'
            : 'Click Add Printer to get started',
        style: const TextStyle(fontSize: 12, color: _T.slate300),
      ),
    ]),
  );
}

// Field label — verbatim from create_task_screen.dart
class _FieldLabel extends StatelessWidget {
  final String  text;
  final bool    optional;
  final bool    isRequired;
  final String? optionalNote;

  const _FieldLabel(this.text, {this.optional = false, this.optionalNote})
      : isRequired = false;

  const _FieldLabel.required(this.text)
      : optional     = false,
        isRequired   = true,
        optionalNote = null;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Text(text,
          style: const TextStyle(
            fontSize:   12,
            fontWeight: FontWeight.w600,
            color:      _T.ink3,
          )),
      if (isRequired) ...[
        const SizedBox(width: 3),
        const Text('*',
            style: TextStyle(
              color:      _T.red,
              fontSize:   13,
              fontWeight: FontWeight.w700,
            )),
      ],
      if (optional) ...[
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          decoration: BoxDecoration(
            color:        _T.slate100,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            optionalNote ?? 'Optional',
            style: const TextStyle(
              fontSize:      9.5,
              fontWeight:    FontWeight.w600,
              color:         _T.slate400,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ],
    ],
  );
}
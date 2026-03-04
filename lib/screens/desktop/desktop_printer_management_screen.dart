// ─────────────────────────────────────────────────────────────────────────────
// MANAGE PRINTERS SCREEN  —  Desktop master-detail layout
// ─────────────────────────────────────────────────────────────────────────────
// Layout:
//   TopBar (52px) — title + "Add Printer" CTA
//   Body:
//     Left  (380px fixed) — searchable printer list
//     Right (flexible)    — detail / create form panel
//                           idle state when nothing selected
//
// Data logic lifted verbatim from add_printer_screen.dart (mobile).
// All _savePrinter / _confirmDelete bodies preserved.
// Only the presentation layer is new.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/core/models/printer.dart';
import 'package:smooflow/providers/printer_provider.dart';

// ── Design tokens — identical to the rest of the desktop system ──────────────
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
  static const topbarH   = 52.0;
  static const listW     = 380.0;
  static const r         = 8.0;
  static const rLg       = 12.0;
}

// ── Status helpers ────────────────────────────────────────────────────────────
Color _sColor(PrinterStatus s) => switch (s) {
  PrinterStatus.active      => _T.green,
  PrinterStatus.maintenance => _T.amber,
  PrinterStatus.offline     => _T.slate400,
  _                         => _T.slate400,
};
Color _sBg(PrinterStatus s) => switch (s) {
  PrinterStatus.active      => _T.green50,
  PrinterStatus.maintenance => _T.amber50,
  PrinterStatus.offline     => _T.slate100,
  _                         => _T.slate100,
};
IconData _sIcon(PrinterStatus s) => switch (s) {
  PrinterStatus.active      => Icons.check_circle_outline_rounded,
  PrinterStatus.maintenance => Icons.build_outlined,
  PrinterStatus.offline     => Icons.power_off_outlined,
  _                         => Icons.help_outline_rounded,
};
String _sLabel(PrinterStatus s) => switch (s) {
  PrinterStatus.active      => 'Active',
  PrinterStatus.maintenance => 'Maintenance',
  PrinterStatus.offline     => 'Offline',
  _                         => 'Unknown',
};

// ─────────────────────────────────────────────────────────────────────────────
// ROOT SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class DesktopPrinterManagementScreen extends ConsumerStatefulWidget {
  const DesktopPrinterManagementScreen({super.key});

  @override
  ConsumerState<DesktopPrinterManagementScreen> createState() =>
      _ManagePrintersScreenState();
}

class _ManagePrintersScreenState extends ConsumerState<DesktopPrinterManagementScreen> {
  Printer? _selected;       // null = "add new" form, set = edit form
  bool     _showAddForm = false;

  final _searchCtrl = TextEditingController();
  String get _q => _searchCtrl.text.trim().toLowerCase();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _selectPrinter(Printer p) =>
      setState(() { _selected = p; _showAddForm = false; });

  void _openAddForm() =>
      setState(() { _selected = null; _showAddForm = true; });

  void _closeDetail() =>
      setState(() { _selected = null; _showAddForm = false; });

  @override
  Widget build(BuildContext context) {
    final printerState = ref.watch(printerNotifierProvider);
    final all          = printerState.printers;
    final filtered     = _q.isEmpty
        ? all
        : all.where((p) =>
            p.name.toLowerCase().contains(_q) ||
            p.nickname.toLowerCase().contains(_q)).toList();

    final showDetail = _selected != null || _showAddForm;

    return Scaffold(
      backgroundColor: _T.slate50,
      body: Column(children: [
        _TopBar(onAdd: _openAddForm),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── LEFT: Printer list ───────────────────────────────────
              SizedBox(
                width: _T.listW,
                child: Container(
                  decoration: const BoxDecoration(
                    color: _T.white,
                    border: Border(right: BorderSide(color: _T.slate200)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [

                      // List header
                      Container(
                        height: _T.topbarH,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: const BoxDecoration(
                          border: Border(bottom: BorderSide(color: _T.slate200)),
                        ),
                        child: Row(children: [
                          Container(
                            width: 28, height: 28,
                            decoration: BoxDecoration(
                              color: _T.blue50,
                              borderRadius: BorderRadius.circular(7),
                              border: Border.all(color: _T.blue100),
                            ),
                            child: const Icon(Icons.print_rounded,
                                size: 13, color: _T.blue),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Printers',
                                  style: TextStyle(
                                    fontSize:   12.5,
                                    fontWeight: FontWeight.w700,
                                    color:      _T.ink,
                                  )),
                              Text('${all.length} total',
                                  style: const TextStyle(
                                      fontSize: 10.5, color: _T.slate400)),
                            ],
                          ),
                          const Spacer(),
                          // Status breakdown pills
                          _StatusCountPill(
                            count: all.where((p) => p.status == PrinterStatus.active && !p.isBusy).length,
                            color: _T.green,
                            bg:    _T.green50,
                            label: 'Free',
                          ),
                          const SizedBox(width: 5),
                          _StatusCountPill(
                            count: all.where((p) => p.isBusy).length,
                            color: _T.blue,
                            bg:    _T.blue50,
                            label: 'Busy',
                          ),
                        ]),
                      ),

                      // Search bar
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                        child: Container(
                          height: 30,
                          decoration: BoxDecoration(
                            color:        _T.slate50,
                            borderRadius: BorderRadius.circular(_T.r),
                            border:       Border.all(color: _T.slate200),
                          ),
                          child: TextField(
                            controller: _searchCtrl,
                            onChanged:  (_) => setState(() {}),
                            style: const TextStyle(
                                fontSize: 12, color: _T.ink),
                            decoration: InputDecoration(
                              hintText:  'Search printers…',
                              hintStyle: const TextStyle(
                                  fontSize: 12, color: _T.slate300),
                              prefixIcon: const Icon(
                                  Icons.search_rounded,
                                  size: 13, color: _T.slate400),
                              suffixIcon: _searchCtrl.text.isNotEmpty
                                  ? GestureDetector(
                                      onTap: () => setState(
                                          () => _searchCtrl.clear()),
                                      child: const Icon(Icons.close_rounded,
                                          size: 12, color: _T.slate400))
                                  : null,
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 7),
                            ),
                          ),
                        ),
                      ),

                      // Printer rows
                      Expanded(
                        child: filtered.isEmpty
                            ? _EmptyListState(
                                hasSearch: _q.isNotEmpty,
                                onAdd:     _openAddForm)
                            : ListView.separated(
                                padding: const EdgeInsets.fromLTRB(
                                    12, 4, 12, 12),
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

              // ── RIGHT: Detail / Add form ─────────────────────────────
              Expanded(
                child: showDetail
                    ? _DetailPanel(
                        key:       ValueKey(_selected?.id ?? 'new'),
                        printer:   _selected,
                        onClose:   _closeDetail,
                        onSaved:   _closeDetail,
                        onDeleted: _closeDetail,
                      )
                    : const _IdlePane(),
              ),

            ],
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TOP BAR
// ─────────────────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final VoidCallback onAdd;
  const _TopBar({required this.onAdd});

  @override
  Widget build(BuildContext context) => Container(
    height: _T.topbarH,
    decoration: const BoxDecoration(
      color: _T.white,
      border: Border(bottom: BorderSide(color: _T.slate200)),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Row(children: [
      Container(
        width: 26, height: 26,
        decoration: BoxDecoration(
          color:        _T.blue50,
          borderRadius: BorderRadius.circular(6),
          border:       Border.all(color: _T.blue100),
        ),
        child: const Icon(Icons.print_rounded, size: 13, color: _T.blue),
      ),
      const SizedBox(width: 10),
      const Text('Manage Printers',
          style: TextStyle(
            fontSize:   13.5,
            fontWeight: FontWeight.w700,
            color:      _T.ink,
            letterSpacing: -0.2,
          )),
      const Spacer(),
      _AddButton(onTap: onAdd),
    ]),
  );
}

class _AddButton extends StatefulWidget {
  final VoidCallback onTap;
  const _AddButton({required this.onTap});
  @override
  State<_AddButton> createState() => _AddButtonState();
}

class _AddButtonState extends State<_AddButton> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor:  SystemMouseCursors.click,
    onEnter: (_) => setState(() => _hovered = true),
    onExit:  (_) => setState(() => _hovered = false),
    child: GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 130),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color:        _hovered ? _T.blueHover : _T.blue,
          borderRadius: BorderRadius.circular(_T.r),
          boxShadow: [
            BoxShadow(color: _T.blue.withOpacity(0.25),
                blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: const Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.add_rounded, size: 14, color: Colors.white),
          SizedBox(width: 5),
          Text('Add Printer',
              style: TextStyle(
                fontSize:   12.5,
                fontWeight: FontWeight.w700,
                color:      Colors.white,
              )),
        ]),
      ),
    ),
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
    final p = widget.printer;
    final selected = widget.isSelected;

    // Determine display status
    final Color dotColor;
    final Color dotBg;
    final String statusText;
    if (p.isBusy) {
      dotColor   = _T.blue;
      dotBg      = _T.blue50;
      statusText = 'Busy';
    } else {
      dotColor   = _sColor(p.status);
      dotBg      = _sBg(p.status);
      statusText = _sLabel(p.status);
    }

    return MouseRegion(
      cursor:  SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? _T.blue50
                : _hovered ? _T.slate50 : Colors.transparent,
            borderRadius: BorderRadius.circular(_T.r),
            border: Border.all(
              color: selected
                  ? _T.blue.withOpacity(0.35)
                  : _hovered ? _T.slate200 : _T.slate200,
              width: selected ? 1.5 : 1.0,
            ),
          ),
          child: Row(children: [
            // Printer icon
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                color: selected
                    ? _T.blue.withOpacity(0.10)
                    : _T.slate100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.print_outlined,
                  size:  16,
                  color: selected ? _T.blue : _T.slate500),
            ),
            const SizedBox(width: 10),

            // Name + nickname
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.name,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize:   12.5,
                        fontWeight: FontWeight.w600,
                        color:      selected ? _T.blue : _T.ink,
                      )),
                  Text(p.nickname,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 11, color: _T.slate400)),
                ],
              ),
            ),

            // Status pill
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                  color: dotBg,
                  borderRadius: BorderRadius.circular(99)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 5, height: 5,
                  decoration: BoxDecoration(
                      color: dotColor, shape: BoxShape.circle),
                ),
                const SizedBox(width: 4),
                Text(statusText,
                    style: TextStyle(
                      fontSize:   10,
                      fontWeight: FontWeight.w700,
                      color:      dotColor,
                    )),
              ]),
            ),

            if (selected) ...[
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right_rounded,
                  size: 14, color: _T.blue),
            ],
          ]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// IDLE PANE  — shown when nothing is selected
// ─────────────────────────────────────────────────────────────────────────────
class _IdlePane extends StatelessWidget {
  const _IdlePane();

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 52, height: 52,
          decoration: BoxDecoration(
            color:        _T.slate100,
            borderRadius: BorderRadius.circular(14),
            border:       Border.all(color: _T.slate200),
          ),
          child: const Icon(Icons.print_outlined,
              size: 24, color: _T.slate400),
        ),
        const SizedBox(height: 14),
        const Text('Select a printer to view details',
            style: TextStyle(
              fontSize:   13,
              fontWeight: FontWeight.w600,
              color:      _T.slate400,
            )),
        const SizedBox(height: 4),
        const Text('or add a new one using the button above',
            style: TextStyle(fontSize: 11.5, color: _T.slate300)),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// DETAIL PANEL  — create or edit form
// ─────────────────────────────────────────────────────────────────────────────
class _DetailPanel extends ConsumerStatefulWidget {
  final Printer?     printer;   // null = create mode
  final VoidCallback onClose;
  final VoidCallback onSaved;
  final VoidCallback onDeleted;

  const _DetailPanel({
    super.key,
    required this.printer,
    required this.onClose,
    required this.onSaved,
    required this.onDeleted,
  });

  @override
  ConsumerState<_DetailPanel> createState() => _DetailPanelState();
}

class _DetailPanelState extends ConsumerState<_DetailPanel> {
  final _formKey      = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _nickCtrl;
  late TextEditingController _locCtrl;

  PrinterStatus _status = PrinterStatus.active;
  bool _saving          = false;
  bool _deleting        = false;

  bool get _isEditing => widget.printer != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.printer?.name     ?? '');
    _nickCtrl = TextEditingController(text: widget.printer?.nickname ?? '');
    _locCtrl  = TextEditingController(text: widget.printer?.location ?? '');
    if (widget.printer != null) _status = widget.printer!.status;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _nickCtrl.dispose();
    _locCtrl.dispose();
    super.dispose();
  }

  // ── Data logic — verbatim from add_printer_screen.dart ────────────────────

  void _savePrinter() async {
    if (widget.printer != null) {
      setState(() => _saving = true);
      try {
        await ref
            .read(printerNotifierProvider.notifier)
            .updatePrinter(
          widget.printer!.id,
          name:     _nameCtrl.text,
          nickname: _nickCtrl.text,
          location: _locCtrl.text,
          status:   _status,
        );
      } catch (e) {
        _snack('Failed to update printer. Please try again.',
            isError: true);
        setState(() => _saving = false);
        return;
      }
      _snack('Printer updated successfully', isError: false);
      setState(() => _saving = false);
      widget.onSaved();
      return;
    }

    if (_formKey.currentState!.validate()) {
      setState(() => _saving = true);
      await ref
          .read(printerNotifierProvider.notifier)
          .createPrinter(
        name:     _nameCtrl.text,
        nickname: _nickCtrl.text,
        location: _locCtrl.text,
      );
      _snack('Printer added', isError: false);
      setState(() => _saving = false);
      widget.onSaved();
    }
  }

  void _confirmDelete() {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (_) => _DeleteDialog(
        printerName: widget.printer?.name ?? 'this printer',
        onConfirm: () async {
          Navigator.of(context).pop();
          setState(() => _deleting = true);
          // TODO: wire delete call
          // await ref.read(printerNotifierProvider.notifier).deletePrinter(widget.printer!.id);
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
        Expanded(
          child: Text(msg,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w500)),
        ),
      ]),
      backgroundColor: _T.ink,
      behavior:        SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_T.r)),
      margin:   const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
    ));
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _T.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Panel top bar ──────────────────────────────────────────────
          Container(
            height: _T.topbarH,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: _T.slate200)),
            ),
            child: Row(children: [
              // Close
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: widget.onClose,
                  child: Container(
                    width: 26, height: 26,
                    decoration: BoxDecoration(
                      border:       Border.all(color: _T.slate200),
                      borderRadius: BorderRadius.circular(_T.r),
                    ),
                    child: const Icon(Icons.close_rounded,
                        size: 13, color: _T.slate400),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Title
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isEditing
                          ? widget.printer!.name
                          : 'New Printer',
                      style: const TextStyle(
                        fontSize:   13,
                        fontWeight: FontWeight.w700,
                        color:      _T.ink,
                      ),
                    ),
                    Text(
                      _isEditing
                          ? 'Edit printer details'
                          : 'Fill in the details below',
                      style: const TextStyle(
                          fontSize: 10.5, color: _T.slate400),
                    ),
                  ],
                ),
              ),

              // Live status badge (edit mode only)
              if (_isEditing) ...[
                _StatusBadge(status: widget.printer!.status,
                    isBusy: widget.printer!.isBusy),
                const SizedBox(width: 10),
              ],

              // Delete (edit mode only)
              if (_isEditing)
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: _confirmDelete,
                    child: Container(
                      width: 26, height: 26,
                      decoration: BoxDecoration(
                        color: _T.red50,
                        borderRadius: BorderRadius.circular(_T.r),
                        border: Border.all(
                            color: _T.red.withOpacity(0.2)),
                      ),
                      child: const Icon(Icons.delete_outline_rounded,
                          size: 13, color: _T.red),
                    ),
                  ),
                ),
            ]),
          ),

          // ── Scrollable form body ───────────────────────────────────────
          Expanded(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // ── PRINTER INFO ───────────────────────────────────
                    _FormSection(
                      icon:      Icons.print_outlined,
                      iconColor: _T.blue,
                      iconBg:    _T.blue50,
                      title:     'Printer Details',
                      subtitle:  'Model name, nickname & location',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _DesktopField(
                            controller: _nameCtrl,
                            label:      'Printer Name',
                            hint:       'e.g. Epson SureColor P8000',
                            icon:       Icons.print_outlined,
                            readOnly:   _isEditing,
                            validator: (v) => (v == null || v.isEmpty)
                                ? 'Required'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          _DesktopField(
                            controller: _nickCtrl,
                            label:      'Nickname',
                            hint:       'e.g. Large Format A',
                            icon:       Icons.label_outline_rounded,
                            readOnly:   _isEditing,
                            validator: (v) => (v == null || v.isEmpty)
                                ? 'Required'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          _DesktopField(
                            controller: _locCtrl,
                            label:      'Location',
                            hint:       'e.g. Section A',
                            icon:       Icons.location_on_outlined,
                            readOnly:   _isEditing,
                          ),
                          // Read-only stats (edit mode)
                          if (_isEditing) ...[
                            const SizedBox(height: 12),
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
                              const SizedBox(width: 10),
                              Expanded(
                                child: _StatCell(
                                  label: 'Current Task',
                                  value: widget.printer!.currentJobId
                                          ?.toString() ??
                                      'None',
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

                    // ── STATUS ─────────────────────────────────────────
                    _FormSection(
                      icon:      _sIcon(_status),
                      iconColor: _sColor(_status),
                      iconBg:    _sBg(_status),
                      title:     'Operational Status',
                      subtitle:  'Set the current state of this printer',
                      child: Column(
                        children: [
                          _StatusOptionRow(
                            status:   PrinterStatus.active,
                            current:  _status,
                            label:    'Active',
                            sub:      'Ready to receive print jobs',
                            onTap: () => setState(
                                () => _status = PrinterStatus.active),
                          ),
                          const SizedBox(height: 8),
                          _StatusOptionRow(
                            status:   PrinterStatus.maintenance,
                            current:  _status,
                            label:    'Maintenance',
                            sub:      'Under service — not accepting jobs',
                            onTap: () => setState(
                                () => _status = PrinterStatus.maintenance),
                          ),
                          const SizedBox(height: 8),
                          _StatusOptionRow(
                            status:   PrinterStatus.offline,
                            current:  _status,
                            label:    'Offline',
                            sub:      'Powered off or unreachable',
                            onTap: () => setState(
                                () => _status = PrinterStatus.offline),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Footer action bar ──────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              color: _T.slate50,
              border: Border(top: BorderSide(color: _T.slate200)),
            ),
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              // Cancel
              Expanded(
                child: _GhostBtn(
                  label: 'Cancel',
                  onTap: _saving ? null : widget.onClose,
                ),
              ),
              const SizedBox(width: 10),
              // Save / Create
              Expanded(
                flex: 2,
                child: _PrimaryBtn(
                  label:   _saving
                      ? (_isEditing ? 'Saving…' : 'Adding…')
                      : (_isEditing ? 'Save Changes' : 'Add Printer'),
                  icon:    _saving
                      ? null
                      : (_isEditing
                          ? Icons.check_rounded
                          : Icons.add_rounded),
                  loading: _saving,
                  onTap:   _saving ? null : _savePrinter,
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
// FORM SECTION CARD
// ─────────────────────────────────────────────────────────────────────────────
class _FormSection extends StatelessWidget {
  final IconData icon;
  final Color    iconColor, iconBg;
  final String   title, subtitle;
  final Widget   child;

  const _FormSection({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color:        _T.white,
      borderRadius: BorderRadius.circular(_T.rLg),
      border:       Border.all(color: _T.slate200),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
          child: Row(children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color:        iconBg,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(color: iconColor.withOpacity(0.2)),
              ),
              child: Icon(icon, size: 13, color: iconColor),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                      fontSize:   12.5,
                      fontWeight: FontWeight.w700,
                      color:      _T.ink,
                    )),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 10.5, color: _T.slate400)),
              ],
            ),
          ]),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child:   Divider(height: 1, color: _T.slate100),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          child:   child,
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// DESKTOP TEXT FIELD
// ─────────────────────────────────────────────────────────────────────────────
class _DesktopField extends StatefulWidget {
  final TextEditingController?     controller;
  final String                     label, hint;
  final IconData                   icon;
  final bool                       readOnly;
  final String? Function(String?)? validator;

  const _DesktopField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.readOnly  = false,
    this.validator,
  });
  @override
  State<_DesktopField> createState() => _DesktopFieldState();
}

class _DesktopFieldState extends State<_DesktopField> {
  final _focus   = FocusNode();
  bool  _focused = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(
        () => setState(() => _focused = _focus.hasFocus));
  }
  @override
  void dispose() { _focus.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    // Read-only row
    if (widget.readOnly) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldLabel(widget.label),
          const SizedBox(height: 5),
          Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color:        _T.slate50,
              borderRadius: BorderRadius.circular(_T.r),
              border:       Border.all(color: _T.slate200),
            ),
            child: Row(children: [
              Icon(widget.icon, size: 13, color: _T.slate400),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.controller?.text.isNotEmpty == true
                      ? widget.controller!.text
                      : widget.hint,
                  style: const TextStyle(
                    fontSize:   12.5,
                    fontWeight: FontWeight.w500,
                    color:      _T.ink3,
                  ),
                ),
              ),
            ]),
          ),
        ],
      );
    }

    // Editable field
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(widget.label),
        const SizedBox(height: 5),
        AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          height: 36,
          decoration: BoxDecoration(
            color: _focused ? _T.white : _T.slate50,
            borderRadius: BorderRadius.circular(_T.r),
            border: Border.all(
              color: _focused ? _T.blue : _T.slate200,
              width: _focused ? 1.5 : 1,
            ),
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode:  _focus,
            validator:  widget.validator,
            style: const TextStyle(
                fontSize: 12.5, color: _T.ink, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              hintText:  widget.hint,
              hintStyle: const TextStyle(
                  fontSize: 12.5, color: _T.slate300),
              prefixIcon: Icon(widget.icon, size: 13, color: _T.slate400),
              border:         InputBorder.none,
              isDense:        true,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              errorStyle:     const TextStyle(height: 0),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STATUS OPTION ROW
// ─────────────────────────────────────────────────────────────────────────────
class _StatusOptionRow extends StatefulWidget {
  final PrinterStatus status, current;
  final String        label, sub;
  final VoidCallback  onTap;
  const _StatusOptionRow({
    required this.status,
    required this.current,
    required this.label,
    required this.sub,
    required this.onTap,
  });
  @override
  State<_StatusOptionRow> createState() => _StatusOptionRowState();
}

class _StatusOptionRowState extends State<_StatusOptionRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final selected = widget.status == widget.current;
    final color    = _sColor(widget.status);
    final bg       = _sBg(widget.status);
    final icon     = _sIcon(widget.status);

    return MouseRegion(
      cursor:  SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? bg
                : _hovered ? _T.slate50 : Colors.transparent,
            borderRadius: BorderRadius.circular(_T.r),
            border: Border.all(
              color: selected
                  ? color.withOpacity(0.4)
                  : _hovered ? _T.slate200 : _T.slate200,
              width: selected ? 1.5 : 1.0,
            ),
          ),
          child: Row(children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: selected
                    ? color.withOpacity(0.13)
                    : _T.slate100,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Icon(icon, size: 13,
                  color: selected ? color : _T.slate400),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.label,
                      style: TextStyle(
                        fontSize:   12.5,
                        fontWeight: FontWeight.w600,
                        color:      selected ? color : _T.ink3,
                      )),
                  Text(widget.sub,
                      style: const TextStyle(
                          fontSize: 11, color: _T.slate400)),
                ],
              ),
            ),
            AnimatedOpacity(
              opacity:  selected ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 130),
              child: Icon(Icons.check_circle_rounded,
                  size: 14, color: color),
            ),
          ]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STAT CELL — compact read-only metric in a box
// ─────────────────────────────────────────────────────────────────────────────
class _StatCell extends StatelessWidget {
  final String   label, value;
  final IconData icon;
  final Color    color;
  const _StatCell({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color:        _T.slate50,
      borderRadius: BorderRadius.circular(_T.r),
      border:       Border.all(color: _T.slate200),
    ),
    child: Row(children: [
      Icon(icon, size: 13, color: color),
      const SizedBox(width: 8),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 10, color: _T.slate400)),
            Text(value,
                style: const TextStyle(
                  fontSize:   13,
                  fontWeight: FontWeight.w700,
                  color:      _T.ink3,
                )),
          ],
        ),
      ),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// STATUS BADGE  — compact live-status pill in the panel topbar
// ─────────────────────────────────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final PrinterStatus status;
  final bool          isBusy;
  const _StatusBadge({required this.status, required this.isBusy});

  @override
  Widget build(BuildContext context) {
    final Color c;
    final Color bg;
    final String label;
    if (isBusy) {
      c  = _T.blue; bg = _T.blue50; label = 'Busy';
    } else {
      c  = _sColor(status); bg = _sBg(status); label = _sLabel(status);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(99)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 5, height: 5,
          decoration: BoxDecoration(color: c, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
              fontSize:   10.5,
              fontWeight: FontWeight.w700,
              color:      c,
            )),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EMPTY LIST STATE
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyListState extends StatelessWidget {
  final bool         hasSearch;
  final VoidCallback onAdd;
  const _EmptyListState({required this.hasSearch, required this.onAdd});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasSearch
                ? Icons.search_off_rounded
                : Icons.print_disabled_outlined,
            size:  22,
            color: _T.slate300,
          ),
          const SizedBox(height: 8),
          Text(
            hasSearch ? 'No results' : 'No printers yet',
            style: const TextStyle(
              fontSize:   12.5,
              fontWeight: FontWeight.w600,
              color:      _T.slate400,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            hasSearch
                ? 'Try a different search'
                : 'Add your first printer',
            style: const TextStyle(
                fontSize: 11, color: _T.slate300),
          ),
        ],
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// STATUS COUNT PILL  — used in list header
// ─────────────────────────────────────────────────────────────────────────────
class _StatusCountPill extends StatelessWidget {
  final int    count;
  final Color  color, bg;
  final String label;
  const _StatusCountPill({
    required this.count,
    required this.color,
    required this.bg,
    required this.label,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
        color: bg, borderRadius: BorderRadius.circular(99)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 5, height: 5,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 4),
      Text('$count $label',
          style: TextStyle(
            fontSize:   10,
            fontWeight: FontWeight.w700,
            color:      color,
          )),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// DELETE CONFIRMATION DIALOG  (desktop: centered dialog, not a bottom sheet)
// ─────────────────────────────────────────────────────────────────────────────
class _DeleteDialog extends StatelessWidget {
  final String       printerName;
  final VoidCallback onConfirm;
  const _DeleteDialog({
    required this.printerName,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: Colors.transparent,
    insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
    child: Container(
      width:  380,
      decoration: BoxDecoration(
        color:        _T.white,
        borderRadius: BorderRadius.circular(_T.rLg + 4),
        border:       Border.all(color: _T.slate200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.10),
              blurRadius: 24, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 16, 0),
            child: Row(children: [
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  color:  _T.red50,
                  shape:  BoxShape.circle,
                  border: Border.all(color: _T.red.withOpacity(0.2)),
                ),
                child: const Icon(Icons.delete_outline_rounded,
                    size: 15, color: _T.red),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Delete Printer',
                        style: TextStyle(
                          fontSize:   15,
                          fontWeight: FontWeight.w700,
                          color:      _T.ink,
                        )),
                    Text('This action cannot be undone',
                        style: TextStyle(
                            fontSize: 11.5, color: _T.slate400)),
                  ],
                ),
              ),
              // Close
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 26, height: 26,
                    decoration: BoxDecoration(
                      border:       Border.all(color: _T.slate200),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: const Icon(Icons.close_rounded,
                        size: 13, color: _T.slate400),
                  ),
                ),
              ),
            ]),
          ),

          // Printer chip
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color:        _T.slate50,
                borderRadius: BorderRadius.circular(_T.r),
                border:       Border.all(color: _T.slate200),
              ),
              child: Row(children: [
                const Icon(Icons.print_outlined,
                    size: 13, color: _T.slate400),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(printerName,
                      style: const TextStyle(
                        fontSize:   12.5,
                        fontWeight: FontWeight.w600,
                        color:      _T.ink3,
                      )),
                ),
              ]),
            ),
          ),

          const Divider(height: 24, indent: 20, endIndent: 20,
              color: _T.slate100),

          // Actions
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(children: [
              Expanded(
                child: _GhostBtn(
                  label: 'Cancel',
                  onTap: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: _DangerBtn(
                  label: 'Delete Printer',
                  onTap: onConfirm,
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
// SHARED BUTTON COMPONENTS
// ─────────────────────────────────────────────────────────────────────────────
class _GhostBtn extends StatefulWidget {
  final String       label;
  final VoidCallback? onTap;
  const _GhostBtn({required this.label, this.onTap});
  @override
  State<_GhostBtn> createState() => _GhostBtnState();
}

class _GhostBtnState extends State<_GhostBtn> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) {
    final disabled = widget.onTap == null;
    return MouseRegion(
      cursor:  disabled ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: _hovered && !disabled ? _T.slate100 : Colors.transparent,
            borderRadius: BorderRadius.circular(_T.r),
            border: Border.all(color: _T.slate200),
          ),
          child: Center(
            child: Text(widget.label,
                style: TextStyle(
                  fontSize:   12.5,
                  fontWeight: FontWeight.w600,
                  color:      disabled ? _T.slate300 : _T.slate500,
                )),
          ),
        ),
      ),
    );
  }
}

class _PrimaryBtn extends StatefulWidget {
  final String       label;
  final IconData?    icon;
  final bool         loading;
  final VoidCallback? onTap;
  const _PrimaryBtn({
    required this.label,
    required this.loading,
    this.icon,
    this.onTap,
  });
  @override
  State<_PrimaryBtn> createState() => _PrimaryBtnState();
}

class _PrimaryBtnState extends State<_PrimaryBtn> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null && !widget.loading;
    return MouseRegion(
      cursor:  enabled ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: enabled
                ? (_hovered ? _T.blueHover : _T.blue)
                : _T.slate100,
            borderRadius: BorderRadius.circular(_T.r),
            boxShadow: enabled
                ? [BoxShadow(color: _T.blue.withOpacity(0.25),
                    blurRadius: 8, offset: const Offset(0, 2))]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.loading)
                const SizedBox(width: 13, height: 13,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: Colors.white))
              else if (widget.icon != null)
                Icon(widget.icon, size: 13,
                    color: enabled ? Colors.white : _T.slate400),
              if (!widget.loading && widget.icon != null)
                const SizedBox(width: 6),
              Text(widget.label,
                  style: TextStyle(
                    fontSize:   12.5,
                    fontWeight: FontWeight.w700,
                    color:      enabled ? Colors.white : _T.slate400,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

class _DangerBtn extends StatefulWidget {
  final String       label;
  final VoidCallback onTap;
  const _DangerBtn({required this.label, required this.onTap});
  @override
  State<_DangerBtn> createState() => _DangerBtnState();
}

class _DangerBtnState extends State<_DangerBtn> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor:  SystemMouseCursors.click,
    onEnter: (_) => setState(() => _hovered = true),
    onExit:  (_) => setState(() => _hovered = false),
    child: GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color:        _hovered ? const Color(0xFFDC2626) : _T.red,
          borderRadius: BorderRadius.circular(_T.r),
          boxShadow: [
            BoxShadow(color: _T.red.withOpacity(0.25),
                blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.delete_outline_rounded,
              size: 13, color: Colors.white),
          const SizedBox(width: 6),
          Text(widget.label,
              style: const TextStyle(
                fontSize:   12.5,
                fontWeight: FontWeight.w700,
                color:      Colors.white,
              )),
        ]),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// MICRO WIDGETS
// ─────────────────────────────────────────────────────────────────────────────
class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize:   10.5,
      fontWeight: FontWeight.w700,
      color:      _T.slate500,
      letterSpacing: 0.1,
    ),
  );
}
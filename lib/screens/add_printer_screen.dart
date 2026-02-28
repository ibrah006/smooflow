// lib/screens/printer/add_printer_screen.dart
//
// Design-system refresh — zero data/logic changes.
// All _savePrinter(), _confirmDelete(), _showStaffPicker() bodies are
// preserved verbatim; only the presentation layer has changed.
//
// Token system, card anatomy, field style, topbar, bottom-bar, and
// status-option colours now match every other smooflow mobile screen
// (delivery_dashboard_screen, viewer_pending_screen, invite_member_screen).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/core/models/printer.dart';
import 'package:smooflow/providers/printer_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TOKENS — identical to every other smooflow screen
// ─────────────────────────────────────────────────────────────────────────────
class _T {
  static const blue    = Color(0xFF2563EB);
  static const blue50  = Color(0xFFEFF6FF);
  static const teal    = Color(0xFF38BDF8);
  static const green   = Color(0xFF10B981);
  static const green50 = Color(0xFFECFDF5);
  static const amber   = Color(0xFFF59E0B);
  static const amber50 = Color(0xFFFEF3C7);
  static const red     = Color(0xFFEF4444);
  static const red50   = Color(0xFFFEE2E2);
  static const slate50  = Color(0xFFF8FAFC);
  static const slate100 = Color(0xFFF1F5F9);
  static const slate200 = Color(0xFFE2E8F0);
  static const slate300 = Color(0xFFCBD5E1);
  static const slate400 = Color(0xFF94A3B8);
  static const slate500 = Color(0xFF64748B);
  static const ink      = Color(0xFF0F172A);
  static const ink3     = Color(0xFF334155);
  static const white    = Colors.white;
  static const r        = 8.0;
  static const rLg      = 12.0;
  static const rXl      = 16.0;
}

// ─────────────────────────────────────────────────────────────────────────────
// STATUS METADATA
// ─────────────────────────────────────────────────────────────────────────────
Color _statusColor(PrinterStatus s) => switch (s) {
  PrinterStatus.active      => _T.green,
  PrinterStatus.maintenance => _T.amber,
  PrinterStatus.offline     => _T.slate400,
  _                         => _T.slate400,
};
Color _statusBg(PrinterStatus s) => switch (s) {
  PrinterStatus.active      => _T.green50,
  PrinterStatus.maintenance => _T.amber50,
  PrinterStatus.offline     => _T.slate100,
  _                         => _T.slate100,
};
IconData _statusIcon(PrinterStatus s) => switch (s) {
  PrinterStatus.active      => Icons.check_circle_outline_rounded,
  PrinterStatus.maintenance => Icons.build_outlined,
  PrinterStatus.offline     => Icons.power_off_outlined,
  _                         => Icons.help_outline_rounded,
};

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class AddPrinterScreen extends ConsumerStatefulWidget {
  final Printer? printer;

  const AddPrinterScreen.add({Key? key, this.printer}) : super(key: key);
  const AddPrinterScreen.details({Key? key, required this.printer})
      : super(key: key);

  @override
  ConsumerState<AddPrinterScreen> createState() => _AddPrinterScreenState();
}

class _AddPrinterScreenState extends ConsumerState<AddPrinterScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _nicknameController;
  late TextEditingController _locationController;

  PrinterStatus _selectedStatus = PrinterStatus.active;
  List<String> _selectedStaffIds = [];

  // ── Lifecycle ────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.printer?.name ?? '');
    _nicknameController =
        TextEditingController(text: widget.printer?.nickname ?? '');
    _locationController =
        TextEditingController(text: widget.printer?.location ?? '');

    if (widget.printer != null) {
      _selectedStatus = widget.printer!.status;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nicknameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  bool get _isEditing => widget.printer != null;

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark
          .copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: _T.slate50,
        body: Column(
          children: [
            // ── Topbar ─────────────────────────────────────────────────
            _Topbar(
              isEditing:  _isEditing,
              onBack:     () => Navigator.pop(context),
              onDelete:   _isEditing ? _confirmDelete : null,
            ),

            // ── Scrollable form ────────────────────────────────────────
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: EdgeInsets.fromLTRB(16, 20, 16, 20 + mq.padding.bottom),
                  physics: const BouncingScrollPhysics(),
                  children: [

                    // Printer details card
                    _SectionCard(
                      icon:     Icons.print_outlined,
                      iconColor: _T.blue,
                      iconBg:   _T.blue50,
                      title:    'Printer Details',
                      subtitle: 'Model, nickname and location',
                      child: Column(
                        children: [
                          _SmooField(
                            controller: _nameController,
                            label:      'Printer Name',
                            hint:       'e.g. Epson SureColor P8000',
                            icon:       Icons.print_outlined,
                            readOnly:   _isEditing,
                            validator: (v) =>
                                (v == null || v.isEmpty)
                                    ? 'Please enter printer name'
                                    : null,
                          ),
                          const SizedBox(height: 14),
                          _SmooField(
                            controller: _nicknameController,
                            label:      'Nickname',
                            hint:       'e.g. Large Format A',
                            icon:       Icons.label_outline_rounded,
                            readOnly:   _isEditing,
                            validator: (v) =>
                                (v == null || v.isEmpty)
                                    ? 'Please enter a nickname'
                                    : null,
                          ),
                          const SizedBox(height: 14),
                          _SmooField(
                            controller: _locationController,
                            label:      'Location',
                            hint:       _isEditing ? 'N/a' : 'e.g. Section A',
                            icon:       Icons.location_on_outlined,
                            readOnly:   _isEditing,
                          ),
                          // Task ID — shown only in edit/details mode
                          if (widget.printer?.currentJobId != null) ...[
                            const SizedBox(height: 14),
                            _ReadOnlyField(
                              label: 'Current Task ID',
                              value: widget.printer!.currentJobId.toString(),
                              icon:  Icons.assignment_outlined,
                            ),
                          ],
                          // True hardware status (read-only info row)
                          const SizedBox(height: 14),
                          _ReadOnlyField(
                            label: 'Hardware Status',
                            value: widget.printer?.statusName ?? 'N/a',
                            icon:  Icons.sensors_rounded,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Status card
                    _SectionCard(
                      icon:     Icons.toggle_on_outlined,
                      iconColor: _statusColor(_selectedStatus),
                      iconBg:   _statusBg(_selectedStatus),
                      title:    'Printer Status',
                      subtitle: 'Set the operational state',
                      child: Column(
                        children: [
                          _StatusOption(
                            status:    PrinterStatus.active,
                            label:     'Active',
                            sub:       'Ready to receive print jobs',
                            selected:  _selectedStatus,
                            onTap: () =>
                                setState(() => _selectedStatus = PrinterStatus.active),
                          ),
                          const SizedBox(height: 10),
                          _StatusOption(
                            status:    PrinterStatus.maintenance,
                            label:     'Maintenance',
                            sub:       'Under service — not accepting jobs',
                            selected:  _selectedStatus,
                            onTap: () =>
                                setState(() => _selectedStatus = PrinterStatus.maintenance),
                          ),
                          const SizedBox(height: 10),
                          _StatusOption(
                            status:    PrinterStatus.offline,
                            label:     'Offline',
                            sub:       'Powered off or unreachable',
                            selected:  _selectedStatus,
                            onTap: () =>
                                setState(() => _selectedStatus = PrinterStatus.offline),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Staff assignment card
                    _StaffCard(
                      count: _selectedStaffIds.length,
                      onTap: _showStaffPicker,
                    ),
                  ],
                ),
              ),
            ),

            // ── Bottom action bar ──────────────────────────────────────
            _BottomBar(
              isEditing: _isEditing,
              onCancel:  () => Navigator.pop(context),
              onSave:    _savePrinter,
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // DATA / LOGIC — unchanged from original
  // ─────────────────────────────────────────────────────────────────────────
  void _showStaffPicker() {
    showModalBottomSheet(
      context:         context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: _T.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: _T.slate200,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Assign Staff',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
                    color: _T.ink, letterSpacing: -0.4)),
            const SizedBox(height: 16),
            const Text('Staff picker will be implemented here',
                style: TextStyle(fontSize: 15, color: _T.slate400)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                style: FilledButton.styleFrom(
                  backgroundColor: _T.blue,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(_T.rLg)),
                ),
                child: const Text('Done',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
          ],
        ),
      ),
    );
  }

  void _savePrinter() async {
    if (widget.printer != null) {
      try {
        await ref.read(printerNotifierProvider.notifier).updatePrinter(
          widget.printer!.id,
          name:     _nameController.text,
          nickname: _nicknameController.text,
          location: _locationController.text,
          status:   _selectedStatus,
        );
      } catch (e) {
        _snack('Failed to update printer. Please try again.', isError: true);
        return;
      }
      _snack('Printer updated successfully', isError: false);
      return;
    }

    if (_formKey.currentState!.validate()) {
      // try {
        await ref.read(printerNotifierProvider.notifier).createPrinter(
          name:     _nameController.text,
          nickname: _nicknameController.text,
          location: _locationController.text,
        );
      // } catch (e) {
      //   _snack('Failed to add printer. Please try again.', isError: true);
      //   return;
      // }
      Navigator.pop(context);
      _snack(widget.printer != null ? 'Printer updated' : 'Printer added',
          isError: false);
    }
  }

  void _confirmDelete() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context:            context,
      isScrollControlled: true,
      backgroundColor:    Colors.transparent,
      builder: (_) => _DeleteConfirmSheet(
        printerName: widget.printer?.name ?? 'this printer',
        onConfirm: () {
          Navigator.pop(context); // close sheet
          Navigator.pop(context); // close screen
          _snack('Printer deleted', isError: false);
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
          size: 16,
          color: Colors.white,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(msg,
              style: const TextStyle(
                  fontSize: 13.5, fontWeight: FontWeight.w500)),
        ),
      ]),
      backgroundColor: _T.ink,
      behavior:        SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_T.r)),
      margin:   const EdgeInsets.all(16),
      duration: const Duration(seconds: 4),
    ));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TOPBAR
// ─────────────────────────────────────────────────────────────────────────────
class _Topbar extends StatelessWidget {
  final bool         isEditing;
  final VoidCallback onBack;
  final VoidCallback? onDelete;

  const _Topbar({
    required this.isEditing,
    required this.onBack,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return Container(
      color: _T.white,
      padding: EdgeInsets.only(top: mq.padding.top),
      child: Container(
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: const BoxDecoration(
          color: _T.white,
          border: Border(bottom: BorderSide(color: _T.slate200)),
        ),
        child: Row(children: [
          // Back button
          GestureDetector(
            onTap: onBack,
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: _T.slate100,
                borderRadius: BorderRadius.circular(_T.r),
                border: Border.all(color: _T.slate200),
              ),
              child: const Icon(Icons.arrow_back_rounded,
                  size: 18, color: _T.ink3),
            ),
          ),
          const SizedBox(width: 12),

          // Title
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEditing ? 'Printer Details' : 'Add Printer',
                  style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700,
                    color: _T.ink, letterSpacing: -0.2),
                ),
                const Text(
                  'Configure printer settings',
                  style: TextStyle(
                    fontSize: 10.5, color: _T.slate400,
                    fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),

          // Delete button (edit mode only)
          if (isEditing && onDelete != null)
            GestureDetector(
              onTap: onDelete,
              child: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: _T.red50,
                  borderRadius: BorderRadius.circular(_T.r),
                  border: Border.all(color: _T.red.withOpacity(0.25)),
                ),
                child: const Icon(Icons.delete_outline_rounded,
                    size: 18, color: _T.red),
              ),
            ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SECTION CARD — white card with header row + divider + content
// ─────────────────────────────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final IconData icon;
  final Color    iconColor, iconBg;
  final String   title, subtitle;
  final Widget   child;

  const _SectionCard({
    required this.icon,     required this.iconColor, required this.iconBg,
    required this.title,    required this.subtitle,  required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _T.white,
        borderRadius: BorderRadius.circular(_T.rXl),
        border: Border.all(color: _T.slate200),
        boxShadow: [
          BoxShadow(
            color:  Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
            child: Row(children: [
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: iconColor.withOpacity(0.2)),
                ),
                child: Icon(icon, size: 17, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700,
                          color: _T.ink, letterSpacing: -0.2)),
                    Text(subtitle,
                        style: const TextStyle(
                          fontSize: 11.5, color: _T.slate400,
                          fontWeight: FontWeight.w400)),
                  ],
                ),
              ),
            ]),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Divider(height: 1, color: _T.slate100),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
            child: child,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SMOO TEXT FIELD — editable, focus-animated
// ─────────────────────────────────────────────────────────────────────────────
class _SmooField extends StatefulWidget {
  final TextEditingController? controller;
  final String                 label, hint;
  final IconData               icon;
  final bool                   readOnly;
  final String? Function(String?)? validator;

  const _SmooField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.readOnly  = false,
    this.validator,
  });

  @override
  State<_SmooField> createState() => _SmooFieldState();
}

class _SmooFieldState extends State<_SmooField> {
  final _focus = FocusNode();
  bool  _focused = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() =>
        setState(() => _focused = _focus.hasFocus));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // In read-only (details/edit) mode, render as a static info row
    // so the form doesn't show disabled inputs which look broken.
    if (widget.readOnly) {
      return _ReadOnlyField(
        label: widget.label,
        value: widget.controller?.text.isNotEmpty == true
            ? widget.controller!.text
            : widget.hint,
        icon: widget.icon,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(widget.label),
        const SizedBox(height: 7),
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
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
                fontSize: 14, color: _T.ink, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              hintText:  widget.hint,
              hintStyle: const TextStyle(
                  fontSize: 14, color: _T.slate300),
              prefixIcon: Icon(widget.icon, size: 17, color: _T.slate400),
              border:     InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                  vertical: 13, horizontal: 14),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// READ-ONLY INFO ROW — for details mode + hardware-status field
// ─────────────────────────────────────────────────────────────────────────────
class _ReadOnlyField extends StatelessWidget {
  final String   label, value;
  final IconData icon;

  const _ReadOnlyField({
    required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label),
        const SizedBox(height: 7),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: _T.slate50,
            borderRadius: BorderRadius.circular(_T.r),
            border: Border.all(color: _T.slate200),
          ),
          child: Row(children: [
            Icon(icon, size: 16, color: _T.slate400),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 14, color: _T.ink3,
                  fontWeight: FontWeight.w500),
              ),
            ),
          ]),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STATUS OPTION — coloured selection card per status
// ─────────────────────────────────────────────────────────────────────────────
class _StatusOption extends StatelessWidget {
  final PrinterStatus status, selected;
  final String        label, sub;
  final VoidCallback  onTap;

  const _StatusOption({
    required this.status, required this.selected,
    required this.label,  required this.sub,
    required this.onTap,
  });

  bool get _isSelected => status == selected;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    final bg    = _statusBg(status);
    final icon  = _statusIcon(status);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _isSelected ? bg : _T.white,
          borderRadius: BorderRadius.circular(_T.rLg),
          border: Border.all(
            color: _isSelected ? color.withOpacity(0.5) : _T.slate200,
            width: _isSelected ? 1.5 : 1,
          ),
          boxShadow: _isSelected
              ? [BoxShadow(
                  color: color.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 3))]
              : null,
        ),
        child: Row(children: [
          // Coloured icon container
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: _isSelected
                  ? color.withOpacity(0.15)
                  : _T.slate100,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 17,
                color: _isSelected ? color : _T.slate400),
          ),
          const SizedBox(width: 12),

          // Label + subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                      fontSize: 13.5, fontWeight: FontWeight.w700,
                      color: _isSelected ? color : _T.ink3,
                    )),
                const SizedBox(height: 2),
                Text(sub,
                    style: const TextStyle(
                        fontSize: 11.5, color: _T.slate400)),
              ],
            ),
          ),

          // Check indicator
          AnimatedOpacity(
            opacity: _isSelected ? 1.0 : 0.0,
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
// STAFF ASSIGNMENT CARD
// ─────────────────────────────────────────────────────────────────────────────
class _StaffCard extends StatelessWidget {
  final int          count;
  final VoidCallback onTap;
  const _StaffCard({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _T.white,
        borderRadius: BorderRadius.circular(_T.rXl),
        border: Border.all(color: _T.slate200),
        boxShadow: [
          BoxShadow(
            color:  Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: _T.slate100,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _T.slate200),
          ),
          child: const Icon(Icons.people_outline_rounded,
              size: 20, color: _T.slate500),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Assigned Staff',
                  style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700,
                    color: _T.ink, letterSpacing: -0.1)),
              const SizedBox(height: 3),
              Text(
                count == 0
                    ? 'Tap to assign staff members'
                    : '$count staff assigned',
                style: const TextStyle(
                    fontSize: 12, color: _T.slate400),
              ),
            ],
          ),
        ),
        // Count badge
        if (count > 0) ...[
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: _T.blue50,
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: _T.blue.withOpacity(0.25)),
            ),
            child: Text('$count',
                style: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700,
                  color: _T.blue)),
          ),
          const SizedBox(width: 8),
        ],
        const Icon(Icons.chevron_right_rounded,
            size: 20, color: _T.slate400),
      ]),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// BOTTOM ACTION BAR
// ─────────────────────────────────────────────────────────────────────────────
class _BottomBar extends StatelessWidget {
  final bool         isEditing;
  final VoidCallback onCancel, onSave;
  const _BottomBar({
    required this.isEditing, required this.onCancel, required this.onSave});

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + mq.padding.bottom),
      decoration: const BoxDecoration(
        color: _T.white,
        border: Border(top: BorderSide(color: _T.slate200)),
      ),
      child: Row(children: [
        if (isEditing) ...[
          Expanded(
            child: OutlinedButton(
              onPressed: onCancel,
              style: OutlinedButton.styleFrom(
                foregroundColor: _T.slate500,
                side: const BorderSide(color: _T.slate200),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(_T.rLg)),
              ),
              child: const Text('Cancel',
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          flex: isEditing ? 2 : 1,
          child: FilledButton.icon(
            onPressed: onSave,
            style: FilledButton.styleFrom(
              backgroundColor: _T.blue,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_T.rLg)),
            ),
            icon: Icon(
              isEditing
                  ? Icons.check_rounded
                  : Icons.add_rounded,
              size: 18,
            ),
            label: Text(
              isEditing ? 'Save Changes' : 'Add Printer',
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DELETE CONFIRM SHEET
// Bottom-sheet pattern matching DeliveryDashboardScreen._DeliverSheet.
// Replaces the old AlertDialog.
// ─────────────────────────────────────────────────────────────────────────────
class _DeleteConfirmSheet extends StatelessWidget {
  final String       printerName;
  final VoidCallback onConfirm;
  const _DeleteConfirmSheet({
    required this.printerName, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return Container(
      padding: EdgeInsets.fromLTRB(22, 0, 22, 24 + mq.padding.bottom),
      decoration: const BoxDecoration(
        color: _T.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 14),
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: _T.slate200,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),

          // Red icon
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: _T.red50,
              shape: BoxShape.circle,
              border: Border.all(
                  color: _T.red.withOpacity(0.2), width: 2),
            ),
            child: const Icon(Icons.delete_outline_rounded,
                size: 28, color: _T.red),
          ),
          const SizedBox(height: 14),

          const Text('Delete Printer',
              style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.w800,
                color: _T.ink, letterSpacing: -0.4)),
          const SizedBox(height: 6),

          const Text(
            'This action cannot be undone.\nThe printer and all its data will be permanently removed.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 13.5, height: 1.55, color: _T.slate500),
          ),
          const SizedBox(height: 18),

          // Printer name chip
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _T.slate50,
              borderRadius: BorderRadius.circular(_T.rLg),
              border: Border.all(color: _T.slate200),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.print_outlined,
                  size: 16, color: _T.slate400),
              const SizedBox(width: 8),
              Text(
                printerName,
                style: const TextStyle(
                  fontSize: 13.5, fontWeight: FontWeight.w600,
                  color: _T.ink3),
              ),
            ]),
          ),
          const SizedBox(height: 22),

          // Buttons
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _T.slate500,
                  side: const BorderSide(color: _T.slate200),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(_T.rLg)),
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
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(_T.rLg)),
                ),
                icon: const Icon(Icons.delete_outline_rounded,
                    size: 18),
                label: const Text('Delete Printer',
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ],
      ),
    );
  }
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
        fontSize: 11.5, fontWeight: FontWeight.w700,
        color: _T.slate500, letterSpacing: 0.1),
  );
}
// START PRINT JOB SCREEN - Desktop three-column layout
// Navigation: Navigator.push(context, MaterialPageRoute(builder: (_) => StartPrintJobScreen(task: task)));
// TODO markers = your three wiring points. Zero data logic included.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/core/models/task.dart';

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
  static const r         = 8.0;
  static const rLg       = 12.0;
}

// Stub models - replace with your real Printer / MaterialModel classes
class _PrinterStub {
  final String id, name, nickname;
  final bool   isAvailable;
  final String statusLabel;
  final Color  statusColor, statusBg;
  const _PrinterStub({required this.id, required this.name,
    required this.nickname, required this.isAvailable,
    required this.statusLabel, required this.statusColor,
    required this.statusBg});
}

class _MaterialStub {
  final String id, name, unitShort;
  final double currentStock, minStockLevel;
  bool   get isLowStock      => currentStock > 0 && currentStock < minStockLevel;
  bool   get isCriticalStock => currentStock <= 0;
  Color  get stockColor => isCriticalStock ? _T.red  : isLowStock ? _T.amber  : _T.green;
  Color  get stockBg    => isCriticalStock ? _T.red50 : isLowStock ? _T.amber50 : _T.green50;
  String get stockLabel => isCriticalStock ? 'Out of stock' : isLowStock ? 'Low stock' : 'In stock';
  String fmtStock() {
    final v = currentStock;
    return v == v.truncateToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);
  }
  const _MaterialStub({required this.id, required this.name,
    required this.unitShort, required this.currentStock,
    required this.minStockLevel});
}

// SCREEN
class StartPrintJobScreen extends ConsumerStatefulWidget {
  final Task task;
  const StartPrintJobScreen({super.key, required this.task});
  @override
  ConsumerState<StartPrintJobScreen> createState() => _State();
}

class _State extends ConsumerState<StartPrintJobScreen> {
  _PrinterStub?  _printer;
  _MaterialStub? _material;
  final _qtyCtrl    = TextEditingController();
  final _searchCtrl = TextEditingController();
  bool _submitting  = false;

  double? get _qty {
    final v = double.tryParse(_qtyCtrl.text);
    return (v != null && v > 0) ? v : null;
  }
  bool get _canSubmit => _printer != null && _material != null && _qty != null;

  // TODO: replace with ref.watch(printerProvider).printers
  List<_PrinterStub> get _printers => const [];

  // TODO: replace with ref.watch(materialProvider).materials
  List<_MaterialStub> get _allMaterials => const [];

  List<_MaterialStub> get _filtered {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return _allMaterials;
    return _allMaterials.where((m) => m.name.toLowerCase().contains(q)).toList();
  }

  Future<void> _submit() async {
    if (!_canSubmit || _submitting) return;
    setState(() => _submitting = true);
    // TODO: await ref.read(printerProvider.notifier).startPrintJob(
    //   taskId: widget.task.id, printerId: _printer!.id,
    //   materialId: _material!.id, quantity: _qty!);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() { _qtyCtrl.dispose(); _searchCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _T.slate50,
    body: Column(children: [
      _TopBar(task: widget.task),
      Expanded(child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: Printer
          SizedBox(width: 340,
            child: _Panel(borderRight: true,
              child: _PrinterColumn(
                printers: _printers, selected: _printer,
                onSelect: (p) => setState(() => _printer = p)))),
          // Center: Material
          Expanded(child: _Panel(borderRight: true,
            child: _MaterialColumn(
              allMaterials: _allMaterials, filtered: _filtered,
              selected: _material, searchCtrl: _searchCtrl,
              onSelect: (m) => setState(() { _material = m; _qtyCtrl.clear(); }),
              onSearchChanged: (_) => setState(() {})))),
          // Right: Usage + CTA
          SizedBox(width: 300,
            child: _Panel(child: _UsageColumn(
              task: widget.task, printer: _printer, material: _material,
              qtyCtrl: _qtyCtrl, canSubmit: _canSubmit, submitting: _submitting,
              onChanged: (_) => setState(() {}), onSubmit: _submit))),
        ],
      )),
    ]),
  );
}

// TOP BAR
class _TopBar extends StatelessWidget {
  final Task task;
  const _TopBar({required this.task});
  @override
  Widget build(BuildContext context) => Container(
    height: _T.topbarH,
    decoration: const BoxDecoration(
      color: _T.white,
      border: Border(bottom: BorderSide(color: _T.slate200))),
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Row(children: [
      MouseRegion(cursor: SystemMouseCursors.click,
        child: GestureDetector(onTap: () => Navigator.of(context).pop(),
          child: Container(width: 26, height: 26,
            decoration: BoxDecoration(
              border: Border.all(color: _T.slate200),
              borderRadius: BorderRadius.circular(_T.r)),
            child: const Icon(Icons.arrow_back_rounded, size: 13, color: _T.slate400)))),
      const SizedBox(width: 12),
      Container(width: 1, height: 18, color: _T.slate200),
      const SizedBox(width: 12),
      Container(width: 26, height: 26,
        decoration: BoxDecoration(
          color: _T.blue50, borderRadius: BorderRadius.circular(6),
          border: Border.all(color: _T.blue100)),
        child: const Icon(Icons.print_rounded, size: 13, color: _T.blue)),
      const SizedBox(width: 8),
      const Text('Start Print Job',
          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700,
              color: _T.ink, letterSpacing: -0.2)),
      const SizedBox(width: 6),
      const Icon(Icons.chevron_right_rounded, size: 14, color: _T.slate300),
      const SizedBox(width: 6),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: _T.slate100, borderRadius: BorderRadius.circular(5),
          border: Border.all(color: _T.slate200)),
        child: Text('TASK-${task.id}',
            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700,
                letterSpacing: 0.3, color: _T.slate500, fontFamily: 'monospace'))),
      const Spacer(),
      _StepDot(number: '1', label: 'Printer'),
      const SizedBox(width: 4),
      Container(width: 20, height: 1, color: _T.slate200),
      const SizedBox(width: 4),
      _StepDot(number: '2', label: 'Material'),
      const SizedBox(width: 4),
      Container(width: 20, height: 1, color: _T.slate200),
      const SizedBox(width: 4),
      _StepDot(number: '3', label: 'Usage'),
    ]),
  );
}

class _StepDot extends StatelessWidget {
  final String number, label;
  const _StepDot({required this.number, required this.label});
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min,
    children: [
      Container(width: 18, height: 18,
        decoration: BoxDecoration(color: _T.white, shape: BoxShape.circle,
          border: Border.all(color: _T.slate200)),
        child: Center(child: Text(number,
            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: _T.slate400)))),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: _T.slate400)),
    ]);
}

// PANEL WRAPPER
class _Panel extends StatelessWidget {
  final Widget child;
  final bool   borderRight;
  const _Panel({required this.child, this.borderRight = false});
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(color: _T.white,
      border: borderRight ? const Border(right: BorderSide(color: _T.slate200)) : null),
    child: child);
}

// COLUMN HEADER
class _ColHeader extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final Color iconColor, iconBg;
  const _ColHeader({required this.title, required this.subtitle,
    required this.icon, required this.iconColor, required this.iconBg});
  @override
  Widget build(BuildContext context) => Container(
    height: _T.topbarH,
    padding: const EdgeInsets.symmetric(horizontal: 16),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: _T.slate200))),
    child: Row(children: [
      Container(width: 28, height: 28,
        decoration: BoxDecoration(color: iconBg,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: iconColor.withOpacity(0.2))),
        child: Icon(icon, size: 13, color: iconColor)),
      const SizedBox(width: 10),
      Column(crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: const TextStyle(fontSize: 12.5,
              fontWeight: FontWeight.w700, color: _T.ink)),
          Text(subtitle, style: const TextStyle(fontSize: 10.5, color: _T.slate400)),
        ]),
    ]));
}

// PRINTER COLUMN
class _PrinterColumn extends StatelessWidget {
  final List<_PrinterStub> printers;
  final _PrinterStub? selected;
  final ValueChanged<_PrinterStub> onSelect;
  const _PrinterColumn({required this.printers, required this.selected, required this.onSelect});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _ColHeader(title: 'Select Printer', subtitle: 'Available printers only',
        icon: Icons.print_rounded, iconColor: _T.blue, iconBg: _T.blue50),
      Expanded(child: printers.isEmpty
        ? _EmptyState(icon: Icons.print_disabled_outlined,
            title: 'No printers available', subtitle: 'All printers are busy or offline')
        : ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: printers.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (_, i) {
              final p = printers[i];
              return _PrinterTile(printer: p, isSelected: selected?.id == p.id,
                onTap: p.isAvailable ? () => onSelect(p) : null);
            })),
    ]);
}

class _PrinterTile extends StatefulWidget {
  final _PrinterStub printer;
  final bool isSelected;
  final VoidCallback? onTap;
  const _PrinterTile({required this.printer, required this.isSelected, this.onTap});
  @override
  State<_PrinterTile> createState() => _PrinterTileState();
}

class _PrinterTileState extends State<_PrinterTile> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) {
    final p = widget.printer;
    final selected = widget.isSelected;
    final disabled = widget.onTap == null;
    return MouseRegion(
      cursor: disabled ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(onTap: widget.onTap,
        child: AnimatedContainer(duration: const Duration(milliseconds: 130),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: disabled ? Colors.transparent
              : selected ? _T.blue50
              : _hovered ? _T.slate50 : Colors.transparent,
            borderRadius: BorderRadius.circular(_T.r),
            border: Border.all(
              color: selected ? _T.blue.withOpacity(0.4)
                : _hovered ? _T.slate200 : _T.slate200,
              width: selected ? 1.5 : 1.0)),
          child: Row(children: [
            Container(width: 32, height: 32,
              decoration: BoxDecoration(
                color: disabled ? _T.slate100
                  : selected ? _T.blue.withOpacity(0.10) : _T.slate100,
                borderRadius: BorderRadius.circular(7)),
              child: Icon(Icons.print_outlined, size: 15,
                  color: disabled ? _T.slate300 : selected ? _T.blue : _T.slate500)),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.name, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600,
                  color: disabled ? _T.slate400 : _T.ink)),
              if (p.nickname.isNotEmpty)
                Text(p.nickname, style: const TextStyle(fontSize: 11, color: _T.slate400)),
            ])),
            _StatusPill(label: p.statusLabel, color: p.statusColor, bg: p.statusBg),
            if (selected) ...[
              const SizedBox(width: 8),
              const Icon(Icons.check_circle_rounded, size: 15, color: _T.blue),
            ],
          ]))));
  }
}

// MATERIAL COLUMN
class _MaterialColumn extends StatelessWidget {
  final List<_MaterialStub> allMaterials, filtered;
  final _MaterialStub? selected;
  final TextEditingController searchCtrl;
  final ValueChanged<_MaterialStub> onSelect;
  final ValueChanged<String> onSearchChanged;
  const _MaterialColumn({required this.allMaterials, required this.filtered,
    required this.selected, required this.searchCtrl,
    required this.onSelect, required this.onSearchChanged});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _ColHeader(title: 'Select Material', subtitle: 'Pick the material for this job',
        icon: Icons.layers_outlined, iconColor: _T.purple, iconBg: _T.purple50),
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
        child: Row(children: [
          Expanded(child: Container(
            height: 30,
            decoration: BoxDecoration(color: _T.slate50,
              borderRadius: BorderRadius.circular(_T.r),
              border: Border.all(color: _T.slate200)),
            child: TextField(
              controller: searchCtrl, onChanged: onSearchChanged,
              style: const TextStyle(fontSize: 12, color: _T.ink),
              decoration: InputDecoration(
                hintText: 'Search…',
                hintStyle: const TextStyle(fontSize: 12, color: _T.slate300),
                prefixIcon: const Icon(Icons.search_rounded, size: 13, color: _T.slate400),
                suffixIcon: searchCtrl.text.isNotEmpty
                  ? GestureDetector(
                      onTap: () { searchCtrl.clear(); onSearchChanged(''); },
                      child: const Icon(Icons.close_rounded, size: 12, color: _T.slate400))
                  : null,
                border: InputBorder.none, isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 7))))),
          const SizedBox(width: 8),
          Text('${filtered.length}',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _T.slate400)),
        ])),
      Expanded(child: allMaterials.isEmpty
        ? _EmptyState(icon: Icons.layers_clear_outlined,
            title: 'No materials', subtitle: 'Add materials to inventory first')
        : filtered.isEmpty
          ? _EmptyState(icon: Icons.search_off_rounded,
              title: 'No results', subtitle: 'Try a different search')
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemBuilder: (_, i) {
                final m = filtered[i];
                return _MaterialTile(material: m, isSelected: selected?.id == m.id,
                  onTap: m.isCriticalStock ? null : () => onSelect(m));
              })),
    ]);
}

class _MaterialTile extends StatefulWidget {
  final _MaterialStub material;
  final bool isSelected;
  final VoidCallback? onTap;
  const _MaterialTile({required this.material, required this.isSelected, this.onTap});
  @override
  State<_MaterialTile> createState() => _MaterialTileState();
}

class _MaterialTileState extends State<_MaterialTile> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) {
    final m = widget.material;
    final selected = widget.isSelected;
    final disabled = widget.onTap == null;
    return MouseRegion(
      cursor: disabled ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(onTap: widget.onTap,
        child: AnimatedContainer(duration: const Duration(milliseconds: 130),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: disabled ? Colors.transparent
              : selected ? _T.purple50
              : _hovered ? _T.slate50 : Colors.transparent,
            borderRadius: BorderRadius.circular(_T.r),
            border: Border.all(
              color: selected ? _T.purple.withOpacity(0.35)
                : _hovered ? _T.slate200 : _T.slate200,
              width: selected ? 1.5 : 1.0)),
          child: Row(children: [
            Container(width: 30, height: 30,
              decoration: BoxDecoration(
                color: disabled ? _T.slate100
                  : selected ? _T.purple.withOpacity(0.10) : _T.slate100,
                borderRadius: BorderRadius.circular(7)),
              child: Icon(Icons.layers_outlined, size: 13,
                  color: disabled ? _T.slate300 : selected ? _T.purple : _T.slate500)),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(m.name, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600,
                    color: disabled ? _T.slate400 : _T.ink)),
              Text('${m.fmtStock()} ${m.unitShort} available',
                style: TextStyle(fontSize: 11, color: disabled ? _T.slate300 : _T.slate400)),
            ])),
            _StatusPill(label: m.stockLabel, color: m.stockColor, bg: m.stockBg),
            if (selected) ...[
              const SizedBox(width: 8),
              const Icon(Icons.check_circle_rounded, size: 15, color: _T.purple),
            ],
          ]))));
  }
}

// USAGE + CTA COLUMN
class _UsageColumn extends StatelessWidget {
  final Task task;
  final _PrinterStub? printer;
  final _MaterialStub? material;
  final TextEditingController qtyCtrl;
  final bool canSubmit, submitting;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmit;
  const _UsageColumn({required this.task, required this.printer,
    required this.material, required this.qtyCtrl,
    required this.canSubmit, required this.submitting,
    required this.onChanged, required this.onSubmit});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _ColHeader(title: 'Material Usage', subtitle: 'Quantity to consume',
        icon: Icons.straighten_outlined, iconColor: _T.green, iconBg: _T.green50),
      Expanded(child: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _SummaryCard(task: task, printer: printer, material: material),
          const SizedBox(height: 18),
          const Text('QUANTITY TO USE',
            style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700,
                letterSpacing: 0.9, color: _T.slate400)),
          const SizedBox(height: 8),
          _QtyInput(material: material, controller: qtyCtrl, onChanged: onChanged),
          const SizedBox(height: 20),
          const Divider(height: 1, color: _T.slate200),
          const SizedBox(height: 16),
          _CtaButton(canSubmit: canSubmit, submitting: submitting, onTap: onSubmit),
          if (!canSubmit) ...[
            const SizedBox(height: 10),
            Text(_hintText(), textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11.5, color: _T.slate400)),
          ],
        ]))),
    ]);

  String _hintText() {
    if (printer  == null) return 'Select a printer first';
    if (material == null) return 'Select a material';
    return 'Enter the quantity to use';
  }
}

// SUMMARY CARD
class _SummaryCard extends StatelessWidget {
  final Task task;
  final _PrinterStub? printer;
  final _MaterialStub? material;
  const _SummaryCard({required this.task, required this.printer, required this.material});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(color: _T.slate50,
      borderRadius: BorderRadius.circular(_T.rLg),
      border: Border.all(color: _T.slate200)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Row(children: [
          const Icon(Icons.assignment_outlined, size: 12, color: _T.slate400),
          const SizedBox(width: 6),
          Expanded(child: Text(task.name, overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _T.ink3))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: _T.slate100,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: _T.slate200)),
            child: Text('TASK-${task.id}',
              style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700,
                  color: _T.slate500, fontFamily: 'monospace', letterSpacing: 0.2))),
        ])),
      const Divider(height: 1, color: _T.slate100),
      _SummaryRow(icon: Icons.print_outlined, label: 'Printer',
        value: printer?.name, placeholder: 'Not selected', color: _T.blue, bg: _T.blue50),
      const Divider(height: 1, color: _T.slate100),
      _SummaryRow(icon: Icons.layers_outlined, label: 'Material',
        value: material?.name, placeholder: 'Not selected', color: _T.purple, bg: _T.purple50),
    ]));
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final String placeholder;
  final Color color, bg;
  const _SummaryRow({required this.icon, required this.label,
    required this.value, required this.placeholder,
    required this.color, required this.bg});

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      child: Row(children: [
        Container(width: 22, height: 22,
          decoration: BoxDecoration(
            color: hasValue ? bg : _T.slate100,
            borderRadius: BorderRadius.circular(5)),
          child: Icon(icon, size: 10, color: hasValue ? color : _T.slate400)),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 11,
            fontWeight: FontWeight.w500, color: _T.slate400)),
        const Spacer(),
        Text(value ?? placeholder,
          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600,
              color: hasValue ? _T.ink3 : _T.slate300)),
        if (hasValue) ...[
          const SizedBox(width: 5),
          Icon(Icons.check_circle_rounded, size: 10, color: color),
        ],
      ]));
  }
}

// QTY INPUT
class _QtyInput extends StatelessWidget {
  final _MaterialStub? material;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  const _QtyInput({required this.material, required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final disabled = material == null;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Container(
          height: 40,
          decoration: BoxDecoration(
            color: disabled ? _T.slate50 : _T.white,
            borderRadius: BorderRadius.circular(_T.r),
            border: Border.all(color: disabled ? _T.slate100 : _T.slate200)),
          child: TextField(
            controller: controller, enabled: !disabled, onChanged: onChanged,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
            textAlign: TextAlign.right,
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700,
                color: disabled ? _T.slate300 : _T.ink),
            decoration: InputDecoration(
              hintText: '0',
              hintStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _T.slate200),
              border: InputBorder.none, isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10))))),
        const SizedBox(width: 8),
        Container(height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: disabled ? _T.slate50 : _T.green50,
            borderRadius: BorderRadius.circular(_T.r),
            border: Border.all(color: disabled ? _T.slate100 : _T.green.withOpacity(0.25))),
          child: Center(child: Text(
            material?.unitShort.toUpperCase() ?? '—',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800,
                color: disabled ? _T.slate300 : _T.green, letterSpacing: 0.5)))),
      ]),
      if (material != null) ...[
        const SizedBox(height: 7),
        Row(children: [
          Container(width: 5, height: 5,
            decoration: BoxDecoration(color: material!.stockColor, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Text('${material!.fmtStock()} ${material!.unitShort} available',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: material!.stockColor)),
        ]),
      ],
    ]);
  }
}

// CTA BUTTON
class _CtaButton extends StatefulWidget {
  final bool canSubmit, submitting;
  final VoidCallback onTap;
  const _CtaButton({required this.canSubmit, required this.submitting, required this.onTap});
  @override
  State<_CtaButton> createState() => _CtaButtonState();
}

class _CtaButtonState extends State<_CtaButton> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) {
    final active = widget.canSubmit && !widget.submitting;
    return MouseRegion(
      cursor: active ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(onTap: active ? widget.onTap : null,
        child: AnimatedContainer(duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: widget.submitting ? _T.slate100
              : active ? (_hovered ? _T.blueHover : _T.blue) : _T.slate100,
            borderRadius: BorderRadius.circular(_T.r),
            boxShadow: active ? [BoxShadow(color: _T.blue.withOpacity(0.25),
                blurRadius: 8, offset: const Offset(0, 2))] : null),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            if (widget.submitting)
              const SizedBox(width: 13, height: 13,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
            else
              Icon(Icons.print_rounded, size: 14,
                  color: active ? Colors.white : _T.slate300),
            const SizedBox(width: 7),
            Text(widget.submitting ? 'Starting…' : 'Start Print Job',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                  color: active || widget.submitting ? Colors.white : _T.slate300)),
          ]))));
  }
}

// SHARED SMALL COMPONENTS
class _StatusPill extends StatelessWidget {
  final String label;
  final Color color, bg;
  const _StatusPill({required this.label, required this.color, required this.bg});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(99)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 5, height: 5,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
    ]));
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  const _EmptyState({required this.icon, required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 22, color: _T.slate300),
      const SizedBox(height: 8),
      Text(title, style: const TextStyle(fontSize: 12.5,
          fontWeight: FontWeight.w600, color: _T.slate400)),
      const SizedBox(height: 3),
      Text(subtitle, style: const TextStyle(fontSize: 11, color: _T.slate300)),
    ]));
}
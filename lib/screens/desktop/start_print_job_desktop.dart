// ─────────────────────────────────────────────────────────────────────────────
// START PRINT JOB SCREEN
//
// Navigation:  Navigator.push(context, MaterialPageRoute(
//                builder: (_) => StartPrintJobScreen(task: task)))
//
// Sections:
//   1. App bar with task summary chip
//   2. SELECT PRINTER — scrollable horizontal cards + vertical list fallback
//   3. SELECT MATERIAL — searchable list with stock indicator
//   4. MATERIAL USAGE  — quantity input with unit label
//   5. Sticky bottom CTA — disabled until all three selections are made
//
// TODO markers show the three hook-points where you wire up your providers /
// API calls.  Everything else is pure UI.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/core/models/task.dart';

// ── Inline design tokens (matches detail_panel.dart palette) ─────────────────
class _T {
  static const blue       = Color(0xFF2563EB);
  static const blue50     = Color(0xFFEFF6FF);
  static const blue100    = Color(0xFFDBEAFE);
  static const green      = Color(0xFF10B981);
  static const green50    = Color(0xFFECFDF5);
  static const amber      = Color(0xFFF59E0B);
  static const amber50    = Color(0xFFFEF3C7);
  static const red        = Color(0xFFEF4444);
  static const red50      = Color(0xFFFEE2E2);
  static const purple     = Color(0xFF8B5CF6);
  static const purple50   = Color(0xFFF3E8FF);
  static const slate50    = Color(0xFFF8FAFC);
  static const slate100   = Color(0xFFF1F5F9);
  static const slate200   = Color(0xFFE2E8F0);
  static const slate300   = Color(0xFFCBD5E1);
  static const slate400   = Color(0xFF94A3B8);
  static const slate500   = Color(0xFF64748B);
  static const ink        = Color(0xFF0F172A);
  static const ink2       = Color(0xFF1E293B);
  static const ink3       = Color(0xFF334155);
  static const white      = Colors.white;
  static const r   = 8.0;
  static const rLg = 12.0;
  static const rXl = 16.0;
}

// ─────────────────────────────────────────────────────────────────────────────
// STUB MODELS
// Replace _PrinterStub with your real Printer model from printer.dart.
// Replace _MaterialStub with your real MaterialModel from material_model.dart.
// The fields used below map 1-to-1 with those classes.
// ─────────────────────────────────────────────────────────────────────────────

class _PrinterStub {
  final String id, name, nickname;
  final bool   isAvailable;
  final String statusLabel;
  final Color  statusColor, statusBg;
  const _PrinterStub({
    required this.id,
    required this.name,
    required this.nickname,
    required this.isAvailable,
    required this.statusLabel,
    required this.statusColor,
    required this.statusBg,
  });
}

class _MaterialStub {
  final String id, name, unitShort;
  final double currentStock, minStockLevel;
  bool get isLowStock      => currentStock < minStockLevel;
  bool get isCriticalStock => currentStock <= 0;
  Color get stockColor => isCriticalStock
      ? _T.red
      : isLowStock ? _T.amber : _T.green;
  Color get stockBg => isCriticalStock
      ? _T.red50
      : isLowStock ? _T.amber50 : _T.green50;
  String get stockLabel => isCriticalStock
      ? 'Out of stock'
      : isLowStock ? 'Low stock' : 'In stock';

  const _MaterialStub({
    required this.id,
    required this.name,
    required this.unitShort,
    required this.currentStock,
    required this.minStockLevel,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class StartPrintJobScreen extends ConsumerStatefulWidget {
  final Task task;

  const StartPrintJobScreen({super.key, required this.task});

  @override
  ConsumerState<StartPrintJobScreen> createState() =>
      _StartPrintJobScreenState();
}

class _StartPrintJobScreenState extends ConsumerState<StartPrintJobScreen> {
  // ── Selections ─────────────────────────────────────────────────────────────
  _PrinterStub?  _selectedPrinter;
  _MaterialStub? _selectedMaterial;
  final TextEditingController _qtyController = TextEditingController();
  double? get _parsedQty {
    final v = double.tryParse(_qtyController.text);
    return (v != null && v > 0) ? v : null;
  }

  bool get _canSubmit =>
      _selectedPrinter  != null &&
      _selectedMaterial != null &&
      _parsedQty        != null;

  // ── Submitting state ───────────────────────────────────────────────────────
  bool _submitting = false;

  // ── Material search ────────────────────────────────────────────────────────
  final TextEditingController _searchController = TextEditingController();
  String get _searchQuery => _searchController.text.trim().toLowerCase();

  // ── TODO: replace these stubs with your real provider data ────────────────
  // e.g. ref.watch(printerNotifierProvider).printers
  List<_PrinterStub> get _printers => const [];

  // e.g. ref.watch(materialNotifierProvider).materials
  List<_MaterialStub> get _materials => const [];

  List<_MaterialStub> get _filteredMaterials => _searchQuery.isEmpty
      ? _materials
      : _materials
          .where((m) => m.name.toLowerCase().contains(_searchQuery))
          .toList();

  // ── Submit ─────────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    if (!_canSubmit || _submitting) return;
    setState(() => _submitting = true);

    // TODO: call your API here, e.g.:
    // await ref.read(printerNotifierProvider.notifier).startPrintJob(
    //   taskId:     widget.task.id,
    //   printerId:  _selectedPrinter!.id,
    //   materialId: _selectedMaterial!.id,
    //   quantity:   _parsedQty!,
    // );

    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _T.slate50,
      body: Column(
        children: [
          _AppBar(task: widget.task),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Section 1: Printer ──────────────────────────────────
                  _SectionHeader(
                    step:     '1',
                    label:    'Select Printer',
                    subtitle: 'Choose an available printer for this job',
                    icon:     Icons.print_rounded,
                    iconColor: _T.blue,
                    iconBg:   _T.blue50,
                  ),
                  const SizedBox(height: 12),
                  _PrinterSection(
                    printers:  _printers,
                    selected:  _selectedPrinter,
                    onSelect:  (p) => setState(() => _selectedPrinter = p),
                  ),
                  const SizedBox(height: 28),

                  // ── Section 2: Material ─────────────────────────────────
                  _SectionHeader(
                    step:      '2',
                    label:     'Select Material',
                    subtitle:  'Pick the material to use for this print job',
                    icon:      Icons.layers_outlined,
                    iconColor: _T.purple,
                    iconBg:    _T.purple50,
                  ),
                  const SizedBox(height: 12),
                  _MaterialSection(
                    materials:        _filteredMaterials,
                    allMaterials:     _materials,
                    selected:         _selectedMaterial,
                    searchController: _searchController,
                    onSelect:         (m) => setState(() {
                      _selectedMaterial = m;
                      _qtyController.clear();
                    }),
                    onSearchChanged:  (_) => setState(() {}),
                  ),
                  const SizedBox(height: 28),

                  // ── Section 3: Usage quantity ───────────────────────────
                  _SectionHeader(
                    step:      '3',
                    label:     'Material Usage',
                    subtitle:  'Enter how much material will be consumed',
                    icon:      Icons.straighten_outlined,
                    iconColor: _T.green,
                    iconBg:    _T.green50,
                    disabled:  _selectedMaterial == null,
                  ),
                  const SizedBox(height: 12),
                  _UsageSection(
                    material:   _selectedMaterial,
                    controller: _qtyController,
                    onChanged:  (_) => setState(() {}),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),

      // ── Sticky bottom CTA ─────────────────────────────────────────────────
      bottomNavigationBar: _BottomBar(
        canSubmit:  _canSubmit,
        submitting: _submitting,
        onTap:      _submit,
        printer:    _selectedPrinter,
        material:   _selectedMaterial,
        qty:        _parsedQty,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// APP BAR
// ─────────────────────────────────────────────────────────────────────────────
class _AppBar extends StatelessWidget {
  final Task task;
  const _AppBar({required this.task});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color:  _T.white,
        border: Border(bottom: BorderSide(color: _T.slate200)),
      ),
      padding: EdgeInsets.only(
        top:    MediaQuery.of(context).padding.top + 8,
        left:   16,
        right:  16,
        bottom: 12,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Back button
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  border:       Border.all(color: _T.slate200),
                  borderRadius: BorderRadius.circular(_T.r),
                ),
                child: const Icon(Icons.arrow_back_rounded,
                    size: 16, color: _T.slate500),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Title
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Start Print Job',
                  style: TextStyle(
                    fontSize:   17,
                    fontWeight: FontWeight.w700,
                    color:      _T.ink,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  'Configure printer & material',
                  style: TextStyle(fontSize: 12, color: _T.slate400),
                ),
              ],
            ),
          ),

          // Task chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color:        _T.blue50,
              borderRadius: BorderRadius.circular(_T.r),
              border:       Border.all(color: _T.blue100),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.assignment_outlined,
                  size: 13, color: _T.blue),
              const SizedBox(width: 5),
              Text(
                'TASK-${task.id}',
                style: const TextStyle(
                  fontSize:      11,
                  fontWeight:    FontWeight.w700,
                  color:         _T.blue,
                  letterSpacing: 0.3,
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
// SECTION HEADER
// ─────────────────────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String    step, label, subtitle;
  final IconData  icon;
  final Color     iconColor, iconBg;
  final bool      disabled;

  const _SectionHeader({
    required this.step,
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: disabled ? 0.45 : 1.0,
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color:        iconBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: iconColor.withOpacity(0.2)),
          ),
          child: Icon(icon, size: 17, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  width: 18, height: 18,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color:        iconColor,
                    shape:        BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      step,
                      style: const TextStyle(
                        fontSize:   9.5,
                        fontWeight: FontWeight.w800,
                        color:      Colors.white,
                      ),
                    ),
                  ),
                ),
                Text(label,
                    style: const TextStyle(
                      fontSize:   14,
                      fontWeight: FontWeight.w700,
                      color:      _T.ink,
                    )),
              ]),
              const SizedBox(height: 1),
              Text(subtitle,
                  style: const TextStyle(fontSize: 11.5, color: _T.slate400)),
            ],
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PRINTER SECTION
// ─────────────────────────────────────────────────────────────────────────────
class _PrinterSection extends StatelessWidget {
  final List<_PrinterStub>          printers;
  final _PrinterStub?               selected;
  final ValueChanged<_PrinterStub>  onSelect;

  const _PrinterSection({
    required this.printers,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (printers.isEmpty) {
      return _EmptyCard(
        icon:     Icons.print_disabled_outlined,
        title:    'No printers available',
        subtitle: 'All printers are currently busy or offline',
      );
    }

    return Column(
      children: printers.map((p) {
        final isSelected = selected?.id == p.id;
        final disabled   = !p.isAvailable;
        return _PrinterCard(
          printer:    p,
          isSelected: isSelected,
          onTap: disabled ? null : () => onSelect(p),
        );
      }).toList(),
    );
  }
}

class _PrinterCard extends StatefulWidget {
  final _PrinterStub  printer;
  final bool          isSelected;
  final VoidCallback? onTap;
  const _PrinterCard({
    required this.printer,
    required this.isSelected,
    this.onTap,
  });

  @override
  State<_PrinterCard> createState() => _PrinterCardState();
}

class _PrinterCardState extends State<_PrinterCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final p        = widget.printer;
    final selected = widget.isSelected;
    final disabled = widget.onTap == null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: MouseRegion(
        cursor:  disabled ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit:  (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: disabled
                  ? _T.slate50
                  : selected
                      ? _T.blue50
                      : _hovered ? const Color(0xFFF5F9FF) : _T.white,
              borderRadius: BorderRadius.circular(_T.rLg),
              border: Border.all(
                color: disabled
                    ? _T.slate200
                    : selected
                        ? _T.blue.withOpacity(0.5)
                        : _hovered ? _T.slate300 : _T.slate200,
                width: selected ? 1.5 : 1.0,
              ),
              boxShadow: selected
                  ? [BoxShadow(
                      color:      _T.blue.withOpacity(0.08),
                      blurRadius: 10,
                      offset:     const Offset(0, 3))]
                  : null,
            ),
            child: Row(
              children: [
                // Printer icon
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    color: disabled
                        ? _T.slate100
                        : selected
                            ? _T.blue.withOpacity(0.12)
                            : _T.slate100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.print_rounded,
                    size:  20,
                    color: disabled
                        ? _T.slate300
                        : selected ? _T.blue : _T.slate500,
                  ),
                ),
                const SizedBox(width: 12),

                // Name + nickname
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.name,
                        style: TextStyle(
                          fontSize:   14,
                          fontWeight: FontWeight.w600,
                          color: disabled ? _T.slate400 : _T.ink,
                        ),
                      ),
                      if (p.nickname.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(p.nickname,
                            style: const TextStyle(
                                fontSize: 12, color: _T.slate400)),
                      ],
                    ],
                  ),
                ),

                // Status pill
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color:        p.statusBg,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                      width: 5, height: 5,
                      decoration: BoxDecoration(
                          color: p.statusColor, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      p.statusLabel,
                      style: TextStyle(
                        fontSize:   10.5,
                        fontWeight: FontWeight.w700,
                        color:      p.statusColor,
                      ),
                    ),
                  ]),
                ),

                // Check indicator
                AnimatedOpacity(
                  opacity:  selected ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 150),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: Container(
                      width: 22, height: 22,
                      decoration: BoxDecoration(
                        color:  _T.blue,
                        shape:  BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_rounded,
                          size: 12, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MATERIAL SECTION
// ─────────────────────────────────────────────────────────────────────────────
class _MaterialSection extends StatelessWidget {
  final List<_MaterialStub>          materials;
  final List<_MaterialStub>          allMaterials;
  final _MaterialStub?               selected;
  final TextEditingController        searchController;
  final ValueChanged<_MaterialStub>  onSelect;
  final ValueChanged<String>         onSearchChanged;

  const _MaterialSection({
    required this.materials,
    required this.allMaterials,
    required this.selected,
    required this.searchController,
    required this.onSelect,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search bar
        Container(
          decoration: BoxDecoration(
            color:        _T.white,
            borderRadius: BorderRadius.circular(_T.r),
            border:       Border.all(color: _T.slate200),
          ),
          child: TextField(
            controller:    searchController,
            onChanged:     onSearchChanged,
            style: const TextStyle(fontSize: 13.5, color: _T.ink),
            decoration: InputDecoration(
              hintText:        'Search materials…',
              hintStyle: const TextStyle(fontSize: 13.5, color: _T.slate300),
              prefixIcon: const Icon(Icons.search_rounded,
                  size: 18, color: _T.slate400),
              suffixIcon: searchController.text.isNotEmpty
                  ? GestureDetector(
                      onTap: () {
                        searchController.clear();
                        onSearchChanged('');
                      },
                      child: const Icon(Icons.close_rounded,
                          size: 16, color: _T.slate400),
                    )
                  : null,
              isDense:      true,
              border:       InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                  vertical: 12, horizontal: 4),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // List
        if (allMaterials.isEmpty)
          _EmptyCard(
            icon:     Icons.layers_clear_outlined,
            title:    'No materials found',
            subtitle: 'Add materials to your inventory first',
          )
        else if (materials.isEmpty)
          _EmptyCard(
            icon:     Icons.search_off_rounded,
            title:    'No results',
            subtitle: 'Try a different search term',
          )
        else
          Column(
            children: materials.map((m) {
              final isSelected = selected?.id == m.id;
              final disabled   = m.isCriticalStock;
              return _MaterialRow(
                material:   m,
                isSelected: isSelected,
                onTap: disabled ? null : () => onSelect(m),
              );
            }).toList(),
          ),
      ],
    );
  }
}

class _MaterialRow extends StatefulWidget {
  final _MaterialStub  material;
  final bool           isSelected;
  final VoidCallback?  onTap;
  const _MaterialRow({
    required this.material,
    required this.isSelected,
    this.onTap,
  });

  @override
  State<_MaterialRow> createState() => _MaterialRowState();
}

class _MaterialRowState extends State<_MaterialRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final m        = widget.material;
    final selected = widget.isSelected;
    final disabled = widget.onTap == null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: MouseRegion(
        cursor:  disabled ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit:  (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: disabled
                  ? _T.slate50
                  : selected
                      ? _T.purple50
                      : _hovered ? const Color(0xFFFBF8FF) : _T.white,
              borderRadius: BorderRadius.circular(_T.rLg),
              border: Border.all(
                color: disabled
                    ? _T.slate100
                    : selected
                        ? _T.purple.withOpacity(0.45)
                        : _hovered ? _T.slate300 : _T.slate200,
                width: selected ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              children: [
                // Material icon
                Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: disabled
                        ? _T.slate100
                        : selected
                            ? _T.purple.withOpacity(0.12)
                            : _T.slate100,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(Icons.layers_outlined,
                      size: 17,
                      color: disabled
                          ? _T.slate300
                          : selected ? _T.purple : _T.slate500),
                ),
                const SizedBox(width: 12),

                // Name + stock
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        m.name,
                        style: TextStyle(
                          fontSize:   13.5,
                          fontWeight: FontWeight.w600,
                          color: disabled ? _T.slate400 : _T.ink,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(children: [
                        Text(
                          '${m.currentStock.toStringAsFixed(m.currentStock.truncateToDouble() == m.currentStock ? 0 : 2)} ${m.unitShort} available',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: disabled ? _T.slate300 : _T.slate400,
                          ),
                        ),
                      ]),
                    ],
                  ),
                ),

                // Stock status pill
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color:        m.stockBg,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                      width: 5, height: 5,
                      decoration: BoxDecoration(
                          color: m.stockColor, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 4),
                    Text(m.stockLabel,
                        style: TextStyle(
                            fontSize:   10.5,
                            fontWeight: FontWeight.w700,
                            color:      m.stockColor)),
                  ]),
                ),

                // Check
                AnimatedOpacity(
                  opacity:  selected ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 150),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Container(
                      width: 20, height: 20,
                      decoration: const BoxDecoration(
                          color: _T.purple, shape: BoxShape.circle),
                      child: const Icon(Icons.check_rounded,
                          size: 11, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// USAGE / QUANTITY SECTION
// ─────────────────────────────────────────────────────────────────────────────
class _UsageSection extends StatelessWidget {
  final _MaterialStub?        material;
  final TextEditingController controller;
  final ValueChanged<String>  onChanged;

  const _UsageSection({
    required this.material,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = material == null;

    return AnimatedOpacity(
      opacity:  disabled ? 0.4 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: Container(
        decoration: BoxDecoration(
          color:        _T.white,
          borderRadius: BorderRadius.circular(_T.rLg),
          border: Border.all(
            color: disabled ? _T.slate100 : _T.slate200,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Row(children: [
                Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(
                    color:        disabled ? _T.slate100 : _T.green50,
                    borderRadius: BorderRadius.circular(9),
                    border: disabled
                        ? null
                        : Border.all(color: _T.green.withOpacity(0.2)),
                  ),
                  child: Icon(Icons.straighten_outlined,
                      size: 16,
                      color: disabled ? _T.slate300 : _T.green),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Quantity to Use',
                        style: TextStyle(
                          fontSize:   13,
                          fontWeight: FontWeight.w700,
                          color:      _T.ink,
                        )),
                    Text(
                      material != null
                          ? 'Measured in ${material!.unitShort}'
                          : 'Select a material first',
                      style: const TextStyle(
                          fontSize: 11, color: _T.slate400),
                    ),
                  ],
                ),
              ]),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child:   Divider(height: 1, color: _T.slate100),
            ),

            // Input row
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Numeric field
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color:        disabled ? _T.slate50 : _T.white,
                        borderRadius: BorderRadius.circular(_T.r),
                        border: Border.all(
                          color: disabled ? _T.slate100 : _T.slate200,
                        ),
                      ),
                      child: TextField(
                        controller:  controller,
                        enabled:     !disabled,
                        onChanged:   onChanged,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d*')),
                        ],
                        style: const TextStyle(
                          fontSize:   22,
                          fontWeight: FontWeight.w700,
                          color:      _T.ink,
                        ),
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          hintText:  '0',
                          hintStyle: const TextStyle(
                            fontSize:   22,
                            fontWeight: FontWeight.w700,
                            color:      _T.slate200,
                          ),
                          border:        InputBorder.none,
                          isDense:       true,
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 12),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Unit label badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      color:        disabled ? _T.slate50 : _T.green50,
                      borderRadius: BorderRadius.circular(_T.r),
                      border: Border.all(
                        color: disabled
                            ? _T.slate100
                            : _T.green.withOpacity(0.25),
                      ),
                    ),
                    child: Text(
                      material?.unitShort.toUpperCase() ?? '—',
                      style: TextStyle(
                        fontSize:      16,
                        fontWeight:    FontWeight.w800,
                        color: disabled ? _T.slate300 : _T.green,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Available stock note
            if (material != null)
              Container(
                decoration: const BoxDecoration(
                  color:  _T.slate50,
                  border: Border(top: BorderSide(color: _T.slate100)),
                  borderRadius: BorderRadius.only(
                    bottomLeft:  Radius.circular(_T.rLg),
                    bottomRight: Radius.circular(_T.rLg),
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                child: Row(children: [
                  Icon(Icons.inventory_2_outlined,
                      size: 12, color: material!.stockColor),
                  const SizedBox(width: 6),
                  Text(
                    'Available: ${material!.currentStock.toStringAsFixed(material!.currentStock.truncateToDouble() == material!.currentStock ? 0 : 2)} ${material!.unitShort}',
                    style: TextStyle(
                      fontSize:   11.5,
                      fontWeight: FontWeight.w500,
                      color:      material!.stockColor,
                    ),
                  ),
                ]),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BOTTOM BAR / CTA
// ─────────────────────────────────────────────────────────────────────────────
class _BottomBar extends StatelessWidget {
  final bool            canSubmit;
  final bool            submitting;
  final VoidCallback    onTap;
  final _PrinterStub?   printer;
  final _MaterialStub?  material;
  final double?         qty;

  const _BottomBar({
    required this.canSubmit,
    required this.submitting,
    required this.onTap,
    required this.printer,
    required this.material,
    required this.qty,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: const BoxDecoration(
        color:  _T.white,
        border: Border(top: BorderSide(color: _T.slate200)),
      ),
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomPad),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Summary chips row (visible once selections are made)
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve:    Curves.easeOutCubic,
            child: (printer != null || material != null || qty != null)
                ? Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Wrap(
                      spacing:    8,
                      runSpacing: 6,
                      children: [
                        if (printer != null)
                          _SummaryChip(
                            icon:  Icons.print_rounded,
                            label: printer!.name,
                            color: _T.blue,
                            bg:    _T.blue50,
                          ),
                        if (material != null)
                          _SummaryChip(
                            icon:  Icons.layers_outlined,
                            label: material!.name,
                            color: _T.purple,
                            bg:    _T.purple50,
                          ),
                        if (qty != null && material != null)
                          _SummaryChip(
                            icon:  Icons.straighten_outlined,
                            label: '${qty!.toStringAsFixed(qty!.truncateToDouble() == qty ? 0 : 2)} ${material!.unitShort}',
                            color: _T.green,
                            bg:    _T.green50,
                          ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          // Submit button
          MouseRegion(
            cursor: canSubmit && !submitting
                ? SystemMouseCursors.click
                : SystemMouseCursors.forbidden,
            child: GestureDetector(
              onTap: (canSubmit && !submitting) ? onTap : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width:   double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: canSubmit && !submitting
                      ? _T.blue
                      : _T.slate100,
                  borderRadius: BorderRadius.circular(_T.rLg),
                  boxShadow: canSubmit && !submitting
                      ? [BoxShadow(
                          color:      _T.blue.withOpacity(0.28),
                          blurRadius: 12,
                          offset:     const Offset(0, 4))]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (submitting)
                      const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white),
                      )
                    else
                      Icon(Icons.print_rounded,
                          size:  17,
                          color: canSubmit ? Colors.white : _T.slate300),
                    const SizedBox(width: 9),
                    Text(
                      submitting ? 'Starting…' : 'Start Print Job',
                      style: TextStyle(
                        fontSize:   14.5,
                        fontWeight: FontWeight.w700,
                        color:      canSubmit && !submitting
                            ? Colors.white
                            : _T.slate400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Hint text when not all selections are done
          if (!canSubmit) ...[
            const SizedBox(height: 10),
            Text(
              _hintText(printer, material, qty),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: _T.slate400),
            ),
          ],
        ],
      ),
    );
  }

  String _hintText(
      _PrinterStub? p, _MaterialStub? m, double? q) {
    if (p == null) return 'Select a printer to continue';
    if (m == null) return 'Select a material to continue';
    if (q == null) return 'Enter the quantity to use';
    return '';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SUMMARY CHIP
// ─────────────────────────────────────────────────────────────────────────────
class _SummaryChip extends StatelessWidget {
  final IconData icon;
  final String   label;
  final Color    color, bg;
  const _SummaryChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color:        bg,
      borderRadius: BorderRadius.circular(99),
      border:       Border.all(color: color.withOpacity(0.25)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 11, color: color),
      const SizedBox(width: 5),
      Text(label,
          style: TextStyle(
            fontSize:   11.5,
            fontWeight: FontWeight.w600,
            color:      color,
          )),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// EMPTY STATE CARD
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String   title, subtitle;
  const _EmptyCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 28),
    decoration: BoxDecoration(
      color:        _T.slate50,
      borderRadius: BorderRadius.circular(_T.rLg),
      border:       Border.all(color: _T.slate200),
    ),
    child: Column(children: [
      Icon(icon, size: 26, color: _T.slate300),
      const SizedBox(height: 10),
      Text(title,
          style: const TextStyle(
              fontSize:   13.5,
              fontWeight: FontWeight.w600,
              color:      _T.slate400)),
      const SizedBox(height: 3),
      Text(subtitle,
          style: const TextStyle(fontSize: 12, color: _T.slate300)),
    ]),
  );
}
// DesktopMaterialsManagementScreen
// ─────────────────────────────────────────────────────────────────────────────
// materials_screen.dart  (Desktop)
//
// Corporate-grade stock management screen aligned with the existing desktop
// design system.  Layout: toolbar + searchable materials table on the left,
// sliding stock-entry panel on the right (same split-panel pattern as the
// task detail panel).
//
// Data logic preserved from the mobile MaterialsScreen / StockEntryScreen.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/core/models/material.dart';
import 'package:smooflow/core/models/stock_transaction.dart';
import 'package:smooflow/providers/material_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TOKENS — matches existing desktop _T class exactly
// ─────────────────────────────────────────────────────────────────────────────
class _T {
  static const blue      = Color(0xFF2563EB);
  static const blue50    = Color(0xFFEFF6FF);
  static const green     = Color(0xFF10B981);
  static const green50   = Color(0xFFECFDF5);
  static const amber     = Color(0xFFF59E0B);
  static const amber50   = Color(0xFFFEF3C7);
  static const red       = Color(0xFFEF4444);
  static const red50     = Color(0xFFFEE2E2);
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
}

// ─────────────────────────────────────────────────────────────────────────────
// LAYOUT CONSTANTS
// ─────────────────────────────────────────────────────────────────────────────
const double _kRowHPad      = 16.0;
const double _kCellHPad     = 6.0;
const double _kPanelWidth   = 380.0;
const _kPanelDuration       = Duration(milliseconds: 260);

// ─────────────────────────────────────────────────────────────────────────────
// ENTRY MODE
// ─────────────────────────────────────────────────────────────────────────────
enum _EntryMode { stockIn, stockOut }

// ─────────────────────────────────────────────────────────────────────────────
// MATERIALS SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class DesktopMaterialsManagementScreen extends ConsumerStatefulWidget {
  const DesktopMaterialsManagementScreen({super.key});

  @override
  ConsumerState<DesktopMaterialsManagementScreen> createState() =>
      _DesktopMaterialsScreenState();
}

class _DesktopMaterialsScreenState
    extends ConsumerState<DesktopMaterialsManagementScreen> {
  final _searchController = TextEditingController();
  String _searchQuery   = '';
  String _filterMode    = 'All'; // 'All' | 'Low Stock'

  MaterialModel? _selectedMaterial;
  _EntryMode?    _entryMode;        // null = panel closed

  bool get _panelOpen => _entryMode != null;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
    Future.microtask(() =>
        ref.read(materialNotifierProvider.notifier).fetchMaterials());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Derived lists ──────────────────────────────────────────────────────────
  List<MaterialModel> get _allMaterials =>
      ref.watch(materialNotifierProvider).materials;

  List<MaterialModel> get _filteredMaterials {
    var list = _allMaterials;
    if (_filterMode == 'Low Stock') {
      list = list.where((m) => m.isLowStock).toList();
    }
    if (_searchQuery.isNotEmpty) {
      list = list
          .where((m) =>
              m.name.toLowerCase().contains(_searchQuery) ||
              (m.description?.toLowerCase().contains(_searchQuery) ?? false))
          .toList();
    }
    return list;
  }

  // ── Panel control ──────────────────────────────────────────────────────────
  void _openPanel(MaterialModel material, _EntryMode mode) {
    setState(() {
      _selectedMaterial = material;
      _entryMode        = mode;
    });
  }

  void _closePanel() => setState(() => _entryMode = null);

  void _onEntryComplete() {
    _closePanel();
    ref.read(materialNotifierProvider.notifier).fetchMaterials();
  }

  // ── CSV Import ─────────────────────────────────────────────────────────────
  Future<void> _importCSV() async {
    final result = await FilePicker.platform
        .pickFiles(type: FileType.custom, allowedExtensions: ['csv']);
    if (result == null || result.files.isEmpty) return;

    if (!mounted) return;
    _showLoadingDialog();

    final file      = File(result.files.single.path!);
    final csvString = await file.readAsString();
    final csvData   = const CsvToListConverter()
        .convert(csvString, eol: '\n', shouldParseNumbers: false);

    if (!mounted) return;
    Navigator.pop(context); // close loading

    if (csvData.isEmpty) {
      _showMessage('Empty file', 'The CSV file contains no data.', isError: true);
      return;
    }

    final materials = _parseCSV(csvData);
    if (materials.isEmpty) return;

    await ref.read(materialNotifierProvider.notifier).createMaterials(materials);
    if (!mounted) return;
    _showMessage(
      'Import complete',
      '${materials.length} material${materials.length == 1 ? '' : 's'} imported successfully.',
    );
  }

  List<MaterialModel> _parseCSV(List<List<dynamic>> data) {
    final headers =
        data[0].map((h) => h.toString().toLowerCase().trim()).toList();
    int _idx(List<String> names) {
      for (final n in names) {
        final i = headers.indexWhere((h) => h == n);
        if (i != -1) return i;
      }
      return -1;
    }
    final nameIdx    = _idx(['name']);
    final typeIdx    = _idx(['measure type','measuretype','measure_type','type']);
    final descIdx    = _idx(['description','desc']);
    final minStockIdx= _idx(['min stock level','min_stock_level','min stock','minstock']);

    if (nameIdx == -1 || typeIdx == -1) {
      _showMessage('Missing columns',
          'CSV must have "name" and "measure type" columns.', isError: true);
      return [];
    }

    final results  = <MaterialModel>[];
    final errors   = <String>[];

    for (int i = 1; i < data.length; i++) {
      final row = data[i];
      if (row.isEmpty || row.every((c) => c.toString().trim().isEmpty)) continue;
      String? cell(int idx) =>
          (idx == -1 || idx >= row.length) ? null : row[idx]?.toString();

      final name = cell(nameIdx)?.trim();
      if (name == null || name.isEmpty) {
        errors.add('Row ${i + 1}: name required'); continue;
      }
      final typeStr = cell(typeIdx)?.toLowerCase().trim();
      final type    = _parseMeasureType(typeStr ?? '');
      if (type == null) {
        errors.add('Row ${i + 1}: invalid measure type "$typeStr"'); continue;
      }
      final minStock = double.tryParse(cell(minStockIdx) ?? '') ?? 0.0;
      results.add(MaterialModel.create(
        name:          name,
        description:   cell(descIdx)?.trim(),
        measureType:   type,
        minStockLevel: minStock,
      ));
    }

    if (errors.isNotEmpty && mounted) {
      _showMessage('${errors.length} rows skipped',
          errors.take(5).join('\n') +
              (errors.length > 5 ? '\n…and ${errors.length - 5} more' : ''),
          isError: true);
    }
    return results;
  }

  MeasureType? _parseMeasureType(String v) {
    final s = v.replaceAll(' ', '_');
    return switch (s) {
      'running_meter' || 'runningmeter'   => MeasureType.running_meter,
      'item_quantity' || 'itemquantity'
          || 'quantity'                   => MeasureType.item_quantity,
      'liters' || 'liter' || 'l'         => MeasureType.liters,
      'kilograms' || 'kilogram' || 'kg'  => MeasureType.kilograms,
      'square_meter' || 'squaremeter'
          || 'sqm'                        => MeasureType.square_meter,
      _ => null,
    };
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: _T.blue),
      ),
    );
  }

  void _showMessage(String title, String body, {bool isError = false}) {
    showDialog(
      context: context,
      builder: (_) => _MessageDialog(title: title, body: body, isError: isError),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final state    = ref.watch(materialNotifierProvider);
    final loading  = state.isLoading;
    final materials = _filteredMaterials;
    final lowCount  = _allMaterials.where((m) => m.isLowStock).length;

    return Scaffold(
      backgroundColor: _T.slate50,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Page header ───────────────────────────────────────────────────
          _PageHeader(
            totalCount:  _allMaterials.length,
            lowCount:    lowCount,
            filterMode:  _filterMode,
            searchCtrl:  _searchController,
            onFilter:    (f) => setState(() => _filterMode = f),
            onImport:    _importCSV,
          ),

          // ── Main content ──────────────────────────────────────────────────
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Materials table ────────────────────────────────────────
                Expanded(
                  child: loading
                      ? const _LoadingState()
                      : materials.isEmpty
                          ? _EmptyState(hasFilter: _filterMode != 'All' || _searchQuery.isNotEmpty)
                          : _MaterialsTable(
                              materials:       materials,
                              selectedId:      _selectedMaterial?.id,
                              panelOpen:       _panelOpen,
                              entryMode:       _entryMode,
                              onStockIn:  (m) => _openPanel(m, _EntryMode.stockIn),
                              onStockOut: (m) => _openPanel(m, _EntryMode.stockOut),
                            ),
                ),

                // ── Sliding stock-entry panel ──────────────────────────────
                AnimatedContainer(
                  duration: _kPanelDuration,
                  curve:    Curves.easeInOut,
                  width:    _panelOpen ? _kPanelWidth : 0,
                  child: _panelOpen && _selectedMaterial != null
                      ? _StockEntryPanel(
                          key:      ValueKey('${_selectedMaterial!.id}_${_entryMode!.name}'),
                          material: _selectedMaterial!,
                          mode:     _entryMode!,
                          onClose:  _closePanel,
                          onSubmit: _onEntryComplete,
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PAGE HEADER
// ─────────────────────────────────────────────────────────────────────────────
class _PageHeader extends StatelessWidget {
  final int totalCount;
  final int lowCount;
  final String filterMode;
  final TextEditingController searchCtrl;
  final void Function(String) onFilter;
  final VoidCallback onImport;

  const _PageHeader({
    required this.totalCount,
    required this.lowCount,
    required this.filterMode,
    required this.searchCtrl,
    required this.onFilter,
    required this.onImport,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _T.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Title bar ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 20, 0),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: _T.blue50,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: _T.blue.withOpacity(0.2)),
                  ),
                  child: const Icon(Icons.inventory_2_outlined, size: 17, color: _T.blue),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Materials',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _T.ink)),
                    Text('$totalCount items · $lowCount low stock',
                        style: const TextStyle(fontSize: 11.5, color: _T.slate400)),
                  ],
                ),
                const Spacer(),
                // Import CSV button
                _HeaderButton(
                  icon: Icons.upload_file_outlined,
                  label: 'Import CSV',
                  onTap: onImport,
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ── Toolbar: search + filter tabs ────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 20, 0),
            child: Row(
              children: [
                // Search
                _SearchField(controller: searchCtrl),
                const SizedBox(width: 16),
                // Filter tabs
                _FilterTab(label: 'All',       count: totalCount,   active: filterMode == 'All',       onTap: () => onFilter('All')),
                const SizedBox(width: 2),
                _FilterTab(label: 'Low Stock', count: lowCount,     active: filterMode == 'Low Stock', onTap: () => onFilter('Low Stock'),
                    accentColor: _T.red),
              ],
            ),
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, thickness: 1, color: _T.slate200),
        ],
      ),
    );
  }
}

class _HeaderButton extends StatefulWidget {
  final IconData icon;
  final String   label;
  final VoidCallback onTap;

  const _HeaderButton({required this.icon, required this.label, required this.onTap});

  @override
  State<_HeaderButton> createState() => _HeaderButtonState();
}

class _HeaderButtonState extends State<_HeaderButton> {
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color:        _hovered ? _T.slate50 : _T.white,
          border:       Border.all(color: _hovered ? _T.slate300 : _T.slate200),
          borderRadius: BorderRadius.circular(_T.r),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(widget.icon, size: 14, color: _T.slate500),
          const SizedBox(width: 6),
          Text(widget.label, style: const TextStyle(
            fontSize: 12, fontWeight: FontWeight.w600, color: _T.ink3,
          )),
        ]),
      ),
    ),
  );
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  const _SearchField({required this.controller});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 240,
    height: 32,
    child: TextField(
      controller: controller,
      style: const TextStyle(fontSize: 12.5, color: _T.ink),
      decoration: InputDecoration(
        hintText:    'Search materials…',
        hintStyle:   const TextStyle(fontSize: 12.5, color: _T.slate400),
        prefixIcon:  const Icon(Icons.search_rounded, size: 15, color: _T.slate400),
        prefixIconConstraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        filled:      true,
        fillColor:   _T.slate50,
        border:      OutlineInputBorder(
          borderRadius: BorderRadius.circular(_T.r),
          borderSide:   const BorderSide(color: _T.slate200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_T.r),
          borderSide:   const BorderSide(color: _T.slate200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_T.r),
          borderSide:   const BorderSide(color: _T.blue, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
      ),
    ),
  );
}

class _FilterTab extends StatelessWidget {
  final String    label;
  final int       count;
  final bool      active;
  final Color     accentColor;
  final VoidCallback onTap;

  const _FilterTab({
    required this.label,
    required this.count,
    required this.active,
    required this.onTap,
    this.accentColor = _T.blue,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 130),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? accentColor.withOpacity(0.07) : Colors.transparent,
          borderRadius: BorderRadius.circular(_T.r),
          border: Border.all(
            color: active ? accentColor.withOpacity(0.25) : Colors.transparent,
          ),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(label, style: TextStyle(
            fontSize:   12,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color:      active ? accentColor : _T.slate500,
          )),
          if (count > 0) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color:        active ? accentColor : _T.slate200,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text('$count', style: TextStyle(
                fontSize:   9.5, fontWeight: FontWeight.w800,
                color:      active ? Colors.white : _T.slate500,
              )),
            ),
          ],
        ]),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// MATERIALS TABLE
// ─────────────────────────────────────────────────────────────────────────────

// Column definitions
class _Col {
  final String   id;
  final String   label;
  final int      flex;
  const _Col(this.id, this.label, this.flex);
}

const _kTableCols = [
  _Col('name',       'MATERIAL',      4),
  _Col('unit',       'UNIT',          1),
  _Col('stock',      'CURRENT STOCK', 2),
  _Col('min',        'MIN LEVEL',     2),
  _Col('status',     'STATUS',        2),
  _Col('created',    'ADDED',         2),
];

class _MaterialsTable extends StatelessWidget {
  final List<MaterialModel>           materials;
  final String?                       selectedId;
  final bool                          panelOpen;
  final _EntryMode?                   entryMode;
  final void Function(MaterialModel)  onStockIn;
  final void Function(MaterialModel)  onStockOut;

  const _MaterialsTable({
    required this.materials,
    required this.selectedId,
    required this.panelOpen,
    required this.entryMode,
    required this.onStockIn,
    required this.onStockOut,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Column headers ────────────────────────────────────────────────
        Container(
          color: _T.white,
          padding: const EdgeInsets.symmetric(horizontal: _kRowHPad, vertical: 8),
          child: LayoutBuilder(
            builder: (_, constraints) => _ColHeaderRow(
              availWidth: constraints.maxWidth,
              panelOpen:  panelOpen,
            ),
          ),
        ),
        const Divider(height: 1, thickness: 1, color: _T.slate200),

        // ── Data rows ─────────────────────────────────────────────────────
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: _kRowHPad, vertical: 6),
            itemCount:        materials.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, thickness: 1, color: _T.slate100),
            itemBuilder: (_, i) => _MaterialRow(
              material:   materials[i],
              isSelected: materials[i].id == selectedId,
              panelOpen:  panelOpen,
              activeMode: materials[i].id == selectedId ? entryMode : null,
              onStockIn:  () => onStockIn(materials[i]),
              onStockOut: () => onStockOut(materials[i]),
            ),
          ),
        ),
      ],
    );
  }
}

class _ColHeaderRow extends StatelessWidget {
  final double availWidth;
  final bool   panelOpen;
  const _ColHeaderRow({required this.availWidth, required this.panelOpen});

  @override
  Widget build(BuildContext context) {
    // Reserve space for the action buttons column
    const actionW = 148.0;
    final flexW   = availWidth - actionW;
    final totalFlex = _kTableCols.fold<int>(0, (s, c) => s + c.flex);

    return Row(
      children: [
        ..._kTableCols.map((c) => SizedBox(
          width: (c.flex / totalFlex) * flexW,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: _kCellHPad),
            child: Text(c.label,
              style: const TextStyle(
                fontSize:      10.5,
                fontWeight:    FontWeight.w700,
                letterSpacing: 0.7,
                color:         _T.slate400,
              ),
            ),
          ),
        )),
        const SizedBox(width: actionW),
      ],
    );
  }
}

class _MaterialRow extends StatefulWidget {
  final MaterialModel material;
  final bool          isSelected;
  final bool          panelOpen;
  final _EntryMode?   activeMode;
  final VoidCallback  onStockIn;
  final VoidCallback  onStockOut;

  const _MaterialRow({
    required this.material,
    required this.isSelected,
    required this.panelOpen,
    required this.activeMode,
    required this.onStockIn,
    required this.onStockOut,
  });

  @override
  State<_MaterialRow> createState() => _MaterialRowState();
}

class _MaterialRowState extends State<_MaterialRow> {
  bool _hovered = false;

  String _fmt(DateTime d) {
    final now = DateTime.now();
    if (d.year == now.year) return '${_kMonths[d.month - 1]} ${d.day}';
    return '${_kMonths[d.month - 1]} ${d.day}, ${d.year}';
  }

  static const _kMonths = [
    'Jan','Feb','Mar','Apr','May','Jun',
    'Jul','Aug','Sep','Oct','Nov','Dec',
  ];

  String _measureLabel(MeasureType t) =>
      t.name.replaceAll('_', ' ').split(' ')
          .map((w) => w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1))
          .join(' ');

  @override
  Widget build(BuildContext context) {
    final m   = widget.material;
    final low = m.isLowStock;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        decoration: BoxDecoration(
          color: widget.isSelected
              ? _T.blue50
              : (_hovered ? _T.slate50 : _T.white),
          borderRadius: BorderRadius.circular(_T.r),
          border: Border.all(
            color: widget.isSelected
                ? _T.blue.withOpacity(0.2)
                : Colors.transparent,
          ),
        ),
        child: LayoutBuilder(
          builder: (_, constraints) {
            const actionW   = 148.0;
            final flexW     = constraints.maxWidth - actionW;
            final totalFlex = _kTableCols.fold<int>(0, (s, c) => s + c.flex);

            Widget cell(String id) {
              return switch (id) {
                'name' => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment:  MainAxisAlignment.center,
                  children: [
                    Text(m.name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600, color: _T.ink,
                      ),
                    ),
                    if (m.description != null && m.description!.isNotEmpty)
                      Text(m.description!,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, color: _T.slate400),
                      ),
                  ],
                ),
                'unit' => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color:        _T.slate100,
                    borderRadius: BorderRadius.circular(4),
                    border:       Border.all(color: _T.slate200),
                  ),
                  child: Text(m.unit,
                    style: const TextStyle(
                      fontSize: 10.5, fontWeight: FontWeight.w600,
                      color: _T.ink3, fontFamily: 'monospace',
                    ),
                  ),
                ),
                'stock' => Text(
                  m.currentStock.toStringAsFixed(
                      m.currentStock == m.currentStock.floorToDouble() ? 0 : 2),
                  style: TextStyle(
                    fontSize:   13,
                    fontWeight: FontWeight.w700,
                    color:      low ? _T.red : _T.ink,
                  ),
                ),
                'min' => Text(
                  m.minStockLevel.toStringAsFixed(
                      m.minStockLevel == m.minStockLevel.floorToDouble() ? 0 : 2),
                  style: const TextStyle(fontSize: 12.5, color: _T.slate500),
                ),
                'status' => _StockStatusPill(isLow: low),
                'created' => Text(_fmt(m.createdAt),
                  style: const TextStyle(fontSize: 12, color: _T.slate500)),
                _ => const SizedBox.shrink(),
              };
            }

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  ..._kTableCols.map((c) => SizedBox(
                    width: (c.flex / totalFlex) * flexW,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: _kCellHPad),
                      child: cell(c.id),
                    ),
                  )),
                  // ── Action buttons ──────────────────────────────────────
                  SizedBox(
                    width: actionW,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _ActionButton(
                          label:   'Stock In',
                          icon:    Icons.add_rounded,
                          color:   _T.green,
                          bgColor: _T.green50,
                          active:  widget.activeMode == _EntryMode.stockIn,
                          onTap:   widget.onStockIn,
                        ),
                        const SizedBox(width: 6),
                        _ActionButton(
                          label:   'Stock Out',
                          icon:    Icons.remove_rounded,
                          color:   _T.red,
                          bgColor: _T.red50,
                          active:  widget.activeMode == _EntryMode.stockOut,
                          onTap:   widget.onStockOut,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _StockStatusPill extends StatelessWidget {
  final bool isLow;
  const _StockStatusPill({required this.isLow});

  @override
  Widget build(BuildContext context) {
    final color = isLow ? _T.red    : _T.green;
    final bg    = isLow ? _T.red50  : _T.green50;
    final label = isLow ? 'Low'     : 'OK';
    final icon  = isLow ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color:        bg,
        border:       Border.all(color: color.withOpacity(0.25)),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(
          fontSize: 11, fontWeight: FontWeight.w600, color: color,
        )),
      ]),
    );
  }
}

class _ActionButton extends StatefulWidget {
  final String   label;
  final IconData icon;
  final Color    color;
  final Color    bgColor;
  final bool     active;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.active,
    required this.onTap,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
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
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: widget.active || _hovered
              ? widget.bgColor
              : Colors.transparent,
          border: Border.all(
            color: widget.active
                ? widget.color.withOpacity(0.35)
                : (_hovered ? widget.color.withOpacity(0.2) : _T.slate200),
          ),
          borderRadius: BorderRadius.circular(_T.r),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(widget.icon, size: 12,
              color: widget.active || _hovered ? widget.color : _T.slate400),
          const SizedBox(width: 4),
          Text(widget.label, style: TextStyle(
            fontSize:   11,
            fontWeight: FontWeight.w600,
            color:      widget.active || _hovered ? widget.color : _T.slate500,
          )),
        ]),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// STOCK ENTRY PANEL
//
// Slides in from the right — same split-panel pattern as the task detail panel.
// Handles both Stock In and Stock Out in a single widget, driven by `mode`.
// ─────────────────────────────────────────────────────────────────────────────
class _StockEntryPanel extends ConsumerStatefulWidget {
  final MaterialModel material;
  final _EntryMode    mode;
  final VoidCallback  onClose;
  final VoidCallback  onSubmit;

  const _StockEntryPanel({
    super.key,
    required this.material,
    required this.mode,
    required this.onClose,
    required this.onSubmit,
  });

  @override
  ConsumerState<_StockEntryPanel> createState() => _StockEntryPanelState();
}

class _StockEntryPanelState extends ConsumerState<_StockEntryPanel> {
  final _qtyController   = TextEditingController();
  final _notesController = TextEditingController();
  final _formKey         = GlobalKey<FormState>();

  bool _submitting = false;

  bool get _isStockIn => widget.mode == _EntryMode.stockIn;

  @override
  void dispose() {
    _qtyController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _measureLabel(MeasureType t) =>
      t.name.replaceAll('_', ' ').split(' ')
          .map((w) => w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1))
          .join(' ');

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    final qty = double.parse(_qtyController.text.trim());

    try {
      if (_isStockIn) {
        await ref.read(materialNotifierProvider.notifier)
            .stockIn(widget.material.id, qty);
      } else {
        // Stock out uses barcode of the most recent stock-in transaction.
        // Fall back to a direct stock-out by material id if barcode unavailable.
        // Adapt to match your actual provider API:
        await ref.read(materialNotifierProvider.notifier)
            .stockOut(widget.material.barcode ?? widget.material.id, qty);
      }
      if (mounted) widget.onSubmit();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed: $e'),
          backgroundColor: _T.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // ── Computed stock preview ─────────────────────────────────────────────────
  double? get _previewQty {
    final v = double.tryParse(_qtyController.text.trim());
    if (v == null || v <= 0) return null;
    return _isStockIn
        ? widget.material.currentStock + v
        : widget.material.currentStock - v;
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final m        = widget.material;
    final preview  = _previewQty;
    final willLow  = preview != null && preview < m.minStockLevel;
    final willNeg  = preview != null && preview < 0;

    final modeColor  = _isStockIn ? _T.green  : _T.red;
    final modeBg     = _isStockIn ? _T.green50 : _T.red50;
    final modeLabel  = _isStockIn ? 'Stock In' : 'Stock Out';
    final modeIcon   = _isStockIn ? Icons.add_rounded : Icons.remove_rounded;

    return Container(
      width:       _kPanelWidth,
      decoration:  const BoxDecoration(
        color: _T.white,
        border: Border(left: BorderSide(color: _T.slate200)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Panel header ───────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 14),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: _T.slate100)),
              ),
              child: Row(children: [
                Container(
                  width: 30, height: 30,
                  decoration: BoxDecoration(
                    color:        modeBg,
                    borderRadius: BorderRadius.circular(8),
                    border:       Border.all(color: modeColor.withOpacity(0.25)),
                  ),
                  child: Icon(modeIcon, size: 15, color: modeColor),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(modeLabel, style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700, color: _T.ink,
                    )),
                    Text(m.name, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11.5, color: _T.slate400)),
                  ]),
                ),
                GestureDetector(
                  onTap: widget.onClose,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Container(
                      width: 26, height: 26,
                      decoration: BoxDecoration(
                        color: _T.slate100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.close_rounded, size: 14, color: _T.slate400),
                    ),
                  ),
                ),
              ]),
            ),

            // ── Scrollable body ────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // ── Material summary card ────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color:        _T.slate50,
                        borderRadius: BorderRadius.circular(_T.r),
                        border:       Border.all(color: _T.slate200),
                      ),
                      child: Column(children: [
                        _SummaryRow(
                          label: 'Current stock',
                          value: '${m.currentStock} ${m.unit}',
                          valueStyle: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700,
                            color: m.isLowStock ? _T.red : _T.ink,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _SummaryRow(
                          label: 'Minimum level',
                          value: '${m.minStockLevel} ${m.unit}',
                        ),
                        const SizedBox(height: 8),
                        _SummaryRow(
                          label: 'Measure type',
                          value: _measureLabel(m.measureType),
                        ),
                      ]),
                    ),

                    const SizedBox(height: 20),

                    // ── Quantity input ────────────────────────────────────
                    _FieldLabel('Quantity *'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller:  _qtyController,
                      onChanged:   (_) => setState(() {}),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600, color: _T.ink,
                      ),
                      decoration: _inputDecoration(
                        hint:    '0.00',
                        suffix:  Text(m.unit,
                          style: const TextStyle(
                            fontSize: 12, color: _T.slate400, fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        final d = double.tryParse(v.trim());
                        if (d == null)   return 'Enter a valid number';
                        if (d <= 0)      return 'Must be greater than 0';
                        if (!_isStockIn && d > m.currentStock) {
                          return 'Cannot exceed current stock (${m.currentStock})';
                        }
                        return null;
                      },
                    ),

                    // ── Stock preview ─────────────────────────────────────
                    if (preview != null) ...[
                      const SizedBox(height: 10),
                      _StockPreview(
                        current: m.currentStock,
                        after:   preview,
                        unit:    m.unit,
                        isIn:    _isStockIn,
                        willLow: willLow,
                        willNeg: willNeg,
                      ),
                    ],

                    const SizedBox(height: 20),

                    // ── Notes ─────────────────────────────────────────────
                    _FieldLabel('Notes'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _notesController,
                      maxLines:   3,
                      style: const TextStyle(fontSize: 13, color: _T.ink),
                      decoration: _inputDecoration(
                        hint: 'Supplier, batch number, reason…',
                      ),
                    ),

                    // ── Warning: will go negative ─────────────────────────
                    if (willNeg) ...[
                      const SizedBox(height: 14),
                      _WarningBanner(
                        icon:    Icons.error_outline_rounded,
                        color:   _T.red,
                        bg:      _T.red50,
                        message: 'Quantity exceeds current stock. This will result in negative stock.',
                      ),
                    ] else if (willLow && _isStockIn == false) ...[
                      const SizedBox(height: 14),
                      _WarningBanner(
                        icon:    Icons.warning_amber_rounded,
                        color:   _T.amber,
                        bg:      _T.amber50,
                        message: 'After this transaction stock will be below the minimum level.',
                      ),
                    ],

                  ],
                ),
              ),
            ),

            // ── Footer actions ─────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: _T.slate100)),
              ),
              child: Row(children: [
                Expanded(
                  child: _PanelButton(
                    label:     'Cancel',
                    onTap:     widget.onClose,
                    style:     _PanelButtonStyle.outline,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: _submitting
                      ? Container(
                          height: 38,
                          decoration: BoxDecoration(
                            color:        modeColor,
                            borderRadius: BorderRadius.circular(_T.r),
                          ),
                          child: const Center(
                            child: SizedBox(
                              width: 18, height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white,
                              ),
                            ),
                          ),
                        )
                      : _PanelButton(
                          label:     modeLabel,
                          icon:      modeIcon,
                          onTap:     _submit,
                          color:     modeColor,
                          style:     _PanelButtonStyle.filled,
                        ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({required String hint, Widget? suffix}) =>
      InputDecoration(
        hintText:      hint,
        hintStyle:     const TextStyle(color: _T.slate400, fontSize: 13),
        suffixIcon:    suffix != null
            ? Padding(padding: const EdgeInsets.only(right: 12), child: suffix)
            : null,
        suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        filled:        true,
        fillColor:     _T.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border:        OutlineInputBorder(
          borderRadius: BorderRadius.circular(_T.r),
          borderSide:   const BorderSide(color: _T.slate200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_T.r),
          borderSide:   const BorderSide(color: _T.slate200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_T.r),
          borderSide:   const BorderSide(color: _T.blue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_T.r),
          borderSide:   const BorderSide(color: _T.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_T.r),
          borderSide:   const BorderSide(color: _T.red, width: 1.5),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// PANEL SUB-WIDGETS
// ─────────────────────────────────────────────────────────────────────────────
class _SummaryRow extends StatelessWidget {
  final String    label;
  final String    value;
  final TextStyle? valueStyle;
  const _SummaryRow({required this.label, required this.value, this.valueStyle});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: const TextStyle(fontSize: 12, color: _T.slate500)),
      Text(value, style: valueStyle ?? const TextStyle(
        fontSize: 12.5, fontWeight: FontWeight.w600, color: _T.ink3,
      )),
    ],
  );
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text, style: const TextStyle(
    fontSize: 11.5, fontWeight: FontWeight.w600,
    letterSpacing: 0.2, color: _T.ink3,
  ));
}

class _StockPreview extends StatelessWidget {
  final double current;
  final double after;
  final String unit;
  final bool   isIn;
  final bool   willLow;
  final bool   willNeg;

  const _StockPreview({
    required this.current,
    required this.after,
    required this.unit,
    required this.isIn,
    required this.willLow,
    required this.willNeg,
  });

  String _fmt(double v) =>
      v == v.floorToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    final afterColor = willNeg ? _T.red
        : (willLow ? _T.amber : _T.green);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color:        afterColor.withOpacity(0.05),
        border:       Border.all(color: afterColor.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(_T.r),
      ),
      child: Row(children: [
        Text(_fmt(current),
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _T.slate400)),
        const SizedBox(width: 8),
        Icon(
          isIn ? Icons.arrow_forward_rounded : Icons.arrow_forward_rounded,
          size: 14, color: afterColor,
        ),
        const SizedBox(width: 8),
        Text('${_fmt(after)} $unit',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: afterColor)),
        const Spacer(),
        Text(
          isIn ? '+${_fmt(after - current)}' : '−${_fmt(current - after)}',
          style: TextStyle(
            fontSize: 11.5, fontWeight: FontWeight.w600,
            color: afterColor.withOpacity(0.8),
          ),
        ),
      ]),
    );
  }
}

class _WarningBanner extends StatelessWidget {
  final IconData icon;
  final Color    color;
  final Color    bg;
  final String   message;

  const _WarningBanner({
    required this.icon,
    required this.color,
    required this.bg,
    required this.message,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color:        bg,
      border:       Border.all(color: color.withOpacity(0.3)),
      borderRadius: BorderRadius.circular(_T.r),
    ),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 14, color: color),
      const SizedBox(width: 8),
      Expanded(child: Text(message, style: TextStyle(
        fontSize: 11.5, color: color, fontWeight: FontWeight.w500,
      ))),
    ]),
  );
}

enum _PanelButtonStyle { outline, filled }

class _PanelButton extends StatefulWidget {
  final String           label;
  final IconData?        icon;
  final VoidCallback     onTap;
  final Color            color;
  final _PanelButtonStyle style;

  const _PanelButton({
    required this.label,
    required this.onTap,
    required this.style,
    this.icon,
    this.color = _T.blue,
  });

  @override
  State<_PanelButton> createState() => _PanelButtonState();
}

class _PanelButtonState extends State<_PanelButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final filled = widget.style == _PanelButtonStyle.filled;
    return MouseRegion(
      cursor:  SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          height: 38,
          decoration: BoxDecoration(
            color: filled
                ? (_hovered ? widget.color.withOpacity(0.85) : widget.color)
                : (_hovered ? _T.slate50 : _T.white),
            border: Border.all(
              color: filled ? Colors.transparent : (_hovered ? _T.slate300 : _T.slate200),
            ),
            borderRadius: BorderRadius.circular(_T.r),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            if (widget.icon != null) ...[
              Icon(widget.icon, size: 14,
                  color: filled ? Colors.white : _T.ink3),
              const SizedBox(width: 6),
            ],
            Text(widget.label, style: TextStyle(
              fontSize:   13,
              fontWeight: FontWeight.w600,
              color:      filled ? Colors.white : _T.ink3,
            )),
          ]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EMPTY STATE
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final bool hasFilter;
  const _EmptyState({required this.hasFilter});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 52, height: 52,
        decoration: BoxDecoration(
          color: _T.slate100, borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          hasFilter ? Icons.filter_list_off_rounded : Icons.inventory_2_outlined,
          size: 24, color: _T.slate400,
        ),
      ),
      const SizedBox(height: 16),
      Text(
        hasFilter ? 'No matching materials' : 'No materials yet',
        style: const TextStyle(
          fontSize: 15, fontWeight: FontWeight.w600, color: _T.ink3,
        ),
      ),
      const SizedBox(height: 6),
      Text(
        hasFilter
            ? 'Try changing your search or filter'
            : 'Add materials manually or import a CSV',
        style: const TextStyle(fontSize: 13, color: _T.slate400),
      ),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// LOADING STATE
// ─────────────────────────────────────────────────────────────────────────────
class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) => const Center(
    child: CircularProgressIndicator(color: _T.blue, strokeWidth: 2),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// MESSAGE DIALOG
// ─────────────────────────────────────────────────────────────────────────────
class _MessageDialog extends StatelessWidget {
  final String title;
  final String body;
  final bool   isError;

  const _MessageDialog({
    required this.title,
    required this.body,
    required this.isError,
  });

  @override
  Widget build(BuildContext context) {
    final color = isError ? _T.red   : _T.green;
    final bg    = isError ? _T.red50 : _T.green50;
    final icon  = isError
        ? Icons.error_outline_rounded
        : Icons.check_circle_outline_rounded;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_T.rLg)),
      child: Container(
        width: 380,
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(
            fontSize: 16, fontWeight: FontWeight.w700, color: _T.ink,
          )),
          const SizedBox(height: 8),
          Text(body, style: const TextStyle(fontSize: 13, color: _T.slate500),
              textAlign: TextAlign.center),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: _PanelButton(
              label: 'OK',
              onTap: () => Navigator.pop(context),
              color: color,
              style: _PanelButtonStyle.filled,
            ),
          ),
        ]),
      ),
    );
  }
}
// ─────────────────────────────────────────────────────────────────────────────
// manage_materials_screen.dart
//
// Desktop screen for managing material inventory — stock in / out, CSV import,
// barcode export, and material creation.
//
// LAYOUT
// ──────
//   Topbar (58 px)
//   └── Body: horizontal split
//       ├── LEFT  (400 px fixed) — searchable, filterable material list
//       │                          with stat summary row at top
//       └── RIGHT (flexible)     — detail panel OR idle pane
//           ├── Overview tab      — stock level, barcode, metadata
//           └── Transactions tab  — stock-in / stock-out history
//
// DATA LOGIC
// ──────────
//   All provider calls (fetchMaterials, createMaterials, CSV parsing) lifted
//   verbatim from materials_screen.dart (mobile v1).
//   Zero logic changes; only presentation layer is new.
//
// DESIGN SYSTEM
// ─────────────
//   Token class _T, _SectionCard anatomy, _SmooField, _FieldLabel,
//   FilledButton.icon / OutlinedButton — identical to create_task_screen.dart
//   and manage_printers_screen.dart.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:io';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/components/product_barcode.dart';
import 'package:smooflow/core/models/material.dart';
import 'package:smooflow/providers/material_provider.dart';
import 'package:smooflow/utils/exportBarcodeToJpg.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TOKENS — identical to every other desktop screen
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
  static const ink3      = Color(0xFF334155);
  static const white     = Colors.white;
  static const r         = 8.0;
  static const rLg       = 12.0;
  static const rXl       = 16.0;
}

// ─────────────────────────────────────────────────────────────────────────────
// ROOT SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class DesktopMaterialsListScreen extends ConsumerStatefulWidget {
  const DesktopMaterialsListScreen({super.key});

  @override
  ConsumerState<DesktopMaterialsListScreen> createState() =>
      _ManageMaterialsScreenState();
}

class _ManageMaterialsScreenState
    extends ConsumerState<DesktopMaterialsListScreen> {
  MaterialModel? _selected;
  bool           _showCreate = false;

  final _searchCtrl = TextEditingController();
  String _filter    = 'All'; // 'All' | 'Low Stock' | 'Out of Stock'

  String get _q => _searchCtrl.text.trim().toLowerCase();

  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => ref.read(materialNotifierProvider.notifier).fetchMaterials());
  }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  List<MaterialModel> get _filtered {
    var list = ref.watch(materialNotifierProvider).materials;
    if (_filter == 'Low Stock')    list = list.where((m) => m.isLowStock && !m.isCriticalStock).toList();
    if (_filter == 'Out of Stock') list = list.where((m) => m.isCriticalStock).toList();
    if (_q.isNotEmpty) list = list.where((m) => m.name.toLowerCase().contains(_q)).toList();
    return list;
  }

  void _selectMaterial(MaterialModel m) =>
      setState(() { _selected = m; _showCreate = false; });

  void _openCreate() =>
      setState(() { _selected = null; _showCreate = true; });

  void _closePanel() =>
      setState(() { _selected = null; _showCreate = false; });

  void _onSaved() {
    _closePanel();
    ref.read(materialNotifierProvider.notifier).fetchMaterials();
  }

  // ── CSV import — verbatim from mobile v1 ──────────────────────────────────

  void _showImportDialog() {
    showDialog<void>(
      context:      context,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (_) => _CsvImportDialog(
        onConfirm: () { Navigator.of(context).pop(); _pickCSVFile(); },
      ),
    );
  }

  Future<void> _pickCSVFile() async {
    final result = await FilePicker.platform.pickFiles(
      type:              FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (result == null || result.files.isEmpty) return;

    if (!mounted) return;
    showDialog<void>(
      context:            context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final file      = File(result.files.single.path!);
    final csvString = await file.readAsString();
    final csvData   = const CsvToListConverter()
        .convert(csvString, eol: '\n', shouldParseNumbers: false);

    if (!mounted) return;
    Navigator.of(context).pop();

    if (csvData.isEmpty) {
      _showErrorDialog('Empty CSV', 'The CSV file appears to be empty.');
      return;
    }

    final materials = await _parseCSVData(csvData);
    if (materials.isEmpty) return;

    await ref.read(materialNotifierProvider.notifier).createMaterials(materials);
    ref.read(materialNotifierProvider.notifier).fetchMaterials();
    _snack('${materials.length} material${materials.length == 1 ? '' : 's'} imported', isError: false);
  }

  Future<List<MaterialModel>> _parseCSVData(List<List<dynamic>> csvData) async {
    final headers = csvData[0].map((h) => h.toString().toLowerCase().trim()).toList();

    int _col(List<String> names) {
      for (final n in names) {
        final i = headers.indexWhere((h) => h == n);
        if (i != -1) return i;
      }
      return -1;
    }

    final nameIdx    = _col(['name']);
    final typeIdx    = _col(['measure type','measuretype','measure_type','type']);
    final descIdx    = _col(['description','desc']);
    final minStockIdx = _col(['min stock level','minstocklevel','min_stock_level','min stock','minstock','min_stock','minimum stock']);

    if (nameIdx == -1) { _showErrorDialog('Missing Column', '"name" column not found.'); return []; }
    if (typeIdx == -1) { _showErrorDialog('Missing Column', '"measure type" column not found.'); return []; }

    String? cell(List<dynamic> row, int idx) =>
        (idx == -1 || idx >= row.length) ? null : row[idx]?.toString();

    MeasureType? parseMT(String? v) {
      if (v == null) return null;
      final s = v.trim().replaceAll(' ', '_').toLowerCase();
      return switch (s) {
        'running_meter' || 'runningmeter' => MeasureType.running_meter,
        'item_quantity' || 'itemquantity' || 'quantity' => MeasureType.item_quantity,
        'liters' || 'liter' || 'l' => MeasureType.liters,
        'square_meter' || 'squaremeter' || 'sqm' => MeasureType.square_meter,
        'kilograms' || 'kilogram' || 'kg' => MeasureType.kilograms,
        _ => null,
      };
    }

    final materials = <MaterialModel>[];
    final errors    = <String>[];

    for (int i = 1; i < csvData.length; i++) {
      final row = csvData[i];
      if (row.isEmpty || row.every((c) => c.toString().trim().isEmpty)) continue;
      final name = cell(row, nameIdx)?.trim();
      if (name == null || name.isEmpty) { errors.add('Row ${i+1}: name is required'); continue; }
      final mt = parseMT(cell(row, typeIdx));
      if (mt == null) { errors.add('Row ${i+1}: invalid measure type'); continue; }
      final minStock = double.tryParse(cell(row, minStockIdx)?.trim() ?? '') ?? 0.0;
      if (minStock < 0) { errors.add('Row ${i+1}: min stock cannot be negative'); continue; }
      materials.add(MaterialModel.create(
        name: name,
        description: cell(row, descIdx)?.trim(),
        measureType: mt,
        minStockLevel: minStock,
      ));
    }

    if (errors.isNotEmpty && mounted) _showValidationDialog(errors);
    return materials;
  }

  void _showErrorDialog(String title, String msg) {
    showDialog<void>(
      context:      context,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (_) => _AlertDialog(
        icon:  Icons.error_outline_rounded,
        color: _T.red,
        bg:    _T.red50,
        title: title,
        body:  msg,
        cta:   'OK',
      ),
    );
  }

  void _showValidationDialog(List<String> errors) {
    showDialog<void>(
      context:      context,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (_) => _ValidationDialog(errors: errors),
    );
  }

  void _snack(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(
          isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
          size: 15, color: Colors.white,
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(msg, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
      ]),
      backgroundColor: _T.ink,
      behavior:        SnackBarBehavior.floating,
      margin:          const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_T.r)),
      duration: const Duration(seconds: 3),
    ));
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state    = ref.watch(materialNotifierProvider);
    final all      = state.materials;
    final filtered = _filtered;

    final totalMaterials = all.length;
    final lowStock       = all.where((m) => m.isLowStock && !m.isCriticalStock).length;
    final outOfStock     = all.where((m) => m.isCriticalStock).length;

    final showPanel = _selected != null || _showCreate;

    return Scaffold(
      backgroundColor: _T.slate50,
      body: Column(children: [
        _Topbar(
          onAdd:    _openCreate,
          onImport: _showImportDialog,
        ),
        Expanded(child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── LEFT: material list ──────────────────────────────────────
            SizedBox(
              width: 400,
              child: Container(
                decoration: const BoxDecoration(
                  color: _T.white,
                  border: Border(right: BorderSide(color: _T.slate200)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [

                    // Stat summary row
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: _T.slate200)),
                      ),
                      child: Row(children: [
                        _StatChip(value: '$totalMaterials', label: 'Total',
                            color: _T.slate500, bg: _T.slate100),
                        const SizedBox(width: 8),
                        _StatChip(value: '$lowStock', label: 'Low stock',
                            color: _T.amber, bg: _T.amber50),
                        const SizedBox(width: 8),
                        _StatChip(value: '$outOfStock', label: 'Out of stock',
                            color: _T.red, bg: _T.red50),
                      ]),
                    ),

                    // Search + filter
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
                      child: Column(children: [
                        _SearchBar(
                          controller: _searchCtrl,
                          onChanged:  (_) => setState(() {}),
                        ),
                        const SizedBox(height: 8),
                        // Filter tabs
                        Row(children: [
                          _FilterTab(label: 'All',          selected: _filter, count: all.length,                                     onTap: () => setState(() => _filter = 'All')),
                          const SizedBox(width: 6),
                          _FilterTab(label: 'Low Stock',    selected: _filter, count: lowStock,                                        onTap: () => setState(() => _filter = 'Low Stock')),
                          const SizedBox(width: 6),
                          _FilterTab(label: 'Out of Stock', selected: _filter, count: outOfStock,                                      onTap: () => setState(() => _filter = 'Out of Stock')),
                        ]),
                      ]),
                    ),

                    // Material list
                    Expanded(
                      child: state.isLoading
                          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                          : filtered.isEmpty
                              ? _EmptyListState(hasSearch: _q.isNotEmpty || _filter != 'All')
                              : ListView.separated(
                                  padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
                                  itemCount: filtered.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 4),
                                  itemBuilder: (_, i) {
                                    final m = filtered[i];
                                    return _MaterialListTile(
                                      material:   m,
                                      isSelected: _selected?.id == m.id,
                                      onTap:      () => _selectMaterial(m),
                                    );
                                  },
                                ),
                    ),
                  ],
                ),
              ),
            ),

            // ── RIGHT: detail panel or idle ──────────────────────────────
            Expanded(
              child: showPanel
                  ? (_showCreate
                      ? _CreatePanel(
                          key:     const ValueKey('create'),
                          onClose: _closePanel,
                          onSaved: _onSaved,
                        )
                      : _DetailPanel(
                          key:      ValueKey(_selected!.id),
                          material: _selected!,
                          onClose:  _closePanel,
                          onUpdate: () {
                            ref.read(materialNotifierProvider.notifier).fetchMaterials();
                            setState(() {});
                          },
                        ))
                  : const _IdlePane(),
            ),
          ],
        )),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TOP BAR
// ─────────────────────────────────────────────────────────────────────────────
class _Topbar extends StatelessWidget {
  final VoidCallback onAdd, onImport;
  const _Topbar({required this.onAdd, required this.onImport});

  @override
  Widget build(BuildContext context) => Container(
    height: 58,
    padding: const EdgeInsets.symmetric(horizontal: 20),
    decoration: const BoxDecoration(
      color:  _T.white,
      border: Border(bottom: BorderSide(color: _T.slate200)),
    ),
    child: Row(children: [
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
            child: const Icon(Icons.arrow_back_rounded, size: 17, color: _T.ink3),
          ),
        ),
      ),
      const SizedBox(width: 14),
      Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          color:        _T.purple50,
          borderRadius: BorderRadius.circular(9),
          border:       Border.all(color: _T.purple.withOpacity(0.2)),
        ),
        child: const Icon(Icons.layers_outlined, size: 16, color: _T.purple),
      ),
      const SizedBox(width: 12),
      const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Manage Materials',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                  color: _T.ink, letterSpacing: -0.2)),
          Text('Inventory stock management',
              style: TextStyle(fontSize: 10.5, color: _T.slate400,
                  fontWeight: FontWeight.w500)),
        ],
      ),
      const Spacer(),
      // Import CSV
      OutlinedButton.icon(
        onPressed: onImport,
        style: OutlinedButton.styleFrom(
          foregroundColor: _T.slate500,
          side: const BorderSide(color: _T.slate200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_T.r)),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        icon:  const Icon(Icons.upload_file_outlined, size: 15),
        label: const Text('Import CSV'),
      ),
      const SizedBox(width: 10),
      // Add material
      FilledButton.icon(
        onPressed: onAdd,
        style: FilledButton.styleFrom(
          backgroundColor: _T.blue,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_T.r)),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
        icon:  const Icon(Icons.add_rounded, size: 16),
        label: const Text('Add Material'),
      ),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// MATERIAL LIST TILE
// ─────────────────────────────────────────────────────────────────────────────
class _MaterialListTile extends StatefulWidget {
  final MaterialModel material;
  final bool          isSelected;
  final VoidCallback  onTap;
  const _MaterialListTile({required this.material, required this.isSelected, required this.onTap});
  @override
  State<_MaterialListTile> createState() => _MaterialListTileState();
}

class _MaterialListTileState extends State<_MaterialListTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final m        = widget.material;
    final selected = widget.isSelected;

    final Color stockColor;
    final Color stockBg;
    final String stockLabel;
    if (m.isCriticalStock) {
      stockColor = _T.red; stockBg = _T.red50; stockLabel = 'Out of stock';
    } else if (m.isLowStock) {
      stockColor = _T.amber; stockBg = _T.amber50; stockLabel = 'Low stock';
    } else {
      stockColor = _T.green; stockBg = _T.green50; stockLabel = 'In stock';
    }

    return MouseRegion(
      cursor:  SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? _T.blue50 : _hovered ? _T.slate50 : Colors.transparent,
            borderRadius: BorderRadius.circular(_T.r),
            border: Border.all(
              color: selected ? _T.blue.withOpacity(0.35) : _hovered ? _T.slate200 : _T.slate200,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: selected ? _T.blue.withOpacity(0.10) : _T.slate100,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(Icons.layers_outlined, size: 17,
                  color: selected ? _T.blue : _T.slate500),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(m.name, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                        color: selected ? _T.blue : _T.ink)),
                Text('${_fmtStock(m.currentStock)} ${m.unitShort}',
                    style: const TextStyle(fontSize: 11.5, color: _T.slate400)),
              ]),
            ),
            _StockPill(label: stockLabel, color: stockColor, bg: stockBg),
            if (selected) ...[
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right_rounded, size: 16, color: _T.blue),
            ],
          ]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DETAIL PANEL — overview + stock actions
// ─────────────────────────────────────────────────────────────────────────────
class _DetailPanel extends ConsumerStatefulWidget {
  final MaterialModel material;
  final VoidCallback  onClose, onUpdate;
  const _DetailPanel({super.key, required this.material, required this.onClose, required this.onUpdate});

  @override
  ConsumerState<_DetailPanel> createState() => _DetailPanelState();
}

class _DetailPanelState extends ConsumerState<_DetailPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final _barcodeKey = GlobalKey();

  @override
  void initState() { super.initState(); _tabs = TabController(length: 2, vsync: this); }
  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  void _showStockDialog({required bool isIn}) {
    showDialog<void>(
      context:      context,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (_) => _StockAdjustDialog(
        material: widget.material,
        isIn:     isIn,
        onConfirm: (double qty, String? note) async {
          Navigator.of(context).pop();
          if (isIn) {
            //TODO
            // await ref.read(materialNotifierProvider.notifier)
            //     .addStock(widget.material.id, qty, note: note);
          } else {
            //TODO
            // await ref.read(materialNotifierProvider.notifier)
            //     .removeStock(widget.material.id, qty, note: note);
          }
          widget.onUpdate();
          _snack(
            isIn ? 'Stock added successfully' : 'Stock removed successfully',
            isError: false,
          );
        },
      ),
    );
  }

  void _snack(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
            size: 15, color: Colors.white),
        const SizedBox(width: 8),
        Expanded(child: Text(msg, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
      ]),
      backgroundColor: _T.ink,
      behavior:        SnackBarBehavior.floating,
      margin:          const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_T.r)),
      duration: const Duration(seconds: 3),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.material;

    final Color stockColor;
    final Color stockBg;
    final String stockLabel;
    if (m.isCriticalStock) {
      stockColor = _T.red; stockBg = _T.red50; stockLabel = 'Out of stock';
    } else if (m.isLowStock) {
      stockColor = _T.amber; stockBg = _T.amber50; stockLabel = 'Low stock';
    } else {
      stockColor = _T.green; stockBg = _T.green50; stockLabel = 'In stock';
    }

    return Container(
      decoration: const BoxDecoration(
        color:  _T.slate50,
        border: Border(left: BorderSide(color: _T.slate200)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [

        // ── Panel topbar ────────────────────────────────────────────────
        Container(
          height: 58,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: const BoxDecoration(
            color:  _T.white,
            border: Border(bottom: BorderSide(color: _T.slate200)),
          ),
          child: Row(children: [
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
                  child: const Icon(Icons.close_rounded, size: 17, color: _T.ink3),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color:        _T.slate100,
                borderRadius: BorderRadius.circular(9),
                border:       Border.all(color: _T.slate200),
              ),
              child: const Icon(Icons.layers_outlined, size: 16, color: _T.slate500),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(m.name, style: const TextStyle(fontSize: 15,
                    fontWeight: FontWeight.w700, color: _T.ink, letterSpacing: -0.2)),
                Text(m.unit, style: const TextStyle(fontSize: 10.5,
                    color: _T.slate400, fontWeight: FontWeight.w500)),
              ]),
            ),
            _StockPill(label: stockLabel, color: stockColor, bg: stockBg),
            const SizedBox(width: 12),
            // Stock-in button
            FilledButton.icon(
              onPressed: () => _showStockDialog(isIn: true),
              style: FilledButton.styleFrom(
                backgroundColor: _T.green,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_T.r)),
                textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
              ),
              icon:  const Icon(Icons.add_rounded, size: 15),
              label: const Text('Stock In'),
            ),
            const SizedBox(width: 8),
            // Stock-out button
            OutlinedButton.icon(
              onPressed: m.isCriticalStock ? null : () => _showStockDialog(isIn: false),
              style: OutlinedButton.styleFrom(
                foregroundColor: _T.red,
                disabledForegroundColor: _T.slate300,
                side: BorderSide(color: m.isCriticalStock ? _T.slate200 : _T.red.withOpacity(0.4)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_T.r)),
                textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
              ),
              icon:  const Icon(Icons.remove_rounded, size: 15),
              label: const Text('Stock Out'),
            ),
          ]),
        ),

        // ── Tab bar ─────────────────────────────────────────────────────
        Container(
          color: _T.white,
          child: TabBar(
            controller:       _tabs,
            labelColor:       _T.blue,
            unselectedLabelColor: _T.slate400,
            indicatorColor:   _T.blue,
            indicatorWeight:  2,
            labelStyle:       const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            padding:          const EdgeInsets.symmetric(horizontal: 20),
            tabAlignment:     TabAlignment.start,
            isScrollable:     true,
            tabs: const [
              Tab(text: 'Overview'),
              Tab(text: 'Stock History'),
            ],
          ),
        ),

        // ── Tab views ───────────────────────────────────────────────────
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              // ── Overview ──────────────────────────────────────────────
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(28, 28, 28, 40),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Material Overview',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800,
                            color: _T.ink, letterSpacing: -0.5)),
                    const SizedBox(height: 4),
                    const Text('Stock levels and material details.',
                        style: TextStyle(fontSize: 13, color: _T.slate400)),
                    const SizedBox(height: 24),

                    // Stock level card
                    _SectionCard(
                      icon:      Icons.inventory_2_outlined,
                      iconColor: stockColor,
                      iconBg:    stockBg,
                      title:     'Stock Level',
                      subtitle:  'Current inventory quantities',
                      child: Column(children: [
                        Row(children: [
                          Expanded(child: _MetricCell(
                            label: 'Current Stock',
                            value: '${_fmtStock(m.currentStock)} ${m.unitShort}',
                            icon:  Icons.inventory_2_outlined,
                            color: stockColor,
                          )),
                          const SizedBox(width: 12),
                          Expanded(child: _MetricCell(
                            label: 'Min Stock Level',
                            value: '${_fmtStock(m.minStockLevel)} ${m.unitShort}',
                            icon:  Icons.warning_amber_outlined,
                            color: _T.amber,
                          )),
                        ]),
                        if (m.minStockLevel > 0) ...[
                          const SizedBox(height: 16),
                          _StockBar(current: m.currentStock, min: m.minStockLevel),
                        ],
                      ]),
                    ),
                    const SizedBox(height: 16),

                    // Details card
                    _SectionCard(
                      icon:      Icons.info_outline_rounded,
                      iconColor: _T.blue,
                      iconBg:    _T.blue50,
                      title:     'Material Details',
                      subtitle:  'Name, unit and description',
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        _DetailRow(label: 'Name',        value: m.name),
                        _DetailRow(label: 'Measure Type', value: m.measureType.name.replaceAll('_', ' ')),
                        _DetailRow(label: 'Unit',        value: m.unit),
                        _DetailRow(label: 'Unit Short',  value: m.unitShort),
                        if (m.description != null)
                          _DetailRow(label: 'Description', value: m.description!),
                        _DetailRow(
                          label: 'Added',
                          value: '${m.createdAt.day}/${m.createdAt.month}/${m.createdAt.year}',
                          isLast: true,
                        ),
                      ]),
                    ),
                    const SizedBox(height: 16),

                    // Barcode card
                    _SectionCard(
                      icon:      Icons.qr_code_outlined,
                      iconColor: _T.purple,
                      iconBg:    _T.purple50,
                      title:     'Barcode',
                      subtitle:  'Scan or export for stock operations',
                      child: Column(children: [
                        RepaintBoundary(
                          key: _barcodeKey,
                          child: ProductBarcode(barcode: m.barcode),
                        ),
                        const SizedBox(height: 14),
                        Align(
                          alignment: Alignment.centerRight,
                          child: OutlinedButton.icon(
                            onPressed: () => exportToJpg(context, _barcodeKey),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _T.purple,
                              side: BorderSide(color: _T.purple.withOpacity(0.4)),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_T.r)),
                              textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                            icon:  const Icon(Icons.file_download_outlined, size: 15),
                            label: const Text('Export Barcode'),
                          ),
                        ),
                      ]),
                    ),
                  ]),
                ),
              ),

              // ── Stock History ─────────────────────────────────────────
              _StockHistoryTab(material: m),
            ],
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STOCK HISTORY TAB
// ─────────────────────────────────────────────────────────────────────────────
class _StockHistoryTab extends ConsumerWidget {
  final MaterialModel material;
  const _StockHistoryTab({required this.material});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // final transactions = material.stockTransactions ?? [];

    // if transactions.isEmpty
    if (true) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.swap_vert_rounded, size: 28, color: _T.slate300),
          const SizedBox(height: 10),
          const Text('No stock movements yet',
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: _T.slate400)),
          const SizedBox(height: 4),
          const Text('Use Stock In / Stock Out to record changes',
              style: TextStyle(fontSize: 12, color: _T.slate300)),
        ]),
      );
    }

    // Uncomment this
    // return SingleChildScrollView(
    //   padding: const EdgeInsets.fromLTRB(28, 28, 28, 40),
    //   child: ConstrainedBox(
    //     constraints: const BoxConstraints(maxWidth: 680),
    //     child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    //       const Text('Stock History',
    //           style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800,
    //               color: _T.ink, letterSpacing: -0.5)),
    //       const SizedBox(height: 4),
    //       Text('${transactions.length} movement${transactions.length == 1 ? '' : 's'} recorded',
    //           style: const TextStyle(fontSize: 13, color: _T.slate400)),
    //       const SizedBox(height: 24),
    //       _SectionCard(
    //         icon:      Icons.swap_vert_rounded,
    //         iconColor: _T.blue,
    //         iconBg:    _T.blue50,
    //         title:     'Movements',
    //         subtitle:  'Chronological stock changes',
    //         child: Column(
    //           children: transactions
    //               .map((t) => _TransactionRow(transaction: t, unit: material.unitShort))
    //               .toList(),
    //         ),
    //       ),
    //     ]),
    //   ),
    // );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CREATE PANEL
// ─────────────────────────────────────────────────────────────────────────────
class _CreatePanel extends ConsumerStatefulWidget {
  final VoidCallback onClose, onSaved;
  const _CreatePanel({super.key, required this.onClose, required this.onSaved});

  @override
  ConsumerState<_CreatePanel> createState() => _CreatePanelState();
}

class _CreatePanelState extends ConsumerState<_CreatePanel> {
  final _nameCtrl     = TextEditingController();
  final _descCtrl     = TextEditingController();
  final _minStockCtrl = TextEditingController();

  MeasureType? _measureType;
  bool         _submitted = false;
  bool         _saving    = false;

  bool get _nameOk => _nameCtrl.text.trim().isNotEmpty;
  bool get _typeOk => _measureType != null;
  bool get _formOk => _nameOk && _typeOk;

  @override
  void initState() {
    super.initState();
    for (final c in [_nameCtrl, _descCtrl, _minStockCtrl]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _descCtrl.dispose(); _minStockCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _submitted = true);
    if (!_formOk) return;
    setState(() => _saving = true);

    try {
      final material = MaterialModel.create(
        name:          _nameCtrl.text.trim(),
        description:   _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        measureType:   _measureType!,
        minStockLevel: double.tryParse(_minStockCtrl.text.trim()) ?? 0.0,
      );
      await ref.read(materialNotifierProvider.notifier)
          .createMaterials([material]);
      _snack('Material created', isError: false);
      widget.onSaved();
    } catch (e) {
      _snack('Failed to create material', isError: true);
      setState(() => _saving = false);
    }
  }

  void _snack(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
            size: 15, color: Colors.white),
        const SizedBox(width: 8),
        Expanded(child: Text(msg, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
      ]),
      backgroundColor: _T.ink,
      behavior:        SnackBarBehavior.floating,
      margin:          const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_T.r)),
      duration: const Duration(seconds: 3),
    ));
  }

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      color:  _T.slate50,
      border: Border(left: BorderSide(color: _T.slate200)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      // Panel topbar
      Container(
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: const BoxDecoration(
          color:  _T.white,
          border: Border(bottom: BorderSide(color: _T.slate200)),
        ),
        child: Row(children: [
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
                child: const Icon(Icons.close_rounded, size: 17, color: _T.ink3),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color:        _T.blue50,
              borderRadius: BorderRadius.circular(9),
              border:       Border.all(color: _T.blue.withOpacity(0.2)),
            ),
            child: const Icon(Icons.add_rounded, size: 16, color: _T.blue),
          ),
          const SizedBox(width: 12),
          const Column(mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('New Material', style: TextStyle(fontSize: 15,
                fontWeight: FontWeight.w700, color: _T.ink, letterSpacing: -0.2)),
            Text('Add to inventory', style: TextStyle(fontSize: 10.5,
                color: _T.slate400, fontWeight: FontWeight.w500)),
          ]),
        ]),
      ),

      // Form body
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 28, 28, 40),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('New Material', style: TextStyle(fontSize: 22,
                  fontWeight: FontWeight.w800, color: _T.ink, letterSpacing: -0.5)),
              const SizedBox(height: 4),
              const Text('Fill in the details below. Required fields are marked *.',
                  style: TextStyle(fontSize: 13, color: _T.slate400)),
              const SizedBox(height: 24),

              // Details card
              _SectionCard(
                icon:      Icons.layers_outlined,
                iconColor: _T.purple,
                iconBg:    _T.purple50,
                title:     'Material Details',
                subtitle:  'Name, type and description',
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _SmooField(
                    controller: _nameCtrl,
                    label:      'Material Name',
                    hint:       'e.g. Vinyl Roll 3.2m',
                    icon:       Icons.layers_outlined,
                    required:   true,
                    error: _submitted && !_nameOk ? 'Name is required' : null,
                  ),
                  const SizedBox(height: 16),

                  // Measure type picker
                  _FieldLabel.required('Measure Type'),
                  const SizedBox(height: 9),
                  _MeasureTypePicker(
                    selected:  _measureType,
                    showError: _submitted && !_typeOk,
                    onSelect:  (t) => setState(() => _measureType = t),
                  ),
                  const SizedBox(height: 16),

                  _SmooField(
                    controller: _descCtrl,
                    label:      'Description',
                    hint:       'Optional notes about this material',
                    icon:       Icons.notes_rounded,
                    required:   false,
                  ),
                ]),
              ),
              const SizedBox(height: 16),

              // Stock thresholds card
              _SectionCard(
                icon:      Icons.warning_amber_outlined,
                iconColor: _T.amber,
                iconBg:    _T.amber50,
                title:     'Stock Thresholds',
                subtitle:  'Optional — configure low stock alerts',
                child: _NumField(
                  controller: _minStockCtrl,
                  label:      'Minimum Stock Level',
                  hint:       'e.g. 10',
                  required:   false,
                  suffix: _measureType != null
                      ? _measureType!.name.replaceAll('_', ' ')
                      : null,
                ),
              ),
            ]),
          ),
        ),
      ),

      // Action bar
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_T.r)),
              ),
              child: const Text('Cancel', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: FilledButton.icon(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor:         _T.blue,
                disabledBackgroundColor: _T.slate200,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_T.r)),
              ),
              icon: _saving
                  ? const SizedBox(width: 15, height: 15,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                  : const Icon(Icons.add_rounded, size: 17),
              label: Text(_saving ? 'Creating…' : 'Create Material',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
      ),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// MEASURE TYPE PICKER — same chip anatomy as priority picker in create_task
// ─────────────────────────────────────────────────────────────────────────────
class _MeasureTypePicker extends StatelessWidget {
  final MeasureType?             selected;
  final bool                     showError;
  final ValueChanged<MeasureType> onSelect;

  const _MeasureTypePicker({
    required this.selected, required this.showError, required this.onSelect});

  static const _options = [
    (MeasureType.running_meter, 'Running Meter', 'rm', Icons.straighten_rounded),
    (MeasureType.square_meter,  'Square Meter',  'sqm', Icons.crop_square_rounded),
    (MeasureType.item_quantity, 'Item / Qty',    'pcs', Icons.inventory_2_outlined),
    (MeasureType.liters,        'Liters',        'L',   Icons.water_drop_outlined),
    (MeasureType.kilograms,     'Kilograms',     'kg',  Icons.scale_outlined),
  ];

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Wrap(spacing: 8, runSpacing: 8,
        children: _options.map((o) {
          final (type, label, unit, icon) = o;
          final active = selected == type;
          return GestureDetector(
            onTap: () => onSelect(type),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: active ? _T.blue50 : _T.white,
                borderRadius: BorderRadius.circular(_T.rLg),
                border: Border.all(
                  color: active ? _T.blue.withOpacity(0.5)
                      : showError ? _T.red.withOpacity(0.4) : _T.slate200,
                  width: active ? 1.5 : 1,
                ),
                boxShadow: active ? [BoxShadow(color: _T.blue.withOpacity(0.10),
                    blurRadius: 10, offset: const Offset(0, 3))] : null,
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(icon, size: 14,
                    color: active ? _T.blue : _T.slate400),
                const SizedBox(width: 6),
                Text(label, style: TextStyle(
                  fontSize: 13, fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: active ? _T.blue : _T.ink3,
                )),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color:        active ? _T.blue.withOpacity(0.12) : _T.slate100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(unit, style: TextStyle(
                    fontSize: 10, fontWeight: FontWeight.w700,
                    color: active ? _T.blue : _T.slate500,
                  )),
                ),
                if (active) ...[
                  const SizedBox(width: 5),
                  const Icon(Icons.check_circle_rounded, size: 13, color: _T.blue),
                ],
              ]),
            ),
          );
        }).toList(),
      ),
      if (showError)
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(children: const [
            Icon(Icons.error_outline_rounded, size: 11, color: _T.red),
            SizedBox(width: 4),
            Text('Please select a measure type',
                style: TextStyle(fontSize: 11, color: _T.red, fontWeight: FontWeight.w500)),
          ]),
        ),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// STOCK ADJUST DIALOG
// ─────────────────────────────────────────────────────────────────────────────
class _StockAdjustDialog extends StatefulWidget {
  final MaterialModel material;
  final bool          isIn;
  final void Function(double qty, String? note) onConfirm;
  const _StockAdjustDialog({required this.material, required this.isIn, required this.onConfirm});

  @override
  State<_StockAdjustDialog> createState() => _StockAdjustDialogState();
}

class _StockAdjustDialogState extends State<_StockAdjustDialog> {
  final _qtyCtrl  = TextEditingController();
  final _noteCtrl = TextEditingController();
  bool _submitted = false;

  bool get _qtyOk {
    final v = double.tryParse(_qtyCtrl.text.trim());
    return v != null && v > 0;
  }

  bool get _withinStock {
    if (widget.isIn) return true;
    final v = double.tryParse(_qtyCtrl.text.trim()) ?? 0;
    return v <= widget.material.currentStock;
  }

  @override
  void dispose() { _qtyCtrl.dispose(); _noteCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final m       = widget.material;
    final isIn    = widget.isIn;
    final color   = isIn ? _T.green : _T.red;
    final bg      = isIn ? _T.green50 : _T.red50;
    final label   = isIn ? 'Stock In' : 'Stock Out';

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 440,
        decoration: BoxDecoration(
          color:        _T.white,
          borderRadius: BorderRadius.circular(_T.rXl),
          border:       Border.all(color: _T.slate200),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.10),
              blurRadius: 24, offset: const Offset(0, 8))],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 16, 0),
            child: Row(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color:        bg,
                  shape:        BoxShape.circle,
                  border:       Border.all(color: color.withOpacity(0.2)),
                ),
                child: Icon(isIn ? Icons.add_rounded : Icons.remove_rounded,
                    size: 18, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(label, style: const TextStyle(fontSize: 16,
                    fontWeight: FontWeight.w700, color: _T.ink)),
                Text(m.name, style: const TextStyle(fontSize: 12, color: _T.slate400)),
              ])),
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
                    child: const Icon(Icons.close_rounded, size: 15, color: _T.slate400),
                  ),
                ),
              ),
            ]),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child:   Divider(height: 1, color: _T.slate100),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Current stock info row
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: BoxDecoration(
                  color:        _T.slate50,
                  borderRadius: BorderRadius.circular(_T.r),
                  border:       Border.all(color: _T.slate200),
                ),
                child: Row(children: [
                  const Icon(Icons.inventory_2_outlined, size: 14, color: _T.slate400),
                  const SizedBox(width: 8),
                  const Text('Current stock',
                      style: TextStyle(fontSize: 12, color: _T.slate400)),
                  const Spacer(),
                  Text('${_fmtStock(m.currentStock)} ${m.unitShort}',
                      style: const TextStyle(fontSize: 13,
                          fontWeight: FontWeight.w700, color: _T.ink3)),
                ]),
              ),
              const SizedBox(height: 16),

              // Quantity
              _NumField(
                controller: _qtyCtrl,
                label:      'Quantity',
                hint:       'e.g. 5',
                required:   true,
                suffix:     m.unitShort,
                onChanged:  (_) => setState(() {}),
                error: _submitted
                    ? (!_qtyOk ? 'Enter a valid quantity'
                        : !_withinStock ? 'Cannot exceed current stock' : null)
                    : null,
              ),
              const SizedBox(height: 14),

              // Note
              _SmooField(
                controller: _noteCtrl,
                label:      'Note',
                hint:       'Optional — reason or reference',
                icon:       Icons.notes_rounded,
                required:   false,
              ),
            ]),
          ),
          // Actions
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_T.r)),
                  ),
                  child: const Text('Cancel',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: () {
                    setState(() => _submitted = true);
                    if (!_qtyOk || !_withinStock) return;
                    widget.onConfirm(
                      double.parse(_qtyCtrl.text.trim()),
                      _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: color,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_T.r)),
                  ),
                  icon:  Icon(isIn ? Icons.add_rounded : Icons.remove_rounded, size: 17),
                  label: Text(label,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CSV IMPORT DIALOG
// ─────────────────────────────────────────────────────────────────────────────
class _CsvImportDialog extends StatelessWidget {
  final VoidCallback onConfirm;
  const _CsvImportDialog({required this.onConfirm});

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: Colors.transparent,
    child: Container(
      width: 480,
      decoration: BoxDecoration(
        color:        _T.white,
        borderRadius: BorderRadius.circular(_T.rXl),
        border:       Border.all(color: _T.slate200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.10),
            blurRadius: 24, offset: const Offset(0, 8))],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 16, 0),
          child: Row(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: _T.blue50, shape: BoxShape.circle,
                border: Border.all(color: _T.blue.withOpacity(0.2)),
              ),
              child: const Icon(Icons.upload_file_outlined, size: 18, color: _T.blue),
            ),
            const SizedBox(width: 12),
            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Import from CSV', style: TextStyle(fontSize: 16,
                  fontWeight: FontWeight.w700, color: _T.ink)),
              Text('Bulk-create materials from a spreadsheet',
                  style: TextStyle(fontSize: 12, color: _T.slate400)),
            ])),
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
                  child: const Icon(Icons.close_rounded, size: 15, color: _T.slate400),
                ),
              ),
            ),
          ]),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child:   Divider(height: 1, color: _T.slate100),
        ),
        // Format reference
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            decoration: BoxDecoration(
              color:        _T.slate50,
              borderRadius: BorderRadius.circular(_T.rLg),
              border:       Border.all(color: _T.slate200),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Row(children: [
                  const Icon(Icons.table_chart_outlined, size: 14, color: _T.slate400),
                  const SizedBox(width: 7),
                  const Text('CSV Column Reference',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _T.ink3)),
                ]),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child:   Divider(height: 1, color: _T.slate200),
              ),
              ...[
                ('name',          'Required',              true,  null),
                ('measure type',  'Required',              true,  'running_meter · item_quantity · liters · kilograms · square_meter'),
                ('description',   'Optional',              false, null),
                ('min stock level','Optional — default 0', false, null),
              ].map((r) {
                final (field, req, isReq, note) = r;
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(width: 5, height: 5, margin: const EdgeInsets.only(top: 5),
                        decoration: BoxDecoration(shape: BoxShape.circle,
                            color: isReq ? _T.red : _T.green)),
                    const SizedBox(width: 8),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Text(field, style: const TextStyle(fontSize: 12.5,
                            fontWeight: FontWeight.w600, color: _T.ink3,
                            fontFamily: 'monospace')),
                        const SizedBox(width: 8),
                        Text(req, style: TextStyle(fontSize: 11,
                            color: isReq ? _T.red : _T.slate400)),
                      ]),
                      if (note != null) ...[
                        const SizedBox(height: 2),
                        Text(note, style: const TextStyle(fontSize: 11,
                            color: _T.slate400, fontStyle: FontStyle.italic)),
                      ],
                    ])),
                  ]),
                );
              }),
            ]),
          ),
        ),
        // Info strip
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color:        _T.amber50,
              borderRadius: BorderRadius.circular(_T.r),
              border:       Border.all(color: _T.amber.withOpacity(0.35)),
            ),
            child: Row(children: const [
              Icon(Icons.info_outline_rounded, size: 14, color: _T.amber),
              SizedBox(width: 8),
              Expanded(child: Text('Column names are case-insensitive and can be in any order',
                  style: TextStyle(fontSize: 12, color: _T.ink3))),
            ]),
          ),
        ),
        // Actions
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          child: Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _T.slate500,
                  side: const BorderSide(color: _T.slate200),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_T.r)),
                ),
                child: const Text('Cancel',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed: onConfirm,
                style: FilledButton.styleFrom(
                  backgroundColor: _T.blue,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_T.r)),
                ),
                icon:  const Icon(Icons.folder_open_outlined, size: 17),
                label: const Text('Choose File',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ),
      ]),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED SECTION CARD — verbatim from create_task_screen.dart
// ─────────────────────────────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final IconData icon;
  final Color    iconColor, iconBg;
  final String   title, subtitle;
  final Widget   child;
  const _SectionCard({required this.icon, required this.iconColor,
    required this.iconBg, required this.title, required this.subtitle,
    required this.child});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: _T.white,
      borderRadius: BorderRadius.circular(_T.rXl),
      border: Border.all(color: _T.slate200),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03),
          blurRadius: 14, offset: const Offset(0, 3))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
        child: Row(children: [
          Container(width: 34, height: 34,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(9),
              border: Border.all(color: iconColor.withOpacity(0.2))),
            child: Icon(icon, size: 16, color: iconColor)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                color: _T.ink, letterSpacing: -0.2)),
            Text(subtitle, style: const TextStyle(fontSize: 11.5, color: _T.slate400)),
          ])),
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
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// SMOO FIELD — verbatim from create_task_screen.dart
// ─────────────────────────────────────────────────────────────────────────────
class _SmooField extends StatefulWidget {
  final TextEditingController controller;
  final String                label, hint;
  final IconData              icon;
  final bool                  required;
  final String?               error;
  const _SmooField({required this.controller, required this.label,
    required this.hint, required this.icon,
    this.required = false, this.error});
  @override
  State<_SmooField> createState() => _SmooFieldState();
}

class _SmooFieldState extends State<_SmooField> {
  final _focus   = FocusNode();
  bool  _focused = false;
  @override
  void initState() { super.initState(); _focus.addListener(() => setState(() => _focused = _focus.hasFocus)); }
  @override
  void dispose() { _focus.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.error != null;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (widget.required) _FieldLabel.required(widget.label)
      else _FieldLabel(widget.label, optional: true),
      const SizedBox(height: 7),
      AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: _focused ? _T.white : _T.slate50,
          borderRadius: BorderRadius.circular(_T.r),
          border: Border.all(
            color: hasError ? _T.red : (_focused ? _T.blue : _T.slate200),
            width: (_focused || hasError) ? 1.5 : 1,
          ),
        ),
        child: TextField(
          controller: widget.controller, focusNode: _focus,
          style: const TextStyle(fontSize: 13, color: _T.ink, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText:  widget.hint,
            hintStyle: const TextStyle(fontSize: 13, color: _T.slate300),
            prefixIcon: Icon(widget.icon, size: 16, color: _T.slate400),
            border:         InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 13, horizontal: 12),
          ),
        ),
      ),
      if (hasError)
        Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Row(children: [
            const Icon(Icons.error_outline_rounded, size: 11, color: _T.red),
            const SizedBox(width: 4),
            Text(widget.error!, style: const TextStyle(fontSize: 11, color: _T.red, fontWeight: FontWeight.w500)),
          ]),
        ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// NUM FIELD — numeric with optional suffix badge
// ─────────────────────────────────────────────────────────────────────────────
class _NumField extends StatefulWidget {
  final TextEditingController controller;
  final String                label, hint;
  final bool                  required;
  final String?               suffix, error;
  final ValueChanged<String>? onChanged;
  const _NumField({required this.controller, required this.label,
    required this.hint, required this.required,
    this.suffix, this.error, this.onChanged});
  @override
  State<_NumField> createState() => _NumFieldState();
}

class _NumFieldState extends State<_NumField> {
  final _focus   = FocusNode();
  bool  _focused = false;
  @override
  void initState() { super.initState(); _focus.addListener(() => setState(() => _focused = _focus.hasFocus)); }
  @override
  void dispose() { _focus.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.error != null;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (widget.required) _FieldLabel.required(widget.label)
      else _FieldLabel(widget.label, optional: true),
      const SizedBox(height: 7),
      AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: _focused ? _T.white : _T.slate50,
          borderRadius: BorderRadius.circular(_T.r),
          border: Border.all(
            color: hasError ? _T.red : (_focused ? _T.blue : _T.slate200),
            width: (_focused || hasError) ? 1.5 : 1,
          ),
        ),
        child: Row(children: [
          Expanded(
            child: TextField(
              controller:   widget.controller,
              focusNode:    _focus,
              onChanged:    widget.onChanged,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
              style: const TextStyle(fontSize: 13, color: _T.ink, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                hintText:  widget.hint,
                hintStyle: const TextStyle(fontSize: 13, color: _T.slate300),
                prefixIcon: const Icon(Icons.tag_rounded, size: 15, color: _T.slate400),
                border:         InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 13, horizontal: 12),
              ),
            ),
          ),
          if (widget.suffix != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(widget.suffix!,
                  style: const TextStyle(fontSize: 12,
                      fontWeight: FontWeight.w700, color: _T.slate500)),
            ),
        ]),
      ),
      if (hasError)
        Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Row(children: [
            const Icon(Icons.error_outline_rounded, size: 11, color: _T.red),
            const SizedBox(width: 4),
            Text(widget.error!, style: const TextStyle(fontSize: 11,
                color: _T.red, fontWeight: FontWeight.w500)),
          ]),
        ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FIELD LABEL — verbatim from create_task_screen.dart
// ─────────────────────────────────────────────────────────────────────────────
class _FieldLabel extends StatelessWidget {
  final String text; final bool optional, isRequired; final String? optionalNote;
  const _FieldLabel(this.text, {this.optional = false, this.optionalNote}) : isRequired = false;
  const _FieldLabel.required(this.text) : optional = false, isRequired = true, optionalNote = null;

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _T.ink3)),
      if (isRequired) ...[const SizedBox(width: 3),
        const Text('*', style: TextStyle(color: _T.red, fontSize: 13, fontWeight: FontWeight.w700))],
      if (optional) ...[const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          decoration: BoxDecoration(color: _T.slate100, borderRadius: BorderRadius.circular(4)),
          child: Text(optionalNote ?? 'Optional', style: const TextStyle(
              fontSize: 9.5, fontWeight: FontWeight.w600, color: _T.slate400, letterSpacing: 0.2)),
        )],
    ]);
}

// ─────────────────────────────────────────────────────────────────────────────
// MISC SHARED WIDGETS
// ─────────────────────────────────────────────────────────────────────────────
class _StockPill extends StatelessWidget {
  final String label; final Color color, bg;
  const _StockPill({required this.label, required this.color, required this.bg});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(99)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 5, height: 5, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 5),
      Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    ]),
  );
}

class _StatChip extends StatelessWidget {
  final String value, label; final Color color, bg;
  const _StatChip({required this.value, required this.label, required this.color, required this.bg});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(99)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color)),
      const SizedBox(width: 5),
      Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: color)),
    ]),
  );
}

class _FilterTab extends StatelessWidget {
  final String label, selected; final int count; final VoidCallback onTap;
  const _FilterTab({required this.label, required this.selected,
    required this.count, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final active = selected == label;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 130),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: active ? _T.blue : Colors.transparent,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: active ? _T.blue : _T.slate200),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(label, style: TextStyle(
            fontSize: 11.5, fontWeight: FontWeight.w600,
            color: active ? _T.white : _T.slate500,
          )),
          if (count > 0) ...[
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color:        active ? Colors.white.withOpacity(0.25) : _T.slate100,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text('$count', style: TextStyle(
                fontSize: 10.5, fontWeight: FontWeight.w700,
                color: active ? _T.white : _T.slate500,
              )),
            ),
          ],
        ]),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller; final ValueChanged<String> onChanged;
  const _SearchBar({required this.controller, required this.onChanged});
  @override
  Widget build(BuildContext context) => Container(
    height: 36,
    decoration: BoxDecoration(color: _T.slate50,
        borderRadius: BorderRadius.circular(_T.r), border: Border.all(color: _T.slate200)),
    child: TextField(
      controller: controller, onChanged: onChanged,
      style: const TextStyle(fontSize: 13, color: _T.ink),
      decoration: InputDecoration(
        hintText:  'Search materials…',
        hintStyle: const TextStyle(fontSize: 13, color: _T.slate300),
        prefixIcon: const Icon(Icons.search_rounded, size: 15, color: _T.slate400),
        suffixIcon: controller.text.isNotEmpty
            ? GestureDetector(
                onTap: () { controller.clear(); onChanged(''); },
                child: const Icon(Icons.close_rounded, size: 14, color: _T.slate400))
            : null,
        border: InputBorder.none, isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 9),
      ),
    ),
  );
}

class _MetricCell extends StatelessWidget {
  final String label, value; final IconData icon; final Color color;
  const _MetricCell({required this.label, required this.value,
    required this.icon, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(color: _T.slate50,
        borderRadius: BorderRadius.circular(_T.r), border: Border.all(color: _T.slate200)),
    child: Row(children: [
      Container(width: 32, height: 32,
        decoration: BoxDecoration(color: color.withOpacity(0.10),
            borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 15, color: color)),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
            color: _T.slate400, letterSpacing: 0.3)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _T.ink3)),
      ])),
    ]),
  );
}

class _StockBar extends StatelessWidget {
  final double current, min;
  const _StockBar({required this.current, required this.min});
  @override
  Widget build(BuildContext context) {
    final ratio  = (current / (min * 2)).clamp(0.0, 1.0);
    final Color barColor = current <= 0 ? _T.red : current < min ? _T.amber : _T.green;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text('Stock level', style: const TextStyle(fontSize: 11, color: _T.slate400)),
        const Spacer(),
        Text('${(ratio * 100).round()}%',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: barColor)),
      ]),
      const SizedBox(height: 6),
      ClipRRect(
        borderRadius: BorderRadius.circular(99),
        child: LinearProgressIndicator(
          value:           ratio,
          minHeight:       6,
          backgroundColor: _T.slate100,
          color:           barColor,
        ),
      ),
      const SizedBox(height: 5),
      Text('Min: ${_fmtStock(min)}  ·  Target: ${_fmtStock(min * 2)}',
          style: const TextStyle(fontSize: 10.5, color: _T.slate400)),
    ]);
  }
}

class _DetailRow extends StatelessWidget {
  final String label, value; final bool isLast;
  const _DetailRow({required this.label, required this.value, this.isLast = false});
  @override
  Widget build(BuildContext context) => Column(children: [
    Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(children: [
        SizedBox(width: 120,
          child: Text(label, style: const TextStyle(fontSize: 12, color: _T.slate400))),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 13,
            fontWeight: FontWeight.w600, color: _T.ink3))),
      ]),
    ),
    if (!isLast) const Divider(height: 1, color: _T.slate100),
  ]);
}

class _TransactionRow extends StatelessWidget {
  final dynamic transaction;
  final String  unit;
  const _TransactionRow({required this.transaction, required this.unit});
  @override
  Widget build(BuildContext context) {
    final isIn   = transaction.type == 'in';
    final color  = isIn ? _T.green : _T.red;
    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(children: [
          Container(width: 28, height: 28,
            decoration: BoxDecoration(color: isIn ? _T.green50 : _T.red50,
                borderRadius: BorderRadius.circular(7)),
            child: Icon(isIn ? Icons.add_rounded : Icons.remove_rounded,
                size: 14, color: color)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(isIn ? 'Stock In' : 'Stock Out',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
            if (transaction.note != null)
              Text(transaction.note!, style: const TextStyle(fontSize: 11.5, color: _T.slate400)),
          ])),
          Text('${isIn ? '+' : '−'}${_fmtStock(transaction.qty)} $unit',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
        ]),
      ),
      const Divider(height: 1, color: _T.slate100),
    ]);
  }
}

class _EmptyListState extends StatelessWidget {
  final bool hasSearch;
  const _EmptyListState({required this.hasSearch});
  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(hasSearch ? Icons.search_off_rounded : Icons.layers_clear_outlined,
          size: 28, color: _T.slate300),
      const SizedBox(height: 10),
      Text(hasSearch ? 'No results' : 'No materials yet',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _T.slate400)),
      const SizedBox(height: 4),
      Text(hasSearch ? 'Try adjusting your search or filter' : 'Click Add Material to get started',
          style: const TextStyle(fontSize: 12, color: _T.slate300)),
    ]),
  );
}

class _IdlePane extends StatelessWidget {
  const _IdlePane();
  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 56, height: 56,
        decoration: BoxDecoration(color: _T.slate100,
            borderRadius: BorderRadius.circular(14), border: Border.all(color: _T.slate200)),
        child: const Icon(Icons.layers_outlined, size: 26, color: _T.slate400)),
      const SizedBox(height: 14),
      const Text('Select a material to view details',
          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: _T.slate400)),
      const SizedBox(height: 4),
      const Text('or click Add Material to create a new one',
          style: TextStyle(fontSize: 12, color: _T.slate300)),
    ]),
  );
}

class _AlertDialog extends StatelessWidget {
  final IconData icon; final Color color, bg;
  final String   title, body, cta;
  const _AlertDialog({required this.icon, required this.color, required this.bg,
    required this.title, required this.body, required this.cta});
  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: Colors.transparent,
    child: Container(
      width: 380,
      decoration: BoxDecoration(color: _T.white,
          borderRadius: BorderRadius.circular(_T.rXl), border: Border.all(color: _T.slate200),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.10),
              blurRadius: 24, offset: const Offset(0, 8))]),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 24),
        Container(width: 50, height: 50,
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.2))),
          child: Icon(icon, size: 22, color: color)),
        const SizedBox(height: 14),
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _T.ink)),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(body, textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: _T.slate400)),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            style: FilledButton.styleFrom(
              backgroundColor: _T.blue,
              minimumSize:     const Size(double.infinity, 44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_T.r)),
            ),
            child: Text(cta, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          ),
        ),
      ]),
    ),
  );
}

class _ValidationDialog extends StatelessWidget {
  final List<String> errors;
  const _ValidationDialog({required this.errors});
  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: Colors.transparent,
    child: Container(
      width: 460,
      decoration: BoxDecoration(color: _T.white,
          borderRadius: BorderRadius.circular(_T.rXl), border: Border.all(color: _T.slate200),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.10),
              blurRadius: 24, offset: const Offset(0, 8))]),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 16, 0),
          child: Row(children: [
            Container(width: 40, height: 40,
              decoration: BoxDecoration(color: _T.amber50, shape: BoxShape.circle,
                  border: Border.all(color: _T.amber.withOpacity(0.2))),
              child: const Icon(Icons.warning_amber_rounded, size: 18, color: _T.amber)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Validation Warnings', style: TextStyle(fontSize: 16,
                  fontWeight: FontWeight.w700, color: _T.ink)),
              Text('${errors.length} row${errors.length == 1 ? '' : 's'} could not be imported',
                  style: const TextStyle(fontSize: 12, color: _T.slate400)),
            ])),
            Material(color: Colors.transparent, borderRadius: BorderRadius.circular(_T.r),
              child: InkWell(onTap: () => Navigator.of(context).pop(),
                borderRadius: BorderRadius.circular(_T.r),
                child: Container(width: 32, height: 32,
                  decoration: BoxDecoration(border: Border.all(color: _T.slate200),
                      borderRadius: BorderRadius.circular(_T.r)),
                  child: const Icon(Icons.close_rounded, size: 15, color: _T.slate400)))),
          ]),
        ),
        const Padding(padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Divider(height: 1, color: _T.slate100)),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          constraints: const BoxConstraints(maxHeight: 200),
          decoration: BoxDecoration(color: _T.slate50,
              borderRadius: BorderRadius.circular(_T.rLg), border: Border.all(color: _T.slate200)),
          child: ListView.separated(
            padding:     const EdgeInsets.all(12),
            shrinkWrap:  true,
            itemCount:   errors.length > 5 ? 5 : errors.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.error_outline_rounded, size: 13, color: _T.red),
              const SizedBox(width: 8),
              Expanded(child: Text(errors[i],
                  style: const TextStyle(fontSize: 12, color: _T.ink3))),
            ]),
          ),
        ),
        if (errors.length > 5)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('… and ${errors.length - 5} more',
                style: const TextStyle(fontSize: 12, color: _T.slate400,
                    fontStyle: FontStyle.italic)),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          child: FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            style: FilledButton.styleFrom(backgroundColor: _T.blue,
              minimumSize: const Size(double.infinity, 44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_T.r)),
            ),
            child: const Text('Continue', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          ),
        ),
      ]),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────────────────────────────────────────
String _fmtStock(double v) =>
    v == v.truncateToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);
// ─────────────────────────────────────────────────────────────────────────────
// manage_materials_screen.dart  (DesktopMaterialsManagementScreen)
//
// Inventory-aware materials management.  Real inventory model:
//   Material        = a category / type  (e.g. "Vinyl Roll 3.2m")
//   Batch (StockIn) = a real physical item received — one inventory unit
//   Consumption     = a StockOut whose sourceTransactionId → parent batch
//
// Layout: left list → right panel (topbar + KPI strip + batch table | detail)
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:io';

import 'package:card_loading/card_loading.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/core/models/material.dart';
import 'package:smooflow/core/models/project.dart';
import 'package:smooflow/core/models/stock_transaction.dart';
import 'package:smooflow/core/models/task.dart';
import 'package:smooflow/extensions/stock_transaction_list_ext.dart';
import 'package:smooflow/providers/material_provider.dart';
import 'package:smooflow/providers/project_provider.dart';
import 'package:smooflow/providers/task_provider.dart';
import 'package:smooflow/screens/desktop/components/action_buttons.dart';
import 'package:smooflow/screens/desktop/components/dialog_buttons.dart';
import 'package:smooflow/screens/desktop/components/field_label.dart';
import 'package:smooflow/screens/desktop/components/inventory_features.dart';
import 'package:smooflow/screens/desktop/components/notification_toast.dart';
import 'package:smooflow/screens/desktop/components/smoofield.dart';
import 'package:smooflow/screens/desktop/components/stock_pill.dart';
import 'package:smooflow/screens/desktop/helpers/fmt_transaction_note.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:smooflow/screens/desktop/helpers/fmt_stock.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TOKENS
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

// ─────────────────────────────────────────────────────────────────────────────
// ROOT SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class DesktopMaterialsManagementScreen extends ConsumerStatefulWidget {
  const DesktopMaterialsManagementScreen({super.key});

  @override
  ConsumerState<DesktopMaterialsManagementScreen> createState() =>
      _ManageMaterialsScreenState();
}

class _ManageMaterialsScreenState
    extends ConsumerState<DesktopMaterialsManagementScreen> {
  MaterialModel? _selected;
  bool _showCreate = false;

  final _searchCtrl = TextEditingController();
  String _filter = 'All';

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(materialNotifierProvider.notifier).fetchMaterials(),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _selectMaterial(MaterialModel m) => setState(() {
    _selected = m;
    _showCreate = false;
  });

  void _openCreate() => setState(() {
    _selected = null;
    _showCreate = true;
  });

  void _closePanel() => setState(() {
    _selected = null;
    _showCreate = false;
  });

  void _onSaved() {
    _closePanel();
    ref.read(materialNotifierProvider.notifier).fetchMaterials();
  }

  void _showImportDialog() {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.35),
      builder:
          (_) => _CsvImportDialog(
            onConfirm: () {
              Navigator.of(context).pop();
              _pickCSVFile();
            },
          ),
    );
  }

  void _showWriteOffDialog(MaterialModel material) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.35),
      builder:
          (_) => WriteOffDialog(
            material: material,
            onConfirm: (qty, note) async {
              Navigator.of(context).pop();
              // stockOut with the encoded note — reuses existing provider method
              await ref
                  .read(materialNotifierProvider.notifier)
                  .stockOut(material.id, qty, notes: note);
              ref.read(materialNotifierProvider.notifier).fetchMaterials();
              AppToast.show(
                message: 'Write-off recorded',
                subtitle: '${fmtStock(qty)} ${material.unitShort} removed',
                icon: Icons.remove_circle_outline_rounded,
                color: _T.red,
              );
            },
          ),
    );
  }

  void _showQuickStockInDialog(MaterialModel material) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.35),
      builder:
          (_) => _StockAdjustDialog(
            material: material,
            onConfirm: (qty, note) async {
              Navigator.of(context).pop();
              await ref
                  .read(materialNotifierProvider.notifier)
                  .stockIn(material.id, qty, notes: note);
              ref.read(materialNotifierProvider.notifier).fetchMaterials();
              AppToast.show(
                message: 'Batch received',
                subtitle: '${fmtStock(qty)} ${material.unitShort} added',
                icon: Icons.add_rounded,
                color: _T.green,
              );
            },
          ),
    );
  }

  Future<void> _pickCSVFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (result == null || result.files.isEmpty) return;
    if (!mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    final file = File(result.files.single.path!);
    final csvString = await file.readAsString();
    final csvData = const CsvToListConverter().convert(
      csvString,
      eol: '\n',
      shouldParseNumbers: false,
    );
    if (!mounted) return;
    Navigator.of(context).pop();
    if (csvData.isEmpty) {
      _showErrorDialog('Empty CSV', 'The CSV file appears to be empty.');
      return;
    }
    final materials = await _parseCSVData(csvData);
    if (materials.isEmpty) return;
    await ref
        .read(materialNotifierProvider.notifier)
        .createMaterials(materials);
    ref.read(materialNotifierProvider.notifier).fetchMaterials();
    _snack(
      '${materials.length} material${materials.length == 1 ? '' : 's'} imported',
      isError: false,
    );
  }

  Future<List<MaterialModel>> _parseCSVData(List<List<dynamic>> csvData) async {
    final headers =
        csvData[0].map((h) => h.toString().toLowerCase().trim()).toList();
    int col(List<String> ns) {
      for (final n in ns) {
        final i = headers.indexWhere((h) => h == n);
        if (i != -1) return i;
      }
      return -1;
    }

    final nameIdx = col(['name']);
    final typeIdx = col([
      'measure type',
      'measuretype',
      'measure_type',
      'type',
    ]);
    final descIdx = col(['description', 'desc']);
    final minStockIdx = col([
      'min stock level',
      'minstocklevel',
      'min_stock_level',
      'min stock',
      'minstock',
      'min_stock',
      'minimum stock',
    ]);
    if (nameIdx == -1) {
      _showErrorDialog('Missing Column', '"name" column not found.');
      return [];
    }
    if (typeIdx == -1) {
      _showErrorDialog('Missing Column', '"measure type" column not found.');
      return [];
    }
    String? cell(List<dynamic> row, int idx) =>
        (idx == -1 || idx >= row.length) ? null : row[idx]?.toString();
    MeasureType? parseMT(String? v) {
      if (v == null) return null;
      final s = v.trim().replaceAll(' ', '_').toLowerCase();
      return switch (s) {
        'running_meter' || 'runningmeter' => MeasureType.running_meter,
        'item_quantity' ||
        'itemquantity' ||
        'quantity' => MeasureType.item_quantity,
        'liters' || 'liter' || 'l' => MeasureType.liters,
        'square_meter' || 'squaremeter' || 'sqm' => MeasureType.square_meter,
        'kilograms' || 'kilogram' || 'kg' => MeasureType.kilograms,
        _ => null,
      };
    }

    final materials = <MaterialModel>[];
    final errors = <String>[];
    for (int i = 1; i < csvData.length; i++) {
      final row = csvData[i];
      if (row.isEmpty || row.every((c) => c.toString().trim().isEmpty))
        continue;
      final name = cell(row, nameIdx)?.trim();
      if (name == null || name.isEmpty) {
        errors.add('Row ${i + 1}: name is required');
        continue;
      }
      final mt = parseMT(cell(row, typeIdx));
      if (mt == null) {
        errors.add('Row ${i + 1}: invalid measure type');
        continue;
      }
      final minStock =
          double.tryParse(cell(row, minStockIdx)?.trim() ?? '') ?? 0.0;
      if (minStock < 0) {
        errors.add('Row ${i + 1}: min stock cannot be negative');
        continue;
      }
      materials.add(
        MaterialModel.create(
          name: name,
          description: cell(row, descIdx)?.trim(),
          measureType: mt,
          minStockLevel: minStock,
        ),
      );
    }
    if (errors.isNotEmpty && mounted) _showValidationDialog(errors);
    return materials;
  }

  void _showErrorDialog(String title, String msg) => showDialog<void>(
    context: context,
    barrierColor: Colors.black.withOpacity(0.35),
    builder:
        (_) => _AlertDialog(
          icon: Icons.error_outline_rounded,
          color: _T.red,
          bg: _T.red50,
          title: title,
          body: msg,
          cta: 'OK',
        ),
  );
  void _showValidationDialog(List<String> errors) => showDialog<void>(
    context: context,
    barrierColor: Colors.black.withOpacity(0.35),
    builder: (_) => _ValidationDialog(errors: errors),
  );
  void _snack(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_outline_rounded,
              size: 15,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                msg,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: _T.ink,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_T.r),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Only read summary stats from provider here — no isLoading dependency.
    // The list panel is extracted into _MaterialListPanel which owns its own
    // provider watch, so selecting a material won't cause the list to flash.
    final all = ref.watch(materialNotifierProvider.select((s) => s.materials));
    final totalMaterials = all.length;
    final lowStock =
        all.where((m) => m.isLowStock && !m.isCriticalStock).length;
    final outOfStock = all.where((m) => m.isCriticalStock).length;
    final showPanel = _selected != null || _showCreate;

    return Scaffold(
      backgroundColor: _T.slate50,
      body: Column(
        children: [
          _Topbar(onAdd: _openCreate, onImport: _showImportDialog),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── LEFT list panel — isolated widget so selection state changes
                //    in the parent do NOT trigger a provider re-read here. ────────
                SizedBox(
                  width: 400,
                  child: _MaterialListPanel(
                    selectedId: _selected?.id,
                    filter: _filter,
                    searchCtrl: _searchCtrl,
                    totalMaterials: totalMaterials,
                    lowStock: lowStock,
                    outOfStock: outOfStock,
                    onFilterChanged: (f) => setState(() => _filter = f),
                    onSearchChanged: () => setState(() {}),
                    onSelect: _selectMaterial,
                    onQuickReceive: _showQuickStockInDialog,
                  ),
                ),

                // ── RIGHT panel ──────────────────────────────────────────────────
                Expanded(
                  child:
                      showPanel
                          ? (_showCreate
                              ? _CreatePanel(
                                key: const ValueKey('create'),
                                onClose: _closePanel,
                                onSaved: _onSaved,
                              )
                              : _DetailPanel(
                                key: ValueKey(_selected!.id),
                                material: _selected!,
                                onClose: _closePanel,
                                onUpdate: () {
                                  ref
                                      .read(materialNotifierProvider.notifier)
                                      .fetchMaterials();
                                  setState(() {});
                                },
                              ))
                          : const _IdlePane(),
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
// MATERIAL LIST PANEL  (extracted widget)
//
// Owns its own `ref.watch(materialNotifierProvider)` so that selection-state
// changes in the parent screen do NOT cause this widget to re-read the
// provider.  The only rebuilds happen when:
//   • the provider emits new data  (real list update)
//   • selectedId / filter / search props change  (cosmetic highlight only)
//
// Loading guard:  `isLoading && materials.isEmpty`
//   If we already have a populated list and the provider briefly flips
//   isLoading=true (e.g. fetchMaterialTransactions in the detail panel),
//   we keep showing the list instead of flashing a spinner.
// ─────────────────────────────────────────────────────────────────────────────
class _MaterialListPanel extends ConsumerWidget {
  final String? selectedId;
  final String filter;
  final TextEditingController searchCtrl;
  final int totalMaterials, lowStock, outOfStock;
  final ValueChanged<String> onFilterChanged;
  final VoidCallback onSearchChanged;
  final ValueChanged<MaterialModel> onSelect;
  final ValueChanged<MaterialModel> onQuickReceive;

  const _MaterialListPanel({
    required this.selectedId,
    required this.filter,
    required this.searchCtrl,
    required this.totalMaterials,
    required this.lowStock,
    required this.outOfStock,
    required this.onFilterChanged,
    required this.onSearchChanged,
    required this.onSelect,
    required this.onQuickReceive,
  });

  String get _q => searchCtrl.text.trim().toLowerCase();

  List<MaterialModel> _filtered(List<MaterialModel> all) {
    var list = all;
    if (filter == 'Low Stock')
      list = list.where((m) => m.isLowStock && !m.isCriticalStock).toList();
    if (filter == 'Out of Stock')
      list = list.where((m) => m.isCriticalStock).toList();
    if (_q.isNotEmpty)
      list = list.where((m) => m.name.toLowerCase().contains(_q)).toList();
    return list;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(materialNotifierProvider);
    final all = state.materials;
    final filtered = _filtered(all);

    // Only show skeleton on the very first load (no data yet).
    // Once the list is populated we never replace it with a spinner,
    // even if isLoading briefly flips true (e.g. during transaction fetches).
    final showSkeleton = state.isLoading && all.isEmpty;

    return Container(
      decoration: const BoxDecoration(
        color: _T.white,
        border: Border(right: BorderSide(color: _T.slate200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Stat chips ────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: _T.slate200)),
            ),
            child: Row(
              children: [
                _StatChip(
                  value: '$totalMaterials',
                  label: 'Total',
                  color: _T.slate500,
                  bg: _T.slate100,
                ),
                const SizedBox(width: 8),
                _StatChip(
                  value: '$lowStock',
                  label: 'Low stock',
                  color: _T.amber,
                  bg: _T.amber50,
                ),
                const SizedBox(width: 8),
                _StatChip(
                  value: '$outOfStock',
                  label: 'Out of stock',
                  color: _T.red,
                  bg: _T.red50,
                ),
              ],
            ),
          ),
          // ── Search + filters ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
            child: Column(
              children: [
                _SearchBar(
                  controller: searchCtrl,
                  onChanged: (_) => onSearchChanged(),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _FilterTab(
                      label: 'All',
                      selected: filter,
                      count: all.length,
                      onTap: () => onFilterChanged('All'),
                    ),
                    const SizedBox(width: 6),
                    _FilterTab(
                      label: 'Low Stock',
                      selected: filter,
                      count: lowStock,
                      onTap: () => onFilterChanged('Low Stock'),
                    ),
                    const SizedBox(width: 6),
                    _FilterTab(
                      label: 'Out of Stock',
                      selected: filter,
                      count: outOfStock,
                      onTap: () => onFilterChanged('Out of Stock'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // ── List body ────────────────────────────────────────────────────
          Expanded(
            child:
                showSkeleton
                    ? const _SkeletonMaterialList()
                    : filtered.isEmpty
                    ? _EmptyListState(
                      hasSearch: _q.isNotEmpty || filter != 'All',
                    )
                    : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 4),
                      itemBuilder: (_, i) {
                        final m = filtered[i];
                        return _MaterialListTile(
                          material: m,
                          isSelected: selectedId == m.id,
                          onTap: () => onSelect(m),
                          onQuickReceive: () => onQuickReceive(m),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SKELETON MATERIAL LIST  — shown only on the initial empty-state load
// Uses varying name-line widths so tiles feel organic, not mechanical.
// ─────────────────────────────────────────────────────────────────────────────
class _SkeletonMaterialList extends StatelessWidget {
  const _SkeletonMaterialList();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: 4),
      itemBuilder: (_, i) => _SkeletonMaterialTile(index: i),
    );
  }
}

class _SkeletonMaterialTile extends StatelessWidget {
  final int index;
  const _SkeletonMaterialTile({required this.index});

  static const _nameWidths = [130.0, 100.0, 150.0, 90.0, 120.0, 110.0];

  @override
  Widget build(BuildContext context) {
    final nameWidth = _nameWidths[index % _nameWidths.length];
    final theme = CardLoadingTheme(
      colorOne: _T.slate100,
      colorTwo: _T.slate200,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _T.white,
        borderRadius: BorderRadius.circular(_T.r),
        border: Border.all(color: _T.slate200),
      ),
      child: Row(
        children: [
          // Icon placeholder
          CardLoading(
            height: 26,
            width: 26,
            borderRadius: BorderRadius.circular(9),
            cardLoadingTheme: theme,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name line — varied width per tile
                CardLoading(
                  height: 11,
                  width: nameWidth,
                  borderRadius: BorderRadius.circular(4),
                  cardLoadingTheme: theme,
                ),
                const SizedBox(height: 5),
                // Sub-line (stock amount)
                CardLoading(
                  height: 9,
                  width: 70,
                  borderRadius: BorderRadius.circular(4),
                  cardLoadingTheme: theme,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Stock pill placeholder
          CardLoading(
            height: 18,
            width: 54,
            borderRadius: BorderRadius.circular(99),
            cardLoadingTheme: theme,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TOPBAR
// ─────────────────────────────────────────────────────────────────────────────
class _Topbar extends StatelessWidget {
  final VoidCallback onAdd, onImport;
  const _Topbar({required this.onAdd, required this.onImport});

  @override
  Widget build(BuildContext context) => Container(
    height: 58,
    padding: const EdgeInsets.symmetric(horizontal: 20),
    decoration: const BoxDecoration(
      color: _T.white,
      border: Border(bottom: BorderSide(color: _T.slate200)),
    ),
    child: Row(
      children: [
        const Icon(CupertinoIcons.cube_box_fill, size: 27, color: _T.ink),
        const SizedBox(width: 12),
        const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Manage Materials',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _T.ink,
                letterSpacing: -0.2,
              ),
            ),
            Text(
              'Inventory stock management',
              style: TextStyle(
                fontSize: 10.5,
                color: _T.slate400,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const Spacer(),
        GhostActionButton(
          label: 'Import CSV',
          icon: Icons.upload_file_outlined,
          color: _T.slate500,
          onTap: onImport,
        ),
        const SizedBox(width: 10),
        GreenActionButton(
          label: 'Material',
          icon: Icons.add_rounded,
          onTap: onAdd,
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// MATERIAL LIST TILE
// ─────────────────────────────────────────────────────────────────────────────
class _MaterialListTile extends StatefulWidget {
  final MaterialModel material;
  final bool isSelected;
  final VoidCallback onTap;
  final Function() onQuickReceive;
  const _MaterialListTile({
    required this.material,
    required this.isSelected,
    required this.onTap,
    required this.onQuickReceive,
  });
  @override
  State<_MaterialListTile> createState() => _MaterialListTileState();
}

class _MaterialListTileState extends State<_MaterialListTile> {
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
        child: Container(
          decoration: BoxDecoration(
            color:
                selected
                    ? _T.blue50
                    : _hovered
                    ? _T.slate50
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(_T.r),
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 130),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(_T.r),
              border: Border.all(
                color: selected ? _T.blue.withOpacity(0.35) : _T.slate200,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Stack(
              alignment: Alignment.centerRight,
              children: [
                Row(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color:
                            selected ? _T.blue.withOpacity(0.10) : _T.slate100,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Icon(
                        Icons.layers_outlined,
                        size: 17,
                        color: selected ? _T.blue : _T.slate500,
                      ),
                    ),
                    const SizedBox(width: 12),
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
                          Text(
                            '${fmtStock(m.currentStock)} ${m.unitShort}',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: _T.slate400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (selected) ...[
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: _T.blue,
                      ),
                    ],
                  ],
                ),
                Container(
                  padding: EdgeInsets.only(right: 12, left: 5),
                  child: StockPill(
                    label: stockLabel,
                    color: stockColor,
                    bg: stockBg,
                    collapsed: !_hovered,
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
// DETAIL PANEL
// ─────────────────────────────────────────────────────────────────────────────
class _DetailPanel extends ConsumerStatefulWidget {
  final MaterialModel material;
  final VoidCallback onClose, onUpdate;
  const _DetailPanel({
    super.key,
    required this.material,
    required this.onClose,
    required this.onUpdate,
  });
  @override
  ConsumerState<_DetailPanel> createState() => _DetailPanelState();
}

class _DetailPanelState extends ConsumerState<_DetailPanel> {
  StockTransaction? _selectedBatch;

  void _showWriteOffDialog() {
    if (_selectedBatch == null) return;

    // Get the parent screen's method via a callback, or duplicate the
    // dialog call here:
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.35),
      builder:
          (_) => WriteOffDialog(
            material: widget.material,
            onConfirm: (qty, note) async {
              Navigator.of(context).pop();
              await ref
                  .read(materialNotifierProvider.notifier)
                  .stockOut(_selectedBatch!.barcode!, qty, notes: note);
              widget.onUpdate();
              _snack(
                'Write-off recorded — ${fmtStock(qty)} '
                '${widget.material.unitShort} removed',
                isError: false,
              );
            },
          ),
    );
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref
          .read(materialNotifierProvider.notifier)
          .fetchMaterialTransactions(widget.material.id),
    );
  }

  List<StockTransaction> _allTxns() =>
      ref
          .watch(materialNotifierProvider)
          .byMaterial(widget.material.id)
          .toList();

  List<StockTransaction> _batches(List<StockTransaction> all) =>
      all.where((t) => t.type == TransactionType.stockIn).toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  List<StockTransaction> _consumptions(
    List<StockTransaction> all,
    String batchBarcode,
  ) =>
      all
          .where(
            (t) =>
                t.type == TransactionType.stockOut && t.barcode == batchBarcode,
          )
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  double _remaining(StockTransaction batch, List<StockTransaction> all) {
    final consumed = _consumptions(
      all,
      batch.id,
    ).fold(0.0, (s, t) => s + t.quantity);
    return (batch.quantity - consumed).clamp(0.0, double.infinity);
  }

  void _showStockInDialog() {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.35),
      builder:
          (_) => _StockAdjustDialog(
            material: widget.material,
            onConfirm: (qty, note) async {
              Navigator.of(context).pop();
              await ref
                  .read(materialNotifierProvider.notifier)
                  .stockIn(widget.material.id, qty, notes: note);
              widget.onUpdate();
              _snack(
                'Batch received — ${fmtStock(qty)} ${widget.material.unitShort} added',
                isError: false,
              );
            },
          ),
    );
  }

  void _snack(String msg, {required bool isError}) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(
            isError
                ? Icons.error_outline_rounded
                : Icons.check_circle_outline_rounded,
            size: 15,
            color: Colors.white,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              msg,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
      backgroundColor: _T.ink,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_T.r)),
      duration: const Duration(seconds: 3),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final m = widget.material;
    final all = _allTxns();
    final batches = _batches(all);

    final totalReceived = batches.fold(0.0, (s, b) => s + b.quantity);
    final totalConsumed = all
        .where((t) => t.type == TransactionType.stockOut)
        .fold(0.0, (s, t) => s + t.quantity);
    final totalRemaining = batches.fold(0.0, (s, b) => s + _remaining(b, all));

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

    final List<StockTransaction> consumptions =
        _selectedBatch != null
            ? (all
                .where(
                  (t) =>
                      t.type == TransactionType.stockOut &&
                      t.barcode == _selectedBatch!.barcode,
                )
                .toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt)))
            : [];

    return Container(
      decoration: const BoxDecoration(
        color: _T.slate50,
        border: Border(left: BorderSide(color: _T.slate200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Top bar ──────────────────────────────────────────────────────
          Container(
            height: 58,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: const BoxDecoration(
              color: _T.white,
              border: Border(bottom: BorderSide(color: _T.slate200)),
            ),
            child: Row(
              children: [
                Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(_T.r),
                  child: InkWell(
                    onTap: widget.onClose,
                    borderRadius: BorderRadius.circular(_T.r),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: _T.slate100,
                        borderRadius: BorderRadius.circular(_T.r),
                        border: Border.all(color: _T.slate200),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 17,
                        color: _T.ink3,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // const Icon(Icons.layers_outlined, size: 26, color: _T.blue),
                // const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        m.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _T.ink,
                          letterSpacing: -0.2,
                        ),
                      ),
                      Text(
                        m.unit,
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: _T.slate400,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Write-off ghost button
                if (_selectedBatch != null)
                  GhostActionButton(
                    label: 'Write Off',
                    icon: Icons.remove_circle_outline_rounded,
                    color: _T.red,
                    onTap: _showWriteOffDialog,
                  ),
                const SizedBox(width: 8),
                // Receive batch primary button (unchanged)
                GreenActionButton(
                  label: 'Batch',
                  icon: Icons.add_rounded,
                  onTap: _showStockInDialog,
                ),
              ],
            ),
          ),

          // ── Body: batch table + batch detail side-by-side ─────────────────
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 55,
                  child: _BatchInventoryPanel(
                    batches: batches,
                    allTxns: all,
                    unit: m.unitShort,
                    selectedBatchId: _selectedBatch?.id,
                    selectedBatchBarcode: _selectedBatch?.barcode!,
                    remaining:
                        (b) => (b.quantity - consumptions.totalQuantity).clamp(
                          0.0,
                          double.infinity,
                        ),
                    onSelect:
                        (b) => setState(
                          () =>
                              _selectedBatch =
                                  (_selectedBatch?.id == b.id) ? null : b,
                        ),
                    // kpi: _KpiChip(
                    //   label: 'Remaining',
                    //   value: '${fmtStock(totalRemaining)} ${m.unitShort}',
                    //   color: stockColor,
                    //   bg: stockBg.withValues(alpha: 0.5),
                    // ),
                  ),
                ),

                Container(width: 1, color: _T.slate200),

                Expanded(
                  flex: 45,
                  child:
                      _selectedBatch == null
                          ? _BatchIdlePane()
                          : _BatchDetailPanel(
                            key: ValueKey(_selectedBatch!.id),
                            batch: _selectedBatch!,
                            consumptions: consumptions,
                            unit: m.unitShort,
                            remaining:
                                _selectedBatch!.quantity -
                                consumptions.totalQuantity,
                          ),
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
// KPI CHIP
// ─────────────────────────────────────────────────────────────────────────────
class _KpiChip extends StatelessWidget {
  final String label, value;
  final Color color, bg;
  const _KpiChip({
    required this.label,
    required this.value,
    required this.color,
    required this.bg,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(_T.r),
      border: Border.all(color: color.withOpacity(0.25)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
            color: color.withOpacity(0.7),
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          value,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// BATCH INVENTORY PANEL
// ─────────────────────────────────────────────────────────────────────────────
class _BatchInventoryPanel extends StatelessWidget {
  final List<StockTransaction> batches;
  final List<StockTransaction> allTxns;
  final String unit;
  final String? selectedBatchId;
  final double Function(StockTransaction) remaining;
  final ValueChanged<StockTransaction> onSelect;
  final Widget? kpi;
  final String? selectedBatchBarcode;

  const _BatchInventoryPanel({
    required this.batches,
    required this.allTxns,
    required this.unit,
    required this.selectedBatchId,
    required this.remaining,
    required this.onSelect,
    this.kpi,
    required this.selectedBatchBarcode,
  });

  double usedQuantityInBatch(String batchBarcode) =>
      allTxns
          .where(
            (txn) =>
                txn.barcode == batchBarcode &&
                txn.type == TransactionType.stockOut,
          )
          .toList()
          .totalQuantity;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
          decoration: const BoxDecoration(
            color: _T.white,
            border: Border(bottom: BorderSide(color: _T.slate100)),
          ),
          child: Stack(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Inventory Batches',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _T.ink,
                              letterSpacing: -0.1,
                            ),
                          ),
                          Text(
                            '${batches.length} batch${batches.length == 1 ? '' : 'es'} · FIFO order',
                            style: const TextStyle(
                              fontSize: 10.5,
                              color: _T.slate400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Align(alignment: Alignment.centerRight, child: kpi),
            ],
          ),
        ),

        if (batches.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.inbox_outlined, size: 26, color: _T.slate300),
                  SizedBox(height: 10),
                  Text(
                    'No batches received yet',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _T.slate400,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Click "Receive Batch" to record incoming stock',
                    style: TextStyle(fontSize: 11.5, color: _T.slate300),
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 8,
                  ),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: _T.slate100)),
                  ),
                  child: Row(
                    children: [
                      Expanded(flex: 2, child: _ColHdr('BARCODE')),
                      Expanded(flex: 2, child: _ColHdr('RECEIVED')),
                      Expanded(flex: 2, child: _ColHdr('QTY IN')),
                      Expanded(flex: 2, child: _ColHdr('CONSUMED')),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(10, 6, 10, 12),
                    itemCount: batches.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 3),
                    itemBuilder: (_, i) {
                      final b = batches[i];
                      final rem = remaining(b);
                      final consumed = usedQuantityInBatch(b.barcode!);
                      final isSelected = selectedBatchId == b.id;
                      final isEmpty = rem <= 0;

                      print("remaining: ${rem}");
                      print("remaining: ${consumed}");
                      return _BatchRow(
                        batch: b,
                        unit: unit,
                        consumed: consumed,
                        remaining: rem,
                        fifoRank: i + 1,
                        isSelected: isSelected,
                        isEmpty: isEmpty,
                        onTap: () => onSelect(b),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ColHdr extends StatelessWidget {
  final String text;
  const _ColHdr(this.text);
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 9.5,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.5,
      color: _T.slate400,
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// BATCH ROW
// ─────────────────────────────────────────────────────────────────────────────
class _BatchRow extends StatefulWidget {
  final StockTransaction batch;
  final String unit;
  final double consumed, remaining;
  final int fifoRank;
  final bool isSelected, isEmpty;
  final VoidCallback onTap;
  const _BatchRow({
    required this.batch,
    required this.unit,
    required this.consumed,
    required this.remaining,
    required this.fifoRank,
    required this.isSelected,
    required this.isEmpty,
    required this.onTap,
  });
  @override
  State<_BatchRow> createState() => _BatchRowState();
}

class _BatchRowState extends State<_BatchRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final b = widget.batch;
    final dt = b.createdAt;
    final dateStr =
        '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/${dt.year}';

    final Color pillColor;
    final Color pillBg;
    final String pillLabel;
    if (widget.isEmpty) {
      pillColor = _T.slate400;
      pillBg = _T.slate100;
      pillLabel = 'Depleted';
    } else if (widget.remaining < b.quantity * 0.25) {
      pillColor = _T.amber;
      pillBg = _T.amber50;
      pillLabel = 'Low';
    } else {
      pillColor = _T.green;
      pillBg = _T.green50;
      pillLabel = 'Available';
    }

    final sel = widget.isSelected;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            color:
                sel
                    ? _T.blue50
                    : _hovered
                    ? _T.slate50
                    : _T.white,
            borderRadius: BorderRadius.circular(_T.r),
            border: Border.all(
              color: sel ? _T.blue.withOpacity(0.4) : _T.slate200,
              width: sel ? 1.5 : 1,
            ),
          ),
          child: Stack(
            alignment: Alignment.centerRight,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (b.barcode != null)
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  b.barcode!.length > 14
                                      ? '${b.barcode!.substring(0, 14)}…'
                                      : b.barcode!,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: _T.ink3,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                            ],
                          )
                        else
                          Text(
                            'Batch #${widget.fifoRank}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _T.slate500,
                            ),
                          ),
                        if (b.notes != null)
                          Text(
                            b.notes!,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10,
                              color: _T.slate400,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      dateStr,
                      style: const TextStyle(fontSize: 11, color: _T.slate500),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '${fmtStock(b.quantity)} ${widget.unit}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: _T.ink3,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      widget.consumed > 0
                          ? '${fmtStock(widget.consumed)} ${widget.unit}'
                          : '—',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: widget.consumed > 0 ? _T.red : _T.slate300,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              AnimatedOpacity(
                opacity: sel ? 1.0 : (_hovered ? 0.5 : 0.0),
                duration: const Duration(milliseconds: 120),
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 15,
                  color: sel ? _T.blue : _T.slate400,
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
// BATCH DETAIL PANEL — drop-in replacement
//
// Changes:
//   • Notes: extracted from the stats card into a dedicated _BatchNotesCard
//     with an amber tint, quotes icon, and styled body text
//   • Consumption rows: redesigned to a two-line layout with task name
//     prominent on the first line and project + date metadata on the second
// ─────────────────────────────────────────────────────────────────────────────

class _BatchDetailPanel extends StatelessWidget {
  final StockTransaction batch;
  final List<StockTransaction> consumptions;
  final String unit;
  final double remaining;

  const _BatchDetailPanel({
    super.key,
    required this.batch,
    required this.consumptions,
    required this.unit,
    required this.remaining,
  });

  @override
  Widget build(BuildContext context) {
    final b = batch;
    final dt = b.createdAt;
    final dateStr =
        '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/${dt.year}  '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

    final consumed = consumptions.totalQuantity;
    final usePct =
        b.quantity > 0 ? (consumed / b.quantity).clamp(0.0, 1.0) : 0.0;

    final Color statusColor;
    final String statusLabel;
    final Color statusBg;
    if (remaining <= 0) {
      statusColor = _T.slate400;
      statusBg = _T.slate100;
      statusLabel = 'Depleted';
    } else if (remaining < b.quantity * 0.25) {
      statusColor = _T.amber;
      statusBg = _T.amber50;
      statusLabel = 'Low';
    } else {
      statusColor = _T.green;
      statusBg = _T.green50;
      statusLabel = 'Available';
    }

    final metaCard =
        b.notes != null ? BatchMetaCard.fromNote(b.notes!, unit) : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Section header ────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
          decoration: const BoxDecoration(
            color: _T.white,
            border: Border(bottom: BorderSide(color: _T.slate100)),
          ),
          child: Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: _T.purple50,
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(color: _T.purple.withOpacity(0.2)),
                ),
                child: const Icon(
                  Icons.inventory_rounded,
                  size: 12,
                  color: _T.purple,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Batch Detail',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _T.ink,
                        letterSpacing: -0.1,
                      ),
                    ),
                    Text(
                      b.barcode ?? 'No barcode',
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: _T.slate400,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              StockPill(label: statusLabel, color: statusColor, bg: statusBg),
            ],
          ),
        ),

        // ── Scrollable body ───────────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Stats card ────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _T.white,
                    borderRadius: BorderRadius.circular(_T.rLg),
                    border: Border.all(color: _T.slate200),
                  ),
                  child: Column(
                    children: [
                      _BatchInfoRow(
                        icon: Icons.calendar_today_outlined,
                        label: 'Received',
                        value: dateStr,
                      ),
                      const Divider(height: 16, color: _T.slate100),
                      _BatchInfoRow(
                        icon: Icons.add_circle_outline_rounded,
                        label: 'Original Qty',
                        value: '${fmtStock(remaining + consumed)} $unit',
                        valueColor: _T.green,
                      ),
                      const Divider(height: 16, color: _T.slate100),
                      _BatchInfoRow(
                        icon: Icons.remove_circle_outline_rounded,
                        label: 'Total Consumed',
                        value:
                            consumed > 0 ? '${fmtStock(consumed)} $unit' : '—',
                        valueColor: consumed > 0 ? _T.red : _T.slate300,
                      ),
                      const Divider(height: 16, color: _T.slate100),
                      _BatchInfoRow(
                        icon: Icons.inventory_2_outlined,
                        label: 'Remaining',
                        value: '${fmtStock(remaining)} $unit',
                        valueColor: statusColor,
                      ),

                      // Usage progress bar
                      if (b.quantity > 0) ...[
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(99),
                                child: LinearProgressIndicator(
                                  value: usePct,
                                  minHeight: 5,
                                  backgroundColor: _T.slate100,
                                  color: statusColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '${(usePct * 100).round()}% used',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: statusColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                if (metaCard != null) ...[const SizedBox(height: 12), metaCard],

                // ── Notes card ────────────────────────────────────────────
                // Shown only when a note exists. Amber-tinted surface to
                // distinguish it from the stats card — feels like a sticky
                // note or annotation rather than structured data.
                if (b.notes != null && b.notes!.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _BatchNotesCard(notes: b.notes!),
                ],

                const SizedBox(height: 18),

                // ── Consumption history header ─────────────────────────────
                Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: _T.red50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: _T.red.withOpacity(0.2)),
                      ),
                      child: const Icon(
                        Icons.output_rounded,
                        size: 11,
                        color: _T.red,
                      ),
                    ),
                    const SizedBox(width: 9),
                    const Text(
                      'History',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _T.ink,
                        letterSpacing: -0.1,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _T.slate100,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        '${consumptions.length} event${consumptions.length == 1 ? '' : 's'}',
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: _T.slate500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // ── Consumption list ──────────────────────────────────────
                if (consumptions.isEmpty)
                  _ConsumptionEmptyState()
                else
                  Container(
                    decoration: BoxDecoration(
                      color: _T.white,
                      borderRadius: BorderRadius.circular(_T.rLg),
                      border: Border.all(color: _T.slate200),
                    ),
                    child: Column(
                      children:
                          consumptions.asMap().entries.map((e) {
                            final isLast = e.key == consumptions.length - 1;
                            return _ConsumptionRow(
                              txn: e.value,
                              unit: unit,
                              isLast: isLast,
                            );
                          }).toList(),
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
// BATCH NOTES CARD
//
// Amber-tinted surface — immediately reads as "annotation" rather than data.
// Left accent bar (3px amber) mirrors the board lane / filter drawer motif.
// Quote icon in the header grounds the copy visually.
// ─────────────────────────────────────────────────────────────────────────────
class _BatchNotesCard extends StatelessWidget {
  final String notes;
  const _BatchNotesCard({required this.notes});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB), // amber50 with more warmth
        borderRadius: BorderRadius.circular(_T.rLg),
        border: Border.all(color: _T.amber.withOpacity(0.25)),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left accent bar
            Container(
              width: 3,
              decoration: BoxDecoration(
                color: _T.amber.withOpacity(0.6),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(_T.rLg),
                  bottomLeft: Radius.circular(_T.rLg),
                ),
              ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 11, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row
                    Row(
                      children: [
                        Icon(
                          Icons.sticky_note_2_outlined,
                          size: 12,
                          color: _T.amber.withOpacity(0.8),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'BATCH NOTE',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.7,
                            color: _T.amber.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 7),

                    // Note body
                    Text(
                      _stripBatchTag(notes),
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w400,
                        color: _T.ink3,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CONSUMPTION EMPTY STATE
// ─────────────────────────────────────────────────────────────────────────────
class _ConsumptionEmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 10),
      decoration: BoxDecoration(
        color: _T.white,
        borderRadius: BorderRadius.circular(_T.rLg),
        border: Border.all(color: _T.slate200),
      ),
      child: Column(
        children: const [
          Icon(Icons.inventory_2_outlined, size: 20, color: _T.slate300),
          SizedBox(height: 8),
          Text(
            'No consumption yet',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: _T.slate400,
            ),
          ),
          SizedBox(height: 3),
          Text(
            'This batch has not been used in any job',
            style: TextStyle(fontSize: 11, color: _T.slate300),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CONSUMPTION ROW — redesigned
//
// Layout:
//   ┌──────────────────────────────────────────────────────────────┐
//   │ [red icon]  −12 rm            [project chip]  [task chip]   │
//   │             Task name here                    dd/mm/yyyy     │
//   └──────────────────────────────────────────────────────────────┘
//
// Task name is the primary identifier — shown large and bold.
// Project is a colored dot + name chip (same pattern as task cards).
// Date/time is muted, right-aligned.
// Quantity is prominent in red on the leading left.
// ─────────────────────────────────────────────────────────────────────────────
class _ConsumptionRow extends ConsumerStatefulWidget {
  final StockTransaction txn;
  final String unit;
  final bool isLast;

  const _ConsumptionRow({
    required this.txn,
    required this.unit,
    required this.isLast,
  });

  @override
  ConsumerState<_ConsumptionRow> createState() => _ConsumptionRowState();
}

class _ConsumptionRowState extends ConsumerState<_ConsumptionRow> {
  Future<Task?>? _taskFuture;
  Future<Project?>? _projectFuture;

  @override
  void initState() {
    super.initState();
    if (widget.txn.taskId != null) {
      _taskFuture = ref.read(taskByIdProvider(widget.txn.taskId!));
      _taskFuture!.then((task) {
        if (task != null && mounted) {
          setState(() {
            _projectFuture = ref.read(
              projectByIdFutureProvider(task.projectId),
            );
          });
        }
      });
    }
  }

  String _relativeDate(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(day).inDays;
    final time =
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
    if (diff == 0) return 'Today · $time';
    if (diff == 1) return 'Yesterday · $time';
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year} · $time';
  }

  @override
  Widget build(BuildContext context) {
    final dt = widget.txn.createdAt;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Leading icon ────────────────────────────────────────────
              Container(
                width: 30,
                height: 30,
                margin: const EdgeInsets.only(top: 1),
                decoration: BoxDecoration(
                  color: _T.red50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.output_rounded,
                  size: 13,
                  color: _T.red,
                ),
              ),
              const SizedBox(width: 12),

              // ── Body ────────────────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row 1: quantity (bold red) + right-aligned date
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          '${fmtStock(widget.txn.quantity)} ${widget.unit}',
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: _T.red,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _relativeDate(dt),
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: _T.slate400,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),

                    // Row 2: task name (or loading skeleton)
                    if (_taskFuture != null)
                      FutureBuilder<Task?>(
                        future: _taskFuture,
                        builder: (_, snap) {
                          if (!snap.hasData) {
                            return _InlineSkeletonPair();
                          }
                          final task = snap.data;
                          if (task == null) {
                            return const Text(
                              'Unknown task',
                              style: TextStyle(
                                fontSize: 12,
                                color: _T.slate300,
                              ),
                            );
                          }
                          return _TaskProjectLine(
                            taskName: task.name,
                            projectFuture: _projectFuture,
                          );
                        },
                      )
                    else if (widget.txn.notes != null &&
                        widget.txn.notes!.isNotEmpty)
                      Text(
                        fmtTransactionNote(widget.txn.notes!)!,
                        style: TextStyle(fontSize: 12, color: _T.slate500),
                      )
                    else
                      const Text(
                        'No task linked',
                        style: TextStyle(
                          fontSize: 12,
                          color: _T.slate300,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),

        if (!widget.isLast)
          const Divider(
            height: 1,
            color: _T.slate100,
            indent: 14,
            endIndent: 14,
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TASK + PROJECT LINE — stacked layout
//
// Task name sits on its own full-width line so it never truncates against the
// project name. Project chip sits below as a subordinate metadata line.
// This handles any combination of long/short names gracefully.
//
// Structure:
//   Task name (full width, up to 2 lines, w600 ink3)
//   [● Project Name]  (small chip, left-aligned, below the task name)
// ─────────────────────────────────────────────────────────────────────────────
class _TaskProjectLine extends StatelessWidget {
  final String taskName;
  final Future<Project?>? projectFuture;

  const _TaskProjectLine({required this.taskName, required this.projectFuture});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Task name — full width, wraps to 2 lines if needed
        Text(
          taskName,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: _T.ink3,
            height: 1.35,
          ),
        ),

        // Project chip — below the task name, left-aligned
        if (projectFuture != null) ...[
          const SizedBox(height: 5),
          FutureBuilder<Project?>(
            future: projectFuture,
            builder: (_, snap) {
              if (!snap.hasData) return _InlineSkeletonChip();
              final proj = snap.data;
              if (proj == null) return const SizedBox.shrink();
              return _ProjectChip(project: proj);
            },
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PROJECT CHIP
//
// Colored dot + project name. Matches the pattern used on task cards in the
// board view and detail panel summary rows.
// ─────────────────────────────────────────────────────────────────────────────
class _ProjectChip extends StatelessWidget {
  final Project project;
  const _ProjectChip({required this.project});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(7, 3, 8, 3),
      decoration: BoxDecoration(
        color: _T.slate100,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _T.slate200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: project.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            project.name,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: _T.slate500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// INLINE SKELETON WIDGETS — shown while task/project futures are loading
// ─────────────────────────────────────────────────────────────────────────────

// Two skeleton lines: task name + project chip — stacked to match loaded state
class _InlineSkeletonPair extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        CardLoading(
          height: 11,
          width: 150,
          borderRadius: BorderRadius.circular(4),
          cardLoadingTheme: const CardLoadingTheme(
            colorOne: _T.slate100,
            colorTwo: _T.slate200,
          ),
        ),
        const SizedBox(height: 6),
        CardLoading(
          height: 18,
          width: 80,
          borderRadius: BorderRadius.circular(6),
          cardLoadingTheme: const CardLoadingTheme(
            colorOne: _T.slate100,
            colorTwo: _T.slate200,
          ),
        ),
      ],
    );
  }
}

// Just the project chip skeleton
class _InlineSkeletonChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CardLoading(
      height: 18,
      width: 70,
      borderRadius: BorderRadius.circular(6),
      cardLoadingTheme: const CardLoadingTheme(
        colorOne: _T.slate100,
        colorTwo: _T.slate200,
      ),
    );
  }
}

class _BatchInfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color? valueColor;
  const _BatchInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 13, color: _T.slate400),
      const SizedBox(width: 8),
      SizedBox(
        width: 110,
        child: Text(
          label,
          style: const TextStyle(fontSize: 11.5, color: _T.slate500),
        ),
      ),
      Expanded(
        child: Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: valueColor ?? _T.ink3,
          ),
        ),
      ),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// BATCH IDLE PANE
// ─────────────────────────────────────────────────────────────────────────────
class _BatchIdlePane extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _T.slate100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _T.slate200),
          ),
          child: const Icon(
            Icons.touch_app_outlined,
            size: 22,
            color: _T.slate400,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Select a batch',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _T.slate400,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Tap a row on the left to see its consumption history',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11.5, color: _T.slate300),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// COMMIT BADGE
// ─────────────────────────────────────────────────────────────────────────────
class _CommitBadge extends StatelessWidget {
  final bool committed;
  const _CommitBadge({required this.committed});
  @override
  Widget build(BuildContext context) {
    final color = committed ? _T.green : _T.amber;
    final bg = committed ? _T.green50 : _T.amber50;
    final label = committed ? 'Committed' : 'Pending';
    final icon =
        committed ? Icons.check_circle_outline_rounded : Icons.schedule_rounded;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STOCK ADJUST DIALOG
// ─────────────────────────────────────────────────────────────────────────────
class _StockAdjustDialog extends StatefulWidget {
  final MaterialModel material;
  final void Function(double qty, String? note) onConfirm;
  const _StockAdjustDialog({required this.material, required this.onConfirm});
  @override
  State<_StockAdjustDialog> createState() => _StockAdjustDialogState();
}

class _StockAdjustDialogState extends State<_StockAdjustDialog> {
  final _qtyCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  bool _submitted = false;
  bool get _qtyOk {
    final v = double.tryParse(_qtyCtrl.text.trim());
    return v != null && v > 0;
  }

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
        width: 440,
        decoration: BoxDecoration(
          color: _T.white,
          borderRadius: BorderRadius.circular(_T.rXl),
          border: Border.all(color: _T.slate200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 16, 0),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _T.green50,
                      shape: BoxShape.circle,
                      border: Border.all(color: _T.green.withOpacity(0.2)),
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      size: 18,
                      color: _T.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Stock In',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _T.ink,
                          ),
                        ),
                        Text(
                          m.name,
                          style: const TextStyle(
                            fontSize: 12,
                            color: _T.slate400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(_T.r),
                    child: InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(_T.r),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          border: Border.all(color: _T.slate200),
                          borderRadius: BorderRadius.circular(_T.r),
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 15,
                          color: _T.slate400,
                        ),
                      ),
                    ),
                  ),
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
                  _NumField(
                    controller: _qtyCtrl,
                    label: m.unitLong,
                    hint: 'e.g. 5',
                    required: true,
                    suffix: m.unitShort,
                    onChanged: (_) => setState(() {}),
                    error:
                        _submitted && !_qtyOk ? 'Enter a valid quantity' : null,
                  ),
                  const SizedBox(height: 14),
                  SmooField(
                    controller: _noteCtrl,
                    label: 'Note',
                    hint: 'Optional — supplier, batch ref, etc.',
                    icon: Icons.notes_rounded,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _T.slate500,
                        side: const BorderSide(color: _T.slate200),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(_T.r),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: () {
                        setState(() => _submitted = true);
                        if (!_qtyOk) return;
                        widget.onConfirm(
                          double.parse(_qtyCtrl.text.trim()),
                          _noteCtrl.text.trim().isEmpty
                              ? null
                              : _noteCtrl.text.trim(),
                        );
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: _T.green,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(_T.r),
                        ),
                      ),
                      icon: const Icon(Icons.add_rounded, size: 17),
                      label: const Text(
                        'Confirm Stock In',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
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
// CREATE PANEL
// ─────────────────────────────────────────────────────────────────────────────
class _CreatePanel extends ConsumerStatefulWidget {
  final VoidCallback onClose, onSaved;
  const _CreatePanel({super.key, required this.onClose, required this.onSaved});
  @override
  ConsumerState<_CreatePanel> createState() => _CreatePanelState();
}

class _CreatePanelState extends ConsumerState<_CreatePanel> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _minStockCtrl = TextEditingController();
  MeasureType? _measureType;
  bool _submitted = false;
  bool _saving = false;
  bool get _nameOk => _nameCtrl.text.trim().isNotEmpty;
  bool get _typeOk => _measureType != null;
  bool get _formOk => _nameOk && _typeOk;

  final _reorderCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    for (final c in [_nameCtrl, _descCtrl, _minStockCtrl])
      c.addListener(() => setState(() {}));
    _reorderCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _minStockCtrl.dispose();
    _reorderCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _submitted = true);
    if (!_formOk) return;
    setState(() => _saving = true);
    try {
      final material = MaterialModel.create(
        name: _nameCtrl.text.trim(),
        description:
            _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        measureType: _measureType!,
        minStockLevel: double.tryParse(_minStockCtrl.text.trim()) ?? 0.0,
      );
      await ref
          .read(materialNotifierProvider.notifier)
          .createMaterial(material);
      _snack('Material created', isError: false);
      widget.onSaved();
    } catch (e) {
      _snack('Failed to create material', isError: true);
      setState(() => _saving = false);
    }
  }

  void _snack(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_outline_rounded,
              size: 15,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                msg,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: _T.ink,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_T.r),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      color: _T.slate50,
      border: Border(left: BorderSide(color: _T.slate200)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 58,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: const BoxDecoration(
            color: _T.white,
            border: Border(bottom: BorderSide(color: _T.slate200)),
          ),
          child: Row(
            children: [
              Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(_T.r),
                child: InkWell(
                  onTap: widget.onClose,
                  borderRadius: BorderRadius.circular(_T.r),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: _T.slate100,
                      borderRadius: BorderRadius.circular(_T.r),
                      border: Border.all(color: _T.slate200),
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 17,
                      color: _T.ink3,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _T.blue50,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: _T.blue.withOpacity(0.2)),
                ),
                child: const Icon(Icons.add_rounded, size: 16, color: _T.blue),
              ),
              const SizedBox(width: 12),
              const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'New Material',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _T.ink,
                      letterSpacing: -0.2,
                    ),
                  ),
                  Text(
                    'Add to inventory',
                    style: TextStyle(
                      fontSize: 10.5,
                      color: _T.slate400,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 28, 28, 40),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'New Material',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: _T.ink,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Fill in the details below. Required fields are marked *.',
                    style: TextStyle(fontSize: 13, color: _T.slate400),
                  ),
                  const SizedBox(height: 24),
                  _SectionCard(
                    icon: Icons.layers_outlined,
                    iconColor: _T.purple,
                    iconBg: _T.purple50,
                    title: 'Material Details',
                    subtitle: 'Name, type and description',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SmooField(
                          controller: _nameCtrl,
                          label: 'Material Name',
                          hint: 'e.g. Vinyl Roll 3.2m',
                          icon: Icons.layers_outlined,
                          required: true,
                          error:
                              _submitted && !_nameOk
                                  ? 'Name is required'
                                  : null,
                        ),
                        const SizedBox(height: 16),
                        FieldLabel.required('Measure Type'),
                        const SizedBox(height: 9),
                        _MeasureTypePicker(
                          selected: _measureType,
                          showError: _submitted && !_typeOk,
                          onSelect: (t) => setState(() => _measureType = t),
                        ),
                        const SizedBox(height: 16),
                        SmooField(
                          controller: _descCtrl,
                          label: 'Description',
                          hint: 'Optional notes about this material',
                          icon: Icons.notes_rounded,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    icon: Icons.warning_amber_outlined,
                    iconColor: _T.amber,
                    iconBg: _T.amber50,
                    title: 'Stock Thresholds',
                    subtitle: 'Optional — configure low stock alerts',
                    child: StockThresholdsCard(
                      minStockCtrl: _minStockCtrl,
                      reorderCtrl: _reorderCtrl,
                      unit:
                          _measureType != null
                              ? _measureType!.name.replaceAll('_', ' ')
                              : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          decoration: const BoxDecoration(
            color: _T.white,
            border: Border(top: BorderSide(color: _T.slate200)),
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _saving ? null : widget.onClose,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _T.slate500,
                    side: const BorderSide(color: _T.slate200),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(_T.r),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: _T.blue,
                    disabledBackgroundColor: _T.slate200,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(_T.r),
                    ),
                  ),
                  icon:
                      _saving
                          ? const SizedBox(
                            width: 15,
                            height: 15,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                          : const Icon(Icons.add_rounded, size: 17),
                  label: Text(
                    _saving ? 'Creating…' : 'Create Material',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// MEASURE TYPE PICKER
// ─────────────────────────────────────────────────────────────────────────────
class _MeasureTypePicker extends StatelessWidget {
  final MeasureType? selected;
  final bool showError;
  final ValueChanged<MeasureType> onSelect;
  const _MeasureTypePicker({
    required this.selected,
    required this.showError,
    required this.onSelect,
  });
  static const _options = [
    (
      MeasureType.running_meter,
      'Running Meter',
      'rm',
      Icons.straighten_rounded,
    ),
    (
      MeasureType.square_meter,
      'Square Meter',
      'sqm',
      Icons.crop_square_rounded,
    ),
    (
      MeasureType.item_quantity,
      'Item / Qty',
      'pcs',
      Icons.inventory_2_outlined,
    ),
    (MeasureType.liters, 'Liters', 'L', Icons.water_drop_outlined),
    (MeasureType.kilograms, 'Kilograms', 'kg', Icons.scale_outlined),
  ];
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children:
            _options.map((o) {
              final (type, label, unit, icon) = o;
              final active = selected == type;
              return GestureDetector(
                onTap: () => onSelect(type),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: active ? _T.blue50 : _T.white,
                    borderRadius: BorderRadius.circular(_T.rLg),
                    border: Border.all(
                      color:
                          active
                              ? _T.blue.withOpacity(0.5)
                              : showError
                              ? _T.red.withOpacity(0.4)
                              : _T.slate200,
                      width: active ? 1.5 : 1,
                    ),
                    boxShadow:
                        active
                            ? [
                              BoxShadow(
                                color: _T.blue.withOpacity(0.10),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ]
                            : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icon,
                        size: 14,
                        color: active ? _T.blue : _T.slate400,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              active ? FontWeight.w700 : FontWeight.w500,
                          color: active ? _T.blue : _T.ink3,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color:
                              active ? _T.blue.withOpacity(0.12) : _T.slate100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          unit,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: active ? _T.blue : _T.slate500,
                          ),
                        ),
                      ),
                      if (active) ...[
                        const SizedBox(width: 5),
                        const Icon(
                          Icons.check_circle_rounded,
                          size: 13,
                          color: _T.blue,
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
      ),
      if (showError)
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(
            children: const [
              Icon(Icons.error_outline_rounded, size: 11, color: _T.red),
              SizedBox(width: 4),
              Text(
                'Please select a measure type',
                style: TextStyle(
                  fontSize: 11,
                  color: _T.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// CSV IMPORT DIALOG — redesigned to match design system
//
// Changes from previous version:
//   • Icon badge: circle → rounded rect (matches detail panel, section cards)
//   • Close button: Material/InkWell → AnimatedContainer hover pattern
//   • Footer buttons: OutlinedButton/FilledButton → _GhostButton/_PrimaryButton
//   • Column reference: table-style rows with alternating slate50/white bg
//     replacing the dot + indent layout — easier to scan at a glance
//   • Info banner: amber → blue tint (informational, not a warning)
//   • Dialog width: 480 → 460, tighter proportions for desktop
//   • All border weights, radius, and spacing audited against system
//   • Template strip: opens hosted .xlsx via url_launcher (no callback needed)
//
// pubspec.yaml dependency required:
//   url_launcher: ^6.x.x
// ─────────────────────────────────────────────────────────────────────────────

class _CsvImportDialog extends StatelessWidget {
  final VoidCallback onConfirm;
  const _CsvImportDialog({required this.onConfirm});

  static const _columns = [
    _CsvColumn(field: 'name', required: true, note: null),
    _CsvColumn(
      field: 'measure_type',
      required: true,
      note: 'running_meter · item_quantity · liters · kilograms · square_meter',
    ),
    _CsvColumn(field: 'description', required: false, note: null),
    _CsvColumn(
      field: 'min_stock_level',
      required: false,
      note: 'Defaults to 0 if omitted',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 460,
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
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 16, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Icon badge — rounded rect, matches section cards
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: _T.blue50,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: _T.blue.withOpacity(0.2)),
                    ),
                    child: const Icon(
                      Icons.upload_file_outlined,
                      size: 15,
                      color: _T.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Import from CSV',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _T.ink,
                            letterSpacing: -0.1,
                          ),
                        ),
                        Text(
                          'Bulk-create materials from a spreadsheet',
                          style: TextStyle(fontSize: 11.5, color: _T.slate400),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Close button — hover pattern from design system
                  _DialogCloseButton(onTap: () => Navigator.of(context).pop()),
                ],
              ),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Divider(height: 1, color: _T.slate100),
            ),

            // ── Column reference table ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Table header
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: const [
                        SizedBox(width: 10),
                        Expanded(flex: 3, child: _ColHeader('COLUMN')),
                        Expanded(flex: 2, child: _ColHeader('REQUIRED')),
                        Expanded(flex: 4, child: _ColHeader('NOTES')),
                      ],
                    ),
                  ),

                  // Table rows — alternating row background
                  ClipRRect(
                    borderRadius: BorderRadius.circular(_T.r),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: _T.slate200),
                        borderRadius: BorderRadius.circular(_T.r),
                      ),
                      child: Column(
                        children:
                            _columns.asMap().entries.map((entry) {
                              final i = entry.key;
                              final col = entry.value;
                              final isLast = i == _columns.length - 1;

                              return Container(
                                decoration: BoxDecoration(
                                  color: i % 2 == 0 ? _T.white : _T.slate50,
                                  border:
                                      isLast
                                          ? null
                                          : const Border(
                                            bottom: BorderSide(
                                              color: _T.slate100,
                                            ),
                                          ),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Field name — monospace, ink3
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        col.field,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: _T.ink3,
                                          fontFamily: 'monospace',
                                        ),
                                      ),
                                    ),

                                    // Required / Optional pill
                                    Expanded(
                                      flex: 2,
                                      child: Container(
                                        margin: const EdgeInsets.only(top: 1),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              width: 5,
                                              height: 5,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color:
                                                    col.required
                                                        ? _T.red
                                                        : _T.green,
                                              ),
                                            ),
                                            const SizedBox(width: 5),
                                            Text(
                                              col.required
                                                  ? 'Required'
                                                  : 'Optional',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color:
                                                    col.required
                                                        ? _T.red
                                                        : _T.green,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                    // Notes
                                    Expanded(
                                      flex: 4,
                                      child:
                                          col.note != null
                                              ? Text(
                                                col.note!,
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: _T.slate400,
                                                  height: 1.4,
                                                ),
                                              )
                                              : const SizedBox.shrink(),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Template download strip ───────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: _TemplateDownloadStrip(),
            ),

            // ── Info banner ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: _T.blue50,
                  borderRadius: BorderRadius.circular(_T.r),
                  border: Border.all(color: _T.blue.withOpacity(0.2)),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.info_outline_rounded, size: 13, color: _T.blue),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Column names are case-insensitive and can be in any order.',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: _T.ink3,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Footer ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
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
                      label: 'Choose File',
                      icon: Icons.folder_open_outlined,
                      onTap: onConfirm,
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
// TEMPLATE DOWNLOAD STRIP
//
// A friendly nudge card that lives between the column table and the info
// banner. Left side: spark icon + copy. Right side: download button.
//
// Copy reads conversationally — "Not sure about the format?" — so it feels
// like a helpful hint rather than a UI label.
//
// The download button uses the ghost pattern (transparent → slate100 on hover)
// with a green download icon to distinguish it visually from the primary CTA.
// ─────────────────────────────────────────────────────────────────────────────
// ─────────────────────────────────────────────────────────────────────────────
// TEMPLATE DOWNLOAD STRIP
//
// Opens the hosted .xlsx template in the system browser/downloader.
// The user opens it in Excel / Sheets, fills it in, exports as CSV,
// then imports that CSV back here.
//
// URL is baked in — no callback needed.
// Requires url_launcher in pubspec.yaml.
// ─────────────────────────────────────────────────────────────────────────────
class _TemplateDownloadStrip extends StatefulWidget {
  const _TemplateDownloadStrip();

  static const _templateUrl =
      'https://raw.githubusercontent.com/ibrah006/smooflow/main/Example%20Template.xlsx';

  @override
  State<_TemplateDownloadStrip> createState() => _TemplateDownloadStripState();
}

class _TemplateDownloadStripState extends State<_TemplateDownloadStrip> {
  bool _hovered = false;

  Future<void> _launch() async {
    final uri = Uri.parse(_TemplateDownloadStrip._templateUrl);
    await launchUrl(uri, mode: LaunchMode.platformDefault);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: _launch,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
          decoration: BoxDecoration(
            color: _hovered ? const Color(0xFFF0FDF4) : _T.white,
            borderRadius: BorderRadius.circular(_T.r),
            border: Border.all(
              color: _hovered ? _T.green.withOpacity(0.4) : _T.slate200,
              width: _hovered ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            children: [
              // Icon badge
              AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: _hovered ? _T.green.withOpacity(0.12) : _T.green50,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(
                  Icons.download_rounded,
                  size: 14,
                  color: _hovered ? _T.green : _T.green.withOpacity(0.75),
                ),
              ),
              const SizedBox(width: 11),

              // Copy
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Not sure about the format?',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: _T.ink3,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'Download the Excel template → fill it in → export as CSV → import here.',
                      style: TextStyle(
                        fontSize: 11,
                        color: _hovered ? _T.ink3 : _T.slate400,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // "Download .xlsx" label — fades in on hover
              AnimatedOpacity(
                opacity: _hovered ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 140),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _T.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Download .xlsx',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _T.green,
                    ),
                  ),
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
// CSV COLUMN MODEL
// ─────────────────────────────────────────────────────────────────────────────
class _CsvColumn {
  final String field;
  final bool required;
  final String? note;
  const _CsvColumn({
    required this.field,
    required this.required,
    required this.note,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// TABLE COLUMN HEADER
// ─────────────────────────────────────────────────────────────────────────────
class _ColHeader extends StatelessWidget {
  final String text;
  const _ColHeader(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 9.5,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.6,
      color: _T.slate400,
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// DIALOG CLOSE BUTTON — AnimatedContainer hover, matches system pattern
// ─────────────────────────────────────────────────────────────────────────────
class _DialogCloseButton extends StatefulWidget {
  final VoidCallback onTap;
  const _DialogCloseButton({required this.onTap});

  @override
  State<_DialogCloseButton> createState() => _DialogCloseButtonState();
}

class _DialogCloseButtonState extends State<_DialogCloseButton> {
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
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: _hovered ? _T.slate100 : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: _T.slate200),
          ),
          child: Icon(
            Icons.close_rounded,
            size: 13,
            color: _hovered ? _T.ink3 : _T.slate400,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DIALOG PRIMARY BUTTON — matches _PrimaryButton / _CreateTaskButton
// ─────────────────────────────────────────────────────────────────────────────
class _DialogPrimaryButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _DialogPrimaryButton({
    required this.label,
    required this.icon,
    required this.onTap,
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
            color: _hovered ? _T.blueHover : _T.blue,
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
} // ─────────────────────────────────────────────────────────────────────────────

// SECTION CARD
// ─────────────────────────────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor, iconBg;
  final String title, subtitle;
  final Widget child;
  const _SectionCard({
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
      color: _T.white,
      borderRadius: BorderRadius.circular(_T.rXl),
      border: Border.all(color: _T.slate200),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.03),
          blurRadius: 14,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: iconColor.withOpacity(0.2)),
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _T.ink,
                        letterSpacing: -0.2,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: _T.slate400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Divider(height: 1, color: _T.slate100),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: child,
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// NUM FIELD
// ─────────────────────────────────────────────────────────────────────────────
class _NumField extends StatefulWidget {
  final TextEditingController controller;
  final String label, hint;
  final bool required;
  final String? suffix, error;
  final ValueChanged<String>? onChanged;
  const _NumField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.required,
    this.suffix,
    this.error,
    this.onChanged,
  });
  @override
  State<_NumField> createState() => _NumFieldState();
}

class _NumFieldState extends State<_NumField> {
  final _focus = FocusNode();
  bool _focused = false;
  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() => _focused = _focus.hasFocus));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.error != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.required)
          FieldLabel.required(widget.label)
        else
          FieldLabel(widget.label, optional: true),
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
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focus,
                  onChanged: widget.onChanged,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  style: const TextStyle(
                    fontSize: 13,
                    color: _T.ink,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: widget.hint,
                    hintStyle: const TextStyle(
                      fontSize: 13,
                      color: _T.slate300,
                    ),
                    prefixIcon: const Icon(
                      Icons.tag_rounded,
                      size: 15,
                      color: _T.slate400,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 13,
                      horizontal: 12,
                    ),
                  ),
                ),
              ),
              if (widget.suffix != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    widget.suffix!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _T.slate500,
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 11,
                  color: _T.red,
                ),
                const SizedBox(width: 4),
                Text(
                  widget.error!,
                  style: const TextStyle(
                    fontSize: 11,
                    color: _T.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String value, label;
  final Color color, bg;
  const _StatChip({
    required this.value,
    required this.label,
    required this.color,
    required this.bg,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(99),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    ),
  );
}

class _FilterTab extends StatelessWidget {
  final String label, selected;
  final int count;
  final VoidCallback onTap;
  const _FilterTab({
    required this.label,
    required this.selected,
    required this.count,
    required this.onTap,
  });
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: active ? _T.white : _T.slate500,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: active ? Colors.white.withOpacity(0.25) : _T.slate100,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: active ? _T.white : _T.slate500,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  const _SearchBar({required this.controller, required this.onChanged});
  @override
  Widget build(BuildContext context) => Container(
    height: 36,
    decoration: BoxDecoration(
      color: _T.slate50,
      borderRadius: BorderRadius.circular(_T.r),
      border: Border.all(color: _T.slate200),
    ),
    child: TextField(
      controller: controller,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 13, color: _T.ink),
      decoration: InputDecoration(
        hintText: 'Search materials…',
        hintStyle: const TextStyle(fontSize: 13, color: _T.slate300),
        prefixIcon: const Icon(
          Icons.search_rounded,
          size: 15,
          color: _T.slate400,
        ),
        suffixIcon:
            controller.text.isNotEmpty
                ? GestureDetector(
                  onTap: () {
                    controller.clear();
                    onChanged('');
                  },
                  child: const Icon(
                    Icons.close_rounded,
                    size: 14,
                    color: _T.slate400,
                  ),
                )
                : null,
        border: InputBorder.none,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 9),
      ),
    ),
  );
}

class _EmptyListState extends StatelessWidget {
  final bool hasSearch;
  const _EmptyListState({required this.hasSearch});
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          hasSearch ? Icons.search_off_rounded : Icons.layers_clear_outlined,
          size: 28,
          color: _T.slate300,
        ),
        const SizedBox(height: 10),
        Text(
          hasSearch ? 'No results' : 'No materials yet',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _T.slate400,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          hasSearch
              ? 'Try adjusting your search or filter'
              : 'Click Add Material to get started',
          style: const TextStyle(fontSize: 12, color: _T.slate300),
        ),
      ],
    ),
  );
}

class _IdlePane extends StatelessWidget {
  const _IdlePane();
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: _T.slate100,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _T.slate200),
          ),
          child: const Icon(
            Icons.layers_outlined,
            size: 26,
            color: _T.slate400,
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Select a material to view details',
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: _T.slate400,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'or click Add Material to create a new one',
          style: TextStyle(fontSize: 12, color: _T.slate300),
        ),
      ],
    ),
  );
}

class _AlertDialog extends StatelessWidget {
  final IconData icon;
  final Color color, bg;
  final String title, body, cta;
  const _AlertDialog({
    required this.icon,
    required this.color,
    required this.bg,
    required this.title,
    required this.body,
    required this.cta,
  });
  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: Colors.transparent,
    child: Container(
      width: 380,
      decoration: BoxDecoration(
        color: _T.white,
        borderRadius: BorderRadius.circular(_T.rXl),
        border: Border.all(color: _T.slate200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 24),
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: bg,
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.2)),
            ),
            child: Icon(icon, size: 22, color: color),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _T.ink,
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              body,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: _T.slate400),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(
                backgroundColor: _T.blue,
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_T.r),
                ),
              ),
              child: Text(
                cta,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
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
      decoration: BoxDecoration(
        color: _T.white,
        borderRadius: BorderRadius.circular(_T.rXl),
        border: Border.all(color: _T.slate200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 16, 0),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _T.amber50,
                    shape: BoxShape.circle,
                    border: Border.all(color: _T.amber.withOpacity(0.2)),
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    size: 18,
                    color: _T.amber,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Validation Warnings',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _T.ink,
                        ),
                      ),
                      Text(
                        '${errors.length} row${errors.length == 1 ? '' : 's'} could not be imported',
                        style: const TextStyle(
                          fontSize: 12,
                          color: _T.slate400,
                        ),
                      ),
                    ],
                  ),
                ),
                Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(_T.r),
                  child: InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(_T.r),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        border: Border.all(color: _T.slate200),
                        borderRadius: BorderRadius.circular(_T.r),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 15,
                        color: _T.slate400,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Divider(height: 1, color: _T.slate100),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: _T.slate50,
              borderRadius: BorderRadius.circular(_T.rLg),
              border: Border.all(color: _T.slate200),
            ),
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              shrinkWrap: true,
              itemCount: errors.length > 5 ? 5 : errors.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder:
                  (_, i) => Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        size: 13,
                        color: _T.red,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          errors[i],
                          style: const TextStyle(fontSize: 12, color: _T.ink3),
                        ),
                      ),
                    ],
                  ),
            ),
          ),
          if (errors.length > 5)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '… and ${errors.length - 5} more',
                style: const TextStyle(
                  fontSize: 12,
                  color: _T.slate400,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(
                backgroundColor: _T.blue,
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_T.r),
                ),
              ),
              child: const Text(
                'Continue',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

// Helpers
String _stripBatchTag(String note) =>
    note.replaceAll(RegExp(r'\[BATCH:[^\]]+\]\s*'), '').trim();

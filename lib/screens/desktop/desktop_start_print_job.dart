// ─────────────────────────────────────────────────────────────────────────────
// start_print_job_screen.dart
//
// Desktop three-column screen for starting a print job.
//
// LAYOUT
// ──────
//   Topbar (58px) — back button · icon badge · title · task chip · step indicators
//   Body: three columns
//     LEFT   (340px) — Printer selection
//     CENTER (flex)  — Material selection (two-phase: material → stock item)
//     RIGHT  (300px) — Usage input · job summary · CTA
//
// MATERIAL SELECTION — two-phase flow
// ─────────────────────────────────────
//   Phase 1 — Search by material name OR toggle to barcode mode and scan/type
//             directly. Each result shows material name + total available stock.
//   Phase 2 — After picking a material, the column transitions to show all
//             available stockIn batches for that material (individual physical
//             items) with their quantity and barcode shown per row.
//             The user selects one specific batch — this is the StockTransaction
//             that gets consumed. We never expose "StockTransaction" wording.
//
// DATA WIRING (TODO markers)
// ──────────────────────────
//   TODO-1  Replace _printers getter with real provider
//   TODO-2  Replace _allMaterials getter with real provider
//   TODO-3  _stockItemsFor() fetches async via provider and caches in _stockItems
//   TODO-4  Implement _submit() with real stockOut API call
//
// DESIGN SYSTEM
// ─────────────
//   Identical _T tokens, _SectionCard anatomy, _SmooField, topbar height (58px),
//   FilledButton.icon / OutlinedButton — matches create_task_screen.dart,
//   manage_materials_screen.dart, manage_printers_screen.dart.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/core/models/material.dart';
import 'package:smooflow/core/models/printer.dart';
import 'package:smooflow/core/models/stock_transaction.dart';
import 'package:smooflow/core/models/task.dart';
import 'package:smooflow/providers/material_provider.dart';
import 'package:smooflow/providers/printer_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TOKENS
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
// SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class StartPrintJobScreen extends ConsumerStatefulWidget {
  final Task task;
  const StartPrintJobScreen({super.key, required this.task});

  @override
  ConsumerState<StartPrintJobScreen> createState() => _StartPrintJobScreenState();
}

class _StartPrintJobScreenState extends ConsumerState<StartPrintJobScreen> {
  // ── Selections ─────────────────────────────────────────────────────────────
  Printer?          _printer;
  MaterialModel?    _material;    // Phase-1 selection
  StockTransaction? _stockItem;   // Phase-2 selection (the real stockIn batch)

  // ── Material column state ──────────────────────────────────────────────────
  final _materialSearchCtrl = TextEditingController();
  final _barcodeSearchCtrl  = TextEditingController();
  bool  _barcodeMode        = false; // true = search by barcode

  // ── Stock item cache ───────────────────────────────────────────────────────
  // Keyed by materialId. Populated lazily when a material is selected or when
  // barcode search needs to scan all materials' transactions.
  // Kept across material changes so repeated selections don't re-fetch.
  final Map<String, List<StockTransaction>> _stockItems   = {};
  bool                                      _stockLoading = false;
  bool                                      _printersLoading = false;

  // ── Usage ──────────────────────────────────────────────────────────────────
  final _qtyCtrl = TextEditingController();
  bool  _submitting = false;
  bool  _qtySubmitted = false;

  double? get _qty {
    final v = double.tryParse(_qtyCtrl.text.trim());
    return (v != null && v > 0) ? v : null;
  }

  double? get _maxQty => _stockItem?.quantity; // Can only use up to what's in this batch

  bool get _qtyValid {
    if (_qty == null) return false;
    if (_maxQty != null && _qty! > _maxQty!) return false;
    return true;
  }

  bool get _canSubmit => _printer != null && _stockItem != null && _qtyValid;

  // ── Data ────────────────────────────────────────────────────────────────────

  // TODO-1: replace with ref.watch(printerNotifierProvider).printers.where(available)
  List<Printer> get _printers => ref.watch(printerNotifierProvider).printers
      .where((p) => p.status == PrinterStatus.active && !p.isBusy)
      .toList();

  // TODO-2: replace with ref.watch(materialNotifierProvider).materials
  List<MaterialModel> get _allMaterials =>
      ref.watch(materialNotifierProvider).materials;

  List<MaterialModel> get _filteredMaterials {
    final q = _materialSearchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return _allMaterials.where((m) => !m.isCriticalStock).toList();
    return _allMaterials
        .where((m) => !m.isCriticalStock && m.name.toLowerCase().contains(q))
        .toList();
  }

  // Fetches stockIn transactions for [materialId] from the provider, caches
  // the result in _stockItems, and returns only uncommitted stockIn entries
  // with remaining quantity — sorted FIFO (oldest first).
  Future<void> _fetchStockItems(String materialId) async {
    if (_stockItems.containsKey(materialId)) return; // already cached
    setState(() => _stockLoading = true);
    try {
      final all = await ref
          .read(materialNotifierProvider.notifier)
          .fetchMaterialTransactions(materialId);
      if (!mounted) return;
      _stockItems[materialId] = all
          .where((t) => t.type == TransactionType.stockIn && t.quantity > 0)
          .toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    } finally {
      if (mounted) setState(() => _stockLoading = false);
    }
  }

  // Returns the cached list for [materialId], or empty while loading.
  List<StockTransaction> _cachedItemsFor(String materialId) =>
      _stockItems[materialId] ?? [];

  // Barcode search across all cached materials' items.
  // For barcode mode we also eagerly pre-fetch any materials not yet cached.
  List<StockTransaction> get _barcodeResults {
    final q = _barcodeSearchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return [];
    // Kick off fetches for any un-cached materials (fire-and-forget).
    for (final m in _allMaterials) {
      if (!_stockItems.containsKey(m.id)) _fetchStockItems(m.id);
    }
    return _stockItems.values
        .expand((list) => list)
        .where((t) => t.barcode != null && t.barcode!.toLowerCase().contains(q))
        .toList();
  }

  // ── Interactions ───────────────────────────────────────────────────────────

  void _selectMaterial(MaterialModel m) {
    setState(() {
      _material  = m;
      _stockItem = null;
      _qtyCtrl.clear();
      _qtySubmitted = false;
    });
    // Fetch stock items for this material if not already cached.
    _fetchStockItems(m.id);
  }

  void _selectStockItem(StockTransaction t) {
    setState(() {
      _stockItem    = t;
      _qtyCtrl.clear();
      _qtySubmitted = false;
    });
  }

  void _selectStockItemFromBarcode(StockTransaction t, MaterialModel m) {
    setState(() {
      _material   = m;
      _stockItem  = t;
      _barcodeMode = false;
      _qtyCtrl.clear();
      _qtySubmitted = false;
    });
  }

  void _clearMaterial() {
    setState(() {
      _material  = null;
      _stockItem = null;
      _qtyCtrl.clear();
      _qtySubmitted = false;
      _materialSearchCtrl.clear();
    });
  }

  void _toggleBarcodeMode() {
    setState(() {
      _barcodeMode = !_barcodeMode;
      _barcodeSearchCtrl.clear();
      if (_barcodeMode) {
        _material  = null;
        _stockItem = null;
        _materialSearchCtrl.clear();
      }
    });
  }

  Future<void> _submit() async {
    setState(() => _qtySubmitted = true);
    if (!_canSubmit || _submitting) return;
    setState(() => _submitting = true);
    try {
      // TODO-4: implement real stock-out call, e.g.:
      // await ref.read(materialNotifierProvider.notifier).stockOut(
      //   barcode:   _stockItem!.barcode!,
      //   quantity:  _qty!,
      //   projectId: widget.task.projectId,
      //   taskId:    widget.task.id,
      // );
      // await ref.read(printerNotifierProvider.notifier).startPrintJob(
      //   taskId:    widget.task.id,
      //   printerId: _printer!.id,
      // );
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void initState() {
    super.initState();
    for (final c in [_materialSearchCtrl, _barcodeSearchCtrl, _qtyCtrl]) {
      c.addListener(() => setState(() {}));
    }
    Future.microtask(() async {
      setState(() => _printersLoading = true);
      await ref.read(printerNotifierProvider.notifier).fetchPrinters();
      if (mounted) setState(() => _printersLoading = false);
    });
  }

  @override
  void dispose() {
    _materialSearchCtrl.dispose();
    _barcodeSearchCtrl.dispose();
    _qtyCtrl.dispose();
    super.dispose();
  }

  // ── Step state ─────────────────────────────────────────────────────────────
  _Step get _step {
    if (_printer == null)    return _Step.printer;
    if (_stockItem == null)  return _Step.material;
    return _Step.usage;
  }

  @override
  Widget build(BuildContext context) {
    final stockItems = _material != null
        ? _cachedItemsFor(_material!.id)
        : <StockTransaction>[];

    return Scaffold(
      backgroundColor: _T.slate50,
      body: Column(children: [
        // ── Topbar ────────────────────────────────────────────────────────
        _Topbar(task: widget.task, step: _step),

        // ── Three-column body ─────────────────────────────────────────────
        Expanded(child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // LEFT — Printer
            SizedBox(
              width: 340,
              child: _ColumnShell(
                borderRight: true,
                header: _ColHeader(
                  icon:      Icons.print_rounded,
                  iconColor: _T.blue,
                  iconBg:    _T.blue50,
                  stepNum:   '1',
                  title:     'Printer',
                  subtitle:  'Select an available printer',
                  isDone:    _printer != null,
                ),
                child: _PrinterList(
                  printers:  _printers,
                  selected:  _printer,
                  isLoading: _printersLoading,
                  onSelect:  (p) => setState(() => _printer = p),
                ),
              ),
            ),

            // CENTER — Material (two-phase)
            Expanded(
              child: _ColumnShell(
                borderRight: true,
                header: _MaterialColHeader(
                  phase:         _material == null ? 1 : 2,
                  material:      _material,
                  barcodeMode:   _barcodeMode,
                  isDone:        _stockItem != null,
                  onBack:        _material != null ? _clearMaterial : null,
                  onToggleMode:  _toggleBarcodeMode,
                ),
                child: _material == null
                    // Phase 1: pick a material
                    ? _MaterialPhase(
                        barcodeMode:       _barcodeMode,
                        allMaterials:      _allMaterials,
                        filteredMaterials: _filteredMaterials,
                        barcodeResults:    _barcodeResults,
                        materialSearchCtrl: _materialSearchCtrl,
                        barcodeSearchCtrl:  _barcodeSearchCtrl,
                        onSelectMaterial:   _selectMaterial,
                        onSelectFromBarcode: (t) {
                          final mat = _allMaterials.firstWhere(
                              (m) => m.id == t.materialId,
                              orElse: () => _allMaterials.first);
                          _selectStockItemFromBarcode(t, mat);
                        },
                      )
                    // Phase 2: pick a stock item (batch)
                    : _StockItemPhase(
                        material:   _material!,
                        stockItems: stockItems,
                        isLoading:  _stockLoading,
                        selected:   _stockItem,
                        onSelect:   _selectStockItem,
                      ),
              ),
            ),

            // RIGHT — Usage + Summary + CTA
            SizedBox(
              width: 300,
              child: _ColumnShell(
                header: _ColHeader(
                  icon:      Icons.straighten_outlined,
                  iconColor: _T.green,
                  iconBg:    _T.green50,
                  stepNum:   '3',
                  title:     'Quantity',
                  subtitle:  'Amount to consume',
                  isDone:    _canSubmit,
                ),
                child: _UsagePanel(
                  task:        widget.task,
                  printer:     _printer,
                  material:    _material,
                  stockItem:   _stockItem,
                  qtyCtrl:     _qtyCtrl,
                  qty:         _qty,
                  maxQty:      _maxQty,
                  qtyValid:    _qtyValid,
                  submitted:   _qtySubmitted,
                  canSubmit:   _canSubmit,
                  submitting:  _submitting,
                  onSubmit:    _submit,
                  step:        _step,
                ),
              ),
            ),
          ],
        )),
      ]),
    );
  }
}

enum _Step { printer, material, usage }

// ─────────────────────────────────────────────────────────────────────────────
// TOPBAR — 58px, matches design system exactly
// ─────────────────────────────────────────────────────────────────────────────
class _Topbar extends StatelessWidget {
  final Task  task;
  final _Step step;
  const _Topbar({required this.task, required this.step});

  @override
  Widget build(BuildContext context) => Container(
    height: 58,
    padding: const EdgeInsets.symmetric(horizontal: 20),
    decoration: const BoxDecoration(
      color:  _T.white,
      border: Border(bottom: BorderSide(color: _T.slate200)),
    ),
    child: Row(children: [
      // Back button
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
      // Title + breadcrumb
      Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Start Print Job',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                color: _T.ink, letterSpacing: -0.2)),
        Text('Task #${task.id}',
            style: const TextStyle(fontSize: 10.5, color: _T.slate400, fontWeight: FontWeight.w500)),
      ]),
      const SizedBox(width: 16),
      // Task chip
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color:        _T.slate100,
          borderRadius: BorderRadius.circular(6),
          border:       Border.all(color: _T.slate200),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.assignment_outlined, size: 11, color: _T.slate400),
          const SizedBox(width: 5),
          Text(task.name, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _T.ink3)),
        ]),
      ),
      const Spacer(),
      // Step indicators
      _StepIndicator(num: '1', label: 'Printer',  done: step.index > 0, active: step == _Step.printer),
      _StepConnector(done: step.index > 0),
      _StepIndicator(num: '2', label: 'Material', done: step.index > 1, active: step == _Step.material),
      _StepConnector(done: step.index > 1),
      _StepIndicator(num: '3', label: 'Quantity', done: false,           active: step == _Step.usage),
    ]),
  );
}

class _StepIndicator extends StatelessWidget {
  final String num, label;
  final bool done, active;
  const _StepIndicator({required this.num, required this.label, required this.done, required this.active});

  @override
  Widget build(BuildContext context) {
    final Color dotColor = done ? _T.green : active ? _T.blue : _T.slate300;
    final Color dotBg    = done ? _T.green50 : active ? _T.blue50 : Colors.transparent;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 20, height: 20,
        decoration: BoxDecoration(shape: BoxShape.circle, color: dotBg,
            border: Border.all(color: dotColor, width: 1.5)),
        child: Center(
          child: done
              ? Icon(Icons.check_rounded, size: 10, color: dotColor)
              : Text(num, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: dotColor)),
        ),
      ),
      const SizedBox(width: 5),
      Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
          color: active ? _T.ink3 : done ? _T.slate400 : _T.slate300)),
    ]);
  }
}

class _StepConnector extends StatelessWidget {
  final bool done;
  const _StepConnector({required this.done});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8),
    child: Container(width: 24, height: 1.5,
        color: done ? _T.green.withOpacity(0.4) : _T.slate200),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// COLUMN SHELL — white panel with optional right border
// ─────────────────────────────────────────────────────────────────────────────
class _ColumnShell extends StatelessWidget {
  final Widget header, child;
  final bool   borderRight;
  const _ColumnShell({required this.header, required this.child, this.borderRight = false});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color:  _T.white,
      border: borderRight
          ? const Border(right: BorderSide(color: _T.slate200))
          : null,
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      header,
      Expanded(child: child),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// COLUMN HEADERS
// ─────────────────────────────────────────────────────────────────────────────
class _ColHeader extends StatelessWidget {
  final IconData icon;
  final Color    iconColor, iconBg;
  final String   stepNum, title, subtitle;
  final bool     isDone;
  const _ColHeader({required this.icon, required this.iconColor, required this.iconBg,
    required this.stepNum, required this.title, required this.subtitle,
    required this.isDone});

  @override
  Widget build(BuildContext context) => Container(
    height: 52,
    padding: const EdgeInsets.symmetric(horizontal: 16),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: _T.slate200)),
    ),
    child: Row(children: [
      Container(
        width: 28, height: 28,
        decoration: BoxDecoration(
          color:        isDone ? _T.green50 : iconBg,
          borderRadius: BorderRadius.circular(7),
          border:       Border.all(color: isDone ? _T.green.withOpacity(0.2) : iconColor.withOpacity(0.2)),
        ),
        child: isDone
            ? const Icon(Icons.check_rounded, size: 13, color: _T.green)
            : Icon(icon, size: 13, color: iconColor),
      ),
      const SizedBox(width: 10),
      Expanded(child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 16, height: 16,
              decoration: BoxDecoration(
                color:  isDone ? _T.green : _T.slate200,
                shape:  BoxShape.circle,
              ),
              child: Center(child: Text(stepNum,
                  style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: _T.white))),
            ),
            const SizedBox(width: 6),
            Text(title, style: const TextStyle(fontSize: 12.5,
                fontWeight: FontWeight.w700, color: _T.ink)),
          ]),
          Text(subtitle, style: const TextStyle(fontSize: 10.5, color: _T.slate400)),
        ],
      )),
    ]),
  );
}

// Material column header is different — it has phase back-navigation and mode toggle
class _MaterialColHeader extends StatelessWidget {
  final int           phase;
  final MaterialModel? material;
  final bool          barcodeMode, isDone;
  final VoidCallback? onBack;
  final VoidCallback  onToggleMode;
  const _MaterialColHeader({required this.phase, required this.material,
    required this.barcodeMode, required this.isDone,
    required this.onBack, required this.onToggleMode});

  @override
  Widget build(BuildContext context) => Container(
    height: 52,
    padding: const EdgeInsets.symmetric(horizontal: 16),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: _T.slate200)),
    ),
    child: Row(children: [
      // Back button (phase 2 only)
      if (onBack != null) ...[
        Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          child: InkWell(
            onTap: onBack,
            borderRadius: BorderRadius.circular(6),
            child: Container(
              width: 26, height: 26,
              decoration: BoxDecoration(
                color:        _T.slate100,
                borderRadius: BorderRadius.circular(6),
                border:       Border.all(color: _T.slate200),
              ),
              child: const Icon(Icons.arrow_back_rounded, size: 13, color: _T.ink3),
            ),
          ),
        ),
        const SizedBox(width: 8),
      ],
      // Icon badge
      AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 28, height: 28,
        decoration: BoxDecoration(
          color:        isDone ? _T.green50 : barcodeMode ? _T.amber50 : _T.purple50,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(
            color: isDone ? _T.green.withOpacity(0.2)
                : barcodeMode ? _T.amber.withOpacity(0.2)
                : _T.purple.withOpacity(0.2),
          ),
        ),
        child: isDone
            ? const Icon(Icons.check_rounded, size: 13, color: _T.green)
            : barcodeMode
                ? const Icon(Icons.qr_code_scanner_rounded, size: 13, color: _T.amber)
                : const Icon(Icons.layers_outlined, size: 13, color: _T.purple),
      ),
      const SizedBox(width: 10),
      // Title / breadcrumb
      Expanded(child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 16, height: 16,
              decoration: BoxDecoration(
                color:  isDone ? _T.green : _T.slate200,
                shape:  BoxShape.circle,
              ),
              child: Center(child: const Text('2',
                  style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: _T.white))),
            ),
            const SizedBox(width: 6),
            Text(
              phase == 2 ? material!.name : 'Material',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: _T.ink),
            ),
          ]),
          Text(
            phase == 2 ? 'Select a specific item' : 'Search by name or barcode',
            style: const TextStyle(fontSize: 10.5, color: _T.slate400),
          ),
        ],
      )),
      // Barcode toggle (phase 1 only)
      if (phase == 1) ...[
        const SizedBox(width: 8),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: onToggleMode,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color:        barcodeMode ? _T.amber50 : _T.slate100,
                borderRadius: BorderRadius.circular(99),
                border:       Border.all(
                  color: barcodeMode ? _T.amber.withOpacity(0.4) : _T.slate200,
                ),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.qr_code_scanner_rounded, size: 12,
                    color: barcodeMode ? _T.amber : _T.slate400),
                const SizedBox(width: 5),
                Text(barcodeMode ? 'Barcode' : 'Scan',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                        color: barcodeMode ? _T.amber : _T.slate500)),
              ]),
            ),
          ),
        ),
      ],
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// PRINTER LIST
// ─────────────────────────────────────────────────────────────────────────────
class _PrinterLoadingState extends StatefulWidget {
  @override
  State<_PrinterLoadingState> createState() => _PrinterLoadingStateState();
}

class _PrinterLoadingStateState extends State<_PrinterLoadingState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  late final Animation<double> _fade =
      Tween(begin: 0.4, end: 1.0).animate(
        CurvedAnimation(parent: _ac, curve: Curves.easeInOut));

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Subtle instructional text
          Padding(
            padding: const EdgeInsets.only(bottom: 10, left: 2),
            child: FadeTransition(
              opacity: _fade,
              child: const Text(
                'Fetching available printers…',
                style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: _T.slate400),
              ),
            ),
          ),
          // Three skeleton tiles
          ...List.generate(3, (i) => _SkeletonPrinterTile(
            delay: Duration(milliseconds: i * 80),
            ac: _ac,
          )),
        ],
      ),
    );
  }
}

class _SkeletonPrinterTile extends StatelessWidget {
  final Duration          delay;
  final AnimationController ac;
  const _SkeletonPrinterTile({required this.delay, required this.ac});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: AnimatedBuilder(
        animation: ac,
        builder: (_, __) {
          // Stagger each tile slightly using a phase-shifted sine
          final phase = (ac.value + delay.inMilliseconds / 1200.0) % 1.0;
          final opacity = 0.35 + 0.45 * (1 - (phase - 0.5).abs() * 2).clamp(0.0, 1.0);
          return Opacity(
            opacity: opacity,
            child: Container(
              height: 58,
              decoration: BoxDecoration(
                color:        _T.slate100,
                borderRadius: BorderRadius.circular(_T.r),
                border:       Border.all(color: _T.slate200),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(children: [
                // Icon placeholder
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color:        _T.slate200,
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
                const SizedBox(width: 10),
                // Text placeholders
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment:  MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 10,
                        width:  120,
                        decoration: BoxDecoration(
                          color:        _T.slate200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 8,
                        width:  80,
                        decoration: BoxDecoration(
                          color:        _T.slate200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
                // Status pill placeholder
                Container(
                  height: 18,
                  width:  60,
                  decoration: BoxDecoration(
                    color:        _T.slate200,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ]),
            ),
          );
        },
      ),
    );
  }
}

class _PrinterList extends StatelessWidget {
  final List<Printer>         printers;
  final Printer?              selected;
  final bool                  isLoading;
  final ValueChanged<Printer> onSelect;
  const _PrinterList({required this.printers, required this.selected,
    required this.isLoading, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _PrinterLoadingState();
    }
    if (printers.isEmpty) {
      return _EmptyState(
        icon:     Icons.print_disabled_outlined,
        title:    'No printers available',
        subtitle: 'All printers are busy or offline',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount:        printers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (_, i) {
        final p = printers[i];
        return _PrinterTile(
          printer:    p,
          isSelected: selected?.id == p.id,
          onTap:      () => onSelect(p),
        );
      },
    );
  }
}

class _PrinterTile extends StatefulWidget {
  final Printer      printer;
  final bool         isSelected;
  final VoidCallback onTap;
  const _PrinterTile({required this.printer, required this.isSelected, required this.onTap});
  @override State<_PrinterTile> createState() => _PrinterTileState();
}

class _PrinterTileState extends State<_PrinterTile> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) {
    final p        = widget.printer;
    final selected = widget.isSelected;
    return MouseRegion(
      cursor:  SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          decoration: BoxDecoration(
            color:        selected ? _T.blue50 : _hovered ? _T.slate50 : Colors.transparent,
            borderRadius: BorderRadius.circular(_T.r),
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 130),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(_T.r),
              border:       Border.all(
                color: selected ? _T.blue.withOpacity(0.4) : _T.slate200,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color:        selected ? _T.blue.withOpacity(0.10) : _T.slate100,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(Icons.print_outlined, size: 15,
                    color: selected ? _T.blue : _T.slate500),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(p.name, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600,
                    color: selected ? _T.blue : _T.ink)),
                if ((p.nickname ?? '').isNotEmpty)
                  Text(p.nickname!, style: const TextStyle(fontSize: 11, color: _T.slate400)),
              ])),
              _StatusPill(label: 'Available', color: _T.green, bg: _T.green50),
              if (selected) ...[
                const SizedBox(width: 8),
                const Icon(Icons.check_circle_rounded, size: 15, color: _T.blue),
              ],
            ]),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MATERIAL PHASE 1 — search by name OR by barcode
// ─────────────────────────────────────────────────────────────────────────────
class _MaterialPhase extends StatelessWidget {
  final bool              barcodeMode;
  final List<MaterialModel>    allMaterials, filteredMaterials;
  final List<StockTransaction> barcodeResults;
  final TextEditingController  materialSearchCtrl, barcodeSearchCtrl;
  final ValueChanged<MaterialModel>    onSelectMaterial;
  final ValueChanged<StockTransaction> onSelectFromBarcode;

  const _MaterialPhase({
    required this.barcodeMode,
    required this.allMaterials,
    required this.filteredMaterials,
    required this.barcodeResults,
    required this.materialSearchCtrl,
    required this.barcodeSearchCtrl,
    required this.onSelectMaterial,
    required this.onSelectFromBarcode,
  });

  @override
  Widget build(BuildContext context) {
    if (barcodeMode) {
      return _BarcodeModeBody(
        controller: barcodeSearchCtrl,
        results:    barcodeResults,
        onSelect:   onSelectFromBarcode,
      );
    }
    return _NameModeBody(
      allMaterials:      allMaterials,
      filteredMaterials: filteredMaterials,
      searchCtrl:        materialSearchCtrl,
      onSelect:          onSelectMaterial,
    );
  }
}

// ── Name search mode ──────────────────────────────────────────────────────────
class _NameModeBody extends StatelessWidget {
  final List<MaterialModel>   allMaterials, filteredMaterials;
  final TextEditingController searchCtrl;
  final ValueChanged<MaterialModel> onSelect;
  const _NameModeBody({required this.allMaterials, required this.filteredMaterials,
    required this.searchCtrl, required this.onSelect});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
        child: _SearchField(
          controller: searchCtrl,
          hint:       'Search by material name…',
          icon:       Icons.search_rounded,
        ),
      ),
      if (allMaterials.isEmpty)
        const Expanded(child: _EmptyState(
          icon:     Icons.layers_clear_outlined,
          title:    'No materials in inventory',
          subtitle: 'Add materials via the inventory screen',
        ))
      else if (filteredMaterials.isEmpty)
        const Expanded(child: _EmptyState(
          icon:     Icons.search_off_rounded,
          title:    'No results',
          subtitle: 'Try a different search term',
        ))
      else
        Expanded(
          child: ListView.separated(
            padding:          const EdgeInsets.fromLTRB(12, 0, 12, 12),
            itemCount:        filteredMaterials.length,
            separatorBuilder: (_, __) => const SizedBox(height: 5),
            itemBuilder: (_, i) {
              final m = filteredMaterials[i];
              return _MaterialNameTile(material: m, onTap: () => onSelect(m));
            },
          ),
        ),
    ],
  );
}

class _MaterialNameTile extends StatefulWidget {
  final MaterialModel material;
  final VoidCallback  onTap;
  const _MaterialNameTile({required this.material, required this.onTap});
  @override State<_MaterialNameTile> createState() => _MaterialNameTileState();
}

class _MaterialNameTileState extends State<_MaterialNameTile> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) {
    final m = widget.material;
    // Stock pill
    final Color stockColor = m.isCriticalStock ? _T.red : m.isLowStock ? _T.amber : _T.green;
    final Color stockBg    = m.isCriticalStock ? _T.red50 : m.isLowStock ? _T.amber50 : _T.green50;
    final String stockLabel = m.isCriticalStock ? 'Out of stock' : m.isLowStock ? 'Low stock' : 'In stock';

    return MouseRegion(
      cursor:  SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          decoration: BoxDecoration(
            color:        _hovered ? _T.purple50 : Colors.transparent,
            borderRadius: BorderRadius.circular(_T.r),
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 130),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(_T.r),
              border:       Border.all(
                  color: _hovered ? _T.purple.withOpacity(0.3) : _T.slate200),
            ),
            child: Row(children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color:        _T.slate100,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: const Icon(Icons.layers_outlined, size: 14, color: _T.slate500),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(m.name, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12.5,
                        fontWeight: FontWeight.w600, color: _T.ink)),
                Text('${_fmtQty(m.currentStock)} ${m.unitShort} available',
                    style: const TextStyle(fontSize: 11, color: _T.slate400)),
              ])),
              _StatusPill(label: stockLabel, color: stockColor, bg: stockBg),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right_rounded, size: 15, color: _T.slate300),
            ]),
          ),
        ),
      ),
    );
  }
}

// ── Barcode scan mode ─────────────────────────────────────────────────────────
class _BarcodeModeBody extends StatelessWidget {
  final TextEditingController        controller;
  final List<StockTransaction>       results;
  final ValueChanged<StockTransaction> onSelect;
  const _BarcodeModeBody({required this.controller, required this.results, required this.onSelect});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      // Instructional banner
      Container(
        margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color:        _T.amber50,
          borderRadius: BorderRadius.circular(_T.r),
          border:       Border.all(color: _T.amber.withOpacity(0.35)),
        ),
        child: Row(children: const [
          Icon(Icons.info_outline_rounded, size: 13, color: _T.amber),
          SizedBox(width: 8),
          Expanded(child: Text(
            'Scan an item barcode or type it manually to jump straight to a specific item.',
            style: TextStyle(fontSize: 11.5, color: _T.ink3),
          )),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
        child: _SearchField(
          controller:  controller,
          hint:        'Scan or type barcode…',
          icon:        Icons.qr_code_scanner_rounded,
          accentColor: _T.amber,
          autofocus:   true,
        ),
      ),
      if (controller.text.isEmpty)
        const Expanded(child: _EmptyState(
          icon:     Icons.qr_code_rounded,
          title:    'Waiting for barcode',
          subtitle: 'Scan or type an item barcode above',
        ))
      else if (results.isEmpty)
        const Expanded(child: _EmptyState(
          icon:     Icons.search_off_rounded,
          title:    'No match found',
          subtitle: 'Check the barcode and try again',
        ))
      else
        Expanded(
          child: ListView.separated(
            padding:          const EdgeInsets.fromLTRB(12, 0, 12, 12),
            itemCount:        results.length,
            separatorBuilder: (_, __) => const SizedBox(height: 5),
            itemBuilder: (_, i) {
              final t = results[i];
              return _BarcodeResultTile(transaction: t, onTap: () => onSelect(t));
            },
          ),
        ),
    ],
  );
}

class _BarcodeResultTile extends StatefulWidget {
  final StockTransaction transaction;
  final VoidCallback     onTap;
  const _BarcodeResultTile({required this.transaction, required this.onTap});
  @override State<_BarcodeResultTile> createState() => _BarcodeResultTileState();
}

class _BarcodeResultTileState extends State<_BarcodeResultTile> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) {
    final t = widget.transaction;
    return MouseRegion(
      cursor:  SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          decoration: BoxDecoration(
            color:        _hovered ? _T.amber50 : Colors.transparent,
            borderRadius: BorderRadius.circular(_T.r),
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 130),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(_T.r),
              border:       Border.all(
                  color: _hovered ? _T.amber.withOpacity(0.35) : _T.slate200),
            ),
            child: Row(children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(color: _T.amber50, borderRadius: BorderRadius.circular(7),
                    border: Border.all(color: _T.amber.withOpacity(0.2))),
                child: const Icon(Icons.qr_code_rounded, size: 14, color: _T.amber),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(t.barcode ?? '—',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                        color: _T.ink3, fontFamily: 'monospace')),
                Text('${_fmtQty(t.quantity)} available',
                    style: const TextStyle(fontSize: 11, color: _T.slate400)),
              ])),
              const Icon(Icons.chevron_right_rounded, size: 15, color: _T.slate300),
            ]),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MATERIAL PHASE 2 — pick a specific stock item (batch) for a chosen material
// ─────────────────────────────────────────────────────────────────────────────
class _StockItemPhase extends StatelessWidget {
  final MaterialModel          material;
  final List<StockTransaction> stockItems;
  final bool                   isLoading;
  final StockTransaction?      selected;
  final ValueChanged<StockTransaction> onSelect;
  const _StockItemPhase({required this.material, required this.stockItems,
    required this.isLoading, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(width: 20, height: 20,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: _T.purple)),
          SizedBox(height: 12),
          Text('Loading items…',
              style: TextStyle(fontSize: 12, color: _T.slate400)),
        ]),
      );
    }

    if (stockItems.isEmpty) {
      return const _EmptyState(
        icon:     Icons.inventory_2_outlined,
        title:    'No items in stock',
        subtitle: 'All batches of this material are depleted',
      );
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      // Subheader — explains what user is choosing
      Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        decoration: const BoxDecoration(
          color:  _T.slate50,
          border: Border(bottom: BorderSide(color: _T.slate200)),
        ),
        child: Row(children: [
          const Icon(Icons.inventory_2_outlined, size: 13, color: _T.slate400),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              '${stockItems.length} item${stockItems.length == 1 ? '' : 's'} available — oldest first',
              style: const TextStyle(fontSize: 11.5, color: _T.slate400, fontWeight: FontWeight.w500),
            ),
          ),
        ]),
      ),
      Expanded(
        child: ListView.separated(
          padding:          const EdgeInsets.all(12),
          itemCount:        stockItems.length,
          separatorBuilder: (_, __) => const SizedBox(height: 6),
          itemBuilder: (_, i) {
            final t = stockItems[i];
            return _StockItemTile(
              transaction: t,
              material:    material,
              isSelected:  selected?.id == t.id,
              onTap:       () => onSelect(t),
            );
          },
        ),
      ),
    ]);
  }
}

class _StockItemTile extends StatefulWidget {
  final StockTransaction transaction;
  final MaterialModel    material;
  final bool             isSelected;
  final VoidCallback     onTap;
  const _StockItemTile({required this.transaction, required this.material,
    required this.isSelected, required this.onTap});
  @override State<_StockItemTile> createState() => _StockItemTileState();
}

class _StockItemTileState extends State<_StockItemTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final t        = widget.transaction;
    final m        = widget.material;
    final selected = widget.isSelected;

    // Date label
    final dt  = t.createdAt;
    final now = DateTime.now();
    final String dateLabel = (dt.year == now.year && dt.month == now.month && dt.day == now.day)
        ? 'Received today'
        : 'Received ${dt.day}/${dt.month}/${dt.year}';

    return MouseRegion(
      cursor:  SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          decoration: BoxDecoration(
            color:        selected ? _T.purple50 : _hovered ? _T.slate50 : _T.white,
            borderRadius: BorderRadius.circular(_T.r),
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 130),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(_T.r),
              border:       Border.all(
                color: selected ? _T.purple.withOpacity(0.4) : _T.slate200,
                width: selected ? 1.5 : 1,
              ),
              boxShadow: selected ? [BoxShadow(
                color:  _T.purple.withOpacity(0.08),
                blurRadius: 8, offset: const Offset(0, 2),
              )] : null,
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Top row: quantity + check
              Row(children: [
                Container(
                  width: 30, height: 30,
                  decoration: BoxDecoration(
                    color:        selected ? _T.purple.withOpacity(0.10) : _T.slate100,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Icon(Icons.inventory_2_outlined, size: 14,
                      color: selected ? _T.purple : _T.slate500),
                ),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    '${_fmtQty(t.quantity)} ${m.unitShort}',
                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800,
                        color: selected ? _T.purple : _T.ink),
                  ),
                  Text(dateLabel, style: const TextStyle(fontSize: 11, color: _T.slate400)),
                ])),
                if (selected)
                  const Icon(Icons.check_circle_rounded, size: 16, color: _T.purple),
              ]),
              // Barcode row
              if (t.barcode != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color:        selected ? _T.white : _T.slate50,
                    borderRadius: BorderRadius.circular(6),
                    border:       Border.all(
                        color: selected ? _T.purple.withOpacity(0.2) : _T.slate200),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.qr_code_rounded, size: 11,
                        color: selected ? _T.purple : _T.slate400),
                    const SizedBox(width: 6),
                    Text(
                      t.barcode!,
                      style: TextStyle(
                        fontSize:   10.5,
                        fontWeight: FontWeight.w600,
                        color:      selected ? _T.purple : _T.ink3,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ]),
                ),
              ],
              // Notes if present
              if (t.notes != null) ...[
                const SizedBox(height: 6),
                Row(children: [
                  const Icon(Icons.notes_rounded, size: 11, color: _T.slate400),
                  const SizedBox(width: 5),
                  Expanded(child: Text(t.notes!,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: _T.slate400))),
                ]),
              ],
            ]),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// USAGE PANEL (right column)
// ─────────────────────────────────────────────────────────────────────────────
class _UsagePanel extends StatelessWidget {
  final Task               task;
  final Printer?           printer;
  final MaterialModel?     material;
  final StockTransaction?  stockItem;
  final TextEditingController qtyCtrl;
  final double?            qty, maxQty;
  final bool               qtyValid, submitted, canSubmit, submitting;
  final VoidCallback       onSubmit;
  final _Step              step;

  const _UsagePanel({
    required this.task,     required this.printer,   required this.material,
    required this.stockItem, required this.qtyCtrl,  required this.qty,
    required this.maxQty,  required this.qtyValid,  required this.submitted,
    required this.canSubmit, required this.submitting, required this.onSubmit,
    required this.step,
  });

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [

      // ── Job summary card ───────────────────────────────────────────────
      _JobSummaryCard(
        task:      task,
        printer:   printer,
        material:  material,
        stockItem: stockItem,
      ),
      const SizedBox(height: 18),

      // ── Quantity input ─────────────────────────────────────────────────
      const Text('QUANTITY TO USE',
          style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800,
              letterSpacing: 0.9, color: _T.slate400)),
      const SizedBox(height: 10),
      _QtyInput(
        stockItem: stockItem,
        material:  material,
        controller: qtyCtrl,
        maxQty:    maxQty,
        submitted: submitted,
        qtyValid:  qtyValid,
      ),
      const SizedBox(height: 20),
      const Divider(height: 1, color: _T.slate200),
      const SizedBox(height: 16),

      // ── CTA ────────────────────────────────────────────────────────────
      _CtaButton(canSubmit: canSubmit, submitting: submitting, onTap: onSubmit),
      const SizedBox(height: 10),

      // Hint text
      if (!canSubmit)
        Text(
          _hintFor(step, stockItem, qty),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11.5, color: _T.slate400),
        ),
    ]),
  );

  static String _hintFor(_Step step, StockTransaction? item, double? qty) {
    if (step == _Step.printer)  return 'Select a printer to continue';
    if (step == _Step.material) return 'Select an item to continue';
    if (item == null)           return 'Select an item to continue';
    if (qty == null)            return 'Enter the quantity to use';
    return 'Quantity exceeds available stock';
  }
}

// ── Job summary card ───────────────────────────────────────────────────────────
class _JobSummaryCard extends StatelessWidget {
  final Task              task;
  final Printer?          printer;
  final MaterialModel?    material;
  final StockTransaction? stockItem;
  const _JobSummaryCard({required this.task, required this.printer,
    required this.material, required this.stockItem});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color:        _T.slate50,
      borderRadius: BorderRadius.circular(_T.rLg),
      border:       Border.all(color: _T.slate200),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Task header
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
        child: Row(children: [
          const Icon(Icons.assignment_outlined, size: 12, color: _T.slate400),
          const SizedBox(width: 6),
          Expanded(child: Text(task.name, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _T.ink3))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: _T.slate100,
                borderRadius: BorderRadius.circular(4), border: Border.all(color: _T.slate200)),
            child: Text('TASK-${task.id}',
                style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700,
                    color: _T.slate500, fontFamily: 'monospace', letterSpacing: 0.2))),
        ]),
      ),
      const Divider(height: 1, color: _T.slate100),
      _SummaryRow(
        icon:        Icons.print_outlined,
        label:       'Printer',
        value:       printer?.name,
        placeholder: 'Not selected',
        color:       _T.blue,
        bg:          _T.blue50,
      ),
      const Divider(height: 1, color: _T.slate100),
      _SummaryRow(
        icon:        Icons.layers_outlined,
        label:       'Material',
        value:       material?.name,
        placeholder: 'Not selected',
        color:       _T.purple,
        bg:          _T.purple50,
      ),
      // Barcode row — only when stock item selected
      if (stockItem?.barcode != null) ...[
        const Divider(height: 1, color: _T.slate100),
        _SummaryRow(
          icon:        Icons.qr_code_rounded,
          label:       'Item',
          value:       stockItem!.barcode,
          placeholder: '—',
          color:       _T.amber,
          bg:          _T.amber50,
          mono:        true,
        ),
      ],
    ]),
  );
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String?  value;
  final String   placeholder;
  final Color    color, bg;
  final bool     mono;
  const _SummaryRow({required this.icon, required this.label,
    required this.value, required this.placeholder,
    required this.color, required this.bg, this.mono = false});

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      child: Row(children: [
        Container(width: 22, height: 22,
          decoration: BoxDecoration(
            color:        hasValue ? bg : _T.slate100,
            borderRadius: BorderRadius.circular(5)),
          child: Icon(icon, size: 10, color: hasValue ? color : _T.slate400)),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 11,
            fontWeight: FontWeight.w500, color: _T.slate400)),
        const Spacer(),
        Flexible(child: Text(
          value ?? placeholder,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600,
              color: hasValue ? _T.ink3 : _T.slate300,
              fontFamily: mono ? 'monospace' : null),
        )),
        if (hasValue) ...[
          const SizedBox(width: 5),
          Icon(Icons.check_circle_rounded, size: 10, color: color),
        ],
      ]),
    );
  }
}

// ── Quantity input ─────────────────────────────────────────────────────────────
class _QtyInput extends StatefulWidget {
  final StockTransaction?     stockItem;
  final MaterialModel?        material;
  final TextEditingController controller;
  final double?               maxQty;
  final bool                  submitted, qtyValid;
  const _QtyInput({required this.stockItem, required this.material,
    required this.controller, required this.maxQty,
    required this.submitted, required this.qtyValid});
  @override State<_QtyInput> createState() => _QtyInputState();
}

class _QtyInputState extends State<_QtyInput> {
  final _focus = FocusNode();
  bool _focused = false;
  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() => _focused = _focus.hasFocus));
  }
  @override void dispose() { _focus.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final disabled  = widget.stockItem == null;
    final hasError  = widget.submitted && !widget.qtyValid && !disabled;
    final unit      = widget.material?.unitShort.toUpperCase() ?? '—';

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Input row
      Row(children: [
        Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: 42,
            decoration: BoxDecoration(
              color:        disabled ? _T.slate50 : _focused ? _T.white : _T.slate50,
              borderRadius: BorderRadius.circular(_T.r),
              border:       Border.all(
                color: hasError ? _T.red
                    : disabled ? _T.slate100
                    : _focused ? _T.blue : _T.slate200,
                width: _focused && !disabled ? 1.5 : 1,
              ),
            ),
            child: TextField(
              controller:   widget.controller,
              focusNode:    _focus,
              enabled:      !disabled,
              textAlign:    TextAlign.right,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
                  color: disabled ? _T.slate300 : _T.ink),
              decoration: InputDecoration(
                hintText:  '0',
                hintStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
                    color: _T.slate200),
                border:         InputBorder.none,
                isDense:        true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Unit badge
        Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color:        disabled ? _T.slate50 : _T.green50,
            borderRadius: BorderRadius.circular(_T.r),
            border:       Border.all(
                color: disabled ? _T.slate100 : _T.green.withOpacity(0.25)),
          ),
          child: Center(child: Text(unit,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800,
                  color: disabled ? _T.slate300 : _T.green, letterSpacing: 0.5))),
        ),
      ]),
      const SizedBox(height: 7),
      // Available stock info + error
      if (widget.stockItem != null) ...[
        Row(children: [
          Container(width: 5, height: 5,
              decoration: BoxDecoration(
                  color: widget.qtyValid ? _T.green : _T.red, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Text(
            '${_fmtQty(widget.maxQty ?? 0)} ${widget.material?.unitShort ?? ''} available in this item',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500,
                color: widget.qtyValid ? _T.green : _T.red),
          ),
        ]),
        if (hasError && !widget.qtyValid) ...[
          const SizedBox(height: 4),
          Row(children: const [
            Icon(Icons.error_outline_rounded, size: 11, color: _T.red),
            SizedBox(width: 4),
            Text('Quantity exceeds available stock in this item',
                style: TextStyle(fontSize: 11, color: _T.red, fontWeight: FontWeight.w500)),
          ]),
        ],
      ] else
        const Text('Select an item first',
            style: TextStyle(fontSize: 11, color: _T.slate300)),
    ]);
  }
}

// ── CTA ────────────────────────────────────────────────────────────────────────
class _CtaButton extends StatefulWidget {
  final bool canSubmit, submitting;
  final VoidCallback onTap;
  const _CtaButton({required this.canSubmit, required this.submitting, required this.onTap});
  @override State<_CtaButton> createState() => _CtaButtonState();
}

class _CtaButtonState extends State<_CtaButton> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) {
    final active = widget.canSubmit && !widget.submitting;
    return MouseRegion(
      cursor:  active ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: active ? widget.onTap : null,
        child: Container(
          decoration: BoxDecoration(
            color:        widget.submitting ? _T.slate100
                  : active ? (_hovered ? _T.blueHover : _T.blue) : _T.slate100,
            borderRadius: BorderRadius.circular(_T.r),
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(_T.r),
              boxShadow: active ? [BoxShadow(color: _T.blue.withOpacity(0.25),
                  blurRadius: 8, offset: const Offset(0, 2))] : null,
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              if (widget.submitting)
                const SizedBox(width: 14, height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
              else
                Icon(Icons.print_rounded, size: 15,
                    color: active ? Colors.white : _T.slate300),
              const SizedBox(width: 8),
              Text(
                widget.submitting ? 'Starting…' : 'Start Print Job',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700,
                    color: active || widget.submitting ? Colors.white : _T.slate300),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED SMALL WIDGETS
// ─────────────────────────────────────────────────────────────────────────────
class _SearchField extends StatefulWidget {
  final TextEditingController controller;
  final String                hint;
  final IconData              icon;
  final Color                 accentColor;
  final bool                  autofocus;
  const _SearchField({required this.controller, required this.hint,
    required this.icon, this.accentColor = _T.blue, this.autofocus = false});
  @override State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  final _focus = FocusNode();
  bool _focused = false;
  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() => _focused = _focus.hasFocus));
    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
    }
  }
  @override void dispose() { _focus.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 150),
    height: 34,
    decoration: BoxDecoration(
      color:        _focused ? _T.white : _T.slate50,
      borderRadius: BorderRadius.circular(_T.r),
      border:       Border.all(
        color: _focused ? widget.accentColor : _T.slate200,
        width: _focused ? 1.5 : 1,
      ),
    ),
    child: TextField(
      controller: widget.controller,
      focusNode:  _focus,
      style: const TextStyle(fontSize: 12.5, color: _T.ink),
      decoration: InputDecoration(
        hintText:  widget.hint,
        hintStyle: const TextStyle(fontSize: 12.5, color: _T.slate300),
        prefixIcon: Icon(widget.icon, size: 14,
            color: _focused ? widget.accentColor : _T.slate400),
        suffixIcon: widget.controller.text.isNotEmpty
            ? GestureDetector(
                onTap: () { widget.controller.clear(); },
                child: const Icon(Icons.close_rounded, size: 13, color: _T.slate400))
            : null,
        border:         InputBorder.none,
        isDense:        true,
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
      ),
    ),
  );
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color  color, bg;
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
    ]),
  );
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String   title, subtitle;
  const _EmptyState({required this.icon, required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 24, color: _T.slate300),
      const SizedBox(height: 10),
      Text(title, style: const TextStyle(fontSize: 12.5,
          fontWeight: FontWeight.w600, color: _T.slate400)),
      const SizedBox(height: 3),
      Text(subtitle, style: const TextStyle(fontSize: 11, color: _T.slate300)),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────────────────────────────────────────
String _fmtQty(double v) =>
    v == v.truncateToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);
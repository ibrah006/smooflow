// ─────────────────────────────────────────────────────────────────────────────
// material_reports_screen.dart
//
// Desktop material consumption reports for large-format printing teams.
//
// SECTIONS
// ────────
//   KPI row          — period totals: consumed, top material, active projects,
//                      avg per job
//   Monthly Trend    — stacked bar chart: consumption by material per month
//                      (12-month rolling window)
//   Material Split   — donut + ranked bar list (% share of total consumption)
//   By Project       — horizontal bar per project coloured by project colour,
//                      expandable to show per-material breakdown
//   By Client        — same pattern as project but grouped by client name
//                      (derived from project.clientName or task.clientRef)
//   Stock Health     — current stock vs min threshold per material, sorted
//                      by criticality (out → low → ok)
//   Top Jobs table   — last N stock-out transactions sorted by qty descending
//   Efficiency       — avg qty per job per material (useful for estimating)
//
// DATA
// ────
//   All data is derived from:
//     • materialNotifierProvider  → List<MaterialModel>
//     • materialNotifierProvider  → StockTransaction (stockOut entries)
//     • projectProvider           → List<Project>
//     • taskProvider              → List<Task>   (for clientRef / projectId)
//
//   All heavy computation is done in _ReportsData (derived model computed once
//   in initState and on filter change — not in build()).
//
// FILTERS
// ───────
//   Period picker  — Last 3 / 6 / 12 months (default 12)
//   Material filter — All / individual material dropdown
//   Project filter  — All / individual project dropdown
//
// DESIGN SYSTEM
// ─────────────
//   Exact _T token set, _AnalyticsCard shell, _DonutPainter, animated progress
//   bars — matches admin_desktop_dashboard.dart & manage_materials_screen.dart.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/core/models/material.dart';
import 'package:smooflow/core/models/project.dart';
import 'package:smooflow/core/models/stock_transaction.dart';
import 'package:smooflow/core/models/task.dart';
import 'package:smooflow/providers/material_provider.dart';
import 'package:smooflow/providers/project_provider.dart';
import 'package:smooflow/providers/task_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DESIGN TOKENS
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
  static const teal      = Color(0xFF0EA5E9);
  static const teal50    = Color(0xFFE0F2FE);
  static const orange    = Color(0xFFF97316);
  static const orange50  = Color(0xFFFFF7ED);
  static const pink      = Color(0xFFEC4899);
  static const pink50    = Color(0xFFFDF2F8);
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

  // Palette for per-material colours (cycled)
  static const materialPalette = [
    blue, green, purple, amber, teal, orange, pink, red,
    Color(0xFF06B6D4), Color(0xFF84CC16),
  ];
}

// ─────────────────────────────────────────────────────────────────────────────
// PERIOD FILTER
// ─────────────────────────────────────────────────────────────────────────────
enum _Period { months3, months6, months12 }

extension _PeriodX on _Period {
  String get label => switch (this) {
    _Period.months3  => 'Last 3 months',
    _Period.months6  => 'Last 6 months',
    _Period.months12 => 'Last 12 months',
  };
  int get months => switch (this) {
    _Period.months3  => 3,
    _Period.months6  => 6,
    _Period.months12 => 12,
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// COMPUTED REPORT DATA
// ─────────────────────────────────────────────────────────────────────────────
class _MonthBucket {
  final int year, month;
  // materialId → total qty consumed
  final Map<String, double> byMaterial;
  _MonthBucket(this.year, this.month, this.byMaterial);
  double get total => byMaterial.values.fold(0, (a, b) => a + b);
  String get label {
    const names = ['Jan','Feb','Mar','Apr','May','Jun',
                   'Jul','Aug','Sep','Oct','Nov','Dec'];
    return names[month - 1];
  }
}

class _MaterialSummary {
  final MaterialModel material;
  final double        totalConsumed;
  final int           jobCount;
  final double        avgPerJob;
  _MaterialSummary({
    required this.material,
    required this.totalConsumed,
    required this.jobCount,
  }) : avgPerJob = jobCount > 0 ? totalConsumed / jobCount : 0;
}

class _ProjectSummary {
  final String        projectId;
  final String        projectName;
  final Color         projectColor;
  final double        totalConsumed;
  // materialId → qty
  final Map<String, double> byMaterial;
  _ProjectSummary({
    required this.projectId,
    required this.projectName,
    required this.projectColor,
    required this.totalConsumed,
    required this.byMaterial,
  });
}

class _ClientSummary {
  final String clientName;
  final double totalConsumed;
  final Map<String, double> byMaterial;
  _ClientSummary({
    required this.clientName,
    required this.totalConsumed,
    required this.byMaterial,
  });
}

class _ReportsData {
  final List<_MonthBucket>    months;
  final List<_MaterialSummary> materials;
  final List<_ProjectSummary>  projects;
  final List<_ClientSummary>   clients;
  final List<StockTransaction> topJobs;
  final double                 totalConsumed;
  final int                    totalJobs;

  const _ReportsData({
    required this.months,
    required this.materials,
    required this.projects,
    required this.clients,
    required this.topJobs,
    required this.totalConsumed,
    required this.totalJobs,
  });

  static _ReportsData empty() => _ReportsData(
    months: [], materials: [], projects: [], clients: [],
    topJobs: [], totalConsumed: 0, totalJobs: 0,
  );
}

_ReportsData _computeReports({
  required List<MaterialModel>    allMaterials,
  required List<StockTransaction> allTransactions,
  required List<Project>          allProjects,
  required List<Task>             allTasks,
  required _Period                period,
  required String?                filterMaterialId,
  required String?                filterProjectId,
}) {
  final now   = DateTime.now();
  final since = DateTime(now.year, now.month - period.months + 1, 1);

  // Filter to stockOut only within period
  var txns = allTransactions
      .where((t) =>
          t.type == TransactionType.stockOut &&
          !t.createdAt.isBefore(since))
      .toList();

  if (filterMaterialId != null) {
    txns = txns.where((t) => t.materialId == filterMaterialId).toList();
  }
  if (filterProjectId != null) {
    txns = txns.where((t) => t.projectId == filterProjectId).toList();
  }

  // ── Monthly buckets ──────────────────────────────────────────────────────
  final monthKeys = <String, Map<String, double>>{};
  for (var i = 0; i < period.months; i++) {
    final d = DateTime(now.year, now.month - i, 1);
    monthKeys['${d.year}-${d.month}'] = {};
  }
  for (final t in txns) {
    final key = '${t.createdAt.year}-${t.createdAt.month}';
    if (!monthKeys.containsKey(key)) continue;
    monthKeys[key]![t.materialId] =
        (monthKeys[key]![t.materialId] ?? 0) + t.quantity;
  }
  final months = monthKeys.entries.map((e) {
    final parts = e.key.split('-');
    return _MonthBucket(int.parse(parts[0]), int.parse(parts[1]), e.value);
  }).toList()
    ..sort((a, b) => DateTime(a.year, a.month)
        .compareTo(DateTime(b.year, b.month)));

  // ── Per-material summary ──────────────────────────────────────────────────
  final matTotals  = <String, double>{};
  final matJobCnt  = <String, int>{};
  for (final t in txns) {
    matTotals[t.materialId]  = (matTotals[t.materialId] ?? 0) + t.quantity;
    matJobCnt[t.materialId]  = (matJobCnt[t.materialId] ?? 0) + 1;
  }
  final materials = allMaterials
      .where((m) => matTotals.containsKey(m.id))
      .map((m) => _MaterialSummary(
            material:      m,
            totalConsumed: matTotals[m.id]!,
            jobCount:      matJobCnt[m.id]!,
          ))
      .toList()
    ..sort((a, b) => b.totalConsumed.compareTo(a.totalConsumed));

  // ── Per-project summary ───────────────────────────────────────────────────
  final projTotals = <String, Map<String, double>>{};
  for (final t in txns) {
    if (t.projectId == null) continue;
    projTotals.putIfAbsent(t.projectId!, () => {});
    projTotals[t.projectId!]![t.materialId] =
        (projTotals[t.projectId!]![t.materialId] ?? 0) + t.quantity;
  }
  final projects = projTotals.entries.map((e) {
    final proj  = allProjects.cast<Project?>()
        .firstWhere((p) => p?.id == e.key, orElse: () => null);
    final total = e.value.values.fold(0.0, (a, b) => a + b);
    return _ProjectSummary(
      projectId:    e.key,
      projectName:  proj?.name ?? 'Unknown Project',
      projectColor: proj?.color ?? _T.slate400,
      totalConsumed: total,
      byMaterial:   e.value,
    );
  }).toList()
    ..sort((a, b) => b.totalConsumed.compareTo(a.totalConsumed));

  // ── Per-client summary ────────────────────────────────────────────────────
  // Map project → client name via Project.clientName (fall back to "No client")
  final clientTotals = <String, Map<String, double>>{};
  for (final t in txns) {
    if (t.projectId == null) continue;
    final proj = allProjects.cast<Project?>()
        .firstWhere((p) => p?.id == t.projectId, orElse: () => null);
    final client = (proj?.client.name.isNotEmpty == true)
        ? proj!.client.name
        : 'Internal / Unassigned';
    clientTotals.putIfAbsent(client, () => {});
    clientTotals[client]![t.materialId] =
        (clientTotals[client]![t.materialId] ?? 0) + t.quantity;
  }
  final clients = clientTotals.entries.map((e) {
    final total = e.value.values.fold(0.0, (a, b) => a + b);
    return _ClientSummary(
      clientName:    e.key,
      totalConsumed: total,
      byMaterial:    e.value,
    );
  }).toList()
    ..sort((a, b) => b.totalConsumed.compareTo(a.totalConsumed));

  // ── Top jobs (by qty) ─────────────────────────────────────────────────────
  final topJobs = List<StockTransaction>.from(txns)
    ..sort((a, b) => b.quantity.compareTo(a.quantity));

  final totalConsumed = txns.fold(0.0, (s, t) => s + t.quantity);

  return _ReportsData(
    months:        months,
    materials:     materials,
    projects:      projects,
    clients:       clients,
    topJobs:       topJobs.take(20).toList(),
    totalConsumed: totalConsumed,
    totalJobs:     txns.length,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class MaterialReportsScreen extends ConsumerStatefulWidget {
  const MaterialReportsScreen({super.key});
  @override
  ConsumerState<MaterialReportsScreen> createState() =>
      _MaterialReportsScreenState();
}

class _MaterialReportsScreenState
    extends ConsumerState<MaterialReportsScreen> {
  _Period  _period            = _Period.months12;
  String?  _filterMaterialId;
  String?  _filterProjectId;
  _ReportsData _data          = _ReportsData.empty();
  bool        _loading        = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(_recompute);
  }

  Future<void> _recompute() async {
    setState(() => _loading = true);
    final mats  = ref.read(materialNotifierProvider).materials;
    final txns  = ref.read(materialNotifierProvider).transactions;
    final projs = ref.read(projectNotifierProvider);
    final tasks = ref.read(taskNotifierProvider).tasks;
    final data  = _computeReports(
      allMaterials:    mats,
      allTransactions: txns,
      allProjects:     projs,
      allTasks:        tasks,
      period:          _period,
      filterMaterialId: _filterMaterialId,
      filterProjectId: _filterProjectId,
    );
    if (mounted) setState(() { _data = data; _loading = false; });
  }

  // Assign consistent colour to each material across all charts
  Color _matColor(String materialId) {
    final mats = ref.read(materialNotifierProvider).materials;
    final idx  = mats.indexWhere((m) => m.id == materialId);
    return _T.materialPalette[(idx < 0 ? 0 : idx) % _T.materialPalette.length];
  }

  String _matName(String materialId) {
    final mats = ref.read(materialNotifierProvider).materials;
    return mats.cast<MaterialModel?>()
        .firstWhere((m) => m?.id == materialId, orElse: () => null)
        ?.name ?? materialId;
  }

  String _matUnit(String materialId) {
    final mats = ref.read(materialNotifierProvider).materials;
    return mats.cast<MaterialModel?>()
        .firstWhere((m) => m?.id == materialId, orElse: () => null)
        ?.unitShort ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final allMats  = ref.watch(materialNotifierProvider).materials;
    final allProjs = ref.watch(projectNotifierProvider);

    return Scaffold(
      backgroundColor: _T.slate50,
      body: Column(children: [
        // ── Topbar ──────────────────────────────────────────────────────
        _ReportsTopbar(
          period:           _period,
          filterMaterialId: _filterMaterialId,
          filterProjectId:  _filterProjectId,
          allMaterials:     allMats,
          allProjects:      allProjs,
          onPeriod: (p) {
            setState(() => _period = p);
            _recompute();
          },
          onMaterial: (id) {
            setState(() => _filterMaterialId = id);
            _recompute();
          },
          onProject: (id) {
            setState(() => _filterProjectId = id);
            _recompute();
          },
        ),

        // ── Body ────────────────────────────────────────────────────────
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: _T.blue))
              : _data.totalConsumed == 0 && _data.materials.isEmpty
                  ? _EmptyReports(period: _period)
                  : _ReportsBody(
                      data:     _data,
                      period:   _period,
                      allMats:  allMats,
                      matColor: _matColor,
                      matName:  _matName,
                      matUnit:  _matUnit,
                    ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TOP BAR
// ─────────────────────────────────────────────────────────────────────────────
class _ReportsTopbar extends StatelessWidget {
  final _Period             period;
  final String?             filterMaterialId, filterProjectId;
  final List<MaterialModel> allMaterials;
  final List<Project>       allProjects;
  final ValueChanged<_Period>  onPeriod;
  final ValueChanged<String?>  onMaterial, onProject;

  const _ReportsTopbar({
    required this.period,
    required this.filterMaterialId,
    required this.filterProjectId,
    required this.allMaterials,
    required this.allProjects,
    required this.onPeriod,
    required this.onMaterial,
    required this.onProject,
  });

  @override
  Widget build(BuildContext context) => Container(
    height: 58,
    padding: const EdgeInsets.symmetric(horizontal: 24),
    decoration: const BoxDecoration(
      color:  _T.white,
      border: Border(bottom: BorderSide(color: _T.slate200)),
    ),
    child: Row(children: [
      // Icon badge
      Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          color:        _T.blue50,
          borderRadius: BorderRadius.circular(9),
          border:       Border.all(color: _T.blue.withOpacity(0.2)),
        ),
        child: const Icon(Icons.bar_chart_rounded, size: 16, color: _T.blue),
      ),
      const SizedBox(width: 12),
      Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Material Reports',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                color: _T.ink, letterSpacing: -0.2)),
        const Text('Consumption analysis for your print team',
            style: TextStyle(fontSize: 10.5, color: _T.slate400, fontWeight: FontWeight.w500)),
      ]),
      const Spacer(),

      // Period picker
      _FilterDropdown<_Period>(
        icon:        Icons.date_range_outlined,
        label:       period.label,
        items:       _Period.values,
        itemLabel:   (p) => p.label,
        selected:    period,
        onChanged:   onPeriod,
        accentColor: _T.blue,
      ),
      const SizedBox(width: 8),

      // Material filter
      _FilterDropdown<String?>(
        icon:        Icons.layers_outlined,
        label:       filterMaterialId == null
            ? 'All materials'
            : allMaterials.cast<MaterialModel?>()
                .firstWhere((m) => m?.id == filterMaterialId, orElse: () => null)
                ?.name ?? 'All materials',
        items:       [null, ...allMaterials.map((m) => m.id)],
        itemLabel:   (id) => id == null
            ? 'All materials'
            : allMaterials.cast<MaterialModel?>()
                .firstWhere((m) => m?.id == id, orElse: () => null)
                ?.name ?? id!,
        selected:    filterMaterialId,
        onChanged:   onMaterial,
        accentColor: _T.purple,
        hasReset:    filterMaterialId != null,
      ),
      const SizedBox(width: 8),

      // Project filter
      _FilterDropdown<String?>(
        icon:        Icons.folder_outlined,
        label:       filterProjectId == null
            ? 'All projects'
            : allProjects.cast<Project?>()
                .firstWhere((p) => p?.id == filterProjectId, orElse: () => null)
                ?.name ?? 'All projects',
        items:       [null, ...allProjects.map((p) => p.id)],
        itemLabel:   (id) => id == null
            ? 'All projects'
            : allProjects.cast<Project?>()
                .firstWhere((p) => p?.id == id, orElse: () => null)
                ?.name ?? id!,
        selected:    filterProjectId,
        onChanged:   onProject,
        accentColor: _T.green,
        hasReset:    filterProjectId != null,
      ),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// FILTER DROPDOWN
// ─────────────────────────────────────────────────────────────────────────────
class _FilterDropdown<T> extends StatelessWidget {
  final IconData         icon;
  final String           label;
  final List<T>          items;
  final String Function(T) itemLabel;
  final T                selected;
  final ValueChanged<T>  onChanged;
  final Color            accentColor;
  final bool             hasReset;
  const _FilterDropdown({
    required this.icon,
    required this.label,
    required this.items,
    required this.itemLabel,
    required this.selected,
    required this.onChanged,
    required this.accentColor,
    this.hasReset = false,
  });

  @override
  Widget build(BuildContext context) => Container(
    height: 32,
    decoration: BoxDecoration(
      color:        hasReset ? accentColor.withOpacity(0.07) : _T.white,
      borderRadius: BorderRadius.circular(_T.r),
      border:       Border.all(
          color: hasReset ? accentColor.withOpacity(0.4) : _T.slate200),
    ),
    child: PopupMenuButton<T>(
      onSelected: onChanged,
      offset:     const Offset(0, 36),
      shape:      RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_T.rLg),
          side: const BorderSide(color: _T.slate200)),
      color: _T.white,
      elevation: 4,
      itemBuilder: (_) => items.map((item) => PopupMenuItem<T>(
        value: item,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        child: Row(children: [
          if (item == selected)
            Icon(Icons.check_rounded, size: 13, color: accentColor)
          else
            const SizedBox(width: 13),
          const SizedBox(width: 8),
          Text(itemLabel(item),
              style: TextStyle(
                fontSize: 12.5, fontWeight: FontWeight.w500,
                color: item == selected ? accentColor : _T.ink3,
              )),
        ]),
      )).toList(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 13,
              color: hasReset ? accentColor : _T.slate400),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
              color: hasReset ? accentColor : _T.ink3)),
          const SizedBox(width: 4),
          Icon(Icons.keyboard_arrow_down_rounded, size: 14,
              color: hasReset ? accentColor : _T.slate400),
        ]),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// REPORTS BODY — scrollable column of sections
// ─────────────────────────────────────────────────────────────────────────────
class _ReportsBody extends StatelessWidget {
  final _ReportsData       data;
  final _Period            period;
  final List<MaterialModel> allMats;
  final Color Function(String)  matColor;
  final String Function(String) matName;
  final String Function(String) matUnit;

  const _ReportsBody({
    required this.data,
    required this.period,
    required this.allMats,
    required this.matColor,
    required this.matName,
    required this.matUnit,
  });

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

      // ── KPI row ──────────────────────────────────────────────────────
      _KpiRow(data: data, matName: matName, matUnit: matUnit),
      const SizedBox(height: 24),

      // ── Row 1: Monthly trend (wide) + Donut split ──────────────────
      IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Expanded(flex: 3, child: _Card(
          icon:      Icons.stacked_bar_chart_rounded,
          iconColor: _T.blue,
          iconBg:    _T.blue50,
          title:     'Monthly Consumption Trend',
          subtitle:  '${period.label} — total material usage per month',
          child:     _MonthlyTrendChart(
            months:   data.months,
            matColor: matColor,
            matName:  matName,
          ),
        )),
        const SizedBox(width: 16),
        Expanded(flex: 2, child: _Card(
          icon:      Icons.donut_large_rounded,
          iconColor: _T.purple,
          iconBg:    _T.purple50,
          title:     'Material Split',
          subtitle:  'Share of total volume consumed',
          child:     _MaterialDonut(
            materials: data.materials,
            total:     data.totalConsumed,
            matColor:  matColor,
          ),
        )),
      ])),
      const SizedBox(height: 16),

      // ── Row 2: By Project + By Client ─────────────────────────────
      IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Expanded(child: _Card(
          icon:      Icons.folder_open_outlined,
          iconColor: _T.green,
          iconBg:    _T.green50,
          title:     'Consumption by Project',
          subtitle:  'Total material used per project',
          child:     _ProjectBars(
            projects: data.projects,
            matColor: matColor,
            matName:  matName,
            matUnit:  matUnit,
          ),
        )),
        const SizedBox(width: 16),
        Expanded(child: _Card(
          icon:      Icons.business_outlined,
          iconColor: _T.teal,
          iconBg:    _T.teal50,
          title:     'Consumption by Client',
          subtitle:  'Total material used per client',
          child:     _ClientBars(
            clients:  data.clients,
            matColor: matColor,
            matName:  matName,
            matUnit:  matUnit,
          ),
        )),
      ])),
      const SizedBox(height: 16),

      // ── Row 3: Stock Health + Efficiency table ─────────────────────
      IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Expanded(flex: 2, child: _Card(
          icon:      Icons.inventory_2_outlined,
          iconColor: _T.amber,
          iconBg:    _T.amber50,
          title:     'Stock Health',
          subtitle:  'Current stock vs minimum threshold',
          child:     _StockHealthChart(allMats: allMats),
        )),
        const SizedBox(width: 16),
        Expanded(flex: 3, child: _Card(
          icon:      Icons.analytics_outlined,
          iconColor: _T.orange,
          iconBg:    _T.orange50,
          title:     'Avg Consumption per Job',
          subtitle:  'Useful for estimating material for upcoming runs',
          child:     _EfficiencyTable(
            materials: data.materials,
            matColor:  matColor,
          ),
        )),
      ])),
      const SizedBox(height: 16),

      // ── Row 4: Top jobs table (full width) ─────────────────────────
      _Card(
        icon:      Icons.receipt_long_outlined,
        iconColor: _T.ink3,
        iconBg:    _T.slate100,
        title:     'Largest Individual Jobs',
        subtitle:  'Top 20 stock-out transactions by quantity consumed',
        child:     _TopJobsTable(
          jobs:    data.topJobs,
          matName: matName,
          matUnit: matUnit,
          matColor: matColor,
        ),
      ),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// KPI ROW
// ─────────────────────────────────────────────────────────────────────────────
class _KpiRow extends StatelessWidget {
  final _ReportsData            data;
  final String Function(String) matName;
  final String Function(String) matUnit;
  const _KpiRow({required this.data, required this.matName, required this.matUnit});

  @override
  Widget build(BuildContext context) {
    final topMat   = data.materials.isNotEmpty ? data.materials.first : null;
    final topProj  = data.projects.isNotEmpty  ? data.projects.first  : null;
    final avgPerJob = data.totalJobs > 0
        ? data.totalConsumed / data.totalJobs
        : 0.0;

    return Row(children: [
      Expanded(child: _KpiCard(
        icon:      Icons.local_shipping_outlined,
        iconColor: _T.blue,
        iconBg:    _T.blue50,
        value:     _fmtQty(data.totalConsumed),
        label:     'Total Consumed',
        sub:       '${data.totalJobs} stock-out events',
      )),
      const SizedBox(width: 12),
      Expanded(child: _KpiCard(
        icon:      Icons.layers_rounded,
        iconColor: _T.purple,
        iconBg:    _T.purple50,
        value:     topMat != null ? _fmtQty(topMat.totalConsumed) : '—',
        label:     topMat != null ? topMat.material.name : 'Top Material',
        sub:       topMat != null
            ? '${matUnit(topMat.material.id)} — highest volume'
            : 'No data',
      )),
      const SizedBox(width: 12),
      Expanded(child: _KpiCard(
        icon:      Icons.folder_outlined,
        iconColor: _T.green,
        iconBg:    _T.green50,
        value:     '${data.projects.length}',
        label:     'Active Projects',
        sub:       topProj != null
            ? '${topProj.projectName} uses most'
            : 'No project data',
      )),
      const SizedBox(width: 12),
      Expanded(child: _KpiCard(
        icon:      Icons.speed_outlined,
        iconColor: _T.amber,
        iconBg:    _T.amber50,
        value:     _fmtQty(avgPerJob),
        label:     'Avg per Job',
        sub:       'mixed units — see material breakdown',
      )),
    ]);
  }
}

class _KpiCard extends StatelessWidget {
  final IconData icon;
  final Color    iconColor, iconBg;
  final String   value, label, sub;
  const _KpiCard({required this.icon, required this.iconColor,
    required this.iconBg, required this.value, required this.label, required this.sub});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color:        _T.white,
      borderRadius: BorderRadius.circular(_T.rLg),
      border:       Border.all(color: _T.slate200),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width: 34, height: 34,
          decoration: BoxDecoration(color: iconBg,
              borderRadius: BorderRadius.circular(_T.r)),
          child: Icon(icon, size: 16, color: iconColor)),
        const Spacer(),
      ]),
      const SizedBox(height: 14),
      Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800,
          color: _T.ink, letterSpacing: -1, height: 1)),
      const SizedBox(height: 5),
      Text(label, style: const TextStyle(fontSize: 12.5,
          fontWeight: FontWeight.w700, color: _T.ink3)),
      const SizedBox(height: 3),
      Text(sub, style: const TextStyle(fontSize: 11, color: _T.slate400,
          fontWeight: FontWeight.w500)),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// CARD SHELL
// ─────────────────────────────────────────────────────────────────────────────
class _Card extends StatelessWidget {
  final IconData icon;
  final Color    iconColor, iconBg;
  final String   title, subtitle;
  final Widget   child;
  const _Card({required this.icon, required this.iconColor, required this.iconBg,
    required this.title, required this.subtitle, required this.child});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color:        _T.white,
      borderRadius: BorderRadius.circular(_T.rLg),
      border:       Border.all(color: _T.slate200),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width: 28, height: 28,
          decoration: BoxDecoration(color: iconBg,
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: iconColor.withOpacity(0.2))),
          child: Icon(icon, size: 13, color: iconColor)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 13,
              fontWeight: FontWeight.w700, color: _T.ink, letterSpacing: -0.2)),
          Text(subtitle, style: const TextStyle(fontSize: 10.5,
              color: _T.slate400, fontWeight: FontWeight.w500)),
        ])),
      ]),
      const SizedBox(height: 16),
      const Divider(height: 1, color: _T.slate100),
      const SizedBox(height: 16),
      child,
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// MONTHLY TREND CHART — stacked horizontal bar per month
// ─────────────────────────────────────────────────────────────────────────────
class _MonthlyTrendChart extends StatelessWidget {
  final List<_MonthBucket>      months;
  final Color Function(String)  matColor;
  final String Function(String) matName;
  const _MonthlyTrendChart({required this.months, required this.matColor,
    required this.matName});

  @override
  Widget build(BuildContext context) {
    if (months.every((m) => m.total == 0)) {
      return _noData('No consumption data in this period');
    }

    final maxVal = months.map((m) => m.total).fold(0.0, math.max);

    // Build legend from all unique materialIds seen
    final allMatIds = <String>{};
    for (final m in months) allMatIds.addAll(m.byMaterial.keys);
    final matIds = allMatIds.toList();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Legend
      Wrap(spacing: 12, runSpacing: 6, children: matIds.map((id) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8, height: 8,
              decoration: BoxDecoration(color: matColor(id), shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Text(matName(id), style: const TextStyle(fontSize: 10.5,
              fontWeight: FontWeight.w500, color: _T.slate500)),
        ],
      )).toList()),
      const SizedBox(height: 16),

      // Bars
      ...months.map((m) {
        final frac = maxVal > 0 ? m.total / maxVal : 0.0;
        return Padding(
          padding: const EdgeInsets.only(bottom: 9),
          child: Row(children: [
            // Month label
            SizedBox(width: 36,
              child: Text(m.label, style: const TextStyle(fontSize: 11,
                  fontWeight: FontWeight.w600, color: _T.slate500))),
            const SizedBox(width: 10),
            // Stacked bar
            Expanded(child: LayoutBuilder(builder: (_, c) {
              return Stack(children: [
                Container(height: 22,
                    decoration: BoxDecoration(color: _T.slate100,
                        borderRadius: BorderRadius.circular(5))),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 600),
                  curve:    Curves.easeOutCubic,
                  height:   22,
                  width:    c.maxWidth * frac,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5)),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: Row(
                      children: m.total > 0
                          ? matIds.where((id) => (m.byMaterial[id] ?? 0) > 0).map((id) {
                              final seg = m.byMaterial[id]! / m.total;
                              return Flexible(
                                flex: (seg * 100).round(),
                                child: Container(color: matColor(id)),
                              );
                            }).toList()
                          : [const SizedBox.shrink()],
                    ),
                  ),
                ),
                if (m.total > 0)
                  Positioned(
                    left: math.max(c.maxWidth * frac - 60, 4),
                    top: 0, bottom: 0,
                    child: Center(child: Text(
                      _fmtQty(m.total),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: frac > 0.15 ? _T.white : _T.slate500,
                      ),
                    )),
                  ),
              ]);
            })),
          ]),
        );
      }),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MATERIAL DONUT + RANKED LIST
// ─────────────────────────────────────────────────────────────────────────────
class _MaterialDonut extends StatelessWidget {
  final List<_MaterialSummary> materials;
  final double                 total;
  final Color Function(String) matColor;
  const _MaterialDonut({required this.materials, required this.total,
    required this.matColor});

  @override
  Widget build(BuildContext context) {
    if (materials.isEmpty) return _noData('No consumption data');

    final values = materials.map((m) => m.totalConsumed).toList();
    final colors = materials.map((m) => matColor(m.material.id)).toList();

    return Column(children: [
      // Donut
      SizedBox(
        height: 150,
        child: CustomPaint(
          painter: _DonutPainter(values: values, colors: colors, strokeWidth: 22),
          child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(_fmtQty(total),
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800,
                    color: _T.ink, letterSpacing: -1, height: 1)),
            const Text('total', style: TextStyle(fontSize: 10,
                fontWeight: FontWeight.w500, color: _T.slate400)),
          ])),
        ),
      ),
      const SizedBox(height: 16),
      // Ranked list
      ...materials.take(6).map((m) {
        final pct = total > 0 ? m.totalConsumed / total : 0.0;
        final c   = matColor(m.material.id);
        return Padding(
          padding: const EdgeInsets.only(bottom: 9),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 8, height: 8,
                  decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
              const SizedBox(width: 7),
              Expanded(child: Text(m.material.name, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600,
                      color: _T.ink3))),
              Text('${_fmtQty(m.totalConsumed)} ${m.material.unitShort}',
                  style: const TextStyle(fontSize: 11, color: _T.slate500,
                      fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              SizedBox(width: 36, child: Text(
                '${(pct * 100).round()}%',
                textAlign: TextAlign.right,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: c),
              )),
            ]),
            const SizedBox(height: 5),
            LayoutBuilder(builder: (_, c2) => Stack(children: [
              Container(height: 4,
                  decoration: BoxDecoration(color: _T.slate100,
                      borderRadius: BorderRadius.circular(2))),
              AnimatedContainer(
                duration: const Duration(milliseconds: 700),
                curve:    Curves.easeOutCubic,
                height: 4,
                width:  c2.maxWidth * pct,
                decoration: BoxDecoration(color: c,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ])),
          ]),
        );
      }),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PROJECT BARS — expandable per-material breakdown
// ─────────────────────────────────────────────────────────────────────────────
class _ProjectBars extends StatefulWidget {
  final List<_ProjectSummary>   projects;
  final Color Function(String)  matColor;
  final String Function(String) matName;
  final String Function(String) matUnit;
  const _ProjectBars({required this.projects, required this.matColor,
    required this.matName, required this.matUnit});
  @override State<_ProjectBars> createState() => _ProjectBarsState();
}

class _ProjectBarsState extends State<_ProjectBars> {
  String? _expanded;
  @override
  Widget build(BuildContext context) {
    if (widget.projects.isEmpty) return _noData('No project data in this period');
    final maxVal = widget.projects.map((p) => p.totalConsumed).fold(0.0, math.max);

    return Column(
      children: widget.projects.take(10).map((p) {
        final frac     = maxVal > 0 ? p.totalConsumed / maxVal : 0.0;
        final isOpen   = _expanded == p.projectId;

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Main row
            MouseRegion(cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => setState(() =>
                    _expanded = isOpen ? null : p.projectId),
                child: Row(children: [
                  Container(width: 8, height: 8,
                      decoration: BoxDecoration(color: p.projectColor,
                          shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  SizedBox(width: 120,
                    child: Text(p.projectName, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12,
                            fontWeight: FontWeight.w600, color: _T.ink3))),
                  const SizedBox(width: 8),
                  Expanded(child: LayoutBuilder(builder: (_, c) => Stack(children: [
                    Container(height: 24,
                        decoration: BoxDecoration(color: _T.slate100,
                            borderRadius: BorderRadius.circular(5))),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOutCubic,
                      height: 24,
                      width: c.maxWidth * frac,
                      decoration: BoxDecoration(
                        color: p.projectColor.withOpacity(0.75),
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                            color: p.projectColor.withOpacity(0.5), width: 0.5),
                      ),
                    ),
                    if (p.totalConsumed > 0)
                      Positioned(left: 8, top: 0, bottom: 0,
                        child: Center(child: Text(_fmtQty(p.totalConsumed),
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                                color: frac > 0.25 ? _T.white : _T.slate500)))),
                  ]))),
                  const SizedBox(width: 6),
                  AnimatedRotation(
                    turns:    isOpen ? 0.5 : 0,
                    duration: const Duration(milliseconds: 150),
                    child: const Icon(Icons.keyboard_arrow_down_rounded,
                        size: 15, color: _T.slate400)),
                ]),
              ),
            ),
            // Expanded breakdown
            AnimatedCrossFade(
              crossFadeState: isOpen
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 200),
              firstChild: const SizedBox(width: double.infinity),
              secondChild: Container(
                margin: const EdgeInsets.only(top: 8, left: 16),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: _T.slate50,
                    borderRadius: BorderRadius.circular(_T.r),
                    border: Border.all(color: _T.slate200)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: p.byMaterial.entries.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(children: [
                      Container(width: 6, height: 6,
                          decoration: BoxDecoration(
                              color: widget.matColor(e.key), shape: BoxShape.circle)),
                      const SizedBox(width: 7),
                      Expanded(child: Text(widget.matName(e.key),
                          style: const TextStyle(fontSize: 11,
                              color: _T.slate500, fontWeight: FontWeight.w500))),
                      Text('${_fmtQty(e.value)} ${widget.matUnit(e.key)}',
                          style: const TextStyle(fontSize: 11,
                              fontWeight: FontWeight.w700, color: _T.ink3)),
                    ]),
                  )).toList(),
                ),
              ),
            ),
          ]),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CLIENT BARS — same pattern as project
// ─────────────────────────────────────────────────────────────────────────────
class _ClientBars extends StatefulWidget {
  final List<_ClientSummary>    clients;
  final Color Function(String)  matColor;
  final String Function(String) matName;
  final String Function(String) matUnit;
  const _ClientBars({required this.clients, required this.matColor,
    required this.matName, required this.matUnit});
  @override State<_ClientBars> createState() => _ClientBarsState();
}

class _ClientBarsState extends State<_ClientBars> {
  String? _expanded;

  static const _clientPalette = [
    _T.teal, _T.blue, _T.purple, _T.green, _T.orange,
    _T.pink, _T.amber, _T.red,
  ];

  @override
  Widget build(BuildContext context) {
    if (widget.clients.isEmpty) return _noData('No client data in this period');
    final maxVal = widget.clients.map((c) => c.totalConsumed).fold(0.0, math.max);

    return Column(
      children: widget.clients.take(10).toList().asMap().entries.map((entry) {
        final i    = entry.key;
        final cl   = entry.value;
        final color = _clientPalette[i % _clientPalette.length];
        final frac  = maxVal > 0 ? cl.totalConsumed / maxVal : 0.0;
        final isOpen = _expanded == cl.clientName;

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            MouseRegion(cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => setState(() =>
                    _expanded = isOpen ? null : cl.clientName),
                child: Row(children: [
                  Container(width: 8, height: 8,
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  SizedBox(width: 120,
                    child: Text(cl.clientName, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12,
                            fontWeight: FontWeight.w600, color: _T.ink3))),
                  const SizedBox(width: 8),
                  Expanded(child: LayoutBuilder(builder: (_, c) => Stack(children: [
                    Container(height: 24,
                        decoration: BoxDecoration(color: _T.slate100,
                            borderRadius: BorderRadius.circular(5))),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOutCubic,
                      height: 24,
                      width: c.maxWidth * frac,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.75),
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                            color: color.withOpacity(0.5), width: 0.5),
                      ),
                    ),
                    if (cl.totalConsumed > 0)
                      Positioned(left: 8, top: 0, bottom: 0,
                        child: Center(child: Text(_fmtQty(cl.totalConsumed),
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                                color: frac > 0.25 ? _T.white : _T.slate500)))),
                  ]))),
                  const SizedBox(width: 6),
                  AnimatedRotation(
                    turns:    isOpen ? 0.5 : 0,
                    duration: const Duration(milliseconds: 150),
                    child: const Icon(Icons.keyboard_arrow_down_rounded,
                        size: 15, color: _T.slate400)),
                ]),
              ),
            ),
            AnimatedCrossFade(
              crossFadeState: isOpen
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 200),
              firstChild: const SizedBox(width: double.infinity),
              secondChild: Container(
                margin: const EdgeInsets.only(top: 8, left: 16),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: _T.slate50,
                    borderRadius: BorderRadius.circular(_T.r),
                    border: Border.all(color: _T.slate200)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: cl.byMaterial.entries.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(children: [
                      Container(width: 6, height: 6,
                          decoration: BoxDecoration(
                              color: widget.matColor(e.key), shape: BoxShape.circle)),
                      const SizedBox(width: 7),
                      Expanded(child: Text(widget.matName(e.key),
                          style: const TextStyle(fontSize: 11,
                              color: _T.slate500, fontWeight: FontWeight.w500))),
                      Text('${_fmtQty(e.value)} ${widget.matUnit(e.key)}',
                          style: const TextStyle(fontSize: 11,
                              fontWeight: FontWeight.w700, color: _T.ink3)),
                    ]),
                  )).toList(),
                ),
              ),
            ),
          ]),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STOCK HEALTH CHART
// ─────────────────────────────────────────────────────────────────────────────
class _StockHealthChart extends StatelessWidget {
  final List<MaterialModel> allMats;
  const _StockHealthChart({required this.allMats});

  @override
  Widget build(BuildContext context) {
    if (allMats.isEmpty) return _noData('No materials configured');

    // Sort: critical → low → ok
    final sorted = List<MaterialModel>.from(allMats)
      ..sort((a, b) {
        int score(MaterialModel m) =>
            m.isCriticalStock ? 0 : m.isLowStock ? 1 : 2;
        return score(a).compareTo(score(b));
      });

    return Column(
      children: sorted.map((m) {
        final maxVal  = m.minStockLevel > 0 ? m.minStockLevel * 2 : 100.0;
        final frac    = (m.currentStock / maxVal).clamp(0.0, 1.0);
        final minFrac = m.minStockLevel > 0
            ? (m.minStockLevel / maxVal).clamp(0.0, 1.0)
            : 0.0;
        final Color barColor = m.isCriticalStock ? _T.red
            : m.isLowStock ? _T.amber
            : _T.green;
        final Color barBg    = m.isCriticalStock ? _T.red50
            : m.isLowStock ? _T.amber50
            : _T.green50;
        final String statusLabel = m.isCriticalStock ? 'Out'
            : m.isLowStock ? 'Low'
            : 'OK';

        return Padding(
          padding: const EdgeInsets.only(bottom: 11),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              // Status pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(color: barBg,
                    borderRadius: BorderRadius.circular(4)),
                child: Text(statusLabel, style: TextStyle(fontSize: 9.5,
                    fontWeight: FontWeight.w800, color: barColor)),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(m.name, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12,
                      fontWeight: FontWeight.w600, color: _T.ink3))),
              Text('${_fmtQty(m.currentStock)} / ${_fmtQty(m.minStockLevel)} ${m.unitShort}',
                  style: const TextStyle(fontSize: 10.5,
                      fontWeight: FontWeight.w600, color: _T.slate500)),
            ]),
            const SizedBox(height: 6),
            LayoutBuilder(builder: (_, c) => Stack(children: [
              // Track
              Container(height: 8,
                  decoration: BoxDecoration(color: _T.slate100,
                      borderRadius: BorderRadius.circular(4))),
              // Fill
              AnimatedContainer(
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
                height: 8,
                width:  c.maxWidth * frac,
                decoration: BoxDecoration(color: barColor,
                    borderRadius: BorderRadius.circular(4)),
              ),
              // Min threshold marker
              if (minFrac > 0)
                Positioned(
                  left: c.maxWidth * minFrac - 1,
                  top: 0, bottom: 0,
                  child: Container(width: 2,
                      decoration: BoxDecoration(color: _T.slate400,
                          borderRadius: BorderRadius.circular(1))),
                ),
            ])),
          ]),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EFFICIENCY TABLE — avg consumption per job per material
// ─────────────────────────────────────────────────────────────────────────────
class _EfficiencyTable extends StatelessWidget {
  final List<_MaterialSummary>  materials;
  final Color Function(String)  matColor;
  const _EfficiencyTable({required this.materials, required this.matColor});

  @override
  Widget build(BuildContext context) {
    if (materials.isEmpty) return _noData('No job data to analyse');

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Header
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(children: const [
          SizedBox(width: 14),
          Expanded(flex: 3, child: _TblHeader('MATERIAL')),
          Expanded(flex: 2, child: _TblHeader('JOBS')),
          Expanded(flex: 2, child: _TblHeader('TOTAL')),
          Expanded(flex: 2, child: _TblHeader('AVG / JOB')),
          Expanded(flex: 3, child: _TblHeader('DISTRIBUTION')),
        ]),
      ),
      const Divider(height: 1, color: _T.slate100),
      const SizedBox(height: 8),
      ...materials.map((m) {
        final c       = matColor(m.material.id);
        final maxAvg  = materials.map((x) => x.avgPerJob).fold(0.0, math.max);
        final frac    = maxAvg > 0 ? m.avgPerJob / maxAvg : 0.0;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color:        _T.slate50,
            borderRadius: BorderRadius.circular(_T.r),
            border:       Border.all(color: _T.slate100),
          ),
          child: Row(children: [
            Container(width: 6, height: 6,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
            Expanded(flex: 3, child: Text(m.material.name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12,
                    fontWeight: FontWeight.w600, color: _T.ink3))),
            Expanded(flex: 2, child: Text('${m.jobCount}',
                style: const TextStyle(fontSize: 12,
                    fontWeight: FontWeight.w600, color: _T.slate500))),
            Expanded(flex: 2, child: Text(
                '${_fmtQty(m.totalConsumed)} ${m.material.unitShort}',
                style: const TextStyle(fontSize: 12,
                    fontWeight: FontWeight.w600, color: _T.slate500))),
            Expanded(flex: 2, child: Text(
                '${_fmtQty(m.avgPerJob)} ${m.material.unitShort}',
                style: TextStyle(fontSize: 12,
                    fontWeight: FontWeight.w700, color: c))),
            Expanded(flex: 3, child: LayoutBuilder(builder: (_, con) =>
              Stack(children: [
                Container(height: 6,
                    decoration: BoxDecoration(color: _T.slate200,
                        borderRadius: BorderRadius.circular(3))),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeOutCubic,
                  height: 6,
                  width: con.maxWidth * frac,
                  decoration: BoxDecoration(color: c,
                      borderRadius: BorderRadius.circular(3)),
                ),
              ]),
            )),
          ]),
        );
      }),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TOP JOBS TABLE
// ─────────────────────────────────────────────────────────────────────────────
class _TopJobsTable extends StatelessWidget {
  final List<StockTransaction>  jobs;
  final String Function(String) matName;
  final String Function(String) matUnit;
  final Color Function(String)  matColor;
  const _TopJobsTable({required this.jobs, required this.matName,
    required this.matUnit, required this.matColor});

  @override
  Widget build(BuildContext context) {
    if (jobs.isEmpty) return _noData('No job data in this period');

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Table header
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(children: const [
          SizedBox(width: 12),
          Expanded(flex: 3, child: _TblHeader('MATERIAL')),
          Expanded(flex: 2, child: _TblHeader('DATE')),
          Expanded(flex: 3, child: _TblHeader('PROJECT')),
          Expanded(flex: 2, child: _TblHeader('BARCODE')),
          Expanded(flex: 2, child: _TblHeader('QUANTITY')),
          SizedBox(width: 40),
        ]),
      ),
      const Divider(height: 1, color: _T.slate100),
      const SizedBox(height: 6),
      ...jobs.asMap().entries.map((entry) {
        final i = entry.key;
        final t = entry.value;
        final c = matColor(t.materialId);
        final dt = t.createdAt;
        final dateStr = '${dt.day}/${dt.month}/${dt.year}';

        return Container(
          margin: const EdgeInsets.only(bottom: 5),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color:        i % 2 == 0 ? _T.slate50 : _T.white,
            borderRadius: BorderRadius.circular(_T.r),
            border:       Border.all(color: _T.slate100),
          ),
          child: Row(children: [
            // Rank badge
            Container(
              width: 20, height: 20,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color:        i < 3 ? c.withOpacity(0.15) : _T.slate100,
                shape:        BoxShape.circle,
              ),
              child: Center(child: Text('${i + 1}',
                  style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800,
                      color: i < 3 ? c : _T.slate400))),
            ),
            Expanded(flex: 3, child: Row(children: [
              Container(width: 7, height: 7,
                  margin: const EdgeInsets.only(right: 7),
                  decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
              Expanded(child: Text(matName(t.materialId),
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12,
                      fontWeight: FontWeight.w600, color: _T.ink3))),
            ])),
            Expanded(flex: 2, child: Text(dateStr,
                style: const TextStyle(fontSize: 11.5, color: _T.slate500))),
            Expanded(flex: 3, child: t.projectId != null
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: _T.slate100,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(t.projectId!,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 10.5,
                          fontWeight: FontWeight.w600, color: _T.slate500,
                          fontFamily: 'monospace')),
                )
              : const Text('—', style: TextStyle(fontSize: 11, color: _T.slate300))),
            Expanded(flex: 2, child: t.barcode != null
              ? Text(
                  t.barcode!.length > 12
                      ? '${t.barcode!.substring(0, 12)}…'
                      : t.barcode!,
                  style: const TextStyle(fontSize: 10.5, color: _T.slate400,
                      fontFamily: 'monospace'))
              : const Text('—', style: TextStyle(fontSize: 11, color: _T.slate300))),
            Expanded(flex: 2, child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('${_fmtQty(t.quantity)} ${matUnit(t.materialId)}',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800,
                        color: c)),
              ],
            )),
          ]),
        );
      }),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EMPTY REPORTS
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyReports extends StatelessWidget {
  final _Period period;
  const _EmptyReports({required this.period});
  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 56, height: 56,
        decoration: BoxDecoration(color: _T.slate100,
            borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.bar_chart_rounded, size: 26, color: _T.slate400)),
      const SizedBox(height: 16),
      const Text('No consumption data',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
              color: _T.ink, letterSpacing: -0.3)),
      const SizedBox(height: 6),
      Text('No stock-out events recorded in ${period.label.toLowerCase()}.',
          style: const TextStyle(fontSize: 12.5, color: _T.slate400)),
      const SizedBox(height: 4),
      const Text('Start print jobs to see consumption analytics.',
          style: TextStyle(fontSize: 12.5, color: _T.slate400)),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED MICRO WIDGETS
// ─────────────────────────────────────────────────────────────────────────────
class _TblHeader extends StatelessWidget {
  final String text;
  const _TblHeader(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700,
          letterSpacing: 0.6, color: _T.slate400));
}

Widget _noData(String msg) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 28),
  child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    const Icon(Icons.hourglass_empty_rounded, size: 20, color: _T.slate300),
    const SizedBox(height: 8),
    Text(msg, style: const TextStyle(fontSize: 12, color: _T.slate400)),
  ])),
);

// ─────────────────────────────────────────────────────────────────────────────
// DONUT PAINTER (shared from design system)
// ─────────────────────────────────────────────────────────────────────────────
class _DonutPainter extends CustomPainter {
  final List<double> values;
  final List<Color>  colors;
  final double       strokeWidth;
  const _DonutPainter({required this.values, required this.colors,
    required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final total  = values.fold(0.0, (a, b) => a + b);
    if (total == 0) return;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - strokeWidth / 2;
    final rect   = Rect.fromCircle(center: center, radius: radius);
    double startAngle = -math.pi / 2;
    const gap = 0.035;
    for (int i = 0; i < values.length; i++) {
      if (values[i] == 0) continue;
      final sweep = (values[i] / total) * 2 * math.pi - gap;
      canvas.drawArc(rect, startAngle, math.max(sweep, 0.01), false,
          Paint()
            ..color       = colors[i]
            ..style       = PaintingStyle.stroke
            ..strokeWidth = strokeWidth
            ..strokeCap   = StrokeCap.round);
      startAngle += sweep + gap;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.values != values || old.colors != colors;
}

// ─────────────────────────────────────────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────────────────────────────────────────
String _fmtQty(double v) =>
    v == v.truncateToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);
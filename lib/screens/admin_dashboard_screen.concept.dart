import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smooflow/components/dashboard_actions_fab.dart';
import 'package:smooflow/components/logo.dart';
import 'package:smooflow/helpers/dashboard_actions_fab_helper.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Design tokens  (shared with the rest of the Smooflow design system)
// ─────────────────────────────────────────────────────────────────────────────
class _T {
  static const bg            = Color(0xFFF8FAFC);
  static const surface       = Color(0xFFFFFFFF);
  static const border        = Color(0xFFE2E8F0);
  static const textPrimary   = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF64748B);
  static const textMuted     = Color(0xFF94A3B8);
  static const brandBlue     = Color(0xFF2563EB);
  static const blueBg        = Color(0xFFEFF6FF);
  static const green         = Color(0xFF10B981);
  static const greenBg       = Color(0xFFECFDF5);
  static const amber         = Color(0xFFF59E0B);
  static const amberBg       = Color(0xFFFEF3C7);
  static const red           = Color(0xFFEF4444);
  static const redBg         = Color(0xFFFEE2E2);
  static const purple        = Color(0xFF8B5CF6);
  static const purpleBg      = Color(0xFFF3E8FF);
  static const cyan          = Color(0xFF06B6D4);
  static const cyanBg        = Color(0xFFECFEFF);
}

// ─────────────────────────────────────────────────────────────────────────────
// Lightweight data models (replace with your real models)
// ─────────────────────────────────────────────────────────────────────────────
enum JobStatus { designing, printing, finishing, installing, completed, cancelled }

class AdminPrinter {
  final String id, name, section;
  final String status; // available | busy | maintenance | blocked
  final String? currentJob;
  final double? progress;
  AdminPrinter({required this.id, required this.name, required this.section,
      required this.status, this.currentJob, this.progress});
}

class AdminTask {
  final int id;
  final String name, projectId;
  final JobStatus status;
  final DateTime? dueDate;
  final List<String> assignees;
  AdminTask({required this.id, required this.name, required this.projectId,
      required this.status, this.dueDate, this.assignees = const []});
}

class AdminProject {
  final String id, name;
  final String? description;
  final DateTime? dueDate;
  final List<String> memberIds;
  final List<AdminTask> tasks;
  AdminProject({required this.id, required this.name, this.description,
      this.dueDate, this.memberIds = const [], this.tasks = const []});

  int get total      => tasks.length;
  int get completed  => tasks.where((t) => t.status == JobStatus.completed).length;
  double get percent => total == 0 ? 0 : completed / total;
}

class TeamMember {
  final String id, name;
  final int activeTasks;
  TeamMember({required this.id, required this.name, required this.activeTasks});
  String get load => activeTasks <= 2 ? 'Light' : activeTasks <= 5 ? 'Moderate' : 'Heavy';
  Color get loadColor => activeTasks <= 2 ? _T.green : activeTasks <= 5 ? _T.amber : _T.red;
  Color get loadBg    => activeTasks <= 2 ? _T.greenBg : activeTasks <= 5 ? _T.amberBg : _T.redBg;
}

class StockAlert {
  final String material;
  final double current, minimum;
  StockAlert({required this.material, required this.current, required this.minimum});
}

class ActivityEvent {
  final String action, author;
  final DateTime at;
  final String type; // status | assign | create | print | stock
  ActivityEvent({required this.action, required this.author, required this.at, required this.type});
}

class ScheduledJob {
  final String taskName, printerName;
  final DateTime startTime;
  final int durationMin;
  final String status;
  ScheduledJob({required this.taskName, required this.printerName,
      required this.startTime, required this.durationMin, required this.status});
}

// ─────────────────────────────────────────────────────────────────────────────
// Admin Dashboard Screen
// ─────────────────────────────────────────────────────────────────────────────
class AdminDashboardScreen extends StatefulWidget {
  final List<AdminPrinter>   printers;
  final List<AdminTask>      tasks;
  final List<AdminProject>   projects;
  final List<TeamMember>     team;
  final List<StockAlert>     stockAlerts;
  final List<ActivityEvent>  recentActivity;
  final List<ScheduledJob>   todaysSchedule;
  final int notificationCount;

  // Navigation callbacks
  final VoidCallback? onNewTask;
  final VoidCallback? onNewProject;
  final VoidCallback? onSchedulePrint;
  final VoidCallback? onAddPrinter;
  final Function(AdminProject)? onProjectTap;
  final VoidCallback? onViewAllPrinters;
  final VoidCallback? onViewAllTasks;
  final VoidCallback? onViewInventory;
  final VoidCallback? onViewSchedule;

  const AdminDashboardScreen({
    Key? key,
    this.printers      = const [],
    this.tasks         = const [],
    this.projects      = const [],
    this.team          = const [],
    this.stockAlerts   = const [],
    this.recentActivity = const [],
    this.todaysSchedule = const [],
    this.notificationCount = 0,
    this.onNewTask,
    this.onNewProject,
    this.onSchedulePrint,
    this.onAddPrinter,
    this.onProjectTap,
    this.onViewAllPrinters,
    this.onViewAllTasks,
    this.onViewInventory,
    this.onViewSchedule,
  }) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with TickerProviderStateMixin {

  // Search
  final _searchCtrl    = TextEditingController();
  final _searchFocus   = FocusNode();
  bool  _searchActive  = false;
  String _query        = '';

  // New-project sheet
  final _projNameCtrl = TextEditingController();
  final _projDescCtrl = TextEditingController();
  DateTime? _projDue;

  final DashboardActionsFabHelper fabHelper = DashboardActionsFabHelper(fabOpen: false);

  @override
  void initState() {
    super.initState();
    _searchFocus.addListener(() {
      setState(() => _searchActive = _searchFocus.hasFocus);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    _projNameCtrl.dispose();
    _projDescCtrl.dispose();
    super.dispose();
  }

  // ── Search data ────────────────────────────────────────────────────────────
  List<_SearchResult> get _searchResults {
    if (_query.trim().isEmpty) return [];
    final q = _query.toLowerCase();
    final out = <_SearchResult>[];

    for (final t in widget.tasks) {
      if (t.name.toLowerCase().contains(q) ||
          t.projectId.toLowerCase().contains(q)) {
        out.add(_SearchResult(
          category: 'Tasks',
          title: t.name,
          subtitle: t.projectId,
          icon: Icons.assignment_rounded,
          iconColor: _statusColor(t.status),
          badgeLabel: _statusLabel(t.status),
          badgeColor: _statusColor(t.status),
          badgeBg: _statusBg(t.status),
        ));
      }
    }
    for (final p in widget.projects) {
      if (p.name.toLowerCase().contains(q) ||
          (p.description ?? '').toLowerCase().contains(q)) {
        out.add(_SearchResult(
          category: 'Projects',
          title: p.name,
          subtitle: '${p.total} tasks · ${(p.percent * 100).toInt()}% complete',
          icon: Icons.folder_rounded,
          iconColor: _T.brandBlue,
          badgeLabel: null,
          badgeColor: null,
          badgeBg: null,
        ));
      }
    }
    for (final pr in widget.printers) {
      if (pr.name.toLowerCase().contains(q) ||
          pr.section.toLowerCase().contains(q)) {
        out.add(_SearchResult(
          category: 'Printers',
          title: pr.name,
          subtitle: pr.section,
          icon: Icons.print_rounded,
          iconColor: _printerStatusColor(pr.status),
          badgeLabel: pr.status,
          badgeColor: _printerStatusColor(pr.status),
          badgeBg: _printerStatusBg(pr.status),
        ));
      }
    }
    for (final m in widget.team) {
      if (m.name.toLowerCase().contains(q)) {
        out.add(_SearchResult(
          category: 'People',
          title: m.name,
          subtitle: '${m.activeTasks} active tasks',
          icon: Icons.person_rounded,
          iconColor: _T.purple,
          badgeLabel: null,
          badgeColor: null,
          badgeBg: null,
        ));
      }
    }
    return out;
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  Color _statusColor(JobStatus s) {
    switch (s) {
      case JobStatus.designing:  return _T.amber;
      case JobStatus.printing:   return _T.brandBlue;
      case JobStatus.finishing:  return _T.purple;
      case JobStatus.installing: return _T.cyan;
      case JobStatus.completed:  return _T.green;
      case JobStatus.cancelled:  return _T.red;
    }
  }
  Color _statusBg(JobStatus s) {
    switch (s) {
      case JobStatus.designing:  return _T.amberBg;
      case JobStatus.printing:   return _T.blueBg;
      case JobStatus.finishing:  return _T.purpleBg;
      case JobStatus.installing: return _T.cyanBg;
      case JobStatus.completed:  return _T.greenBg;
      case JobStatus.cancelled:  return _T.redBg;
    }
  }
  String _statusLabel(JobStatus s) => s.name[0].toUpperCase() + s.name.substring(1);

  Color _printerStatusColor(String s) {
    switch (s.toLowerCase()) {
      case 'available':   return _T.green;
      case 'busy':        return _T.brandBlue;
      case 'maintenance': return _T.amber;
      default:            return _T.red;
    }
  }
  Color _printerStatusBg(String s) {
    switch (s.toLowerCase()) {
      case 'available':   return _T.greenBg;
      case 'busy':        return _T.blueBg;
      case 'maintenance': return _T.amberBg;
      default:            return _T.redBg;
    }
  }

  int get _activeJobs      => widget.tasks.where((t) =>
      t.status != JobStatus.completed && t.status != JobStatus.cancelled).length;
  int get _printersOnline  => widget.printers
      .where((p) => p.status.toLowerCase() == 'available' || p.status.toLowerCase() == 'busy').length;
  int get _dueToday        {
    final today = DateTime.now();
    return widget.tasks.where((t) =>
        t.dueDate != null &&
        t.dueDate!.year == today.year &&
        t.dueDate!.month == today.month &&
        t.dueDate!.day == today.day).length;
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        if (fabHelper.fabOpen) { setState(() => fabHelper.fabOpen = false); fabHelper.fabCtrl.reverse(); }
      },
      child: Scaffold(
        backgroundColor: _T.bg,
        body: SafeArea(
          child: Stack(
            children: [
              // ── Main scroll ──────────────────────────────────────────────
              CustomScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                slivers: [
                  SliverToBoxAdapter(child: _buildHeader()),
                  SliverToBoxAdapter(
                    child: AnimatedSwitcher(
                      duration: Duration(milliseconds: 220),
                      child: _searchActive || _query.isNotEmpty
                          ? _buildSearchResults()
                          : _buildDashboardContent(),
                    ),
                  ),
                  SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),

              // ── FAB overlay ──────────────────────────────────────────────
              DashboardActionsFab(fabHelper: fabHelper)
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // HEADER + SEARCH
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildHeader() {
    return Container(
      color: _T.surface,
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row
          Row(
            children: [
              // Container(
              //   padding: EdgeInsets.all(10),
              //   decoration: BoxDecoration(
              //     color: _T.brandBlue,
              //     borderRadius: BorderRadius.circular(12),
              //   ),
              //   child: Icon(Icons.admin_panel_settings_rounded,
              //       color: Colors.white, size: 24),
              // ),
              Logo(),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Admin Dashboard',
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w700,
                            color: _T.textPrimary, letterSpacing: -0.5)),
                    Text(DateFormat('EEEE, MMMM d').format(DateTime.now()),
                        style: TextStyle(fontSize: 13, color: _T.textSecondary)),
                  ],
                ),
              ),
              // Notifications
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.notifications_outlined,
                        color: Color(0xFF475569), size: 22),
                  ),
                  if (widget.notificationCount > 0)
                    Positioned(
                      top: -4, right: -4,
                      child: Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: _T.red, shape: BoxShape.circle),
                        child: Text(
                          widget.notificationCount > 9
                              ? '9+' : '${widget.notificationCount}',
                          style: TextStyle(fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(width: 10),
              // Admin avatar
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: _T.brandBlue.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text('AD',
                      style: TextStyle(fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: _T.brandBlue)),
                ),
              ),
            ],
          ),
          SizedBox(height: 18),

          // ── Search bar ────────────────────────────────────────────────────
          AnimatedContainer(
            duration: Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: _T.bg,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: _searchActive ? _T.brandBlue : _T.border,
                width: _searchActive ? 2 : 1,
              ),
              boxShadow: _searchActive ? [
                BoxShadow(color: _T.brandBlue.withOpacity(0.12),
                    blurRadius: 12, offset: Offset(0, 4))
              ] : [],
            ),
            child: Row(
              children: [
                Padding(
                  padding: EdgeInsets.only(left: 14),
                  child: AnimatedSwitcher(
                    duration: Duration(milliseconds: 180),
                    child: _searchActive
                        ? Icon(Icons.search_rounded,
                            color: _T.brandBlue, size: 22, key: ValueKey('a'))
                        : Icon(Icons.search_rounded,
                            color: _T.textMuted, size: 22, key: ValueKey('b')),
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    focusNode: _searchFocus,
                    onChanged: (v) => setState(() => _query = v),
                    style: TextStyle(
                        fontSize: 15, color: _T.textPrimary,
                        fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      hintText: 'Search tasks, projects, printers, people…',
                      hintStyle: TextStyle(
                          fontSize: 15, color: _T.textMuted,
                          fontWeight: FontWeight.w400),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 12, vertical: 15),
                    ),
                  ),
                ),
                AnimatedSwitcher(
                  duration: Duration(milliseconds: 180),
                  child: _query.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            _searchCtrl.clear();
                            setState(() => _query = '');
                            _searchFocus.unfocus();
                          },
                          child: Padding(
                            padding: EdgeInsets.only(right: 12),
                            child: Icon(Icons.close_rounded,
                                color: _T.textSecondary, size: 20),
                          ),
                        )
                      : SizedBox(width: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SEARCH RESULTS
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildSearchResults() {
    final results = _searchResults;

    if (_query.trim().isEmpty) {
      return _buildRecentSearchesHint();
    }

    if (results.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            Icon(Icons.search_off_rounded, size: 48, color: _T.textMuted),
            SizedBox(height: 16),
            Text('No results for "$_query"',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
                    color: _T.textPrimary)),
            SizedBox(height: 6),
            Text('Try a different keyword',
                style: TextStyle(fontSize: 13, color: _T.textSecondary)),
          ],
        ),
      );
    }

    // Group by category
    final grouped = <String, List<_SearchResult>>{};
    for (final r in results) {
      grouped.putIfAbsent(r.category, () => []).add(r);
    }

    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${results.length} result${results.length == 1 ? '' : 's'} for "$_query"',
              style: TextStyle(fontSize: 13, color: _T.textSecondary,
                  fontWeight: FontWeight.w500)),
          SizedBox(height: 16),
          ...grouped.entries.map((entry) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category header
              Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: Row(children: [
                  Text(entry.key,
                      style: TextStyle(fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _T.textMuted,
                          letterSpacing: 0.6)),
                  SizedBox(width: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text('${entry.value.length}',
                        style: TextStyle(fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _T.textSecondary)),
                  ),
                ]),
              ),
              _card(
                child: Column(
                  children: entry.value.asMap().entries.map((e) {
                    final r = e.value;
                    final isLast = e.key == entry.value.length - 1;
                    return _searchResultRow(r, isLast: isLast);
                  }).toList(),
                ),
              ),
              SizedBox(height: 20),
            ],
          )).toList(),
        ],
      ),
    );
  }

  Widget _searchResultRow(_SearchResult r, {bool isLast = false}) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: r.iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(r.icon, size: 18, color: r.iconColor),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _highlightedText(r.title, _query),
                    SizedBox(height: 3),
                    Text(r.subtitle,
                        style: TextStyle(fontSize: 12, color: _T.textSecondary)),
                  ],
                ),
              ),
              if (r.badgeLabel != null)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: r.badgeBg, borderRadius: BorderRadius.circular(6)),
                  child: Text(r.badgeLabel!,
                      style: TextStyle(fontSize: 11,
                          fontWeight: FontWeight.w700, color: r.badgeColor)),
                ),
              SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded,
                  size: 18, color: _T.textMuted),
            ],
          ),
        ),
        if (!isLast) Divider(height: 1, thickness: 1, color: _T.border),
      ],
    );
  }

  /// Renders the title with the matching substring in blue/bold
  Widget _highlightedText(String text, String query) {
    if (query.isEmpty) return Text(text,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
            color: _T.textPrimary));
    final lower = text.toLowerCase();
    final qLower = query.toLowerCase();
    final idx = lower.indexOf(qLower);
    if (idx < 0) return Text(text,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
            color: _T.textPrimary));
    return RichText(
      text: TextSpan(
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
            color: _T.textPrimary),
        children: [
          if (idx > 0) TextSpan(text: text.substring(0, idx)),
          TextSpan(
            text: text.substring(idx, idx + query.length),
            style: TextStyle(color: _T.brandBlue,
                backgroundColor: _T.brandBlue.withOpacity(0.1)),
          ),
          if (idx + query.length < text.length)
            TextSpan(text: text.substring(idx + query.length)),
        ],
      ),
    );
  }

  Widget _buildRecentSearchesHint() {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SEARCH ACROSS',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                  color: _T.textMuted, letterSpacing: 0.8)),
          SizedBox(height: 12),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: [
              _searchHintChip(Icons.assignment_rounded, 'Tasks', _T.brandBlue),
              _searchHintChip(Icons.folder_rounded, 'Projects', _T.purple),
              _searchHintChip(Icons.print_rounded, 'Printers', _T.green),
              _searchHintChip(Icons.people_rounded, 'People', _T.amber),
            ],
          ),
        ],
      ),
    );
  }

  Widget _searchHintChip(IconData icon, String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _T.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _T.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 13,
              fontWeight: FontWeight.w500, color: _T.textSecondary)),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // MAIN DASHBOARD CONTENT
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildDashboardContent() {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildKpiStrip(),
          SizedBox(height: 28),
          _buildProductionHealth(),
          SizedBox(height: 28),
          _buildProjectsSection(),
          SizedBox(height: 28),
          _buildPrinterFleet(),
          SizedBox(height: 28),
          _buildTodaysSchedule(),
          SizedBox(height: 28),
          _buildTeamWorkload(),
          if (widget.stockAlerts.isNotEmpty) ...[
            SizedBox(height: 28),
            _buildStockAlerts(),
          ],
          SizedBox(height: 28),
          _buildActivityFeed(),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 1 · KPI STRIP
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildKpiStrip() {
    final kpis = [
      _KpiData('Active Jobs',     '$_activeJobs',
          Icons.work_outline_rounded,     _T.brandBlue, _T.blueBg,   '+3 vs last wk', true),
      _KpiData('Printers Online', '$_printersOnline/${widget.printers.length}',
          Icons.print_rounded,            _T.green,     _T.greenBg,  'All operational', null),
      _KpiData('Due Today',       '$_dueToday',
          Icons.today_rounded,            _T.amber,     _T.amberBg,  '2 overdue', false),
      _KpiData('Stock Alerts',    '${widget.stockAlerts.length}',
          Icons.inventory_2_outlined,     _T.red,       _T.redBg,    'Needs attention', false),
      _KpiData('On Shift',        '${widget.team.length}',
          Icons.people_alt_rounded,       _T.purple,    _T.purpleBg, 'Active now', null),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Overview'),
        SizedBox(height: 12),
        SizedBox(
          height: 150,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: kpis.length,
            separatorBuilder: (_, __) => SizedBox(width: 12),
            itemBuilder: (_, i) => _kpiCard(kpis[i]),
          ),
        ),
      ],
    );
  }

  Widget _kpiCard(_KpiData d) {
    return Container(
      width: 150,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _T.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _T.border),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02),
            blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: d.iconBg, borderRadius: BorderRadius.circular(9)),
            child: Icon(d.icon, size: 18, color: d.iconColor),
          ),
          Spacer(),
          Text(d.value,
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800,
                  color: _T.textPrimary, letterSpacing: -0.8, height: 1)),
          SizedBox(height: 4),
          Text(d.label,
              style: TextStyle(fontSize: 11, color: _T.textSecondary,
                  fontWeight: FontWeight.w500)),
          SizedBox(height: 6),
          Row(
            children: [
              if (d.trendUp != null)
                Icon(
                  d.trendUp! ? Icons.trending_up : Icons.trending_down,
                  size: 12,
                  color: d.trendUp! ? _T.green : _T.red,
                ),
              if (d.trendUp != null) SizedBox(width: 3),
              Flexible(
                child: Text(d.trend,
                    style: TextStyle(
                        fontSize: 10,
                        color: d.trendUp == null
                            ? _T.textMuted
                            : d.trendUp!
                                ? _T.green
                                : _T.red,
                        fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 2 · PRODUCTION HEALTH BAR
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildProductionHealth() {
    final counts = <JobStatus, int>{};
    for (final s in JobStatus.values) {
      counts[s] = widget.tasks.where((t) => t.status == s).length;
    }
    final total = widget.tasks.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _sectionHeader('Production Health'),
            Spacer(),
            GestureDetector(
              onTap: widget.onViewAllTasks,
              child: Row(children: [
                Text('View Tasks',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                        color: _T.brandBlue)),
                SizedBox(width: 3),
                Icon(Icons.arrow_forward_ios_rounded,
                    size: 12, color: _T.brandBlue),
              ]),
            ),
          ],
        ),
        SizedBox(height: 12),
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('$total total tasks',
                      style: TextStyle(fontSize: 13, color: _T.textSecondary,
                          fontWeight: FontWeight.w500)),
                  Text('${counts[JobStatus.completed] ?? 0} completed',
                      style: TextStyle(fontSize: 13,
                          fontWeight: FontWeight.w600, color: _T.green)),
                ],
              ),
              SizedBox(height: 12),
              // Segmented bar
              if (total > 0)
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Row(
                    children: JobStatus.values.map((s) {
                      final count = counts[s] ?? 0;
                      if (count == 0) return SizedBox.shrink();
                      return Flexible(
                        flex: count,
                        child: Container(
                          height: 10,
                          color: _statusColor(s),
                        ),
                      );
                    }).toList(),
                  ),
                )
              else
                Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: _T.border,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              SizedBox(height: 14),
              // Legend
              Wrap(
                spacing: 14,
                runSpacing: 8,
                children: JobStatus.values.map((s) {
                  final count = counts[s] ?? 0;
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8, height: 8,
                        decoration: BoxDecoration(
                          color: _statusColor(s), shape: BoxShape.circle),
                      ),
                      SizedBox(width: 5),
                      Text('${_statusLabel(s)} ($count)',
                          style: TextStyle(fontSize: 12, color: _T.textSecondary,
                              fontWeight: FontWeight.w500)),
                    ],
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 3 · PROJECTS
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildProjectsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _sectionHeader('Projects'),
            Spacer(),
            // New project button
            GestureDetector(
              onTap: _showNewProjectSheet,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: _T.brandBlue,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Row(
                  children: [
                    Icon(Icons.add_rounded, size: 16, color: Colors.white),
                    SizedBox(width: 5),
                    Text('New Project',
                        style: TextStyle(fontSize: 13,
                            fontWeight: FontWeight.w600, color: Colors.white)),
                  ],
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        widget.projects.isEmpty
            ? _card(
                child: _emptyInline(
                  Icons.folder_off_rounded,
                  'No projects yet',
                  subtitle: 'Tap "New Project" to create your first one.',
                ),
              )
            : Column(
                children: widget.projects
                    .map((p) => Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: _projectCard(p),
                        ))
                    .toList(),
              ),
      ],
    );
  }

  Widget _projectCard(AdminProject p) {
    final pct = p.percent;
    return GestureDetector(
      onTap: () => widget.onProjectTap?.call(p),
      child: Container(
        padding: EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _T.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _T.border),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02),
              blurRadius: 8, offset: Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _T.blueBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.folder_rounded,
                      size: 20, color: _T.brandBlue),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.name,
                          style: TextStyle(fontSize: 15,
                              fontWeight: FontWeight.w700, color: _T.textPrimary,
                              letterSpacing: -0.2)),
                      if (p.description != null && p.description!.isNotEmpty) ...[
                        SizedBox(height: 3),
                        Text(p.description!,
                            style: TextStyle(fontSize: 13, color: _T.textSecondary),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ],
                  ),
                ),
                SizedBox(width: 8),
                // Percent bubble
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: pct >= 1.0 ? _T.greenBg : _T.blueBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('${(pct * 100).toInt()}%',
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700,
                          color: pct >= 1.0 ? _T.green : _T.brandBlue)),
                ),
              ],
            ),
            SizedBox(height: 14),
            // Mini segmented bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Row(
                children: p.tasks.isEmpty
                    ? [Expanded(
                        child: Container(height: 6, color: _T.border))]
                    : JobStatus.values.map((s) {
                        final count = p.tasks.where((t) => t.status == s).length;
                        if (count == 0) return SizedBox.shrink();
                        return Flexible(
                          flex: count,
                          child: Container(height: 6, color: _statusColor(s)),
                        );
                      }).toList(),
              ),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                // Task count
                Icon(Icons.assignment_outlined, size: 14, color: _T.textMuted),
                SizedBox(width: 5),
                Text('${p.total} task${p.total == 1 ? '' : 's'}',
                    style: TextStyle(fontSize: 12, color: _T.textSecondary,
                        fontWeight: FontWeight.w500)),
                SizedBox(width: 14),
                // Members
                Icon(Icons.people_outline, size: 14, color: _T.textMuted),
                SizedBox(width: 5),
                Text('${p.memberIds.length} member${p.memberIds.length == 1 ? '' : 's'}',
                    style: TextStyle(fontSize: 12, color: _T.textSecondary,
                        fontWeight: FontWeight.w500)),
                Spacer(),
                if (p.dueDate != null) ...[
                  Icon(Icons.event_rounded, size: 14, color: _T.textMuted),
                  SizedBox(width: 5),
                  Text(DateFormat('MMM dd').format(p.dueDate!),
                      style: TextStyle(fontSize: 12, color: _T.textSecondary,
                          fontWeight: FontWeight.w500)),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // New-project bottom sheet
  void _showNewProjectSheet() {
    _projNameCtrl.clear();
    _projDescCtrl.clear();
    _projDue = null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) => Container(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom),
          decoration: BoxDecoration(
            color: _T.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 8, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40, height: 4,
                    margin: EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: _T.border,
                      borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: _T.blueBg,
                        borderRadius: BorderRadius.circular(10)),
                      child: Icon(Icons.folder_rounded,
                          size: 20, color: _T.brandBlue),
                    ),
                    SizedBox(width: 12),
                    Text('New Project',
                        style: TextStyle(fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: _T.textPrimary, letterSpacing: -0.3)),
                  ],
                ),
                SizedBox(height: 20),
                _sheetField('Project Name', _projNameCtrl,
                    hint: 'e.g. Spring Campaign 2026', required: true),
                SizedBox(height: 14),
                _sheetField('Description', _projDescCtrl,
                    hint: 'Brief overview of the project',
                    maxLines: 3),
                SizedBox(height: 14),
                // Due date
                GestureDetector(
                  onTap: () async {
                    final d = await showDatePicker(
                      context: ctx,
                      initialDate: DateTime.now().add(Duration(days: 7)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(Duration(days: 730)),
                      builder: (ctx, child) => Theme(
                        data: Theme.of(ctx).copyWith(
                          colorScheme: ColorScheme.light(
                              primary: _T.brandBlue)),
                        child: child!,
                      ),
                    );
                    if (d != null) setSheet(() => _projDue = d);
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      color: _T.bg,
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(color: _T.border),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.event_rounded,
                            size: 18, color: _T.textSecondary),
                        SizedBox(width: 10),
                        Text(
                          _projDue != null
                              ? DateFormat('MMM dd, yyyy').format(_projDue!)
                              : 'Set due date (optional)',
                          style: TextStyle(
                              fontSize: 15,
                              color: _projDue != null
                                  ? _T.textPrimary
                                  : _T.textMuted),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (_projNameCtrl.text.trim().isEmpty) return;
                      Navigator.pop(ctx);
                      widget.onNewProject?.call();
                    },
                    icon: Icon(Icons.add_rounded, size: 20),
                    label: Text('Create Project',
                        style: TextStyle(fontSize: 15,
                            fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _T.brandBlue,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
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

  Widget _sheetField(String label, TextEditingController ctrl,
      {String hint = '', bool required = false, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text(label,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                  color: _T.textPrimary)),
          if (required) ...[
            SizedBox(width: 3),
            Text('*', style: TextStyle(color: _T.red, fontSize: 13)),
          ],
        ]),
        SizedBox(height: 7),
        TextField(
          controller: ctrl,
          maxLines: maxLines,
          style: TextStyle(fontSize: 15, color: _T.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: _T.textMuted),
            filled: true,
            fillColor: _T.bg,
            contentPadding: EdgeInsets.symmetric(
                horizontal: 14, vertical: 13),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: BorderSide(color: _T.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: BorderSide(color: _T.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: BorderSide(color: _T.brandBlue, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 4 · PRINTER FLEET
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildPrinterFleet() {
    final busy      = widget.printers.where((p) => p.status.toLowerCase() == 'busy').length;
    final available = widget.printers.where((p) => p.status.toLowerCase() == 'available').length;
    final maint     = widget.printers.where((p) => p.status.toLowerCase() == 'maintenance').length;
    final blocked   = widget.printers.where((p) => p.status.toLowerCase() == 'blocked').length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _sectionHeader('Printer Fleet'),
            Spacer(),
            GestureDetector(
              onTap: widget.onViewAllPrinters,
              child: Row(children: [
                Text('View All',
                    style: TextStyle(fontSize: 13,
                        fontWeight: FontWeight.w600, color: _T.brandBlue)),
                SizedBox(width: 3),
                Icon(Icons.arrow_forward_ios_rounded,
                    size: 12, color: _T.brandBlue),
              ]),
            ),
          ],
        ),
        SizedBox(height: 12),
        // Fleet summary strip
        _card(
          child: Column(
            children: [
              Row(
                children: [
                  _fleetStat('Available', available, _T.green, _T.greenBg),
                  _fleetDivider(),
                  _fleetStat('Busy', busy, _T.brandBlue, _T.blueBg),
                  _fleetDivider(),
                  _fleetStat('Maint.', maint, _T.amber, _T.amberBg),
                  _fleetDivider(),
                  _fleetStat('Blocked', blocked, _T.red, _T.redBg),
                ],
              ),
              if (widget.printers.isNotEmpty) ...[
                SizedBox(height: 16),
                Divider(height: 1, thickness: 1, color: _T.border),
                SizedBox(height: 14),
                // Compact printer rows (max 4)
                ...widget.printers.take(4).map((p) => _compactPrinterRow(p)).toList(),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _fleetStat(String label, int count, Color color, Color bg) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: Center(
              child: Text('$count',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800,
                      color: color)),
            ),
          ),
          SizedBox(height: 6),
          Text(label,
              style: TextStyle(fontSize: 11, color: _T.textSecondary,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _fleetDivider() => Container(
      width: 1, height: 44, color: _T.border,
      margin: EdgeInsets.symmetric(horizontal: 4));

  Widget _compactPrinterRow(AdminPrinter p) {
    final color = _printerStatusColor(p.status);
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 8, height: 8,
            margin: EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              shape: BoxShape.circle, color: color),
          ),
          Expanded(
            child: Text(p.name,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                    color: _T.textPrimary)),
          ),
          if (p.progress != null) ...[
            SizedBox(
              width: 80,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: p.progress!,
                  minHeight: 5,
                  backgroundColor: _T.border,
                  valueColor: AlwaysStoppedAnimation(_T.brandBlue),
                ),
              ),
            ),
            SizedBox(width: 8),
            Text('${(p.progress! * 100).toInt()}%',
                style: TextStyle(fontSize: 12,
                    fontWeight: FontWeight.w600, color: _T.brandBlue)),
          ] else
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _printerStatusBg(p.status),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(p.status,
                  style: TextStyle(fontSize: 11,
                      fontWeight: FontWeight.w600, color: color)),
            ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 5 · TODAY'S SCHEDULE
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildTodaysSchedule() {
    final now = DateTime.now();
    final morning   = widget.todaysSchedule.where(
        (j) => j.startTime.hour < 12).toList();
    final afternoon = widget.todaysSchedule.where(
        (j) => j.startTime.hour >= 12 && j.startTime.hour < 17).toList();
    final evening   = widget.todaysSchedule.where(
        (j) => j.startTime.hour >= 17).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _sectionHeader('Today\'s Schedule'),
            Spacer(),
            GestureDetector(
              onTap: widget.onViewSchedule,
              child: Row(children: [
                Text('Full Schedule',
                    style: TextStyle(fontSize: 13,
                        fontWeight: FontWeight.w600, color: _T.brandBlue)),
                SizedBox(width: 3),
                Icon(Icons.arrow_forward_ios_rounded,
                    size: 12, color: _T.brandBlue),
              ]),
            ),
          ],
        ),
        SizedBox(height: 12),
        widget.todaysSchedule.isEmpty
            ? _card(
                child: _emptyInline(
                  Icons.event_available_rounded,
                  'No jobs scheduled today',
                  subtitle: 'Use "Schedule Print" to add jobs',
                ),
              )
            : Column(
                children: [
                  if (morning.isNotEmpty)
                    _scheduleGroup('Morning', '🌅', morning),
                  if (afternoon.isNotEmpty)
                    _scheduleGroup('Afternoon', '☀️', afternoon),
                  if (evening.isNotEmpty)
                    _scheduleGroup('Evening', '🌙', evening),
                ],
              ),
      ],
    );
  }

  Widget _scheduleGroup(
      String label, String emoji, List<ScheduledJob> jobs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Text(emoji, style: TextStyle(fontSize: 13)),
              SizedBox(width: 6),
              Text(label.toUpperCase(),
                  style: TextStyle(fontSize: 11,
                      fontWeight: FontWeight.w700, color: _T.textMuted,
                      letterSpacing: 0.6)),
            ],
          ),
        ),
        _card(
          child: Column(
            children: jobs.asMap().entries.map((e) {
              final isLast = e.key == jobs.length - 1;
              return _scheduleJobRow(e.value, isLast: isLast);
            }).toList(),
          ),
        ),
        SizedBox(height: 12),
      ],
    );
  }

  Widget _scheduleJobRow(ScheduledJob job, {bool isLast = false}) {
    Color statusColor;
    Color statusBg;
    switch (job.status.toLowerCase()) {
      case 'in_progress':
        statusColor = _T.brandBlue; statusBg = _T.blueBg; break;
      case 'completed':
        statusColor = _T.green; statusBg = _T.greenBg; break;
      case 'delayed':
        statusColor = _T.red; statusBg = _T.redBg; break;
      default:
        statusColor = _T.textSecondary; statusBg = Color(0xFFF1F5F9);
    }

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 11),
          child: Row(
            children: [
              Text(DateFormat('HH:mm').format(job.startTime),
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                      color: _T.textPrimary, letterSpacing: -0.2)),
              SizedBox(width: 12),
              Container(width: 1, height: 30, color: _T.border),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(job.taskName,
                        style: TextStyle(fontSize: 14,
                            fontWeight: FontWeight.w600, color: _T.textPrimary),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(Icons.print_rounded,
                            size: 12, color: _T.textMuted),
                        SizedBox(width: 4),
                        Text(job.printerName,
                            style: TextStyle(fontSize: 12,
                                color: _T.textSecondary)),
                        SizedBox(width: 8),
                        Icon(Icons.timer_outlined,
                            size: 12, color: _T.textMuted),
                        SizedBox(width: 4),
                        Text('${job.durationMin}m',
                            style: TextStyle(fontSize: 12,
                                color: _T.textSecondary)),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  job.status.replaceAll('_', ' ').toUpperCase(),
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                      color: statusColor, letterSpacing: 0.3),
                ),
              ),
            ],
          ),
        ),
        if (!isLast) Divider(height: 1, thickness: 1, color: _T.border),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 6 · TEAM WORKLOAD
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildTeamWorkload() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Team Workload'),
        SizedBox(height: 12),
        widget.team.isEmpty
            ? _card(child: _emptyInline(Icons.people_outline,
                'No team members added'))
            : _card(
                child: Column(
                  children: widget.team.asMap().entries.map((e) {
                    final isLast = e.key == widget.team.length - 1;
                    return _teamMemberRow(e.value, isLast: isLast);
                  }).toList(),
                ),
              ),
      ],
    );
  }

  Widget _teamMemberRow(TeamMember m, {bool isLast = false}) {
    final initials = m.name.split(' ').take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '').join();
    final avatarColors = [
      _T.brandBlue, _T.green, _T.purple, _T.amber, _T.cyan];
    final ac = avatarColors[m.name.codeUnitAt(0) % avatarColors.length];

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: ac.withOpacity(0.14), shape: BoxShape.circle),
                child: Center(
                  child: Text(initials,
                      style: TextStyle(fontSize: 13,
                          fontWeight: FontWeight.w700, color: ac)),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(m.name,
                        style: TextStyle(fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _T.textPrimary)),
                    SizedBox(height: 2),
                    Text('${m.activeTasks} active task${m.activeTasks == 1 ? '' : 's'}',
                        style: TextStyle(fontSize: 12,
                            color: _T.textSecondary)),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: m.loadBg,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(m.load,
                    style: TextStyle(fontSize: 12,
                        fontWeight: FontWeight.w700, color: m.loadColor)),
              ),
            ],
          ),
        ),
        if (!isLast) Divider(height: 1, thickness: 1, color: _T.border),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 7 · STOCK ALERTS
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildStockAlerts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _sectionHeader('Stock Alerts'),
            SizedBox(width: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: _T.redBg, borderRadius: BorderRadius.circular(5)),
              child: Text('${widget.stockAlerts.length}',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                      color: _T.red)),
            ),
            Spacer(),
            GestureDetector(
              onTap: widget.onViewInventory,
              child: Row(children: [
                Text('Inventory',
                    style: TextStyle(fontSize: 13,
                        fontWeight: FontWeight.w600, color: _T.brandBlue)),
                SizedBox(width: 3),
                Icon(Icons.arrow_forward_ios_rounded,
                    size: 12, color: _T.brandBlue),
              ]),
            ),
          ],
        ),
        SizedBox(height: 12),
        _card(
          child: Column(
            children: widget.stockAlerts.asMap().entries.map((e) {
              final isLast = e.key == widget.stockAlerts.length - 1;
              return _stockAlertRow(e.value, isLast: isLast);
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _stockAlertRow(StockAlert a, {bool isLast = false}) {
    final pct = (a.current / a.minimum).clamp(0.0, 1.0);
    final isCritical = a.current < a.minimum * 0.5;

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      size: 16,
                      color: isCritical ? _T.red : _T.amber),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(a.material,
                        style: TextStyle(fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _T.textPrimary)),
                  ),
                  Text('${a.current}/${a.minimum} units',
                      style: TextStyle(fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isCritical ? _T.red : _T.amber)),
                ],
              ),
              SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: pct,
                  minHeight: 5,
                  backgroundColor: _T.border,
                  valueColor: AlwaysStoppedAnimation(
                      isCritical ? _T.red : _T.amber),
                ),
              ),
            ],
          ),
        ),
        if (!isLast) Divider(height: 1, thickness: 1, color: _T.border),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 8 · ACTIVITY FEED
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildActivityFeed() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Recent Activity'),
        SizedBox(height: 12),
        widget.recentActivity.isEmpty
            ? _card(child: _emptyInline(Icons.history_rounded,
                'No recent activity'))
            : _card(
                child: Column(
                  children: widget.recentActivity
                      .take(10)
                      .toList()
                      .asMap()
                      .entries
                      .map((e) {
                    final isLast = e.key ==
                        (widget.recentActivity.length > 10
                                ? 9
                                : widget.recentActivity.length - 1);
                    return _activityRow(e.value, isLast: isLast);
                  }).toList(),
                ),
              ),
      ],
    );
  }

  Widget _activityRow(ActivityEvent ev, {bool isLast = false}) {
    IconData icon;
    Color color;
    switch (ev.type) {
      case 'status': icon = Icons.swap_horiz_rounded;  color = _T.brandBlue; break;
      case 'assign': icon = Icons.person_add_outlined;  color = _T.purple;   break;
      case 'create': icon = Icons.add_circle_outline;   color = _T.green;    break;
      case 'print':  icon = Icons.print_rounded;        color = _T.cyan;     break;
      case 'stock':  icon = Icons.inventory_2_outlined; color = _T.amber;    break;
      default:       icon = Icons.edit_outlined;        color = _T.textSecondary;
    }

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 14, color: color),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ev.action,
                        style: TextStyle(fontSize: 13, color: _T.textPrimary,
                            height: 1.4)),
                    SizedBox(height: 3),
                    Text('${ev.author} · ${_timeAgo(ev.at)}',
                        style: TextStyle(fontSize: 12, color: _T.textMuted)),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!isLast) Divider(height: 1, thickness: 1, color: _T.border),
      ],
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1)  return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24)   return '${diff.inHours}h ago';
    return DateFormat('MMM dd').format(dt);
  }

  // ── Shared helpers ─────────────────────────────────────────────────────────
  Widget _sectionHeader(String title) => Text(
        title,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
            color: _T.textPrimary, letterSpacing: -0.3),
      );

  Widget _card({required Widget child}) => Container(
        width: double.infinity,
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _T.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _T.border),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02),
              blurRadius: 8, offset: Offset(0, 2))],
        ),
        child: child,
      );

  Widget _emptyInline(IconData icon, String label, {String? subtitle}) =>
      Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Icon(icon, size: 34, color: _T.textMuted),
            SizedBox(height: 10),
            Text(label,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                    color: _T.textSecondary)),
            if (subtitle != null) ...[
              SizedBox(height: 4),
              Text(subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: _T.textMuted)),
            ],
          ],
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Internal data classes
// ─────────────────────────────────────────────────────────────────────────────
class _KpiData {
  final String label, value, trend;
  final IconData icon;
  final Color iconColor, iconBg;
  final bool? trendUp;
  const _KpiData(this.label, this.value, this.icon,
      this.iconColor, this.iconBg, this.trend, this.trendUp);
}

class _SearchResult {
  final String category, title, subtitle;
  final IconData icon;
  final Color iconColor;
  final String? badgeLabel;
  final Color? badgeColor, badgeBg;
  const _SearchResult({
    required this.category, required this.title, required this.subtitle,
    required this.icon, required this.iconColor,
    this.badgeLabel, this.badgeColor, this.badgeBg,
  });
}
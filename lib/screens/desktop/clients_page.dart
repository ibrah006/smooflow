// ─────────────────────────────────────────────────────────────────────────────
// clients_screen.dart
//
// Clients page for smooflow desktop (design + admin roles).
// Pixel-perfect match to the existing design system:
//   • Same _T token class (ink sidebar, slate50 canvas, blue primary)
//   • Same sidebar shell (220px, dark ink, ADMIN badge)
//   • Same topbar (52px, white, slate-200 border)
//   • Same card anatomy (_AnalyticsCard shell)
//   • Same stagger animations on entry
//   • Same _SidebarNavItem / _SidebarLabel / _AvatarWidget micro-widgets
//
// Wire into your nav by adding a "Clients" item to the sidebar and pushing
// this screen, or embed ClientsView inside your existing dashboard shell
// if you prefer not to push a new route.
//
// Usage (new route):
//   Navigator.push(context, MaterialPageRoute(
//     builder: (_) => const ClientsScreen(),
//   ));
//
// Usage (embed in existing shell — recommended):
//   Add _AdminView.clients to your enum, add a sidebar nav item,
//   then swap ClientsView() in where you render the canvas.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/core/models/project.dart';
import 'package:smooflow/core/services/login_service.dart';
import 'package:smooflow/providers/project_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DESIGN TOKENS — exact copy of _T from admin_desktop_dashboard.dart
// ─────────────────────────────────────────────────────────────────────────────
class _T {
  static const blue       = Color(0xFF2563EB);
  static const blueHover  = Color(0xFF1D4ED8);
  static const blue100    = Color(0xFFDBEAFE);
  static const blue50     = Color(0xFFEFF6FF);
  static const teal       = Color(0xFF38BDF8);
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
  static const sidebarW  = 220.0;
  static const topbarH   = 52.0;
  static const r         = 8.0;
  static const rLg       = 12.0;
  static const rXl       = 16.0;
}

// ─────────────────────────────────────────────────────────────────────────────
// CLIENT MODEL
// Replace with your real Client model / repository when ready.
// ─────────────────────────────────────────────────────────────────────────────
class Client {
  final String  id;
  final String  name;
  final String  contactName;
  final String  email;
  final String  phone;
  final String  industry;
  final Color   color;           // brand colour for avatar
  final int     projectCount;
  final int     activeTaskCount;
  final DateTime joinedDate;
  final ClientStatus status;

  const Client({
    required this.id,
    required this.name,
    required this.contactName,
    required this.email,
    required this.phone,
    required this.industry,
    required this.color,
    required this.projectCount,
    required this.activeTaskCount,
    required this.joinedDate,
    required this.status,
  });

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}

enum ClientStatus { active, inactive, pending }

// ─────────────────────────────────────────────────────────────────────────────
// STUB DATA — remove once you wire a real ClientRepository
// ─────────────────────────────────────────────────────────────────────────────
final _kStubClients = <Client>[
  Client(id: '1', name: 'Harrington & Co',    contactName: 'James Harrington', email: 'james@harrington.co',  phone: '+1 212 555 0101', industry: 'Finance',     color: const Color(0xFF2563EB), projectCount: 6,  activeTaskCount: 14, joinedDate: DateTime(2023, 3, 12),  status: ClientStatus.active),
  Client(id: '2', name: 'Verdant Studios',    contactName: 'Sofia Mendez',     email: 'sofia@verdant.io',     phone: '+1 415 555 0182', industry: 'Media',       color: const Color(0xFF10B981), projectCount: 3,  activeTaskCount: 7,  joinedDate: DateTime(2023, 7, 4),   status: ClientStatus.active),
  Client(id: '3', name: 'NovaTech Solutions', contactName: 'Raj Patel',        email: 'raj@novatech.com',     phone: '+1 650 555 0133', industry: 'Technology',  color: const Color(0xFF8B5CF6), projectCount: 9,  activeTaskCount: 22, joinedDate: DateTime(2022, 11, 20), status: ClientStatus.active),
  Client(id: '4', name: 'Bloom Collective',   contactName: 'Chloe Bernard',    email: 'chloe@bloomco.fr',     phone: '+33 1 555 0144',  industry: 'Retail',      color: const Color(0xFFF59E0B), projectCount: 2,  activeTaskCount: 3,  joinedDate: DateTime(2024, 1, 8),   status: ClientStatus.pending),
  Client(id: '5', name: 'Summit Properties',  contactName: 'Marcus Webb',      email: 'marcus@summit.re',     phone: '+1 303 555 0155', industry: 'Real Estate', color: const Color(0xFFEF4444), projectCount: 4,  activeTaskCount: 0,  joinedDate: DateTime(2022, 5, 15),  status: ClientStatus.inactive),
  Client(id: '6', name: 'Arclight Media',     contactName: 'Priya Nair',       email: 'priya@arclight.media', phone: '+44 20 555 0166', industry: 'Advertising', color: const Color(0xFF38BDF8), projectCount: 5,  activeTaskCount: 11, joinedDate: DateTime(2023, 9, 30),  status: ClientStatus.active),
  Client(id: '7', name: 'Zenith Apparel',     contactName: 'Lucas Kim',        email: 'lucas@zenithapp.com',  phone: '+1 718 555 0177', industry: 'Fashion',     color: const Color(0xFF64748B), projectCount: 1,  activeTaskCount: 5,  joinedDate: DateTime(2024, 2, 14),  status: ClientStatus.active),
];

// ─────────────────────────────────────────────────────────────────────────────
// FILTER / SORT STATE
// ─────────────────────────────────────────────────────────────────────────────
enum _SortField { name, projects, tasks, joined }
enum _FilterStatus { all, active, inactive, pending }
enum _ViewMode { table, grid }

// ─────────────────────────────────────────────────────────────────────────────
// ROOT SCREEN  (standalone — wraps its own Scaffold + sidebar)
// ─────────────────────────────────────────────────────────────────────────────
class ClientsPage extends ConsumerStatefulWidget {
  const ClientsPage({super.key});

  @override
  ConsumerState<ClientsPage> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends ConsumerState<ClientsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _T.slate50,
      body: Focus(
        autofocus: true,
        onKeyEvent: (_, __) => KeyEventResult.ignored,
        child: ClientsView()
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CLIENTS VIEW  — the main canvas, embeddable in any shell
// ─────────────────────────────────────────────────────────────────────────────
class ClientsView extends StatefulWidget {
  const ClientsView({super.key});

  @override
  State<ClientsView> createState() => _ClientsViewState();
}

class _ClientsViewState extends State<ClientsView>
    with SingleTickerProviderStateMixin {
  // ── Animation
  late final AnimationController _ac = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 800));

  // ── State
  _SortField    _sort       = _SortField.name;
  bool          _sortAsc    = true;
  _FilterStatus _filter     = _FilterStatus.all;
  _ViewMode     _viewMode   = _ViewMode.table;
  String        _search     = '';
  Client?       _selected;

  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _ac.forward();
  }

  @override
  void dispose() {
    _ac.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Animation<double> _stagger(double s, double e) => CurvedAnimation(
      parent: _ac, curve: Interval(s, e, curve: Curves.easeOutCubic));

  // ── Derived list
  List<Client> get _filtered {
    var list = _kStubClients.where((c) {
      final matchSearch = _search.isEmpty ||
          c.name.toLowerCase().contains(_search.toLowerCase()) ||
          c.contactName.toLowerCase().contains(_search.toLowerCase()) ||
          c.email.toLowerCase().contains(_search.toLowerCase()) ||
          c.industry.toLowerCase().contains(_search.toLowerCase());
      final matchStatus = _filter == _FilterStatus.all ||
          (_filter == _FilterStatus.active   && c.status == ClientStatus.active)   ||
          (_filter == _FilterStatus.inactive && c.status == ClientStatus.inactive) ||
          (_filter == _FilterStatus.pending  && c.status == ClientStatus.pending);
      return matchSearch && matchStatus;
    }).toList();

    list.sort((a, b) {
      int cmp;
      switch (_sort) {
        case _SortField.name:     cmp = a.name.compareTo(b.name); break;
        case _SortField.projects: cmp = a.projectCount.compareTo(b.projectCount); break;
        case _SortField.tasks:    cmp = a.activeTaskCount.compareTo(b.activeTaskCount); break;
        case _SortField.joined:   cmp = a.joinedDate.compareTo(b.joinedDate); break;
      }
      return _sortAsc ? cmp : -cmp;
    });

    return list;
  }

  // ── KPI counts
  int get _activeCount   => _kStubClients.where((c) => c.status == ClientStatus.active).length;
  int get _inactiveCount => _kStubClients.where((c) => c.status == ClientStatus.inactive).length;
  int get _pendingCount  => _kStubClients.where((c) => c.status == ClientStatus.pending).length;
  int get _totalProjects => _kStubClients.fold(0, (s, c) => s + c.projectCount);
  int get _totalTasks    => _kStubClients.fold(0, (s, c) => s + c.activeTaskCount);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Main content ──────────────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── KPI strip ───────────────────────────────────────────
                FadeTransition(
                  opacity: _stagger(0.0, 0.40),
                  child: SlideTransition(
                    position: Tween<Offset>(
                            begin: const Offset(0, 0.04), end: Offset.zero)
                        .animate(_stagger(0.0, 0.40)),
                    child: Row(children: [
                      _KpiCard(
                        icon: Icons.business_outlined,
                        iconColor: _T.blue, iconBg: _T.blue50,
                        label: 'Total Clients',
                        value: '${_kStubClients.length}',
                        sub: 'All accounts',
                        subPositive: null,
                      ),
                      const SizedBox(width: 12),
                      _KpiCard(
                        icon: Icons.check_circle_outline_rounded,
                        iconColor: _T.green, iconBg: _T.green50,
                        label: 'Active',
                        value: '$_activeCount',
                        sub: 'In good standing',
                        subPositive: true,
                      ),
                      const SizedBox(width: 12),
                      _KpiCard(
                        icon: Icons.hourglass_top_rounded,
                        iconColor: _T.amber, iconBg: _T.amber50,
                        label: 'Pending',
                        value: '$_pendingCount',
                        sub: 'Awaiting onboard',
                        subPositive: null,
                      ),
                      const SizedBox(width: 12),
                      _KpiCard(
                        icon: Icons.folder_outlined,
                        iconColor: _T.purple, iconBg: _T.purple50,
                        label: 'Projects',
                        value: '$_totalProjects',
                        sub: 'Across all clients',
                        subPositive: null,
                      ),
                      const SizedBox(width: 12),
                      _KpiCard(
                        icon: Icons.assignment_outlined,
                        iconColor: _T.teal,
                        iconBg: const Color(0xFFECFEFF),
                        label: 'Active Tasks',
                        value: '$_totalTasks',
                        sub: 'In pipeline now',
                        subPositive: _totalTasks > 0,
                      ),
                    ]),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Toolbar: search + filters + view toggle + add ────────
                FadeTransition(
                  opacity: _stagger(0.12, 0.50),
                  child: SlideTransition(
                    position: Tween<Offset>(
                            begin: const Offset(0, 0.04), end: Offset.zero)
                        .animate(_stagger(0.12, 0.50)),
                    child: _Toolbar(
                      searchCtrl:  _searchCtrl,
                      filter:      _filter,
                      viewMode:    _viewMode,
                      activeCount: _activeCount,
                      pendingCount: _pendingCount,
                      inactiveCount: _inactiveCount,
                      onSearchChanged: (v) => setState(() => _search = v),
                      onFilterChanged: (f) => setState(() => _filter = f),
                      onViewModeChanged: (m) => setState(() => _viewMode = m),
                      onAddClient: () => _showCreateClientSheet(context),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // ── Client list / grid ────────────────────────────────────
                FadeTransition(
                  opacity: _stagger(0.22, 0.70),
                  child: SlideTransition(
                    position: Tween<Offset>(
                            begin: const Offset(0, 0.04), end: Offset.zero)
                        .animate(_stagger(0.22, 0.70)),
                    child: _viewMode == _ViewMode.table
                        ? _ClientTable(
                            clients:  _filtered,
                            sort:     _sort,
                            sortAsc:  _sortAsc,
                            selected: _selected,
                            onSort: (f) => setState(() {
                              if (_sort == f) {
                                _sortAsc = !_sortAsc;
                              } else {
                                _sort = f;
                                _sortAsc = true;
                              }
                            }),
                            onSelect: (c) => setState(() =>
                              _selected = _selected?.id == c.id ? null : c),
                            onEdit:   (c) => _showCreateClientSheet(context, client: c),
                          )
                        : _ClientGrid(
                            clients:  _filtered,
                            selected: _selected,
                            onSelect: (c) => setState(() =>
                              _selected = _selected?.id == c.id ? null : c),
                            onEdit:   (c) => _showCreateClientSheet(context, client: c),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Detail panel (slides in when a client is selected) ──────────
        AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          width: _selected != null ? 320.0 : 0,
          child: _selected != null
              ? _ClientDetailPanel(
                  client: _selected!,
                  onClose: () => setState(() => _selected = null),
                  onEdit:  () => _showCreateClientSheet(context, client: _selected),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  // ── Create / Edit bottom sheet ────────────────────────────────────────────
  void _showCreateClientSheet(BuildContext context, {Client? client}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreateClientSheet(existing: client),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// KPI CARD — same anatomy as admin dashboard
// ─────────────────────────────────────────────────────────────────────────────
class _KpiCard extends StatelessWidget {
  final IconData icon;
  final Color    iconColor, iconBg;
  final String   label, value, sub;
  final bool?    subPositive;

  const _KpiCard({
    required this.icon, required this.iconColor, required this.iconBg,
    required this.label, required this.value, required this.sub,
    required this.subPositive,
  });

  @override
  Widget build(BuildContext context) {
    final subColor = subPositive == null
        ? _T.slate400
        : subPositive!
            ? _T.green
            : _T.red;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: _T.white,
            border: Border.all(color: _T.slate200),
            borderRadius: BorderRadius.circular(_T.rLg)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(_T.r)),
                child: Icon(icon, size: 17, color: iconColor),
              ),
              const Spacer(),
              Icon(
                subPositive == null
                    ? Icons.remove
                    : subPositive!
                        ? Icons.trending_up_rounded
                        : Icons.trending_down_rounded,
                size: 14, color: subColor,
              ),
            ]),
            const SizedBox(height: 12),
            Text(value,
                style: const TextStyle(
                    fontSize: 28, fontWeight: FontWeight.w800,
                    color: _T.ink, letterSpacing: -1, height: 1)),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600, color: _T.ink3)),
            const SizedBox(height: 6),
            Text(sub,
                style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w500, color: subColor)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TOOLBAR
// ─────────────────────────────────────────────────────────────────────────────
class _Toolbar extends StatelessWidget {
  final TextEditingController searchCtrl;
  final _FilterStatus filter;
  final _ViewMode viewMode;
  final int activeCount, pendingCount, inactiveCount;
  final ValueChanged<String>        onSearchChanged;
  final ValueChanged<_FilterStatus> onFilterChanged;
  final ValueChanged<_ViewMode>     onViewModeChanged;
  final VoidCallback                onAddClient;

  const _Toolbar({
    required this.searchCtrl, required this.filter, required this.viewMode,
    required this.activeCount, required this.pendingCount, required this.inactiveCount,
    required this.onSearchChanged, required this.onFilterChanged,
    required this.onViewModeChanged, required this.onAddClient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: _T.white,
          border: Border.all(color: _T.slate200),
          borderRadius: BorderRadius.circular(_T.rLg)),
      child: Row(children: [

        // ── Search ─────────────────────────────────────────────────────
        Expanded(
          flex: 3,
          child: SizedBox(
            height: 36,
            child: TextField(
              controller: searchCtrl,
              onChanged: onSearchChanged,
              style: const TextStyle(fontSize: 13, color: _T.ink),
              decoration: InputDecoration(
                hintText: 'Search clients, contacts, industries…',
                hintStyle: const TextStyle(fontSize: 13, color: _T.slate400),
                prefixIcon: const Icon(Icons.search_rounded,
                    size: 16, color: _T.slate400),
                filled: true,
                fillColor: _T.slate50,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(_T.r),
                    borderSide: const BorderSide(color: _T.slate200)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(_T.r),
                    borderSide: const BorderSide(color: _T.slate200)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(_T.r),
                    borderSide: const BorderSide(color: _T.blue, width: 1.5)),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),

        // ── Status filter tabs ─────────────────────────────────────────
        _FilterChip(
          label: 'All',
          isActive: filter == _FilterStatus.all,
          onTap: () => onFilterChanged(_FilterStatus.all),
        ),
        const SizedBox(width: 4),
        _FilterChip(
          label: 'Active',
          count: activeCount,
          dotColor: _T.green,
          isActive: filter == _FilterStatus.active,
          onTap: () => onFilterChanged(_FilterStatus.active),
        ),
        const SizedBox(width: 4),
        _FilterChip(
          label: 'Pending',
          count: pendingCount,
          dotColor: _T.amber,
          isActive: filter == _FilterStatus.pending,
          onTap: () => onFilterChanged(_FilterStatus.pending),
        ),
        const SizedBox(width: 4),
        _FilterChip(
          label: 'Inactive',
          count: inactiveCount,
          dotColor: _T.slate400,
          isActive: filter == _FilterStatus.inactive,
          onTap: () => onFilterChanged(_FilterStatus.inactive),
        ),
        const SizedBox(width: 10),

        // ── View toggle ────────────────────────────────────────────────
        Container(
          height: 32,
          decoration: BoxDecoration(
              color: _T.slate100,
              borderRadius: BorderRadius.circular(_T.r)),
          child: Row(children: [
            _ViewToggleBtn(
              icon: Icons.table_rows_outlined,
              isActive: viewMode == _ViewMode.table,
              onTap: () => onViewModeChanged(_ViewMode.table),
            ),
            _ViewToggleBtn(
              icon: Icons.grid_view_rounded,
              isActive: viewMode == _ViewMode.grid,
              onTap: () => onViewModeChanged(_ViewMode.grid),
            ),
          ]),
        ),
        const SizedBox(width: 10),

        // ── Add client CTA ─────────────────────────────────────────────
        Material(
          color: _T.blue,
          borderRadius: BorderRadius.circular(_T.r),
          child: InkWell(
            onTap: onAddClient,
            borderRadius: BorderRadius.circular(_T.r),
            hoverColor: _T.blueHover,
            child: Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, size: 15, color: Colors.white),
                  SizedBox(width: 6),
                  Text('Add Client',
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600,
                          color: Colors.white)),
                ],
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String     label;
  final int?       count;
  final Color?     dotColor;
  final bool       isActive;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label, required this.isActive, required this.onTap,
    this.count, this.dotColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? _T.blue50 : Colors.transparent,
          borderRadius: BorderRadius.circular(_T.r),
          border: Border.all(
              color: isActive ? _T.blue.withOpacity(0.4) : Colors.transparent),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (dotColor != null) ...[
            Container(
              width: 5, height: 5,
              decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
          ],
          Text(label,
              style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive ? _T.blue : _T.slate500)),
          if (count != null) ...[
            const SizedBox(width: 5),
            Text('$count',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isActive ? _T.blue : _T.slate400)),
          ],
        ]),
      ),
    );
  }
}

class _ViewToggleBtn extends StatelessWidget {
  final IconData icon;
  final bool     isActive;
  final VoidCallback onTap;

  const _ViewToggleBtn({required this.icon, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        width: 32, height: 32,
        decoration: BoxDecoration(
          color: isActive ? _T.white : Colors.transparent,
          borderRadius: BorderRadius.circular(_T.r - 1),
          boxShadow: isActive
              ? [BoxShadow(color: Colors.black.withOpacity(0.07),
                  blurRadius: 4, offset: const Offset(0, 1))]
              : null,
        ),
        child: Icon(icon,
            size: 15,
            color: isActive ? _T.ink : _T.slate400),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CLIENT TABLE
// ─────────────────────────────────────────────────────────────────────────────
class _ClientTable extends StatelessWidget {
  final List<Client> clients;
  final _SortField   sort;
  final bool         sortAsc;
  final Client?      selected;
  final ValueChanged<_SortField> onSort;
  final ValueChanged<Client>     onSelect;
  final ValueChanged<Client>     onEdit;

  const _ClientTable({
    required this.clients, required this.sort, required this.sortAsc,
    required this.selected, required this.onSort, required this.onSelect,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _T.white,
        border: Border.all(color: _T.slate200),
        borderRadius: BorderRadius.circular(_T.rLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            decoration: const BoxDecoration(
              color: _T.slate50,
              border: Border(bottom: BorderSide(color: _T.slate200)),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(_T.rLg),
                topRight: Radius.circular(_T.rLg),
              ),
            ),
            child: Row(children: [
              const SizedBox(width: 36 + 10),           // avatar spacer
              Expanded(flex: 4, child: _SortHeader('Client', _SortField.name, sort, sortAsc, onSort)),
              Expanded(flex: 3, child: _ColHeader('Contact')),
              Expanded(flex: 2, child: _ColHeader('Industry')),
              Expanded(flex: 1, child: _SortHeader('Projects', _SortField.projects, sort, sortAsc, onSort)),
              Expanded(flex: 1, child: _SortHeader('Tasks', _SortField.tasks, sort, sortAsc, onSort)),
              Expanded(flex: 2, child: _SortHeader('Joined', _SortField.joined, sort, sortAsc, onSort)),
              Expanded(flex: 2, child: _ColHeader('Status')),
              const SizedBox(width: 36),                // actions spacer
            ]),
          ),

          // Data rows
          if (clients.isEmpty)
            _EmptyState()
          else
            ...clients.asMap().entries.map((e) {
              final i = e.key;
              final c = e.value;
              final isSelected = selected?.id == c.id;
              return _ClientTableRow(
                client: c,
                isSelected: isSelected,
                isLast: i == clients.length - 1,
                onTap: () => onSelect(c),
                onEdit: () => onEdit(c),
              );
            }),
        ],
      ),
    );
  }
}

class _SortHeader extends StatelessWidget {
  final String       label;
  final _SortField   field;
  final _SortField   active;
  final bool         asc;
  final ValueChanged<_SortField> onSort;

  const _SortHeader(this.label, this.field, this.active, this.asc, this.onSort);

  @override
  Widget build(BuildContext context) {
    final isActive = field == active;
    return GestureDetector(
      onTap: () => onSort(field),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(label,
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: isActive ? _T.blue : _T.slate400)),
        const SizedBox(width: 3),
        Icon(
          isActive
              ? (asc ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded)
              : Icons.unfold_more_rounded,
          size: 11,
          color: isActive ? _T.blue : _T.slate300,
        ),
      ]),
    );
  }
}

class _ColHeader extends StatelessWidget {
  final String text;
  const _ColHeader(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontSize: 10, fontWeight: FontWeight.w700,
          letterSpacing: 0.5, color: _T.slate400));
}

class _ClientTableRow extends StatefulWidget {
  final Client       client;
  final bool         isSelected, isLast;
  final VoidCallback onTap, onEdit;

  const _ClientTableRow({
    required this.client, required this.isSelected, required this.isLast,
    required this.onTap, required this.onEdit,
  });

  @override
  State<_ClientTableRow> createState() => _ClientTableRowState();
}

class _ClientTableRowState extends State<_ClientTableRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.client;
    return MouseRegion(
      onEnter:  (_) => setState(() => _hovered = true),
      onExit:   (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? _T.blue50
                : _hovered
                    ? _T.slate50
                    : _T.white,
            border: widget.isLast
                ? null
                : const Border(bottom: BorderSide(color: _T.slate100)),
            borderRadius: widget.isLast
                ? const BorderRadius.only(
                    bottomLeft: Radius.circular(_T.rLg),
                    bottomRight: Radius.circular(_T.rLg))
                : null,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar
              _ClientAvatar(client: c, size: 36),
              const SizedBox(width: 10),

              // Name
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.name,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600,
                            color: _T.ink)),
                    const SizedBox(height: 1),
                    Text(c.email,
                        style: const TextStyle(
                            fontSize: 11, color: _T.slate400,
                            fontWeight: FontWeight.w400)),
                  ],
                ),
              ),

              // Contact
              Expanded(
                flex: 3,
                child: Text(c.contactName,
                    style: const TextStyle(
                        fontSize: 12.5, fontWeight: FontWeight.w500,
                        color: _T.ink3)),
              ),

              // Industry
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _T.slate100,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(c.industry,
                      style: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w600,
                          color: _T.slate500)),
                ),
              ),

              // Projects
              Expanded(
                flex: 1,
                child: Text('${c.projectCount}',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700,
                        color: _T.ink3)),
              ),

              // Tasks
              Expanded(
                flex: 1,
                child: Row(children: [
                  if (c.activeTaskCount > 0)
                    Container(
                      width: 6, height: 6,
                      margin: const EdgeInsets.only(right: 5),
                      decoration: const BoxDecoration(
                          color: _T.blue, shape: BoxShape.circle),
                    ),
                  Text('${c.activeTaskCount}',
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700,
                          color: c.activeTaskCount > 0 ? _T.ink3 : _T.slate300)),
                ]),
              ),

              // Joined
              Expanded(
                flex: 2,
                child: Text(_fmtDate(c.joinedDate),
                    style: const TextStyle(
                        fontSize: 12, color: _T.slate400,
                        fontWeight: FontWeight.w500)),
              ),

              // Status
              Expanded(
                flex: 2,
                child: _StatusBadge(c.status),
              ),

              // Actions
              SizedBox(
                width: 36,
                child: AnimatedOpacity(
                  opacity: _hovered || widget.isSelected ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 120),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: widget.onEdit,
                      borderRadius: BorderRadius.circular(_T.r),
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(Icons.edit_outlined,
                            size: 14, color: _T.slate400),
                      ),
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
// CLIENT GRID
// ─────────────────────────────────────────────────────────────────────────────
class _ClientGrid extends StatelessWidget {
  final List<Client> clients;
  final Client?      selected;
  final ValueChanged<Client> onSelect, onEdit;

  const _ClientGrid({
    required this.clients, required this.selected,
    required this.onSelect, required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    if (clients.isEmpty) return _EmptyState();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 280,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.22,
      ),
      itemCount: clients.length,
      itemBuilder: (_, i) => _ClientGridCard(
        client:     clients[i],
        isSelected: selected?.id == clients[i].id,
        onTap:      () => onSelect(clients[i]),
        onEdit:     () => onEdit(clients[i]),
      ),
    );
  }
}

class _ClientGridCard extends StatefulWidget {
  final Client client;
  final bool   isSelected;
  final VoidCallback onTap, onEdit;

  const _ClientGridCard({
    required this.client, required this.isSelected,
    required this.onTap, required this.onEdit,
  });

  @override
  State<_ClientGridCard> createState() => _ClientGridCardState();
}

class _ClientGridCardState extends State<_ClientGridCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.client;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _T.white,
            border: Border.all(
              color: widget.isSelected ? _T.blue : _T.slate200,
              width: widget.isSelected ? 1.5 : 1.0,
            ),
            borderRadius: BorderRadius.circular(_T.rLg),
            boxShadow: _hovered
                ? [BoxShadow(color: Colors.black.withOpacity(0.06),
                    blurRadius: 16, offset: const Offset(0, 4))]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _ClientAvatar(client: c, size: 40),
                  const Spacer(),
                  _StatusBadge(c.status),
                ],
              ),
              const SizedBox(height: 12),
              Text(c.name,
                  style: const TextStyle(
                      fontSize: 13.5, fontWeight: FontWeight.w700,
                      color: _T.ink, height: 1.2),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text(c.contactName,
                  style: const TextStyle(fontSize: 11.5, color: _T.slate400,
                      fontWeight: FontWeight.w500)),
              const Spacer(),
              Row(children: [
                _GridStat(Icons.folder_outlined, '${c.projectCount}', _T.purple),
                const SizedBox(width: 12),
                _GridStat(Icons.assignment_outlined, '${c.activeTaskCount}', _T.blue),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                      color: _T.slate100,
                      borderRadius: BorderRadius.circular(99)),
                  child: Text(c.industry,
                      style: const TextStyle(
                          fontSize: 10, fontWeight: FontWeight.w600,
                          color: _T.slate500)),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

class _GridStat extends StatelessWidget {
  final IconData icon;
  final String   value;
  final Color    color;
  const _GridStat(this.icon, this.value, this.color);

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 12, color: color),
      const SizedBox(width: 4),
      Text(value,
          style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w700, color: color)),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// CLIENT DETAIL PANEL — slides in from right
// ─────────────────────────────────────────────────────────────────────────────
class _ClientDetailPanel extends StatelessWidget {
  final Client       client;
  final VoidCallback onClose, onEdit;

  const _ClientDetailPanel({
    required this.client, required this.onClose, required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final c = client;
    return Container(
      decoration: const BoxDecoration(
        color: _T.white,
        border: Border(left: BorderSide(color: _T.slate200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
            decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: _T.slate200))),
            child: Row(children: [
              const Text('Client details',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700, color: _T.ink)),
              const Spacer(),
              // Edit
              _IconBtn(Icons.edit_outlined, onEdit),
              const SizedBox(width: 4),
              // Close
              _IconBtn(Icons.close_rounded, onClose),
            ]),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Identity
                  Center(
                    child: Column(children: [
                      _ClientAvatar(client: c, size: 56),
                      const SizedBox(height: 10),
                      Text(c.name,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w800,
                              color: _T.ink, letterSpacing: -0.3),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 4),
                      _StatusBadge(c.status),
                    ]),
                  ),
                  const SizedBox(height: 20),
                  const Divider(height: 1, color: _T.slate100),
                  const SizedBox(height: 16),

                  // Contact info
                  _DetailSection('Contact', [
                    _DetailRow(Icons.person_outline, c.contactName),
                    _DetailRow(Icons.email_outlined, c.email),
                    _DetailRow(Icons.phone_outlined, c.phone),
                  ]),
                  const SizedBox(height: 16),

                  // Business info
                  _DetailSection('Business', [
                    _DetailRow(Icons.business_outlined, c.industry),
                    _DetailRow(Icons.calendar_today_outlined,
                        'Joined ${_fmtDateLong(c.joinedDate)}'),
                  ]),
                  const SizedBox(height: 16),

                  // Stats
                  Row(children: [
                    Expanded(child: _StatTile('Projects',
                        '${c.projectCount}', _T.purple, _T.purple50)),
                    const SizedBox(width: 10),
                    Expanded(child: _StatTile('Active Tasks',
                        '${c.activeTaskCount}', _T.blue, _T.blue50)),
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  final String        title;
  final List<Widget>  rows;
  const _DetailSection(this.title, this.rows);

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title.toUpperCase(),
          style: TextStyle(
              fontSize: 9.5, fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
              color: _T.slate400.withOpacity(0.8))),
      const SizedBox(height: 8),
      ...rows,
    ],
  );
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String   value;
  const _DetailRow(this.icon, this.value);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(children: [
      Icon(icon, size: 13, color: _T.slate400),
      const SizedBox(width: 8),
      Expanded(
        child: Text(value,
            style: const TextStyle(
                fontSize: 12.5, fontWeight: FontWeight.w500, color: _T.ink3),
            overflow: TextOverflow.ellipsis),
      ),
    ]),
  );
}

class _StatTile extends StatelessWidget {
  final String label, value;
  final Color  color, bg;
  const _StatTile(this.label, this.value, this.color, this.bg);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: color.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(_T.r)),
    child: Column(children: [
      Text(value,
          style: TextStyle(
              fontSize: 22, fontWeight: FontWeight.w800,
              color: color, letterSpacing: -0.5)),
      const SizedBox(height: 2),
      Text(label,
          style: const TextStyle(
              fontSize: 10.5, fontWeight: FontWeight.w600,
              color: _T.slate500)),
    ]),
  );
}

class _IconBtn extends StatelessWidget {
  final IconData     icon;
  final VoidCallback onTap;
  const _IconBtn(this.icon, this.onTap);

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(_T.r),
      child: Container(
        width: 28, height: 28,
        decoration: BoxDecoration(
            border: Border.all(color: _T.slate200),
            borderRadius: BorderRadius.circular(_T.r)),
        child: Icon(icon, size: 13, color: _T.slate400),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// CREATE / EDIT CLIENT BOTTOM SHEET
// ─────────────────────────────────────────────────────────────────────────────
class _CreateClientSheet extends StatefulWidget {
  final Client? existing;
  const _CreateClientSheet({this.existing});

  @override
  State<_CreateClientSheet> createState() => _CreateClientSheetState();
}

class _CreateClientSheetState extends State<_CreateClientSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 320));

  final _namCtrl  = TextEditingController();
  final _conCtrl  = TextEditingController();
  final _emlCtrl  = TextEditingController();
  final _phnCtrl  = TextEditingController();
  final _indCtrl  = TextEditingController();

  bool _saving = false;

  static const _industries = [
    'Advertising', 'Finance', 'Fashion', 'Media', 'Real Estate',
    'Retail', 'Technology', 'Healthcare', 'Education', 'Other',
  ];

  String? _selectedIndustry;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final c = widget.existing!;
      _namCtrl.text = c.name;
      _conCtrl.text = c.contactName;
      _emlCtrl.text = c.email;
      _phnCtrl.text = c.phone;
      _selectedIndustry = c.industry;
    }
    _ac.forward();
  }

  @override
  void dispose() {
    _ac.dispose();
    _namCtrl.dispose(); _conCtrl.dispose();
    _emlCtrl.dispose(); _phnCtrl.dispose(); _indCtrl.dispose();
    super.dispose();
  }

  bool get _isEdit => widget.existing != null;

  void _submit() async {
    if (_namCtrl.text.trim().isEmpty || _emlCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    await Future.delayed(const Duration(milliseconds: 600)); // replace with real API call
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ac,
      builder: (_, child) => Opacity(opacity: _ac.value, child: child),
      child: Container(
        decoration: const BoxDecoration(
          color: _T.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 4),
                width: 36, height: 4,
                decoration: BoxDecoration(
                    color: _T.slate200,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 4),

            // Title
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 0),
              child: Row(children: [
                Text(_isEdit ? 'Edit Client' : 'Add New Client',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800,
                        color: _T.ink, letterSpacing: -0.3)),
                const Spacer(),
                _IconBtn(Icons.close_rounded, () => Navigator.of(context).pop()),
              ]),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Text(
                _isEdit
                    ? 'Update the client details below.'
                    : 'Fill in the details to create a new client account.',
                style: const TextStyle(fontSize: 12.5, color: _T.slate400)),
            ),
            const SizedBox(height: 20),
            const Divider(height: 1, color: _T.slate100),

            // Form
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row 1: Company + Contact
                    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Expanded(child: _Field(
                        label: 'Company Name',
                        hint: 'e.g. Harrington & Co',
                        controller: _namCtrl,
                        icon: Icons.business_outlined,
                        required: true,
                      )),
                      const SizedBox(width: 14),
                      Expanded(child: _Field(
                        label: 'Contact Name',
                        hint: 'Primary contact person',
                        controller: _conCtrl,
                        icon: Icons.person_outline,
                      )),
                    ]),
                    const SizedBox(height: 14),

                    // Row 2: Email + Phone
                    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Expanded(child: _Field(
                        label: 'Email Address',
                        hint: 'client@company.com',
                        controller: _emlCtrl,
                        icon: Icons.email_outlined,
                        required: true,
                        keyboard: TextInputType.emailAddress,
                      )),
                      const SizedBox(width: 14),
                      Expanded(child: _Field(
                        label: 'Phone',
                        hint: '+1 212 555 0100',
                        controller: _phnCtrl,
                        icon: Icons.phone_outlined,
                        keyboard: TextInputType.phone,
                      )),
                    ]),
                    const SizedBox(height: 14),

                    // Industry dropdown
                    _FieldLabel('Industry'),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _selectedIndustry,
                      hint: const Text('Select an industry',
                          style: TextStyle(fontSize: 13, color: _T.slate400)),
                      icon: const Icon(Icons.keyboard_arrow_down_rounded,
                          size: 16, color: _T.slate400),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.category_outlined,
                            size: 15, color: _T.slate400),
                        filled: true,
                        fillColor: _T.slate50,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(_T.r),
                            borderSide: const BorderSide(color: _T.slate200)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(_T.r),
                            borderSide: const BorderSide(color: _T.slate200)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(_T.r),
                            borderSide: const BorderSide(color: _T.blue, width: 1.5)),
                      ),
                      dropdownColor: _T.white,
                      borderRadius: BorderRadius.circular(_T.rLg),
                      items: _industries.map((ind) => DropdownMenuItem(
                        value: ind,
                        child: Text(ind,
                            style: const TextStyle(
                                fontSize: 13, color: _T.ink, fontWeight: FontWeight.w500)),
                      )).toList(),
                      onChanged: (v) => setState(() => _selectedIndustry = v),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 22),
              decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: _T.slate100))),
              child: Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving ? null : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _T.slate500,
                      side: const BorderSide(color: _T.slate200),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(_T.r)),
                    ),
                    child: const Text('Cancel',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: _T.blue,
                      disabledBackgroundColor: _T.slate200,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(_T.r)),
                    ),
                    icon: _saving
                        ? const SizedBox(
                            width: 14, height: 14,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : Icon(_isEdit ? Icons.check_rounded : Icons.add_rounded,
                            size: 16),
                    label: Text(
                      _saving
                          ? (_isEdit ? 'Saving…' : 'Creating…')
                          : (_isEdit ? 'Save Changes' : 'Create Client'),
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600),
                    ),
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
// FORM FIELD HELPERS
// ─────────────────────────────────────────────────────────────────────────────
class _Field extends StatelessWidget {
  final String                label, hint;
  final TextEditingController controller;
  final IconData              icon;
  final bool                  required;
  final TextInputType?        keyboard;

  const _Field({
    required this.label, required this.hint,
    required this.controller, required this.icon,
    this.required = false, this.keyboard,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(children: [
        _FieldLabel(label),
        if (required) ...[
          const SizedBox(width: 3),
          const Text('*', style: TextStyle(color: _T.red, fontSize: 12)),
        ],
      ]),
      const SizedBox(height: 6),
      TextField(
        controller:  controller,
        keyboardType: keyboard,
        style: const TextStyle(fontSize: 13, color: _T.ink),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 13, color: _T.slate300),
          prefixIcon: Icon(icon, size: 15, color: _T.slate400),
          filled: true,
          fillColor: _T.slate50,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_T.r),
              borderSide: const BorderSide(color: _T.slate200)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_T.r),
              borderSide: const BorderSide(color: _T.slate200)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_T.r),
              borderSide: const BorderSide(color: _T.blue, width: 1.5)),
        ),
      ),
    ],
  );
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontSize: 12, fontWeight: FontWeight.w600, color: _T.ink3));
}

// ─────────────────────────────────────────────────────────────────────────────
// STATUS BADGE
// ─────────────────────────────────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final ClientStatus status;
  const _StatusBadge(this.status);

  @override
  Widget build(BuildContext context) {
    final (label, color, bg) = switch (status) {
      ClientStatus.active   => ('Active',   _T.green,   _T.green50),
      ClientStatus.inactive => ('Inactive', _T.slate400, _T.slate100),
      ClientStatus.pending  => ('Pending',  _T.amber,   _T.amber50),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: color.withOpacity(0.35)),
          borderRadius: BorderRadius.circular(99)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 5, height: 5,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(label,
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700, color: color)),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CLIENT AVATAR
// ─────────────────────────────────────────────────────────────────────────────
class _ClientAvatar extends StatelessWidget {
  final Client client;
  final double size;
  const _ClientAvatar({required this.client, required this.size});

  @override
  Widget build(BuildContext context) => Container(
    width: size, height: size,
    decoration: BoxDecoration(
        color: client.color.withOpacity(0.12), shape: BoxShape.circle,
        border: Border.all(color: client.color.withOpacity(0.25))),
    child: Center(
      child: Text(client.initials,
          style: TextStyle(
              fontSize: size * 0.33, fontWeight: FontWeight.w800,
              color: client.color, letterSpacing: -0.5)),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// EMPTY STATE
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 52),
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
                color: _T.slate100, borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.business_outlined,
                size: 24, color: _T.slate400),
          ),
          const SizedBox(height: 14),
          const Text('No clients found',
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700, color: _T.ink3)),
          const SizedBox(height: 4),
          const Text('Try adjusting your search or filters.',
              style: TextStyle(fontSize: 12.5, color: _T.slate400)),
        ],
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED SIDEBAR WIDGETS — identical to admin_desktop_dashboard.dart
// ─────────────────────────────────────────────────────────────────────────────
class _SidebarLabel extends StatelessWidget {
  final String text;
  const _SidebarLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 8, bottom: 4),
    child: Text(text.toUpperCase(),
        style: TextStyle(
            fontSize: 9.5, fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
            color: Colors.white.withOpacity(0.28))),
  );
}

class _SidebarNavItem extends StatelessWidget {
  final IconData     icon;
  final String       label;
  final bool         isActive;
  final String?      badge;
  final VoidCallback onTap;

  const _SidebarNavItem({
    required this.icon, required this.label, required this.isActive,
    required this.onTap, this.badge,
  });

  @override
  Widget build(BuildContext context) => Material(
    color: isActive ? _T.blue.withOpacity(0.25) : Colors.transparent,
    borderRadius: BorderRadius.circular(_T.r),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(_T.r),
      hoverColor: Colors.white.withOpacity(0.07),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Row(children: [
          Icon(icon, size: 14,
              color: Colors.white.withOpacity(isActive ? 1.0 : 0.5)),
          const SizedBox(width: 9),
          Expanded(
            child: Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    color: Colors.white.withOpacity(isActive ? 1.0 : 0.5))),
          ),
          if (badge != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
              decoration: BoxDecoration(
                  color: _T.blue, borderRadius: BorderRadius.circular(99)),
              child: Text(badge!,
                  style: const TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w700,
                      color: Colors.white)),
            ),
        ]),
      ),
    ),
  );
}

class _SidebarProjectRow extends StatelessWidget {
  final String name;
  final Color  color;
  final int    count;
  final bool   isActive;
  final VoidCallback onTap;

  const _SidebarProjectRow({
    required this.name, required this.color, required this.count,
    required this.isActive, required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Material(
    color: isActive ? Colors.white.withOpacity(0.10) : Colors.transparent,
    borderRadius: BorderRadius.circular(_T.r),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(_T.r),
      hoverColor: Colors.white.withOpacity(0.06),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Row(children: [
          Container(width: 8, height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 9),
          Expanded(
            child: Text(name,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    color: Colors.white.withOpacity(isActive ? 0.9 : 0.55))),
          ),
          Text('$count',
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.25))),
        ]),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// LOGO + HELPERS
// ─────────────────────────────────────────────────────────────────────────────
class _LogoMark extends StatelessWidget {
  final double size;
  const _LogoMark({required this.size});

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size(size, size), painter: _LogoPainter());
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final paint = Paint()..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.19, h * 0.66), w * 0.065,
        paint..color = Colors.white.withOpacity(0.5));
    canvas.drawCircle(Offset(w * 0.48, h * 0.34), w * 0.065,
        paint..color = Colors.white.withOpacity(0.7));
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.19, h * 0.66)
        ..cubicTo(w * 0.19, h * 0.66, w * 0.30, h * 0.34, w * 0.48, h * 0.34)
        ..cubicTo(w * 0.66, h * 0.34, w * 0.64, h * 0.66, w * 0.81, h * 0.55),
      Paint()
        ..color = Colors.white.withOpacity(0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.055
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.35, h * 0.51)
        ..lineTo(w * 0.48, h * 0.65)
        ..lineTo(w * 0.81, h * 0.33),
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.077
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}

String _fmtDate(DateTime d) {
  const months = ['Jan','Feb','Mar','Apr','May','Jun',
                   'Jul','Aug','Sep','Oct','Nov','Dec'];
  return '${months[d.month - 1]} ${d.day}, ${d.year}';
}

String _fmtDateLong(DateTime d) {
  const months = ['January','February','March','April','May','June',
                   'July','August','September','October','November','December'];
  return '${months[d.month - 1]} ${d.day}, ${d.year}';
}
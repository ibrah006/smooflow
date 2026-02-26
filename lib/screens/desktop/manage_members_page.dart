// ─────────────────────────────────────────────────────────────────────────────
// manage_members_page.dart
//
// Desktop member management page for Smooflow.
// Pixel-perfect match to ClientsPage design system.
//
// Features:
// • Real-time member list with WebSocket
// • Role management
// • Member invite/edit
// • Search and filtering
// • Consistent design with ClientsPage
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/components/connection_status_banner.dart';
import 'package:smooflow/core/api/websocket_clients/member_websocket.dart';
import 'package:smooflow/core/models/member.dart';
import 'package:smooflow/enums/table_view_mode.dart';
import 'package:smooflow/providers/member_provider.dart';
import 'package:smooflow/screens/desktop/components/error_view.dart';
import 'package:smooflow/screens/desktop/components/kpi_card.dart';
import 'package:smooflow/screens/printers_management_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DESIGN TOKENS — exact copy from ClientsPage
// ─────────────────────────────────────────────────────────────────────────────
class _T {
  static const blue = Color(0xFF2563EB);
  static const blueHover = Color(0xFF1D4ED8);
  static const blue100 = Color(0xFFDBEAFE);
  static const blue50 = Color(0xFFEFF6FF);
  static const teal = Color(0xFF38BDF8);
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
  static const ink2 = Color(0xFF1E293B);
  static const ink3 = Color(0xFF334155);
  static const white = Colors.white;

  // Radius
  static const double rSm = 6.0;
  static const r = 8.0;
  static const rLg = 12.0;
  static const rXl = 16.0;
}

// ─────────────────────────────────────────────────────────────────────────────
// FILTER / SORT STATE
// ─────────────────────────────────────────────────────────────────────────────
enum _SortField { name, role, joined }
enum _FilterRole { all, admin, manager, designer, delivery, viewer }

// ─────────────────────────────────────────────────────────────────────────────
// ROOT SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class ManageMembersPage extends ConsumerStatefulWidget {
  const ManageMembersPage({super.key});

  @override
  ConsumerState<ManageMembersPage> createState() => _ManageMembersPageState();
}

class _ManageMembersPageState extends ConsumerState<ManageMembersPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(memberListProvider.notifier).loadMembers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _T.slate50,
      body: Focus(
        autofocus: true,
        onKeyEvent: (_, __) => KeyEventResult.ignored,
        child: const MembersView(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MEMBERS VIEW
// ─────────────────────────────────────────────────────────────────────────────
class MembersView extends ConsumerStatefulWidget {
  const MembersView({super.key});

  @override
  ConsumerState<MembersView> createState() => _MembersViewState();
}

class _MembersViewState extends ConsumerState<MembersView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 800));

  _SortField _sort = _SortField.name;
  bool _sortAsc = true;
  _FilterRole _filter = _FilterRole.all;
  TableViewMode _viewMode = TableViewMode.table;
  String _search = '';

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

  @override
  Widget build(BuildContext context) {
    final memberState = ref.watch(memberListProvider);
    final selectedMember = ref.watch(selectedMemberProvider);
    final connectionStatus = ref.watch(memberConnectionStatusProvider);

    final members = _getFilteredMembers(memberState.members);

    // Listen for real-time changes
    ref.listen<AsyncValue<MemberChangeEvent>>(
      memberChangesStreamProvider,
      (previous, next) {
        next.whenData((event) {
          _showChangeNotification(context, event);
        });
      },
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Connection status banner
                connectionStatus.when(
                  data: (status) => ConnectionStatusBanner(status: status),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),

                // KPI strip
                FadeTransition(
                  opacity: _stagger(0.0, 0.40),
                  child: SlideTransition(
                    position: Tween<Offset>(
                            begin: const Offset(0, 0.04), end: Offset.zero)
                        .animate(_stagger(0.0, 0.40)),
                    child: _buildKpiStrip(memberState.members),
                  ),
                ),
                const SizedBox(height: 16),

                // Toolbar
                FadeTransition(
                  opacity: _stagger(0.12, 0.50),
                  child: SlideTransition(
                    position: Tween<Offset>(
                            begin: const Offset(0, 0.04), end: Offset.zero)
                        .animate(_stagger(0.12, 0.50)),
                    child: _buildToolbar(memberState.members),
                  ),
                ),
                const SizedBox(height: 12),

                // Loading / Error States
                if (memberState.isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (memberState.error != null)
                  ErrorView(
                    error: memberState.error!,
                    onRetry: () {
                      ref.read(memberListProvider.notifier).clearError();
                      ref.read(memberListProvider.notifier).loadMembers();
                    },
                  )
                else
                  // Member list / grid
                  FadeTransition(
                    opacity: _stagger(0.22, 0.70),
                    child: SlideTransition(
                      position: Tween<Offset>(
                              begin: const Offset(0, 0.04), end: Offset.zero)
                          .animate(_stagger(0.22, 0.70)),
                      child: _viewMode == TableViewMode.table
                          ? _MemberTable(
                              members: members,
                              sort: _sort,
                              sortAsc: _sortAsc,
                              selected: selectedMember,
                              onSort: (f) => setState(() {
                                if (_sort == f) {
                                  _sortAsc = !_sortAsc;
                                } else {
                                  _sort = f;
                                  _sortAsc = true;
                                }
                              }),
                              onSelect: (m) {
                                if (selectedMember?.id == m.id) {
                                  ref.read(selectedMemberProvider.notifier).state = null;
                                  ref.read(memberListProvider.notifier)
                                      .unsubscribeFromMember(m.id);
                                } else {
                                  ref.read(selectedMemberProvider.notifier).state = m;
                                  ref.read(memberListProvider.notifier)
                                      .subscribeToMember(m.id);
                                }
                              },
                              onEdit: (m) => _showInviteMemberSheet(context, existing: m),
                            )
                          : _MemberGrid(
                              members: members,
                              selected: selectedMember,
                              onSelect: (m) {
                                if (selectedMember?.id == m.id) {
                                  ref.read(selectedMemberProvider.notifier).state = null;
                                  ref.read(memberListProvider.notifier)
                                      .unsubscribeFromMember(m.id);
                                } else {
                                  ref.read(selectedMemberProvider.notifier).state = m;
                                  ref.read(memberListProvider.notifier)
                                      .subscribeToMember(m.id);
                                }
                              },
                              onEdit: (m) => _showInviteMemberSheet(context, existing: m),
                            ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // Detail panel
        AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          width: selectedMember != null ? 320.0 : 0,
          child: selectedMember != null
              ? _MemberDetailPanel(
                  member: selectedMember,
                  onClose: () {
                    ref.read(memberListProvider.notifier)
                        .unsubscribeFromMember(selectedMember.id);
                    ref.read(selectedMemberProvider.notifier).state = null;
                  },
                  onEdit: () => _showInviteMemberSheet(context, existing: selectedMember),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  List<Member> _getFilteredMembers(List<Member> allMembers) {
    var list = allMembers.where((m) {
      // Search filter
      final matchSearch = _search.isEmpty ||
          m.name.toLowerCase().contains(_search.toLowerCase()) ||
          m.email.toLowerCase().contains(_search.toLowerCase());

      // Role filter
      final matchRole = _filter == _FilterRole.all ||
          (_filter == _FilterRole.admin && m.role == 'admin') ||
          (_filter == _FilterRole.manager && m.role == 'manager') ||
          (_filter == _FilterRole.designer && m.role == 'designer') ||
          (_filter == _FilterRole.delivery && m.role == 'delivery') ||
          (_filter == _FilterRole.viewer && m.role == 'viewer');

      return matchSearch && matchRole;
    }).toList();

    // Sort
    list.sort((a, b) {
      int cmp;
      switch (_sort) {
        case _SortField.name:
          cmp = a.name.compareTo(b.name);
          break;
        case _SortField.role:
          cmp = a.role.compareTo(b.role);
          break;
        case _SortField.joined:
          cmp = a.createdAt.compareTo(b.createdAt);
          break;
      }
      return _sortAsc ? cmp : -cmp;
    });

    return list;
  }

  Widget _buildKpiStrip(List<Member> members) {
    final adminCount = members.where((m) => m.role == 'admin').length;
    final managerCount = members.where((m) => m.role == 'manager').length;
    final designerCount = members.where((m) => m.role == 'designer').length;
    final deliveryCount = members.where((m) => m.role == 'delivery').length;
    final viewerCount = members.where((m) => m.role == 'viewer').length;

    return Row(
      children: [
      KpiCard(
        icon: Icons.people_outline,
        iconColor: _T.blue,
        iconBg: _T.blue50,
        label: 'Total Members',
        value: '${members.length}',
        sub: 'In your organization',
        subPositive: null,
      ),
      const SizedBox(width: 12),
      KpiCard(
        icon: Icons.admin_panel_settings_outlined,
        iconColor: _T.purple,
        iconBg: _T.purple50,
        label: 'Admins',
        value: '$adminCount',
        sub: 'Full access',
        subPositive: null,
      ),
      const SizedBox(width: 12),
      KpiCard(
        icon: Icons.work_outline,
        iconColor: _T.green,
        iconBg: _T.green50,
        label: 'Staff',
        value: '${managerCount + designerCount + deliveryCount}',
        sub: 'Active contributors',
        subPositive: true,
      ),
    ]);
  }

  Widget _buildToolbar(List<Member> members) {
    final adminCount = members.where((m) => m.role == 'admin').length;
    final managerCount = members.where((m) => m.role == 'manager').length;

    return _Toolbar(
      searchCtrl: _searchCtrl,
      filter: _filter,
      viewMode: _viewMode,
      adminCount: adminCount,
      managerCount: managerCount,
      onSearchChanged: (v) => setState(() => _search = v),
      onFilterChanged: (f) => setState(() => _filter = f),
      onViewModeChanged: (m) => setState(() => _viewMode = m),
      onInviteMember: () => _showInviteMemberSheet(context),
    );
  }

  void _showChangeNotification(BuildContext context, MemberChangeEvent event) {
    String message;
    IconData icon;
    Color color;

    switch (event.type) {
      case MemberChangeType.created:
      case MemberChangeType.invited:
        message = 'New member invited';
        icon = Icons.person_add;
        color = _T.green;
        break;
      case MemberChangeType.updated:
        message = 'Member updated';
        icon = Icons.update;
        color = _T.blue;
        break;
      case MemberChangeType.deleted:
      case MemberChangeType.removed:
        message = 'Member removed';
        icon = Icons.person_remove;
        color = _T.red;
        break;
      case MemberChangeType.roleChanged:
        message = 'Member role changed';
        icon = Icons.security;
        color = _T.amber;
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showInviteMemberSheet(BuildContext context, {Member? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _InviteMemberSheet(existing: existing),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// REMAINING COMPONENTS (Table, Grid, Toolbar, etc.)
// ─────────────────────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────────────────────
// TOOLBAR
// ─────────────────────────────────────────────────────────────────────────────
class _Toolbar extends StatelessWidget {
  final TextEditingController searchCtrl;
  final _FilterRole filter;
  final TableViewMode viewMode;
  final int adminCount, managerCount;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<_FilterRole> onFilterChanged;
  final ValueChanged<TableViewMode> onViewModeChanged;
  final VoidCallback onInviteMember;

  const _Toolbar({
    required this.searchCtrl,
    required this.filter,
    required this.viewMode,
    required this.adminCount,
    required this.managerCount,
    required this.onSearchChanged,
    required this.onFilterChanged,
    required this.onViewModeChanged,
    required this.onInviteMember,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _T.white,
        border: Border.all(color: _T.slate200),
        borderRadius: BorderRadius.circular(_T.rLg),
      ),
      child: Row(
        children: [
          // Search field
          Expanded(
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                color: _T.slate50,
                border: Border.all(color: _T.slate200),
                borderRadius: BorderRadius.circular(_T.r),
              ),
              child: TextField(
                controller: searchCtrl,
                onChanged: onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search members...',
                  hintStyle: const TextStyle(color: _T.slate400, fontSize: 13),
                  prefixIcon: const Icon(Icons.search, size: 16, color: _T.slate400),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
                style: const TextStyle(fontSize: 13, color: _T.ink),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Role filter chips
          _FilterChip(
            label: 'All',
            isActive: filter == _FilterRole.all,
            onTap: () => onFilterChanged(_FilterRole.all),
          ),
          const SizedBox(width: 6),
          _FilterChip(
            label: 'Admin',
            count: adminCount,
            isActive: filter == _FilterRole.admin,
            onTap: () => onFilterChanged(_FilterRole.admin),
          ),
          const SizedBox(width: 6),
          _FilterChip(
            label: 'Manager',
            count: managerCount,
            isActive: filter == _FilterRole.manager,
            onTap: () => onFilterChanged(_FilterRole.manager),
          ),
          const SizedBox(width: 12),

          // View mode toggle
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: _T.slate100,
              borderRadius: BorderRadius.circular(_T.r),
            ),
            child: Row(
              children: [
                _ViewToggleBtn(
                  icon: Icons.table_chart_rounded,
                  isActive: viewMode == TableViewMode.table,
                  onTap: () => onViewModeChanged(TableViewMode.table),
                ),
                const SizedBox(width: 2),
                _ViewToggleBtn(
                  icon: Icons.grid_3x3_rounded,
                  isActive: viewMode == TableViewMode.grid,
                  onTap: () => onViewModeChanged(TableViewMode.grid),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Invite Member button
          Material(
            color: _T.blue,
            borderRadius: BorderRadius.circular(_T.r),
            child: InkWell(
              onTap: onInviteMember,
              borderRadius: BorderRadius.circular(_T.r),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add_rounded, size: 16, color: Colors.white),
                    const SizedBox(width: 6),
                    const Text(
                      'Invite Member',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int? count;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isActive,
    required this.onTap,
    this.count,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? _T.blue.withOpacity(0.12) : _T.slate100,
          border: Border.all(
            color: isActive ? _T.blue.withOpacity(0.3) : _T.slate200,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                color: isActive ? _T.blue : _T.ink3,
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: isActive ? _T.blue : _T.slate300,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
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

class _ViewToggleBtn extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _ViewToggleBtn({
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(_T.r),
        ),
        child: Icon(icon, size: 16, color: isActive ? _T.blue : _T.slate400),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MEMBER TABLE
// ─────────────────────────────────────────────────────────────────────────────
class _MemberTable extends StatelessWidget {
  final List<Member> members;
  final _SortField sort;
  final bool sortAsc;
  final Member? selected;
  final ValueChanged<_SortField> onSort;
  final ValueChanged<Member> onSelect;
  final ValueChanged<Member> onEdit;

  const _MemberTable({
    required this.members,
    required this.sort,
    required this.sortAsc,
    required this.selected,
    required this.onSort,
    required this.onSelect,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) return _EmptyState();

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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: _T.slate50,
              border: Border(bottom: BorderSide(color: _T.slate200)),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 48,
                  child: _ColHeader(''),
                ),
                Expanded(
                  flex: 3,
                  child: _SortHeader('Name', _SortField.name, sort, sortAsc, onSort),
                ),
                Expanded(
                  flex: 3,
                  child: _ColHeader('Email'),
                ),
                Expanded(
                  flex: 2,
                  child: _ColHeader('Role'),
                ),
                Expanded(
                  flex: 2,
                  child: _SortHeader('Joined', _SortField.joined, sort, sortAsc, onSort),
                ),
                SizedBox(width: 80, child: _ColHeader('Actions')),
              ],
            ),
          ),
          // Rows
          ...List.generate(members.length, (i) {
            final isLast = i == members.length - 1;
            return _MemberTableRow(
              member: members[i],
              isSelected: selected?.id == members[i].id,
              isLast: isLast,
              onTap: () => onSelect(members[i]),
              onEdit: () => onEdit(members[i]),
            );
          }),
        ],
      ),
    );
  }
}

class _SortHeader extends StatelessWidget {
  final String label;
  final _SortField field;
  final _SortField active;
  final bool asc;
  final ValueChanged<_SortField> onSort;

  const _SortHeader(this.label, this.field, this.active, this.asc, this.onSort);

  @override
  Widget build(BuildContext context) {
    final isActive = field == active;
    return GestureDetector(
      onTap: () => onSort(field),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: _T.slate400)),
          if (isActive)
            Icon(
              asc ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
              size: 12,
              color: _T.blue,
            ),
        ],
      ),
    );
  }
}

class _ColHeader extends StatelessWidget {
  final String text;
  const _ColHeader(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.5,
      color: _T.slate400,
    ),
  );
}

class _MemberTableRow extends StatefulWidget {
  final Member member;
  final bool isSelected, isLast;
  final VoidCallback onTap, onEdit;

  const _MemberTableRow({
    required this.member,
    required this.isSelected,
    required this.isLast,
    required this.onTap,
    required this.onEdit,
  });

  @override
  State<_MemberTableRow> createState() => _MemberTableRowState();
}

class _MemberTableRowState extends State<_MemberTableRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final m = widget.member;
    final roleColor = _getRoleColor(m.role);
    final roleBg = _getRoleColorBg(m.role);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: _hovered || widget.isSelected ? _T.blue.withOpacity(0.04) : Colors.transparent,
            border: Border(bottom: BorderSide(color: widget.isLast ? Colors.transparent : _T.slate200)),
          ),
          child: Row(
            children: [
              // Avatar
              SizedBox(
                width: 48,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _T.amber.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: _T.amber.withOpacity(0.3)),
                  ),
                  child: Center(
                    child: Text(
                      m.initials.isNotEmpty ? m.initials[0] : '?',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _T.amber,
                      ),
                    ),
                  ),
                ),
              ),
              // Name
              Expanded(
                flex: 3,
                child: Text(
                  m.name,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _T.ink),
                ),
              ),
              // Email
              Expanded(
                flex: 3,
                child: Text(
                  m.email,
                  style: const TextStyle(fontSize: 13, color: _T.slate500),
                ),
              ),
              // Role
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: roleBg,
                    borderRadius: BorderRadius.circular(_T.r),
                    border: Border.all(color: roleColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    m.role.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: roleColor,
                    ),
                  ),
                ),
              ),
              // Joined
              Expanded(
                flex: 2,
                child: Text(
                  _fmtDate(m.createdAt),
                  style: const TextStyle(fontSize: 12, color: _T.slate500),
                ),
              ),
              // Actions
              SizedBox(
                width: 80,
                child: _hovered
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _IconBtn(Icons.edit_outlined, widget.onEdit),
                          const SizedBox(width: 4),
                          _IconBtn(Icons.more_vert_rounded, () {}),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return _T.purple;
      case 'manager':
        return _T.blue;
      case 'designer':
        return _T.green;
      case 'delivery':
        return _T.amber;
      case 'viewer':
        return _T.slate400;
      default:
        return _T.slate400;
    }
  }

  Color _getRoleColorBg(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return _T.purple50;
      case 'manager':
        return _T.blue50;
      case 'designer':
        return _T.green50;
      case 'delivery':
        return _T.amber50;
      case 'viewer':
        return _T.slate100;
      default:
        return _T.slate100;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MEMBER GRID
// ─────────────────────────────────────────────────────────────────────────────
class _MemberGrid extends StatelessWidget {
  final List<Member> members;
  final Member? selected;
  final ValueChanged<Member> onSelect, onEdit;

  const _MemberGrid({
    required this.members,
    required this.selected,
    required this.onSelect,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) return _EmptyState();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.3,
      ),
      itemCount: members.length,
      itemBuilder: (_, i) => _MemberGridCard(
        member: members[i],
        isSelected: selected?.id == members[i].id,
        onTap: () => onSelect(members[i]),
        onEdit: () => onEdit(members[i]),
      ),
    );
  }
}

class _MemberGridCard extends StatefulWidget {
  final Member member;
  final bool isSelected;
  final VoidCallback onTap, onEdit;

  const _MemberGridCard({
    required this.member,
    required this.isSelected,
    required this.onTap,
    required this.onEdit,
  });

  @override
  State<_MemberGridCard> createState() => _MemberGridCardState();
}

class _MemberGridCardState extends State<_MemberGridCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final m = widget.member;
    final roleColor = _getRoleColor(m.role);
    final roleBg = _getRoleColorBg(m.role);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _T.white,
            border: Border.all(
              color: widget.isSelected ? _T.blue : _T.slate200,
              width: widget.isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(_T.rLg),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with avatar and actions
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _T.amber.withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: _T.amber.withOpacity(0.3), width: 1.5),
                    ),
                    child: Center(
                      child: Text(
                        m.initials.isNotEmpty ? m.initials[0] : '?',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: _T.amber,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (_hovered)
                    _IconBtn(Icons.edit_outlined, widget.onEdit),
                ],
              ),
              const SizedBox(height: 8),
              // Name
              Text(
                m.name,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _T.ink,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              // Email
              Text(
                m.email,
                style: const TextStyle(
                  fontSize: 11,
                  color: _T.slate500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              // Role badge + Joined
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: roleBg,
                      borderRadius: BorderRadius.circular(_T.r),
                      border: Border.all(color: roleColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      m.role.toUpperCase(),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: roleColor,
                      ),
                    ),
                  ),
                  Text(
                    _fmtDate(m.createdAt),
                    style: const TextStyle(
                      fontSize: 9,
                      color: _T.slate400,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return _T.purple;
      case 'manager':
        return _T.blue;
      case 'designer':
        return _T.green;
      case 'delivery':
        return _T.amber;
      case 'viewer':
        return _T.slate400;
      default:
        return _T.slate400;
    }
  }

  Color _getRoleColorBg(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return _T.purple50;
      case 'manager':
        return _T.blue50;
      case 'designer':
        return _T.green50;
      case 'delivery':
        return _T.amber50;
      case 'viewer':
        return _T.slate100;
      default:
        return _T.slate100;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MEMBER DETAIL PANEL — slides in from right
// ─────────────────────────────────────────────────────────────────────────────
class _MemberDetailPanel extends StatelessWidget {
  final Member member;
  final VoidCallback onClose;
  final VoidCallback onEdit;
  final VoidCallback? onRemove;       // null → hide Remove (e.g. current user)
  final VoidCallback? onResendInvite; // optional extra action

  const _MemberDetailPanel({
    required this.member,
    required this.onClose,
    required this.onEdit,
    this.onRemove,
    this.onResendInvite,
  });

  // ── Helpers ────────────────────────────────────────────────────────────────

  bool get _recentlyActive => true;

  Widget _buildAvatar() {
    final roleColor = _RoleBadge._color(member.role);

    // if (member.avatarUrl != null) {
    //   return Stack(
    //     clipBehavior: Clip.none,
    //     children: [
    //       CircleAvatar(
    //         radius: 34,
    //         backgroundImage: NetworkImage(member.avatarUrl!),
    //       ),
    //       Positioned(
    //         bottom: 0,
    //         right: 0,
    //         child: _ActivityDot(isActive: _recentlyActive),
    //       ),
    //     ],
    //   );
    // }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            color: roleColor.withOpacity(0.12),
            shape: BoxShape.circle,
            border: Border.all(color: roleColor.withOpacity(0.3), width: 2),
          ),
          child: Center(
            child: Text(
              member.initials,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: roleColor,
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 2,
          right: 2,
          child: _ActivityDot(isActive: _recentlyActive),
        ),
      ],
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final m = member;

    return Container(
      width: 280,
      decoration: const BoxDecoration(
        color: _T.white,
        border: Border(left: BorderSide(color: _T.slate200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ─────────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: _T.slate200)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Member Details',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _T.ink,
                  ),
                ),
                _IconBtn(
                  Icons.close_rounded,
                  onClose,
                  tooltip: 'Close panel',
                ),
              ],
            ),
          ),

          // ── Scrollable body ────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar + name + role
                  Center(
                    child: Column(
                      children: [
                        _buildAvatar(),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              m.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: _T.ink,
                              ),
                            ),
                            if (m.isCurrentUser) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _T.blue50,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                      color: _T.blue.withOpacity(0.3)),
                                ),
                                child: const Text(
                                  'YOU',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: _T.blue,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        _RoleBadge(m.role),
                        const SizedBox(height: 4),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Contact ────────────────────────────────────────────────
                  _DetailSection(
                    'Contact',
                    [
                      _DetailRow(
                        Icons.email_outlined,
                        m.email,
                        label: 'Email address',
                        copyable: true,
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // ── Organization ───────────────────────────────────────────
                  _DetailSection(
                    'Organization',
                    [
                      _DetailRow(
                        Icons.business_outlined,
                        m.role.capitalize(),
                        label: 'Department',
                      ),
                      _DetailRow(
                        Icons.calendar_today_outlined,
                        _fmtDateLong(m.createdAt),
                        label: 'Joined',
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Extra spacing so footer shadow isn't clipped
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),

          // ── Footer actions ─────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: const BoxDecoration(
              color: _T.white,
              border: Border(top: BorderSide(color: _T.slate200)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Primary: Edit Role (always shown)
                _PrimaryButton(
                  icon: Icons.edit_rounded,
                  label: 'Edit Role',
                  color: _T.blue,
                  onTap: onEdit,
                ),

                // Resend invite (optional)
                if (onResendInvite != null) ...[
                  const SizedBox(height: 8),
                  _OutlineButton(
                    icon: Icons.send_rounded,
                    label: 'Resend Invitation',
                    color: _T.slate500,
                    onTap: onResendInvite!,
                  ),
                ],

                // Remove (hidden for current user)
                if (onRemove != null && !m.isCurrentUser) ...[
                  const SizedBox(height: 8),
                  _OutlineButton(
                    icon: Icons.person_remove_outlined,
                    label: 'Remove Member',
                    color: _T.red,
                    onTap: onRemove!,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Small square icon button used throughout the panel.
class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;
  final Color? bgColor;
  final String? tooltip;

  const _IconBtn(
    this.icon,
    this.onTap, {
    this.color,
    this.bgColor,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final btn = Material(
      color: bgColor ?? Colors.transparent,
      borderRadius: BorderRadius.circular(_T.rSm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_T.rSm),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 18, color: color ?? _T.slate500),
        ),
      ),
    );
    return tooltip != null ? Tooltip(message: tooltip!, child: btn) : btn;
  }
}

/// Section header label (e.g. "Contact", "Membership").
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: _T.slate400,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

/// A labelled info row with an icon, label, and copyable value.
class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String value;
  final String? label;
  final bool copyable;
  final Color? iconColor;

  const _DetailRow(
    this.icon,
    this.value, {
    this.label,
    this.copyable = false,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: _T.slate100,
              borderRadius: BorderRadius.circular(_T.rSm),
            ),
            child: Icon(icon, size: 15, color: iconColor ?? _T.slate500),
          ),
          const SizedBox(width: 10),
          // Label + value
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (label != null)
                  Text(
                    label!,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _T.slate400,
                      letterSpacing: 0.3,
                    ),
                  ),
                if (label != null) const SizedBox(height: 1),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _T.ink,
                  ),
                ),
              ],
            ),
          ),
          // Copy button
          if (copyable)
            _IconBtn(
              Icons.copy_rounded,
              () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Copied: $value'),
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(_T.r),
                    ),
                  ),
                );
              },
              tooltip: 'Copy',
            ),
        ],
      ),
    );
  }
}

/// Card-style section containing a label + list of _DetailRows.
class _DetailSection extends StatelessWidget {
  final String title;
  final List<Widget> rows;

  const _DetailSection(this.title, this.rows);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _T.slate50,
        borderRadius: BorderRadius.circular(_T.r),
        border: Border.all(color: _T.slate200),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(title),
          ...rows,
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

/// Pill-shaped role badge.
class _RoleBadge extends StatelessWidget {
  final String role;
  const _RoleBadge(this.role);

  static Color _color(String r) {
    switch (r.toLowerCase()) {
      case 'admin':    return _T.purple;
      case 'manager':  return _T.blue;
      case 'designer': return _T.green;
      case 'delivery': return _T.amber;
      default:         return _T.slate400;
    }
  }

  static Color _bg(String r) {
    switch (r.toLowerCase()) {
      case 'admin':    return _T.purple50;
      case 'manager':  return _T.blue50;
      case 'designer': return _T.green50;
      case 'delivery': return _T.amber50;
      default:         return _T.slate100;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _color(role);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _bg(role),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: c.withOpacity(0.3)),
      ),
      child: Text(
        role.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: c,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// Online / offline indicator dot.
class _ActivityDot extends StatelessWidget {
  final bool isActive;
  const _ActivityDot({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: isActive ? _T.green : _T.slate400,
        shape: BoxShape.circle,
        border: Border.all(color: _T.white, width: 1.5),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// REUSABLE FOOTER BUTTONS
// ─────────────────────────────────────────────────────────────────────────────

class _PrimaryButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _PrimaryButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(_T.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_T.r),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 11),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15, color: Colors.white),
              const SizedBox(width: 7),
              Text(
                label,
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
}

class _OutlineButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _OutlineButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(_T.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_T.r),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: color.withOpacity(0.35)),
            borderRadius: BorderRadius.circular(_T.r),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
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
// INVITE MEMBER BOTTOM SHEET
// ─────────────────────────────────────────────────────────────────────────────
class _InviteMemberSheet extends StatelessWidget {
  final Member? existing;
  const _InviteMemberSheet({this.existing});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: AnimatedScale(
        scale: 1.0,
        duration: const Duration(milliseconds: 300),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: _T.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                existing != null ? 'Edit Member' : 'Invite Member',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _T.ink,
                ),
              ),
              const SizedBox(height: 20),
              // Placeholder for form
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _T.slate50,
                  borderRadius: BorderRadius.circular(_T.rLg),
                  border: Border.all(color: _T.slate200),
                ),
                child: const Text(
                  'Invite/Edit form to be implemented',
                  style: TextStyle(color: _T.slate400),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
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
          Icon(Icons.people_outline, size: 48, color: _T.slate300),
          const SizedBox(height: 16),
          const Text(
            'No members found',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _T.ink3),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try adjusting your filters or search terms',
            style: TextStyle(fontSize: 13, color: _T.slate500),
          ),
        ],
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────────────────────────────────────────
String _fmtDate(DateTime d) {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${months[d.month - 1]} ${d.day}, ${d.year}';
}

String _fmtDateLong(DateTime d) {
  const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
  return '${months[d.month - 1]} ${d.day}, ${d.year}';
}
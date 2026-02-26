// ─────────────────────────────────────────────────────────────────────────────
// TOOLBAR
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:smooflow/enums/filter_status.dart';
import 'package:smooflow/enums/table_view_mode.dart';

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

class Toolbar extends StatelessWidget {
  final TextEditingController searchCtrl;
  final FilterStatus filter;
  final TableViewMode viewMode;
  final int activeCount, pendingCount, inactiveCount;
  final ValueChanged<String>        onSearchChanged;
  final ValueChanged<FilterStatus> onFilterChanged;
  final ValueChanged<TableViewMode>     onViewModeChanged;
  final VoidCallback                onAddClient;

  const Toolbar({
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
        // _FilterChip(
        //   label: 'All',
        //   isActive: filter == _FilterStatus.all,
        //   onTap: () => onFilterChanged(_FilterStatus.all),
        // ),
        // const SizedBox(width: 4),
        // _FilterChip(
        //   label: 'Active',
        //   count: activeCount,
        //   dotColor: _T.green,
        //   isActive: filter == _FilterStatus.active,
        //   onTap: () => onFilterChanged(_FilterStatus.active),
        // ),
        // const SizedBox(width: 4),
        // _FilterChip(
        //   label: 'Pending',
        //   count: pendingCount,
        //   dotColor: _T.amber,
        //   isActive: filter == _FilterStatus.pending,
        //   onTap: () => onFilterChanged(_FilterStatus.pending),
        // ),
        // const SizedBox(width: 4),
        // _FilterChip(
        //   label: 'Inactive',
        //   count: inactiveCount,
        //   dotColor: _T.slate400,
        //   isActive: filter == _FilterStatus.inactive,
        //   onTap: () => onFilterChanged(_FilterStatus.inactive),
        // ),
        // const SizedBox(width: 10),

        // ── View toggle ────────────────────────────────────────────────
        Container(
          height: 32,
          decoration: BoxDecoration(
              color: _T.slate100,
              borderRadius: BorderRadius.circular(_T.r)),
          child: Row(children: [
            _ViewToggleBtn(
              icon: Icons.table_rows_outlined,
              isActive: viewMode == TableViewMode.table,
              onTap: () => onViewModeChanged(TableViewMode.table),
            ),
            _ViewToggleBtn(
              icon: Icons.grid_view_rounded,
              isActive: viewMode == TableViewMode.grid,
              onTap: () => onViewModeChanged(TableViewMode.grid),
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
                  Text('Add Company',
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


import 'package:flutter/material.dart';
import 'package:smooflow/components/permission_gate.dart';
import 'package:smooflow/core/app_routes.dart';
import 'package:smooflow/enums/user_permission.dart';
import 'package:smooflow/helpers/dashboard_actions_fab_helper.dart';

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

class DashboardActionsFab extends StatefulWidget {
  const DashboardActionsFab({super.key, required this.fabHelper});

  final DashboardActionsFabHelper fabHelper;

  @override
  State<DashboardActionsFab> createState() => _DashboardActionsFabState();
}

class _DashboardActionsFabState extends State<DashboardActionsFab> with TickerProviderStateMixin {  

  @override
  void initState() {
    super.initState();
    
    widget.fabHelper.initialize(this);
  }


  @override
  void dispose() {
    widget.fabHelper.dispose();
    super.dispose();
  }

  void onNewProject() async {
    await AppRoutes.navigateTo(context, AppRoutes.addProject);
    setState(() {});
  }
  void onSchedulePrint() async {
    await AppRoutes.navigateTo(context, AppRoutes.schedulePrintStages);
    setState(() {});
  }
  void onAddPrinter() async {
    await AppRoutes.navigateTo(context, AppRoutes.addPrinter);
    setState(() {});
  }
  

  Widget _buildFab() {
    final actions = [
      // _FabAction(Icons.add_task_rounded,       'New Task',     _T.brandBlue, onNewTask),
      _FabAction(Icons.folder_special_rounded, 'New Project',  _T.purple,    onNewProject),
      _FabAction(Icons.print_rounded,          'Schedule Print',_T.green,    onSchedulePrint),
      _FabAction(Icons.add_rounded,            'Add Printer',   _T.amber,    onAddPrinter),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Expanded action items
        ...actions.asMap().entries.map((e) {
          final delay = (actions.length - e.key) * 40;
          return PermissionGate(
            permission: [UserPermission.addProjectAction, UserPermission.schedulePrintAction, UserPermission.addPrinterAction][e.key],
            child: AnimatedBuilder(
              animation: widget.fabHelper.fabCtrl,
              builder: (_, __) {
                final t = widget.fabHelper.fabCtrl.value;
                return Opacity(
                  opacity: t,
                  child: Transform.translate(
                    offset: Offset(0, (1 - t) * 20),
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 10),
                      child: _fabActionRow(e.value),
                    ),
                  ),
                );
              },
            ),
          );
        }).toList(),
        SizedBox(height: 4),
        // Main FAB
        GestureDetector(
          onTap: () {
            setState(() => widget.fabHelper.fabOpen = !widget.fabHelper.fabOpen);
            widget.fabHelper.fabOpen ? widget.fabHelper.fabCtrl.forward() : widget.fabHelper.fabCtrl.reverse();
          },
          child: AnimatedBuilder(
            animation: widget.fabHelper.fabRotation,
            builder: (_, child) => Transform.rotate(
              angle: widget.fabHelper.fabRotation.value * 3.14159 * 2,
              child: child,
            ),
            child: Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                color: _T.brandBlue,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: _T.brandBlue.withOpacity(0.35),
                      blurRadius: 16, offset: Offset(0, 6)),
                ],
              ),
              child: Icon(Icons.add_rounded, color: Colors.white, size: 28),
            ),
          ),
        ),
      ],
    );
  }

  Widget _fabActionRow(_FabAction a) {
    return GestureDetector(
      onTap: () {
        setState(() => widget.fabHelper.fabOpen = false);
        widget.fabHelper.fabCtrl.reverse();
        a.onTap?.call();
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: _T.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _T.border),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06),
                  blurRadius: 8, offset: Offset(0, 2))],
            ),
            child: Text(a.label,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                    color: _T.textPrimary)),
          ),
          SizedBox(width: 10),
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: a.color, shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: a.color.withOpacity(0.3),
                  blurRadius: 8, offset: Offset(0, 3))],
            ),
            child: Icon(a.icon, color: Colors.white, size: 19),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 24, right: 20,
      child: _buildFab(),
    );
  }
}

class _FabAction {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  const _FabAction(this.icon, this.label, this.color, this.onTap);
}
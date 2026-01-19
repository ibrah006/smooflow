import 'package:flutter/material.dart';
import 'package:smooflow/enums/user_permission.dart';
import 'package:smooflow/core/services/login_service.dart';

class PermissionGate extends StatelessWidget {
  final UserPermission permission;
  final Widget child;
  final Widget? fallback;

  const PermissionGate({
    required this.permission,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {

    debugPrint("user role: ${LoginService.currentUser!.role}, expected permission: $permission");

    return LoginService.can(permission)
        ? child
        : (fallback ?? const SizedBox.shrink());
  }
}

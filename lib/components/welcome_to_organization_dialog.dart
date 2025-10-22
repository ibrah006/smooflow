import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/constants.dart';
import 'package:smooflow/enums/status.dart';
import 'package:smooflow/models/organization.dart';
import 'package:smooflow/providers/organization_provider.dart';
import 'package:smooflow/screens/flash_screen.dart';

/// This dialog is to be shown when the user auto joins an organization by private domain
class WelcomeToOrganizationDialog extends ConsumerStatefulWidget {
  final Organization organization;
  WelcomeToOrganizationDialog({super.key, required this.organization});

  @override
  ConsumerState<WelcomeToOrganizationDialog> createState() =>
      _WelcomeToOrganizationDialogState();
}

class _WelcomeToOrganizationDialogState
    extends ConsumerState<WelcomeToOrganizationDialog> {
  String? selectedRole;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(16);

    final departments = Status.values.where((item) {
      return item != Status.cancelled;
    });

    final state = ref.read(organizationNotifierProvider);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: borderRadius),
      contentPadding: EdgeInsets.zero,
      content: Container(
        width: 340, // similar proportion as in the image
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          color: Colors.white,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 28.0,
              ),
              child: Column(
                children: [
                  // Building icon
                  Icon(Icons.apartment_rounded, size: 65, color: colorPrimary),
                  const SizedBox(height: 16),

                  // Title
                  Text(
                    'Welcome to\n${widget.organization.name}!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 27,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Subtitle
                  Text(
                    'You’ve successfully joined the organization.\n\n'
                    'To get started, please select your role or department within the organization',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey.shade900,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Dropdown
                  DropdownButtonFormField<String>(
                    icon: Transform.rotate(
                      angle: pi / 2,
                      child: Icon(Icons.chevron_right),
                    ),
                    decoration: InputDecoration(
                      hintText: "Select Role",
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: Colors.grey.shade200,
                          width: 1.25,
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: Colors.grey.shade200,
                          width: 1.25,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: Colors.grey.shade200,
                          width: 1.25,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                    ),
                    items: List.generate(departments.length, (index) {
                      final status = departments.elementAt(index).name;
                      return DropdownMenuItem(
                        value: status,
                        child: Text(
                          "${status[0].toUpperCase()}${status.substring(1)}",
                        ),
                      );
                    }),
                    onChanged: (value) {
                      selectedRole = value;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Continue button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onPressed: () async {
                        selectedRole = selectedRole?.trim();

                        if (selectedRole == null ||
                            (selectedRole?.isEmpty ?? false)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Please select a Role")),
                          );
                          return;
                        }
                        // join organization
                        await ref
                            .read(organizationNotifierProvider.notifier)
                            .joinOrganization(
                              widget.organization.id,
                              role: selectedRole!,
                            );

                        final state = ref.read(organizationNotifierProvider);

                        if (state.error != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                state.error ?? "Error accepting invitation",
                              ),
                            ),
                          );
                          return;
                        }

                        // navigate
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (context) => FlashScreen(),
                          ),
                          (Route<dynamic> route) => false,
                        );
                      },
                      child: Row(
                        spacing: 10,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Continue',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                          const Icon(
                            Icons.arrow_right_alt,
                            color: Colors.white,
                            size: 27,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Cancel button
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        overlayColor: Colors.grey.shade500,
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(fontSize: 15, color: Colors.black54),
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

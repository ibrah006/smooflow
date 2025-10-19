import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class InviteMemberScreen extends ConsumerWidget {
  const InviteMemberScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emailController = TextEditingController();
    String? selectedRole;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Invite Members',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Invite your teammates to join your organization.",
              style: TextStyle(fontSize: 15, color: Colors.black54),
            ),
            const SizedBox(height: 24),

            // Invite card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Invite by Email",
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  const SizedBox(height: 12),

                  // Email TextField
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: "Enter email address",
                      prefixIcon: const Icon(
                        Icons.mail_outline_rounded,
                        size: 20,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF3F4F6),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Role Dropdown (optional)
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      hintText: "Select role (optional)",
                      filled: true,
                      fillColor: const Color(0xFFF3F4F6),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: "admin", child: Text("Admin")),
                      DropdownMenuItem(
                        value: "production",
                        child: Text("Production"),
                      ),
                      DropdownMenuItem(value: "design", child: Text("Design")),
                      DropdownMenuItem(value: "viewer", child: Text("Viewer")),
                    ],
                    onChanged: (value) {
                      selectedRole = value;
                    },
                  ),

                  const SizedBox(height: 20),

                  // Invite Button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 8),
                      ),
                      onPressed: () {
                        final email = emailController.text.trim();
                        if (email.isEmpty || !email.contains('@')) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Enter a valid email'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          return;
                        }

                        // TODO: call invite member repo
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Invitation sent to $email'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        emailController.clear();
                      },
                      icon: const Icon(Icons.send_rounded, size: 20),
                      label: const Text(
                        "Send Invitation",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Pending Invites Section
            const Text(
              "Pending Invitations",
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 2, // TODO: replace with pending invites
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final mockInvites = [
                    {"email": "alex@company.com", "role": "design"},
                    {"email": "jane@company.com", "role": "admin"},
                  ];
                  final invite = mockInvites[index];
                  return ListTile(
                    leading: const Icon(Icons.mail_rounded, size: 20),
                    title: Text(invite['email']!),
                    subtitle: Text(
                      invite['role']!,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    trailing: TextButton(
                      onPressed: () {},
                      style: TextButton.styleFrom(
                        overlayColor: Colors.redAccent.shade100,
                      ),
                      child: const Text(
                        "Cancel",
                        style: TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

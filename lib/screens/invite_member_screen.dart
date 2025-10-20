import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loading_overlay/loading_overlay.dart';
import 'package:smooflow/models/invitation.dart';
import 'package:smooflow/notifiers/invitation_notifier.dart';
import 'package:smooflow/providers/invitation_provider.dart';
import 'package:smooflow/services/login_service.dart';

class InviteMemberScreen extends ConsumerStatefulWidget {
  const InviteMemberScreen({super.key});

  @override
  ConsumerState<InviteMemberScreen> createState() => _InviteMemberScreenState();
}

class _InviteMemberScreenState extends ConsumerState<InviteMemberScreen> {
  final emailController = TextEditingController();
  String? selectedRole;

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      ref
          .watch(invitationNotifierProvider.notifier)
          .fetchInvitations(forceReload: false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final state = ref.watch(invitationNotifierProvider);

    final invitations = state.invitations;

    return LoadingOverlay(
      isLoading: state.isLoading,
      child: Scaffold(
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Invite by Email",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
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

                    // Role Dropdown
                    DropdownButtonFormField<String>(
                      value: selectedRole,
                      decoration: InputDecoration(
                        hintText: "Select role ",
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
                        DropdownMenuItem(
                          value: "design",
                          child: Text("Design"),
                        ),
                        DropdownMenuItem(
                          value: "viewer",
                          child: Text("Viewer"),
                        ),
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
                        onPressed: () async {
                          final email =
                              emailController.text.toLowerCase().trim();

                          if (email == LoginService.currentUser!.email) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Please enter a valid email address that's not your own.",
                                ),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            return;
                          }

                          if (email.isEmpty || !email.contains('@')) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Enter a valid email'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            return;
                          }

                          if (selectedRole == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please select a Role'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            return;
                          }

                          final invitationResponse = await ref
                              .watch(invitationNotifierProvider.notifier)
                              .sendInvitation(email: email, role: selectedRole);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              duration: Duration(seconds: 8),
                              content: Text(
                                invitationResponse ==
                                        InvitationSendStatus.success
                                    ? 'Successfully sent invite'
                                    : invitationResponse ==
                                        InvitationSendStatus.alreadyPending
                                    ? 'An invite to this user is already pending from your organization'
                                    : 'Failed to send invite to user',
                              ),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          emailController.clear();
                          selectedRole = null;
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
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount:
                    invitations.length, // TODO: replace with pending invites
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final invite = invitations[index];
                  return ListTile(
                    leading: const Icon(Icons.mail_rounded, size: 20),
                    title: Text(invite.email, style: textTheme.labelLarge),
                    subtitle: Text(
                      invite.role!,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    trailing: TextButton(
                      onPressed:
                          invite.status == InvitationStatus.cancelled
                              ? null
                              : () async {
                                late final String message;
                                try {
                                  await ref
                                      .watch(
                                        invitationNotifierProvider.notifier,
                                      )
                                      .cancelInvitation(invite.id);
                                  message = "Successfully cancelled invitation";
                                } catch (e) {
                                  message = e.toString();
                                }

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(message)),
                                );

                                setState(() {});
                              },
                      style: TextButton.styleFrom(
                        overlayColor: Colors.redAccent.shade100,
                        disabledForegroundColor: Colors.grey,
                        foregroundColor: Colors.redAccent,
                      ),
                      child: Text(
                        invite.status == InvitationStatus.cancelled
                            ? "Cancelled"
                            : "Cancel",
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

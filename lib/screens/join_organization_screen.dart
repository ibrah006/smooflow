import 'package:card_loading/card_loading.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/constants.dart';
import 'package:smooflow/models/invitation.dart';
import 'package:smooflow/notifiers/invitation_notifier.dart';
import 'package:smooflow/providers/invitation_provider.dart';
import 'package:smooflow/screens/flash_screen.dart';

class JoinOrganizationScreen extends ConsumerStatefulWidget {
  JoinOrganizationScreen({super.key});

  @override
  ConsumerState<JoinOrganizationScreen> createState() =>
      _JoinOrganizationScreenState();
}

class _JoinOrganizationScreenState
    extends ConsumerState<JoinOrganizationScreen> {
  final invitationIdController = TextEditingController();

  InvitationNotifier get invitationNotifier =>
      ref.read(invitationNotifierProvider.notifier);

  @override
  void initState() {
    super.initState();
    Future.microtask(() => invitationNotifier.fetchMyInvitations());
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final screenSize = MediaQuery.of(context).size;

    final width = screenSize.width;

    final paddingValue = width / 14.2909;

    final state = ref.watch(invitationNotifierProvider);

    // Current user invitations
    final userInvitations = state.getUserInvitations;

    final isLoading = state.isLoading;

    return Scaffold(
      backgroundColor: Color(0xFFf7f9fb),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              margin: EdgeInsets.symmetric(horizontal: paddingValue),
              padding: EdgeInsets.all(paddingValue),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.02),
                    spreadRadius: 5,
                    blurRadius: 10,
                    offset: Offset(0, 3), // changes position of shadow
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      spacing: 10,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(width: 42, "assets/icons/app_icon.png"),
                        Text(
                          "Smooflow",
                          style: textTheme.headlineMedium!.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Text(
                      "Join your Organization",
                      style: textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: const Text(
                        'Join Organization and Collaborate on projects',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
                    const SizedBox(height: 40),

                    TextFormField(
                      keyboardType: TextInputType.emailAddress,
                      controller: invitationIdController,
                      decoration: InputDecoration(
                        hintText: 'Enter invitation ID',
                        hintStyle: TextStyle(color: Colors.grey.shade600),
                        border: UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFe7eaf0)),
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFe7eaf0)),
                        ),
                        prefixIcon: Icon(Icons.apartment_rounded),
                      ),
                    ),
                    const SizedBox(height: 50),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () async {
                          // final name = nameController.text;
                        },
                        style: FilledButton.styleFrom(
                          disabledBackgroundColor: Colors.grey.shade200,
                        ),
                        child: Text("Join"),
                      ),
                    ),

                    // Invitations for current user
                    SizedBox(height: 20),
                    Wrap(
                      spacing: 10,
                      children: [
                        Text("Your Invitations", style: textTheme.titleMedium),
                        InkWell(
                          borderRadius: BorderRadius.circular(50),
                          onTap: () async {
                            if (!ref
                                .read(invitationNotifierProvider)
                                .canFetchCurrentUserInvitations) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    "Please refresh after some time",
                                  ),
                                ),
                              );
                              return;
                            }

                            // Refresh current user invitations
                            await invitationNotifier.fetchMyInvitations();

                            if (ref
                                .read(invitationNotifierProvider)
                                .getUserInvitations
                                .isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    "No Invitations found, please try again after a minute",
                                  ),
                                ),
                              );
                            }
                          },
                          child: Icon(
                            Icons.refresh_rounded,
                            color: colorPrimary,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    if (isLoading)
                      CardLoading(
                        height: 60,
                        borderRadius: BorderRadius.circular(10),
                      )
                    else if (userInvitations.isEmpty)
                      SizedBox(
                        height: 60,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: 10,
                          children: [
                            Icon(Icons.mark_email_read, color: colorPrimary),
                            Text("No Invitations"),
                          ],
                        ),
                      ),
                    ...List.generate(userInvitations.length, (index) {
                      final invite = userInvitations[index];
                      return ListTile(
                        contentPadding: EdgeInsets.symmetric(horizontal: 0),
                        title: Text(
                          invite.organizationName,
                          maxLines: 2,
                          overflow: TextOverflow.fade,
                        ),
                        leading: Icon(CupertinoIcons.building_2_fill),
                        trailing: FilledButton(
                          onPressed:
                              invite.status != InvitationStatus.pending
                                  ? null
                                  : () async {
                                    // Accept invitation
                                    await ref
                                        .read(
                                          invitationNotifierProvider.notifier,
                                        )
                                        .acceptInvitation(invite);

                                    final state = ref.read(
                                      invitationNotifierProvider,
                                    );

                                    if (!state.success) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            state.error ??
                                                "Error accepting invitation",
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
                          style: FilledButton.styleFrom(
                            minimumSize: Size.zero,
                            disabledBackgroundColor: Colors.grey.shade200,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            textStyle: textTheme.labelLarge!.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          child: Text(
                            invite.status == InvitationStatus.pending
                                ? "Accept"
                                : "${invite.status.name[0].toUpperCase()}${invite.status.name.substring(1)}",
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

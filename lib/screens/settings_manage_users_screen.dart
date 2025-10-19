import 'package:card_loading/card_loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loading_overlay/loading_overlay.dart';
import 'package:smooflow/components/settings_section.dart';
import 'package:smooflow/constants.dart';
import 'package:smooflow/models/member.dart';
import 'package:smooflow/models/organization.dart';
import 'package:smooflow/providers/member_provider.dart';
import 'package:smooflow/providers/organization_provider.dart';
import 'package:smooflow/screens/invite_member_screen.dart';
import 'package:smooflow/services/login_service.dart';

class SettingsManageUsersScreen extends ConsumerWidget {
  const SettingsManageUsersScreen({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final textTheme = Theme.of(context).textTheme;

    final Future<Organization> currentOrgFuture =
        ref.watch(organizationNotifierProvider.notifier).getCurrentOrganization;

    final membersFuture = ref.watch(memberNotifierProvider.notifier).members;

    return FutureBuilder(
      future: currentOrgFuture,
      builder: (context, snapshot) {
        final currentOrg = snapshot.data;

        return Scaffold(
          backgroundColor: backgroundDarker2,
          appBar:
              currentOrg != null
                  ? AppBar(
                    title: Text(currentOrg!.name),
                    backgroundColor: backgroundDarker2,
                  )
                  : null,
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => InviteMemberScreen()),
              );
            },
            child: Icon(Icons.add_rounded),
          ),
          body:
              currentOrg == null
                  ? LoadingOverlay(isLoading: true, child: SizedBox())
                  : SingleChildScrollView(
                    child: DefaultTextStyle(
                      style: textTheme.titleSmall!.copyWith(
                        color: Colors.grey.shade600,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          spacing: 30,
                          children: [
                            // Members list
                            FutureBuilder(
                              future: membersFuture,
                              builder: (context, snapshot) {
                                final members = snapshot.data;

                                return members == null
                                    ? CardLoading(
                                      height: 120,
                                      borderRadius: BorderRadius.circular(15),
                                    )
                                    : SettingsSection(
                                      title: "MEMBERS",
                                      items: List.generate(members.length, (
                                        index,
                                      ) {
                                        return ListTileItem(
                                          icon: Icons.account_circle_rounded,
                                          title: members[index].name,
                                          selectedOption:
                                              members[index].id ==
                                                      LoginService
                                                          .currentUser!
                                                          .id
                                                  ? "You/${members[index].role}"
                                                  : members[index].role,
                                        );
                                      }),
                                    );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
        );
      },
    );
  }
}

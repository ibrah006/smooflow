import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/components/settings_section.dart';
import 'package:smooflow/constants.dart';
import 'package:smooflow/models/organization.dart';
import 'package:smooflow/providers/organization_provider.dart';
import 'package:smooflow/screens/invite_member_screen.dart';
import 'package:smooflow/screens/settings_manage_users_screen.dart';
import 'package:smooflow/screens/settings_profile_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  Future<Organization> get currentOrgFuture =>
      ref.watch(organizationNotifierProvider.notifier).getCurrentOrganization;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: backgroundDarker2,
      appBar: AppBar(
        title: Text("Settings"),
        backgroundColor: backgroundDarker2,
      ),
      body: DefaultTextStyle(
        style: textTheme.titleLarge!.copyWith(fontWeight: FontWeight.w500),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            spacing: 23,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(),
              // Account section
              SettingsSection(
                title: "Account",
                items: [
                  ListTileItem(
                    icon: Icons.person_outline_rounded,
                    title: "Profile",
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SettingsProfileScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),

              // Preferences section
              SettingsSection(
                title: "Preferences",
                items: [
                  ListTileItem(
                    icon: Icons.dark_mode_rounded,
                    title: "Dark Mode",
                    initialSwitchState: false,
                  ),
                  ListTileItem(
                    icon: Icons.language_rounded,
                    title: "Language",
                    selectedOption: "English",
                  ),
                ],
              ),

              // Organization section
              FutureBuilder(
                future: currentOrgFuture,
                builder: (context, snapshot) {
                  final currentOrg = snapshot.data;

                  return SettingsSection(
                    title: "Organization",
                    items: [
                      ListTileItem(
                        icon: CupertinoIcons.building_2_fill,
                        title: "Organization",
                        selectedOption: currentOrg?.name ?? "",
                        isLoading: currentOrg == null,
                      ),
                      ListTileItem(
                        icon: Icons.manage_accounts_outlined,
                        title: "Manage Users",
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SettingsManageUsersScreen(),
                            ),
                          );
                        },
                      ),
                    ],
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

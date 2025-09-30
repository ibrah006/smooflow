import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:smooflow/components/settings_section.dart';
import 'package:smooflow/constants.dart';
import 'package:smooflow/services/login_service.dart';

class SettingsProfileScreen extends StatelessWidget {
  SettingsProfileScreen({super.key});

  final currentUser = LoginService.currentUser!;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: backgroundDarker2,
      appBar: AppBar(
        title: Text("Profile"),
        backgroundColor: backgroundDarker2,
      ),
      body: SingleChildScrollView(
        child: DefaultTextStyle(
          style: textTheme.titleSmall!.copyWith(color: Colors.grey.shade600),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              spacing: 30,
              children: [
                SizedBox(),

                // Personal info
                SettingsSection(
                  title: "PERSONAL INFORMATION",
                  items: [
                    //
                    ListTileItem(
                      icon: Icons.person_rounded,
                      title: "Name",
                      infoText: currentUser.name,
                    ),
                    ListTileItem(
                      icon: Icons.email_rounded,
                      title: "Email",
                      infoText: currentUser.email,
                    ),
                    ListTileItem(
                      icon: Icons.phone_rounded,
                      title: "Phone",
                      infoText: "-",
                    ),
                    ListTileItem(
                      icon: Icons.work_rounded,
                      title: "Role",
                      infoText:
                          "${currentUser.role[0].toUpperCase()}${currentUser.role.substring(1)}",
                    ),
                  ],
                ),

                // Login & Security
                SettingsSection(
                  title: "LOGIN AND SECURITY",
                  items: [
                    ListTileItem(
                      icon: Icons.key_rounded,
                      title: "Change Password",
                    ),
                  ],
                ),

                // Logout
                SettingsSection(
                  title: "AUTH",
                  items: [
                    ListTileItem(icon: Icons.logout_rounded, title: "Logout"),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

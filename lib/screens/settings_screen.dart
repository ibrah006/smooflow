import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:smooflow/components/settings_section.dart';
import 'package:smooflow/constants.dart';
import 'package:smooflow/screens/settings_profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
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
            ],
          ),
        ),
      ),
    );
  }
}

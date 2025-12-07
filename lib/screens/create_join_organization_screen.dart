import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/components/welcome_to_organization_dialog.dart';
import 'package:smooflow/models/organization.dart';
import 'package:smooflow/core/app_routes.dart';

class CreateJoinOrganizationScreen extends ConsumerWidget {
  const CreateJoinOrganizationScreen({super.key, this.autoInviteOrganization});

  final Organization? autoInviteOrganization;

  @override
  Widget build(BuildContext context, ref) {
    final textTheme = Theme.of(context).textTheme;

    final screenSize = MediaQuery.of(context).size;

    final width = screenSize.width;

    final paddingValue = width / 14.2909;

    return Scaffold(
      backgroundColor: Color(0xFFf7f9fb),
      body: Center(
        child: Container(
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
                Text("Create or Join", style: textTheme.headlineLarge),
                SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.createOrganization,
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      iconSize: 28,
                      foregroundColor: Colors.black,
                      side: BorderSide(width: 1, color: Colors.grey.shade200),
                      textStyle: textTheme.titleMedium,
                      padding: EdgeInsets.symmetric(
                        vertical: 17,
                      ).copyWith(left: 25),
                      alignment: Alignment.centerLeft,
                    ),
                    label: Text("Create Organization"),
                    icon: Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Icon(Icons.add_circle_rounded),
                    ),
                  ),
                ),
                SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.joinOrganization,
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      iconSize: 28,
                      foregroundColor: Colors.black,
                      side: BorderSide(width: 1, color: Colors.grey.shade200),
                      textStyle: textTheme.titleMedium,
                      padding: EdgeInsets.symmetric(
                        vertical: 17,
                      ).copyWith(left: 25),
                      alignment: Alignment.centerLeft,
                    ),
                    label: Text("Join Organization"),
                    icon: Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Icon(Icons.people_rounded),
                    ),
                  ),
                ),
                SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.joinOrganization,
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      iconSize: 28,
                      foregroundColor: Colors.black,
                      side: BorderSide(width: 1, color: Colors.grey.shade200),
                      textStyle: textTheme.titleMedium,
                      padding: EdgeInsets.symmetric(
                        vertical: 17,
                      ).copyWith(left: 25),
                      alignment: Alignment.centerLeft,
                    ),
                    label: Text("Decide later"),
                    icon: Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Icon(Icons.explore_outlined),
                    ),
                  ),
                ),
                if (autoInviteOrganization != null) ...[
                  SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () async {
                        showCupertinoModalPopup(
                          context: context,
                          builder: (context) {
                            return WelcomeToOrganizationDialog(
                              organization: autoInviteOrganization!,
                            );
                          },
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        iconSize: 28,
                        textStyle: textTheme.titleMedium,
                        padding: EdgeInsets.symmetric(
                          vertical: 17,
                        ).copyWith(left: 25),
                        alignment: Alignment.centerLeft,
                      ),
                      label: Text("Join ${autoInviteOrganization!.name}"),
                      icon: Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: Icon(Icons.domain_rounded),
                      ),
                    ),
                  ),
                ],
                SizedBox(height: autoInviteOrganization == null ? 70 : 60),
                Text("Need help with this?"),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.createJoinOrgHelp,
                    );
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 6, horizontal: 20),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text("Learn More"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

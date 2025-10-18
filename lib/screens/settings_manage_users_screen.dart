import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loading_overlay/loading_overlay.dart';
import 'package:smooflow/components/settings_section.dart';
import 'package:smooflow/constants.dart';
import 'package:smooflow/models/organization.dart';
import 'package:smooflow/providers/member_provider.dart';
import 'package:smooflow/providers/organization_provider.dart';

class SettingsManageUsersScreen extends ConsumerWidget {
  const SettingsManageUsersScreen({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final textTheme = Theme.of(context).textTheme;

    final Future<Organization> currentOrgFuture =
        ref.watch(organizationNotifierProvider.notifier).getCurrentOrganization;

    final members = ref.watch(memberNotifierProvider.notifier).members;

    members.then((val) => print("members: $val"));

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
                            SizedBox(),
                            // Personal info
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

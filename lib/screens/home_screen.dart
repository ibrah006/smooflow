import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:smooflow/components/overview_card.dart';
import 'package:smooflow/constants.dart';
import 'package:smooflow/custom_button.dart';
import 'package:smooflow/providers/project_provider.dart';
import 'package:smooflow/search_bar.dart' as search_bar;
import 'package:smooflow/sections/quick_actions.dart';
import 'package:smooflow/sections/recent_projects_section.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      ref.read(projectNotifierProvider.notifier).load().then((value) {
        setState(() {});
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final activeProjectsLength =
        ref.watch(projectNotifierProvider.notifier).activeProjectsLength;

    return Scaffold(
      appBar: AppBar(
        title: Text("Smooflow"),
        actions: [
          IconButton(
            color: colorPrimary,
            onPressed: () {},
            iconSize: 43,
            icon: Icon(Icons.person_pin_sharp),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          spacing: 20,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              spacing: 12,
              children: [
                Expanded(child: search_bar.SearchBar()),
                CustomButton.icon(
                  icon: Icons.notifications_rounded,
                  onPressed: () {},
                ),
              ],
            ),
            // Dashboard content
            // Overview info
            Row(
              spacing: 15,
              children: [
                Expanded(
                  child: OverviewCard(
                    title: "Active Projects",
                    color: colorPrimary,
                    icon: SvgPicture.asset("assets/icons/flow.svg", width: 23),
                    value: activeProjectsLength.toString(),
                  ),
                ),
                Expanded(child: SizedBox()),
              ],
            ),
            // Quick actions
            Text("Quick Actions", style: textTheme.titleMedium),
            QuickActions(),

            RecentProjectsSection(),
            SafeArea(child: SizedBox()),
          ],
        ),
      ),
    );
  }
}

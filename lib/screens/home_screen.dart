import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:smooflow/components/overview_card.dart';
import 'package:smooflow/constants.dart';
import 'package:smooflow/custom_button.dart';
import 'package:smooflow/providers/project_provider.dart';
import 'package:smooflow/screens/settings_profile_screen.dart';
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

    final project = ref.watch(projectNotifierProvider.notifier);

    final activeProjectsLength = project.activeProjectsLength;
    final projectsCompletionRate = project.projectsProgressRate;

    return Scaffold(
      appBar: AppBar(
        title: Text("Smooflow"),
        actions: [
          IconButton.filled(
            color: Colors.black,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsProfileScreen(),
                ),
              );
            },
            iconSize: 27,
            style: IconButton.styleFrom(
              backgroundColor: colorPrimary.withValues(alpha: 0.08),
            ),
            icon: Icon(Icons.person_rounded),
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
                Expanded(
                  child: OverviewCard(
                    title: "Completion Rate",
                    color: colorPurple,
                    icon: Icon(
                      CupertinoIcons.chart_bar_square_fill,
                      color: colorPurple,
                    ),
                    value:
                        "${(projectsCompletionRate * 100).toStringAsFixed(0)}%",
                  ),
                ),
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

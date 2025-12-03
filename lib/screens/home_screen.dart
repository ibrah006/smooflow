import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:loading_overlay/loading_overlay.dart';
import 'package:smooflow/components/active_work_activity_log_card.dart';
import 'package:smooflow/components/overview_card.dart';
import 'package:smooflow/constants.dart';
import 'package:smooflow/custom_button.dart';
import 'package:smooflow/main.dart';
import 'package:smooflow/providers/project_provider.dart';
import 'package:smooflow/screens/add_printer_screen.dart';
import 'package:smooflow/screens/desktop_material_list_screen.dart';
import 'package:smooflow/screens/settings_profile_screen.dart';
import 'package:smooflow/components/search_bar.dart' as search_bar;
import 'package:smooflow/sections/quick_actions.dart';
import 'package:smooflow/sections/recent_projects_section.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with RouteAware {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => DesktopMaterialListScreen()),
        );
      }

      ref
          .read(projectNotifierProvider.notifier)
          .load(projectsLastAddedLocal: null)
          .then((value) async {
            setState(() {
              _isLoading = false;
            });
          });
    });
  }

  // Called when coming back to this screen
  @override
  void didPopNext() {
    super.didPopNext();

    Future.microtask(() {
      setState(() {});
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)! as PageRoute);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final project = ref.watch(projectNotifierProvider.notifier);

    final activeProjectsLength = project.activeProjectsLength;
    final projectsCompletionRate = project.projectsProgressRate;

    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Smooflow"),
          leading: Padding(
            padding: const EdgeInsets.all(10).copyWith(right: 0),
            child: Image.asset("assets/icons/app_icon.png"),
          ),
          actions: [
            Ink(
              decoration: BoxDecoration(
                color: const Color(0xFFF5F6FA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.person_outline),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SettingsProfileScreen(),
                    ),
                  );
                },
              ),
            ),
            SizedBox(width: 15),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
              ).copyWith(top: 15, bottom: 25),
              child: Row(
                spacing: 12,
                children: [
                  Expanded(child: search_bar.SearchBar()),
                  CustomButton.icon(
                    icon: Icons.notifications_rounded,
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Dashboard content
                    // Active work activity log card, if any
                    ActiveWorkActivityLogCard(),
                    // Overview info
                    Row(
                      spacing: 15,
                      children: [
                        Expanded(
                          child: OverviewCard(
                            title: "Active Projects",
                            color: colorPrimary,
                            icon: SvgPicture.asset(
                              "assets/icons/flow.svg",
                              width: 23,
                            ),
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
                                projectsCompletionRate == 0
                                    ? "N/a"
                                    : "${(projectsCompletionRate * 100).toStringAsFixed(0)}%",
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    // Quick actions
                    Text("Quick Actions", style: textTheme.titleMedium),
                    SizedBox(height: 20),
                    QuickActions(),
                    FilledButton(
                      onPressed:
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddPrinterScreen(),
                            ),
                          ),
                      child: Text("Add Printer"),
                    ),
                    SizedBox(height: 20),

                    RecentProjectsSection(),
                    SizedBox(height: 20),
                    SafeArea(child: SizedBox()),
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

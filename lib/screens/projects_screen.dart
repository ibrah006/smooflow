import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:smooflow/components/project_card_v2.dart';
import 'package:smooflow/providers/organization_provider.dart';
import 'package:smooflow/providers/project_provider.dart';
import 'package:smooflow/screens/add_project.dart';
import 'package:smooflow/components/search_bar.dart' as search_bar;

class ProjectsScreen extends ConsumerStatefulWidget {
  const ProjectsScreen({super.key});

  @override
  ConsumerState<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends ConsumerState<ProjectsScreen> {
  Future<void> _refreshProjects() async {
    final projectsLastAdded =
        ref.watch(organizationNotifierProvider).projectsLastAdded;
    await ref
        .watch(projectNotifierProvider.notifier)
        .load(projectsLastAddedLocal: projectsLastAdded);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final projects = ref.watch(projectNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: projects.isNotEmpty ? Text("Projects") : null,
        actions: [
          if (projects.isNotEmpty)
            IconButton.filled(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AddProjectScreen()),
                );
              },
              icon: Icon(Icons.add_rounded, color: Colors.white),
            ),
          SizedBox(width: 20),
        ],
      ),
      body:
          projects.isEmpty
              ? RefreshIndicator(
                onRefresh: _refreshProjects,
                child: ListView(
                  children: [
                    SizedBox(
                      height: (MediaQuery.of(context).size.height / 2) - 265,
                    ),
                    Center(
                      child: SizedBox(
                        width: 200,
                        child: Column(
                          spacing: 10,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SvgPicture.asset(
                              "assets/icons/no_projects_icon.svg",
                            ),
                            Text(
                              "No projects",
                              style: textTheme.headlineLarge!.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(),
                            Text(
                              "Click the button below to add a new project.",
                              textAlign: TextAlign.center,
                              style: textTheme.titleMedium!.copyWith(
                                color: Colors.grey.shade600,
                              ),
                            ),
                            SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AddProjectScreen(),
                                    ),
                                  );
                                },
                                child: Text("Add Project"),
                              ),
                            ),
                            SizedBox(height: kToolbarHeight),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              )
              : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 25,
                      vertical: 15,
                    ),
                    child: search_bar.SearchBar(),
                  ),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _refreshProjects,
                      child: ListView(
                        physics: AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.symmetric(horizontal: 25),
                        children:
                            projects.map((project) {
                              return ProjectCardV2(project);
                            }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
    );
  }
}

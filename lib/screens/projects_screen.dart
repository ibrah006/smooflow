import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:smooflow/components/project_card_v2.dart';
import 'package:smooflow/constants.dart';
import 'package:smooflow/providers/project_provider.dart';
import 'package:smooflow/screens/add_project.dart';
import 'package:smooflow/components/search_bar.dart' as search_bar;

class ProjectsScreen extends ConsumerStatefulWidget {
  const ProjectsScreen({super.key});

  @override
  ConsumerState<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends ConsumerState<ProjectsScreen> {
  InputDecoration _inputDecoration(
    String hint, {
    Color? backgroundColor,
    IconData? icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey, letterSpacing: 0),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      filled: backgroundColor != null,
      fillColor: backgroundColor,
      prefixIcon: icon != null ? Icon(icon, color: Colors.grey.shade400) : null,
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: colorError),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: colorBorderDark),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: colorBorderDark),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: colorBorderDark, width: 1.2),
      ),
    );
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
              ? Center(
                child: SizedBox(
                  width: 200,
                  child: Column(
                    spacing: 10,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset("assets/icons/no_projects_icon.svg"),
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
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(horizontal: 25),
                      child: Column(
                        spacing: 15,
                        children: [
                          ...projects.map((project) {
                            return ProjectCardV2(project);
                          }),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
    );
  }
}

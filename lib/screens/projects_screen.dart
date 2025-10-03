import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/components/project_card_v2.dart';
import 'package:smooflow/constants.dart';
import 'package:smooflow/extensions/date_time_format.dart';
import 'package:smooflow/providers/project_provider.dart';
import 'package:smooflow/screens/add_project.dart';

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
        title: Text("Projects"),
        actions: [
          IconButton.filled(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddProjectScreen()),
              );
            },
            icon: Icon(Icons.add_rounded),
            style: ButtonStyle(
              backgroundColor: WidgetStatePropertyAll(
                colorPrimary.withValues(alpha: .15),
              ),
              iconColor: WidgetStatePropertyAll(colorPrimary),
            ),
          ),
          SizedBox(width: 20),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 25),
        child: Column(
          spacing: 15,
          children: [
            if (projects.isEmpty) ...[
              SizedBox(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 10,
                children: [
                  Icon(Icons.folder_open, color: Colors.grey.shade700),
                  Text("No Projects Found", style: textTheme.bodyMedium),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 10,
                children: [
                  Icon(Icons.info_outline_rounded, color: Colors.grey.shade700),
                  Text("Click on + to create a project"),
                ],
              ),
            ] else ...[
              TextField(
                decoration: _inputDecoration(
                  "Search Projects...",
                  icon: Icons.search_rounded,
                  backgroundColor: Colors.white,
                ),
              ),
              ...projects.map((project) {
                return ProjectCardV2(project);
              }),
            ],
          ],
        ),
      ),
    );
  }
}

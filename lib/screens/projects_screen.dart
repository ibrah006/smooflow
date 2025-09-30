import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/components/project_card_v2.dart';
import 'package:smooflow/constants.dart';
import 'package:smooflow/extensions/date_time_format.dart';
import 'package:smooflow/providers/project_provider.dart';

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
      backgroundColor: Color(0xFFf7f9fb),
      appBar: AppBar(
        backgroundColor: Colors.grey.shade50,
        title: Text("Projects"),
        actions: [
          IconButton.filled(
            onPressed: () {},
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
            TextField(
              decoration: _inputDecoration(
                "Search Projects...",
                icon: Icons.search_rounded,
                backgroundColor: Colors.white,
              ),
            ),
            ...projects.map((project) {
              return ProjectCardV2(project);
              Container(
                padding: EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  spacing: 10,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            project.name,
                            style: textTheme.titleLarge,
                          ),
                        ),
                        Flexible(
                          child: Text(
                            project.dueDate?.formatDisplay ?? "NA",
                            style: textTheme.bodyMedium!.copyWith(
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      decoration: BoxDecoration(
                        color: colorPrimary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        project.status,
                        style: textTheme.labelMedium!.copyWith(
                          color: colorPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    LinearProgressIndicator(
                      value: 0.60,
                      color: colorPrimary,
                      backgroundColor: colorPrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

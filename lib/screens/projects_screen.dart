import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/constants.dart';

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
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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
    return Scaffold(
      appBar: AppBar(
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
          SizedBox(width: 10),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            TextField(
              decoration: _inputDecoration(
                "Search Projects...",
                icon: Icons.search_rounded,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

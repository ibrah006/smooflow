// lib/screens/project/project_details_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/constants.dart';
import 'package:smooflow/core/app_routes.dart';
import 'package:smooflow/core/args/project_args.dart';
import 'package:smooflow/enums/priorities.dart';
import 'package:smooflow/extensions/date_time_format.dart';
import 'package:smooflow/models/company.dart';
import 'package:smooflow/models/project.dart';
import 'package:smooflow/providers/project_provider.dart';
import 'package:smooflow/providers/task_provider.dart';
import 'package:smooflow/repositories/company_repo.dart';
import 'package:smooflow/screens/components/project_overall_progress_card.dart';

enum ProjectStage {
  planning,
  design,
  production,
  finishing,
  application,
  finished,
  cancelled,
}

enum ProgressStatus {
  completed,
  issue,
  inProgress,
}

class ProjectScreen extends ConsumerStatefulWidget {
  final String projectId;

  const ProjectScreen({Key? key, required this.projectId}) : super(key: key);

  @override
  ConsumerState<ProjectScreen> createState() => _ProjectScreenState();
}

class _ProjectScreenState extends ConsumerState<ProjectScreen> {
  late final Company clientCompany;

  void initializeClientCompany(String clientId) {
    try {
      clientCompany = CompanyRepo.companies.firstWhere((company) => company.id == clientId);
    } catch (e) {
      // already initialized
    }
  }

  @override
  void initState() {
    super.initState();

    Future.microtask(() async {
      await ref.watch(taskNotifierProvider.notifier).loadAll();
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final project = ref.watch(projectByIdProvider(widget.projectId))!;
    final name = project.name;

    initializeClientCompany(project.client.id);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
            color: Colors.white,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F7FA),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.arrow_back, color: Colors.black, size: 22),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Project Details',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF9CA3AF),
                              ),
                            ),
                          ],
                        ),
                      ),
                      InkWell(
                        onTap: () {},
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F7FA),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.more_vert, color: Colors.black, size: 22),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: _buildInformationTab(project),
          ),
        ],
      ),
    );
  }

  Widget _buildInformationTab(Project project) {
    final status = project.status;
    var priority = PriorityLevel.values.elementAt(project.priority).name;
    priority = priority[0].toUpperCase() + priority.substring(1);

    final startDate = project.estimatedProductionStart;
    final dueDate = project.dueDate;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 20),
      children: [
        // Current Stage Card
        Container(
          margin: EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Current Stage',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF9CA3AF),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.print, color: Color(0xFF2563EB), size: 20),
                    SizedBox(width: 8),
                    Text(
                      "${status[0].toUpperCase()}${status.substring(1)}",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Basic Information Card
        Container(
          margin: EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Basic Information',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 20),

              _buildInfoRow('Client', clientCompany.name),
              const SizedBox(height: 16),
              _buildInfoRow('Priority', priority, isHighlighted: true),
              const SizedBox(height: 16),
              if (startDate != null) _buildInfoRow('Start Date', startDate.formatDisplay!),
              const SizedBox(height: 16),
              if (dueDate != null) _buildInfoRow('End Date', dueDate.formatDisplay!),
            ],
          ),
        ),
        const SizedBox(height: 20),
        ProjectOverallProgressCard(
          projectId: widget.projectId,
          margin: EdgeInsets.symmetric(horizontal: 4),
          heroKey: kOverallProgressHeroKey,
          onPressed: () {
            AppRoutes.navigateTo(
                context, AppRoutes.projectProgress,
                arguments: ProjectArgs(projectId: widget.projectId));
          },
        ),
        // Description Card
        if (project.description != null && project.description!.isNotEmpty) ...[
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(24),
            margin: EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Description',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  project.description!,
                  style: TextStyle(
                    fontSize: 15,
                    color: Color(0xFF6B7280),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          )
        ],
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isHighlighted = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF9CA3AF),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: isHighlighted ? const Color(0xFFF59E0B) : Colors.black,
          ),
        ),
      ],
    );
  }
}
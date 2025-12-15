// lib/screens/project_progress_log_screen.dart
import 'package:card_loading/card_loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/components/help_timeline.dart';
import 'package:smooflow/constants.dart';
import 'package:smooflow/core/app_routes.dart';
import 'package:smooflow/core/args/task_args.dart';
import 'package:smooflow/extensions/date_time_format.dart';
import 'package:smooflow/models/progress_log.dart';
import 'package:smooflow/models/task.dart';
import 'package:smooflow/providers/progress_log_provider.dart';
import 'package:smooflow/providers/project_provider.dart';
import 'package:smooflow/providers/task_provider.dart';
import 'package:smooflow/screens/components/project_overall_progress_card.dart';

class ProjectProgressLogScreen extends ConsumerStatefulWidget {
  final String projectId;

  const ProjectProgressLogScreen({
    Key? key,
    required this.projectId,
  }) : super(key: key);

  @override
  ConsumerState<ProjectProgressLogScreen> createState() => _ProjectProgressLogScreenState();
}

class _ProjectProgressLogScreenState extends ConsumerState<ProjectProgressLogScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedJobFilter = 'All';

  late List<ProgressLog> progressLogs;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    Future.microtask(() {
      ref
          .read(
            progressLogsByProjectProvider(
              ProgressLogsByProviderArgs(widget.projectId),
            ),
          )
          .then((updatedFromDatabase) {
            progressLogs = updatedFromDatabase.progressLogs;

            _isLoading = false;
            setState(() {});
          });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final project = ref.watch(projectByIdProvider(widget.projectId))!;
    final appbarSubTitle = "${project.client.name} - ${project.name}";

    progressLogs = ref.watch(
      progressLogsByProjectProviderSimple(widget.projectId),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Progress Log',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
            ),
            Text(
              appbarSubTitle,
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(49),
          child: Container(
            color: Colors.white,
            child: Column(
              children: [
                TabBar(
                  controller: _tabController,
                  labelColor: const Color(0xFF2563EB),
                  unselectedLabelColor: const Color(0xFF94A3B8),
                  labelStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  indicatorColor: const Color(0xFF2563EB),
                  indicatorWeight: 2,
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: 'Timeline'),
                    Tab(text: 'Jobs'),
                  ],
                ),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTimelineTab(),
          _buildJobsTab(), // This now uses the moved code
        ],
      ),
    );
  }

  Widget _buildTimelineTab() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // Project Overview Card
        ProjectOverallProgressCard(projectId: widget.projectId, heroKey: kOverallProgressHeroKey),

        const SizedBox(height: 32),

        const Text(
          'Progress Timeline',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
            letterSpacing: -0.3,
          ),
        ),

        const SizedBox(height: 20),

        if (_isLoading) CardLoading(
          height: 100,
          borderRadius: BorderRadius.all(Radius.circular(10)),
          margin: EdgeInsets.only(bottom: 10),
        ) else if (progressLogs.isNotEmpty) ...progressLogs.map((progressLog)=> 
          // Timeline Items
          _buildTimelineItem(progressLog)
        )
        // No Progress Logs to display
        else HelpTimeline(projectId: widget.projectId),

        const SizedBox(height: 80),
      ],
    );
  }

  // Moved from ProjectScreen
  Widget _buildJobsTab() {
    // All unique progress log stages for this project - uniqie in terms of the status name
    // Don't include 'All' filter here

    final List<String> _availableJobStages = [];
    for (ProgressLog log in progressLogs) {
      if (!_availableJobStages.contains(log.status.name)) {
        _availableJobStages.add(log.status.name);
      }
    }
    
    return Column(
      children: [
        // Filter Chips
        Container(
          width: MediaQuery.of(context).size.width,
          color: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 15),
                  child: _buildJobFilterChip('All'),
                ),
                ..._availableJobStages.map((stage) =>
                    _buildJobFilterChip(_capitalizeFirst(stage))),
              ],
            ),
          ),
        ),

        // Jobs List
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: _getFilteredJobs().map((job) => _buildJobCard(job)).toList(),
          ),
        ),
      ],
    );
  }

  // Moved from ProjectScreen
  Widget _buildJobFilterChip(String label) {
    final isSelected = _selectedJobFilter == label;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () => setState(() => _selectedJobFilter = label),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? colorPrimary : const Color(0xFFF5F7FA),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : const Color(0xFF9CA3AF),
            ),
          ),
        ),
      ),
    );
  }

  // Moved from ProjectScreen
  Widget _buildJobCard(Task task) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          AppRoutes.navigateTo(context, AppRoutes.task, arguments: TaskArgs(task.id));
        },
        child: Ink(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              _buildStatusCircle(task.status, size: 40),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.person, size: 14, color: Color(0xFF9CA3AF)),
                        const SizedBox(width: 6),
                        // Text(
                        //   job['assignee'],
                        //   style: const TextStyle(
                        //     fontSize: 13,
                        //     color: Color(0xFF9CA3AF),
                        //   ),
                        // ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F7FA),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getStageLabel(task),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Moved from ProjectScreen
  List<Task> _getFilteredJobs() {
    // For Tasks for this Project
    final allTasks = ref.watch(taskNotifierProvider).where((task)=> task.projectId == widget.projectId).toList();
    if (_selectedJobFilter == 'All') {
      return allTasks; 
    }

    return allTasks.where((task) {
      return ref.watch(progressLogNotifierProvider.notifier).isTaskExistForProgressLogStatus(
        task: task,
        requiredLogStatus: _selectedJobFilter
      );
    }).toList();
  }

  // Moved from ProjectScreen
  String _getStageLabel(Task task) {

    // Each task can point to many progress logs
    // but for tesing, let's just fetch only one stage that's related to it

    final allProgressLogs = ref.watch(progressLogNotifierProvider);

    late final ProgressLog progressLog;
    try {
      progressLog = allProgressLogs.firstWhere((log)=> log.id == task.progressLogIds.first);
    } catch(e) {
      // Error occuring due to task not pointing to any progress log id, possibly because of major database migrations - old structure conflicting with newer migrations but not casuing any problems
      // Unkown Log
      return "Unkown";
    }
    final stage = ProjectStage.values.byName(progressLog.status.name);
    
    switch (stage) {
      case ProjectStage.planning:
        return 'Planning';
      case ProjectStage.design:
        return 'Design';
      case ProjectStage.production:
        return 'Production';
      case ProjectStage.finishing:
        return 'Finishing';
      case ProjectStage.application:
        return 'Application';
      case ProjectStage.finished:
        return 'Finished';
      case ProjectStage.cancelled:
        return 'Cancelled';
    }
  }

  // Moved from ProjectScreen
  Widget _buildStatusCircle(String taskStatus, {double size = 24}) {
    late final ProgressStatus status;
    print("status circle: ${taskStatus.toLowerCase()}");
    try {
      status = ProgressStatus.values.byName(taskStatus.toLowerCase());
    } catch(e) {
      status = ProgressStatus.pending;
    }
    Color color = _getStatusColor(status);
    IconData? icon;

    switch (status) {
      case ProgressStatus.completed:
        icon = size > 20 ? Icons.check_rounded : null;
        break;
      case ProgressStatus.issues:
        icon = Icons.priority_high_rounded;
        break;
      case ProgressStatus.inProgress:
        icon = size > 20 ? Icons.remove_rounded : null;
        break;
      case ProgressStatus.pending:
        icon = null;
        break;
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: icon != null
          ? Icon(icon, color: Colors.white, size: size * 0.55)
          : null,
    );
  }

  // Moved from ProjectScreen
  Color _getStatusColor(ProgressStatus status) {
    switch (status) {
      case ProgressStatus.completed:
        return const Color(0xFF2563EB);
      case ProgressStatus.issues:
        return const Color(0xFFEF4444);
      case ProgressStatus.inProgress:
        return const Color(0xFFF59E0B);
      case ProgressStatus.pending:
        return const Color(0xFFE2E8F0);
    }
  }

  // Moved from ProjectScreen
  String _capitalizeFirst(String text) {
    return text[0].toUpperCase() + text.substring(1);
  }

  // Original timeline methods remain the same
  Widget _buildTimelineItem(ProgressLog progressLog) {

    String stage = progressLog.status.name[0].toUpperCase() + progressLog.status.name.substring(1);
    String date = progressLog.dueDate.formatDisplay?? "N/A";
    ProgressStatus status = progressLog.isCompleted? ProgressStatus.completed : progressLog.hasIssues? ProgressStatus.issues : ProgressStatus.inProgress;
    String description = progressLog.description?? "No description";
    bool isFirst = false;
    bool isLast = false;

    final allTasks = ref.watch(taskNotifierProvider);
    final tasks = allTasks.where((task) {
      return task.progressLogIds.contains(progressLog.id);
    });

    List<JobItem> jobs = tasks.map((task)=> JobItem(task.name, task.dateCompleted!=null)).toList();
    
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator column
          Column(
            children: [
              if (!isFirst)
                Container(
                  width: 2,
                  height: 24,
                  color: const Color(0xFFE2E8F0),
                ),
              _buildStatusIndicator(status),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: const Color(0xFFE2E8F0),
                  ),
                ),
            ],
          ),

          const SizedBox(width: 20),

          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: MaterialButton(
                onPressed: () {
                  AppRoutes.navigateTo(context, AppRoutes.addProjectProgressView);
                },
                child: Ink(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: status == ProgressStatus.issues
                        ? Border.all(color: const Color(0xFFEF4444), width: 1.5)
                        : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  stage,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0F172A),
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.schedule_rounded,
                                      size: 14,
                                      color: const Color(0xFF64748B),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      date,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          _buildStatusBadge(status),
                        ],
                      ),
                
                      const SizedBox(height: 12),
                
                      // Description
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                          height: 1.5,
                        ),
                      ),
                
                      // Jobs/Works
                      if (jobs.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Divider(color: Color(0xFFF1F5F9)),
                        const SizedBox(height: 12),
                        ...jobs.map((job) => _buildJobListItem(job)),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(ProgressStatus status) {
    Color color;
    Widget? icon;

    switch (status) {
      case ProgressStatus.completed:
        color = const Color(0xFF2563EB);
        icon = const Icon(
          Icons.check_rounded,
          size: 16,
          color: Colors.white,
        );
        break;
      case ProgressStatus.issues:
        color = const Color(0xFFEF4444);
        icon = const Icon(
          Icons.priority_high_rounded,
          size: 16,
          color: Colors.white,
        );
        break;
      case ProgressStatus.inProgress:
        color = const Color(0xFFF59E0B);
        icon = Container(
          width: 12,
          height: 2,
          color: Colors.white,
        );
        break;
      case ProgressStatus.pending:
        color = const Color(0xFFE2E8F0);
        icon = null;
        break;
    }

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: icon != null ? Center(child: icon) : null,
    );
  }

  Widget _buildStatusBadge(ProgressStatus status) {
    String label;
    Color color;

    switch (status) {
      case ProgressStatus.completed:
        label = 'Completed';
        color = const Color(0xFF2563EB);
        break;
      case ProgressStatus.issues:
        label = 'Issues';
        color = const Color(0xFFEF4444);
        break;
      case ProgressStatus.inProgress:
        label = 'In Progress';
        color = const Color(0xFFF59E0B);
        break;
      case ProgressStatus.pending:
        label = 'Pending';
        color = const Color(0xFF94A3B8);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildJobListItem(JobItem job) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: job.isCompleted
                  ? const Color(0xFF2563EB)
                  : job.hasIssue
                      ? const Color(0xFFEF4444)
                      : const Color(0xFFE2E8F0),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              job.title,
              style: TextStyle(
                fontSize: 13,
                color: job.isCompleted
                    ? const Color(0xFF64748B)
                    : const Color(0xFF0F172A),
                fontWeight: job.isCompleted ? FontWeight.w500 : FontWeight.w600,
                decoration: job.isCompleted ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          if (job.hasIssue)
            const Icon(
              Icons.warning_rounded,
              size: 16,
              color: Color(0xFFEF4444),
            ),
        ],
      ),
    );
  }
}

// Models
enum ProgressStatus {
  completed,
  issues,
  inProgress,
  pending,
}

enum ProjectStage {
  planning,
  design,
  production,
  finishing,
  application,
  finished,
  cancelled,
}

class JobItem {
  final String title;
  final bool isCompleted;
  final bool hasIssue;

  JobItem(this.title, this.isCompleted, {this.hasIssue = false});
}
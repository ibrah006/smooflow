// lib/screens/project_progress_log_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/constants.dart';
import 'package:smooflow/providers/project_provider.dart';
import 'dart:async';

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
  String _selectedJobFilter = 'all';
  final List<String> _availableFilters = [
    'all',
    'planning',
    'design',
    'production',
    'finishing',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
          _buildJobsTab(),
        ],
      ),
    );
  }

  Widget _buildTimelineTab() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // Project Overview Card
        ProjectOverallProgressCard(heroKey: kOverallProgressHeroKey),

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

        // Timeline Items
        _buildTimelineItem(
          stage: 'Planning',
          date: 'Dec 1, 2025',
          status: ProgressStatus.completed,
          description: 'Project scope and requirements defined',
          jobs: [
            JobItem('Client meeting', true),
            JobItem('Scope definition', true),
            JobItem('Budget approval', true),
          ],
          isFirst: true,
        ),

        _buildTimelineItem(
          stage: 'Design',
          date: 'Dec 3, 2025',
          status: ProgressStatus.completed,
          description: 'Design mockups created and approved',
          jobs: [
            JobItem('Initial concepts', true),
            JobItem('Client review', true),
            JobItem('Final approval', true),
          ],
        ),

        _buildTimelineItem(
          stage: 'Production',
          date: 'Dec 5, 2025',
          status: ProgressStatus.issues,
          description: 'Material shortage causing delay',
          jobs: [
            JobItem('Material preparation', true),
            JobItem('Printing', false, hasIssue: true),
            JobItem('Quality check', false),
          ],
        ),

        _buildTimelineItem(
          stage: 'Finishing',
          date: 'Pending',
          status: ProgressStatus.pending,
          description: 'Waiting for production completion',
          jobs: [
            JobItem('Trimming', false),
            JobItem('Lamination', false),
          ],
        ),

        _buildTimelineItem(
          stage: 'Application',
          date: 'Pending',
          status: ProgressStatus.pending,
          description: 'On-site installation scheduled',
          jobs: [
            JobItem('Site preparation', false),
            JobItem('Installation', false),
          ],
        ),

        _buildTimelineItem(
          stage: 'Completed',
          date: 'Expected: Dec 14',
          status: ProgressStatus.pending,
          description: 'Final delivery and sign-off',
          jobs: [
            JobItem('Final inspection', false),
            JobItem('Client handover', false),
          ],
          isLast: true,
        ),

        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildJobsTab() {
    return Column(
      children: [
        // Filter Chips
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          color: Colors.white,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _availableFilters.map((filter) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildFilterChip(filter),
                );
              }).toList(),
            ),
          ),
        ),

        const Divider(height: 1, color: Color(0xFFF1F5F9)),

        // Jobs List
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _buildJobCard(
                title: 'Client meeting',
                stage: 'Planning',
                status: ProgressStatus.completed,
                assignee: 'Ibrahim',
                dueDate: 'Dec 1',
                description: 'Initial project discussion and requirements gathering',
              ),

              _buildJobCard(
                title: 'Design mockups',
                stage: 'Design',
                status: ProgressStatus.completed,
                assignee: 'Muhammad Fazaldeen',
                dueDate: 'Dec 3',
                description: 'Create initial design concepts',
              ),

              _buildJobCard(
                title: 'Material preparation',
                stage: 'Production',
                status: ProgressStatus.completed,
                assignee: 'Ahmed Ali',
                dueDate: 'Dec 5',
                description: 'Prepare vinyl and substrate materials',
              ),

              _buildJobCard(
                title: 'Large format printing',
                stage: 'Production',
                status: ProgressStatus.issues,
                assignee: 'Ahmed Ali',
                dueDate: 'Dec 7',
                description: 'Print on 3M vinyl - Material shortage issue',
              ),

              _buildJobCard(
                title: 'Lamination',
                stage: 'Finishing',
                status: ProgressStatus.pending,
                assignee: 'Sarah Johnson',
                dueDate: 'Dec 9',
                description: 'Apply protective laminate',
              ),

              const SizedBox(height: 60),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineItem({
    required String stage,
    required String date,
    required ProgressStatus status,
    required String description,
    required List<JobItem> jobs,
    bool isFirst = false,
    bool isLast = false,
  }) {
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
              child: Container(
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

  Widget _buildFilterChip(String filter) {
    final isSelected = _selectedJobFilter == filter;
    final displayName = filter == 'all' ? 'All Jobs' : filter[0].toUpperCase() + filter.substring(1);

    return InkWell(
      onTap: () => setState(() => _selectedJobFilter = filter),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          displayName,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildJobCard({
    required String title,
    required String stage,
    required ProgressStatus status,
    required String assignee,
    required String dueDate,
    required String description,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: _getStatusColor(status),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              _buildStatusBadge(status),
            ],
          ),

          const SizedBox(height: 12),

          Text(
            description,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
              height: 1.5,
            ),
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.category_rounded,
                      size: 14,
                      color: Color(0xFF64748B),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      stage,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.person_rounded,
                      size: 14,
                      color: Color(0xFF64748B),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      assignee,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      size: 14,
                      color: Color(0xFF64748B),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      dueDate,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

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
}

// Models
enum ProgressStatus {
  completed,
  issues,
  inProgress,
  pending,
}

class JobItem {
  final String title;
  final bool isCompleted;
  final bool hasIssue;

  JobItem(this.title, this.isCompleted, {this.hasIssue = false});
}
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:smooflow/constants.dart';
import 'package:smooflow/enums/priorities.dart';
import 'package:smooflow/enums/status.dart';
import 'package:smooflow/models/project.dart';
import 'package:smooflow/providers/organization_provider.dart';
import 'package:smooflow/providers/project_provider.dart';
import 'package:smooflow/screens/add_project.dart';

class ProjectsScreen extends ConsumerStatefulWidget {
  const ProjectsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends ConsumerState<ProjectsScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  String _selectedSort = 'Due Date';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 8, vsync: this);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  List<Project> get _projects => ref.watch(projectNotifierProvider);

  List<Project> get _filteredProjects {
    var filtered = _projects;

    // Filter by tab
    final selectedTab = _tabController.index;
    if (selectedTab == 1) {
      filtered =
          filtered.where((p) => p.status.toLowerCase() == 'pending').toList();
    } else if (selectedTab == 2) {
      filtered =
          filtered.where((p) => p.status.toLowerCase() == 'design').toList();
    } else if (selectedTab == 3) {
      filtered =
          filtered
              .where((p) => p.status.toLowerCase() == 'production')
              .toList();
    } else if (selectedTab == 4) {
      filtered =
          filtered.where((p) => p.status.toLowerCase() == 'finishing').toList();
    } else if (selectedTab == 5) {
      filtered =
          filtered
              .where((p) => p.status.toLowerCase() == 'application')
              .toList();
    } else if (selectedTab == 6) {
      filtered =
          filtered.where((p) => p.status.toLowerCase() == 'completed').toList();
    } else if (selectedTab == 7) {
      filtered =
          filtered.where((p) => p.status.toLowerCase() == 'cancelled').toList();
    }

    return filtered;
  }

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

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Column(
        children: [
          // Header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(20).copyWith(bottom: 0, top: 5),
            child: SafeArea(
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Platform.isIOS
                              ? Icons.arrow_back_ios
                              : Icons.arrow_back,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Projects',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: colorPrimary,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(
                          Icons.folder_outlined,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F6FA),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextField(
                            controller: _searchController,
                            decoration: const InputDecoration(
                              hintText: 'Search',
                              hintStyle: TextStyle(color: Color(0xFFB0B0B0)),
                              prefixIcon: Icon(
                                Icons.search,
                                color: Color(0xFFB0B0B0),
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F0FE),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.notifications_outlined,
                            color: colorPrimary,
                          ),
                          onPressed: () {},
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Stats Cards
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.work_outline,
                    title: '${_projects.length}',
                    subtitle: 'Active Projects',
                    color: colorPrimary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.schedule,
                    title:
                        '${_projects.where((p) => p.dueDate != null && p.dueDate!.isBefore(DateTime.now().add(const Duration(days: 7)))).length}',
                    subtitle: 'Due This Week',
                    color: colorPending,
                  ),
                ),
              ],
            ),
          ),

          // Tabs
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: colorPrimary,
              indicatorWeight: 3,
              labelColor: colorPrimary,
              unselectedLabelColor: Colors.grey,
              dividerColor: Colors.grey.shade200,
              labelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              onTap: (index) {
                setState(() {});
              },
              tabs: [
                Tab(text: 'All (${_projects.length})'),
                Tab(
                  text:
                      'Pending (${_projects.where((p) => p.status.toLowerCase() == 'pending').length})',
                ),
                Tab(
                  text:
                      'Design (${_projects.where((p) => p.status.toLowerCase() == 'design').length})',
                ),
                Tab(
                  text:
                      'Production (${_projects.where((p) => p.status.toLowerCase() == 'production').length})',
                ),
                Tab(
                  text:
                      'Finishing (${_projects.where((p) => p.status.toLowerCase() == 'finishing').length})',
                ),
                Tab(
                  text:
                      'Application (${_projects.where((p) => p.status.toLowerCase() == 'application').length})',
                ),
                Tab(
                  text:
                      'Completed (${_projects.where((p) => p.status.toLowerCase() == 'finished').length})',
                ),
                Tab(
                  text:
                      'Cancelled (${_projects.where((p) => p.status.toLowerCase() == 'cancelled').length})',
                ),
              ],
            ),
          ),

          // Sort Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
            child: Row(
              children: [
                const Text(
                  'Sort by:',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _selectedSort,
                  underline: Container(),
                  icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                  items:
                      ['Due Date', 'Priority', 'Name', 'Client'].map((
                        String value,
                      ) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedSort = newValue;
                      });
                    }
                  },
                ),
              ],
            ),
          ),

          // Projects List
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshProjects,
              child:
                  _filteredProjects.isEmpty && _tabController.index == 0
                      ? SingleChildScrollView(
                        physics: AlwaysScrollableScrollPhysics(),
                        child: Center(
                          child: SizedBox(
                            width: 200,
                            child: Column(
                              spacing: 10,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height / 30,
                                ),
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
                                          builder:
                                              (context) => AddProjectScreen(),
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
                      )
                      : ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: _filteredProjects.length,
                        itemBuilder: (context, index) {
                          final project = _filteredProjects[index];
                          return _buildProjectCard(project);
                        },
                      ),
            ),
          ),
        ],
      ),
      floatingActionButton:
          _filteredProjects.isEmpty && _tabController.index == 0
              ? null
              : FloatingActionButton.extended(
                onPressed: () {
                  // Navigate to Create Project screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AddProjectScreen()),
                  );
                },
                backgroundColor: colorPrimary,
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  'New Project',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Map<Status, double> get _statusIndicatorValues => Map.fromIterable(
    Status.values,
    key: (element) => element,
    value: (element) => _getIndicatorValue(element),
  );

  // Get the progress indicator value for the specific status
  double _getIndicatorValue(Status status) {
    switch (status) {
      case Status.planning || Status.cancelled:
        return 0;
      case Status.design:
        return 0.10;
      case Status.production:
        return 0.40;
      case Status.finishing:
        return 0.65;
      case Status.application:
        return 0.90;
      case Status.finished:
        return 1;
    }
  }

  Widget _buildProjectCard(Project project) {
    final daysUntilDue = project.dueDate?.difference(DateTime.now()).inDays;
    final isOverdue = daysUntilDue != null && daysUntilDue < 0;
    final isDueSoon =
        daysUntilDue != null && daysUntilDue >= 0 && daysUntilDue <= 3;

    double projectProgress;
    try {
      projectProgress =
          _statusIndicatorValues[Status.values.byName(
            project.status.toLowerCase(),
          )]!;
    } catch (e) {
      projectProgress = 0;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Navigate to project details
            HapticFeedback.lightImpact();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => AddProjectScreen.view(projectId: project.id),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            project.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            project.client.name,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: project.statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "${project.status[0].toUpperCase()}${project.status.substring(1)}",
                        style: TextStyle(
                          color: project.statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                if (project.description != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    project.description!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF666666),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                const SizedBox(height: 16),

                // Progress Bar
                ...[
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Progress',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  '${0}/${project.tasks.length} tasks',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: projectProgress,
                                backgroundColor: const Color(0xFFF5F6FA),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  project.statusColor,
                                ),
                                minHeight: 6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                Row(
                  children: [
                    // Due Date
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 14,
                            color:
                                isOverdue
                                    ? colorError
                                    : isDueSoon
                                    ? colorPending
                                    : Colors.grey,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Due Date',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  project.dueDate != null
                                      ? '${project.dueDate!.day}/${project.dueDate!.month}/${project.dueDate!.year}'
                                      : 'Not set',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        isOverdue
                                            ? colorError
                                            : isDueSoon
                                            ? colorPending
                                            : Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Priority
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: project.priorityColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.flag_outlined,
                            size: 12,
                            color: project.priorityColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            PriorityLevel.values
                                .elementAt(project.priority)
                                .name,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: project.priorityColor,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Assigned Managers Avatars
                    SizedBox(
                      width: project.assignedManagers.length > 2 ? 60 : 40,
                      height: 24,
                      child: Stack(
                        children: [
                          for (
                            int i = 0;
                            i <
                                (project.assignedManagers.length > 2
                                    ? 2
                                    : project.assignedManagers.length);
                            i++
                          )
                            Positioned(
                              left: i * 20.0,
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: colorPrimary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    project.assignedManagers[i].name[0]
                                        .toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          if (project.assignedManagers.length > 2)
                            Positioned(
                              left: 40,
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    '+${project.assignedManagers.length - 2}',
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

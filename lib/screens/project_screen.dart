// lib/screens/project/project_details_screen.dart
import 'package:flutter/material.dart';

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

class ProjectScreen extends StatefulWidget {

  final String projectId;

  const ProjectScreen({Key? key, required this.projectId}) : super(key: key);

  @override
  State<ProjectScreen> createState() => _ProjectScreenState();
}

class _ProjectScreenState extends State<ProjectScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedJobFilter = 'All';
  
  // Mock data
  final List<String> _availableJobStages = ['planning', 'design', 'production', 'finishing'];
  
  final List<Map<String, dynamic>> _progressLogs = [
    {
      'stage': 'Planning',
      'date': '2 days ago',
      'status': ProgressStatus.completed,
      'tasks': [
        {'name': 'Initial consultation', 'status': ProgressStatus.completed},
        {'name': 'Site measurement', 'status': ProgressStatus.completed},
        {'name': 'Quote approval', 'status': ProgressStatus.completed},
      ],
    },
    {
      'stage': 'Design',
      'date': '1 day ago',
      'status': ProgressStatus.issue,
      'tasks': [
        {'name': 'Concept design', 'status': ProgressStatus.completed},
        {'name': 'Client approval', 'status': ProgressStatus.issue},
        {'name': 'Final mockup', 'status': ProgressStatus.inProgress},
      ],
    },
    {
      'stage': 'Production',
      'date': 'Today',
      'status': ProgressStatus.inProgress,
      'tasks': [
        {'name': 'Material preparation', 'status': ProgressStatus.completed},
        {'name': 'Printing', 'status': ProgressStatus.inProgress},
        {'name': 'Quality check', 'status': ProgressStatus.inProgress},
      ],
    },
  ];
  
  final List<Map<String, dynamic>> _allJobs = [
    {
      'name': 'Initial consultation',
      'stage': ProjectStage.planning,
      'assignee': 'John Doe',
      'status': ProgressStatus.completed,
    },
    {
      'name': 'Concept design',
      'stage': ProjectStage.design,
      'assignee': 'Sarah Smith',
      'status': ProgressStatus.completed,
    },
    {
      'name': 'Client approval',
      'stage': ProjectStage.design,
      'assignee': 'Sarah Smith',
      'status': ProgressStatus.issue,
    },
    {
      'name': 'Printing banners',
      'stage': ProjectStage.production,
      'assignee': 'Mike Johnson',
      'status': ProgressStatus.inProgress,
    },
    {
      'name': 'Lamination',
      'stage': ProjectStage.finishing,
      'assignee': 'Lisa Chen',
      'status': ProgressStatus.inProgress,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ABC Corp - Signage',
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
                
                // Tab Bar
                TabBar(
                  controller: _tabController,
                  labelColor: const Color(0xFF2563EB),
                  unselectedLabelColor: const Color(0xFF9CA3AF),
                  labelStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  indicatorColor: const Color(0xFF2563EB),
                  dividerColor: Colors.black12,
                  indicatorWeight: 3,
                  tabs: const [
                    Tab(text: 'Information'),
                    Tab(text: 'Progress'),
                    Tab(text: 'Jobs'),
                  ],
                ),
              ],
            ),
          ),
          
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildInformationTab(),
                _buildProgressTab(),
                _buildJobsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInformationTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Current Stage Card
        Container(
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
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.print, color: Color(0xFF2563EB), size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Production',
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
        
        const SizedBox(height: 16),
        
        // Basic Information Card
        Container(
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
              
              _buildInfoRow('Client', 'ABC Corporation'),
              const SizedBox(height: 16),
              _buildInfoRow('Priority', 'High', isHighlighted: true),
              const SizedBox(height: 16),
              _buildInfoRow('Start Date', 'Dec 1, 2025'),
              const SizedBox(height: 16),
              _buildInfoRow('End Date', 'Dec 15, 2025'),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Description Card
        Container(
          padding: const EdgeInsets.all(24),
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
              const Text(
                'Complete storefront signage package including main exterior sign, window decals, and interior directional signage. All materials to be weather-resistant and meet local regulations.',
                style: TextStyle(
                  fontSize: 15,
                  color: Color(0xFF6B7280),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Header with progress percentage
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Project Timeline',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.trending_up, color: Color(0xFF2563EB), size: 16),
                  SizedBox(width: 6),
                  Text(
                    '60% Complete',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: 0.6,
            backgroundColor: const Color(0xFFE5E7EB),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
            minHeight: 6,
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Timeline
        ..._progressLogs.asMap().entries.map((entry) {
          final index = entry.key;
          final log = entry.value;
          final isLast = index == _progressLogs.length - 1;
          
          return _buildProgressLogItem(
            stage: log['stage'],
            date: log['date'],
            status: log['status'],
            tasks: List<Map<String, dynamic>>.from(log['tasks']),
            isLast: isLast,
          );
        }).toList(),
      ],
    );
  }

  Widget _buildJobsTab() {
    return Column(
      children: [
        // Filter Chips
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildJobFilterChip('All'),
                ..._availableJobStages.map((stage) => 
                  _buildJobFilterChip(_capitalizeFirst(stage))
                ),
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

  Widget _buildProgressLogItem({
    required String stage,
    required String date,
    required ProgressStatus status,
    required List<Map<String, dynamic>> tasks,
    required bool isLast,
  }) {
    final completedTasks = tasks.where((t) => t['status'] == ProgressStatus.completed).length;
    final totalTasks = tasks.length;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator
          Column(
            children: [
              // Status circle with shadow
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _getStatusColor(status).withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: _buildStatusCircle(status, size: 40),
              ),
              if (!isLast)
                Container(
                  width: 3,
                  height: 140,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        _getStatusColor(status).withOpacity(0.3),
                        const Color(0xFFE5E7EB),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
            ],
          ),
          
          const SizedBox(width: 20),
          
          // Content Card
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                // border: Border.all(
                //   color: status == ProgressStatus.issue 
                //       ? const Color(0xFFEF4444).withOpacity(0.3)
                //       : const Color(0xFFE5E7EB),
                //   width: 1.5,
                // ),
                // boxShadow: [
                //   BoxShadow(
                //     color: Colors.black.withOpacity(0.03),
                //     blurRadius: 10,
                //     offset: const Offset(0, 2),
                //   ),
                // ],
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
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 14,
                                  color: const Color(0xFF9CA3AF),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  date,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF9CA3AF),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Task completion badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getStatusColor(status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$completedTasks',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _getStatusColor(status),
                              ),
                            ),
                            Text(
                              '/$totalTasks',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF9CA3AF),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Progress bar for stage
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: completedTasks / totalTasks,
                      backgroundColor: const Color(0xFFF5F7FA),
                      valueColor: AlwaysStoppedAnimation<Color>(_getStatusColor(status)),
                      minHeight: 6,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Divider
                  Container(
                    height: 1,
                    color: const Color(0xFFF5F7FA),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Tasks
                  ...tasks.asMap().entries.map((taskEntry) {
                    final taskIndex = taskEntry.key;
                    final task = taskEntry.value;
                    final isLastTask = taskIndex == tasks.length - 1;
                    
                    return Padding(
                      padding: EdgeInsets.only(bottom: isLastTask ? 0 : 12),
                      child: Row(
                        children: [
                          _buildStatusCircle(task['status'], size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              task['name'],
                              style: TextStyle(
                                fontSize: 14,
                                color: task['status'] == ProgressStatus.completed
                                    ? const Color(0xFF6B7280)
                                    : Colors.black,
                                fontWeight: task['status'] == ProgressStatus.completed
                                    ? FontWeight.w500
                                    : FontWeight.w600,
                                decoration: task['status'] == ProgressStatus.completed
                                    ? TextDecoration.lineThrough
                                    : null,
                                decorationColor: const Color(0xFF9CA3AF),
                              ),
                            ),
                          ),
                          if (task['status'] == ProgressStatus.issue)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Issue',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFEF4444),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCircle(ProgressStatus status, {double size = 24}) {
    Color color = _getStatusColor(status);
    IconData? icon;
    
    switch (status) {
      case ProgressStatus.completed:
        icon = size > 20 ? Icons.check_rounded : null;
        break;
      case ProgressStatus.issue:
        icon = Icons.priority_high_rounded;
        break;
      case ProgressStatus.inProgress:
        icon = size > 20 ? Icons.remove_rounded : null;
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

  Color _getStatusColor(ProgressStatus status) {
    switch (status) {
      case ProgressStatus.completed:
        return const Color(0xFF2563EB);
      case ProgressStatus.issue:
        return const Color(0xFFEF4444);
      case ProgressStatus.inProgress:
        return const Color(0xFFF59E0B);
    }
  }

  Widget _buildJobFilterChip(String label) {
    final isSelected = _selectedJobFilter == label;
    
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () => setState(() => _selectedJobFilter = label),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.black : const Color(0xFFF5F7FA),
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

  Widget _buildJobCard(Map<String, dynamic> job) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          _buildStatusCircle(job['status'], size: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  job['name'],
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
                    Text(
                      job['assignee'],
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
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
              _getStageLabel(job['stage']),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getFilteredJobs() {
    if (_selectedJobFilter == 'All') {
      return _allJobs;
    }
    
    return _allJobs.where((job) {
      return _getStageLabel(job['stage']).toLowerCase() == _selectedJobFilter.toLowerCase();
    }).toList();
  }

  String _getStageLabel(ProjectStage stage) {
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

  String _capitalizeFirst(String text) {
    return text[0].toUpperCase() + text.substring(1);
  }
}
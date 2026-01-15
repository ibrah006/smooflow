import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/enums/priorities.dart';
import 'package:smooflow/enums/progress_status.dart';
import 'package:smooflow/enums/project_stage.dart';
import 'package:smooflow/models/project.dart';
import 'package:smooflow/providers/project_provider.dart';

enum NavigationPage {
  dashboard,
  allProjects,
  completed,
  pending,
}

class Artwork {
  final String id;
  final String name;
  final String path;
  final DateTime uploadedAt;
  final String? notes;
  final String fileType;
  final String fileSize;

  Artwork({
    required this.id,
    required this.name,
    required this.path,
    required this.uploadedAt,
    this.notes,
    required this.fileType,
    required this.fileSize,
  });
}

enum ActivityType {
  created,
  statusChanged,
  artworkUploaded,
  artworkDeleted,
  assigneeChanged,
  priorityChanged,
  completed,
  comment,
}

class TimelineActivity {
  final String id;
  final ActivityType type;
  final DateTime timestamp;
  final String description;
  final String? actor;
  final Map<String, dynamic>? metadata;

  TimelineActivity({
    required this.id,
    required this.type,
    required this.timestamp,
    required this.description,
    this.actor,
    this.metadata,
  });
}

class DesignDashboard extends ConsumerStatefulWidget {
  const DesignDashboard({Key? key}) : super(key: key);

  @override
  ConsumerState<DesignDashboard> createState() => _DesignDashboardState();
}

class _DesignDashboardState extends ConsumerState<DesignDashboard> with TickerProviderStateMixin {
  late AnimationController _pageAnimationController;
  late AnimationController _detailsAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _detailsFadeAnimation;
  late Animation<Offset> _detailsSlideAnimation;
  late Animation<double> _scaleAnimation;
  
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;
  bool _showingDetails = false;

  NavigationPage currentPage = NavigationPage.dashboard;
  Project? selectedProject;

  List<Project> get projects {
    return ref.watch(projectNotifierProvider);
  }

  @override
  void initState() {
    super.initState();

    Future.microtask(() async {
      await ref.read(projectNotifierProvider.notifier).load(projectsLastAddedLocal: null);
      setState(() {});
    });

    _pageAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _detailsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _pageAnimationController,
        curve: Curves.easeInOut,
      ),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.02, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _pageAnimationController,
        curve: Curves.easeOutCubic,
      ),
    );
    
    _detailsFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _detailsAnimationController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
      ),
    );
    
    _detailsSlideAnimation = Tween<Offset>(
      begin: const Offset(0.05, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _detailsAnimationController,
        curve: Curves.easeOutCubic,
      ),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _detailsAnimationController,
        curve: Curves.easeOutCubic,
      ),
    );
    
    _pageAnimationController.forward();
  }

  @override
  void dispose() {
    _pageAnimationController.dispose();
    _detailsAnimationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _triggerPageTransition() {
    _pageAnimationController.reset();
    _pageAnimationController.forward();
  }

  void _navigateToTaskDetails(Project project) async {
    setState(() {
      _showingDetails = true;
    });
    
    // Small delay for visual feedback
    await Future.delayed(const Duration(milliseconds: 100));
    
    setState(() {
      selectedProject = project;
    });
    
    _detailsAnimationController.forward(from: 0.0);
  }

  void _navigateBackFromDetails() async {
    await _detailsAnimationController.reverse();
    
    setState(() {
      selectedProject = null;
      _showingDetails = false;
    });
    
    _triggerPageTransition();
  }

  List<Project> get filteredTasks {
    List<Project> filtered;
    
    switch (currentPage) {
      case NavigationPage.allProjects:
        filtered = projects;
        break;
      case NavigationPage.completed:
        filtered = projects.where((t) => t.status == ProjectStage.finished.name).toList();
        break;
      case NavigationPage.pending:
        filtered = projects.where((t) => t.status == ProjectStage.planning.name).toList();
        break;
      case NavigationPage.dashboard:
      default:
        filtered = projects;
    }
    
    // Apply search filter with improved matching
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase().trim();
      filtered = filtered.where((Project project) {
        // Search in project name
        final nameMatch = project.name.toLowerCase().contains(query);
        
        // Search in description
        final descriptionMatch = project.description?.toLowerCase().contains(query) ?? false;
        
        // Search in assignee name
        // final assigneeMatch = project.assignee?.toLowerCase().contains(query) ?? false;
        
        // Search in priority
        final priorityMatch = PriorityLevel.values[project.priority].name.toLowerCase().contains(query);
        
        // Search in status
        final statusMatch = _getStatusLabel(project.status).toLowerCase().contains(query);
        
        // Search in artworks
        // final artworkMatch = project.artworks.any((artwork) => 
        //   artwork.name.toLowerCase().contains(query) ||
        //   artwork.fileType.toLowerCase().contains(query)
        // );
        
        return nameMatch || descriptionMatch || 
               priorityMatch || statusMatch;
      }).toList();
    }
    
    return filtered;
  }

  String _getStatusLabel(String status) {

    switch (ProjectStage.values.byName(status.toLowerCase())) {
      case ProjectStage.planning:
        return 'Pending';
      case ProjectStage.design:
        return 'Design Phase';
      case ProjectStage.production:
        return 'Production Phase';
      case ProjectStage.finishing:
        return 'Finishing Phase';
      case ProjectStage.application:
        return 'Installation Phase';
      case ProjectStage.finished:
        return 'Completed';
      default: 
        return 'Project Cancelled';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(
            child: selectedProject != null
                ? _buildTaskDetailsPage()
                : _buildMainContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1E293B),
            Color(0xFF0F172A),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(28.0),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4F46E5).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.layers_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DesignHub',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        'Pro',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF94A3B8),
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFF334155)),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildSidebarSection('Main'),
                _buildSidebarItem(
                  Icons.dashboard_rounded,
                  'Dashboard',
                  currentPage == NavigationPage.dashboard,
                  0,
                  () {
                    setState(() {
                      currentPage = NavigationPage.dashboard;
                      selectedProject = null;
                    });
                    _triggerPageTransition();
                  },
                ),
                _buildSidebarItem(
                  Icons.folder_rounded,
                  'All Projects',
                  currentPage == NavigationPage.allProjects,
                  projects.length,
                  () {
                    setState(() {
                      currentPage = NavigationPage.allProjects;
                      selectedProject = null;
                    });
                    _triggerPageTransition();
                  },
                ),
                const SizedBox(height: 20),
                _buildSidebarSection('Status'),
                _buildSidebarItem(
                  Icons.schedule_rounded,
                  'Pending',
                  currentPage == NavigationPage.pending,
                  projects.where((p) => p.status == "planning" || p.status == "pending").length,
                  () {
                    setState(() {
                      currentPage = NavigationPage.pending;
                      selectedProject = null;
                    });
                    _triggerPageTransition();
                  },
                ),
                _buildSidebarItem(
                  Icons.pending_actions_rounded,
                  'Design Phase Projects',
                  false,
                  projects.where((p) => p.status == "design").length,
                  () {},
                ),
                // TODO: For Tasks
                // _buildSidebarItem(
                //   Icons.hourglass_empty_rounded,
                //   'Awaiting Approval',
                //   false,
                //   projects.where((t) => t.status == TaskStatus.waitingApproval).length,
                //   () {},
                // ),
                _buildSidebarItem(
                  Icons.check_circle_rounded,
                  'Completed',
                  currentPage == NavigationPage.completed,
                  projects.where((p) => p.status == "completed").length,
                  () {
                    setState(() {
                      currentPage = NavigationPage.completed;
                      selectedProject = null;
                    });
                    _triggerPageTransition();
                  },
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF334155).withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF475569).withOpacity(0.5),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Text(
                      'AD',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Admin User',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Design Lead',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.settings_rounded,
                  color: Colors.white.withOpacity(0.7),
                  size: 20,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(40.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (currentPage == NavigationPage.dashboard) ...[
                      _buildStatsCards(),
                      const SizedBox(height: 32),
                    ],
                    _buildFilterBar(),
                    const SizedBox(height: 20),
                    _buildTasksList(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    String pageTitle = 'Design Projects';
    String pageSubtitle = 'Manage your design workflow';
    
    switch (currentPage) {
      case NavigationPage.allProjects:
        pageTitle = 'All Projects';
        pageSubtitle = 'Complete overview of all design projects';
        break;
      case NavigationPage.completed:
        pageTitle = 'Completed Projects';
        pageSubtitle = 'Successfully delivered and approved projects';
        break;
      case NavigationPage.pending:
        pageTitle = 'Pending Projects';
        pageSubtitle = 'Projects waiting to be started';
        break;
      case NavigationPage.dashboard:
      default:
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pageTitle,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      pageSubtitle,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${filteredTasks.length} Active',
                        style: const TextStyle(
                          color: Color(0xFF16A34A),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                _buildHeaderIconButton(Icons.filter_list_rounded, () {}),
                _buildHeaderIconButton(Icons.search_rounded, () {}),
                _buildHeaderIconButton(
                  Icons.notifications_outlined,
                  () {},
                  badge: true,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _showUploadArtworkDialog,
            icon: const Icon(Icons.cloud_upload_rounded, size: 20),
            label: const Text(
              'Upload Artwork',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF4F46E5),
              side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
              elevation: 0,
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton.icon(
            onPressed: _showCreateTaskDialog,
            icon: const Icon(Icons.add_rounded, size: 20),
            label: const Text(
              'New Project',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(
          child: _buildModernStatCard(
            'Total Projects',
            projects.length.toString(),
            Icons.folder_rounded,
            const Color(0xFF4F46E5),
            const Color(0xFFEEF2FF),
            '+12%',
            true,
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: _buildModernStatCard(
            'In Progress',
            projects.where((p) => p.status != "completed" && p.status != "cancelled" && p.status != "planning" &&  p.status != "pending").length.toString(),
            Icons.trending_up_rounded,
            const Color(0xFFF59E0B),
            const Color(0xFFFEF3C7),
            '+8%',
            true,
          ),
        ),
        const SizedBox(width: 20),
        // TODO: for tasks
        // Expanded(
        //   child: _buildModernStatCard(
        //     'Pending Approval',
        //     projects.where((t) => t.status == TaskStatus.waitingApproval).length.toString(),
        //     Icons.access_time_rounded,
        //     const Color(0xFF8B5CF6),
        //     const Color(0xFFF3E8FF),
        //     '-3%',
        //     false,
        //   ),
        // ),
        const SizedBox(width: 20),
        Expanded(
          child: _buildModernStatCard(
            'Completed',
            projects.where((p) => p.status == "completed" || p.status == "finished").length.toString(),
            Icons.check_circle_rounded,
            const Color(0xFF10B981),
            const Color(0xFFD1FAE5),
            '+24%',
            true,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterBar() {
    String pageLabel = currentPage == NavigationPage.dashboard
        ? 'All Projects'
        : currentPage == NavigationPage.allProjects
            ? 'Projects List'
            : currentPage == NavigationPage.completed
                ? 'Completed'
                : 'Pending';
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              pageLabel,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
                color: Color(0xFF0F172A),
              ),
            ),
            if (_searchQuery.isNotEmpty) ...[
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF4F46E5).withOpacity(0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.search_rounded,
                      size: 16,
                      color: Color(0xFF4F46E5),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Search: "$_searchQuery"',
                      style: const TextStyle(
                        color: Color(0xFF4F46E5),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4F46E5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${filteredTasks.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: () {
                        setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                        });
                      },
                      child: const Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: Color(0xFF4F46E5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.sort_rounded,
                size: 18,
                color: Color(0xFF64748B),
              ),
              const SizedBox(width: 8),
              Text(
                'Sort by: Recent',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: Colors.grey.shade600,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTasksList() {
    if (filteredTasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 60),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFE2E8F0),
                  width: 2,
                ),
              ),
              child: Icon(
                _searchQuery.isNotEmpty 
                    ? Icons.search_off_rounded 
                    : Icons.folder_open_rounded,
                size: 64,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _searchQuery.isNotEmpty 
                  ? 'No results found' 
                  : 'No projects found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 400,
              child: Text(
                _searchQuery.isNotEmpty
                    ? 'No projects match "$_searchQuery". Try different keywords or check your spelling.'
                    : 'Create a new project to get started with your design workflow.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (_searchQuery.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _searchController.clear();
                        _searchQuery = '';
                      });
                    },
                    icon: const Icon(Icons.clear_rounded, size: 18),
                    label: const Text('Clear Search'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF4F46E5),
                      side: const BorderSide(color: Color(0xFF4F46E5)),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _isSearching = false;
                        _searchController.clear();
                        _searchQuery = '';
                      });
                    },
                    icon: const Icon(Icons.view_list_rounded, size: 18),
                    label: const Text('View All Projects'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.symmetric(horizontal: 80),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF4F46E5).withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.lightbulb_outline_rounded,
                          size: 20,
                          color: Color(0xFF4F46E5),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Search Tips',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildSearchTip('Search by project name, description, or assignee'),
                    _buildSearchTip('Try status keywords: pending, approved, progress'),
                    _buildSearchTip('Search by priority: critical, high, medium, low'),
                    _buildSearchTip('Look for file names or file types: jpg, pdf, fig'),
                  ],
                ),
              ),
            ] else ...[
              ElevatedButton.icon(
                onPressed: _showCreateTaskDialog,
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text('Create New Project'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_searchQuery.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              'Found ${filteredTasks.length} ${filteredTasks.length == 1 ? 'project' : 'projects'}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filteredTasks.length,
          itemBuilder: (context, index) {
            return TweenAnimationBuilder<double>(
              duration: Duration(milliseconds: 300 + (index * 50)),
              tween: Tween(begin: 0.0, end: 1.0),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: Opacity(
                    opacity: value,
                    child: child,
                  ),
                );
              },
              child: _buildModernTaskCard(filteredTasks[index]),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSearchTip(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_rounded,
            size: 16,
            color: Color(0xFF10B981),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskDetailsPage() {
    if (selectedProject == null) return const SizedBox();

    return FadeTransition(
      opacity: _detailsFadeAnimation,
      child: SlideTransition(
        position: _detailsSlideAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _navigateBackFromDetails,
                      icon: const Icon(Icons.arrow_back_rounded),
                      color: const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selectedProject!.name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              _buildModernStatusBadge(selectedProject!.status),
                              const SizedBox(width: 8),
                              _buildPriorityBadge(PriorityLevel.values.elementAt(selectedProject!.priority).name),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // TODO: Only for tasks
                    // if (selectedProject!.status != TaskStatus.approved)
                    //   ElevatedButton.icon(
                    //     onPressed: () => _showMoveToNextStageDialog(selectedProject!),
                    //     icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                    //     label: const Text('Advance Stage'),
                    //     style: ElevatedButton.styleFrom(
                    //       backgroundColor: const Color(0xFF4F46E5),
                    //       foregroundColor: Colors.white,
                    //       padding: const EdgeInsets.symmetric(
                    //         horizontal: 20,
                    //         vertical: 14,
                    //       ),
                    //     ),
                    //   ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(40),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TweenAnimationBuilder<double>(
                              duration: const Duration(milliseconds: 600),
                              tween: Tween(begin: 0.0, end: 1.0),
                              curve: Curves.easeOut,
                              builder: (context, value, child) {
                                return Transform.translate(
                                  offset: Offset(0, 30 * (1 - value)),
                                  child: Opacity(
                                    opacity: value,
                                    child: child,
                                  ),
                                );
                              },
                              child: _buildDetailsCard(
                                'Project Details',
                                Icons.info_outline_rounded,
                                [
                                  // _buildDetailRow('Assignee', selectedProject!.assignee ?? 'Unassigned'),
                                  _buildDetailRow('Created', _formatDateLong(selectedProject!.createdAt)),
                                  // TODO:
                                  // if (selectedProject!.completedAt != null)
                                  //   _buildDetailRow('Completed', _formatDateLong(selectedProject!.completedAt!)),
                                  // TODO: loop throught the tasks and find all artworks related to this project
                                  // _buildDetailRow('Total Artworks', '${selectedProject!.artworks.length}'),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            if (selectedProject!.description != null)
                              TweenAnimationBuilder<double>(
                                duration: const Duration(milliseconds: 700),
                                tween: Tween(begin: 0.0, end: 1.0),
                                curve: Curves.easeOut,
                                builder: (context, value, child) {
                                  return Transform.translate(
                                    offset: Offset(0, 30 * (1 - value)),
                                    child: Opacity(
                                      opacity: value,
                                      child: child,
                                    ),
                                  );
                                },
                                child: _buildDetailsCard(
                                  'Description',
                                  Icons.description_outlined,
                                  [
                                    Text(
                                      selectedProject!.description!,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF475569),
                                        height: 1.6,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 24),
                            TweenAnimationBuilder<double>(
                              duration: const Duration(milliseconds: 800),
                              tween: Tween(begin: 0.0, end: 1.0),
                              curve: Curves.easeOut,
                              builder: (context, value, child) {
                                return Transform.translate(
                                  offset: Offset(0, 30 * (1 - value)),
                                  child: Opacity(
                                    opacity: value,
                                    child: child,
                                  ),
                                );
                              },
                              child: _buildArtworksSection(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        flex: 1,
                        child: Column(
                          children: [
                            TweenAnimationBuilder<double>(
                              duration: const Duration(milliseconds: 700),
                              tween: Tween(begin: 0.0, end: 1.0),
                              curve: Curves.easeOut,
                              builder: (context, value, child) {
                                return Transform.translate(
                                  offset: Offset(30 * (1 - value), 0),
                                  child: Opacity(
                                    opacity: value,
                                    child: child,
                                  ),
                                );
                              },
                              child: _buildSettingsCard(),
                            ),
                            const SizedBox(height: 24),
                            TweenAnimationBuilder<double>(
                              duration: const Duration(milliseconds: 800),
                              tween: Tween(begin: 0.0, end: 1.0),
                              curve: Curves.easeOut,
                              builder: (context, value, child) {
                                return Transform.translate(
                                  offset: Offset(30 * (1 - value), 0),
                                  child: Opacity(
                                    opacity: value,
                                    child: child,
                                  ),
                                );
                              },
                              child: _buildActivityCard(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsCard(String title, IconData icon, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: const Color(0xFF4F46E5), size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArtworksSection() {
    // TODO: work this out from selectedTask
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.collections_rounded,
                      color: Color(0xFF4F46E5),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Artworks',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      // '${selectedProject!.artworks.length}',
                      '0',
                      style: const TextStyle(
                        color: Color(0xFF4F46E5),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _showUploadArtworkDialog(preselectedTask: selectedProject),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add Artwork'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // if (selectedProject!.artworks.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    Icon(
                      Icons.cloud_upload_rounded,
                      size: 64,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No artworks yet',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Upload your first artwork to get started',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            )
          // else
          //   GridView.builder(
          //     shrinkWrap: true,
          //     physics: const NeverScrollableScrollPhysics(),
          //     gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          //       crossAxisCount: 3,
          //       crossAxisSpacing: 16,
          //       mainAxisSpacing: 16,
          //       childAspectRatio: 1,
          //     ),
          //     itemCount: selectedProject!.artworks.length,
          //     itemBuilder: (context, index) {
          //       return _buildDetailedArtworkCard(selectedProject!.artworks[index]);
          //     },
          //   ),
        ],
      ),
    );
  }

  Widget _buildDetailedArtworkCard(Artwork artwork) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFEEF2FF),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Center(
                child: Icon(
                  _getFileIcon(artwork.fileType),
                  size: 48,
                  color: const Color(0xFF4F46E5),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  artwork.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        artwork.fileType,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF4F46E5),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      artwork.fileSize,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _formatDate(artwork.uploadedAt),
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.settings_rounded, color: Color(0xFF4F46E5), size: 20),
              SizedBox(width: 10),
              Text(
                'Settings',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // TODO: only for tasks
          // _buildSettingItem(
          //   'Auto-advance',
          //   'Automatically move to next stage',
          //   selectedProject!.autoMoveToNext,
          //   (value) {
          //     setState(() {
          //       selectedProject!.autoMoveToNext = value;
          //     });
          //   },
          // ),
        ],
      ),
    );
  }

  Widget _buildSettingItem(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF10B981),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard() {
    // final sortedTimeline = List<TimelineActivity>.from(selectedProject!.timeline)
    //   ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row(
          //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //   children: [
          //     const Row(
          //       children: [
          //         Icon(Icons.history_rounded, color: Color(0xFF4F46E5), size: 20),
          //         SizedBox(width: 10),
          //         Text(
          //           'Activity Timeline',
          //           style: TextStyle(
          //             fontSize: 15,
          //             fontWeight: FontWeight.bold,
          //             color: Color(0xFF0F172A),
          //           ),
          //         ),
          //       ],
          //     ),
          //     Container(
          //       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          //       decoration: BoxDecoration(
          //         color: const Color(0xFFEEF2FF),
          //         borderRadius: BorderRadius.circular(12),
          //       ),
          //       child: Text(
          //         '${sortedTimeline.length}',
          //         style: const TextStyle(
          //           color: Color(0xFF4F46E5),
          //           fontSize: 12,
          //           fontWeight: FontWeight.w700,
          //         ),
          //       ),
          //     ),
          //   ],
          // ),
          // const SizedBox(height: 20),
          // if (sortedTimeline.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.timeline_rounded,
                      size: 48,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No activity yet',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            )
          // else
          //   SizedBox(
          //     height: 400,
          //     child: ListView.builder(
          //       itemCount: sortedTimeline.length,
          //       itemBuilder: (context, index) {
          //         final activity = sortedTimeline[index];
          //         final isLast = index == sortedTimeline.length - 1;
          //         return _buildTimelineItem(activity, isLast);
          //       },
          //     ),
          //   ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(TimelineActivity activity, bool isLast) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getActivityColor(activity.type).withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _getActivityColor(activity.type).withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Icon(
                  _getActivityIcon(activity.type),
                  size: 16,
                  color: _getActivityColor(activity.type),
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 40,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        _getActivityColor(activity.type).withOpacity(0.3),
                        Colors.grey.shade200,
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.description,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (activity.actor != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.person_outline_rounded,
                                size: 12,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                activity.actor!,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Icon(
                        Icons.schedule_rounded,
                        size: 12,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatTimeAgo(activity.timestamp),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                  if (activity.metadata != null && activity.metadata!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _buildMetadataTags(activity.metadata!),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildMetadataTags(Map<String, dynamic> metadata) {
    return metadata.entries.map((entry) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFEEF2FF),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          '${entry.key}: ${entry.value}',
          style: const TextStyle(
            fontSize: 10,
            color: Color(0xFF4F46E5),
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }).toList();
  }

  Color _getActivityColor(ActivityType type) {
    switch (type) {
      case ActivityType.created:
        return const Color(0xFF3B82F6);
      case ActivityType.statusChanged:
        return const Color(0xFF8B5CF6);
      case ActivityType.artworkUploaded:
        return const Color(0xFF10B981);
      case ActivityType.artworkDeleted:
        return const Color(0xFFEF4444);
      case ActivityType.assigneeChanged:
        return const Color(0xFFF59E0B);
      case ActivityType.priorityChanged:
        return const Color(0xFFEC4899);
      case ActivityType.completed:
        return const Color(0xFF10B981);
      case ActivityType.comment:
        return const Color(0xFF6366F1);
    }
  }

  IconData _getActivityIcon(ActivityType type) {
    switch (type) {
      case ActivityType.created:
        return Icons.add_circle_outline_rounded;
      case ActivityType.statusChanged:
        return Icons.swap_horiz_rounded;
      case ActivityType.artworkUploaded:
        return Icons.cloud_upload_outlined;
      case ActivityType.artworkDeleted:
        return Icons.delete_outline_rounded;
      case ActivityType.assigneeChanged:
        return Icons.person_add_outlined;
      case ActivityType.priorityChanged:
        return Icons.flag_outlined;
      case ActivityType.completed:
        return Icons.check_circle_outline_rounded;
      case ActivityType.comment:
        return Icons.chat_bubble_outline_rounded;
    }
  }

  String _formatTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[timestamp.month - 1]} ${timestamp.day}';
    }
  }

  IconData _getFileIcon(String fileType) {
    switch (fileType.toUpperCase()) {
      case 'JPG':
      case 'JPEG':
      case 'PNG':
      case 'GIF':
        return Icons.image_rounded;
      case 'PDF':
        return Icons.picture_as_pdf_rounded;
      case 'ZIP':
      case 'RAR':
        return Icons.folder_zip_rounded;
      case 'FIG':
      case 'SKETCH':
      case 'XD':
        return Icons.design_services_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  String _formatDateLong(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Widget _buildSidebarSection(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFF64748B),
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSidebarItem(
    IconData icon,
    String label,
    bool isActive,
    int? count,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isActive
            ? const Color(0xFF4F46E5).withOpacity(0.15)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          icon,
          color: isActive ? const Color(0xFF818CF8) : const Color(0xFF94A3B8),
          size: 22,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : const Color(0xFFCBD5E1),
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            fontSize: 14,
          ),
        ),
        trailing: count != null && count > 0
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFF4F46E5)
                      : const Color(0xFF334155),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    color: isActive ? Colors.white : const Color(0xFF94A3B8),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            : null,
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _buildHeaderIconButton(IconData icon, VoidCallback onPressed,
      {bool badge = false}) {
    return Stack(
      children: [
        IconButton(
          onPressed: onPressed,
          icon: Icon(icon, size: 22),
          color: const Color(0xFF64748B),
          padding: const EdgeInsets.all(12),
        ),
        if (badge)
          Positioned(
            right: 10,
            top: 10,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFFEF4444),
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildModernStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
    Color bgColor,
    String change,
    bool isPositive,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isPositive
                      ? const Color(0xFFD1FAE5)
                      : const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      isPositive
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                      size: 12,
                      color: isPositive
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      change,
                      style: TextStyle(
                        color: isPositive
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            value,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: -1,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernTaskCard(Project project) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToTaskDetails(project),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _getStatusColor(project.status),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        project.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    _buildPriorityBadge(PriorityLevel.values.elementAt(project.priority).name),
                    const SizedBox(width: 12),
                    _buildModernStatusBadge(project.status),
                    const SizedBox(width: 8),
                    PopupMenuButton(
                      icon: const Icon(Icons.more_horiz_rounded,
                          color: Color(0xFF64748B)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'view',
                          onTap: () => _navigateToTaskDetails(project),
                          child: const Row(
                            children: [
                              Icon(Icons.visibility_rounded,
                                  size: 18, color: Color(0xFF64748B)),
                              SizedBox(width: 12),
                              Text('View Details'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_rounded,
                                  size: 18, color: Color(0xFF64748B)),
                              SizedBox(width: 12),
                              Text('Edit Project'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'duplicate',
                          child: Row(
                            children: [
                              Icon(Icons.copy_rounded,
                                  size: 18, color: Color(0xFF64748B)),
                              SizedBox(width: 12),
                              Text('Duplicate'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(child: Divider()),
                        PopupMenuItem(
                          value: 'delete',
                          onTap: () => _deleteTask(project),
                          child: const Row(
                            children: [
                              Icon(Icons.delete_rounded,
                                  size: 18, color: Color(0xFFEF4444)),
                              SizedBox(width: 12),
                              Text('Delete Project',
                                  style: TextStyle(color: Color(0xFFEF4444))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildInfoChip(
                      Icons.image_rounded,
                      '0 artworks',
                      const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 16),
                    _buildInfoChip(
                      Icons.person_outline_rounded,
                      'Unassigned',
                      const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 16),
                    _buildInfoChip(
                      Icons.schedule_rounded,
                      _formatDate(project.createdAt),
                      const Color(0xFF64748B),
                    ),
                  ],
                ),
                // if (project.artworks.isNotEmpty) ...[
                //   const SizedBox(height: 16),
                //   const Divider(),
                //   const SizedBox(height: 16),
                //   Wrap(
                //     spacing: 12,
                //     runSpacing: 12,
                //     children: project.artworks
                //         .take(3)
                //         .map((artwork) => _buildArtworkThumbnail(artwork))
                //         .toList(),
                //   ),
                //   if (project.artworks.length > 3)
                //     Padding(
                //       padding: const EdgeInsets.only(top: 12),
                //       child: Text(
                //         '+${project.artworks.length - 3} more',
                //         style: const TextStyle(
                //           fontSize: 13,
                //           color: Color(0xFF64748B),
                //           fontWeight: FontWeight.w600,
                //         ),
                //       ),
                //     ),
                // ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (ProjectStage.values.byName(status.toLowerCase())) {
      case ProjectStage.planning:
        return const Color(0xFF64748B);
      case ProjectStage.design:
        return const Color(0xFF3B82F6);
      case ProjectStage.production:
        return const Color(0xFF10B981);
      case ProjectStage.finishing:
        return const Color(0xFF8B5CF6);
      case ProjectStage.application:
        return const Color(0xFF8B5CF6);
      case ProjectStage.finished:
        return const Color(0xFF10B981);
      default: 
        return const Color(0xFF64748B);
    }
  }

  Widget _buildPriorityBadge(String priority) {
    Color color;
    IconData icon;

    switch (priority) {
      case 'Critical':
        color = const Color(0xFFEF4444);
        icon = Icons.priority_high_rounded;
        break;
      case 'High':
        color = const Color(0xFFF59E0B);
        icon = Icons.keyboard_arrow_up_rounded;
        break;
      case 'Medium':
        color = const Color(0xFF3B82F6);
        icon = Icons.drag_handle_rounded;
        break;
      default:
        color = const Color(0xFF64748B);
        icon = Icons.keyboard_arrow_down_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            priority,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernStatusBadge(String status) {
    Color color;
    Color bgColor;
    String label;
    IconData icon;

    // switch (status) {
    //   case TaskStatus.pending:
    //     color = const Color(0xFF64748B);
    //     bgColor = const Color(0xFFF1F5F9);
    //     label = 'Pending';
    //     icon = Icons.schedule_rounded;
    //     break;
    //   case TaskStatus.inProgress:
    //     color = const Color(0xFFF59E0B);
    //     bgColor = const Color(0xFFFEF3C7);
    //     label = 'In Progress';
    //     icon = Icons.autorenew_rounded;
    //     break;
    //   case TaskStatus.waitingApproval:
    //     color = const Color(0xFF8B5CF6);
    //     bgColor = const Color(0xFFF3E8FF);
    //     label = 'Pending Approval';
    //     icon = Icons.hourglass_empty_rounded;
    //     break;
    //   case TaskStatus.approved:
    //     color = const Color(0xFF10B981);
    //     bgColor = const Color(0xFFD1FAE5);
    //     label = 'Approved';
    //     icon = Icons.check_circle_rounded;
    //     break;
    //   case TaskStatus.revision:
    //     color = const Color(0xFFEF4444);
    //     bgColor = const Color(0xFFFEE2E2);
    //     label = 'Revision Needed';
    //     icon = Icons.edit_rounded;
    //     break;
    // }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildArtworkThumbnail(Artwork artwork) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _getFileIcon(artwork.fileType),
              size: 28,
              color: const Color(0xFF4F46E5),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              artwork.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF475569),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Today';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _deleteTask(DesignTask task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_rounded, color: Color(0xFFEF4444)),
            SizedBox(width: 12),
            Text('Delete Project'),
          ],
        ),
        content: Text('Are you sure you want to delete "${task.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                projects.removeWhere((t) => t.id == task.id);
                if (selectedProject?.id == task.id) {
                  selectedProject = null;
                }
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Project deleted successfully'),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: Color(0xFFEF4444),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showCreateTaskDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedPriority = 'Medium';
    String selectedAssignee = 'Sarah Johnson';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.add_circle_rounded, color: Color(0xFF4F46E5)),
              SizedBox(width: 12),
              Text(
                'Create New Project',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Project Name',
                      hintText: 'Enter project name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                    ),
                    autofocus: true,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Description (Optional)',
                      hintText: 'Enter project description',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedPriority,
                    decoration: InputDecoration(
                      labelText: 'Priority',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Low', child: Text('Low')),
                      DropdownMenuItem(value: 'Medium', child: Text('Medium')),
                      DropdownMenuItem(value: 'High', child: Text('High')),
                      DropdownMenuItem(
                          value: 'Critical', child: Text('Critical')),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        selectedPriority = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedAssignee,
                    decoration: InputDecoration(
                      labelText: 'Assign to',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: 'Sarah Johnson', child: Text('Sarah Johnson')),
                      DropdownMenuItem(
                          value: 'Michael Chen', child: Text('Michael Chen')),
                      DropdownMenuItem(
                          value: 'Emily Davis', child: Text('Emily Davis')),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        selectedAssignee = value!;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  setState(() {
                    projects.add(
                      DesignTask(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        name: nameController.text,
                        description: descriptionController.text.isNotEmpty
                            ? descriptionController.text
                            : null,
                        status: TaskStatus.pending,
                        artworks: [],
                        createdAt: DateTime.now(),
                        assignee: selectedAssignee,
                        priority: selectedPriority,
                      ),
                    );
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Project created successfully'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: Color(0xFF10B981),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text('Create Project'),
            ),
          ],
        ),
      ),
    );
  }

  void _showUploadArtworkDialog({DesignTask? preselectedTask}) {
    DesignTask? selectedTaskForUpload = preselectedTask;
    final nameController = TextEditingController();
    List<PlatformFile> selectedFiles = [];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.cloud_upload_rounded, color: Color(0xFF4F46E5)),
              SizedBox(width: 12),
              Text(
                'Upload Artwork',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 550,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select or create a project for this artwork:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<DesignTask>(
                    value: selectedTaskForUpload,
                    decoration: InputDecoration(
                      labelText: 'Select Project',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('→ Create new project...'),
                      ),
                      ...projects.map((task) => DropdownMenuItem(
                            value: task,
                            child: Text(task.name),
                          )),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        selectedTaskForUpload = value;
                      });
                    },
                  ),
                  if (selectedTaskForUpload == null) ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'New Project Name',
                        hintText: 'Enter project name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFE2E8F0),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.cloud_upload_rounded,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Drag and drop files here',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF475569),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'or',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () async {
                            try {
                              FilePickerResult? result =
                                  await FilePicker.platform.pickFiles(
                                allowMultiple: true,
                                type: FileType.custom,
                                allowedExtensions: [
                                  'jpg',
                                  'jpeg',
                                  'png',
                                  'gif',
                                  'pdf',
                                  'svg',
                                  'fig',
                                  'sketch',
                                  'xd',
                                  'zip',
                                  'rar'
                                ],
                              );

                              if (result != null) {
                                setDialogState(() {
                                  selectedFiles = result.files;
                                });
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error picking files: $e'),
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: const Color(0xFFEF4444),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.folder_open_rounded),
                          label: const Text('Browse Files'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4F46E5),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Supported: JPG, PNG, SVG, PDF, FIG, SKETCH (Max 10MB)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (selectedFiles.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Selected Files:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: selectedFiles.map((file) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.insert_drive_file_rounded,
                                  size: 20,
                                  color: Color(0xFF4F46E5),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    file.name,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                                Text(
                                  _formatBytes(file.size),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close_rounded,
                                      size: 18),
                                  onPressed: () {
                                    setDialogState(() {
                                      selectedFiles.remove(file);
                                    });
                                  },
                                  color: const Color(0xFF64748B),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedFiles.isEmpty
                  ? null
                  : () {
                      DesignTask targetTask;

                      if (selectedTaskForUpload == null) {
                        if (nameController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter a project name'),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: Color(0xFFEF4444),
                            ),
                          );
                          return;
                        }

                        targetTask = DesignTask(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          name: nameController.text,
                          status: TaskStatus.pending,
                          artworks: [],
                          createdAt: DateTime.now(),
                        );

                        setState(() {
                          projects.add(targetTask);
                        });
                      } else {
                        targetTask = selectedTaskForUpload!;
                      }

                      // Add artworks to task
                      setState(() {
                        for (var file in selectedFiles) {
                          final artwork = Artwork(
                            id: DateTime.now().millisecondsSinceEpoch.toString() +
                                file.name,
                            name: file.name,
                            path: file.path ?? '/uploads/${file.name}',
                            uploadedAt: DateTime.now(),
                            fileType: file.extension?.toUpperCase() ?? 'FILE',
                            fileSize: _formatBytes(file.size),
                          );

                          targetTask.artworks.add(artwork);
                          
                          // Add timeline activity for artwork upload
                          targetTask.timeline.add(
                            TimelineActivity(
                              id: '${DateTime.now().millisecondsSinceEpoch}_${file.name}',
                              type: ActivityType.artworkUploaded,
                              timestamp: DateTime.now(),
                              description: 'Uploaded ${file.name}',
                              actor: 'Admin User',
                              metadata: {'filename': file.name},
                            ),
                          );
                        }
                      });

                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              '${selectedFiles.length} artwork(s) uploaded successfully'),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: const Color(0xFF10B981),
                        ),
                      );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text('Upload'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  void _showMoveToNextStageDialog(DesignTask task) {
    TaskStatus nextStatus;
    String nextStageName;

    switch (task.status) {
      case TaskStatus.pending:
        nextStatus = TaskStatus.inProgress;
        nextStageName = 'In Progress';
        break;
      case TaskStatus.inProgress:
        nextStatus = TaskStatus.waitingApproval;
        nextStageName = 'Pending Approval';
        break;
      case TaskStatus.waitingApproval:
        nextStatus = TaskStatus.approved;
        nextStageName = 'Approved';
        break;
      default:
        return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.arrow_forward_rounded, color: Color(0xFF4F46E5)),
            SizedBox(width: 12),
            Text(
              'Advance Stage',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Move "${task.name}" to the next stage?',
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  _buildModernStatusBadge(task.status),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(Icons.arrow_forward_rounded,
                        size: 20, color: Color(0xFF64748B)),
                  ),
                  _buildModernStatusBadge(nextStatus),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                task.status = nextStatus;
                if (nextStatus == TaskStatus.approved) {
                  task.completedAt = DateTime.now();
                }
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Project moved to $nextStageName'),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: const Color(0xFF10B981),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}
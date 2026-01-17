import 'package:flutter/material.dart';
import 'package:smooflow/enums/navigation_page.dart';
import 'package:smooflow/enums/task_status.dart';
import 'package:smooflow/screens/components/desktop/sidebar.dart';
// Import your models
import 'package:smooflow/models/project.dart';
import 'package:smooflow/models/task.dart';
// Import your widgets
// import 'package:your_app/widgets/sidebar/sidebar.dart';
// import 'package:your_app/widgets/cards/project_card.dart';
// import 'package:your_app/widgets/cards/task_card.dart';

class DesignDashboardScreen extends StatefulWidget {
  const DesignDashboardScreen({Key? key}) : super(key: key);

  @override
  State<DesignDashboardScreen> createState() => _DesignDashboardScreenState();
}

class _DesignDashboardScreenState extends State<DesignDashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _pageAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  NavigationPage currentPage = NavigationPage.dashboard;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;
  
  List<Project> projects = [];
  List<Task> tasks = [];

  @override
  void initState() {
    super.initState();
    _pageAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
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

    _pageAnimationController.forward();
  }

  @override
  void dispose() {
    _pageAnimationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onPageChanged(NavigationPage page) {
    setState(() {
      currentPage = page;
    });
    _triggerPageTransition();
  }

  void _triggerPageTransition() {
    _pageAnimationController.reset();
    _pageAnimationController.forward();
  }

  // TODO: Implement filtering based on your models
  List<Project> get filteredItems {
    // Filter projects or tasks based on currentPage
    // Return filtered list
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: _buildContent(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    final totalProjects = projects.length;
    final pendingTasks = tasks.where((t) => t.status == TaskStatus.pending).length;
    final inProgressTasks = tasks.where((t) => t.status != TaskStatus.pending && t.status != TaskStatus.blocked && t.status != TaskStatus.completed && t.status != TaskStatus.paused).length;
    final awaitingApprovalTasks = tasks.where((t) => t.status == TaskStatus.waitingApproval).length;
    final completedTasks = tasks.where((t) => t.status == TaskStatus.completed).length;
    return Sidebar(
      currentPage: currentPage,
      onPageChanged: _onPageChanged,
      totalProjects: totalProjects,
      pendingTasksCount: pendingTasks,
      inProgressTasksCount: inProgressTasks,
      awaitingApprovalTasksCount: awaitingApprovalTasks,
      completedTasksCount: completedTasks,
    );
  }

  Widget _buildHeader() {
    String title = 'Projects Dashboard';
    String subtitle = 'Manage your design projects and tasks';

    switch (currentPage) {
      case NavigationPage.allProjects:
        title = 'All Projects';
        subtitle = 'Complete overview of all projects';
        break;
      case NavigationPage.pendingTasks:
        title = 'Pending Tasks';
        subtitle = 'Tasks waiting to be started';
        break;
      case NavigationPage.inProgressTasks:
        title = 'In Progress Tasks';
        subtitle = 'Tasks currently being worked on';
        break;
      case NavigationPage.awaitingApprovalTasks:
        title = 'Awaiting Approval';
        subtitle = 'Tasks pending client approval';
        break;
      case NavigationPage.completedTasks:
        title = 'Completed Tasks';
        subtitle = 'Successfully completed tasks';
        break;
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
                  title,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          _buildSearchBar(),
          const SizedBox(width: 12),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: _isSearching ? 320 : 0,
      child: _isSearching
          ? Container(
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4F46E5).withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search projects, tasks...',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: Color(0xFF4F46E5),
                    size: 20,
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Color(0xFF64748B),
                      size: 18,
                    ),
                    onPressed: () {
                      setState(() {
                        _isSearching = false;
                        _searchController.clear();
                        _searchQuery = '';
                      });
                    },
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: Color(0xFFE2E8F0),
                      width: 1.5,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: Color(0xFFE2E8F0),
                      width: 1.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: Color(0xFF4F46E5),
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            )
          : const SizedBox(),
    );
  }

  Widget _buildActionButtons() {
    final showTaskActions = currentPage != NavigationPage.dashboard &&
        currentPage != NavigationPage.allProjects;

    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: IconButton(
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
              });
            },
            icon: const Icon(Icons.search_rounded),
            color: const Color(0xFF64748B),
          ),
        ),
        const SizedBox(width: 12),
        if (showTaskActions)
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
              side: const BorderSide(
                color: Color(0xFFE2E8F0),
                width: 1.5,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
              elevation: 0,
            ),
          ),
        if (showTaskActions) const SizedBox(width: 10),
        ElevatedButton.icon(
          onPressed: _showCreateDialog,
          icon: const Icon(Icons.add_rounded, size: 20),
          label: Text(
            showTaskActions ? 'New Task' : 'New Project',
            style: const TextStyle(fontWeight: FontWeight.w600),
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
    );
  }

  Widget _buildContent() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(40),
          child: _getContentForCurrentPage(),
        ),
      ),
    );
  }

  Widget _getContentForCurrentPage() {
    switch (currentPage) {
      case NavigationPage.dashboard:
      case NavigationPage.allProjects:
        return _buildProjectsGrid();
      case NavigationPage.pendingTasks:
      case NavigationPage.inProgressTasks:
      case NavigationPage.awaitingApprovalTasks:
      case NavigationPage.completedTasks:
        return _buildTasksList();
      default:
        return _buildProjectsGrid();
    }
  }

  Widget _buildProjectsGrid() {
    // TODO: Replace with actual filtered projects
    final filteredProjects = filteredItems as List<Project>;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (currentPage == NavigationPage.dashboard) ...[
          _buildStatsCards(),
          const SizedBox(height: 32),
        ],
        const Text(
          'Projects',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 20),
        // GridView of ProjectCard widgets
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            childAspectRatio: 1.4,
          ),
          itemCount: filteredProjects.length,
          itemBuilder: (context, index) {
            // return ProjectCard(...)
            return Container();
          },
        ),
      ],
    );
  }

  Widget _buildTasksList() {
    // TODO: Replace with actual filtered tasks
    // final filteredTasks = filteredItems as List<Task>;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tasks',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 20),
        // ListView of TaskCard widgets
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 0, // filteredTasks.length
          itemBuilder: (context, index) {
            // return TaskCard(...)
            return Container();
          },
        ),
      ],
    );
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Projects',
            '0', // projects.length.toString()
            Icons.folder_rounded,
            const Color(0xFF4F46E5),
            const Color(0xFFEEF2FF),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: _buildStatCard(
            'Pending Tasks',
            '0',
            Icons.schedule_rounded,
            const Color(0xFF64748B),
            const Color(0xFFF1F5F9),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: _buildStatCard(
            'In Progress',
            '0',
            Icons.autorenew_rounded,
            const Color(0xFFF59E0B),
            const Color(0xFFFEF3C7),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: _buildStatCard(
            'Completed',
            '0',
            Icons.check_circle_rounded,
            const Color(0xFF10B981),
            const Color(0xFFD1FAE5),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
    Color bgColor,
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
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
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

  void _showCreateDialog() {
    // TODO: Show create project or task dialog based on currentPage
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          currentPage == NavigationPage.dashboard ||
                  currentPage == NavigationPage.allProjects
              ? 'Create Project Dialog'
              : 'Create Task Dialog',
        ),
      ),
    );
  }

  void _showUploadArtworkDialog() {
    // TODO: Show upload artwork dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Upload Artwork Dialog')),
    );
  }
}
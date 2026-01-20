import 'package:flutter/material.dart';
import 'package:smooflow/core/models/user.dart';
import 'package:smooflow/core/services/login_service.dart';
import 'package:smooflow/enums/navigation_page.dart';
import 'package:smooflow/constants.dart';

class Sidebar extends StatelessWidget {
  final NavigationPage currentPage;
  final Function(NavigationPage) onPageChanged;
  final int totalProjects;
  final int pendingTasksCount;
  final int inProgressTasksCount;
  final int awaitingApprovalTasksCount;
  final int completedTasksCount;
  final int blockedTasksCount;

  const Sidebar({
    Key? key,
    required this.currentPage,
    required this.onPageChanged,
    required this.totalProjects,
    required this.pendingTasksCount,
    required this.inProgressTasksCount,
    required this.awaitingApprovalTasksCount,
    required this.completedTasksCount,
    required this.blockedTasksCount
  }) : super(key: key);

  User get currentUser => LoginService.currentUser!;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.fromARGB(255, 15, 39, 91),
            Color.fromARGB(255, 15, 23, 43),
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
          _buildHeader(),
          const Divider(height: 1, color: Color(0xFF334155)),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildSidebarSection('Overview'),
                _buildSidebarItem(
                  Icons.dashboard_rounded,
                  'Dashboard',
                  currentPage == NavigationPage.dashboard,
                  0,
                  () => onPageChanged(NavigationPage.dashboard),
                ),
                const SizedBox(height: 20),
                _buildSidebarSection('Projects'),
                _buildSidebarItem(
                  Icons.folder_rounded,
                  'All Projects',
                  currentPage == NavigationPage.allProjects,
                  totalProjects,
                  () => onPageChanged(NavigationPage.allProjects),
                ),
                const SizedBox(height: 20),
                _buildSidebarSection('Design Tasks'),
                _buildSidebarItem(
                  Icons.schedule_rounded,
                  'Pending',
                  currentPage == NavigationPage.pendingTasks,
                  pendingTasksCount,
                  () => onPageChanged(NavigationPage.pendingTasks),
                ),
                _buildSidebarItem(
                  Icons.pending_actions_rounded,
                  'In Progress',
                  currentPage == NavigationPage.inProgressTasks,
                  inProgressTasksCount,
                  () => onPageChanged(NavigationPage.inProgressTasks),
                ),
                _buildSidebarItem(
                  Icons.hourglass_empty_rounded,
                  'Awaiting Approval',
                  currentPage == NavigationPage.awaitingApprovalTasks,
                  awaitingApprovalTasksCount,
                  () => onPageChanged(NavigationPage.awaitingApprovalTasks),
                ),
                _buildSidebarItem(
                  Icons.check_circle_rounded,
                  'Completed',
                  currentPage == NavigationPage.completedTasks,
                  completedTasksCount,
                  () => onPageChanged(NavigationPage.completedTasks),
                ),
                _buildSidebarItem(
                  Icons.block_rounded,
                  'Blocked',
                  currentPage == NavigationPage.blocked,
                  blockedTasksCount,
                  () => onPageChanged(NavigationPage.blocked),
                ),
              ],
            ),
          ),
          _buildUserProfile(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(28.0),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF6366F1), colorPrimary],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: colorPrimary.withOpacity(0.3),
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
                  'Smooflow',
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
    );
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
            ? colorPrimary.withOpacity(0.15)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          icon,
          color: isActive ? const Color.fromARGB(255, 90, 130, 216) : const Color(0xFF94A3B8),
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
                      ? colorPrimary
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

  Widget _buildUserProfile() {
    return Container(
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
              color: colorPrimary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                currentUser.initials,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentUser.displayName,
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
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooflow/constants.dart';
import 'package:smooflow/core/api/api_logger.dart'; // Ensure correct logger import path
import 'package:smooflow/core/models/project.dart';
import 'package:smooflow/providers/task_provider.dart';
import 'package:smooflow/screens/desktop/components/delete_project_dialog.dart';
import 'package:smooflow/screens/desktop/components/notification_toast.dart';

class _T {
  static const Color white = Colors.white;
  static const red = Color(0xFFEF4444);
  static const Color slate50 = Color(0xFFF8FAFC);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate500 = Color(0xFF64748B);
  static const slate600 = Color(0xFF475569);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate800 = Color(0xFF1E293B);
  static const Color ink = Color(0xFF0F172A);
  static const Color ink3 = Color(0xFF1E293B);
  static const Color blue = Color(0xFF2563EB);
  static const double r = 8.0;
}

enum ProjectFilter { incomplete, all, completed }

class DesktopProjectsScreen extends StatefulWidget {
  final List<Project> initialProjects;
  final ValueChanged<String> onProjectSelected;
  final ValueChanged<String> onTogglePinProject;

  const DesktopProjectsScreen({
    super.key,
    required this.initialProjects,
    required this.onProjectSelected,
    required this.onTogglePinProject,
  });

  @override
  State<DesktopProjectsScreen> createState() => _DesktopProjectsScreenState();
}

class _DesktopProjectsScreenState extends State<DesktopProjectsScreen> {
  ProjectFilter _currentFilter = ProjectFilter.incomplete;
  String _searchQuery = "";
  String? _selectedPriorityFilter;

  static const String _pinnedProjectsKey = 'pinned_project_ids';
  List<String> _pinnedProjectIds = [];

  @override
  void initState() {
    super.initState();
    _loadPinsSync();
  }

  Future<void> _loadPinsSync() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _pinnedProjectIds = prefs.getStringList(_pinnedProjectsKey) ?? [];
      });
    } catch (e, s) {
      await AppLogger.logError(
        message: "Failed syncing projects list pins",
        error: e,
        stackTrace: s,
      );
    }
  }

  Future<void> _togglePinCard(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final current = List<String>.from(_pinnedProjectIds);
      if (current.contains(id)) {
        current.remove(id);
      } else {
        current.add(id);
      }
      await prefs.setStringList(_pinnedProjectsKey, current);
      setState(() {
        _pinnedProjectIds = current;
      });

      widget.onTogglePinProject(id);
    } catch (e, s) {
      await AppLogger.logError(
        message: "Error processing persistent local pin toggles",
        error: e,
        stackTrace: s,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredProjects =
        widget.initialProjects.where((project) {
          final isCompleted =
              project.tasksCount == project.completedTasksCount &&
              project.tasksCount > 0;

          if (_currentFilter == ProjectFilter.incomplete && isCompleted)
            return false;
          if (_currentFilter == ProjectFilter.completed && !isCompleted)
            return false;

          if (_searchQuery.isNotEmpty) {
            final matchesName = project.name.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            );
            final matchesClient = project.client.name.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            );
            if (!matchesName && !matchesClient) return false;
          }

          if (_selectedPriorityFilter != null) {
            if (_selectedPriorityFilter == "High" && project.priority < 2)
              return false;
            if (_selectedPriorityFilter == "Normal" && project.priority != 1)
              return false;
            if (_selectedPriorityFilter == "Low" && project.priority != 0)
              return false;
          }
          return true;
        }).toList();

    filteredProjects.sort((a, b) => b.priority.compareTo(a.priority));

    return Scaffold(
      backgroundColor: _T.slate50,
      body: Column(
        children: [
          _Topbar(
            currentFilter: _currentFilter,
            onFilterChanged:
                (filter) => setState(() => _currentFilter = filter),
            onSearchChanged: (val) => setState(() => _searchQuery = val),
            selectedPriority: _selectedPriorityFilter,
            onPriorityChanged:
                (val) => setState(() => _selectedPriorityFilter = val),
          ),
          Expanded(
            child:
                filteredProjects.isEmpty
                    ? _buildEmptyState()
                    : GridView.builder(
                      padding: const EdgeInsets.all(24),
                      itemCount: filteredProjects.length,
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 380,
                            mainAxisExtent: 220,
                            crossAxisSpacing: 18,
                            mainAxisSpacing: 18,
                          ),
                      itemBuilder: (context, index) {
                        final p = filteredProjects[index];
                        return _ProjectCard(
                          project: p,
                          isPinned: _pinnedProjectIds.contains(p.id),
                          onPinToggled: () => _togglePinCard(p.id),
                          onTap: () => widget.onProjectSelected(p.id),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        width: 420,
        padding: const EdgeInsets.all(32),
        // textAlign: TextAlign.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 64,
              width: 64,
              decoration: const BoxDecoration(
                color: _T.slate100,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                CupertinoIcons.folder_badge_minus,
                size: 28,
                color: _T.slate400,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _currentFilter == ProjectFilter.incomplete
                  ? 'No Active Projects'
                  : 'No Matches Found',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _T.ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _currentFilter == ProjectFilter.incomplete
                  ? 'All pending operational tasks are caught up. Review historical files instead.'
                  : 'Try loosening your filter parameters or search queries.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: _T.slate400,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            if (_currentFilter == ProjectFilter.incomplete)
              TextButton(
                onPressed:
                    () => setState(() => _currentFilter = ProjectFilter.all),
                style: TextButton.styleFrom(foregroundColor: _T.blue),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'All Projects',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward_rounded, size: 14),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Dropdown / Input Header Components Filter Topbar ─────────────────────────
class _Topbar extends StatelessWidget {
  final ProjectFilter currentFilter;
  final ValueChanged<ProjectFilter> onFilterChanged;
  final ValueChanged<String> onSearchChanged;
  final String? selectedPriority;
  final ValueChanged<String?> onPriorityChanged;

  const _Topbar({
    required this.currentFilter,
    required this.onFilterChanged,
    required this.onSearchChanged,
    required this.selectedPriority,
    required this.onPriorityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: _T.white,
        border: Border(bottom: BorderSide(color: _T.slate200)),
      ),
      child: Row(
        children: [
          const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Projects Matrix',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _T.ink,
                  letterSpacing: -0.2,
                ),
              ),
              Text(
                'Production execution and client delivery timelines',
                style: TextStyle(
                  fontSize: 11,
                  color: _T.slate400,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(width: 32),
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: _T.slate100,
              borderRadius: BorderRadius.circular(_T.r),
            ),
            child: Row(
              children: [
                _FilterTab(
                  label: 'Incomplete',
                  isActive: currentFilter == ProjectFilter.incomplete,
                  onTap: () => onFilterChanged(ProjectFilter.incomplete),
                ),
                _FilterTab(
                  label: 'All Files',
                  isActive: currentFilter == ProjectFilter.all,
                  onTap: () => onFilterChanged(ProjectFilter.all),
                ),
                _FilterTab(
                  label: 'Completed',
                  isActive: currentFilter == ProjectFilter.completed,
                  onTap: () => onFilterChanged(ProjectFilter.completed),
                ),
              ],
            ),
          ),
          const Spacer(),
          Container(
            width: 240,
            height: 36,
            decoration: BoxDecoration(
              color: _T.slate50,
              borderRadius: BorderRadius.circular(_T.r),
              border: Border.all(color: _T.slate200),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Icon(CupertinoIcons.search, size: 16, color: _T.slate400),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    onChanged: onSearchChanged,
                    style: const TextStyle(fontSize: 13, color: _T.ink),
                    decoration: const InputDecoration(
                      hintText: 'Search operations or client...',
                      hintStyle: TextStyle(color: _T.slate400, fontSize: 13),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(_T.r),
              border: Border.all(color: _T.slate200),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedPriority,
                hint: const Text(
                  'Priority',
                  style: TextStyle(fontSize: 13, color: _T.slate500),
                ),
                icon: const Icon(Icons.arrow_drop_down, color: _T.slate400),
                style: const TextStyle(fontSize: 13, color: _T.ink),
                onChanged: onPriorityChanged,
                items:
                    ['Low', 'Normal', 'High']
                        .map(
                          (String val) => DropdownMenuItem<String>(
                            value: val,
                            child: Text(val),
                          ),
                        )
                        .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterTab extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  const _FilterTab({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? _T.white : Colors.transparent,
          borderRadius: BorderRadius.circular(_T.r - 2),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            color: isActive ? _T.ink : _T.slate500,
          ),
        ),
      ),
    );
  }
}

// ── Interactive Project Card implementation with Pin Toggles ──────────────────
class _ProjectCard extends ConsumerWidget {
  final Project project;
  final bool isPinned;
  final VoidCallback onPinToggled;
  final VoidCallback onTap;

  const _ProjectCard({
    required this.project,
    required this.isPinned,
    required this.onPinToggled,
    required this.onTap,
  });

  void _showContextMenu(
    BuildContext context,
    TapUpDetails details,
    bool canDeleteProject,
  ) async {
    // 1. Locate the absolute global overlay layout boundary
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    // 2. Derive bounding vectors exactly where the cursor is pointing
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromLTWH(details.globalPosition.dx, details.globalPosition.dy, 0, 0),
      Offset.zero & overlay.size,
    );

    // 3. Render a native desktop-behaving Material PopupMenu
    final result = await showMenu<String>(
      context: context,
      position: position,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: _T.slate200, width: 1),
      ),
      color: _T.white,
      surfaceTintColor: Colors.transparent,
      items: [
        PopupMenuItem<String>(
          value: 'open',
          height: 36,
          child: Row(
            children: [
              Icon(Icons.open_in_new_rounded, size: 16, color: _T.slate600),
              const SizedBox(width: 10),
              const Text(
                'Open Project',
                style: TextStyle(fontSize: 13, color: _T.slate800),
              ),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'toggle_pin',
          height: 36,
          child: Row(
            children: [
              Icon(
                isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                size: 16,
                color: _T.slate600,
              ),
              const SizedBox(width: 10),
              Text(
                isPinned ? 'Unpin from Sidebar' : 'Pin to Sidebar',
                style: const TextStyle(fontSize: 13, color: _T.slate800),
              ),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'copy_id',
          height: 36,
          child: Row(
            children: [
              Icon(Icons.copy_rounded, size: 16, color: _T.slate600),
              const SizedBox(width: 10),
              Text(
                'Copy Project ID',
                style: const TextStyle(fontSize: 13, color: _T.slate800),
              ),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'delete_id',
          height: 36,
          enabled: canDeleteProject,
          child: Row(
            children: [
              Icon(Icons.delete_outline_rounded, size: 16, color: _T.red),
              const SizedBox(width: 10),
              Opacity(
                opacity: canDeleteProject ? 1 : 0.4,
                child: Text(
                  'Delete ${canDeleteProject ? 'Project' : '(Unavailable)'}',
                  style: const TextStyle(fontSize: 13, color: _T.red),
                ),
              ),
            ],
          ),
        ),
      ],
    );

    // 4. Handle menu item selection callbacks
    if (!context.mounted) return;
    switch (result) {
      case 'open':
        onTap();
        break;
      case 'toggle_pin':
        onPinToggled();
        break;
      case 'copy_id':
        await Clipboard.setData(ClipboardData(text: project.id.toString()));
        AppToast.show(
          message: 'Project ID copied',
          icon: Icons.check_circle_outline,
          color: _T.blue,
        );
        break;
      case 'delete_id':
        // Show the elegant desktop-style delete confirmation dialog
        showDialog(
          context: context,
          barrierDismissible:
              false, // Prevents accidental closing during network requests
          builder: (context) => DeleteProjectDialog(project: project),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalTasks = project.tasksCount;
    final doneTasks = project.completedTasksCount;
    final double percent = totalTasks == 0 ? 0.0 : (doneTasks / totalTasks);
    final DateFormat formatter = DateFormat('MMM dd, yyyy');

    final canDeleteProject =
        ref
            .watch(taskNotifierProvider)
            .tasks
            .where((t) => t.projectId == project.id)
            .isEmpty;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior:
            HitTestBehavior.opaque, // Ensures the entire box is right-clickable
        onTap: onTap,
        onSecondaryTapUp:
            (details) => _showContextMenu(
              context,
              details,
              canDeleteProject,
            ), // Handles Right-Click
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _T.white,
            borderRadius: BorderRadius.circular(_T.r),
            border: Border.all(color: _T.slate200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.01),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.only(top: 4.5),
                    decoration: BoxDecoration(
                      color: project.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          project.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _T.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          project.client.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: _T.slate500,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Interactive Pin Toggle Button Icon
                  IconButton(
                    icon: Icon(
                      isPinned
                          ? Icons.push_pin_rounded
                          : Icons.push_pin_outlined,
                      size: 14,
                    ),
                    color: isPinned ? _T.blue : _T.slate400,
                    tooltip:
                        isPinned ? 'Unpin project' : 'Pin project to sidebar',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    splashRadius: 16,
                    onPressed: () {
                      onPinToggled();
                    },
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: project.priorityColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      project.priority >= 2
                          ? 'High'
                          : (project.priority == 1 ? 'Normal' : 'Low'),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: project.priorityColor,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              if (project.description != null &&
                  project.description!.isNotEmpty) ...[
                Text(
                  project.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: _T.slate400,
                    height: 1.4,
                  ),
                ),
                const Spacer(),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tasks: $doneTasks/$totalTasks completed',
                    style: const TextStyle(
                      fontSize: 11,
                      color: _T.slate500,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${(percent * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontSize: 11,
                      color: _T.ink3,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: percent,
                  minHeight: 5,
                  backgroundColor: _T.slate100,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    percent == 1.0 ? colorPositiveStatus : _T.blue,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Divider(color: _T.slate100, height: 1),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    CupertinoIcons.calendar,
                    size: 13,
                    color: _T.slate400,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    project.dueDate != null
                        ? 'Due ${formatter.format(project.dueDate!)}'
                        : 'No static deadline',
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: _T.slate400,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: project.statusColor.withOpacity(0.3),
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      project.status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: project.statusColor,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

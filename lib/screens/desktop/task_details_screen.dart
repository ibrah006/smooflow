import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/constants.dart';
import 'package:smooflow/enums/task_status.dart';
import 'package:smooflow/core/models/task.dart';
import 'package:smooflow/providers/project_provider.dart';
import 'package:smooflow/providers/task_provider.dart';
import 'package:smooflow/components/desktop/advance_stage_popup.dart';

// TODO: Import your models
// import 'package:your_app/models/task.dart';
// import 'package:your_app/models/artwork.dart';

class TaskDetailsScreen extends ConsumerStatefulWidget {
  final int taskId;
  // final Task task;

  const TaskDetailsScreen({
    Key? key,
    required this.taskId,
    // required this.task,
  }) : super(key: key);

  @override
  ConsumerState<TaskDetailsScreen> createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends ConsumerState<TaskDetailsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // GlobalKey for the button
  final GlobalKey _advanceButtonKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.05, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Task get task => ref.watch(taskByIdProviderSimple(widget.taskId))!;

  String get taskName => task.name;
  String get projectName => ref.watch(projectByIdProvider(task.projectId))!.name;
  String? get description => task.description;
  // TODO
  String? get assignee => null;
  // TODO
  String? get priority => null;
  bool autoMoveToNext = false;
  // TODO
  DateTime get createdAt => DateTime.now().subtract(const Duration(days: 4));
  List<dynamic> get artworks => []; // Replace with List<Artwork>

  TaskStatus get status => task.status;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
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
                            _buildTaskInfoCard(),
                            const SizedBox(height: 24),
                            if (description != null) _buildDescriptionCard(),
                            if (description != null) const SizedBox(height: 24),
                            _buildArtworksSection(),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        flex: 1,
                        child: Column(
                          children: [
                            _buildSettingsCard(),
                            const SizedBox(height: 24),
                            _buildActivityCard(),
                          ],
                        ),
                      ),
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

  Widget _buildHeader() {
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
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded),
            color: const Color(0xFF64748B),
            tooltip: 'Back to project',
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  taskName,
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
                    Icon(
                      Icons.folder_rounded,
                      size: 14,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Project: $projectName',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(width: 12),
                    _buildStatusBadge(status),
                    if (priority != null) ...[
                      const SizedBox(width: 8),
                      _buildPriorityBadge(priority!),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (task.status.nextStage == TaskStatus.printing) ...[
            ElevatedButton.icon(
              onPressed: approveDesignStage,
              icon: const Icon(Icons.check_rounded, size: 18),
              label: const Text('Approve Deisgn Stage'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                elevation: 0,
              ),
            ),
            SizedBox(width: 10)
          ],
          if (status != TaskStatus.clientApproved)
            ElevatedButton.icon(
              key: _advanceButtonKey,
              onPressed: task.status.nextStage == TaskStatus.printing? null : _showMoveToNextStageDialog,
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              label: const Text('Advance Stage'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                elevation: 0,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTaskInfoCard() {
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
                child: const Icon(
                  Icons.info_outline_rounded,
                  color: colorPrimary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Task Details',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildDetailRow('Assignee', assignee ?? 'Unassigned'),
          _buildDetailRow('Created', _formatDateLong(createdAt)),
          _buildDetailRow('Total Artworks', '${artworks.length}'),
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

  Widget _buildDescriptionCard() {
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
                child: const Icon(
                  Icons.description_outlined,
                  color: colorPrimary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Description',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            description!,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF475569),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArtworksSection() {
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
                      color: colorPrimary,
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
                      '${artworks.length}',
                      style: const TextStyle(
                        color: colorPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _showUploadArtworkDialog,
                icon: const Icon(Icons.cloud_upload_rounded, size: 18),
                label: const Text('Upload'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (artworks.isEmpty)
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
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1,
              ),
              itemCount: artworks.length,
              itemBuilder: (context, index) {
                return _buildArtworkCard(index);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildArtworkCard(int index) {
    // TODO: Use actual artwork data
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
              child: const Center(
                child: Icon(
                  Icons.image_rounded,
                  size: 48,
                  color: colorPrimary,
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
                  'Artwork ${index + 1}.jpg',
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
                      child: const Text(
                        'JPG',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: colorPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      '2.4 MB',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
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
              Icon(Icons.settings_rounded, color: colorPrimary, size: 20),
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
          Container(
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
                      const Text(
                        'Auto-advance',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Automatically move to next stage',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: autoMoveToNext,
                  onChanged: (value) {
                    setState(() {
                      autoMoveToNext = value;
                    });
                  },
                  activeColor: const Color(0xFF10B981),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard() {
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
              Icon(
                Icons.history_rounded,
                color: colorPrimary,
                size: 20,
              ),
              SizedBox(width: 10),
              Text(
                'Activity Timeline',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildActivityItem(
            'Task created',
            _formatDateLong(createdAt),
            Icons.add_circle_outline_rounded,
            const Color(0xFF3B82F6),
          ),
          _buildActivityItem(
            'Status changed to In Progress',
            'Jan 15, 2026',
            Icons.swap_horiz_rounded,
            const Color(0xFF8B5CF6),
          ),
          // Add more activity items from task.timeline
        ],
      ),
    );
  }

  Widget _buildActivityItem(
    String title,
    String time,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  time,
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

  Widget _buildStatusBadge(TaskStatus status) {
   late final Color color;
    late final String label;

    switch (status) {
      case TaskStatus.pending:
        color = const Color(0xFF64748B);
        label = 'Pending';
        break;
      case TaskStatus.waitingApproval:
        color = const Color(0xFF8B5CF6);
        label = 'Pending Approval';
        break;
      case TaskStatus.clientApproved:
        color = const Color(0xFF10B981);
        label = 'Approved';
        break;
      case TaskStatus.revision:
        color = const Color(0xFFEF4444);
        label = 'Needs Revision';
        break;
      case TaskStatus.blocked:
        color = const Color(0xFFF59E0B);
        label = 'Blocked';
        break;
      case TaskStatus.completed:
        color = const Color(0xFF3B82F6);
        label = 'Completed';
        break;
      default: break;
    }

    try {
      if (task.isInProgress) {
        color = const Color(0xFFF59E0B);
        label = 'In Progress';
      }
    } catch(e) {
      // Already initialized
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildPriorityBadge(String priority) {
    Color color;
    switch (priority.toLowerCase()) {
      case 'critical':
        color = const Color(0xFFEF4444);
        break;
      case 'high':
        color = const Color(0xFFF59E0B);
        break;
      case 'medium':
        color = const Color(0xFF3B82F6);
        break;
      default:
        color = const Color(0xFF64748B);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        priority,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
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

  void _showUploadArtworkDialog() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
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
          'zip'
        ],
      );

      if (result != null && mounted) {
        // TODO: Handle file upload
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${result.files.length} file(s) selected for upload'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking files: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  void approveDesignStage() async {
    await ref.watch(taskNotifierProvider.notifier).progressStage(taskId: widget.taskId, newStatus: TaskStatus.clientApproved);
    setState(() {});
  }

  void _showMoveToNextStageDialog() {

    AdvanceStagePopup.show(
      context: context,
      buttonKey: _advanceButtonKey,
      taskId: task.id,
      onConfirm: (notes) async {
        await ref.watch(taskNotifierProvider.notifier).progressStage(taskId: widget.taskId, newStatus: task.status.nextStage);
        setState(() {
          // Update task status
          // task.status = getNextStatus(task.status);
        });
        
        if (notes != null) {
          // Save notes to activity timeline
          // task.addActivity(notes);
        }
      },
    );
  }
}
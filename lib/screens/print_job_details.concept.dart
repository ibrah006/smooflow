// lib/screens/printer/print_job_details_screen.dart
import 'dart:math';

import 'package:cupertino_calendar_picker/cupertino_calendar_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/enums/task_status.dart';
import 'package:smooflow/extensions/date_time_format.dart';
import 'package:smooflow/models/printer.dart';
import 'package:smooflow/models/task.dart';
import 'package:smooflow/providers/material_provider.dart';
import 'package:smooflow/providers/printer_provider.dart';
import 'package:smooflow/providers/project_provider.dart';
import 'package:smooflow/providers/task_provider.dart';

class PrintJobDetailsScreen extends ConsumerStatefulWidget {
  final Task task;

  const PrintJobDetailsScreen({
    Key? key,
    required this.task,
  }) : super(key: key);

  @override
  ConsumerState<PrintJobDetailsScreen> createState() =>
      _PrintJobDetailsScreenState();
}

class _PrintJobDetailsScreenState extends ConsumerState<PrintJobDetailsScreen>
    with SingleTickerProviderStateMixin {
  static const MONTHS = [
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

  late TextEditingController _runsController;
  late TextEditingController _notesController;

  String? _selectedPrinterId;
  JobPriority _selectedPriority = JobPriority.medium;
  int _estimatedDuration = 30;
  bool _requiresApplication = false;
  String? _applicationLocation;
  DateTime? _selectedStartDateTime;

  ExpansionTileController _dateTimeExpansionController =
      ExpansionTileController();

  // Animation controller for printer selection
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  bool _showPrinterSelection = false;
  bool _isAssigningPrinter = false;

  bool get showBottomAction => widget.task.printerId == null;
  bool get isOldVersion => widget.task.isDeprecated;

  @override
  void initState() {
    super.initState();
    _runsController = TextEditingController(text: widget.task.runs.toString());
    _notesController = TextEditingController(text: widget.task.description);
    _estimatedDuration = widget.task.productionDuration;
    _selectedPrinterId = widget.task.printerId;
    _selectedStartDateTime = widget.task.productionStartTime;

    // Initialize animation
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _runsController.dispose();
    _notesController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _showPrinterSelectionPage() {
    setState(() => _showPrinterSelection = true);
    _animationController.forward();
  }

  void _hidePrinterSelectionPage() {
    _animationController.reverse().then((_) {
      setState(() => _showPrinterSelection = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final printers = ref.watch(printerNotifierProvider).printers;
    final projects = ref.watch(projectNotifierProvider);
    final materials = ref.watch(materialNotifierProvider).materials;

    return WillPopScope(
      onWillPop: () async {
        if (_showPrinterSelection) {
          _hidePrinterSelectionPage();
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () {
              if (_showPrinterSelection) {
                _hidePrinterSelectionPage();
              } else {
                Navigator.pop(context);
              }
            },
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _showPrinterSelection ? 'Select Printer' : 'Print Job Details',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              if (!_showPrinterSelection && isOldVersion)
                Row(
                  children: const [
                    Icon(Icons.priority_high_rounded,
                        size: 14, color: Colors.redAccent),
                    SizedBox(width: 4),
                    Text(
                      "Deprecated",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.redAccent,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        body: Stack(
          children: [
            // Main details view
            _buildDetailsView(projects, materials),

            // Printer selection overlay
            if (_showPrinterSelection)
              SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildPrinterSelectionView(printers),
                ),
              ),
          ],
        ),
        bottomNavigationBar: _buildBottomAction(printers),
      ),
    );
  }

  Widget _buildDetailsView(projects, materials) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Job Details Card
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
                      'Print Job Details',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildDetailRow(
                      'Project',
                      projects
                          .firstWhere(
                              (project) => project.id == widget.task.projectId)
                          .name,
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      'Material',
                      materials
                          .firstWhere(
                              (material) => material.id == widget.task.materialId)
                          .name,
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      'Runs / Batches',
                      _runsController.text,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Printer Assignment Card
              _buildSectionCard(
                icon: Icons.print,
                iconColor: const Color(0xFF9333EA),
                title: "Printer Assignment",
                child: _buildPrinterAssignmentSection(),
              ),

              const SizedBox(height: 16),

              // Priority
              _buildSectionCard(
                icon: Icons.flag,
                iconColor: const Color(0xFFEF4444),
                title: 'Priority Level',
                child: _buildPriorityDisplay(),
              ),

              const SizedBox(height: 16),

              // Application/Installation
              if (_requiresApplication)
                _buildSectionCard(
                  icon: Icons.construction,
                  iconColor: const Color(0xFF8B5CF6),
                  title: 'Application / Installation',
                  child: _buildApplicationDisplay(),
                ),

              if (_requiresApplication) const SizedBox(height: 16),

              // Duration & Start Time
              _buildSectionCard(
                icon: Icons.schedule,
                iconColor: const Color(0xFF2563EB),
                title: 'Est. Duration & Start Time',
                child: _buildDurationDisplay(),
              ),

              const SizedBox(height: 16),

              // Notes
              if (_notesController.text.isNotEmpty)
                _buildSectionCard(
                  icon: Icons.notes,
                  iconColor: const Color(0xFF6B7280),
                  title: 'Notes',
                  child: _buildNotesDisplay(),
                ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPrinterSelectionView(List<Printer> printers) {
    return Container(
      color: const Color(0xFFF5F7FA),
      child: Column(
        children: [
          // Header with illustration
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: const Color(0xFF9333EA).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.print_rounded,
                    size: 60,
                    color: Color(0xFF9333EA),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Select a Printer',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Job will start automatically after assignment',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),

          // Printers list
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Available Printers',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                ...printers
                    .where((p) => p.status == PrinterStatus.active)
                    .map((printer) => _buildPrinterOption(printer, true)),
                if (printers.any((p) => p.status != PrinterStatus.active)) ...[
                  const SizedBox(height: 24),
                  const Text(
                    'Unavailable Printers',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...printers
                      .where((p) => p.status != PrinterStatus.active)
                      .map((printer) => _buildPrinterOption(printer, false)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 16, color: Colors.black),
        ),
      ],
    );
  }

  Widget _buildPrinterAssignmentSection() {
    if (widget.task.printerId != null) {
      // Printer already assigned
      final printers = ref.watch(printerNotifierProvider).printers;
      final assignedPrinter = printers.firstWhere(
        (p) => p.id == widget.task.printerId,
        orElse: () => printers.first,
      );

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF10B981).withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.print,
                color: Color(0xFF10B981),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    assignedPrinter.nickname,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Assigned',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF10B981),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.check_circle,
              color: Color(0xFF10B981),
              size: 24,
            ),
          ],
        ),
      );
    } else {
      // No printer assigned
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFFF59E0B).withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFF59E0B).withOpacity(0.3),
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.print_disabled_rounded,
                color: Color(0xFFF59E0B),
                size: 30,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Printer Assigned',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Select a printer to start this print job',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildPrinterOption(Printer printer, bool isAvailable) {
    final isSelected = _selectedPrinterId == printer.id;
    final statusColor =
        isAvailable ? const Color(0xFF10B981) : const Color(0xFF6B7280);

    return InkWell(
      onTap: isAvailable ? () => _assignPrinter(printer) : null,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF2563EB).withOpacity(0.1)
              : isAvailable
                  ? const Color(0xFFF8FAFC)
                  : const Color(0xFFF8FAFC).withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF2563EB)
                : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.print,
                color: statusColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    printer.nickname,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isAvailable ? Colors.black : const Color(0xFF9CA3AF),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isAvailable ? 'Available' : 'Offline',
                        style: TextStyle(
                          fontSize: 13,
                          color: statusColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (isAvailable)
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Color(0xFF94A3B8),
                size: 16,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityDisplay() {
    final colors = {
      JobPriority.low: const Color(0xFF6B7280),
      JobPriority.medium: const Color(0xFF2563EB),
      JobPriority.high: const Color(0xFFF59E0B),
      JobPriority.urgent: const Color(0xFFEF4444),
    };

    final labels = {
      JobPriority.low: 'Low',
      JobPriority.medium: 'Medium',
      JobPriority.high: 'High',
      JobPriority.urgent: 'Urgent',
    };

    final color = colors[_selectedPriority]!;
    final label = labels[_selectedPriority]!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(_getPriorityIcon(_selectedPriority), color: color, size: 24),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplicationDisplay() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on, color: Color(0xFF8B5CF6), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _applicationLocation ?? 'Location not specified',
              style: const TextStyle(fontSize: 15, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDurationDisplay() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Duration',
              style: TextStyle(fontSize: 15, color: Color(0xFF9CA3AF)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$_estimatedDuration min',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2563EB),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Start Time',
              style: TextStyle(fontSize: 15, color: Color(0xFF9CA3AF)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFff3b2f).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _selectedStartDateTime?.formatDisplay ?? "No Schedule",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFff3b2f),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNotesDisplay() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _notesController.text,
        style: const TextStyle(
          fontSize: 14,
          color: Colors.black,
          height: 1.6,
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  IconData _getPriorityIcon(JobPriority priority) {
    switch (priority) {
      case JobPriority.low:
        return Icons.arrow_downward;
      case JobPriority.medium:
        return Icons.remove;
      case JobPriority.high:
        return Icons.arrow_upward;
      case JobPriority.urgent:
        return Icons.priority_high;
    }
  }

  Widget _buildBottomAction(List<Printer> printers) {
    if (!showBottomAction) return const SizedBox.shrink();

    if (_isAssigningPrinter) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 8,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text(
                'Starting print job...',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_showPrinterSelection) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16).copyWith(bottom: 30),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _showPrinterSelectionPage,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Assign Printer & Start',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _assignPrinter(Printer printer) async {
    _hidePrinterSelectionPage();

    // Show loading state
    setState(() => _isAssigningPrinter = true);

    try {
      // TODO: Update task with printer assignment via API
      await ref.read(setTaskPrinterStateProvider(TaskPrinterStateParams(
        id: widget.task.id,
        printerId: _selectedPrinterId,
        stockTransactionBarcode: widget.task.stockTransactionBarcode,
        newTaskStatus: TaskStatus.printing
      )));
    } catch(e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      setState(() {
        _isAssigningPrinter = false;
      });
      return;
    }

    setState(() {
      _selectedPrinterId = printer.id;
      _isAssigningPrinter = false;
    });

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Print job started on ${printer.nickname}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );

    // Navigate back after brief delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) Navigator.pop(context);
    });
  }
}
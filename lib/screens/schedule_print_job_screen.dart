// lib/screens/printer/schedule_job_screen.dart
import 'dart:math';

import 'package:cupertino_calendar_picker/cupertino_calendar_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/models/printer.dart';
import 'package:smooflow/models/task.dart';
import 'package:smooflow/providers/material_provider.dart';
import 'package:smooflow/providers/printer_provider.dart';
import 'package:smooflow/providers/project_provider.dart';

class ScheduleJobScreen extends ConsumerStatefulWidget {
  final String? projectId;

  const ScheduleJobScreen({Key? key, this.projectId}) : super(key: key);

  @override
  ConsumerState<ScheduleJobScreen> createState() => _ScheduleJobScreenState();
}

class _ScheduleJobScreenState extends ConsumerState<ScheduleJobScreen> {

  static const MONTHS = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  final _formKey = GlobalKey<FormState>();

  late TextEditingController _runsController;
  late TextEditingController _notesController;

  String? _selectedProjectId;
  String? _selectedPrinterId;
  String? _selectedMaterialType;
  JobPriority _selectedPriority = JobPriority.medium;
  // In Minutes
  int _estimatedDuration = 30;
  bool _requiresApplication = false;
  String? _applicationLocation;

  DateTime? _selectedStartDateTime;

  ExpansionTileController _dateTimeExpansionController = ExpansionTileController();

  @override
  void initState() {
    super.initState();
    _runsController = TextEditingController(text: '1');
    _notesController = TextEditingController();
    _selectedProjectId = widget.projectId;
  }

  @override
  void dispose() {
    _runsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    final printers = ref.watch(printerNotifierProvider).printers;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          'Schedule Print Job',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ),
      body: Column(
        children: [
          // Form Content
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // 1. Project Selection
                  _buildSectionCard(
                    icon: Icons.folder,
                    iconColor: const Color(0xFF2563EB),
                    title: 'Project',
                    child: _buildProjectDropdown(),
                  ),

                  const SizedBox(height: 16),

                  // 2. Material Selection
                  _buildSectionCard(
                    icon: Icons.inventory_2,
                    iconColor: const Color(0xFF10B981),
                    title: 'Material',
                    child: _buildMaterialDropdown(),
                  ),

                  const SizedBox(height: 16),

                  // 3. Runs/Batches
                  _buildSectionCard(
                    icon: Icons.layers,
                    iconColor: const Color(0xFFF59E0B),
                    title: 'Runs / Batches',
                    child: _buildRunsField(),
                  ),

                  const SizedBox(height: 16),

                  // 4. Printer Selection
                  _buildSectionCard(
                    icon: Icons.print,
                    iconColor: const Color(0xFF9333EA),
                    title: 'Select Printer',
                    child: Column(
                      children:
                          printers
                              .map((printer) => _buildPrinterOption(printer))
                              .toList(),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 5. Priority
                  _buildSectionCard(
                    icon: Icons.flag,
                    iconColor: const Color(0xFFEF4444),
                    title: 'Priority Level',
                    child: _buildPrioritySelector(),
                  ),

                  const SizedBox(height: 16),

                  // 6. Application/Installation
                  _buildSectionCard(
                    icon: Icons.construction,
                    iconColor: const Color(0xFF8B5CF6),
                    title: 'Application / Installation',
                    child: _buildApplicationToggle(),
                  ),

                  const SizedBox(height: 16),

                  // 7. Estimated Duration
                  _buildSectionCard(
                    icon: Icons.schedule,
                    iconColor: const Color(0xFF2563EB),
                    title: 'Estimated Duration',
                    child: _buildDurationSlider(),
                  ),

                  const SizedBox(height: 16),

                  // 8. Optional Notes
                  _buildSectionCard(
                    icon: Icons.notes,
                    iconColor: const Color(0xFF6B7280),
                    title: 'Notes (Optional)',
                    child: _buildNotesField(),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Action Buttons
          Container(
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
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black,
                      side: const BorderSide(color: Color(0xFFE5E7EB)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _scheduleJob,
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
                      'Schedule Job',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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

  Widget _buildProjectDropdown() {
    final projects = ref.watch(projectNotifierProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedProjectId,
        decoration: const InputDecoration(
          border: InputBorder.none,
          hintText: 'Select project',
          hintStyle: TextStyle(color: Color(0xFF9CA3AF)),
        ),
        icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF9CA3AF)),
        items:
            projects.map((project) {
              return DropdownMenuItem(
                value: project.id,
                child: Text(
                  project.name,
                  style: const TextStyle(fontSize: 15),
                ),
              );
            }).toList(),
        onChanged: (value) => setState(() => _selectedProjectId = value),
        validator: (value) => value == null ? 'Please select a project' : null,
      ),
    );
  }

  Widget _buildMaterialDropdown() {
    final materials = ref.watch(materialNotifierProvider).materials;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedMaterialType,
        decoration: const InputDecoration(
          border: InputBorder.none,
          hintText: 'Select material type',
          hintStyle: TextStyle(color: Color(0xFF9CA3AF)),
        ),
        icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF9CA3AF)),
        items:
            materials.map((material) {
              return DropdownMenuItem(
                value: material.id,
                child: Text(material.name, style: const TextStyle(fontSize: 15)),
              );
            }).toList(),
        onChanged: (value) => setState(() => _selectedMaterialType = value),
        validator: (value) => value == null ? 'Please select material' : null,
      ),
    );
  }

  Widget _buildRunsField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.remove_circle_outline,
              color: Color(0xFF6B7280),
            ),
            onPressed: () {
              final current = int.tryParse(_runsController.text) ?? 1;
              if (current > 1) {
                setState(() => _runsController.text = (current - 1).toString());
              }
            },
          ),
          Expanded(
            child: TextFormField(
              controller: _runsController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: '1',
                hintStyle: TextStyle(color: Color(0xFF9CA3AF)),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter runs/batches';
                }
                if (int.tryParse(value) == null || int.parse(value) < 1) {
                  return 'Please enter valid number';
                }
                return null;
              },
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.add_circle_outline,
              color: Color(0xFF2563EB),
            ),
            onPressed: () {
              final current = int.tryParse(_runsController.text) ?? 1;
              setState(() => _runsController.text = (current + 1).toString());
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPrinterOption(Printer printer) {
    final isSelected = _selectedPrinterId == printer.id;
    final isAvailable = printer.status == PrinterStatus.active;
    final statusColor =
        isAvailable ? const Color(0xFF10B981) : const Color(0xFF6B7280);

    return InkWell(
      onTap:
          isAvailable
              ? () => setState(() => _selectedPrinterId = printer.id)
              : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F7FA),
          borderRadius: BorderRadius.circular(12),
          border:
              isSelected
                  ? Border.all(color: const Color(0xFF2563EB), width: 2)
                  : null,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color:
                    isSelected
                        ? const Color(0xFF2563EB).withOpacity(0.1)
                        : statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.print,
                color: isSelected ? const Color(0xFF2563EB) : statusColor,
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
                      color:
                          isAvailable ? Colors.black : const Color(0xFF9CA3AF),
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
            if (isSelected)
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Color(0xFF2563EB),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 16),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrioritySelector() {
    return Row(
      children: [
        _buildPriorityChip(JobPriority.low, 'Low', const Color(0xFF6B7280)),
        const SizedBox(width: 8),
        _buildPriorityChip(
          JobPriority.medium,
          'Medium',
          const Color(0xFF2563EB),
        ),
        const SizedBox(width: 8),
        _buildPriorityChip(JobPriority.high, 'High', const Color(0xFFF59E0B)),
        const SizedBox(width: 8),
        _buildPriorityChip(
          JobPriority.urgent,
          'Urgent',
          const Color(0xFFEF4444),
        ),
      ],
    );
  }

  Widget _buildPriorityChip(JobPriority priority, String label, Color color) {
    final isSelected = _selectedPriority == priority;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedPriority = priority),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color:
                isSelected ? color.withOpacity(0.15) : const Color(0xFFF5F7FA),
            borderRadius: BorderRadius.circular(10),
            border: isSelected ? Border.all(color: color, width: 2) : null,
          ),
          child: Column(
            children: [
              Icon(
                _getPriorityIcon(priority),
                color: isSelected ? color : const Color(0xFF9CA3AF),
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? color : const Color(0xFF9CA3AF),
                ),
              ),
            ],
          ),
        ),
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

  Widget _buildDurationSlider() {

    final showConfirm = _selectedStartDateTime!=null && _dateTimeExpansionController.isExpanded;
    final showTime = _selectedStartDateTime!=null && !_dateTimeExpansionController.isExpanded;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: const Color(0xFF2563EB),
            inactiveTrackColor: const Color(0xFFEDF2F7),
            thumbColor: const Color(0xFF2563EB),
            overlayColor: const Color(0xFF2563EB).withOpacity(0.2),
            trackHeight: 6,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
          ),
          child: Slider(
            value: _estimatedDuration.toDouble(),
            min: 15,
            max: 300,
            divisions: 19,
            onChanged:
                (value) => setState(() => _estimatedDuration = value.toInt()),
          ),
        ),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '15 min',
              style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
            ),
            Text(
              '5 hrs',
              style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
            ),
          ],
        ),
        SizedBox(height: 20),
        Theme(
          data: Theme.of(context).copyWith(
            dividerColor: Colors.transparent, // removes divider
          ),
          child: ExpansionTile(
            controller: _dateTimeExpansionController,
            dense: true,
            tilePadding: EdgeInsets.zero,
            iconColor: Color(0xFFff3b2f),
            onExpansionChanged: (_) {
              setState(() {});
            },
            trailing: SizedBox(
              width: 115,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                spacing: 2,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: showConfirm? Color(0xFFff3b2f) : const Color.fromARGB(255, 255, 231, 230),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      showConfirm ? 'Confirm' : (_selectedStartDateTime == null
                          ? 'Not Set'
                          : ( '${MONTHS[_selectedStartDateTime!.month - 1]} ${_selectedStartDateTime!.day}, ${_selectedStartDateTime!.hour.toString().padLeft(2, '0')}:${_selectedStartDateTime!.minute.toString().padLeft(2, '0')}')),
                      style: TextStyle(
                        fontSize: showTime? 14 : 12,
                        fontWeight: FontWeight.w700,
                        color: showConfirm? const Color.fromARGB(255, 255, 231, 230) : Color(0xFFff3b2f),
                      ),
                    ),
                  ),
                  if (_selectedStartDateTime==null) Transform.rotate(angle: -pi/2, child: Icon(Icons.chevron_left, color: Color(0xFFff3b2f))),
                ],
              ),
            ),
            title: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 255, 231, 230),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.calendar_today, color: const Color(0xFFff3b2f), size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  "Start${ !showTime ? " Date & Time" : " Time"}",
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                Spacer(),
              ],
            ),
            children: [
              SizedBox(
                width: 350,
                child: CupertinoCalendar(
                  onDateTimeChanged: (value) => setState(() => _selectedStartDateTime = value),
                  minimumDateTime: DateTime.now().subtract(const Duration(days: 1)),
                  maximumDateTime: DateTime.now().add(const Duration(days: 365)),
                  initialDateTime: DateTime.now(),
                  currentDateTime: _selectedStartDateTime,
                  timeLabel: 'Start Time',
                  mode: CupertinoCalendarMode.dateTime,
                ),
              ),
              TextButton(
                onPressed: () {
                  _selectedStartDateTime = null;
                  _dateTimeExpansionController.collapse();
                },
                child: Text(
                  'Clear',
                  style: TextStyle(
                    fontSize: 15,
                    color: const Color(0xFFff3b2f),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotesField() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _notesController,
        maxLines: 4,
        style: const TextStyle(fontSize: 15, color: Colors.black),
        decoration: const InputDecoration(
          border: InputBorder.none,
          hintText: 'Add any special instructions or notes...',
          hintStyle: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildApplicationToggle() {
    return Column(
      children: [
        // Toggle Switch
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color:
                _requiresApplication
                    ? const Color(0xFF8B5CF6).withOpacity(0.1)
                    : const Color(0xFFF5F7FA),
            borderRadius: BorderRadius.circular(12),
            border:
                _requiresApplication
                    ? Border.all(color: const Color(0xFF8B5CF6), width: 2)
                    : null,
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color:
                      _requiresApplication
                          ? const Color(0xFF8B5CF6).withOpacity(0.2)
                          : const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.location_on,
                  color:
                      _requiresApplication
                          ? const Color(0xFF8B5CF6)
                          : const Color(0xFF9CA3AF),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Requires On-Site Application',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color:
                            _requiresApplication
                                ? const Color(0xFF8B5CF6)
                                : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Installation at client location',
                      style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _requiresApplication,
                onChanged: (value) {
                  setState(() {
                    _requiresApplication = value;
                    if (!value) _applicationLocation = null;
                  });
                },
                activeColor: const Color(0xFF8B5CF6),
              ),
            ],
          ),
        ),

        // Location Field (shows when toggle is ON)
        if (_requiresApplication) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7FA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              onChanged: (value) => _applicationLocation = value,
              style: const TextStyle(fontSize: 15, color: Colors.black),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Enter site address or location',
                hintStyle: TextStyle(color: Color(0xFF9CA3AF)),
                prefixIcon: Icon(
                  Icons.place,
                  color: Color(0xFF8B5CF6),
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _scheduleJob() async {
    if (_formKey.currentState!.validate() && _selectedPrinterId != null && _selectedProjectId != null) {

      final project = ref.watch(projectByIdProvider(_selectedProjectId!));
      final material = ref.watch(materialNotifierProvider).materials.firstWhere((mat) => mat.id == _selectedMaterialType);

      await ref.watch(projectNotifierProvider.notifier).createTask(
        task: Task.create(
          name: "${material.name} - ${project!.name}",
          description: _notesController.text,
          dueDate: null,
          assignees: [],
          projectId: _selectedProjectId!,
          productionDuration: Duration(minutes: _estimatedDuration),
          printerId: _selectedPrinterId!,
          status: "production",
          materialId: _selectedMaterialType!)
      );

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Job scheduled successfully'),
          backgroundColor: Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
      );
    } else if (_selectedPrinterId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a printer'),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
      );
    }
  }
}

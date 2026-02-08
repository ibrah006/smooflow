import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:smooflow/core/models/material.dart';
import 'package:smooflow/core/models/printer.dart';
import 'package:smooflow/core/models/task.dart';
import 'package:smooflow/enums/task_status.dart';

class SchedulePrintJobScreen extends StatefulWidget {
  const SchedulePrintJobScreen({Key? key}) : super(key: key);

  @override
  State<SchedulePrintJobScreen> createState() => _SchedulePrintJobScreenState();
}

class _SchedulePrintJobScreenState extends State<SchedulePrintJobScreen> {
  // final PrintJobSchedulingService _schedulingService = PrintJobSchedulingService();
  
  List<Task> _clientApprovedTasks = [];
  Task? _selectedTask;
  bool _isLoading = true;
  bool _isScheduling = false;
  String? _errorMessage;
  
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _loadClientApprovedTasks();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadClientApprovedTasks() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // final tasks = await _schedulingService.getClientApprovedTasks();
      setState(() {
        // _clientApprovedTasks = tasks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load tasks: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _onTaskSelected(Task task) {
    setState(() {
      _selectedTask = task;
    });
    _navigateToSchedulingForm();
  }

  void _navigateToSchedulingForm() {
    _pageController.animateToPage(
      1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    setState(() {
      _currentPage = 1;
    });
  }

  void _navigateBackToTaskList() {
    _pageController.animateToPage(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    setState(() {
      _currentPage = 0;
      _selectedTask = null;
    });
  }

  Future<void> _scheduleJob(PrintJobScheduleData scheduleData) async {
    if (_selectedTask == null) return;

    setState(() {
      _isScheduling = true;
      _errorMessage = null;
    });

    try {
      // await _schedulingService.schedulePrintJob(
      //   taskId: _selectedTask!.id,
      //   scheduleData: scheduleData,
      // );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Print job scheduled successfully for "${_selectedTask!.name}"'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        
        // Refresh the task list and go back
        await _loadClientApprovedTasks();
        _navigateBackToTaskList();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to schedule job: ${e.toString()}';
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage!),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isScheduling = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentPage == 0 ? 'Schedule Print Job' : 'Job Details & Scheduling'),
        leading: _currentPage == 1
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _isScheduling ? null : _navigateBackToTaskList,
              )
            : null,
        actions: [
          if (_currentPage == 0)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _isLoading ? null : _loadClientApprovedTasks,
              tooltip: 'Refresh',
            ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          // Page 1: Task Selection
          _buildTaskSelectionPage(),
          
          // Page 2: Scheduling Form
          _buildSchedulingFormPage(),
        ],
      ),
    );
  }

  Widget _buildTaskSelectionPage() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading client approved tasks...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red[300],
              ),
              const SizedBox(height: 16),
              Text(
                'Error',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadClientApprovedTasks,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_clientApprovedTasks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inbox_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No Tasks Ready for Production',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'There are no client-approved tasks ready for print job scheduling.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return TaskSelectionList(
      tasks: _clientApprovedTasks,
      onTaskSelected: _onTaskSelected,
    );
  }

  Widget _buildSchedulingFormPage() {
    if (_selectedTask == null) {
      return const Center(
        child: Text('No task selected'),
      );
    }

    return SchedulingForm(
      task: _selectedTask!,
      onSchedule: _scheduleJob,
      isScheduling: _isScheduling,
    );
  }
}

class TaskSelectionList extends StatefulWidget {
  final List<Task> tasks;
  final Function(Task) onTaskSelected;

  const TaskSelectionList({
    Key? key,
    required this.tasks,
    required this.onTaskSelected,
  }) : super(key: key);

  @override
  State<TaskSelectionList> createState() => _TaskSelectionListState();
}

class _TaskSelectionListState extends State<TaskSelectionList> {
  String _searchQuery = '';
  String _sortBy = 'dueDate'; // dueDate, priority, name

  List<Task> get _filteredAndSortedTasks {
    var tasks = widget.tasks.where((task) {
      if (_searchQuery.isEmpty) return true;
      return task.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          task.description.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    // Sort tasks
    tasks.sort((a, b) {
      switch (_sortBy) {
        case 'priority':
          // return b.compareTo(a.priority);
        case 'name':
          return a.name.compareTo(b.name);
        case 'dueDate':
        default:
          if (a.dueDate == null && b.dueDate == null) return 0;
          if (a.dueDate == null) return 1;
          if (b.dueDate == null) return -1;
          return a.dueDate!.compareTo(b.dueDate!);
      }
    });

    return tasks;
  }

  @override
  Widget build(BuildContext context) {
    final filteredTasks = _filteredAndSortedTasks;

    return Column(
      children: [
        _buildSearchAndFilterBar(),
        Expanded(
          child: filteredTasks.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredTasks.length,
                  itemBuilder: (context, index) {
                    return _TaskCard(
                      task: filteredTasks[index],
                      onTap: () => widget.onTaskSelected(filteredTasks[index]),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Search tasks...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text(
                'Sort by:',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildSortChip('Due Date', 'dueDate'),
                      const SizedBox(width: 8),
                      _buildSortChip('Priority', 'priority'),
                      const SizedBox(width: 8),
                      _buildSortChip('Name', 'name'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSortChip(String label, String value) {
    final isSelected = _sortBy == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _sortBy = value;
        });
      },
      backgroundColor: Colors.grey[200],
      selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
      checkmarkColor: Theme.of(context).primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? Theme.of(context).primaryColor : Colors.black87,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No matching tasks',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search criteria',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;

  const _TaskCard({
    required this.task,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isOverdue = task.dueDate != null && task.dueDate!.isBefore(now);
    final isDueSoon = task.dueDate != null && 
        task.dueDate!.isAfter(now) && 
        task.dueDate!.difference(now).inDays <= 3;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isOverdue 
              ? Colors.red.withOpacity(0.3)
              : isDueSoon
                  ? Colors.orange.withOpacity(0.3)
                  : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (task.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            task.description,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // _buildPriorityBadge(),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (task.dueDate != null) _buildDueDateChip(isOverdue, isDueSoon),
                  if (task.productionQuantity != null) _buildQuantityChip(),
                  if (task.assignees.isNotEmpty) _buildAssigneesChip(),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.print,
                            size: 16,
                            color: Theme.of(context).primaryColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Ready for Production',
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey[400],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget _buildPriorityBadge() {
  //   Color color;
  //   String label;
    
  //   if (task.priority >= 4) {
  //     color = Colors.red;
  //     label = 'High';
  //   } else if (task.priority >= 2) {
  //     color = Colors.orange;
  //     label = 'Med';
  //   } else {
  //     color = Colors.blue;
  //     label = 'Low';
  //   }

  //   return Container(
  //     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  //     decoration: BoxDecoration(
  //       color: color.withOpacity(0.15),
  //       borderRadius: BorderRadius.circular(6),
  //       border: Border.all(color: color.withOpacity(0.5)),
  //     ),
  //     child: Text(
  //       label,
  //       style: TextStyle(
  //         color: color,
  //         fontWeight: FontWeight.bold,
  //         fontSize: 12,
  //       ),
  //     ),
  //   );
  // }

  Widget _buildDueDateChip(bool isOverdue, bool isDueSoon) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    Color chipColor = Colors.grey;
    IconData icon = Icons.calendar_today;
    
    if (isOverdue) {
      chipColor = Colors.red;
      icon = Icons.warning;
    } else if (isDueSoon) {
      chipColor = Colors.orange;
      icon = Icons.access_time;
    }

    return Chip(
      avatar: Icon(icon, size: 16, color: chipColor),
      label: Text(
        isOverdue
            ? 'Overdue: ${dateFormat.format(task.dueDate!)}'
            : isDueSoon
                ? 'Due soon: ${dateFormat.format(task.dueDate!)}'
                : 'Due: ${dateFormat.format(task.dueDate!)}',
        style: TextStyle(
          color: chipColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: chipColor.withOpacity(0.1),
      side: BorderSide(color: chipColor.withOpacity(0.3)),
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildQuantityChip() {
    return Chip(
      avatar: const Icon(Icons.inventory_2, size: 16),
      label: Text(
        'Qty: ${task.productionQuantity}',
        style: const TextStyle(fontSize: 12),
      ),
      backgroundColor: Colors.blue.withOpacity(0.1),
      side: BorderSide(color: Colors.blue.withOpacity(0.3)),
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildAssigneesChip() {
    return Chip(
      avatar: const Icon(Icons.people, size: 16),
      label: Text(
        '${task.assignees.length} assignee${task.assignees.length != 1 ? 's' : ''}',
        style: const TextStyle(fontSize: 12),
      ),
      backgroundColor: Colors.purple.withOpacity(0.1),
      side: BorderSide(color: Colors.purple.withOpacity(0.3)),
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

class SchedulingForm extends StatefulWidget {
  final Task task;
  final Function(PrintJobScheduleData) onSchedule;
  final bool isScheduling;

  const SchedulingForm({
    Key? key,
    required this.task,
    required this.onSchedule,
    required this.isScheduling,
  }) : super(key: key);

  @override
  State<SchedulingForm> createState() => _SchedulingFormState();
}

class _SchedulingFormState extends State<SchedulingForm> {
  final _formKey = GlobalKey<FormState>();
  // final PrintJobSchedulingService _schedulingService = PrintJobSchedulingService();
  
  // Form fields
  Printer? _selectedPrinter;
  MaterialModel? _selectedMaterial;
  DateTime? _productionStartTime;
  int _runs = 1;
  double? _productionQuantity;
  int? _productionDuration; // in minutes
  String? _stockTransactionBarcode;
  
  // Lists for dropdowns
  List<Printer> _availablePrinters = [];
  List<MaterialModel> _availableMaterials = [];
  
  bool _isLoadingData = true;
  String? _dataLoadError;

  final TextEditingController _runsController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _barcodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeFormData();
    _loadPrintersAndMaterials();
  }

  @override
  void dispose() {
    _runsController.dispose();
    _quantityController.dispose();
    _durationController.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  void _initializeFormData() {
    // Pre-fill form with existing task data if available
    _runs = widget.task.runs ?? 1;
    _productionQuantity = widget.task.productionQuantity;
    _productionDuration = widget.task.productionDuration;
    _productionStartTime = widget.task.productionStartTime;
    _stockTransactionBarcode = widget.task.stockTransactionBarcode;

    _runsController.text = _runs.toString();
    if (_productionQuantity != null) {
      _quantityController.text = _productionQuantity.toString();
    }
    if (_productionDuration != null) {
      _durationController.text = _productionDuration.toString();
    }
    if (_stockTransactionBarcode != null) {
      _barcodeController.text = _stockTransactionBarcode!;
    }
  }

  Future<void> _loadPrintersAndMaterials() async {
    setState(() {
      _isLoadingData = true;
      _dataLoadError = null;
    });

    try {
      // final printers = await _schedulingService.getAvailablePrinters();
      // final materials = await _schedulingService.getAvailableMaterials();
      
      setState(() {
        // _availablePrinters = printers;
        // _availableMaterials = materials;
        // _isLoadingData = false;

        // // Pre-select if task already has printer/material
        // if (widget.task.printerId != null) {
        //   _selectedPrinter = printers.firstWhere(
        //     (p) => p.id == widget.task.printerId,
        //     orElse: () => printers.first,
        //   );
        // }
        // if (widget.task.materialId != null) {
        //   _selectedMaterial = materials.firstWhere(
        //     (m) => m.id == widget.task.materialId,
        //     orElse: () => materials.first,
        //   );
        // }
      });
    } catch (e) {
      setState(() {
        _dataLoadError = 'Failed to load printers and materials: ${e.toString()}';
        _isLoadingData = false;
      });
    }
  }

  void _handleSchedule() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedPrinter == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a printer to activate the print job'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final scheduleData = PrintJobScheduleData(
      printerId: _selectedPrinter!.id,
      materialId: _selectedMaterial?.id,
      productionStartTime: _productionStartTime,
      runs: _runs,
      productionQuantity: _productionQuantity,
      productionDuration: _productionDuration,
      stockTransactionBarcode: _stockTransactionBarcode,
    );

    widget.onSchedule(scheduleData);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingData) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading scheduling options...'),
          ],
        ),
      );
    }

    if (_dataLoadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(_dataLoadError!, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadPrintersAndMaterials,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTaskInfoCard(),
            const SizedBox(height: 16),
            _buildSchedulingFormCard(),
            const SizedBox(height: 24),
            _buildScheduleButton(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskInfoCard() {
    final dateFormat = DateFormat('MMM dd, yyyy');
    
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.task,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Task Information',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        widget.task.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (widget.task.description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                widget.task.description,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 14,
                ),
              ),
            ],
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            _buildInfoRow(
              icon: Icons.flag,
              label: 'Status',
              value: widget.task.statusName,
              valueColor: Colors.green,
            ),
            if (widget.task.dueDate != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow(
                icon: Icons.calendar_today,
                label: 'Due Date',
                value: dateFormat.format(widget.task.dueDate!),
              ),
            ],
            // if (widget.task.priority > 0) ...[
            //   const SizedBox(height: 8),
            //   _buildInfoRow(
            //     icon: Icons.priority_high,
            //     label: 'Priority',
            //     value: _getPriorityLabel(widget.task.priority),
            //   ),
            // ],
            if (widget.task.assignees.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildInfoRow(
                icon: Icons.people,
                label: 'Assignees',
                value: '${widget.task.assignees.length} assigned',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSchedulingFormCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.print, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Print Job Scheduling',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Assign a printer to activate this print job',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),
            
            // Printer Selection (Required)
            _buildPrinterSelector(),
            const SizedBox(height: 16),
            
            // Material Selection (Optional)
            _buildMaterialSelector(),
            const SizedBox(height: 16),
            
            // Production Start Time
            _buildDateTimePicker(),
            const SizedBox(height: 16),
            
            // Runs
            _buildRunsField(),
            const SizedBox(height: 16),
            
            // Production Quantity
            _buildQuantityField(),
            const SizedBox(height: 16),
            
            // Production Duration
            _buildDurationField(),
            const SizedBox(height: 16),
            
            // Barcode
            _buildBarcodeField(),
          ],
        ),
      ),
    );
  }

  Widget _buildPrinterSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Printer',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            const Text(
              '*',
              style: TextStyle(color: Colors.red, fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<Printer>(
          value: _selectedPrinter,
          decoration: InputDecoration(
            hintText: 'Select a printer to activate job',
            prefixIcon: const Icon(Icons.print),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          items: _availablePrinters.map((printer) {
            return DropdownMenuItem(
              value: printer,
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: printer.isActive ? Colors.green : Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      printer.name,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (!printer.isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Busy',
                        style: TextStyle(fontSize: 10, color: Colors.orange),
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
          onChanged: widget.isScheduling ? null : (value) {
            setState(() {
              _selectedPrinter = value;
            });
          },
          validator: (value) {
            if (value == null) {
              return 'Please select a printer to activate the job';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildMaterialSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Material',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<MaterialModel>(
          value: _selectedMaterial,
          decoration: InputDecoration(
            hintText: 'Select material (optional)',
            prefixIcon: const Icon(Icons.category),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          items: [
            const DropdownMenuItem(
              value: null,
              child: Text('No material selected'),
            ),
            ..._availableMaterials.map((material) {
              return DropdownMenuItem(
                value: material,
                child: Text(material.name),
              );
            }).toList(),
          ],
          onChanged: widget.isScheduling ? null : (value) {
            setState(() {
              _selectedMaterial = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildDateTimePicker() {
    final dateFormat = DateFormat('MMM dd, yyyy - hh:mm a');
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Production Start Time',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: widget.isScheduling ? null : _selectDateTime,
          child: InputDecorator(
            decoration: InputDecoration(
              hintText: 'Select start time',
              prefixIcon: const Icon(Icons.access_time),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            child: Text(
              _productionStartTime != null
                  ? dateFormat.format(_productionStartTime!)
                  : 'Not set',
              style: TextStyle(
                color: _productionStartTime != null ? Colors.black87 : Colors.grey,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRunsField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Number of Runs',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _runsController,
          enabled: !widget.isScheduling,
          decoration: InputDecoration(
            hintText: 'Enter number of runs',
            prefixIcon: const Icon(Icons.replay),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter number of runs';
            }
            final intValue = int.tryParse(value);
            if (intValue == null || intValue < 1) {
              return 'Runs must be at least 1';
            }
            return null;
          },
          onChanged: (value) {
            final intValue = int.tryParse(value);
            if (intValue != null) {
              setState(() {
                _runs = intValue;
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildQuantityField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Production Quantity',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _quantityController,
          enabled: !widget.isScheduling,
          decoration: InputDecoration(
            hintText: 'Enter quantity',
            prefixIcon: const Icon(Icons.inventory_2),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ],
          onChanged: (value) {
            final doubleValue = double.tryParse(value);
            setState(() {
              _productionQuantity = doubleValue;
            });
          },
        ),
      ],
    );
  }

  Widget _buildDurationField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Production Duration (minutes)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _durationController,
          enabled: !widget.isScheduling,
          decoration: InputDecoration(
            hintText: 'Enter duration in minutes',
            prefixIcon: const Icon(Icons.timer),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (value) {
            final intValue = int.tryParse(value);
            setState(() {
              _productionDuration = intValue;
            });
          },
        ),
      ],
    );
  }

  Widget _buildBarcodeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Stock Transaction Barcode',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _barcodeController,
          enabled: !widget.isScheduling,
          decoration: InputDecoration(
            hintText: 'Enter or scan barcode',
            prefixIcon: const Icon(Icons.qr_code),
            suffixIcon: IconButton(
              icon: const Icon(Icons.qr_code_scanner),
              onPressed: widget.isScheduling ? null : () {
                // TODO: Implement barcode scanner
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Barcode scanner coming soon')),
                );
              },
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          onChanged: (value) {
            setState(() {
              _stockTransactionBarcode = value.isEmpty ? null : value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildScheduleButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ElevatedButton(
        onPressed: widget.isScheduling ? null : _handleSchedule,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: Theme.of(context).primaryColor,
        ),
        child: widget.isScheduling
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.schedule_send, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    _selectedPrinter != null
                        ? 'Schedule & Activate Print Job'
                        : 'Schedule Print Job (Select Printer First)',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? Colors.black87,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _getPriorityLabel(int priority) {
    if (priority >= 4) return 'High ($priority)';
    if (priority >= 2) return 'Medium ($priority)';
    return 'Low ($priority)';
  }

  Future<void> _selectDateTime() async {
    final now = DateTime.now();
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _productionStartTime ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 1),
    );

    if (selectedDate == null) return;

    if (!mounted) return;

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_productionStartTime ?? now),
    );

    if (selectedTime == null) return;

    setState(() {
      _productionStartTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime.hour,
        selectedTime.minute,
      );
    });
  }
}

class PrintJobScheduleData {
  final String printerId;
  final String? materialId;
  final DateTime? productionStartTime;
  final int runs;
  final double? productionQuantity;
  final int? productionDuration;
  final String? stockTransactionBarcode;

  PrintJobScheduleData({
    required this.printerId,
    this.materialId,
    this.productionStartTime,
    this.runs = 1,
    this.productionQuantity,
    this.productionDuration,
    this.stockTransactionBarcode,
  });

  Map<String, dynamic> toJson() {
    return {
      'printerId': printerId,
      if (materialId != null) 'materialId': materialId,
      if (productionStartTime != null)
        'productionStartTime': productionStartTime!.toIso8601String(),
      'runs': runs,
      if (productionQuantity != null) 'productionQuantity': productionQuantity,
      if (productionDuration != null) 'productionDuration': productionDuration,
      if (stockTransactionBarcode != null)
        'stockTransactionBarcode': stockTransactionBarcode,
      // Automatically set status to printing when printer is assigned
      'status': 'printing',
    };
  }

  factory PrintJobScheduleData.fromJson(Map<String, dynamic> json) {
    return PrintJobScheduleData(
      printerId: json['printerId'],
      materialId: json['materialId'],
      productionStartTime: json['productionStartTime'] != null
          ? DateTime.parse(json['productionStartTime'])
          : null,
      runs: json['runs'] ?? 1,
      productionQuantity: json['productionQuantity']?.toDouble(),
      productionDuration: json['productionDuration'],
      stockTransactionBarcode: json['stockTransactionBarcode'],
    );
  }

  @override
  String toString() {
    return 'PrintJobScheduleData(printerId: $printerId, materialId: $materialId, '
        'productionStartTime: $productionStartTime, runs: $runs, '
        'productionQuantity: $productionQuantity, productionDuration: $productionDuration, '
        'stockTransactionBarcode: $stockTransactionBarcode)';
  }
}
import 'package:card_loading/card_loading.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/constants.dart';
import 'package:smooflow/core/app_routes.dart';
import 'package:smooflow/core/args/barcode_scan_args.dart';
import 'package:smooflow/core/args/stock_entry_args.dart';
import 'package:smooflow/core/models/printer.dart';
import 'package:smooflow/core/models/stock_transaction.dart';
import 'package:smooflow/core/models/task.dart';
import 'package:smooflow/enums/task_status.dart';
import 'package:intl/intl.dart';
import 'package:smooflow/providers/material_provider.dart';
import 'package:smooflow/providers/printer_provider.dart';
import 'package:smooflow/providers/task_provider.dart';

class SchedulePrintJobScreen extends ConsumerStatefulWidget {

  const SchedulePrintJobScreen({super.key});

  @override
  ConsumerState<SchedulePrintJobScreen> createState() =>
      _SchedulePrintJobScreenState();
}

class _SchedulePrintJobScreenState extends ConsumerState<SchedulePrintJobScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Task? selectedTask;
  String? selectedPrinterId;
  String? selectedMaterialId;
  String? selectedStockItemBarcode;
  DateTime? scheduledStartTime;
  int productionDuration = 60; // minutes
  int runs = 1;
  int productionQuantity = 0;
  bool isScheduling = false;

  bool stockItemAlreadySpecified = false;

  List<Printer> get availablePrinters => ref.watch(printerNotifierProvider).printers;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    Future.microtask(() async {
      await ref.watch(materialNotifierProvider.notifier).fetchMaterials();
      await Future.delayed(Duration(milliseconds: 100));
    });

  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Task> get allTasks => ref.watch(taskNotifierProvider);

  List<Task> get clientApprovedTasks {

    return allTasks.where((task) {
      // Filter tasks that are post-design stage and ready for production
      return task.status == TaskStatus.clientApproved &&
          task.printerId == null; // Not yet scheduled
    }).toList();
  }

  List<Task> get scheduledTasks {
    return allTasks.where((task) {
      return task.status == TaskStatus.printing && task.printerId != null;
    }).toList();
  }

  resetParameters() {
    selectedTask = null;
    selectedPrinterId = null;
    scheduledStartTime = null;
    productionDuration = 60;
    runs = 1;
    productionQuantity = 0;
    selectedMaterialId = null;
    selectedStockItemBarcode = null;
    isScheduling = false;
  }

  Future<void> _assignPrinter() async {

    final printer = ref.watch(printerNotifierProvider).printers.firstWhere((p) => p.id == selectedPrinterId);

    // await ref.read(setTaskStateProvider(TaskStateParams(
    //   id: selectedTask!.id,
    //   printerId: printer.id,
    //   stockTransactionBarcode: selectedTask!.stockTransactionBarcode,
    //   newTaskStatus: TaskStatus.printing
    // )));

    await TaskProvider.setTaskState(
      ref: ref,
      taskId: selectedTask!.id,
      printerId: printer.id,
      newStatus: TaskStatus.printing,
      materialId: selectedMaterialId,
      stockTransactionBarcode: selectedStockItemBarcode,
    );
  }

  void _scheduleJob() async {
    if (selectedTask == null || selectedPrinterId == null) {
      _showError('Please select a task and printer');
      return;
    }

    setState(() => isScheduling = true);

    try {
      await _assignPrinter();
      
      if (mounted) {
        setState(() {
          resetParameters();
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
                    'Print job started successfully',
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
    } catch (e) {
      setState(() => isScheduling = false);
      _showError('Failed to schedule print job: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          'Print Job Scheduling',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
        ),
        iconTheme: IconThemeData(color: Color(0xFF0F172A)),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(60),
          child: Container(
            color: Colors.white,
            child: Column(
              children: [
                TabBar(
                  controller: _tabController,
                  labelColor: Color(0xFF2563EB),
                  unselectedLabelColor: Color(0xFF64748B),
                  indicatorColor: Color(0xFF2563EB),
                  indicatorWeight: 3,
                  dividerColor: Colors.grey.shade200,
                  labelStyle: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                  ),
                  unselectedLabelStyle: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.pending_actions, size: 18),
                          SizedBox(width: 8),
                          Text('Pending'),
                          SizedBox(width: 6),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${clientApprovedTasks.length}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF166534),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.print, size: 18),
                          SizedBox(width: 8),
                          Text('Scheduled'),
                          SizedBox(width: 6),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Color(0xFFDBEAFE),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${scheduledTasks.length}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1E40AF),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildReadyForProductionTab(),
          _buildScheduledTab(),
        ],
      ),
    );
  }

  Widget _buildReadyForProductionTab() {
    return Row(
      children: [
        // Left Panel - Task List
        Expanded(
          flex: 2,
          child: Container(
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Job to Schedule',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.3,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Tasks approved and ready for production',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      await ref.watch(taskNotifierProvider.notifier).loadAll();
                    },
                    child: clientApprovedTasks.isEmpty
                      ? SingleChildScrollView(physics: AlwaysScrollableScrollPhysics(), child: _buildEmptyState())
                      : ListView.separated(
                          padding: EdgeInsets.all(16).copyWith(bottom: 42),
                          itemCount: clientApprovedTasks.length,
                          separatorBuilder: (context, index) =>
                              SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final task = clientApprovedTasks[index];
                            final isSelected = selectedTask?.id == task.id;
                            return _buildTaskCard(task, isSelected);
                          },
                        )),
                ),
              ],
            ),
          ),
        ),
        
        // Divider
        Container(width: 1, color: Color(0xFFE2E8F0)),
      ],
    );
  }

  Widget _buildTaskCard(Task task, bool isSelected) {

    final taskComponentHelper = task.componentHelper();

    final statusName = taskComponentHelper.labelTitle;
    final statusColor = taskComponentHelper.color;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedTask = task;
          // Pre-fill form with existing task data if available
          productionDuration = task.productionDuration;
          runs = task.runs ?? 1;
          productionQuantity = task.productionQuantity?.toInt()?? 0;
          selectedMaterialId = task.materialId?.isEmpty ?? true ? null : task.materialId;
          selectedStockItemBarcode = task.stockTransactionBarcode;
          scheduledStartTime = task.productionStartTime;
        });

        selectedPrinterId = null;
        stockItemAlreadySpecified = selectedTask != null && (selectedTask!.stockTransactionBarcode != null);

        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (context) => SizedBox(
            height: MediaQuery.of(context).size.height * .8,
            child: selectedTask == null
              ? _buildNoSelectionState()
              : _buildSchedulingForm()
            ));
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFFEFF6FF) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Color(0xFF2563EB) : Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Color(0xFF2563EB).withOpacity(0.1),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    statusName,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                Spacer(),
                Text(
                  'ID: ${task.id}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              task.name,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A),
                letterSpacing: -0.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (task.description.isNotEmpty) ...[
              SizedBox(height: 6),
              Text(
                task.description,
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today,
                    size: 14, color: Color(0xFF64748B)),
                SizedBox(width: 6),
                Text(
                  task.dueDate != null
                      ? 'Due ${DateFormat('MMM dd, yyyy').format(task.dueDate!)}'
                      : 'No due date',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
                Spacer(),
                if (task.productionQuantity != null) ...[
                  Icon(Icons.inventory_2_outlined,
                      size: 14, color: Color(0xFF64748B)),
                  SizedBox(width: 6),
                  Text(
                    '${task.productionQuantity} units',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSchedulingForm() {
    final projectIdSplitted = selectedTask!.projectId.split("-");
    final projectIdDisplay = "${projectIdSplitted[projectIdSplitted.length - 2]}-${projectIdSplitted.last}";
    final materials = ref.watch(materialNotifierProvider).materials;
    
    // Add ScrollController to track scroll position
    final ScrollController scrollController = ScrollController();
    bool showScrollIndicator = false;

    return StatefulBuilder(
      builder: (context, setState) {
        // Add listener to detect scroll position
        void checkScrollPosition() {
          if (scrollController.hasClients) {
            final maxScroll = scrollController.position.maxScrollExtent;
            final currentScroll = scrollController.position.pixels;
            final remainingScroll = maxScroll - currentScroll;
            
            // Show indicator if there's more than 50 pixels to scroll
            setState(() {
              showScrollIndicator = remainingScroll > 50;
            });
          }
        }

        // Add listener on first build
        if (!scrollController.hasListeners) {
          scrollController.addListener(checkScrollPosition);
          // Check initial position after frame is rendered
          WidgetsBinding.instance.addPostFrameCallback((_) {
            checkScrollPosition();
          });
        }

        return Material(
          borderRadius: BorderRadius.vertical(top: Radius.circular(50)),
          color: Color(0xFFF8FAFC),
          child: Stack(
            children: [
              SingleChildScrollView(
                controller: scrollController,
                padding: EdgeInsets.all(24).copyWith(top: 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      alignment: Alignment.center,
                      padding: EdgeInsets.only(top: 24),
                      child: Container(
                        margin: EdgeInsets.only(bottom: 20),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Color(0xFF2563EB).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.schedule,
                            color: Color(0xFF2563EB),
                            size: 24,
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Schedule Print Job',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0F172A),
                                  letterSpacing: -0.3,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                selectedTask!.name,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF64748B),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(Icons.close, color: Color(0xFF64748B))
                        )
                      ],
                    ),
                    
                    SizedBox(height: 28),
                    
                    // Task Details Card
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Task Details',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.2,
                            ),
                          ),
                          SizedBox(height: 16),
                          _buildDetailRow(
                            'Project ID',
                            projectIdDisplay,
                            Icons.folder_outlined,
                          ),
                          _buildDetailRow(
                            'Status',
                            selectedTask!.statusName,
                            Icons.info_outline,
                          ),
                          if (selectedTask!.dueDate != null)
                            _buildDetailRow(
                              'Due Date',
                              DateFormat('MMM dd, yyyy HH:mm').format(selectedTask!.dueDate!),
                              Icons.event,
                            ),
                          if (selectedTask!.assignees.isNotEmpty)
                            _buildDetailRow(
                              'Assignees',
                              '${selectedTask!.assignees.length} assigned',
                              Icons.people_outline,
                            ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: 24),
                    
                    // Printer Selection
                    Text(
                      'Printer Assignment',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.2,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Select a printer to activate this print job',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    SizedBox(height: 12),
                    Container(
                      padding: EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selectedPrinterId == null
                              ? Color(0xFFE2E8F0)
                              : Color(0xFF2563EB),
                        ),
                      ),
                      child: DropdownButtonFormField<String>(
                        value: selectedPrinterId,
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.print, color: Color(0xFF64748B)),
                          border: InputBorder.none,
                          hintText: 'Select printer',
                          hintStyle: TextStyle(color: Color(0xFF94A3B8)),
                        ),
                        items: availablePrinters.map((printer) {
                          final isAvailable = printer.isAvailable;
                          return DropdownMenuItem<String>(
                            value: printer.id,
                            enabled: isAvailable,
                            child: SizedBox(
                              width: 200,
                              child: Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isAvailable
                                          ? Color(0xFF10B981)
                                          : Color(0xFFEF4444),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      printer.name,
                                      style: TextStyle(
                                        color: isAvailable
                                            ? Color(0xFF0F172A)
                                            : Color(0xFF94A3B8),
                                      ),
                                    ),
                                  ),
                                  Text(
                                    printer.isBusy ? "Busy" : printer.statusName,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isAvailable
                                          ? Color(0xFF10B981)
                                          : Color(0xFFEF4444),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => selectedPrinterId = value);
                        },
                      ),
                    ),
                    
                    SizedBox(height: 24),
                    
                    // Production Settings
                    Text(
                      'Production Settings',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.2,
                      ),
                    ),
                    SizedBox(height: 16),
                    
                    // Barcode
                    _buildInputField(
                      label: 'Stock Transaction Barcode',
                      icon: Icons.qr_code,
                      child: TextFormField(
                        enabled: !stockItemAlreadySpecified,
                        initialValue: selectedStockItemBarcode ?? '',
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          disabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Color.fromARGB(255, 240, 244, 249)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Color(0xFF2563EB)),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          hintText: 'Scan Barcode',
                          suffixIcon: IconButton(
                            icon: Icon(CupertinoIcons.barcode, color: Color(0xFF64748B)),
                            onPressed: () async {
                              final response = await AppRoutes.navigateTo(context, AppRoutes.barcodeScanOut, arguments: BarcodeScanArgs.stockOut(projectId: selectedTask!.projectId));
                              print("barcode scan response: $response");
                            },
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            selectedStockItemBarcode = value.isEmpty ? null : value;
                          });
                        },
                      ),
                    ),
                    SizedBox(height: 8),
                    Text("OR"),
                    SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selectedMaterialId == null
                              ? Color(0xFFE2E8F0)
                              : Color(0xFF2563EB),
                        ),
                      ),
                      child: DropdownButtonFormField<String>(
                        value: selectedMaterialId,
                        hint: Text("Select Material"),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintStyle: TextStyle(color: Color(0xFF94A3B8)),
                        ),
                        items: materials.map((material) {
                          return DropdownMenuItem<String>(
                            value: material.id,
                            child: SizedBox(
                              width: 200,
                              child: Row(
                                children: [
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      material.name,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedMaterialId = value;
                            selectedStockItemBarcode = null;
                          });
                        },
                      ),
                    ),
                      
                    SizedBox(height: 8),
                      
                    if (selectedMaterialId != null) _buildStockItemDropdown(setState),
                      
                    SizedBox(height: 16),
                      
                    // Production Quantity
                    _buildInputField(
                      label: 'Production Quantity',
                      icon: Icons.inventory_2_outlined,
                      child: TextFormField(
                        enabled: false,
                        initialValue: productionQuantity.toString(),
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          disabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Color.fromARGB(255, 240, 244, 249)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Color(0xFF2563EB)),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          hintText: 'Enter quantity',
                        ),
                        onChanged: (value) {
                          setState(() {
                            productionQuantity = int.parse(value);
                          });
                        },
                      ),
                    ),
                    
                    SizedBox(height: 32),
                    
                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              side: BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: selectedPrinterId != null && !isScheduling && productionQuantity > 0
                                ? _scheduleJob
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF2563EB),
                              disabledBackgroundColor: Color(0xFFE2E8F0),
                              padding: EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 0,
                            ),
                            child: isScheduling
                                ? SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.check_circle_outline, size: 20, color: selectedPrinterId == null? null : Colors.white,),
                                      SizedBox(width: 8),
                                      Text(
                                        'Start Print Job',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: selectedPrinterId == null? null : Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 16),
                    
                    // Info banner
                    Container(
                      padding: EdgeInsets.all(14),
                      margin: EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Color(0xFFBFDBFE)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 18,
                            color: Color(0xFF2563EB),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'The print job will be activated once a printer is assigned. Make sure all production settings are correct before scheduling.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF1E40AF),
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Scroll Indicator with animations
              Positioned(
                bottom: 24,
                right: 24,
                child: AnimatedSlide(
                  offset: showScrollIndicator ? Offset.zero : Offset(0, 2),
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: AnimatedOpacity(
                    opacity: showScrollIndicator ? 1.0 : 0.0,
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: AnimatedScale(
                      scale: showScrollIndicator ? 1.0 : 0.8,
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      child: IgnorePointer(
                        ignoring: !showScrollIndicator,
                        child: GestureDetector(
                          onTap: () {
                            scrollController.animateTo(
                              scrollController.position.pixels + 200,
                              duration: Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                            );
                          },
                          child: Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Color(0xFF2563EB),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0xFF2563EB).withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: TweenAnimationBuilder<double>(
                              tween: Tween<double>(begin: 0, end: showScrollIndicator ? 1 : 0),
                              duration: Duration(milliseconds: 800),
                              curve: Curves.easeInOut,
                              builder: (context, value, child) {
                                return Transform.translate(
                                  offset: Offset(0, 3 * (value % 1)),
                                  child: Icon(
                                    Icons.keyboard_arrow_down,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }
    );
  }

  Widget _buildInputField({
    required String? label,
    required IconData? icon,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) Icon(icon, size: 16, color: Color(0xFF64748B)),
            SizedBox(width: 6),
            if (label != null) Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF475569),
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Color(0xFF64748B)),
          SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF0F172A),
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduledTab() {
    return Container(
      color: Color(0xFFF8FAFC),
      child: scheduledTasks.isEmpty
          ? _buildEmptyScheduledState()
          : ListView.separated(
              padding: EdgeInsets.all(20),
              itemCount: scheduledTasks.length,
              separatorBuilder: (context, index) => SizedBox(height: 16),
              itemBuilder: (context, index) {
                final task = scheduledTasks[index];
                return _buildScheduledTaskCard(task);
              },
            ),
    );
  }

  Widget _buildScheduledTaskCard(Task task) {
    late final Printer? printer;
    try {
    printer = availablePrinters.firstWhere(
      (p) => p.id == task.printerId,
    );
    } catch (e) {
      printer = null;
    }
    
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(task.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  task.statusName,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(task.status),
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              SizedBox(width: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, size: 12, color: Color(0xFF10B981)),
                    SizedBox(width: 4),
                    Text(
                      'Scheduled',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF10B981),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
              Spacer(),
              Text(
                'ID: ${task.id}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            task.name,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F172A),
              letterSpacing: -0.2,
            ),
          ),
          SizedBox(height: 16),
          Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildScheduledDetail(
                  'Printer',
                  printer?.name ?? 'Unknown Printer',
                  Icons.print,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Color(0xFFE2E8F0),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildScheduledDetail(
                  'Duration',
                  '${task.productionDuration} min',
                  Icons.timer_outlined,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildScheduledDetail(
                  'Runs',
                  '${task.runs ?? 1}',
                  Icons.repeat,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Color(0xFFE2E8F0),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildScheduledDetail(
                  'Quantity',
                  task.productionQuantity?.toString() ?? 'N/A',
                  Icons.inventory_2_outlined,
                ),
              ),
            ],
          ),
          if (task.productionStartTime != null) ...[
            SizedBox(height: 16),
            Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),
            SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.schedule, size: 16, color: Color(0xFF64748B)),
                SizedBox(width: 8),
                Text(
                  'Scheduled Start: ',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                  ),
                ),
                Text(
                  DateFormat('MMM dd, yyyy HH:mm')
                      .format(task.productionStartTime!),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScheduledDetail(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: Color(0xFF64748B)),
            SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
        SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F172A),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildNoSelectionState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.touch_app_outlined,
              size: 48,
              color: Color(0xFF94A3B8),
            ),
          ),
          SizedBox(height: 24),
          Text(
            'Select a Task to Schedule',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F172A),
              letterSpacing: -0.3,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Choose a task from the list to begin\nscheduling the print job',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: MediaQuery.of(context).size.height - 420,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.inbox_outlined,
              size: 48,
              color: Color(0xFF94A3B8),
            ),
          ),
          SizedBox(height: 24),
          Text(
            'No Tasks Ready',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F172A),
              letterSpacing: -0.3,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'There are no client-approved tasks\navailable for production scheduling',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyScheduledState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.event_available_outlined,
              size: 48,
              color: Color(0xFF94A3B8),
            ),
          ),
          SizedBox(height: 24),
          Text(
            'No Scheduled Jobs',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F172A),
              letterSpacing: -0.3,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Print jobs will appear here once\nthey are scheduled with a printer',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.designing:
        return Color(0xFFF59E0B);
      case TaskStatus.printing:
        return Color(0xFF2563EB);
      case TaskStatus.finishing:
        return Color(0xFF8B5CF6);
      case TaskStatus.installing:
        return Color(0xFF06B6D4);
      case TaskStatus.completed:
        return Color(0xFF10B981);
      case TaskStatus.blocked:
        return Color(0xFFEF4444);
      default:
        return Color(0xFF64748B);
    }
  }

  Widget _buildStockItemDropdown(void setState(void Function())) {
    final materials = ref.watch(materialNotifierProvider).materials;

    final selectedMaterial = materials.firstWhere((material)=> material.id == selectedMaterialId);
    late String selectedMaterialUnit;
    try {
      selectedMaterialUnit = selectedMaterial.unit;
      selectedMaterialUnit = "${selectedMaterialUnit[0].toUpperCase()}${selectedMaterialUnit.substring(1)}";
    } catch(e) {
      selectedMaterialUnit = "Quantity";
    }

    Future<List<StockTransaction>> materialStockTransationsFuture = ref.watch(materialNotifierProvider.notifier).fetchMaterialTransactions(
      selectedMaterial.id,
      checkIsLocalEmpty: true,
      updateState: false,
      type: TransactionType.stockIn
    );

    return FutureBuilder(
      future: materialStockTransationsFuture,
      builder: (context, snapshot) {

        final materialStockTransations = snapshot.data;

        final isHigherThanStock = materialStockTransations != null && (materialStockTransations.isEmpty || productionQuantity > selectedMaterial.currentStock);

        return Column(
          spacing: 15,
          children: [
            if (materialStockTransations == null)
              CardLoading(height: 55, borderRadius: BorderRadius.circular(12))
            else Container(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selectedStockItemBarcode == null
                              ? Color(0xFFE2E8F0)
                              : Color(0xFF2563EB),
                        ),
                      ),
              child: DropdownButtonFormField<String>(
                hint: Row(
                  spacing: 8,
                  children: [
                    if (materialStockTransations.isEmpty) Icon(Icons.block_rounded, color: Colors.grey.shade600),
                    Text(materialStockTransations.isEmpty? 'Empty stock' : 'Select item')
                  ],
                ),
                value: selectedStockItemBarcode,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Color(0xFF9CA3AF)),
                ),
                icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF9CA3AF)),
                items:
                    materialStockTransations.map((stockTransaction) {
                      return DropdownMenuItem(
                        value: stockTransaction.barcode,
                        child: Text("${selectedMaterial.name}  ${stockTransaction.barcode}", style: const TextStyle(fontSize: 15)),
                      );
                    }).toList(),
                onChanged: (value) => setState(() => selectedStockItemBarcode = value),
                validator: (value) => value == null ? (materialStockTransations.isEmpty? 'Empty stock' : 'Please select item') : null,
              ),
            ),
            if (selectedStockItemBarcode != null) Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    selectedMaterialUnit,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  Row(
                    children: [
                      _buildIncrementButton(
                        icon: Icons.remove,
                        onPressed: productionQuantity > 1 ? () => setState(() => productionQuantity--) : null,
                      ),
                      Container(
                        width: 60,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          productionQuantity.toString(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: isHigherThanStock? colorPending : Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      if (materialStockTransations==null) CircularProgressIndicator()
                      else _buildIncrementButton(
                        icon: Icons.add,
                        onPressed: () {
                          setState(() => productionQuantity++);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (materialStockTransations?.isEmpty?? false) SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  AppRoutes.navigateTo(context, AppRoutes.stockInEntry, arguments: StockEntryArgs.stockIn());
                  setState(() {
                    // _lookForStockTransactions = true;
                  });
                },
                child: Text("Add Stock Entry")
              ),
            )
          ],
        );
      }
    );
  }

  Widget _buildIncrementButton({
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: onPressed != null
            ? const Color(0xFF2563EB)
            : const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(10),
      ),
      child: IconButton(
        icon: Icon(icon, size: 18),
        color: Colors.white,
        padding: EdgeInsets.zero,
        onPressed: onPressed,
      ),
    );
  }
}
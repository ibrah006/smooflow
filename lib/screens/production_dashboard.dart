// lib/screens/production/production_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:smooflow/components/hawk_fab.dart';
import 'package:smooflow/core/app_routes.dart';
import 'package:smooflow/core/args/material_stock_transaction_args.dart';
import 'package:smooflow/core/args/schedule_print_job_args.dart';
import 'package:smooflow/enums/task_status.dart';
import 'package:smooflow/extensions/date_time_format.dart';
import 'package:smooflow/models/material.dart';
import 'dart:async';

import 'package:smooflow/models/printer.dart';
import 'package:smooflow/models/task.dart';
import 'package:smooflow/providers/material_provider.dart';
import 'package:smooflow/providers/printer_provider.dart';
import 'package:smooflow/providers/project_provider.dart';
import 'package:smooflow/providers/task_provider.dart';
import 'package:smooflow/screens/settings_profile_screen.dart';
import 'package:smooflow/screens/stock_entry_screen.dart';

class ProductionDashboardScreen extends ConsumerStatefulWidget {
  const ProductionDashboardScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ProductionDashboardScreen> createState() =>
      _ProductionDashboardScreenState();
}

class _ProductionDashboardScreenState extends ConsumerState<ProductionDashboardScreen> {
  Timer? _refreshTimer;

  // Active Printers, Print Jobs, Low Stock
  int _selectedSectionIndex = 0;

  // 0: All, 1: Printing, 2: Blocked
  int _selectedFilteredIndex = 0;

  @override
  void initState() {
    super.initState();

    // Auto-refresh every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) setState(() {});
    });

    Future.microtask(() async {
      await ref.watch(projectNotifierProvider.notifier).load(projectsLastAddedLocal: null);
      await ref.watch(printerNotifierProvider.notifier).fetchPrinters();
      await ref.watch(materialNotifierProvider.notifier).fetchMaterials();
      await ref.watch(taskNotifierProvider.notifier).loadAll();
      await ref.watch(materialNotifierProvider.notifier).fetchMaterials();
      await ref.watch(taskNotifierProvider.notifier).fetchProductionScheduleToday();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
  
  List<PrinterStatus>? printerStatusesByFilters(int filterIndex) => filterIndex==0? null : filterIndex==1? [PrinterStatus.active] : [PrinterStatus.maintenance, PrinterStatus.offline];

  TaskStatus? taskStatusByFilters(int filterIndex)=> [null, TaskStatus.printing, TaskStatus.blocked][filterIndex];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final activePrintersCount = ref.watch(printerNotifierProvider).activePrinters.length;
    final totalPrintersCount = ref.watch(printerNotifierProvider).totalPrintersCount;

    final printers = ref.watch(printerNotifierProvider).byStatus(statuses: printerStatusesByFilters(_selectedFilteredIndex));

    // print("activePrintersCount: $activePrintersCount, totalPrintersCount: $totalPrintersCount");

    final tasks = ref.watch(taskNotifierProvider.notifier).byStatus(status: taskStatusByFilters(_selectedFilteredIndex));

    final materials = ref.watch(materialNotifierProvider).byStatus(isLow: _selectedFilteredIndex==1, isCritical: _selectedFilteredIndex==2);

    final allPrintersCount = printersCountByFilter(filterIndex: 0);
    final allTasksCount = tasksCountByFilter(filterIndex: 0);
    final allMaterialsCount = materialsCountByFilter(filterIndex: 0);
    final lowStockMaterialsCount = materialsCountByFilter(filterIndex: 1);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: HawkFabMenu(
        icon: AnimatedIcons.menu_close,
        // fabColor: Colors.yellow,
        // iconColor: Colors.green,
        // hawkFabMenuController: hawkFabMenuController,
        items: [
          HawkFabMenuItem(
            label: 'Add Printer',
            ontap: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              AppRoutes.navigateTo(context, AppRoutes.addPrinter);
            },
            icon: const Icon(Icons.print_rounded),
            // color: Colors.red,
            // labelColor: Colors.blue,
          ),
          HawkFabMenuItem(
            label: 'Schedule Job',
            ontap: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              AppRoutes.navigateTo(context, AppRoutes.schedulePrintStages);
            },
            icon: const Icon(Icons.calendar_month_rounded),
          ),
          HawkFabMenuItem(
            label: 'Stock Entry',
            ontap: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StockEntryScreen.stockin(),
                ),
              );
            },
            icon: const Icon(Icons.add),
          ),
        ],
        body: CustomScrollView(
          slivers: [
            // Simple App Bar (matching Materials Stock style)
            SliverAppBar(
              backgroundColor: const Color(0xFFF5F7FA),
              elevation: 0,
              pinned: false,
              toolbarHeight: 80,
              flexibleSpace: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: SafeArea(
                  child: Row(
                    children: [
                      Container(
                        width: 45,
                        padding: const EdgeInsets.all(10).copyWith(right: 0),
                        child: Image.asset("assets/icons/app_icon.png"),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'Dashboard',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      Ink(
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 251, 251, 251),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.person_outline),
                          iconSize: 28,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SettingsProfileScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search and notification
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEDF2F7),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: const [
                                Icon(
                                  Icons.search,
                                  color: Color(0xFF9CA3AF),
                                  size: 22,
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Search',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Color(0xFF9CA3AF),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEDF2F7),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.notifications_outlined,
                            color: Color(0xFF2563EB),
                            size: 26,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Quick Stats (3 cards like Material Stock)
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.inventory_2,
                            iconBg: const Color(0xFFDCE7FE),
                            iconColor: const Color(0xFF2563EB),
                            value: activePrintersCount.toString(),
                            label: 'Active${_selectedSectionIndex==0? "\n" : " "}Printers',
                            indexValue: 0
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.schema_rounded,
                            iconBg: const Color(0xFFDCFCE7),
                            iconColor: const Color(0xFF22C55E),
                            value: allTasksCount.toString(),
                            label: 'Print${_selectedSectionIndex==1? "\n" : " "}Jobs',
                            indexValue: 1
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.warning_amber_rounded,
                            iconBg: const Color(0xFFFEF3C7),
                            iconColor: const Color(0xFFF59E0B),
                            value: lowStockMaterialsCount.toString(),
                            label: 'Low${_selectedSectionIndex==2? "\n" : " "}Stock',
                            indexValue: 2
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Filter Tabs (like Material Stock)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterTab('All', value: 0, count: totalPrintersCount),
                          const SizedBox(width: 12),
                          _buildFilterTab(['Active', 'Printing', 'Low Stock'][_selectedSectionIndex], value: 1, count: 2),
                          const SizedBox(width: 12),
                          _buildFilterTab(['Blocked', 'Blocked', 'Critical'][_selectedSectionIndex], value: 2, count: 2),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Urgent Jobs List
                    if (_selectedSectionIndex == 0) ... [
                      if (printers.isNotEmpty)
                        // ..._urgentJobs.map((job) => _buildJobCard(job)),

                      // Printer Status Cards
                      ...printers.map((printer)=> _buildPrinterCard(printer))
                      else ... [
                        SizedBox(height: 7),
                        Center(child: Icon(Icons.print, size: 40, color: Colors.grey,)),
                        SizedBox(height: 7),
                        Center(child: Text(allPrintersCount>0? "Nothing here - Try adjusting the filters" : "No printers created", style: textTheme.titleMedium!.copyWith(color: Colors.grey.shade800))),
                        SizedBox(height: 7),
                      ]
                    ] else if (_selectedSectionIndex == 1) 
                      if (tasks.isNotEmpty)
                        ...tasks.map((task) => _buildJobCard(task)).toList()
                      else ... [
                        SizedBox(height: 7),
                        Center(child: SvgPicture.asset(
                          "assets/icons/no_tasks_icon.svg",
                          width: 43,
                        ),),
                        SizedBox(height: 7),
                        Center(child: Text(allTasksCount>0? "Nothing here - Try adjusting the filters" : "No print jobs assigned", style: textTheme.titleMedium!.copyWith(color: Colors.grey.shade800))),
                        SizedBox(height: 7),
                      ]
                    else 
                     if (materials.isNotEmpty)
                     ...materials.map((material)=> _buildMaterialCard(material))
                     else ... [
                        SizedBox(height: 7),
                        Center(child: Icon(Icons.receipt_long_outlined, size: 40, color: Colors.grey)),
                        SizedBox(height: 7),
                        Center(child: Text(allMaterialsCount>0? 'Nothing here - Try adjusting the filters' : "No transactions found", style: textTheme.titleMedium!.copyWith(color: Colors.grey.shade800))),
                        SizedBox(height: 7),
                      ],

                    const SizedBox(height: 24),

                    // Today's Schedule
                    const Text(
                      'Today\'s Schedule',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildScheduleCard(),

                    const SizedBox(height: 24),

                    // Material Alerts
                    // const Text(
                    //   'Material Status',
                    //   style: TextStyle(
                    //     fontSize: 20,
                    //     fontWeight: FontWeight.w700,
                    //     color: Colors.black,
                    //   ),
                    // ),
                    // const SizedBox(height: 16),
                    // _buildMaterialCard(
                    //   'Cast Vinyl',
                    //   '15 rolls',
                    //   'Low Stock',
                    //   const Color(0xFFF59E0B),
                    // ),
                    // _buildMaterialCard(
                    //   'Banner Material',
                    //   '8 rolls',
                    //   'Critical',
                    //   const Color(0xFFEF4444),
                    // ),
                    // _buildMaterialCard(
                    //   'Photo Paper',
                    //   '42 rolls',
                    //   'Good',
                    //   const Color(0xFF10B981),
                    // ),

                    const SizedBox(height: 100), // Bottom padding for FAB
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String value,
    required String label,
    required int indexValue,
  }) {
    final isSelected = _selectedSectionIndex == indexValue;

    return AnimatedScale(
      duration: Duration(milliseconds: 150),
      scale: isSelected? 1.1: 1,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedSectionIndex = indexValue;
            _selectedFilteredIndex = 0;
          });
        },
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isSelected? iconBg : Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isSelected? iconColor : iconBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: isSelected? iconBg : iconColor, size: 28),
              ),
              const SizedBox(height: 16),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                  height: 1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: isSelected? Colors.black : Color(0xFF9CA3AF),
                  fontWeight: isSelected? FontWeight.w700 : null,
                  height: isSelected? 1.2 : 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int printersCountByFilter({required int filterIndex}) {
    final printerNotifier = ref.watch(printerNotifierProvider);
    return printerNotifier.countByStatus(statuses: printerStatusesByFilters(filterIndex));
  }

  int tasksCountByFilter({required int filterIndex}) {
    final tasksNotifier = ref.watch(taskNotifierProvider.notifier);
    return tasksNotifier.countByStatus(status: taskStatusByFilters(filterIndex));
  }

  int materialsCountByFilter({required int filterIndex}) {
    final materialNotifier = ref.watch(materialNotifierProvider);
    return materialNotifier.countByStatus(isLow: filterIndex == 1, isCritical: filterIndex == 2);
  }

  Widget _buildFilterTab(String label, {int? count, required int value}) {

    final isSelected = value == _selectedFilteredIndex;

    final count = [
      printersCountByFilter(filterIndex: value),
      tasksCountByFilter(filterIndex: value),
      materialsCountByFilter(filterIndex: value)
    ][_selectedSectionIndex];

    return InkWell(
      onTap: () {
        setState(() {
          _selectedFilteredIndex = value;
        });
      },
      borderRadius: BorderRadius.circular(24),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2563EB) : Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color:
                    isSelected
                        ? Colors.white.withOpacity(0.3)
                        : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : const Color(0xFF6B7280),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJobCard(Task task) {

    // final isStarted = task.status == TaskStatus.printing;
    final isBlocked = task.status == TaskStatus.blocked;

    final isOverdue = task.productionStartTime != null && task.productionStartTime!.isBefore(DateTime.now());

    final scheduleTimeColor = isOverdue? Colors.red : Color(0xFF9CA3AF);
    
    final isAlert = isBlocked || isOverdue; 

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          AppRoutes.navigateTo(context, AppRoutes.schedulePrintView, arguments: SchedulePrintJobArgs.details(task: task));
        },
        child: Ink(
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
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color:
                          isAlert
                              ? const Color(0xFFFEE2E2)
                              : const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isBlocked ? Icons.block : isOverdue? Icons.warning_amber_rounded : Icons.arrow_downward,
                      color:
                          isAlert
                              ? const Color(0xFFEF4444)
                              : const Color(0xFF10B981),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.name,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.schedule_rounded,
                                size: 15, color: scheduleTimeColor),
                            Text(
                              task.productionStartTime != null
                                  ? ' ${task.productionStartTime!.eventIn}${isOverdue? ", Overdue" : ""}'
                                  : ' No Start Time',
                              style: TextStyle(
                                fontSize: 14,
                                color: scheduleTimeColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isAlert
                              ? const Color(0xFFFEE2E2)
                              : const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      task.statusName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color:
                            isAlert
                                ? const Color(0xFFEF4444)
                                : const Color(0xFF10B981),
                      ),
                    ),
                  ),
                ],
              ),
        
              if (task.status == "printing") ...[
                const SizedBox(height: 20),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value:
                        0 /
                        task.productionDuration,
                    backgroundColor: const Color(0xFFEDF2F7),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF2563EB),
                    ),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '0/${task.productionDuration} min',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    Text(
                      '${0-task.productionDuration} min left',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ],
                ),
              ],
        
              if (task.description.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 18,
                        color: Color(0xFFEF4444),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          task.description,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
        
              const SizedBox(height: 16),
        
              Row(
                children: [
                  const Icon(
                    Icons.person_outline,
                    size: 16,
                    color: Color(0xFF9CA3AF),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'By Ibrahim',
                    style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                  ),
                  Spacer(),
                  if (task.isDeprecated) ...[
                    Icon(Icons.priority_high_rounded, size: 15, color: Colors.redAccent),
                    Text("Deprecated", style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.redAccent
                    ))
                  ]
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrinterCard(Printer printer) {
    final statusColor = _getPrinterStatusColor(printer.status);

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: InkWell(
        onTap: () {
          AppRoutes.navigateTo(context, AppRoutes.printerDetails,
              arguments: printer);
        },
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.print, color: statusColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      printer.nickname,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _getPrinterStatusLabel(printer.status),
                          style: TextStyle(
                            fontSize: 14,
                            color: statusColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (printer.location != null) ...[
                          const SizedBox(width: 8),
                          const Text(
                            '•',
                            style: TextStyle(color: Color(0xFF9CA3AF)),
                          ),
                          const SizedBox(width: 8),
                          if (printer.location == null || printer.location!.isEmpty) 
                          ...[Icon(Icons.location_off_outlined, size: 18, color: const Color(0xFF9CA3AF)),
                          Text(" N/a", style: TextStyle(color: const Color(0xFF9CA3AF)),)]
                          else Text(
                            printer.location!,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF9CA3AF),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleCard() {
    final todaysSchedule = ref.watch(taskNotifierProvider.notifier).todaysProductionTasks;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          ...todaysSchedule.map((task) {
            final productionStartTime = task.productionStartTime!;
            final  duration = 145;
            final durationDisplay = duration/60 > 0? "${(duration/60).toInt()} hrs ${duration%60} mins" : "${duration} mins";
            return _buildScheduleItem("${productionStartTime.hour}:${productionStartTime.minute.toString().padLeft(0)}", task.name, durationDisplay);
          }),
          if (todaysSchedule.isEmpty) ... [
            Row(
              spacing: 15,
              children: [
                Icon(Icons.schema_rounded),
                Expanded(child: Text("No print jobs scheduled for today", style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15),))
              ],
            )
          ]
        ],
      ),
    );
  }

  Widget _buildScheduleItem(
    String time,
    String title,
    String duration, {
    bool isLast = false,
  }) {
    return Container(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
      margin: EdgeInsets.only(bottom: isLast ? 0 : 16),
      decoration: BoxDecoration(
        border:
            isLast
                ? null
                : const Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              time,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2563EB),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  duration,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialCard(
    MaterialModel material
  ) {

    final name = material.name;
    final stock = "${material.currentStock} ${material.unit}";
    final status = material.stockStatus;
    final color = material.stockStatusColor;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          AppRoutes.navigateTo(
            context, AppRoutes.materialTransactions,
            arguments: MaterialStockTransactionArgs(materialId: material.id)
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.inventory_2, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      stock,
                      style: TextStyle(
                        fontSize: 14,
                        color: color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getPrinterStatusColor(PrinterStatus status) {
    switch (status) {
      case PrinterStatus.active:
        return const Color(0xFF10B981);
      case PrinterStatus.offline:
        return const Color(0xFF6B7280);
      case PrinterStatus.maintenance:
        return const Color(0xFFF59E0B);
      case PrinterStatus.error:
        return const Color(0xFFEF4444);
    }
  }

  String _getPrinterStatusLabel(PrinterStatus status) {
    switch (status) {
      case PrinterStatus.active:
        return 'Active';
      case PrinterStatus.offline:
        return 'Offline';
      case PrinterStatus.maintenance:
        return 'Maintenance';
      case PrinterStatus.error:
        return 'Error';
    }
  }
}

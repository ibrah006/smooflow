import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/core/app_routes.dart';
import 'package:smooflow/core/models/printer.dart';
import 'package:smooflow/providers/printer_provider.dart';
import 'package:smooflow/providers/task_provider.dart';


class PrintersManagementScreen extends ConsumerStatefulWidget {
  /// 'busy', 'available', 'maintenance', 'blocked' or null for all
  final String? initialFilter;

  const PrintersManagementScreen({
    Key? key,
    this.initialFilter,
  }) : super(key: key);

  @override
  ConsumerState<PrintersManagementScreen> createState() =>
      _PrintersManagementScreenState();
}

class _PrintersManagementScreenState extends ConsumerState<PrintersManagementScreen> {
  late String? selectedFilter;
  String searchQuery = '';
  String sortBy = 'name'; // name, status, section, jobs

  @override
  void initState() {
    super.initState();
    selectedFilter = widget.initialFilter;
  }

  List<Printer> get printers=> ref.watch(printerNotifierProvider).printers;

  List<Printer> get filteredPrinters {
    var ps = printers;
    // Apply status filter
    if (selectedFilter != null) {
      ps = ps.where((p) => p.status == selectedFilter).toList();
    }

    // Apply search filter
    if (searchQuery.isNotEmpty) {
      ps = ps.where((p) {
        final query = searchQuery.toLowerCase();
        return p.name.toLowerCase().contains(query) ||
            p.nickname.toLowerCase().contains(query) ||
            p.location?.toLowerCase().contains(query) == true;
      }).toList();
    }

    // Apply sorting
    switch (sortBy) {
      case 'name':
        ps.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'status':
        ps.sort((a, b) => a.status.index.compareTo(b.status.index));
        break;
      case 'section':
        ps.sort((a, b) => a.location?.compareTo(b.location ?? '') ?? 0);
        break;
      case 'jobs':
        ps.sort((a, b) =>
            b.totalJobsCompleted.compareTo(a.totalJobsCompleted));
        break;
    }

    return ps;
  }

  int _getPrinterCountByFilter(String filter) {

    return printers.where((p) => (filter == 'available' && !p.isBusy && p.isActive) || (filter == 'busy' && p.isBusy) || p.status.name == filter).length;
  }

  void onStartMaintenance (Printer printer) {}
  void onUnblock (Printer printer) {}
  void onBlock (Printer printer) {}
  void onAddPrinter() {
    AppRoutes.navigateTo(context, AppRoutes.addPrinter);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Bar
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.arrow_back_ios_new,
                            color: Color(0xFF475569),
                            size: 20,
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Printer Fleet',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                                letterSpacing: -0.5,
                              ),
                            ),
                            Text(
                              '${printers.length} printer(s) total',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Sort Menu
                      PopupMenuButton<String>(
                        initialValue: sortBy,
                        offset: Offset(0, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.sort_rounded,
                            color: Color(0xFF475569),
                            size: 22,
                          ),
                        ),
                        onSelected: (value) {
                          setState(() => sortBy = value);
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'name',
                            child: Row(
                              children: [
                                Icon(Icons.sort_by_alpha,
                                    size: 20, color: Color(0xFF64748B)),
                                SizedBox(width: 12),
                                Text('Sort by Name'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'status',
                            child: Row(
                              children: [
                                Icon(Icons.flag_outlined,
                                    size: 20, color: Color(0xFF64748B)),
                                SizedBox(width: 12),
                                Text('Sort by Status'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'section',
                            child: Row(
                              children: [
                                Icon(Icons.location_on_outlined,
                                    size: 20, color: Color(0xFF64748B)),
                                SizedBox(width: 12),
                                Text('Sort by Section'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'jobs',
                            child: Row(
                              children: [
                                Icon(Icons.assignment_outlined,
                                    size: 20, color: Color(0xFF64748B)),
                                SizedBox(width: 12),
                                Text('Sort by Jobs'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Color(0xFFE2E8F0)),
                    ),
                    child: TextField(
                      onChanged: (value) {
                        setState(() => searchQuery = value);
                      },
                      decoration: InputDecoration(
                        hintText: 'Search printers by name, model, section...',
                        hintStyle: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 15,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: Color(0xFF64748B),
                          size: 22,
                        ),
                        suffixIcon: searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  Icons.clear,
                                  color: Color(0xFF64748B),
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() => searchQuery = '');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),

            // Filter Chips
            Container(
              color: Colors.white,
              padding: EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip(
                      label: 'All',
                      count: printers.length,
                      isSelected: selectedFilter == null,
                      onTap: () => setState(() => selectedFilter = null),
                    ),
                    SizedBox(width: 10),
                    _buildFilterChip(
                      label: 'Available',
                      count: _getPrinterCountByFilter('available'),
                      isSelected: selectedFilter == 'available',
                      statusColor: Color(0xFF10B981),
                      onTap: () => setState(() => selectedFilter = 'available'),
                    ),
                    SizedBox(width: 10),
                    _buildFilterChip(
                      label: 'Busy',
                      count: _getPrinterCountByFilter('busy'),
                      isSelected: selectedFilter == 'busy',
                      statusColor: Color(0xFF2563EB),
                      onTap: () => setState(() => selectedFilter = 'busy'),
                    ),
                    SizedBox(width: 10),
                    _buildFilterChip(
                      label: 'Maintenance',
                      count: _getPrinterCountByFilter('maintenance'),
                      isSelected: selectedFilter == 'maintenance',
                      statusColor: Color(0xFFF59E0B),
                      onTap: () => setState(() => selectedFilter = 'maintenance'),
                    ),
                    SizedBox(width: 10),
                    _buildFilterChip(
                      label: 'Blocked',
                      count: _getPrinterCountByFilter('blocked'),
                      isSelected: selectedFilter == 'blocked',
                      statusColor: Color(0xFFEF4444),
                      onTap: () => setState(() => selectedFilter = 'blocked'),
                    ),
                  ],
                ),
              ),
            ),
            Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),

            // Printers List
            Expanded(
              child: Container(
                color: Color(0xFFF8FAFC),
                child: filteredPrinters.isEmpty 
                  ? _buildEmptyState()
                  : ListView.separated(
                      padding: EdgeInsets.all(20),
                      itemCount: filteredPrinters.length,
                      separatorBuilder: (context, index) => SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final printer = filteredPrinters[index];
                        return _buildPrinterCard(printer);
                      },
                    )
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: showEmptyStateAddPrinter? null : FloatingActionButton.extended(
        onPressed: onAddPrinter,
        backgroundColor: Color(0xFF2563EB),
        elevation: 4,
        icon: Icon(Icons.add_rounded, size: 24),
        label: Text(
          'Add Printer',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required int count,
    required bool isSelected,
    Color? statusColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFF2563EB) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? Color(0xFF2563EB) : Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Color(0xFF2563EB).withOpacity(0.2),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  )
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (statusColor != null && !isSelected) ...[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: statusColor,
                ),
              ),
              SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Color(0xFF475569),
                letterSpacing: -0.2,
              ),
            ),
            SizedBox(width: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withOpacity(0.2)
                    : Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : Color(0xFF64748B),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrinterCard(Printer printer) {

    late final String currentJobName;

    try {
      currentJobName = printer.currentJobId != null ? ref.watch(taskNotifierProvider).firstWhere((task) => task.id == printer.currentJobId).name : "No job assigned";
    } catch (e) {
      currentJobName = "Updating current job...";
    }

    return GestureDetector(
      onTap: () {
        _showPrinterDetailsBottomSheet(printer);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
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
          children: [
            // Header
            Padding(
              padding: EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: printer.statusBackgroundColor,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.print_rounded,
                      color: printer.statusColor,
                      size: 28,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          printer.nickname,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.3,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          printer.name,
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: printer.statusColor,
                              ),
                            ),
                            SizedBox(width: 6),
                            Text(
                              printer.statusLabel,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: printer.statusColor,
                              ),
                            ),
                            SizedBox(width: 10),
                            Text(
                              '•',
                              style: TextStyle(color: Color(0xFF94A3B8)),
                            ),
                            SizedBox(width: 10),
                            Icon(Icons.location_on_outlined,
                                size: 14, color: Color(0xFF64748B)),
                            SizedBox(width: 4),
                            Text(
                              printer.location?? 'No section',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF94A3B8),
                    size: 24,
                  ),
                ],
              ),
            ),

            // Current Job / Status Details
            if (printer.isBusy) ...[
              Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),
              Padding(
                padding: EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.play_circle_filled,
                                size: 12,
                                color: Color(0xFF2563EB),
                              ),
                              SizedBox(width: 4),
                              Text(
                                'IN PROGRESS',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF2563EB),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Spacer(),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text(
                      currentJobName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    if (printer.currentJobId != null) ...[
                      SizedBox(height: 4),
                      Text(
                        'Job #${printer.currentJobId}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                    
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: .65,
                              backgroundColor: Color(0xFFE2E8F0),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF2563EB),
                              ),
                              minHeight: 8,
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          '65%',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            if (printer.status == PrinterStatus.maintenance) ...[
              Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),
              Container(
                padding: EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.build_circle,
                        size: 20, color: Color(0xFFF59E0B)),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Under Maintenance',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF92400E),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (printer.status == PrinterStatus.error) ...[
              Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),
              Container(
                padding: EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.block, size: 20, color: Color(0xFFEF4444)),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Printer Blocked',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF991B1B),
                            ),
                          ),
                          
                          SizedBox(height: 2),
                          Text(
                            // TODO: TO be Implemented (as optional to add reason for block)
                            "Blocked due to error state. Please unblock after resolving the issue.",
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFFC81E1E),
                            ),
                          ),
                          
                        ],
                      ),
                    ),
                    TextButton(
                        onPressed: () => onUnblock(printer),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Unblock',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],

            // Stats Footer (for available printers)
            if (!printer.isBusy && printer.isActive) ...[
              Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),
              Padding(
                padding: EdgeInsets.all(18),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        icon: Icons.assignment_turned_in_outlined,
                        label: 'Total Jobs',
                        value: printer.totalJobsCompleted.toString(),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: Color(0xFFE2E8F0),
                    ),
                    SizedBox(width: 16),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
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
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }

  bool get showEmptyStateAddPrinter=> filteredPrinters.isEmpty  && (selectedFilter == null || selectedFilter == 'available');

  Widget _buildEmptyState() {
    String message;
    String description;

    if (searchQuery.isNotEmpty) {
      message = 'No Printers Found';
      description = 'Try adjusting your search or filters';
    } else if (selectedFilter != null) {
      message = 'No ${selectedFilter!.capitalize()} Printers';
      description = 'There are no printers with this status';
    } else {
      message = 'No Printers Available';
      description = 'Add printers to start managing your fleet';
    }

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
              Icons.print_disabled_rounded,
              size: 48,
              color: Color(0xFF94A3B8),
            ),
          ),
          SizedBox(height: 24),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F172A),
              letterSpacing: -0.3,
            ),
          ),
          SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          if (showEmptyStateAddPrinter) ElevatedButton.icon(
            onPressed: onAddPrinter,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF2563EB),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            icon: Icon(Icons.add, size: 20),
            label: Text(
              'Add Printer',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPrinterDetailsBottomSheet(Printer printer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PrinterDetailsBottomSheet(
        printer: printer,
        onStartMaintenance: onStartMaintenance,
        onBlock: onBlock,
        onUnblock: onUnblock,
      ),
    );
  }
}

class PrinterDetailsBottomSheet extends StatelessWidget {
  final Printer printer;
  final Function(Printer)? onStartMaintenance;
  final Function(Printer)? onBlock;
  final Function(Printer)? onUnblock;

  const PrinterDetailsBottomSheet({
    Key? key,
    required this.printer,
    this.onStartMaintenance,
    this.onBlock,
    this.onUnblock,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: printer.statusBackgroundColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.print_rounded,
                    color: printer.statusColor,
                    size: 32,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        printer.name,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.4,
                        ),
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: printer.statusBackgroundColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  printer.statusIcon,
                                  size: 12,
                                  color: printer.statusColor,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  printer.statusLabel.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: printer.statusColor,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Basic Information
                  _buildSection(
                    title: 'Basic Information',
                    child: Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          _buildDetailRow('Model', printer.name),
                          _buildDetailRow('Section', printer.location ?? 'No section'),
                          /// TODO :Implement this
                          // if (printer.ipAddress != null)
                          //   _buildDetailRow('IP Address', printer.ipAddress!),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 20),

                  // Statistics
                  _buildSection(
                    title: 'Statistics',
                    child: Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          _buildDetailRow(
                            'Total Jobs Completed',
                            printer.totalJobsCompleted.toString(),
                          ),
                          // if (printer.lastMaintenance != null)
                          //   _buildDetailRow(
                          //     'Last Maintenance',
                          //     DateFormat('MMM dd, yyyy')
                          //         .format(printer.lastMaintenance!),
                          //   ),
                          // if (printer.nextMaintenance != null)
                          //   _buildDetailRow(
                          //     'Next Maintenance',
                          //     DateFormat('MMM dd, yyyy')
                          //         .format(printer.nextMaintenance!),
                          //   ),
                        ],
                      ),
                    ),
                  ),

                  /// Capabilities
                  // if (printer.capabilities.isNotEmpty) ...[
                  //   SizedBox(height: 20),
                  //   _buildSection(
                  //     title: 'Capabilities',
                  //     child: Wrap(
                  //       spacing: 8,
                  //       runSpacing: 8,
                  //       children: printer.capabilities
                  //           .map((capability) => Container(
                  //                 padding: EdgeInsets.symmetric(
                  //                   horizontal: 12,
                  //                   vertical: 6,
                  //                 ),
                  //                 decoration: BoxDecoration(
                  //                   color: Color(0xFFF1F5F9),
                  //                   borderRadius: BorderRadius.circular(8),
                  //                 ),
                  //                 child: Text(
                  //                   capability,
                  //                   style: TextStyle(
                  //                     fontSize: 13,
                  //                     fontWeight: FontWeight.w500,
                  //                     color: Color(0xFF475569),
                  //                   ),
                  //                 ),
                  //               ))
                  //           .toList(),
                  //     ),
                  //   ),
                  // ],

                  SizedBox(height: 32),

                  // Actions
                  if (!printer.isBusy && printer.isActive &&
                      onStartMaintenance != null)
                    _buildActionButton(
                      label: 'Start Maintenance',
                      icon: Icons.build_circle,
                      color: Color(0xFFF59E0B),
                      onPressed: () {
                        Navigator.pop(context);
                        onStartMaintenance!(printer);
                      },
                    ),

                  if (!printer.isBusy && printer.isActive && onBlock != null)
                    ...[
                      SizedBox(height: 12),
                      _buildActionButton(
                        label: 'Block Printer',
                        icon: Icons.block,
                        color: Color(0xFFEF4444),
                        onPressed: () {
                          Navigator.pop(context);
                          onBlock!(printer);
                        },
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

  Widget _buildSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F172A),
            letterSpacing: -0.2,
          ),
        ),
        SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
            ),
          ),
          Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: color,
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        icon: Icon(icon, size: 20),
        label: Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
}
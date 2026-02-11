import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smooflow/core/models/printer.dart';


class PrintersManagementScreen extends StatefulWidget {
  final List<Printer> printers;
  final PrinterStatus? initialFilter;
  final Function(Printer)? onPrinterTap;
  final Function(Printer)? onStartMaintenance;
  final Function(Printer)? onUnblock;
  final Function(Printer)? onBlock;
  final VoidCallback? onAddPrinter;

  const PrintersManagementScreen({
    Key? key,
    required this.printers,
    this.initialFilter,
    this.onPrinterTap,
    this.onStartMaintenance,
    this.onUnblock,
    this.onBlock,
    this.onAddPrinter,
  }) : super(key: key);

  @override
  State<PrintersManagementScreen> createState() =>
      _PrintersManagementScreenState();
}

class _PrintersManagementScreenState extends State<PrintersManagementScreen> {
  late PrinterStatus? selectedFilter;
  String searchQuery = '';
  String sortBy = 'name'; // name, status, section, jobs

  @override
  void initState() {
    super.initState();
    selectedFilter = widget.initialFilter;
  }

  List<Printer> get filteredPrinters {
    var printers = widget.printers;

    // Apply status filter
    if (selectedFilter != null) {
      printers = printers.where((p) => p.status == selectedFilter).toList();
    }

    // Apply search filter
    if (searchQuery.isNotEmpty) {
      printers = printers.where((p) {
        final query = searchQuery.toLowerCase();
        return p.name.toLowerCase().contains(query) ||
            p.nickname.toLowerCase().contains(query) ||
            p.location?.toLowerCase().contains(query) == true;
      }).toList();
    }

    // Apply sorting
    switch (sortBy) {
      case 'name':
        printers.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'status':
        printers.sort((a, b) => a.status.index.compareTo(b.status.index));
        break;
      case 'section':
        printers.sort((a, b) => a.location?.compareTo(b.location ?? '') ?? 0);
        break;
      case 'jobs':
        printers.sort((a, b) =>
            b.totalJobsCompleted.compareTo(a.totalJobsCompleted));
        break;
    }

    return printers;
  }

  int _getPrinterCountByStatus(PrinterStatus status) {
    return widget.printers.where((p) => p.status == status).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              color: Colors.white,
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
                      SizedBox(width: 12),
                      Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Color(0xFF2563EB),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.print_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      SizedBox(width: 12),
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
                              '${widget.printers.length} printers total',
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
                      count: widget.printers.length,
                      isSelected: selectedFilter == null,
                      onTap: () => setState(() => selectedFilter = null),
                    ),
                    SizedBox(width: 10),
                    _buildFilterChip(
                      label: 'Available',
                      count: _getPrinterCountByStatus(PrinterStatus.available),
                      isSelected: selectedFilter == PrinterStatus.available,
                      statusColor: Color(0xFF10B981),
                      onTap: () =>
                          setState(() => selectedFilter = PrinterStatus.available),
                    ),
                    SizedBox(width: 10),
                    _buildFilterChip(
                      label: 'Busy',
                      count: _getPrinterCountByStatus(PrinterStatus.busy),
                      isSelected: selectedFilter == PrinterStatus.busy,
                      statusColor: Color(0xFF2563EB),
                      onTap: () =>
                          setState(() => selectedFilter = PrinterStatus.busy),
                    ),
                    SizedBox(width: 10),
                    _buildFilterChip(
                      label: 'Maintenance',
                      count: _getPrinterCountByStatus(PrinterStatus.maintenance),
                      isSelected: selectedFilter == PrinterStatus.maintenance,
                      statusColor: Color(0xFFF59E0B),
                      onTap: () => setState(
                          () => selectedFilter = PrinterStatus.maintenance),
                    ),
                    SizedBox(width: 10),
                    _buildFilterChip(
                      label: 'Blocked',
                      count: _getPrinterCountByStatus(PrinterStatus.blocked),
                      isSelected: selectedFilter == PrinterStatus.blocked,
                      statusColor: Color(0xFFEF4444),
                      onTap: () =>
                          setState(() => selectedFilter = PrinterStatus.blocked),
                    ),
                  ],
                ),
              ),
            ),
            Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),

            // Printers List
            Expanded(
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
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: widget.onAddPrinter != null
          ? FloatingActionButton.extended(
              onPressed: widget.onAddPrinter,
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
            )
          : null,
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
    return GestureDetector(
      onTap: () {
        if (widget.onPrinterTap != null) {
          widget.onPrinterTap!(printer);
        } else {
          _showPrinterDetailsBottomSheet(printer);
        }
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
                          printer.name,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.3,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          printer.model,
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
                              printer.section,
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
            if (printer.status == PrinterStatus.busy &&
                printer.currentJobName != null) ...[
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
                        if (printer.estimatedCompletion != null)
                          Row(
                            children: [
                              Icon(Icons.schedule,
                                  size: 14, color: Color(0xFF64748B)),
                              SizedBox(width: 4),
                              Text(
                                'ETC ${DateFormat('HH:mm').format(printer.estimatedCompletion!)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text(
                      printer.currentJobName!,
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
                    if (printer.progress != null) ...[
                      SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: printer.progress!,
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
                            '${(printer.progress! * 100).toInt()}%',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                        ],
                      ),
                    ],
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
                          if (printer.nextMaintenance != null) ...[
                            SizedBox(height: 2),
                            Text(
                              'Expected: ${DateFormat('MMM dd').format(printer.nextMaintenance!)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFFA16207),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (printer.status == PrinterStatus.blocked) ...[
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
                          if (printer.blockedReason != null) ...[
                            SizedBox(height: 2),
                            Text(
                              printer.blockedReason!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFFC81E1E),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (widget.onUnblock != null)
                      TextButton(
                        onPressed: () => widget.onUnblock!(printer),
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
            if (printer.status == PrinterStatus.available) ...[
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
                    Expanded(
                      child: _buildStatItem(
                        icon: Icons.schedule_outlined,
                        label: 'Last Maintenance',
                        value: printer.lastMaintenance != null
                            ? DateFormat('MMM dd')
                                .format(printer.lastMaintenance!)
                            : 'N/A',
                      ),
                    ),
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

  Widget _buildEmptyState() {
    String message;
    String description;

    if (searchQuery.isNotEmpty) {
      message = 'No Printers Found';
      description = 'Try adjusting your search or filters';
    } else if (selectedFilter != null) {
      message = 'No ${selectedFilter!.name.capitalize()} Printers';
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
          if (widget.onAddPrinter != null) ...[
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: widget.onAddPrinter,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF2563EB),
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
        onStartMaintenance: widget.onStartMaintenance,
        onBlock: widget.onBlock,
        onUnblock: widget.onUnblock,
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
                          _buildDetailRow('Model', printer.model),
                          _buildDetailRow('Section', printer.section),
                          if (printer.serialNumber != null)
                            _buildDetailRow('Serial Number', printer.serialNumber!),
                          if (printer.ipAddress != null)
                            _buildDetailRow('IP Address', printer.ipAddress!),
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
                          if (printer.lastMaintenance != null)
                            _buildDetailRow(
                              'Last Maintenance',
                              DateFormat('MMM dd, yyyy')
                                  .format(printer.lastMaintenance!),
                            ),
                          if (printer.nextMaintenance != null)
                            _buildDetailRow(
                              'Next Maintenance',
                              DateFormat('MMM dd, yyyy')
                                  .format(printer.nextMaintenance!),
                            ),
                        ],
                      ),
                    ),
                  ),

                  if (printer.capabilities.isNotEmpty) ...[
                    SizedBox(height: 20),
                    _buildSection(
                      title: 'Capabilities',
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: printer.capabilities
                            .map((capability) => Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    capability,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF475569),
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                  ],

                  SizedBox(height: 32),

                  // Actions
                  if (printer.status == PrinterStatus.available &&
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

                  if (printer.status == PrinterStatus.available && onBlock != null)
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

                  if (printer.status == PrinterStatus.blocked &&
                      onUnblock != null) ...[
                    _buildActionButton(
                      label: 'Unblock Printer',
                      icon: Icons.check_circle,
                      color: Color(0xFF10B981),
                      onPressed: () {
                        Navigator.pop(context);
                        onUnblock!(printer);
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
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/constants.dart';
import 'package:smooflow/core/app_routes.dart';
import 'package:smooflow/core/args/task_args.dart';
import 'package:smooflow/core/models/printer.dart';
import 'package:smooflow/providers/task_provider.dart';

class PrinterScreen extends ConsumerWidget {

  final Printer printer;

  const PrinterScreen({super.key, required this.printer});

  void onStartMaintenance (Printer printer) {}
  void onBlock (Printer printer) {}

  @override
  Widget build(BuildContext context, ref) {

    String? printJobName;
    if (printer.currentJobId != null) {
      try {
        printJobName = ref.watch(taskNotifierProvider).tasks.firstWhere((t)=> t.id == printer.currentJobId).name;
      } catch(e) {
        printJobName = "Loading Task...";
      }
    }

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 100,
        automaticallyImplyLeading: false,
        flexibleSpace: SafeArea(
          child: Container(
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
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.arrow_back_ios_rounded, color: Color(0xFF64748B)),
                ),
                Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: printer.statusBackgroundColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.print_rounded,
                          color: printer.statusColor,
                          size: 28,
                        ),
                      ),
                SizedBox(width: 12),
                Expanded(
                  child: Row(
                    spacing: 5,
                    children: [
                      Text(
                        printer.nickname,
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
              ],
            ),
          ),
        ),
      ),
      body: Column(
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

                    // Current Task Link (when busy)
                    if (printer.isBusy && printer.currentJobId != null) ...[
                      SizedBox(height: 12),
                      InkWell(
                        onTap: () {
                          // Navigate to the current task
                          // TODO: Implement navigation to task detail screen
                          // Navigator.push(
                          //   context,
                          //   MaterialPageRoute(
                          //     builder: (context) => TaskDetailScreen(task: printer.currentTask!),
                          //   ),
                          // );

                          AppRoutes.navigateTo(context, AppRoutes.task, arguments: TaskArgs(printer.currentJobId!));
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Color(0xFF2563EB).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.assignment_outlined,
                                  color: Color(0xFF2563EB),
                                  size: 18,
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Currently Printing',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: colorPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      printJobName.toString(),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF0F172A),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: Color(0xFF2563EB),
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
      
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
      
                    SizedBox(height: 50),

                    // Note
                    if (!(!printer.isBusy && printer.isActive)) Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 5,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 2.0),
                          child: Icon(Icons.info_outline_rounded, color: Color(0xFF64748B), size: 18),
                        ),
                        Expanded(
                          child: Text(
                            "You can only perform maintenance or block actions when the printer is not busy.",
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 16),
                    
                    // Actions
                    _buildActionButton(
                      label: 'Start Maintenance',
                      icon: Icons.build_circle,
                      color: Color(0xFFF59E0B),
                      onPressed: !printer.isBusy && printer.isActive? () {
                        Navigator.pop(context);
                        onStartMaintenance(printer);
                      } : null,
                    ),
      
                    SizedBox(height: 12),
                    _buildActionButton(
                      label: 'Block Printer',
                      icon: Icons.block,
                      color: Color(0xFFEF4444),
                      onPressed: !printer.isBusy && printer.isActive? () {
                        Navigator.pop(context);
                        onBlock(printer);
                      } : null,
                    ),
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
    required VoidCallback? onPressed,
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
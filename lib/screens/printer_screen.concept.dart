
import 'package:flutter/material.dart';
import 'package:smooflow/core/models/printer.dart';

class PrinterScreen extends StatelessWidget {

  final Printer printer;

  const PrinterScreen({super.key, required this.printer});

  void onStartMaintenance (Printer printer) {}
  void onBlock (Printer printer) {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                    if (!printer.isBusy && printer.isActive)
                      _buildActionButton(
                        label: 'Start Maintenance',
                        icon: Icons.build_circle,
                        color: Color(0xFFF59E0B),
                        onPressed: () {
                          Navigator.pop(context);
                          onStartMaintenance(printer);
                        },
                      ),
      
                    if (!printer.isBusy && printer.isActive)
                      ...[
                        SizedBox(height: 12),
                        _buildActionButton(
                          label: 'Block Printer',
                          icon: Icons.block,
                          color: Color(0xFFEF4444),
                          onPressed: () {
                            Navigator.pop(context);
                            onBlock(printer);
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
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/data/production_report_details.dart';

class ProductionReportHeader extends ConsumerWidget {
  final OverviewData overviewData;

  const ProductionReportHeader({
    Key? key,
    required this.overviewData
  }) : super(key: key);

  int get activePrinters => overviewData.activePrinters;
  int get totalPrinters => overviewData.totalPrinters;
  double get averageUtilization => overviewData.averageUtilization;
  int get maintenancePrinters => overviewData.maintenancePrinters;
  int get offlinePrinters => overviewData.offlinePrinters;
  int get jobsInProgress => 2;
  int get jobsPending => 3;
  int get jobsCompletedToday => 2;
  double get avgJobCompletionTime => 20;

  @override
  Widget build(BuildContext context, ref) {

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Printer KPIs Section
        _buildSectionHeader(
          context,
          'Printer Status',
          Icons.print_rounded,
          'Machine-level metrics',
        ),
        const SizedBox(height: 16),
        _buildPrinterKPIs(),
        
        const SizedBox(height: 32),
        
        // Print Job KPIs Section
        _buildSectionHeader(
          context,
          'Print Jobs',
          Icons.assignment_rounded,
          'Workflow & queue metrics',
        ),
        const SizedBox(height: 16),
        _buildJobKPIs(),
      ],
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
    String subtitle,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: Colors.black, size: 27),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF94A3B8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPrinterKPIs() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          // Primary metric - Active Printers
          _buildPrimaryMetric(
            icon: Icons.check_circle_rounded,
            label: 'Active Printers',
            value: '$activePrinters',
            subtitle: 'of $totalPrinters total',
            progress: activePrinters / (totalPrinters == 0 ? 1 : totalPrinters),
            color: const Color(0xFF10B981),
          ),
          
          const SizedBox(height: 20),
          
          // Secondary metrics row
          Row(
            children: [
              Expanded(
                child: _buildSecondaryMetric(
                  icon: Icons.show_chart_rounded,
                  label: 'Avg. Utilization',
                  value: '${averageUtilization.toStringAsFixed(1)}%',
                  color: const Color(0xFF2563EB),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSecondaryMetric(
                  icon: Icons.build_rounded,
                  label: 'Maintenance',
                  value: maintenancePrinters.toString(),
                  color: const Color(0xFFF59E0B),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSecondaryMetric(
                  icon: Icons.power_off_rounded,
                  label: 'Offline',
                  value: offlinePrinters.toString(),
                  color: const Color(0xFFEF4444),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildJobKPIs() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          // Jobs in progress - prominent display
          Row(
            children: [
              Expanded(
                child: _buildJobMetricCard(
                  icon: Icons.autorenew_rounded,
                  label: 'In Progress',
                  value: jobsInProgress.toString(),
                  subtitle: 'Active jobs',
                  color: const Color(0xFF2563EB),
                  isPrimary: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildJobMetricCard(
                  icon: Icons.schedule_rounded,
                  label: 'Pending',
                  value: jobsPending.toString(),
                  subtitle: 'In queue',
                  color: const Color(0xFFF59E0B),
                  isPrimary: true,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Additional job metrics
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildCompactMetric(
                    icon: Icons.check_circle_outline_rounded,
                    label: 'Completed Today',
                    value: jobsCompletedToday.toString(),
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: const Color(0xFFE2E8F0),
                ),
                Expanded(
                  child: _buildCompactMetric(
                    icon: Icons.timer_outlined,
                    label: 'Avg. Time/',
                    highlightLabel: "Project",
                    value: '${avgJobCompletionTime.toStringAsFixed(1)}h',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryMetric({
    required IconData icon,
    required String label,
    required String value,
    required String subtitle,
    required double progress,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        value,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                          height: 1,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF94A3B8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: const Color(0xFFF1F5F9),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildSecondaryMetric({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobMetricCard({
    required IconData icon,
    required String label,
    required String value,
    required String subtitle,
    required Color color,
    bool isPrimary = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: -0.8,
              height: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactMetric({
    required IconData icon,
    required String label,
    required String value,
    String? highlightLabel
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: const Color(0xFF64748B), size: 18),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
                height: 1.2,
              ),
            ),
            Row(
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (highlightLabel!=null) Text(
                  highlightLabel,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade800,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
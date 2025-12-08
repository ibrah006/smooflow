// lib/screens/reports/project_reports_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;

import 'package:smooflow/constants.dart';
import 'package:smooflow/enums/period.dart';
import 'package:smooflow/providers/project_provider.dart';

class ProjectReportsScreen extends ConsumerStatefulWidget {
  const ProjectReportsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ProjectReportsScreen> createState() => _ProjectReportsScreenState();
}

class _ProjectReportsScreenState extends ConsumerState<ProjectReportsScreen> {
  Period _selectedPeriod = Period.thisWeek;
  
  // Mock data
  final Map<String, int> _statusDistribution = {
    'Planned': 4,
    'Printing': 7,
    'Finishing': 6,
    'Installing': 5,
    'Delayed': 3,
  };
  
  final Map<String, int> _delayReasons = {
    'Machine breakdown': 8,
    'Client confirmation': 6,
    'Material shortage': 4,
    'Power outage': 2,
    'Staffing issues': 5,
  };

  @override
  void initState() {
    super.initState();

    Future.microtask(() async {
      await ref.watch(projectNotifierProvider.notifier).ensureReportLoaded(_selectedPeriod);
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {

    // final_statusDistribution = ;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          // Header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(20).copyWith(top: MediaQuery.of(context).padding.top + 20),
            child: Row(
              children: [
                InkWell(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F7FA),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.arrow_back, color: Colors.black, size: 22),
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Project Reports',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Analytics & Insights',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () {},
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F7FA),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.file_download, color: Colors.black, size: 22),
                  ),
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Period Filter
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(23),
                  ),
                  child: Row(
                    children: [
                      _buildPeriodTab('this Week'),
                      _buildPeriodTab('this Month'),
                      _buildPeriodTab('this Year'),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Executive Overview - KPI Strip
                const Text(
                  'Executive Overview',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      child: _buildKPICard(
                        value: '25',
                        label: 'Active\nProjects',
                        icon: Icons.work,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildKPICard(
                        value: '12',
                        label: 'Completed\nThis Week',
                        icon: Icons.check_circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildKPICard(
                        value: '3',
                        label: 'Delayed\nProjects',
                        icon: Icons.warning,
                        isWarning: true,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                // Project Status Distribution
                const Text(
                  'Project Status Distribution',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                      // Pie Chart
                      SizedBox(
                        height: 200,
                        child: CustomPaint(
                          painter: PieChartPainter(_statusDistribution),
                          child: Container(),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Legend
                      ..._buildStatusLegend(),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Delay Analysis
                const Text(
                  'Delay Analysis',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                
                const SizedBox(height: 16),
                
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
                        'Delays by Reason',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Bar Chart
                      ..._buildDelayBars(),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Quick Stats Grid
                const Text(
                  'Performance Metrics',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                      _buildMetricRow('On-Time Delivery', '87%'),
                      const SizedBox(height: 16),
                      _buildMetricRow('Avg. Project Duration', '12 days'),
                      const SizedBox(height: 16),
                      _buildMetricRow('Client Satisfaction', '94%'),
                      const SizedBox(height: 16),
                      _buildMetricRow('Total Revenue', '\$24,580'),
                    ],
                  ),
                ),
                
                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodTab(String period) {
    final isSelected = _selectedPeriod == Period.values.byName(period.replaceAll(" ", ""));

    print("is seelcyed: #$isSelected");
    
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedPeriod = Period.values.byName(period.replaceAll(" ", ""))),
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? colorPrimary : Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            period[0].toUpperCase() + period.substring(1),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : const Color(0xFF9CA3AF),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKPICard({
    required String value,
    required String label,
    required IconData icon,
    bool isWarning = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isWarning 
                  ? const Color(0xFFFEE2E2)
                  : const Color(0xFFF5F7FA),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: isWarning ? const Color(0xFFEF4444) : colorPrimary,
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: isWarning ? const Color(0xFFEF4444) : Colors.black,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF9CA3AF),
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildStatusLegend() {
    final colors = _getStatusColors();
    
    return _statusDistribution.entries.map((entry) {
      final color = colors[entry.key] ?? Colors.grey;
      final total = _statusDistribution.values.reduce((a, b) => a + b);
      final percentage = ((entry.value / total) * 100).toInt();
      
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                entry.key,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            ),
            Text(
              '${entry.value}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$percentage%',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  List<Widget> _buildDelayBars() {
    final maxValue = _delayReasons.values.reduce(math.max);
    
    return _delayReasons.entries.map((entry) {
      final percentage = entry.value / maxValue;
      
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    entry.key,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                ),
                Text(
                  '${entry.value}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: percentage,
                backgroundColor: const Color(0xFFF5F7FA),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFEF4444)),
                minHeight: 8,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildMetricRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            color: Color(0xFF6B7280),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Map<String, Color> _getStatusColors() {
    return {
      'Planned': const Color(0xFF2563EB),
      'Printing': const Color(0xFF8B5CF6),
      'Finishing': const Color(0xFF10B981),
      'Installing': const Color(0xFFF59E0B),
      'Delayed': const Color(0xFFEF4444),
    };
  }
}

// Custom Pie Chart Painter
class PieChartPainter extends CustomPainter {
  final Map<String, int> data;
  
  PieChartPainter(this.data);
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2.5;
    
    final total = data.values.reduce((a, b) => a + b);
    final colors = {
      'Planned': const Color(0xFF2563EB),
      'Printing': const Color(0xFF8B5CF6),
      'Finishing': const Color(0xFF10B981),
      'Installing': const Color(0xFFF59E0B),
      'Delayed': const Color(0xFFEF4444),
    };
    
    double startAngle = -math.pi / 2;
    
    data.forEach((key, value) {
      final sweepAngle = (value / total) * 2 * math.pi;
      final paint = Paint()
        ..color = colors[key] ?? Colors.grey
        ..style = PaintingStyle.fill;
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );
      
      startAngle += sweepAngle;
    });
    
    // Draw white center circle for donut effect
    final centerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(center, radius * 0.5, centerPaint);
    
    // Draw total in center
    final textPainter = TextPainter(
      text: TextSpan(
        children: [
          TextSpan(
            text: '$total\n',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: Colors.black,
              height: 1.2,
            ),
          ),
          const TextSpan(
            text: 'Total',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
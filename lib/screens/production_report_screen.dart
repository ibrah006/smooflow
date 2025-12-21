// lib/screens/reports/printer_reports_screen.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;

import 'package:smooflow/constants.dart';

class ProductionReportsScreen extends StatefulWidget {
  const ProductionReportsScreen({Key? key}) : super(key: key);

  @override
  State<ProductionReportsScreen> createState() => _ProductionReportsScreenState();
}

class _ProductionReportsScreenState extends State<ProductionReportsScreen> {
  String _selectedPeriod = 'This Week';
  
  // Mock data
  final Map<String, int> _printerStatus = {
    'Active': 4,
    'Idle': 2,
    'Maintenance': 1,
    'Offline': 1,
  };
  
  final List<Map<String, dynamic>> _printerUtilization = [
    {'name': 'Large Format A', 'utilization': 89, 'hours': 71, 'total': 80, 'jobs': 24},
    {'name': 'Vinyl Master', 'utilization': 74, 'hours': 59, 'total': 80, 'jobs': 18},
    {'name': 'Banner Pro', 'utilization': 52, 'hours': 42, 'total': 80, 'jobs': 12},
    {'name': 'Sticker Station', 'utilization': 46, 'hours': 37, 'total': 80, 'jobs': 15},
  ];
  
  final Map<String, int> _issueFrequency = {
    'Paper jam': 8,
    'Ink shortage': 5,
    'Head cleaning': 12,
    'Power failure': 3,
    'Software error': 6,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          // Header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(20).copyWith(top: MediaQuery.of(context).padding.top + 10),
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
                        'Printer Reports',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Production Analytics',
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
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      _buildPeriodTab('Today'),
                      _buildPeriodTab('This Week'),
                      _buildPeriodTab('This Month'),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // High-Level Summary KPIs
                const Text(
                  'Overview',
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
                        value: '8',
                        label: 'Total\nPrinters',
                        icon: Icons.print,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildKPICard(
                        value: '4',
                        label: 'Active\nNow',
                        icon: Icons.check_circle,
                        color: const Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    Expanded(
                      child: _buildKPICard(
                        value: '2',
                        label: 'Idle',
                        icon: Icons.remove_circle_outline,
                        color: const Color(0xFFF59E0B),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildKPICard(
                        value: '65%',
                        label: 'Avg\nUtilization',
                        icon: Icons.trending_up,
                        color: const Color(0xFF2563EB),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                // Printer Status Distribution
                const Text(
                  'Printer Status Distribution',
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
                      SizedBox(
                        height: 200,
                        child: CustomPaint(
                          painter: DonutChartPainter(_printerStatus),
                          child: Container(),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ..._buildStatusLegend(),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Printer Utilization
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Printer Utilization',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F7FA),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.info_outline, size: 14, color: Color(0xFF9CA3AF)),
                          SizedBox(width: 4),
                          Text(
                            'Hours active vs available',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF9CA3AF),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                ..._printerUtilization.map((printer) => _buildUtilizationCard(printer)),
                
                const SizedBox(height: 24),
                
                // Insights Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.lightbulb, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Insights',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildInsightItem('Most utilized: Large Format A (89%)'),
                      const SizedBox(height: 10),
                      _buildInsightItem('Underutilized: Sticker Station (46%)'),
                      const SizedBox(height: 10),
                      _buildInsightItem('Consider redistributing jobs to balance load'),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Downtime & Issues
                const Text(
                  'Downtime & Issues',
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
                      Row(
                        children: [
                          Expanded(
                            child: _buildDowntimeStat('12h', 'Total Downtime'),
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: const Color(0xFFF5F7FA),
                          ),
                          Expanded(
                            child: _buildDowntimeStat('34', 'Incidents'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Container(height: 1, color: const Color(0xFFF5F7FA)),
                      const SizedBox(height: 20),
                      const Text(
                        'Most Common Issues',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ..._buildIssueBars(),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Efficiency Ranking
                const Text(
                  'Efficiency Ranking',
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
                      _buildRankingItem(1, 'Large Format A', 94),
                      const SizedBox(height: 16),
                      _buildRankingItem(2, 'Vinyl Master', 87),
                      const SizedBox(height: 16),
                      _buildRankingItem(3, 'Banner Pro', 72),
                      const SizedBox(height: 16),
                      _buildRankingItem(4, 'Sticker Station', 58),
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
    final isSelected = _selectedPeriod == period;
    
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedPeriod = period),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? colorPrimary : Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            period,
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
    required Color color,
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
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: color,
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
    final colors = {
      'Active': const Color(0xFF10B981),
      'Idle': const Color(0xFFF59E0B),
      'Maintenance': const Color(0xFF2563EB),
      'Offline': const Color(0xFF6B7280),
    };
    
    return _printerStatus.entries.map((entry) {
      final color = colors[entry.key]!;
      final total = _printerStatus.values.reduce((a, b) => a + b);
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

  Widget _buildUtilizationCard(Map<String, dynamic> printer) {
    final utilization = printer['utilization'] as int;
    Color barColor;
    
    if (utilization >= 70) {
      barColor = const Color(0xFF10B981);
    } else if (utilization >= 40) {
      barColor = const Color(0xFFF59E0B);
    } else {
      barColor = const Color(0xFFEF4444);
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  printer['name'],
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: barColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$utilization%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: barColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: utilization / 100,
              backgroundColor: const Color(0xFFF5F7FA),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.access_time, size: 14, color: const Color(0xFF9CA3AF)),
              const SizedBox(width: 6),
              Text(
                '${printer['hours']}h / ${printer['total']}h',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF9CA3AF),
                ),
              ),
              const SizedBox(width: 16),
              Icon(Icons.work, size: 14, color: const Color(0xFF9CA3AF)),
              const SizedBox(width: 6),
              Text(
                '${printer['jobs']} jobs',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF9CA3AF),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInsightItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 4),
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.95),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDowntimeStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF9CA3AF),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildIssueBars() {
    final maxValue = _issueFrequency.values.reduce(math.max);
    
    return _issueFrequency.entries.take(5).map((entry) {
      final percentage = entry.value / maxValue;
      
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
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
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: percentage,
                backgroundColor: const Color(0xFFF5F7FA),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6B7280)),
                minHeight: 6,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildRankingItem(int rank, String name, int score) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: rank <= 2 
                ? const Color(0xFF2563EB).withOpacity(0.1)
                : const Color(0xFFF5F7FA),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              '$rank',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: rank <= 2 ? const Color(0xFF2563EB) : const Color(0xFF6B7280),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            name,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ),
        Container(
          width: 60,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: score / 100,
              backgroundColor: const Color(0xFFF5F7FA),
              valueColor: AlwaysStoppedAnimation<Color>(
                score >= 85 ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
              ),
              minHeight: 6,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '$score',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: score >= 85 ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
          ),
        ),
      ],
    );
  }
}

// Donut Chart Painter
class DonutChartPainter extends CustomPainter {
  final Map<String, int> data;
  
  DonutChartPainter(this.data);
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2.5;
    
    final total = data.values.reduce((a, b) => a + b);
    final colors = {
      'Active': const Color(0xFF10B981),
      'Idle': const Color(0xFFF59E0B),
      'Maintenance': const Color(0xFF2563EB),
      'Offline': const Color(0xFF6B7280),
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
    
    // Draw white center
    final centerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(center, radius * 0.5, centerPaint);
    
    // Draw total
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
            text: 'Printers',
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
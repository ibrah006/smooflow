import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/core/models/attendance/attendance_flag.dart';
import 'package:smooflow/core/models/attendance/shift.dart';
import 'package:smooflow/core/repositories/attendance_repo.dart';
import 'package:smooflow/providers/attendance_provider.dart';

const double _kRowHeight = 46;
const double _rSmall = 6;
const double _rLarge = 12;
const Duration _animationDuration = Duration(milliseconds: 300);

class EmployeeAttendanceScreen extends ConsumerStatefulWidget {
  final String employeeId;
  final String employeeName;

  const EmployeeAttendanceScreen({
    required this.employeeId,
    required this.employeeName,
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState<EmployeeAttendanceScreen> createState() =>
      _EmployeeAttendanceScreenState();
}

class _EmployeeAttendanceScreenState
    extends ConsumerState<EmployeeAttendanceScreen> {
  bool _isCheckingInOut = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final currentShift = ref.watch(currentShiftProvider(widget.employeeId));
    final todayMetrics = _getTodayMetrics();

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(),
            const SizedBox(height: 32),

            // Main Check-in/out Card
            _buildCheckInOutCard(currentShift),
            const SizedBox(height: 24),

            // Today's Summary
            _buildTodaySummary(currentShift),
            const SizedBox(height: 24),

            // This Week Overview
            _buildWeekOverview(),
            const SizedBox(height: 24),

            // Alerts (if any)
            _buildAlerts(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome, ${widget.employeeName}',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          'Track your work hours and breaks',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildCheckInOutCard(AsyncValue<Shift?> currentShiftAsync) {
    return currentShiftAsync.when(
      data: (currentShift) {
        final isCheckedIn = currentShift != null && currentShift.isActive;

        return Container(
          decoration: BoxDecoration(
            color:
                isCheckedIn
                    ? Colors.blue.withOpacity(0.05)
                    : Colors.green.withOpacity(0.05),
            border: Border.all(
              color: isCheckedIn ? Colors.blue : Colors.green,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(_rLarge),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: (isCheckedIn ? Colors.blue : Colors.green).withOpacity(
                    0.1,
                  ),
                  border: Border.all(
                    color: isCheckedIn ? Colors.blue : Colors.green,
                  ),
                  borderRadius: BorderRadius.circular(_rSmall),
                ),
                child: Text(
                  isCheckedIn ? 'Checked In' : 'Not Checked In',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: isCheckedIn ? Colors.blue : Colors.green,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Time display
              if (isCheckedIn)
                _buildCheckedInDisplay(currentShift!)
              else
                _buildNotCheckedInDisplay(),

              const SizedBox(height: 24),

              // Action button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                      _isCheckingInOut
                          ? null
                          : () => _handleCheckInOut(isCheckedIn),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isCheckedIn ? Colors.red : Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(_rSmall),
                    ),
                  ),
                  child:
                      _isCheckingInOut
                          ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                          : Text(
                            isCheckedIn ? 'Check Out' : 'Check In',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                ),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    border: Border.all(color: Colors.red),
                    borderRadius: BorderRadius.circular(_rSmall),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                  ),
                ),
              ],
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, st) => Center(child: Text('Error loading shift: $error')),
    );
  }

  Widget _buildCheckedInDisplay(Shift shift) {
    return Column(
      children: [
        Text(
          'You checked in at',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
        Text(
          shift.displayCheckInTime,
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(_rSmall),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Current session:',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  _buildElapsedTime(shift.checkInTime),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotCheckedInDisplay() {
    return Column(
      children: [
        Icon(Icons.access_time_outlined, size: 48, color: Colors.grey[400]),
        const SizedBox(height: 16),
        Text(
          'No active shift',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildElapsedTime(DateTime checkInTime) {
    return StreamBuilder<int>(
      stream: Stream.periodic(const Duration(seconds: 1), (_) {
        return DateTime.now().difference(checkInTime).inSeconds;
      }),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Text('--:--:--');

        final seconds = snapshot.data!;
        final hours = seconds ~/ 3600;
        final minutes = (seconds % 3600) ~/ 60;
        final secs = seconds % 60;

        return Text(
          '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontFamily: 'monospace',
          ),
        );
      },
    );
  }

  Widget _buildTodaySummary(AsyncValue<Shift?> currentShiftAsync) {
    return currentShiftAsync.when(
      data: (currentShift) {
        if (currentShift == null) {
          return const SizedBox.shrink();
        }

        final completedShifts = ref.watch(
          shiftsForRangeProvider(
            ShiftsForRangeParams(
              employeeId: widget.employeeId,
              startDate: DateTime.now(),
              endDate: DateTime.now(),
            ),
          ),
        );

        return completedShifts.when(
          data: (shifts) {
            if (shifts.isEmpty) return const SizedBox.shrink();

            final totalWorkTime = shifts.fold<int>(
              0,
              (sum, s) => sum + (s.workMinutes ?? 0),
            );
            final hours = totalWorkTime ~/ 60;
            final minutes = totalWorkTime % 60;

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.05),
                border: Border.all(color: Colors.amber.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(_rSmall),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Today's Summary",
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Work Time',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${hours}h ${minutes}m',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Shifts',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${shifts.length}',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (e, st) => const SizedBox.shrink(),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (e, st) => const SizedBox.shrink(),
    );
  }

  Widget _buildWeekOverview() {
    final now = DateTime.now();
    final weekStart = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));

    return ref
        .watch(
          weeklyMetricsProvider(
            WeeklyMetricsParams(
              employeeId: widget.employeeId,
              weekStartDate: weekStart,
            ),
          ),
        )
        .when(
          data: (metrics) {
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.05),
                border: Border.all(color: Colors.purple.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(_rSmall),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'This Week',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildMetricRow(
                    'Total Hours',
                    '${metrics.totalWorkHours.toStringAsFixed(1)}h',
                  ),
                  const SizedBox(height: 8),
                  _buildMetricRow(
                    'Overtime',
                    metrics.overtimeHours > 0
                        ? '+${metrics.overtimeHours.toStringAsFixed(1)}h'
                        : '0h',
                    color:
                        metrics.overtimeHours > 0 ? Colors.red : Colors.green,
                  ),
                  const SizedBox(height: 8),
                  _buildMetricRow(
                    'Weekends Worked',
                    '${metrics.weekendDaysWorked.length}',
                    color:
                        metrics.weekendDaysWorked.isNotEmpty
                            ? Colors.orange
                            : Colors.green,
                  ),
                ],
              ),
            );
          },
          loading: () => const CircularProgressIndicator(),
          error: (e, st) => Text('Error: $e'),
        );
  }

  Widget _buildMetricRow(String label, String value, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildAlerts() {
    return ref
        .watch(pendingFlagsForEmployeeProvider(widget.employeeId))
        .when(
          data: (flags) {
            if (flags.isEmpty) return const SizedBox.shrink();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Alerts',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                ...flags.map((flag) => _buildAlertItem(flag)).toList(),
              ],
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (e, st) => const SizedBox.shrink(),
        );
  }

  Widget _buildAlertItem(AttendanceFlag flag) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.05),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(_rSmall),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            flag.description,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.red[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleCheckInOut(bool isCheckedIn) async {
    setState(() => _isCheckingInOut = true);
    _clearError();

    try {
      final repo = ref.read(attendanceRepositoryProvider);

      if (isCheckedIn) {
        await repo.checkOut(widget.employeeId);
      } else {
        await repo.checkIn(widget.employeeId);
      }

      // Refresh current shift
      ref.refresh(currentShiftProvider(widget.employeeId));

      // Show success message
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isCheckedIn
                ? 'Checked out successfully'
                : 'Checked in successfully',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() => _errorMessage = 'Error: ${e.toString()}');
    } finally {
      setState(() => _isCheckingInOut = false);
    }
  }

  Future<DateTime?> _getTodayMetrics() {
    // OPEN ITEM: Implement day metrics calculation
    return Future.value(null);
  }

  void _clearError() {
    setState(() => _errorMessage = null);
  }
}

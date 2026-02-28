// ─────────────────────────────────────────────────────────────────────────────
// LIST VIEW  (renamed to _TaskListView to avoid conflict with Flutter's ListView)
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/core/models/member.dart';
import 'package:smooflow/core/models/project.dart';
import 'package:smooflow/core/models/task.dart';
import 'package:smooflow/providers/member_provider.dart';
import 'package:smooflow/screens/desktop/components/avatar_widget.dart';
import 'package:smooflow/screens/desktop/components/priority_pill.dart';
import 'package:smooflow/screens/desktop/components/stage_pill.dart';
import 'package:smooflow/screens/desktop/helpers/dashboard_helpers.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DESIGN TOKENS
// ─────────────────────────────────────────────────────────────────────────────
class _T {
  // Brand
  static const blue       = Color(0xFF2563EB);
  static const blueHover  = Color(0xFF1D4ED8);
  static const blue100    = Color(0xFFDBEAFE);
  static const blue50     = Color(0xFFEFF6FF);
  static const teal       = Color(0xFF38BDF8);

  // Semantic
  static const green      = Color(0xFF10B981);
  static const green50    = Color(0xFFECFDF5);
  static const amber      = Color(0xFFF59E0B);
  static const amber50    = Color(0xFFFEF3C7);
  static const red        = Color(0xFFEF4444);
  static const red50      = Color(0xFFFEE2E2);
  static const purple     = Color(0xFF8B5CF6);
  static const purple50   = Color(0xFFF3E8FF);

  // Neutrals
  static const slate50    = Color(0xFFF8FAFC);
  static const slate100   = Color(0xFFF1F5F9);
  static const slate200   = Color(0xFFE2E8F0);
  static const slate300   = Color(0xFFCBD5E1);
  static const slate400   = Color(0xFF94A3B8);
  static const slate500   = Color(0xFF64748B);
  static const ink        = Color(0xFF0F172A);
  static const ink2       = Color(0xFF1E293B);
  static const ink3       = Color(0xFF334155);
  static const white      = Colors.white;

  // Dimensions
  static const sidebarW  = 220.0;
  static const topbarH   = 52.0;
  static const detailW   = 400.0;

  // Radius
  static const r   = 8.0;
  static const rLg = 12.0;
  static const rXl = 16.0;
}

class TaskListView extends ConsumerWidget {
  late final List<Task> tasks;
  final List<Project> projects;
  final int? selectedTaskId;
  final ValueChanged<int> onTaskSelected;

  TaskListView({required final List<Task> tasks, required this.projects, required this.selectedTaskId, required this.onTaskSelected})
    : this.tasks = tasks.reversed.toList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: _T.slate50,
      child: Column(
        children: [
          // Table header
          Container(
            color: _T.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: const Row(
              children: [
                Expanded(flex: 3, child: _TableHeader('Task')),
                Expanded(flex: 2, child: _TableHeader('Project')),
                Expanded(flex: 2, child: _TableHeader('Stage')),
                // Expanded(flex: 2, child: _TableHeader('Assignee')),
                Expanded(flex: 1, child: _TableHeader('Date')),
                Expanded(flex: 1, child: _TableHeader('Priority')),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: _T.slate200),
          // Rows
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              itemCount: tasks.length,
              separatorBuilder: (_, __) => const Divider(height: 1, thickness: 1, color: _T.slate100),
              itemBuilder: (_, i) {
                final t = tasks[i];
                final p = projects.cast<Project?>().firstWhere((pr) => pr!.id == t.projectId, orElse: () => null) ?? projects.first;

                Member? m;
                try {
                  m = ref.watch(memberNotifierProvider).members.firstWhere((mem) => t.assignees.contains(mem.id));
                } catch (_) {
                  m = null;
                }

                final s = stageInfo(t.status);
                final d = t.createdAt;
                final now = DateTime.now();
                // final isOverdue = d != null && d.isBefore(now);
                // final isSoon    = d != null && !isOverdue && d.difference(now).inDays <= 3;

                final dateFormatted = fmtDate(d);

                final dateSplitted = dateFormatted.split(" ");
                dateSplitted.removeLast();

                return Material(
                  color: selectedTaskId == t.id ? _T.blue50 : _T.white,
                  borderRadius: BorderRadius.circular(_T.r),
                  child: InkWell(
                    onTap: () => onTaskSelected(t.id),
                    borderRadius: BorderRadius.circular(_T.r),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          // Task name + description
                          Expanded(flex: 3, child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(t.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _T.ink)),
                              if (t.description != null && t.description!.isNotEmpty)
                                Text(
                                  t.description!.length > 55 ? '${t.description!.substring(0, 55)}…' : t.description!,
                                  style: const TextStyle(fontSize: 11.5, color: _T.slate400),
                                ),
                            ]),
                          )),
                          // Project
                          Expanded(flex: 2, child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Row(children: [
                              Container(width: 7, height: 7, decoration: BoxDecoration(color: p.color, shape: BoxShape.circle)),
                              const SizedBox(width: 6),
                              Expanded(child: Text(p.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, color: _T.slate500))),
                            ]),
                          )),
                          // Stage
                          Expanded(flex: 2, child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: StagePill(stageInfo: s),
                          )),
                          // Assignee — always occupies its flex slot
                          // Expanded(flex: 2, child: Padding(
                          //   padding: const EdgeInsets.symmetric(horizontal: 4),
                          //   child: m != null
                          //       ? Row(children: [
                          //           AvatarWidget(initials: m.initials, color: m.color, size: 22),
                          //           const SizedBox(width: 7),
                          //           Expanded(child: Text(m.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, color: _T.slate500))),
                          //         ])
                          //       : const Text('—', style: TextStyle(color: _T.slate400)),
                          // )),
                          // Created date
                          Expanded(flex: 1, child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              d.year == now.year? dateSplitted.join(" ") : dateFormatted,
                              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w400, color: _T.slate500),
                            ),
                          )),
                          // Due date
                          // Expanded(flex: 1, child: Padding(
                          //   padding: const EdgeInsets.symmetric(horizontal: 4),
                          //   child: Text(
                          //     dueDate != null ? fmtDate(d) : '—',
                          //     style: TextStyle(fontSize: 12.5, fontWeight: isOverdue || isSoon ? FontWeight.w600 : FontWeight.w400, color: isOverdue ? _T.red : isSoon ? _T.amber : _T.slate500),
                          //   ),
                          // )),
                          // Priority
                          Expanded(flex: 1, child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: PriorityPill(priority: t.priority),
                          )),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  final String text;
  const _TableHeader(this.text);
  @override
  Widget build(BuildContext context) => Text(text, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 0.7, color: _T.slate400));
}
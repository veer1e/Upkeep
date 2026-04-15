import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/task_card.dart';

class TasksScreen extends StatelessWidget {
  final void Function(String taskId) onTaskDetails;

  const TasksScreen({super.key, required this.onTaskDetails});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final tasks = provider.tasks;
    final overdue = provider.overdueTasks;
    final dueToday = provider.dueTodayTasks;
    final upcoming = provider.upcomingTasks;
    final allSorted = [...overdue, ...dueToday, ...upcoming];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? const Color(0xFFF9FAFB) : AppTheme.textPrimary;
    final mutedColor = isDark ? const Color(0xFF9CA3AF) : AppTheme.textTertiary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Row(
            children: [
              Text(
                'All Tasks',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                  color: titleColor,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  '${tasks.length} task${tasks.length != 1 ? 's' : ''}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: AppTheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        if (tasks.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Row(
              children: [
                if (overdue.isNotEmpty)
                  _StatChip(
                    count: overdue.length,
                    label: 'Overdue',
                    bg: AppTheme.overdueRedBg,
                    textColor: AppTheme.overdueRed,
                  ),
                if (overdue.isNotEmpty) const SizedBox(width: 8),
                if (dueToday.isNotEmpty)
                  _StatChip(
                    count: dueToday.length,
                    label: 'Today',
                    bg: AppTheme.dueTodayOrangeBg,
                    textColor: AppTheme.dueTodayOrange,
                  ),
                if (dueToday.isNotEmpty) const SizedBox(width: 8),
                if (upcoming.isNotEmpty)
                  _StatChip(
                    count: upcoming.length,
                    label: 'Upcoming',
                    bg: AppTheme.upcomingBlueBg,
                    textColor: AppTheme.upcomingBlue,
                  ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        Expanded(
          child: tasks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🌟', style: TextStyle(fontSize: 48)),
                      const SizedBox(height: 16),
                      Text(
                        'No tasks yet',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: titleColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap + to add your first task',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          color: mutedColor,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 112),
                  itemCount: allSorted.length,
                  itemBuilder: (ctx, i) {
                    final task = allSorted[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TaskCard(
                        key: ValueKey(task.id),
                        task: task,
                        onDetails: () => onTaskDetails(task.id),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final int count;
  final String label;
  final Color bg;
  final Color textColor;

  const _StatChip({
    required this.count,
    required this.label,
    required this.bg,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? bg.withValues(alpha: 0.25) : bg,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        '$count $label',
        style: TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w700,
          fontSize: 11,
          color: textColor,
        ),
      ),
    );
  }
}

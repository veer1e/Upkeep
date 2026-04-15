import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatelessWidget {
  final void Function(String taskId) onTaskDetails;

  const HomeScreen({super.key, required this.onTaskDetails});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String _dayName() {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[DateTime.now().weekday - 1];
  }

  String _dateFmt() {
    final now = DateTime.now();
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[now.month - 1]} ${now.day}';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final tasks = provider.tasks;
    final overdue = provider.overdueTasks;
    final dueToday = provider.dueTodayTasks;
    final upcoming = provider.upcomingTasks;
    final completions = tasks.fold<int>(0, (sum, t) => sum + t.history.length);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? const Color(0xFFF9FAFB) : AppTheme.textPrimary;
    final mutedColor = isDark ? const Color(0xFF9CA3AF) : AppTheme.textTertiary;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_dayName()}, ${_dateFmt()}',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: mutedColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_greeting()} 👋',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w800,
                      fontSize: 24,
                      color: titleColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF111827) : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color:
                      isDark ? const Color(0xFF1F2937) : AppTheme.borderLight,
                ),
              ),
              child: Icon(
                Icons.notifications_none_rounded,
                size: 20,
                color: mutedColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'Overview',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
            fontSize: 12,
            color: mutedColor,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                emoji: '📋',
                value: '${tasks.length}',
                label: 'Total Tasks',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatCard(
                emoji: '✅',
                value: '$completions',
                label: 'Completions',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                emoji: '🎯',
                value: '${dueToday.length}',
                label: 'Today',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatCard(
                emoji: '🔴',
                value: '${overdue.length}',
                label: 'Overdue',
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (tasks.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 48),
            child: Column(
              children: [
                const Text('🌟', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 16),
                Text(
                  'All clear!',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'No maintenance tasks yet. Go to Tasks and tap + to add one',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: mutedColor,
                  ),
                ),
              ],
            ),
          ),
        if (tasks.isNotEmpty) ...[
          _PreviewSection(
            title: 'Overdue',
            tasks: overdue.take(4).toList(),
            onTaskDetails: onTaskDetails,
          ),
          const SizedBox(height: 12),
          _PreviewSection(
            title: 'Due Today',
            tasks: dueToday.take(4).toList(),
            onTaskDetails: onTaskDetails,
          ),
          const SizedBox(height: 12),
          _PreviewSection(
            title: 'Upcoming',
            tasks: upcoming.take(4).toList(),
            onTaskDetails: onTaskDetails,
          ),
        ],
      ],
    );
  }
}

class _PreviewSection extends StatelessWidget {
  final String title;
  final List<Task> tasks;
  final void Function(String taskId) onTaskDetails;

  const _PreviewSection({
    required this.title,
    required this.tasks,
    required this.onTaskDetails,
  });

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? const Color(0xFFF9FAFB) : AppTheme.textPrimary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: titleColor,
          ),
        ),
        const SizedBox(height: 8),
        ...tasks.map(
          (task) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _TaskPreviewRow(
              task: task,
              onTap: () => onTaskDetails(task.id),
            ),
          ),
        ),
      ],
    );
  }
}

class _TaskPreviewRow extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;

  const _TaskPreviewRow({required this.task, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? const Color(0xFFF9FAFB) : AppTheme.textPrimary;
    final mutedColor = isDark ? const Color(0xFF9CA3AF) : AppTheme.textTertiary;
    final status = getTaskStatus(task.nextDue);
    final days = getDaysUntilDue(task.nextDue);
    final label = statusLabel(status, days);

    Color badgeBg;
    Color badgeText;
    switch (status) {
      case TaskStatus.overdue:
        badgeBg = AppTheme.overdueRedBadge;
        badgeText = AppTheme.overdueRed;
        break;
      case TaskStatus.dueToday:
        badgeBg = AppTheme.dueTodayOrangeBadge;
        badgeText = AppTheme.dueTodayOrange;
        break;
      case TaskStatus.upcoming:
        badgeBg = AppTheme.upcomingBlueBg;
        badgeText = AppTheme.upcomingBlue;
        break;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0B1220) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? const Color(0xFF253041) : AppTheme.borderLight,
          ),
        ),
        child: Row(
          children: [
            Text(task.emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                task.name,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: titleColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: badgeBg,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  color: badgeText,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded, size: 18, color: mutedColor),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;

  const _StatCard({
    required this.emoji,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF1F2937) : AppTheme.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w800,
              fontSize: 24,
              color: isDark ? const Color(0xFFF9FAFB) : AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: isDark ? const Color(0xFF9CA3AF) : AppTheme.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

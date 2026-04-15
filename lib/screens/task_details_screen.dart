import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/completion_sheet.dart';

class TaskDetailsScreen extends StatelessWidget {
  final String taskId;
  final VoidCallback onBack;

  const TaskDetailsScreen({
    super.key,
    required this.taskId,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final task = provider.tasks.cast<Task?>().firstWhere(
          (t) => t?.id == taskId,
          orElse: () => null,
        );

    if (task == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => onBack());
      return const SizedBox.shrink();
    }

    final status = getTaskStatus(task.nextDue);
    final days = getDaysUntilDue(task.nextDue);
    final label = statusLabel(status, days);
    final sortedHistory = [...task.history].reversed.toList();

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

    return Column(
      children: [
        // Header card
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back + delete row
                Row(
                  children: [
                    GestureDetector(
                      onTap: onBack,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppTheme.background,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          size: 20,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => _confirmDelete(context, task),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppTheme.overdueRedBg,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                          color: AppTheme.overdueRed,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Task hero
                Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppTheme.background,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.borderLight),
                      ),
                      child: Center(
                        child: Text(
                          task.emoji,
                          style: const TextStyle(fontSize: 32),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.name,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w800,
                            fontSize: 22,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: badgeBg,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            label,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              color: badgeText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Done CTA
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      showCompletionSheet(context, task);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 6,
                      shadowColor: AppTheme.primaryShadow.withOpacity(0.5),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_rounded, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Mark as Done',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Body
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            children: [
              // Quick stats grid
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.access_time_rounded,
                      label: 'Last done',
                      value: formatLastDone(task.lastDone),
                      sub: formatDate(task.lastDone),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.calendar_today_rounded,
                      label: 'Next due',
                      value: formatDate(task.nextDue),
                      sub: days == 0
                          ? 'Today!'
                          : days < 0
                              ? '${days.abs()}d ago'
                              : 'In $days days',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Pattern insight
              if (task.patternInsight != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFC7D2FE)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0E7FF),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.trending_up_rounded,
                          size: 20,
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Pattern Insight',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              color: Color(0xFF818CF8),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            task.patternInsight!,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: Color(0xFF3730A3),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

              // Task meta
              _MetaCard(task: task),
              const SizedBox(height: 12),

              // History
              _HistoryCard(history: sortedHistory),
            ],
          ),
        ),
      ],
    );
  }

  void _confirmDelete(BuildContext context, Task task) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Delete Task',
          style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Delete "${task.name}"? This cannot be undone.',
          style: const TextStyle(fontFamily: 'Inter'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<AppProvider>().deleteTask(task.id);
              Navigator.pop(ctx);
              onBack();
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppTheme.overdueRed),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String sub;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppTheme.textTertiary),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: AppTheme.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: AppTheme.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaCard extends StatelessWidget {
  final Task task;

  const _MetaCard({required this.task});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        children: [
          _MetaRow(
            icon: Icons.repeat_rounded,
            label: 'Schedule type',
            value: task.type.label,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: AppTheme.borderLight),
          ),
          _MetaRow(
            icon: Icons.access_time_rounded,
            label: 'Interval',
            value: 'Every ${task.intervalDays} days',
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: AppTheme.borderLight),
          ),
          _MetaRow(
            icon: Icons.label_outline_rounded,
            label: 'Category',
            value: '${task.category.emoji} ${task.category.label}',
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MetaRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.textSecondary),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            color: AppTheme.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final List<String> history;

  const _HistoryCard({required this.history});

  @override
  Widget build(BuildContext context) {
    final visible = history.take(10).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Completion History',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  '${history.length} times',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: AppTheme.textTertiary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...visible.asMap().entries.map((entry) {
            final i = entry.key;
            final date = entry.value;
            final isFirst = i == 0;
            final isLast = i == visible.length - 1;

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 20,
                    child: Column(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: isFirst ? AppTheme.primary : AppTheme.borderMedium,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                            boxShadow: isFirst
                                ? [
                                    BoxShadow(
                                      color: AppTheme.primaryShadow.withOpacity(0.4),
                                      blurRadius: 4,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                        if (!isLast)
                          Expanded(
                            child: Container(
                              width: 1,
                              color: AppTheme.borderLight,
                              margin: const EdgeInsets.symmetric(vertical: 2),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      children: [
                        Text(
                          formatDate(date),
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: isFirst ? FontWeight.w700 : FontWeight.w400,
                            fontSize: 14,
                            color: isFirst
                                ? AppTheme.textPrimary
                                : AppTheme.textSecondary,
                          ),
                        ),
                        if (isFirst) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryLight,
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: const Text(
                              'Latest',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w600,
                                fontSize: 10,
                                color: AppTheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

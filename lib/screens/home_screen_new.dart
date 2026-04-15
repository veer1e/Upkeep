import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/task_card.dart';

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
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday',
    ];
    return days[DateTime.now().weekday - 1];
  }

  String _dateFmt() {
    final now = DateTime.now();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
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

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 112),
      children: [
        // Header
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_dayName()}, ${_dateFmt()}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: AppTheme.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_greeting()} 👋',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w800,
                      fontSize: 24,
                      color: AppTheme.textPrimary,
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
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.borderLight),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                size: 20,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Stats Cards (from Settings)
        const Text(
          'Overview',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
            fontSize: 12,
            color: AppTheme.textTertiary,
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

        // Urgent Action Required (if overdue)
        if (overdue.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.overdueRedBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('⚠️', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Action Required!',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: AppTheme.overdueRed,
                            ),
                          ),
                          Text(
                            '${overdue.length} task${overdue.length > 1 ? 's' : ''} overdue',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              color: AppTheme.overdueRed,
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
          const SizedBox(height: 16),
        ],

        // Overdue Tasks (limited to 3, with link to all)
        if (overdue.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Overdue',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AppTheme.textPrimary,
                ),
              ),
              if (overdue.length > 3)
                Text(
                  'View all (${overdue.length})',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppTheme.primary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ...overdue.take(3).map((task) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TaskCard(
                  task: task,
                  onDetails: () => onTaskDetails(task.id),
                ),
              )),
          const SizedBox(height: 8),
        ],

        // Today's Tasks
        if (dueToday.isNotEmpty) ...[
          const Text(
            'Due Today',
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...dueToday.map((task) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TaskCard(
                  task: task,
                  onDetails: () => onTaskDetails(task.id),
                ),
              )),
          const SizedBox(height: 8),
        ],

        // Upcoming (just count)
        if (upcoming.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.upcomingBlueBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Text('📅', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Upcoming',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: AppTheme.textTertiary,
                      ),
                    ),
                    Text(
                      '${upcoming.length} task${upcoming.length > 1 ? 's' : ''} in next 30 days',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppTheme.upcomingBlue,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

        // Empty state
        if (tasks.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 64),
            child: Column(
              children: const [
                Text('🌟', style: TextStyle(fontSize: 48)),
                SizedBox(height: 16),
                Text(
                  'All clear!',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: AppTheme.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'No maintenance tasks yet. Tap + to add your first one',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: AppTheme.textTertiary,
                  ),
                ),
              ],
            ),
          ),
      ],
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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w800,
              fontSize: 24,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppTheme.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

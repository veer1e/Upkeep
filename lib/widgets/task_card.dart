import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/task.dart';
import '../theme/app_theme.dart';
import 'completion_sheet.dart';

class _StatusConfig {
  final Color cardBg;
  final Color cardBorder;
  final Color badgeBg;
  final Color badgeText;
  final Color doneBtn;
  final Color doneBtnShadow;

  const _StatusConfig({
    required this.cardBg,
    required this.cardBorder,
    required this.badgeBg,
    required this.badgeText,
    required this.doneBtn,
    required this.doneBtnShadow,
  });
}

_StatusConfig _configForStatus(TaskStatus status) {
  switch (status) {
    case TaskStatus.overdue:
      return const _StatusConfig(
        cardBg: AppTheme.overdueRedBg,
        cardBorder: AppTheme.overdueRedBorder,
        badgeBg: AppTheme.overdueRedBadge,
        badgeText: AppTheme.overdueRed,
        doneBtn: AppTheme.overdueRed,
        doneBtnShadow: Color(0xFFFCA5A5),
      );
    case TaskStatus.dueToday:
      return const _StatusConfig(
        cardBg: AppTheme.dueTodayOrangeBg,
        cardBorder: AppTheme.dueTodayOrangeBorder,
        badgeBg: AppTheme.dueTodayOrangeBadge,
        badgeText: AppTheme.dueTodayOrange,
        doneBtn: AppTheme.dueTodayOrange,
        doneBtnShadow: Color(0xFFFDBA74),
      );
    case TaskStatus.upcoming:
      return const _StatusConfig(
        cardBg: Colors.white,
        cardBorder: AppTheme.borderLight,
        badgeBg: AppTheme.upcomingBlueBg,
        badgeText: AppTheme.upcomingBlue,
        doneBtn: AppTheme.primary,
        doneBtnShadow: AppTheme.primaryShadow,
      );
  }
}

class TaskCard extends StatefulWidget {
  final Task task;
  final VoidCallback onDetails;

  const TaskCard({
    super.key,
    required this.task,
    required this.onDetails,
  });

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 120),
      vsync: this,
      lowerBound: 0.97,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = getTaskStatus(widget.task.nextDue);
    final days = getDaysUntilDue(widget.task.nextDue);
    final cfg = _configForStatus(status);
    final label = statusLabel(status, days);

    return Container(
      decoration: BoxDecoration(
        color: cfg.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cfg.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Emoji icon
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                widget.task.emoji,
                style: const TextStyle(fontSize: 26),
              ),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.task.name,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: AppTheme.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: cfg.badgeBg,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          label,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                            color: cfg.badgeText,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Last done row
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time_rounded,
                        size: 12,
                        color: AppTheme.textTertiary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Last: ${formatLastDone(widget.task.lastDone)}',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: AppTheme.textTertiary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        '·',
                        style: TextStyle(color: AppTheme.borderMedium),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Every ${widget.task.intervalDays}d',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: AppTheme.textTertiary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: _DoneButton(
                          cfg: cfg,
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            showCompletionSheet(context, widget.task);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      _DetailsButton(onTap: widget.onDetails),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DoneButton extends StatefulWidget {
  final _StatusConfig cfg;
  final VoidCallback onTap;

  const _DoneButton({required this.cfg, required this.onTap});

  @override
  State<_DoneButton> createState() => _DoneButtonState();
}

class _DoneButtonState extends State<_DoneButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.97,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.reverse(),
      onTapUp: (_) {
        _ctrl.forward();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.forward(),
      child: ScaleTransition(
        scale: _ctrl,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: widget.cfg.doneBtn,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: widget.cfg.doneBtnShadow.withOpacity(0.5),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '✓ Done',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailsButton extends StatefulWidget {
  final VoidCallback onTap;

  const _DetailsButton({required this.onTap});

  @override
  State<_DetailsButton> createState() => _DetailsButtonState();
}

class _DetailsButtonState extends State<_DetailsButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.97,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.reverse(),
      onTapUp: (_) {
        _ctrl.forward();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.forward(),
      child: ScaleTransition(
        scale: _ctrl,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.borderMedium),
          ),
          child: const Row(
            children: [
              Text(
                'Details',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
              SizedBox(width: 2),
              Icon(
                Icons.chevron_right_rounded,
                size: 14,
                color: AppTheme.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

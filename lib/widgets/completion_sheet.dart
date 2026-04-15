import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

const _dayOptions = [
  (label: 'Today', value: 0),
  (label: 'Yesterday', value: 1),
  (label: '2 days ago', value: 2),
  (label: '3 days ago', value: 3),
  (label: '1 week ago', value: 7),
  (label: '2 weeks ago', value: 14),
  (label: '1 month ago', value: 30),
];

class CompletionSheet extends StatefulWidget {
  final Task task;

  const CompletionSheet({super.key, required this.task});

  @override
  State<CompletionSheet> createState() => _CompletionSheetState();
}

class _CompletionSheetState extends State<CompletionSheet> {
  int _daysAgo = 0;
  bool _useCustomDate = false;
  late DateTime _selectedDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  String get _formattedDate {
    return '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
  }

  String get _daysAgoLabel {
    final diff = DateTime.now().difference(_selectedDate).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff == 7) return '1 week ago';
    if (diff == 14) return '2 weeks ago';
    if (diff == 30) return '1 month ago';
    return '$diff days ago';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.borderMedium,
              borderRadius: BorderRadius.circular(100),
            ),
          ),
          const SizedBox(height: 24),

          // Close + task info row
          Row(
            children: [
              Text(
                widget.task.emoji,
                style: const TextStyle(fontSize: 36),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.task.name,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const Text(
                      'When did you do this?',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: AppTheme.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Preset options
          if (!_useCustomDate)
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 2.8,
              children: _dayOptions.map((opt) {
                final isSelected = _daysAgo == opt.value && !_useCustomDate;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _daysAgo = opt.value;
                      _useCustomDate = false;
                      _selectedDate =
                          DateTime.now().subtract(Duration(days: opt.value));
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      color:
                          isSelected ? AppTheme.primary : AppTheme.background,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppTheme.primaryShadow.withOpacity(0.5),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        opt.label,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: isSelected
                              ? Colors.white
                              : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

          // Custom date option
          const SizedBox(height: 16),
          if (_useCustomDate)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderMedium),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selected Date: $_formattedDate',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '($_daysAgoLabel)',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppTheme.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedDate = picked);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.background,
                        foregroundColor: AppTheme.textSecondary,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.calendar_today_rounded, size: 18),
                          SizedBox(width: 8),
                          Text('Change Date'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // Toggle custom date
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: ElevatedButton(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _useCustomDate = false);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: !_useCustomDate
                          ? AppTheme.primary
                          : AppTheme.background,
                      foregroundColor: !_useCustomDate
                          ? Colors.white
                          : AppTheme.textSecondary,
                    ),
                    child: const Text('Preset'),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: ElevatedButton(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _useCustomDate = true);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _useCustomDate
                          ? AppTheme.primary
                          : AppTheme.background,
                      foregroundColor: _useCustomDate
                          ? Colors.white
                          : AppTheme.textSecondary,
                    ),
                    child: const Text('Custom Date'),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // CTA button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () async {
                      HapticFeedback.mediumImpact();
                      setState(() => _isLoading = true);

                      try {
                        final provider = context.read<AppProvider>();
                        final daysAgo =
                            DateTime.now().difference(_selectedDate).inDays;

                        // Complete the task
                        await provider.completeTask(widget.task.id, daysAgo);

                        if (context.mounted) {
                          _showSuccessSnack(context);
                          Navigator.pop(context, true);
                        }
                      } catch (e) {
                        setState(() => _isLoading = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e')),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 6,
                shadowColor: AppTheme.primaryShadow.withOpacity(0.6),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.check_rounded,
                            color: Colors.white, size: 20),
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
    );
  }

  void _showSuccessSnack(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.task.emoji} ${widget.task.name}',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            Text(
              'Marked as done on $_formattedDate ($_daysAgoLabel)',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }
}

/// Call this to show the completion sheet as a modal bottom sheet
Future<void> showCompletionSheet(BuildContext context, Task task) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => ChangeNotifierProvider.value(
      value: context.read<AppProvider>(),
      child: CompletionSheet(task: task),
    ),
  );
}

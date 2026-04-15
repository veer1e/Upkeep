import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

const _emojis = [
  '✂️',
  '🛏️',
  '🔧',
  '🧹',
  '🌱',
  '🍳',
  '💊',
  '🏃',
  '📚',
  '🐕',
  '🚿',
  '🧴',
  '🛁',
  '🚙',
  '🏋️',
  '🧽',
];

const _intervalPresets = [3, 7, 14, 21, 28, 30, 60, 90, 180, 365];
const _stepLabels = ['Task', 'Schedule', 'Finish'];
const _categoryEmojiChoices = [
  '🏷️',
  '🧠',
  '💼',
  '🧾',
  '🎓',
  '🛒',
  '🍽️',
  '🎯',
  '📦',
  '🎨',
  '🧳',
  '🧑‍💻',
];

const _lastDoneOptions = [
  (label: 'Today', value: 0),
  (label: 'Yesterday', value: 1),
  (label: '2 days ago', value: 2),
  (label: '1 week ago', value: 7),
  (label: '2 weeks ago', value: 14),
  (label: '1 month ago', value: 30),
];

const _templates = [
  (emoji: '✂️', name: 'Haircut', category: TaskCategory.personal, interval: 28),
  (
    emoji: '🛏️',
    name: 'Wash Bedsheets',
    category: TaskCategory.home,
    interval: 14
  ),
  (emoji: '🔧', name: 'Oil Change', category: TaskCategory.car, interval: 90),
  (emoji: '🌱', name: 'Water Plants', category: TaskCategory.home, interval: 3),
];

class AddTaskScreen extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onDone;

  const AddTaskScreen({super.key, required this.onBack, required this.onDone});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  int _step = 1;
  String _name = '';
  String _emoji = '✂️';
  TaskCategory _category = TaskCategory.personal;
  TaskType _taskType = TaskType.fixed;
  int _intervalDays = 14;
  int _lastDoneOffset = 0;
  bool _isSubmitting = false;
  CustomCategory? _selectedCustomCategory;

  final _nameController = TextEditingController();
  final _nameFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _nameFocus.requestFocus());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  String get _previewDate {
    final d = DateTime.now().subtract(Duration(days: _lastDoneOffset));
    final lastStr =
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    return addDaysToDate(lastStr, _intervalDays);
  }

  bool _isDuplicateName(List<Task> tasks) {
    final normalized = _name.trim().toLowerCase();
    if (normalized.isEmpty) return false;
    return tasks.any((t) => t.name.trim().toLowerCase() == normalized);
  }

  void _applyTemplate(
      ({
        String emoji,
        String name,
        TaskCategory category,
        int interval,
      }) template) {
    _nameController.text = template.name;
    setState(() {
      _emoji = template.emoji;
      _name = template.name;
      _category = template.category;
      _selectedCustomCategory = null;
      _intervalDays = template.interval;
      _taskType = TaskType.fixed;
    });
  }

  void _goNext() {
    if (_step < 3) setState(() => _step += 1);
  }

  void _goBack() {
    if (_step > 1) {
      setState(() => _step -= 1);
    } else {
      widget.onBack();
    }
  }

  Future<void> _submit({
    required AppProvider provider,
    required bool addAnother,
  }) async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    final d = DateTime.now().subtract(Duration(days: _lastDoneOffset));
    final lastDoneStr =
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    final nextDue = addDaysToDate(lastDoneStr, _intervalDays);

    final task = Task(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: _name.trim(),
      emoji: _emoji,
      category: _category,
      type: _taskType,
      intervalDays: _intervalDays,
      lastDone: lastDoneStr,
      nextDue: nextDue,
      history: [lastDoneStr],
      customCategoryLabel: _selectedCustomCategory?.label,
      customCategoryEmoji: _selectedCustomCategory?.emoji,
      patternInsight:
          _taskType == TaskType.fixed ? 'Every $_intervalDays days' : null,
    );

    try {
      await provider.addTask(task);
      if (!mounted) return;

      if (addAnother) {
        _nameController.clear();
        setState(() {
          _step = 1;
          _name = '';
          _emoji = '✂️';
          _category = TaskCategory.personal;
          _taskType = TaskType.fixed;
          _intervalDays = 14;
          _lastDoneOffset = 0;
          _selectedCustomCategory = null;
          _isSubmitting = false;
        });
        WidgetsBinding.instance
            .addPostFrameCallback((_) => _nameFocus.requestFocus());
        return;
      }

      widget.onDone();
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not add task. Please try again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _createCustomCategory(AppProvider provider) async {
    final nameController = TextEditingController();
    String selectedEmoji = '🏷️';
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('New Category'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(hintText: 'Category name'),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categoryEmojiChoices.map((emoji) {
                  final selected = selectedEmoji == emoji;
                  return GestureDetector(
                    onTap: () => setDialogState(() => selectedEmoji = emoji),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: selected
                            ? AppTheme.primaryLight
                            : Colors.transparent,
                        border: Border.all(
                          color: selected
                              ? AppTheme.primary
                              : AppTheme.borderMedium,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(emoji),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Save')),
          ],
        ),
      ),
    );
    if (result != true) return;

    final label = nameController.text.trim();
    if (label.isEmpty) return;
    await provider.addCustomCategory(label: label, emoji: selectedEmoji);
    if (!mounted) return;
    final added = provider.customCategories.firstWhere(
      (c) => c.label.toLowerCase() == label.toLowerCase(),
      orElse: () => provider.customCategories.last,
    );
    setState(() {
      _selectedCustomCategory = added;
      _category = TaskCategory.personal;
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final tasks = provider.tasks;
    final duplicateName = _isDuplicateName(tasks);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF0F172A) : Colors.white;
    final panel = isDark ? const Color(0xFF111827) : AppTheme.background;
    final text = isDark ? const Color(0xFFF9FAFB) : AppTheme.textPrimary;
    final muted = isDark ? const Color(0xFF9CA3AF) : AppTheme.textTertiary;
    final canContinue =
        _step == 1 ? _name.trim().isNotEmpty && !duplicateName : true;

    return Column(
      children: [
        Container(
          color: surface,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: _goBack,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration:
                            BoxDecoration(color: panel, shape: BoxShape.circle),
                        child: Icon(Icons.arrow_back_rounded,
                            color: text, size: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'New Task',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          color: text,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _StepProgress(step: _step, labels: _stepLabels, isDark: isDark),
              ],
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _step == 1
                  ? _Step1(
                      key: const ValueKey(1),
                      isDark: isDark,
                      emoji: _emoji,
                      category: _category,
                      selectedCustomCategory: _selectedCustomCategory,
                      customCategories: provider.customCategories,
                      duplicateName: duplicateName,
                      nameController: _nameController,
                      nameFocus: _nameFocus,
                      onEmojiChanged: (e) => setState(() => _emoji = e),
                      onNameChanged: (v) => setState(() => _name = v),
                      onCategoryChanged: (c) => setState(() {
                        _category = c;
                        _selectedCustomCategory = null;
                      }),
                      onCustomCategoryChanged: (c) =>
                          setState(() => _selectedCustomCategory = c),
                      onAddCustomCategory: () =>
                          _createCustomCategory(provider),
                      onTemplateTap: _applyTemplate,
                    )
                  : _step == 2
                      ? _Step2(
                          key: const ValueKey(2),
                          isDark: isDark,
                          taskType: _taskType,
                          onTypeChanged: (t) => setState(() => _taskType = t),
                        )
                      : _Step3(
                          key: const ValueKey(3),
                          isDark: isDark,
                          emoji: _emoji,
                          intervalDays: _intervalDays,
                          lastDoneOffset: _lastDoneOffset,
                          previewDate: _previewDate,
                          reminderHour: provider.notificationHour,
                          reminderMinute: provider.notificationMinute,
                          onIntervalChanged: (v) =>
                              setState(() => _intervalDays = v),
                          onLastDoneChanged: (v) =>
                              setState(() => _lastDoneOffset = v),
                        ),
            ),
          ),
        ),
        Container(
          color: surface,
          padding: EdgeInsets.fromLTRB(
              20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _step < 3
                      ? (canContinue ? _goNext : null)
                      : (_isSubmitting
                          ? null
                          : () =>
                              _submit(provider: provider, addAnother: false)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shadowColor: AppTheme.primaryShadow.withOpacity(0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _step < 3
                      ? const Text('Continue')
                      : _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Add Task'),
                ),
              ),
              if (_step == 3) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => _submit(provider: provider, addAnother: true),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark
                          ? const Color(0xFFF9FAFB)
                          : AppTheme.textPrimary,
                      side: BorderSide(
                        color: isDark
                            ? const Color(0xFF374151)
                            : AppTheme.borderMedium,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Save and Add Another'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _StepProgress extends StatelessWidget {
  final int step;
  final List<String> labels;
  final bool isDark;

  const _StepProgress({
    required this.step,
    required this.labels,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final muted = isDark ? const Color(0xFF9CA3AF) : AppTheme.textTertiary;
    final topRowChildren = <Widget>[];
    
    for (var i = 0; i < labels.length; i++) {
      final isActive = i + 1 == step;
      final isDone = i + 1 < step;
      
      // Circle
      topRowChildren.add(
        SizedBox(
          width: 28,
          height: 28,
          child: Container(
            decoration: BoxDecoration(
              color: isDone || isActive
                  ? AppTheme.primary
                  : AppTheme.borderMedium,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: isDone
                ? const Icon(Icons.check_rounded,
                    size: 16, color: Colors.white)
                : Text(
                    '${i + 1}',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: isActive ? Colors.white : muted,
                    ),
                  ),
          ),
        ),
      );
      
      // Connector line (if not last)
      if (i < labels.length - 1) {
        topRowChildren.add(
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Container(
                height: 2,
                color: isDone ? AppTheme.primary : AppTheme.borderMedium,
              ),
            ),
          ),
        );
      }
    }

    // Label row - centered below each circle
    final labelWidgets = List.generate(labels.length, (idx) {
      final isActive = idx + 1 == step;
      return Expanded(
        child: Column(
          children: [
            const SizedBox(height: 8),
            Text(
              labels[idx],
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: isActive ? AppTheme.primary : muted,
              ),
            ),
          ],
        ),
      );
    });

    return Column(
      children: [
        Row(children: topRowChildren),
        Row(children: labelWidgets),
      ],
    );
  }
}

class _Step1 extends StatelessWidget {
  final bool isDark;
  final String emoji;
  final TaskCategory category;
  final CustomCategory? selectedCustomCategory;
  final List<CustomCategory> customCategories;
  final bool duplicateName;
  final TextEditingController nameController;
  final FocusNode nameFocus;
  final void Function(String) onEmojiChanged;
  final void Function(String) onNameChanged;
  final void Function(TaskCategory) onCategoryChanged;
  final void Function(CustomCategory) onCustomCategoryChanged;
  final VoidCallback onAddCustomCategory;
  final void Function(
      ({
        String emoji,
        String name,
        TaskCategory category,
        int interval,
      })) onTemplateTap;

  const _Step1({
    super.key,
    required this.isDark,
    required this.emoji,
    required this.category,
    required this.selectedCustomCategory,
    required this.customCategories,
    required this.duplicateName,
    required this.nameController,
    required this.nameFocus,
    required this.onEmojiChanged,
    required this.onNameChanged,
    required this.onCategoryChanged,
    required this.onCustomCategoryChanged,
    required this.onAddCustomCategory,
    required this.onTemplateTap,
  });

  @override
  Widget build(BuildContext context) {
    final text = isDark ? const Color(0xFFF9FAFB) : AppTheme.textPrimary;
    final muted = isDark ? const Color(0xFF9CA3AF) : AppTheme.textTertiary;
    final surface = isDark ? const Color(0xFF111827) : Colors.white;
    final border = isDark ? const Color(0xFF374151) : AppTheme.borderLight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "What's the task?",
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w800,
            fontSize: 22,
            color: text,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Quick templates',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            color: muted,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _templates
                .map(
                  (t) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      avatar: Text(t.emoji),
                      label: Text(t.name),
                      onPressed: () => onTemplateTap(t),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _emojis.map((e) {
            final selected = e == emoji;
            return GestureDetector(
              onTap: () => onEmojiChanged(e),
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: selected ? AppTheme.primaryLight : surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected ? AppTheme.primary : border,
                    width: selected ? 2 : 1,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(e, style: const TextStyle(fontSize: 22)),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: nameController,
          focusNode: nameFocus,
          onChanged: onNameChanged,
          style: TextStyle(color: text, fontFamily: 'Inter', fontSize: 15),
          decoration: InputDecoration(
            hintText: 'Task name',
            hintStyle: TextStyle(color: muted),
          ),
        ),
        if (duplicateName)
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text(
              'A task with this name already exists.',
              style: TextStyle(
                color: AppTheme.overdueRed,
                fontSize: 12,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...TaskCategory.values.map((c) {
              final selected = selectedCustomCategory == null && c == category;
              return ChoiceChip(
                label: Text('${c.emoji} ${c.label}'),
                selected: selected,
                onSelected: (_) => onCategoryChanged(c),
              );
            }),
            ...customCategories.map((c) {
              final selected = selectedCustomCategory?.id == c.id;
              return ChoiceChip(
                label: Text('${c.emoji} ${c.label}'),
                selected: selected,
                onSelected: (_) => onCustomCategoryChanged(c),
              );
            }),
            ActionChip(
              onPressed: onAddCustomCategory,
              avatar: const Icon(Icons.add, size: 16),
              label: const Text('Custom'),
            ),
          ],
        ),
      ],
    );
  }
}

class _Step2 extends StatefulWidget {
  final bool isDark;
  final TaskType taskType;
  final void Function(TaskType) onTypeChanged;

  const _Step2({
    super.key,
    required this.isDark,
    required this.taskType,
    required this.onTypeChanged,
  });

  @override
  State<_Step2> createState() => _Step2State();
}

class _Step2State extends State<_Step2> {
  TaskType? _expandedType;

  @override
  Widget build(BuildContext context) {
    final text = widget.isDark
        ? const Color(0xFFF9FAFB)
        : AppTheme.textPrimary;
    final muted = widget.isDark
        ? const Color(0xFF9CA3AF)
        : AppTheme.textTertiary;
    final surface = widget.isDark
        ? const Color(0xFF111827)
        : Colors.white;
    final border = widget.isDark
        ? const Color(0xFF374151)
        : AppTheme.borderLight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How does it repeat?',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w800,
            fontSize: 22,
            color: text,
          ),
        ),
        const SizedBox(height: 8),
        ...TaskType.values.map((type) {
          final selected = type == widget.taskType;
          final expanded = _expandedType == type;
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              children: [
                ListTile(
                  onTap: () {
                    widget.onTypeChanged(type);
                    setState(() {
                      _expandedType = expanded ? null : type;
                    });
                  },
                  tileColor: selected ? AppTheme.primaryLight : surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                        color: selected ? AppTheme.primary : border),
                  ),
                  leading: Text(type.icon,
                      style: const TextStyle(fontSize: 24)),
                  title: Text(
                    type.label,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                      color: selected ? AppTheme.primary : text,
                    ),
                  ),
                  subtitle: Text(
                    type.desc,
                    style: TextStyle(color: muted, fontFamily: 'Inter'),
                  ),
                  trailing: Icon(
                    expanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: selected ? AppTheme.primary : text,
                  ),
                ),
                if (expanded)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: widget.isDark
                          ? const Color(0xFF0F172A)
                          : AppTheme.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.primary.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Example:',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: AppTheme.primary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _getExample(type),
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            color: muted,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }

  String _getExample(TaskType type) {
    switch (type) {
      case TaskType.fixed:
        return 'If set to 14 days, it will notify you exactly every 14 days regardless of when you mark it done.';
      case TaskType.smart:
        return 'Analyzes your completion history. If you usually complete it every 10-15 days, it learns this pattern and adjusts accordingly.';
      case TaskType.conditional:
        return 'Triggers based on conditions like "when gas tank is half full" or "when battery is low" rather than a fixed schedule.';
    }
  }
}

class _Step3 extends StatelessWidget {
  final bool isDark;
  final String emoji;
  final int intervalDays;
  final int lastDoneOffset;
  final String previewDate;
  final int reminderHour;
  final int reminderMinute;
  final void Function(int) onIntervalChanged;
  final void Function(int) onLastDoneChanged;

  const _Step3({
    super.key,
    required this.isDark,
    required this.emoji,
    required this.intervalDays,
    required this.lastDoneOffset,
    required this.previewDate,
    required this.reminderHour,
    required this.reminderMinute,
    required this.onIntervalChanged,
    required this.onLastDoneChanged,
  });

  String _estimatedReminder(BuildContext context) {
    final parts = previewDate.split('-');
    final dt = DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
      reminderHour,
      reminderMinute,
    );
    final date = formatDate(
        '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}');
    final time = MaterialLocalizations.of(context)
        .formatTimeOfDay(TimeOfDay(hour: dt.hour, minute: dt.minute));
    return '$date at $time';
  }

  @override
  Widget build(BuildContext context) {
    final text = isDark ? const Color(0xFFF9FAFB) : AppTheme.textPrimary;
    final muted = isDark ? const Color(0xFF9CA3AF) : AppTheme.textTertiary;
    final surface = isDark ? const Color(0xFF111827) : Colors.white;
    final border = isDark ? const Color(0xFF374151) : AppTheme.borderLight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Almost done!',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w800,
            fontSize: 22,
            color: text,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _intervalPresets.map((p) {
            final selected = p == intervalDays;
            return ChoiceChip(
              label: Text('${p}d'),
              selected: selected,
              onSelected: (_) => onIntervalChanged(p),
              selectedColor: AppTheme.primary,
              labelStyle: TextStyle(color: selected ? Colors.white : muted),
            );
          }).toList(),
        ),
        Slider(
          min: 1,
          max: 365,
          value: intervalDays.toDouble(),
          onChanged: (v) => onIntervalChanged(v.round()),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _lastDoneOptions.map((o) {
            final selected = o.value == lastDoneOffset;
            return ChoiceChip(
              label: Text(o.label),
              selected: selected,
              onSelected: (_) => onLastDoneChanged(o.value),
              selectedColor: AppTheme.primary,
              labelStyle: TextStyle(color: selected ? Colors.white : muted),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 10),
                  Text(
                    'Next due: ${formatDate(previewDate)}',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                      color: text,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Estimated reminder: ${_estimatedReminder(context)}',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: muted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

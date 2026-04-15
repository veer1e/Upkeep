import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

const _emojis = [
  '✂️', '🛏️', '🔧', '🧹', '🌱', '🍳',
  '💊', '🏃', '📚', '🐕', '🚿', '🧴',
  '🛁', '🚙', '🏋️', '🧽',
];

const _intervalPresets = [3, 7, 14, 21, 28, 30, 60, 90, 180, 365];

const _lastDoneOptions = [
  (label: 'Today', value: 0),
  (label: 'Yesterday', value: 1),
  (label: '2 days ago', value: 2),
  (label: '1 week ago', value: 7),
  (label: '2 weeks ago', value: 14),
  (label: '1 month ago', value: 30),
];

const _stepLabels = ['Task', 'Schedule', 'Finish'];

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

  final _nameController = TextEditingController();
  final _nameFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _nameFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  bool get _canProceed => _step == 1 ? _name.trim().isNotEmpty : true;

  String get _previewDate {
    final d = DateTime.now().subtract(Duration(days: _lastDoneOffset));
    final lastStr =
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    return addDaysToDate(lastStr, _intervalDays);
  }

  void _handleNext() {
    if (_step < 3) {
      HapticFeedback.selectionClick();
      setState(() => _step++);
    }
  }

  void _handleBack() {
    if (_step > 1) {
      HapticFeedback.selectionClick();
      setState(() => _step--);
    } else {
      widget.onBack();
    }
  }

  Future<void> _handleSubmit() async {
    HapticFeedback.mediumImpact();
    final d = DateTime.now().subtract(Duration(days: _lastDoneOffset));
    final lastDoneStr =
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    final nextDue = addDaysToDate(lastDoneStr, _intervalDays);

    final newTask = Task(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _name.trim(),
      emoji: _emoji,
      category: _category,
      type: _taskType,
      intervalDays: _intervalDays,
      lastDone: lastDoneStr,
      nextDue: nextDue,
      history: [lastDoneStr],
      patternInsight: _taskType == TaskType.fixed
          ? 'Every $_intervalDays days'
          : _taskType == TaskType.smart
              ? 'Learning your pattern…'
              : null,
    );

    await context.read<AppProvider>().addTask(newTask);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$_emoji "$_name" added!',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          backgroundColor: AppTheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ),
      );
      widget.onDone();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back + title
                Row(
                  children: [
                    GestureDetector(
                      onTap: _handleBack,
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
                    const SizedBox(width: 12),
                    const Text(
                      'New Task',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Step progress
                _StepProgress(step: _step, labels: _stepLabels),
              ],
            ),
          ),
        ),

        // Content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _step == 1
                  ? _Step1(
                      key: const ValueKey(1),
                      emoji: _emoji,
                      name: _name,
                      nameController: _nameController,
                      nameFocus: _nameFocus,
                      category: _category,
                      onEmojiChanged: (e) => setState(() => _emoji = e),
                      onNameChanged: (n) => setState(() => _name = n),
                      onCategoryChanged: (c) => setState(() => _category = c),
                    )
                  : _step == 2
                      ? _Step2(
                          key: const ValueKey(2),
                          taskType: _taskType,
                          onTypeChanged: (t) => setState(() => _taskType = t),
                        )
                      : _Step3(
                          key: const ValueKey(3),
                          emoji: _emoji,
                          intervalDays: _intervalDays,
                          lastDoneOffset: _lastDoneOffset,
                          previewDate: _previewDate,
                          onIntervalChanged: (v) =>
                              setState(() => _intervalDays = v),
                          onLastDoneChanged: (v) =>
                              setState(() => _lastDoneOffset = v),
                        ),
            ),
          ),
        ),

        // Footer CTA
        Container(
          color: Colors.white,
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            MediaQuery.of(context).padding.bottom + 16,
          ),
          child: _step < 3
              ? SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _canProceed ? _handleNext : null,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Continue'),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
                    ),
                  ),
                )
              : SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _handleSubmit,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_rounded, size: 20),
                        SizedBox(width: 8),
                        Text('Add Task'),
                      ],
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

// ─── Step Progress ─────────────────────────────────────────────────────────────

class _StepProgress extends StatelessWidget {
  final int step;
  final List<String> labels;

  const _StepProgress({required this.step, required this.labels});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(labels.length, (i) {
        final isActive = i + 1 == step;
        final isDone = i + 1 < step;
        final isLast = i == labels.length - 1;

        return Expanded(
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isDone || isActive ? AppTheme.primary : AppTheme.borderMedium,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: isDone
                      ? const Icon(Icons.check_rounded,
                          size: 14, color: Colors.white)
                      : Text(
                          '${i + 1}',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: isActive ? Colors.white : AppTheme.textTertiary,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                labels[i],
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: isActive ? AppTheme.primary : AppTheme.textTertiary,
                ),
              ),
              if (!isLast) ...[
                const SizedBox(width: 6),
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 2,
                    decoration: BoxDecoration(
                      color: isDone ? AppTheme.primary : AppTheme.borderMedium,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      }),
    );
  }
}

// ─── Step 1: Task name, emoji, category ────────────────────────────────────────

class _Step1 extends StatelessWidget {
  final String emoji;
  final String name;
  final TextEditingController nameController;
  final FocusNode nameFocus;
  final TaskCategory category;
  final void Function(String) onEmojiChanged;
  final void Function(String) onNameChanged;
  final void Function(TaskCategory) onCategoryChanged;

  const _Step1({
    super.key,
    required this.emoji,
    required this.name,
    required this.nameController,
    required this.nameFocus,
    required this.category,
    required this.onEmojiChanged,
    required this.onNameChanged,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    final categories = [
      (
        value: TaskCategory.personal,
        color: const Color(0xFFF5F3FF),
        border: const Color(0xFFDDD6FE),
        text: const Color(0xFF6D28D9),
      ),
      (
        value: TaskCategory.home,
        color: const Color(0xFFECFDF5),
        border: const Color(0xFFA7F3D0),
        text: const Color(0xFF065F46),
      ),
      (
        value: TaskCategory.car,
        color: const Color(0xFFFFFBEB),
        border: const Color(0xFFFCD34D),
        text: const Color(0xFF92400E),
      ),
      (
        value: TaskCategory.health,
        color: const Color(0xFFFFF1F2),
        border: const Color(0xFFFECACA),
        text: const Color(0xFF9F1239),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "What's the task?",
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w800,
            fontSize: 22,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Pick an icon, name it, and choose a category.',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            color: AppTheme.textTertiary,
          ),
        ),
        const SizedBox(height: 24),

        // Emoji picker
        const Text(
          'Icon',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _emojis.map((e) {
            final isSelected = emoji == e;
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                onEmojiChanged(e);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryLight : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? AppTheme.primary : AppTheme.borderLight,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Center(
                  child: Text(e, style: const TextStyle(fontSize: 22)),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),

        // Task name
        const Text(
          'Task Name',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: nameController,
          focusNode: nameFocus,
          onChanged: onNameChanged,
          decoration: const InputDecoration(
            hintText: 'e.g. Haircut, Oil Change, Water Plants…',
          ),
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 15,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 24),

        // Category
        const Text(
          'Category',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 3.0,
          children: categories.map((cat) {
            final isSelected = category == cat.value;
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                onCategoryChanged(cat.value);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  color: isSelected ? cat.color : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? cat.border : AppTheme.borderLight,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      cat.value.emoji,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      cat.value.label,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: isSelected ? cat.text : AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ─── Step 2: Task type ─────────────────────────────────────────────────────────

class _Step2 extends StatelessWidget {
  final TaskType taskType;
  final void Function(TaskType) onTypeChanged;

  const _Step2({super.key, required this.taskType, required this.onTypeChanged});

  @override
  Widget build(BuildContext context) {
    final types = [TaskType.fixed, TaskType.smart, TaskType.conditional];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'How does it repeat?',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w800,
            fontSize: 22,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Pick a scheduling method that fits.',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            color: AppTheme.textTertiary,
          ),
        ),
        const SizedBox(height: 24),
        ...types.map((t) {
          final isSelected = taskType == t;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                onTypeChanged(t);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryLight : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppTheme.primary : AppTheme.borderLight,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Text(t.icon, style: const TextStyle(fontSize: 32)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.label,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: isSelected
                                  ? const Color(0xFF3730A3)
                                  : AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            t.desc,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              color: isSelected
                                  ? const Color(0xFF818CF8)
                                  : AppTheme.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          color: AppTheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

// ─── Step 3: Interval + last done ─────────────────────────────────────────────

class _Step3 extends StatelessWidget {
  final String emoji;
  final int intervalDays;
  final int lastDoneOffset;
  final String previewDate;
  final void Function(int) onIntervalChanged;
  final void Function(int) onLastDoneChanged;

  const _Step3({
    super.key,
    required this.emoji,
    required this.intervalDays,
    required this.lastDoneOffset,
    required this.previewDate,
    required this.onIntervalChanged,
    required this.onLastDoneChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Almost done!',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w800,
            fontSize: 22,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Set the interval and when you last did this.',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            color: AppTheme.textTertiary,
          ),
        ),
        const SizedBox(height: 24),

        // Interval heading
        RichText(
          text: TextSpan(
            children: [
              const TextSpan(
                text: 'Repeat every ',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AppTheme.textPrimary,
                ),
              ),
              TextSpan(
                text: '$intervalDays days',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Presets
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _intervalPresets.map((p) {
            final isSelected = intervalDays == p;
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                onIntervalChanged(p);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primary : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${p}d',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: isSelected ? Colors.white : AppTheme.textSecondary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),

        // Slider
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppTheme.primary,
            inactiveTrackColor: AppTheme.borderMedium,
            thumbColor: AppTheme.primary,
            overlayColor: AppTheme.primaryLight,
          ),
          child: Slider(
            min: 1,
            max: 365,
            value: intervalDays.toDouble(),
            onChanged: (v) => onIntervalChanged(v.round()),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('1 day',
                  style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: AppTheme.textTertiary)),
              Text('365 days',
                  style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: AppTheme.textTertiary)),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Last done
        const Text(
          'When did you last do this?',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 3.0,
          children: _lastDoneOptions.map((opt) {
            final isSelected = lastDoneOffset == opt.value;
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                onLastDoneChanged(opt.value);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primary : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    opt.label,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: isSelected ? Colors.white : AppTheme.textSecondary,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),

        // Next due preview
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.borderLight),
          ),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Next due date',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: AppTheme.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formatDate(previewDate),
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

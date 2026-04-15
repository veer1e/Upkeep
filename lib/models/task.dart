import 'dart:convert';

enum TaskStatus { overdue, dueToday, upcoming }

enum TaskCategory { personal, home, car, health }

enum TaskType { fixed, smart, conditional }

extension TaskCategoryExt on TaskCategory {
  String get label {
    switch (this) {
      case TaskCategory.personal:
        return 'Personal';
      case TaskCategory.home:
        return 'Home';
      case TaskCategory.car:
        return 'Car';
      case TaskCategory.health:
        return 'Health';
    }
  }

  String get emoji {
    switch (this) {
      case TaskCategory.personal:
        return '👤';
      case TaskCategory.home:
        return '🏠';
      case TaskCategory.car:
        return '🚗';
      case TaskCategory.health:
        return '❤️';
    }
  }

  String get value {
    return name;
  }

  static TaskCategory fromString(String s) {
    return TaskCategory.values.firstWhere(
      (e) => e.name == s,
      orElse: () => TaskCategory.personal,
    );
  }
}

extension TaskTypeExt on TaskType {
  String get label {
    switch (this) {
      case TaskType.fixed:
        return 'Fixed interval';
      case TaskType.smart:
        return 'Smart learning';
      case TaskType.conditional:
        return 'Conditional';
    }
  }

  String get icon {
    switch (this) {
      case TaskType.fixed:
        return '📅';
      case TaskType.smart:
        return '🧠';
      case TaskType.conditional:
        return '⚡';
    }
  }

  String get desc {
    switch (this) {
      case TaskType.fixed:
        return 'Repeats every X days, always predictable';
      case TaskType.smart:
        return 'Learns your actual pattern over time';
      case TaskType.conditional:
        return 'Triggered by a specific condition';
    }
  }

  static TaskType fromString(String s) {
    return TaskType.values.firstWhere(
      (e) => e.name == s,
      orElse: () => TaskType.fixed,
    );
  }
}

class CustomCategory {
  final String id;
  final String label;
  final String emoji;

  const CustomCategory({
    required this.id,
    required this.label,
    required this.emoji,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'emoji': emoji,
      };

  factory CustomCategory.fromJson(Map<String, dynamic> json) => CustomCategory(
        id: json['id'] as String,
        label: json['label'] as String,
        emoji: json['emoji'] as String,
      );
}

class Task {
  final String id;
  final String name;
  final String emoji;
  final TaskCategory category;
  final TaskType type;
  final int intervalDays;
  final String lastDone; // YYYY-MM-DD
  final String nextDue; // YYYY-MM-DD
  final List<String> history; // YYYY-MM-DD[]
  final String? patternInsight;
  final String? conditionalTrigger;
  final String? customCategoryLabel;
  final String? customCategoryEmoji;

  const Task({
    required this.id,
    required this.name,
    required this.emoji,
    required this.category,
    required this.type,
    required this.intervalDays,
    required this.lastDone,
    required this.nextDue,
    required this.history,
    this.patternInsight,
    this.conditionalTrigger,
    this.customCategoryLabel,
    this.customCategoryEmoji,
  });

  Task copyWith({
    String? id,
    String? name,
    String? emoji,
    TaskCategory? category,
    TaskType? type,
    int? intervalDays,
    String? lastDone,
    String? nextDue,
    List<String>? history,
    String? patternInsight,
    String? conditionalTrigger,
    String? customCategoryLabel,
    String? customCategoryEmoji,
  }) {
    return Task(
      id: id ?? this.id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      category: category ?? this.category,
      type: type ?? this.type,
      intervalDays: intervalDays ?? this.intervalDays,
      lastDone: lastDone ?? this.lastDone,
      nextDue: nextDue ?? this.nextDue,
      history: history ?? this.history,
      patternInsight: patternInsight ?? this.patternInsight,
      conditionalTrigger: conditionalTrigger ?? this.conditionalTrigger,
      customCategoryLabel: customCategoryLabel ?? this.customCategoryLabel,
      customCategoryEmoji: customCategoryEmoji ?? this.customCategoryEmoji,
    );
  }

  String get categoryLabel => customCategoryLabel ?? category.label;
  String get categoryEmoji => customCategoryEmoji ?? category.emoji;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'emoji': emoji,
      'category': category.name,
      'type': type.name,
      'intervalDays': intervalDays,
      'lastDone': lastDone,
      'nextDue': nextDue,
      'history': history,
      'patternInsight': patternInsight,
      'conditionalTrigger': conditionalTrigger,
      'customCategoryLabel': customCategoryLabel,
      'customCategoryEmoji': customCategoryEmoji,
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      name: json['name'] as String,
      emoji: json['emoji'] as String,
      category: TaskCategoryExt.fromString(json['category'] as String),
      type: TaskTypeExt.fromString(json['type'] as String),
      intervalDays: json['intervalDays'] as int,
      lastDone: json['lastDone'] as String,
      nextDue: json['nextDue'] as String,
      history: List<String>.from(json['history'] as List),
      patternInsight: json['patternInsight'] as String?,
      conditionalTrigger: json['conditionalTrigger'] as String?,
      customCategoryLabel: json['customCategoryLabel'] as String?,
      customCategoryEmoji: json['customCategoryEmoji'] as String?,
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory Task.fromJsonString(String s) => Task.fromJson(jsonDecode(s));
}

// ─── Utilities ───────────────────────────────────────────────────────────────

String todayStr() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}

DateTime _parseDate(String dateStr) {
  final parts = dateStr.split('-');
  return DateTime(
    int.parse(parts[0]),
    int.parse(parts[1]),
    int.parse(parts[2]),
  );
}

TaskStatus getTaskStatus(String nextDue) {
  final today = DateTime.now();
  final todayNorm = DateTime(today.year, today.month, today.day);
  final due = _parseDate(nextDue);
  if (due.isBefore(todayNorm)) return TaskStatus.overdue;
  if (due.isAtSameMomentAs(todayNorm)) return TaskStatus.dueToday;
  return TaskStatus.upcoming;
}

int getDaysUntilDue(String nextDue) {
  final today = DateTime.now();
  final todayNorm = DateTime(today.year, today.month, today.day);
  final due = _parseDate(nextDue);
  return due.difference(todayNorm).inDays;
}

int getDaysAgo(String dateStr) {
  final today = DateTime.now();
  final todayNorm = DateTime(today.year, today.month, today.day);
  final date = _parseDate(dateStr);
  return todayNorm.difference(date).inDays;
}

String formatLastDone(String lastDone) {
  final days = getDaysAgo(lastDone);
  if (days == 0) return 'Today';
  if (days == 1) return 'Yesterday';
  if (days < 7) return '$days days ago';
  if (days < 14) return '1 week ago';
  if (days < 30) return '${(days / 7).floor()} weeks ago';
  if (days < 60) return '1 month ago';
  return '${(days / 30).floor()} months ago';
}

String formatDate(String dateStr) {
  final date = _parseDate(dateStr);
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
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}

String addDaysToDate(String dateStr, int days) {
  final date = _parseDate(dateStr);
  final result = date.add(Duration(days: days));
  return '${result.year}-${result.month.toString().padLeft(2, '0')}-${result.day.toString().padLeft(2, '0')}';
}

String statusLabel(TaskStatus status, int days) {
  switch (status) {
    case TaskStatus.overdue:
      return '${days.abs()}d overdue';
    case TaskStatus.dueToday:
      return 'Due today';
    case TaskStatus.upcoming:
      return 'In ${days}d';
  }
}

// ─── Initial seed data ────────────────────────────────────────────────────────

final List<Task> initialTasks = [
  Task(
    id: '1',
    name: 'Haircut',
    emoji: '✂️',
    category: TaskCategory.personal,
    type: TaskType.fixed,
    intervalDays: 28,
    lastDone: '2026-02-26',
    nextDue: '2026-03-26',
    history: ['2025-11-30', '2025-12-28', '2026-01-25', '2026-02-26'],
    patternInsight: '~28 days interval',
  ),
  Task(
    id: '2',
    name: 'Wash Bedsheets',
    emoji: '🛏️',
    category: TaskCategory.home,
    type: TaskType.smart,
    intervalDays: 14,
    lastDone: '2026-03-12',
    nextDue: '2026-03-30',
    history: [
      '2026-01-15',
      '2026-01-29',
      '2026-02-12',
      '2026-02-26',
      '2026-03-12'
    ],
    patternInsight: '~14 days interval',
  ),
  Task(
    id: '3',
    name: 'Oil Change',
    emoji: '🔧',
    category: TaskCategory.car,
    type: TaskType.fixed,
    intervalDays: 90,
    lastDone: '2025-12-21',
    nextDue: '2026-03-21',
    history: ['2025-03-23', '2025-06-21', '2025-09-19', '2025-12-21'],
    patternInsight: '~90 days interval',
  ),
  Task(
    id: '4',
    name: 'Vacuum Home',
    emoji: '🧹',
    category: TaskCategory.home,
    type: TaskType.fixed,
    intervalDays: 7,
    lastDone: '2026-03-19',
    nextDue: '2026-03-28',
    history: ['2026-03-05', '2026-03-12', '2026-03-19'],
    patternInsight: '~7 days interval',
  ),
  Task(
    id: '5',
    name: 'Water Plants',
    emoji: '🌱',
    category: TaskCategory.home,
    type: TaskType.fixed,
    intervalDays: 3,
    lastDone: '2026-03-24',
    nextDue: '2026-03-27',
    history: ['2026-03-18', '2026-03-21', '2026-03-24'],
    patternInsight: '~3 days interval',
  ),
];

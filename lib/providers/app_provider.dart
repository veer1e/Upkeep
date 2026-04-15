import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';

class AppProvider extends ChangeNotifier {
  static const String _storageKey = 'life-maintenance-tasks';
  static const String _themeModeKey = 'life-maintenance-theme-mode';

  List<Task> _tasks = [];
  Task? _completionTarget;
  bool _isLoaded = false;
  ThemeMode _themeMode = ThemeMode.light;

  List<Task> get tasks => _tasks;
  Task? get completionTarget => _completionTarget;
  bool get isLoaded => _isLoaded;
  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  // Derived getters
  List<Task> get overdueTasks => _tasks
      .where((t) => getTaskStatus(t.nextDue) == TaskStatus.overdue)
      .toList();

  List<Task> get dueTodayTasks => _tasks
      .where((t) => getTaskStatus(t.nextDue) == TaskStatus.dueToday)
      .toList();

  List<Task> get upcomingTasks {
    final list = _tasks
        .where((t) => getTaskStatus(t.nextDue) == TaskStatus.upcoming)
        .toList();
    list.sort((a, b) => a.nextDue.compareTo(b.nextDue));
    return list;
  }

  Future<void> loadTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_storageKey);
      final storedThemeMode = prefs.getString(_themeModeKey);
      if (storedThemeMode == 'dark') {
        _themeMode = ThemeMode.dark;
      } else {
        _themeMode = ThemeMode.light;
      }
      if (stored != null) {
        final List<dynamic> decoded = jsonDecode(stored);
        _tasks = decoded
            .map((e) => Task.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        _tasks = List.from(initialTasks);
      }
    } catch (_) {
      _tasks = List.from(initialTasks);
    }
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> _saveTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(_tasks.map((t) => t.toJson()).toList());
      await prefs.setString(_storageKey, encoded);
    } catch (_) {}
  }

  String buildExportJson() {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert({
      'schemaVersion': 1,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'tasks': _tasks.map((task) => task.toJson()).toList(),
    });
  }

  Future<int> importFromJson(String rawJson,
      {bool replaceExisting = true}) async {
    final decoded = jsonDecode(rawJson);
    List<dynamic> rawTasks;

    if (decoded is Map<String, dynamic> && decoded['tasks'] is List) {
      rawTasks = decoded['tasks'] as List<dynamic>;
    } else if (decoded is List) {
      rawTasks = decoded;
    } else {
      throw const FormatException('Invalid import format.');
    }

    final imported = rawTasks
        .map((e) => Task.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    if (replaceExisting) {
      _tasks = imported;
    } else {
      _tasks = [..._tasks, ...imported];
    }

    notifyListeners();
    await _saveTasks();
    return imported.length;
  }

  Future<void> setDarkMode(bool enabled) async {
    _themeMode = enabled ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeModeKey, enabled ? 'dark' : 'light');
    } catch (_) {}
  }

  void setCompletionTarget(Task? task) {
    _completionTarget = task;
    notifyListeners();
  }

  Future<void> completeTask(String id, int daysAgo) async {
    final now = DateTime.now();
    final doneDate = now.subtract(Duration(days: daysAgo));
    final doneDateStr =
        '${doneDate.year}-${doneDate.month.toString().padLeft(2, '0')}-${doneDate.day.toString().padLeft(2, '0')}';

    _tasks = _tasks.map((task) {
      if (task.id != id) return task;
      return task.copyWith(
        lastDone: doneDateStr,
        nextDue: addDaysToDate(doneDateStr, task.intervalDays),
        history: [...task.history, doneDateStr],
      );
    }).toList();

    _completionTarget = null;
    notifyListeners();
    await _saveTasks();
  }

  Future<void> addTask(Task task) async {
    _tasks = [..._tasks, task];
    notifyListeners();
    await _saveTasks();
  }

  Future<void> deleteTask(String id) async {
    _tasks = _tasks.where((t) => t.id != id).toList();
    notifyListeners();
    await _saveTasks();
  }

  Future<void> updateTask(String id, Task updatedTask) async {
    _tasks = _tasks.map((t) => t.id == id ? updatedTask : t).toList();
    notifyListeners();
    await _saveTasks();
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';
import '../services/app_notification_service.dart';

class AppProvider extends ChangeNotifier {
  static const String _storageKey = 'life-maintenance-tasks';
  static const String _themeModeKey = 'life-maintenance-theme-mode';
  static const String _notificationsEnabledKey =
      'life-maintenance-notifications-enabled';
  static const String _notificationMinutesKey =
      'life-maintenance-notification-minutes';
  static const String _customCategoriesKey =
      'life-maintenance-custom-categories';

  List<Task> _tasks = [];
  Task? _completionTarget;
  bool _isLoaded = false;
  ThemeMode _themeMode = ThemeMode.light;
  bool _notificationsEnabled = false;
  int _notificationMinutes = 9 * 60;
  List<CustomCategory> _customCategories = [];

  List<Task> get tasks => _tasks;
  Task? get completionTarget => _completionTarget;
  bool get isLoaded => _isLoaded;
  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get notificationsEnabled => _notificationsEnabled;
  int get notificationHour => _notificationMinutes ~/ 60;
  int get notificationMinute => _notificationMinutes % 60;
  List<CustomCategory> get customCategories => _customCategories;

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
      final storedCustomCategories = prefs.getString(_customCategoriesKey);
      final storedThemeMode = prefs.getString(_themeModeKey);
      _notificationsEnabled = prefs.getBool(_notificationsEnabledKey) ?? false;
      _notificationMinutes = prefs.getInt(_notificationMinutesKey) ?? 9 * 60;
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

      if (storedCustomCategories != null) {
        final decoded = jsonDecode(storedCustomCategories) as List<dynamic>;
        _customCategories = decoded
            .map((e) => CustomCategory.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      } else {
        _customCategories = [];
      }
    } catch (_) {
      _tasks = List.from(initialTasks);
      _customCategories = [];
    }
    _isLoaded = true;
    notifyListeners();
    await _syncScheduledNotifications();
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
    await _syncScheduledNotifications();
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

  Future<void> setNotificationsEnabled(bool enabled) async {
    _notificationsEnabled = enabled;
    notifyListeners();
    await _saveNotificationPrefs();
    if (enabled) {
      await AppNotificationService.instance.requestPermissions();
    }
    await _syncScheduledNotifications();
  }

  Future<void> setNotificationTime(TimeOfDay time) async {
    _notificationMinutes = time.hour * 60 + time.minute;
    notifyListeners();
    await _saveNotificationPrefs();
    if (_notificationsEnabled) {
      await _syncScheduledNotifications();
    }
  }

  Future<void> addCustomCategory({
    required String label,
    required String emoji,
  }) async {
    final normalized = label.trim();
    if (normalized.isEmpty) return;
    final exists = _customCategories
        .any((c) => c.label.toLowerCase() == normalized.toLowerCase());
    if (exists) return;

    final category = CustomCategory(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      label: normalized,
      emoji: emoji.trim().isEmpty ? '🏷️' : emoji.trim(),
    );
    _customCategories = [..._customCategories, category];
    notifyListeners();
    await _saveCustomCategories();
  }

  Future<void> deleteCustomCategory(String id) async {
    _customCategories = _customCategories.where((c) => c.id != id).toList();
    notifyListeners();
    await _saveCustomCategories();
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
    await _syncScheduledNotifications();
  }

  Future<void> addTask(Task task) async {
    _tasks = [..._tasks, task];
    notifyListeners();
    await _saveTasks();
    await _syncScheduledNotifications();
  }

  Future<void> deleteTask(String id) async {
    _tasks = _tasks.where((t) => t.id != id).toList();
    notifyListeners();
    await _saveTasks();
    await _syncScheduledNotifications();
  }

  Future<void> updateTask(String id, Task updatedTask) async {
    _tasks = _tasks.map((t) => t.id == id ? updatedTask : t).toList();
    notifyListeners();
    await _saveTasks();
    await _syncScheduledNotifications();
  }

  Future<int> clearAllTasks() async {
    final clearedCount = _tasks.length;
    _tasks = [];
    notifyListeners();
    await _saveTasks();
    await _syncScheduledNotifications();
    return clearedCount;
  }

  Future<void> _saveNotificationPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_notificationsEnabledKey, _notificationsEnabled);
      await prefs.setInt(_notificationMinutesKey, _notificationMinutes);
    } catch (_) {}
  }

  Future<void> _syncScheduledNotifications() async {
    try {
      await AppNotificationService.instance.scheduleTaskNotifications(
        tasks: _tasks,
        enabled: _notificationsEnabled,
        hour: notificationHour,
        minute: notificationMinute,
      );
    } catch (_) {}
  }

  Future<void> _saveCustomCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(
        _customCategories.map((c) => c.toJson()).toList(),
      );
      await prefs.setString(_customCategoriesKey, encoded);
    } catch (_) {}
  }
}

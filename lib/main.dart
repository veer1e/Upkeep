import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'screens/home_screen.dart';
import 'screens/tasks_screen.dart';
import 'screens/task_details_screen.dart';
import 'screens/add_task_screen.dart';
import 'screens/settings_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Enforce portrait orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Status bar styling
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
  ));

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppProvider()..loadTasks(),
      child: const LifeMaintenanceApp(),
    ),
  );
}

class LifeMaintenanceApp extends StatelessWidget {
  const LifeMaintenanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    return MaterialApp(
      title: 'Life Maintenance',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: provider.themeMode,
      home: const AppShell(),
    );
  }
}

// ─── App Shell with Bottom Navigation ─────────────────────────────────────────

enum _AppRoute { home, tasks, addTask, taskDetails, settings }

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _tab = 0; // 0=Home, 1=Tasks, 2=Settings
  _AppRoute _route = _AppRoute.home;
  String? _selectedTaskId;

  void _navigateToTaskDetails(String taskId) {
    setState(() {
      _selectedTaskId = taskId;
      _route = _AppRoute.taskDetails;
    });
  }

  void _navigateToAdd() {
    setState(() => _route = _AppRoute.addTask);
  }

  void _navigateBack() {
    setState(() {
      if (_route == _AppRoute.taskDetails) {
        _selectedTaskId = null;
        _route = _tab == 0 ? _AppRoute.home : _AppRoute.tasks;
      } else if (_route == _AppRoute.addTask) {
        _route = _tab == 0 ? _AppRoute.home : _AppRoute.tasks;
      }
    });
  }

  void _onTabSelected(int index) {
    setState(() {
      _tab = index;
      _route = index == 0
          ? _AppRoute.home
          : index == 1
              ? _AppRoute.tasks
              : _AppRoute.settings;
    });
  }

  bool get _showNav =>
      _route == _AppRoute.home ||
      _route == _AppRoute.tasks ||
      _route == _AppRoute.settings;

  bool get _showFab => _route == _AppRoute.tasks;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _buildCurrentScreen(),
        ),
      ),
      floatingActionButton: _showFab ? _FAB(onTap: _navigateToAdd) : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: _showNav
          ? _BottomNav(
              selectedIndex: _tab,
              onTap: _onTabSelected,
            )
          : null,
    );
  }

  Widget _buildCurrentScreen() {
    switch (_route) {
      case _AppRoute.home:
        return HomeScreen(
          key: const ValueKey('home'),
          onTaskDetails: _navigateToTaskDetails,
        );
      case _AppRoute.tasks:
        return TasksScreen(
          key: const ValueKey('tasks'),
          onTaskDetails: _navigateToTaskDetails,
        );
      case _AppRoute.settings:
        return const SettingsScreen(key: ValueKey('settings'));
      case _AppRoute.taskDetails:
        return TaskDetailsScreen(
          key: ValueKey('details-$_selectedTaskId'),
          taskId: _selectedTaskId!,
          onBack: _navigateBack,
        );
      case _AppRoute.addTask:
        return AddTaskScreen(
          key: const ValueKey('add'),
          onBack: _navigateBack,
          onDone: _navigateBack,
        );
    }
  }
}

// ─── FAB ──────────────────────────────────────────────────────────────────────

class _FAB extends StatefulWidget {
  final VoidCallback onTap;

  const _FAB({required this.onTap});

  @override
  State<_FAB> createState() => _FABState();
}

class _FABState extends State<_FAB> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.93,
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 72),
      child: GestureDetector(
        onTapDown: (_) => _ctrl.reverse(),
        onTapUp: (_) {
          _ctrl.forward();
          HapticFeedback.mediumImpact();
          widget.onTap();
        },
        onTapCancel: () => _ctrl.forward(),
        child: ScaleTransition(
          scale: _ctrl,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppTheme.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryShadow.withOpacity(0.6),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.add_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Bottom Navigation ─────────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final int selectedIndex;
  final void Function(int) onTap;

  const _BottomNav({
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final items = [
      (
        icon: Icons.home_rounded,
        outlineIcon: Icons.home_outlined,
        label: 'Home'
      ),
      (
        icon: Icons.list_alt_rounded,
        outlineIcon: Icons.list_alt_outlined,
        label: 'Tasks'
      ),
      (
        icon: Icons.settings_rounded,
        outlineIcon: Icons.settings_outlined,
        label: 'Settings'
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF1F2937) : AppTheme.borderLight,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: items.asMap().entries.map((entry) {
              final i = entry.key;
              final item = entry.value;
              final isActive = selectedIndex == i;

              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onTap(i);
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isActive ? item.icon : item.outlineIcon,
                        size: 22,
                        color:
                            isActive ? AppTheme.primary : AppTheme.textTertiary,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                          color: isActive
                              ? AppTheme.primary
                              : AppTheme.textTertiary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      if (isActive)
                        Container(
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: AppTheme.primary,
                            shape: BoxShape.circle,
                          ),
                        )
                      else
                        const SizedBox(height: 4),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

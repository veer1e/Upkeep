import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../utils/export_download.dart';
import '../utils/import_data_picker.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF111827) : Colors.white;
    final borderColor = isDark ? const Color(0xFF1F2937) : AppTheme.borderLight;
    final titleColor = isDark ? const Color(0xFFF9FAFB) : AppTheme.textPrimary;
    final labelColor = isDark ? const Color(0xFFD1D5DB) : AppTheme.textPrimary;
    final mutedColor = isDark ? const Color(0xFF9CA3AF) : AppTheme.textTertiary;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      children: [
        Text(
          'Settings',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w800,
            fontSize: 22,
            color: titleColor,
          ),
        ),
        const SizedBox(height: 24),

        // App info card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Center(
                  child: Text('🔁', style: TextStyle(fontSize: 28)),
                ),
              ),
              const SizedBox(width: 16),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Life Maintenance',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Version 1.0.0 · Offline-first',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // General settings
        _SectionLabel(label: 'General', color: mutedColor),
        const SizedBox(height: 10),
        _SettingsCard(
          bgColor: cardColor,
          borderColor: borderColor,
          children: [
            _SettingsTile(
              icon: Icons.notifications_outlined,
              label: 'Notifications',
              iconColor: mutedColor,
              labelColor: labelColor,
              trailing: Switch.adaptive(
                value: true,
                onChanged: (_) {},
                activeThumbColor: AppTheme.primary,
              ),
            ),
            const _Divider(),
            _SettingsTile(
              icon: Icons.dark_mode_outlined,
              label: 'Dark Mode',
              iconColor: mutedColor,
              labelColor: labelColor,
              trailing: Switch.adaptive(
                value: provider.isDarkMode,
                onChanged: (value) => provider.setDarkMode(value),
                activeThumbColor: AppTheme.primary,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Data settings
        _SectionLabel(label: 'Data', color: mutedColor),
        const SizedBox(height: 10),
        _SettingsCard(
          bgColor: cardColor,
          borderColor: borderColor,
          children: [
            _SettingsTile(
              icon: Icons.file_download_outlined,
              label: 'Export Data',
              iconColor: mutedColor,
              labelColor: labelColor,
              trailing: Icon(
                Icons.chevron_right_rounded,
                color: mutedColor,
              ),
              onTap: () => _exportData(context, provider),
            ),
            const _Divider(),
            _SettingsTile(
              icon: Icons.file_upload_outlined,
              label: 'Import Data',
              iconColor: mutedColor,
              labelColor: labelColor,
              trailing: Icon(
                Icons.chevron_right_rounded,
                color: mutedColor,
              ),
              onTap: () => _importData(context, provider),
            ),
            const _Divider(),
            _SettingsTile(
              icon: Icons.delete_outline_rounded,
              label: 'Clear All Tasks',
              textColor: AppTheme.overdueRed,
              iconColor: AppTheme.overdueRed,
              trailing: const Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.overdueRed,
              ),
              onTap: () => _confirmClear(context, provider),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // About
        _SectionLabel(label: 'About', color: mutedColor),
        const SizedBox(height: 10),
        _SettingsCard(
          bgColor: cardColor,
          borderColor: borderColor,
          children: [
            _SettingsTile(
              icon: Icons.privacy_tip_outlined,
              label: 'Privacy Policy',
              iconColor: mutedColor,
              labelColor: labelColor,
              trailing: Icon(
                Icons.chevron_right_rounded,
                color: mutedColor,
              ),
              onTap: () {},
            ),
            const _Divider(),
            _SettingsTile(
              icon: Icons.star_outline_rounded,
              label: 'Rate the App',
              iconColor: mutedColor,
              labelColor: labelColor,
              trailing: Icon(
                Icons.chevron_right_rounded,
                color: mutedColor,
              ),
              onTap: () {},
            ),
          ],
        ),

        const SizedBox(height: 32),
        Center(
          child: Text(
            'Made with ❤️ · Offline & private',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: mutedColor,
            ),
          ),
        ),
      ],
    );
  }

  void _confirmClear(BuildContext context, AppProvider provider) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Clear All Tasks',
          style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'This will permanently delete all your tasks and history. Are you sure?',
          style: TextStyle(fontFamily: 'Inter'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              for (final task in [...provider.tasks]) {
                await provider.deleteTask(task.id);
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text(
              'Clear All',
              style: TextStyle(color: AppTheme.overdueRed),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportData(BuildContext context, AppProvider provider) async {
    HapticFeedback.lightImpact();

    final json = provider.buildExportJson();
    final now = DateTime.now();
    final date =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final filename = 'life-maintenance-export-$date.json';
    final downloaded =
        await downloadExportFile(filename: filename, content: json);

    await Clipboard.setData(ClipboardData(text: json));
    if (!context.mounted) return;

    final taskCount = (jsonDecode(json)['tasks'] as List<dynamic>).length;
    final message = downloaded
        ? 'Exported $taskCount tasks to $filename and copied JSON to clipboard.'
        : 'Copied export JSON for $taskCount tasks to clipboard.';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _importData(BuildContext context, AppProvider provider) async {
    HapticFeedback.lightImpact();
    final input = await _showImportDialog(context);
    if (input == null || input.trim().isEmpty || !context.mounted) return;

    try {
      final importedCount =
          await provider.importFromJson(input, replaceExisting: true);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Imported $importedCount tasks successfully.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Import failed. Please provide a valid export JSON.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<String?> _showImportDialog(BuildContext context) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Import Data',
            style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700),
          ),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  maxLines: 8,
                  decoration: const InputDecoration(
                    hintText: 'Paste exported JSON here',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final data = await Clipboard.getData('text/plain');
                          final text = data?.text;
                          if (text == null) return;
                          setDialogState(() => controller.text = text);
                        },
                        child: const Text('Paste Clipboard'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final fileJson = await pickImportJsonFile();
                          if (fileJson == null) return;
                          setDialogState(() => controller.text = fileJson);
                        },
                        child: const Text('Pick JSON File'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, controller.text),
              child: const Text('Import'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    return result;
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final Color color;

  const _SectionLabel({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w700,
        fontSize: 11,
        letterSpacing: 0.8,
      ).copyWith(
        color: color,
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  final Color bgColor;
  final Color borderColor;

  const _SettingsCard({
    required this.children,
    required this.bgColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget trailing;
  final Color? textColor;
  final Color? iconColor;
  final Color? labelColor;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.trailing,
    this.textColor,
    this.iconColor,
    this.labelColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon,
                size: 20,
                color: iconColor ?? textColor ?? AppTheme.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                  color: labelColor ?? textColor ?? AppTheme.textPrimary,
                ),
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(left: 48),
      child: Divider(
        height: 1,
        color: isDark ? const Color(0xFF1F2937) : AppTheme.borderLight,
      ),
    );
  }
}

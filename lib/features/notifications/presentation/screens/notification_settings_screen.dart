import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../domain/entities/notification_type.dart';
import '../providers/notification_providers.dart';

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // Load persisted preferences from Hive.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationSettingsProvider.notifier).load();
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(notificationSettingsProvider.notifier).save();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification preferences saved'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickReminderTime() async {
    final settings = ref.read(notificationSettingsProvider);
    final picked = await showTimePicker(
      context: context,
      initialTime: settings.reminderTime,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.primary,
            onPrimary: AppColors.textPrimary,
            surface: AppColors.surface,
            onSurface: AppColors.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      ref
          .read(notificationSettingsProvider.notifier)
          .setReminderTime(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(notificationSettingsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _save,
              child: const Text(
                'Save',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          _SectionHeader(label: 'Reminder Time'),
          _ReminderTimeTile(
            time: settings.reminderTime,
            enabled: settings.isEnabled(NotificationType.dailyReminder),
            onTap: _pickReminderTime,
          ),
          const SizedBox(height: 8),
          _SectionHeader(label: 'Notification Types'),
          ...NotificationType.values.map(
            (type) => _NotificationTypeTile(
              type: type,
              enabled: settings.isEnabled(type),
              onChanged: (value) => ref
                  .read(notificationSettingsProvider.notifier)
                  .toggleType(type, enabled: value),
            ),
          ),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Per-user notifications (nudges, group activity) are delivered '
              'directly to your device via your FCM token.\n\n'
              'Global notifications (streak alerts, leaderboard, milestones) '
              'are sent to subscribed topics.',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _ReminderTimeTile extends StatelessWidget {
  const _ReminderTimeTile({
    required this.time,
    required this.enabled,
    required this.onTap,
  });

  final TimeOfDay time;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = time.format(context);
    return ListTile(
      tileColor: AppColors.surface,
      title: const Text(
        'Daily Reminder Time',
        style: TextStyle(color: AppColors.textPrimary, fontSize: 15),
      ),
      subtitle: Text(
        enabled ? label : 'Disabled',
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 20),
        ],
      ),
      onTap: enabled ? onTap : null,
    );
  }
}

class _NotificationTypeTile extends StatelessWidget {
  const _NotificationTypeTile({
    required this.type,
    required this.enabled,
    required this.onChanged,
  });

  final NotificationType type;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      tileColor: AppColors.surface,
      title: Text(
        type.displayName,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
      ),
      subtitle: Text(
        _subtitleFor(type),
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
      ),
      value: enabled,
      onChanged: onChanged,
      activeColor: AppColors.primary,
    );
  }

  String _subtitleFor(NotificationType type) {
    switch (type) {
      case NotificationType.dailyReminder:
        return 'Remind you to read at your chosen time';
      case NotificationType.streakAtRisk:
        return '2 hours before midnight if you haven\'t read';
      case NotificationType.friendNudge:
        return 'When a friend nudges you';
      case NotificationType.groupActivity:
        return '"James just finished today\'s reading"';
      case NotificationType.milestone:
        return '"You hit 30 days!"';
      case NotificationType.planCompletion:
        return 'When your group finishes a plan';
      case NotificationType.weeklyLeaderboard:
        return 'Sunday ranking update';
    }
  }
}

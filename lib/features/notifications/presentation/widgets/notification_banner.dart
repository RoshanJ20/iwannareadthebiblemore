import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../domain/entities/notification_type.dart';

/// Shows a SnackBar-style in-app banner for foreground FCM messages.
///
/// Usage:
/// ```dart
/// fcmService.onForegroundMessage = (message) {
///   NotificationBanner.show(context, message);
/// };
/// ```
class NotificationBanner {
  NotificationBanner._();

  /// Displays an overlay banner for [message].
  ///
  /// The banner:
  /// - Shows the notification title and body.
  /// - Auto-dismisses after 4 seconds.
  /// - Navigates to the appropriate screen on tap.
  static void show(BuildContext context, RemoteMessage message) {
    final title = message.notification?.title ?? '';
    final body = message.notification?.body ?? '';
    if (title.isEmpty && body.isEmpty) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 4),
        backgroundColor: AppColors.surface,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppColors.primary.withOpacity(0.4)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        content: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            _navigate(context, message);
          },
          child: Row(
            children: [
              const Icon(
                Icons.notifications,
                color: AppColors.primary,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (title.isNotEmpty)
                      Text(
                        title,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (body.isNotEmpty) ...[
                      if (title.isNotEmpty) const SizedBox(height: 2),
                      Text(
                        body,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right,
                color: AppColors.textMuted,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void _navigate(BuildContext context, RemoteMessage message) {
    final typeStr = message.data['type'] as String?;
    final type = NotificationType.fromValue(typeStr ?? '');
    final groupId = message.data['groupId'] as String?;

    switch (type) {
      case NotificationType.dailyReminder:
      case NotificationType.streakAtRisk:
      case NotificationType.friendNudge:
        GoRouter.of(context).go('/read');
      case NotificationType.groupActivity:
        if (groupId != null) {
          GoRouter.of(context).go('/groups/$groupId');
        } else {
          GoRouter.of(context).go('/groups');
        }
      case NotificationType.milestone:
      case NotificationType.planCompletion:
        GoRouter.of(context).go('/profile');
      case NotificationType.weeklyLeaderboard:
        if (groupId != null) {
          GoRouter.of(context).go('/groups/$groupId');
        } else {
          GoRouter.of(context).go('/groups');
        }
      case null:
        break;
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/auth_notifier.dart';
import '../../../../core/design_system/app_colors.dart';
import '../providers/notification_providers.dart';

/// A red-dot badge that overlays [child] when there are unread notifications.
///
/// ```dart
/// NotificationBadge(
///   child: Icon(Icons.notifications),
/// )
/// ```
class NotificationBadge extends ConsumerWidget {
  const NotificationBadge({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authNotifierProvider);
    final userId = userAsync.valueOrNull?.uid;

    if (userId == null) return child;

    final unreadCountAsync = ref.watch(
      StreamProvider.family<int, String>((ref, uid) {
        return ref.watch(notificationRepositoryProvider).watchUnreadCount(uid);
      })(userId),
    );

    final unreadCount = unreadCountAsync.valueOrNull ?? 0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        if (unreadCount > 0)
          Positioned(
            top: -4,
            right: -4,
            child: _BadgeDot(count: unreadCount),
          ),
      ],
    );
  }
}

class _BadgeDot extends StatelessWidget {
  const _BadgeDot({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final label = count > 99 ? '99+' : '$count';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.streakRed,
        borderRadius: BorderRadius.circular(10),
      ),
      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          height: 1.2,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

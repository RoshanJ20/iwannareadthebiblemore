import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import '../../domain/services/lamb_state_service.dart';
import '../../gamification_providers.dart';

class LambMascotWidget extends ConsumerWidget {
  final double size;
  const LambMascotWidget({super.key, this.size = 160});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(userStatsProvider);
    return statsAsync.when(
      loading: () => SizedBox(
        width: size,
        height: size,
        child: const CircularProgressIndicator(),
      ),
      error: (_, __) => _fallback(LambState.idle),
      data: (stats) {
        final state = LambStateService.fromStats(stats);
        final assetPath = LambStateService.lottieAssetPath(state);
        return SizedBox(
          width: size,
          height: size,
          child: Lottie.asset(
            assetPath,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => _fallback(state),
          ),
        );
      },
    );
  }

  Widget _fallback(LambState state) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: LambStateService.fallbackColor(state),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.pets, size: 64, color: Colors.white),
      );
}

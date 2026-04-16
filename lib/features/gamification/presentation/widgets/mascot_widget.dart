import 'package:flutter/material.dart';
import '../../../../core/design_system/app_colors.dart';

enum MascotState { idle, excited, celebrating, worried, sad, sleeping, onFire, outfit }

class MascotWidget extends StatelessWidget {
  const MascotWidget({super.key, required this.state, this.size = 120});

  final MascotState state;
  final double size;

  String get _emoji {
    switch (state) {
      case MascotState.idle:
        return '🐑';
      case MascotState.excited:
        return '🐑✨';
      case MascotState.celebrating:
        return '🎉🐑🎉';
      case MascotState.worried:
        return '😰🐑';
      case MascotState.sad:
        return '😢🐑';
      case MascotState.sleeping:
        return '😴🐑';
      case MascotState.onFire:
        return '🔥🐑🔥';
      case MascotState.outfit:
        return '👑🐑';
    }
  }

  String get _label {
    switch (state) {
      case MascotState.idle:
        return 'idle';
      case MascotState.excited:
        return 'excited';
      case MascotState.celebrating:
        return 'celebrating';
      case MascotState.worried:
        return 'worried';
      case MascotState.sad:
        return 'sad';
      case MascotState.sleeping:
        return 'sleeping';
      case MascotState.onFire:
        return 'onFire';
      case MascotState.outfit:
        return 'outfit';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(size / 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _emoji,
              style: TextStyle(fontSize: size * 0.35),
            ),
            const SizedBox(height: 4),
            Text(
              _label,
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: size * 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

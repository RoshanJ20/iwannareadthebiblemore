import 'package:flutter/material.dart';
import '../../../../core/design_system/app_colors.dart';

enum MascotState { idle, excited, celebrating, worried, sad, sleeping, onFire, outfit }

class MascotWidget extends StatelessWidget {
  const MascotWidget({super.key, required this.state, this.size = 120});

  final MascotState state;
  final double size;

  String get _emoji {
    switch (state) {
      case MascotState.idle:        return '🐑';
      case MascotState.excited:     return '🐑✨';
      case MascotState.celebrating: return '🎉🐑🎉';
      case MascotState.worried:     return '😰🐑';
      case MascotState.sad:         return '😢🐑';
      case MascotState.sleeping:    return '😴🐑';
      case MascotState.onFire:      return '🔥🐑🔥';
      case MascotState.outfit:      return '👑🐑';
    }
  }

  String get _label {
    switch (state) {
      case MascotState.idle:        return 'ready to read';
      case MascotState.excited:     return 'keep going!';
      case MascotState.celebrating: return 'amazing!';
      case MascotState.worried:     return "don't forget";
      case MascotState.sad:         return 'missed a day';
      case MascotState.sleeping:    return 'zzz...';
      case MascotState.onFire:      return 'on fire!';
      case MascotState.outfit:      return 'legendary';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [
            AppColors.primary.withOpacity(0.18),
            AppColors.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(size / 2),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.22),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _emoji,
            style: TextStyle(fontSize: size * 0.33),
          ),
          const SizedBox(height: 5),
          Text(
            _label,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: size * 0.083,
              letterSpacing: 0.2,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/design_system/app_colors.dart';
import '../providers/reader_preferences_provider.dart';

class ReaderSettingsSheet extends ConsumerWidget {
  const ReaderSettingsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(readerPreferencesProvider);
    final notifier = ref.read(readerPreferencesProvider.notifier);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 12, 24, MediaQuery.of(context).padding.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Font size
          _Label('Font Size'),
          const SizedBox(height: 4),
          Row(
            children: [
              const Text('A',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
              Expanded(
                child: Slider(
                  value: prefs.fontSize,
                  min: 14,
                  max: 24,
                  divisions: 5,
                  activeColor: AppColors.primary,
                  inactiveColor: AppColors.surfaceElevated,
                  onChanged: notifier.setFontSize,
                ),
              ),
              const Text('A',
                  style:
                      TextStyle(color: AppColors.textPrimary, fontSize: 22)),
            ],
          ),

          const SizedBox(height: 16),

          // Font family
          _Label('Typeface'),
          const SizedBox(height: 8),
          Row(
            children: [
              _FontChip(
                label: 'Serif',
                sample: 'Lora',
                sampleStyle: GoogleFonts.lora(),
                selected: prefs.fontFamily == 'lora',
                onTap: () => notifier.setFontFamily('lora'),
              ),
              const SizedBox(width: 8),
              _FontChip(
                label: 'Sans',
                sample: 'Clean',
                sampleStyle: const TextStyle(),
                selected: prefs.fontFamily == 'system',
                onTap: () => notifier.setFontFamily('system'),
              ),
              const SizedBox(width: 8),
              _FontChip(
                label: 'Classic',
                sample: 'Garamond',
                sampleStyle: GoogleFonts.ebGaramond(),
                selected: prefs.fontFamily == 'garamond',
                onTap: () => notifier.setFontFamily('garamond'),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Line spacing
          _Label('Line Spacing'),
          const SizedBox(height: 8),
          Row(
            children: [
              _SpacingChip(
                label: 'Tight',
                value: 1.4,
                current: prefs.lineHeight,
                onTap: () => notifier.setLineHeight(1.4),
              ),
              const SizedBox(width: 8),
              _SpacingChip(
                label: 'Normal',
                value: 1.85,
                current: prefs.lineHeight,
                onTap: () => notifier.setLineHeight(1.85),
              ),
              const SizedBox(width: 8),
              _SpacingChip(
                label: 'Relaxed',
                value: 2.3,
                current: prefs.lineHeight,
                onTap: () => notifier.setLineHeight(2.3),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Margins
          _Label('Margins'),
          const SizedBox(height: 8),
          Row(
            children: [
              _MarginChip(
                label: 'Narrow',
                value: 16.0,
                current: prefs.horizontalPadding,
                onTap: () => notifier.setHorizontalPadding(16.0),
              ),
              const SizedBox(width: 8),
              _MarginChip(
                label: 'Normal',
                value: 24.0,
                current: prefs.horizontalPadding,
                onTap: () => notifier.setHorizontalPadding(24.0),
              ),
              const SizedBox(width: 8),
              _MarginChip(
                label: 'Wide',
                value: 40.0,
                current: prefs.horizontalPadding,
                onTap: () => notifier.setHorizontalPadding(40.0),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
      );
}

class _FontChip extends StatelessWidget {
  const _FontChip({
    required this.label,
    required this.sample,
    required this.sampleStyle,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String sample;
  final TextStyle sampleStyle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: selected ? AppColors.primary.withAlpha(30) : AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected ? AppColors.primary : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                Text(
                  sample,
                  style: sampleStyle.copyWith(
                    fontSize: 15,
                    color: selected ? AppColors.primary : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: selected ? AppColors.primary : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _SpacingChip extends StatelessWidget {
  const _SpacingChip({
    required this.label,
    required this.value,
    required this.current,
    required this.onTap,
  });

  final String label;
  final double value;
  final double current;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final selected = (current - value).abs() < 0.01;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary.withAlpha(30) : AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? AppColors.primary : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              _SpacingIcon(lineHeight: value),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: selected ? AppColors.primary : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpacingIcon extends StatelessWidget {
  const _SpacingIcon({required this.lineHeight});
  final double lineHeight;

  @override
  Widget build(BuildContext context) {
    final gaps = ((lineHeight - 1.0) * 12).clamp(2.0, 10.0);
    return Column(
      children: [
        for (int i = 0; i < 3; i++) ...[
          Container(height: 2, width: 28, color: AppColors.textMuted,
              margin: EdgeInsets.symmetric(vertical: gaps / 2)),
        ],
      ],
    );
  }
}

class _MarginChip extends StatelessWidget {
  const _MarginChip({
    required this.label,
    required this.value,
    required this.current,
    required this.onTap,
  });

  final String label;
  final double value;
  final double current;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final selected = (current - value).abs() < 0.01;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary.withAlpha(30) : AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? AppColors.primary : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              _MarginIcon(margin: value),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: selected ? AppColors.primary : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MarginIcon extends StatelessWidget {
  const _MarginIcon({required this.margin});
  final double margin;

  @override
  Widget build(BuildContext context) {
    final innerWidth = (44 - margin * 0.6).clamp(10.0, 40.0);
    return SizedBox(
      width: 40,
      height: 24,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (int i = 0; i < 3; i++)
              Container(
                height: 2,
                width: innerWidth,
                color: AppColors.textMuted,
                margin: const EdgeInsets.symmetric(vertical: 2),
              ),
          ],
        ),
      ),
    );
  }
}

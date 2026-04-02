import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iwannareadthebiblemore/core/design_system/app_colors.dart';
import 'package:iwannareadthebiblemore/core/design_system/app_theme.dart';

void main() {
  group('AppTheme', () {
    test('dark theme brightness is dark', () {
      expect(AppTheme.dark().brightness, Brightness.dark);
    });

    test('dark theme scaffold background matches AppColors.background', () {
      expect(
        AppTheme.dark().scaffoldBackgroundColor,
        AppColors.background,
      );
    });

    test('light theme brightness is light', () {
      expect(AppTheme.light().brightness, Brightness.light);
    });

    test('primary colour is AppColors.primary in both themes', () {
      expect(AppTheme.dark().colorScheme.primary, AppColors.primary);
      expect(AppTheme.light().colorScheme.primary, AppColors.primary);
    });
  });
}

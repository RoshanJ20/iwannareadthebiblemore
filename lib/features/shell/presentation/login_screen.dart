import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../../../core/auth/auth_providers.dart';
import '../../../core/design_system/app_colors.dart';
import '../../../core/design_system/haptics_service.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🐑',
                  style: TextStyle(fontSize: 72)),
              const SizedBox(height: 16),
              const Text(
                'iwannareadthebiblemore',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Read daily. Build streaks. Go together.',
                style: TextStyle(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              _SignInButton(
                key: const Key('google_sign_in_button'),
                label: 'Continue with Google',
                onPressed: () async {
                  await HapticsService.medium();
                  try {
                    await ref.read(authRepositoryProvider).signInWithGoogle();
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Sign-in failed. Please try again.')),
                      );
                    }
                  }
                },
              ),
              const SizedBox(height: 12),
              _SignInButton(
                key: const Key('apple_sign_in_button'),
                label: 'Continue with Apple',
                onPressed: () async {
                  await HapticsService.medium();
                  try {
                    await ref.read(authRepositoryProvider).signInWithApple();
                  } on SignInWithAppleAuthorizationException catch (e) {
                    // User cancelled — not an error; no feedback needed
                    if (e.code == AuthorizationErrorCode.canceled) return;
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Sign-in failed. Please try again.')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Sign-in failed. Please try again.')),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SignInButton extends StatelessWidget {
  const _SignInButton({super.key, required this.label, required this.onPressed});

  final String label;
  final Future<void> Function() onPressed; // async — caller handles errors

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => onPressed(),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textPrimary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}

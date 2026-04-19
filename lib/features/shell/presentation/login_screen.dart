import 'package:flutter/foundation.dart' show kIsWeb;
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
      body: Stack(
        children: [
          // Warm radial glow from top-center
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.5),
                  radius: 0.9,
                  colors: [
                    AppColors.primary.withOpacity(0.10),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  // Mascot / logo
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          AppColors.primary.withOpacity(0.22),
                          AppColors.surface,
                        ],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.35),
                        width: 1.5,
                      ),
                    ),
                    child: const Center(
                      child: Text('🐑', style: TextStyle(fontSize: 46)),
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'iwannareadthebiblemore',
                    style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Read daily. Build streaks. Go together.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 15,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const Spacer(flex: 2),
                  _SignInButton(
                    key: const Key('google_sign_in_button'),
                    label: 'Continue with Google',
                    icon: Icons.g_mobiledata_rounded,
                    onPressed: () async {
                      await HapticsService.medium();
                      try {
                        await ref.read(authRepositoryProvider).signInWithGoogle();
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Sign-in failed. Please try again.')),
                          );
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  if (!kIsWeb)
                    _SignInButton(
                      key: const Key('apple_sign_in_button'),
                      label: 'Continue with Apple',
                      icon: Icons.apple,
                      onPressed: () async {
                        await HapticsService.medium();
                        try {
                          await ref.read(authRepositoryProvider).signInWithApple();
                        } on SignInWithAppleAuthorizationException catch (e) {
                          if (e.code == AuthorizationErrorCode.canceled) return;
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Sign-in failed. Please try again.')),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Sign-in failed. Please try again.')),
                            );
                          }
                        }
                      },
                    ),
                  if (kIsWeb) ...[
                    const SizedBox(height: 12),
                    _SignInButton(
                      key: const Key('guest_sign_in_button'),
                      label: 'Continue as Guest',
                      icon: Icons.person_outline_rounded,
                      onPressed: () async {
                        try {
                          await ref.read(authRepositoryProvider).signInAnonymously();
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Guest sign-in failed: $e')),
                            );
                          }
                        }
                      },
                    ),
                  ],
                  const SizedBox(height: 20),
                  Text(
                    'By continuing you agree to our Terms & Privacy Policy',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SignInButton extends StatelessWidget {
  const _SignInButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => onPressed(),
        icon: Icon(icon, size: 21),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: AppColors.textMuted.withOpacity(0.35)),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

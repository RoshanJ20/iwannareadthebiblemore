import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('iwannareadthebiblemore',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 32),
            // Full sign-in UI wired in Plan 6 (Onboarding).
            ElevatedButton(
              onPressed: () {}, // wired in onboarding plan
              child: const Text('Sign in with Google'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {},
              child: const Text('Sign in with Apple'),
            ),
          ],
        ),
      ),
    );
  }
}

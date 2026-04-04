import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/auth/auth_notifier.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authNotifierProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (user) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(user?.displayName ?? 'Anonymous',
                  style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 16),
              ElevatedButton(
                key: const Key('sign_out_button'),
                onPressed: () =>
                    ref.read(authNotifierProvider.notifier).signOut(),
                child: const Text('Sign out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

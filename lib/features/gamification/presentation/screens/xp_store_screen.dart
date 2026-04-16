import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/user_stats.dart';
import '../../domain/models/xp_store_item.dart';
import '../../gamification_providers.dart';

class XpStoreScreen extends ConsumerWidget {
  const XpStoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(userStatsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('XP Store')),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (stats) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.star, color: Color(0xFFFFD700)),
                  const SizedBox(width: 8),
                  Text(
                    '${stats.xpBalance} XP available',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: kXpStoreItems.length,
                itemBuilder: (context, i) {
                  final item = kXpStoreItems[i];
                  final canAfford = stats.xpBalance >= item.cost;
                  return ListTile(
                    leading: Text(
                      item.emoji,
                      style: const TextStyle(fontSize: 32),
                    ),
                    title: Text(item.name),
                    subtitle: Text('${item.cost} XP'),
                    trailing: ElevatedButton(
                      onPressed: canAfford
                          ? () => _confirmPurchase(context, ref, item, stats)
                          : null,
                      child: const Text('Buy'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmPurchase(
    BuildContext context,
    WidgetRef ref,
    XpStoreItem item,
    UserStats stats,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Buy ${item.name}?'),
        content: Text(
          'This will cost ${item.cost} XP. You have ${stats.xpBalance} XP.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await FirebaseFunctions.instance
                    .httpsCallable('xpStorePurchase')
                    .call({'itemId': item.id});
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${item.name} purchased!')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Purchase failed: $e')),
                  );
                }
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}

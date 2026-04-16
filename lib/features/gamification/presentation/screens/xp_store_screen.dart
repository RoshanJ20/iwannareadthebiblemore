import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/auth/auth_notifier.dart';
import '../../../../core/design_system/app_colors.dart';
import '../providers/gamification_providers.dart';
import '../widgets/xp_store_item_tile.dart';

class XpStoreScreen extends ConsumerWidget {
  const XpStoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authNotifierProvider);
    final storeItems = ref.watch(xpStoreItemsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('XP Store'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
      ),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: AppColors.error))),
        data: (user) {
          if (user == null) {
            return const Center(
              child: Text('Sign in to use the XP Store',
                  style: TextStyle(color: AppColors.textSecondary)),
            );
          }

          final statsAsync = ref.watch(userStatsProvider(user.uid));

          return statsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: AppColors.error))),
            data: (stats) {
              return Column(
                children: [
                  _BalanceHeader(xpBalance: stats.xpBalance),
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.75,
                      ),
                      itemCount: storeItems.length,
                      itemBuilder: (context, index) {
                        final item = storeItems[index];
                        final canAfford = stats.xpBalance >= item.xpCost;
                        return XpStoreItemTile(
                          item: item,
                          canAfford: canAfford,
                          onBuy: () => _handlePurchase(context, ref, item.id, item.name),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _handlePurchase(
    BuildContext context,
    WidgetRef ref,
    String itemId,
    String itemName,
  ) async {
    final service = ref.read(xpStoreServiceProvider);
    try {
      await service.purchaseItem(itemId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$itemName purchased!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Purchase failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

class _BalanceHeader extends StatelessWidget {
  const _BalanceHeader({required this.xpBalance});

  final int xpBalance;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      child: Row(
        children: [
          const Icon(Icons.monetization_on, color: AppColors.xpGold, size: 24),
          const SizedBox(width: 8),
          Text(
            'Your balance: ${_formatBalance(xpBalance)} XP',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatBalance(int xp) {
    if (xp >= 1000) {
      final formatted = xp.toString();
      final intPart = formatted.length > 3
          ? formatted.substring(0, formatted.length - 3)
          : '0';
      final decPart = formatted.substring(formatted.length - 3);
      return '$intPart,$decPart';
    }
    return xp.toString();
  }
}

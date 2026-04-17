import 'package:flutter/material.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../domain/entities/xp_store_item.dart';

class XpStoreItemTile extends StatelessWidget {
  const XpStoreItemTile({
    super.key,
    required this.item,
    required this.canAfford,
    required this.onBuy,
  });

  final XpStoreItem item;
  final bool canAfford;
  final VoidCallback onBuy;

  String get _rarityLabel {
    switch (item.rarity) {
      case XpItemRarity.common:
        return 'Common';
      case XpItemRarity.basic:
        return 'Basic';
      case XpItemRarity.rare:
        return 'Rare';
      case XpItemRarity.legendary:
        return 'Legendary';
    }
  }

  Color get _rarityColor {
    switch (item.rarity) {
      case XpItemRarity.common:
        return AppColors.textSecondary;
      case XpItemRarity.basic:
        return AppColors.success;
      case XpItemRarity.rare:
        return AppColors.streakDiamond;
      case XpItemRarity.legendary:
        return AppColors.streakGold;
    }
  }

  String get _typeEmoji {
    switch (item.itemType) {
      case XpItemType.freeze:
        return '🧊';
      case XpItemType.mascotOutfit:
        return '👗';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _rarityColor.withOpacity(0.3),
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(_typeEmoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(height: 8),
          Text(
            item.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _rarityLabel,
            style: TextStyle(color: _rarityColor, fontSize: 11),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.monetization_on, size: 14, color: AppColors.xpGold),
              const SizedBox(width: 2),
              Text(
                '${item.xpCost}',
                style: const TextStyle(
                  color: AppColors.xpGold,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: canAfford ? onBuy : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: canAfford ? AppColors.primary : AppColors.surfaceElevated,
                foregroundColor: canAfford ? Colors.white : AppColors.textMuted,
                padding: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Buy', style: TextStyle(fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }
}

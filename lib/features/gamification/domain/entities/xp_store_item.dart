enum XpItemType { freeze, mascotOutfit }

enum XpItemRarity { common, basic, rare, legendary }

class XpStoreItem {
  const XpStoreItem({
    required this.id,
    required this.name,
    required this.xpCost,
    required this.itemType,
    required this.rarity,
  });

  final String id;
  final String name;
  final int xpCost;
  final XpItemType itemType;
  final XpItemRarity rarity;
}

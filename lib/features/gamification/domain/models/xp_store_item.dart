class XpStoreItem {
  final String id;
  final String name;
  final int cost;
  final String category; // 'freeze' | 'outfit_basic' | 'outfit_rare' | 'outfit_legendary'
  final String emoji;

  const XpStoreItem({
    required this.id,
    required this.name,
    required this.cost,
    required this.category,
    required this.emoji,
  });
}

const kXpStoreItems = [
  XpStoreItem(id: 'freeze_1', name: 'Streak Freeze', cost: 200, category: 'freeze', emoji: '🧊'),
  XpStoreItem(id: 'outfit_basic_1', name: 'Wool Scarf', cost: 500, category: 'outfit_basic', emoji: '🧣'),
  XpStoreItem(id: 'outfit_basic_2', name: 'Flower Crown', cost: 500, category: 'outfit_basic', emoji: '🌸'),
  XpStoreItem(id: 'outfit_basic_3', name: 'Bow Tie', cost: 500, category: 'outfit_basic', emoji: '🎀'),
  XpStoreItem(id: 'outfit_rare_1', name: 'Angel Wings', cost: 1000, category: 'outfit_rare', emoji: '👼'),
  XpStoreItem(id: 'outfit_rare_2', name: 'Rainbow Blanket', cost: 1000, category: 'outfit_rare', emoji: '🌈'),
  XpStoreItem(id: 'outfit_rare_3', name: 'Golden Bell', cost: 1000, category: 'outfit_rare', emoji: '🔔'),
  XpStoreItem(id: 'outfit_legendary_1', name: 'Crown of Stars', cost: 2000, category: 'outfit_legendary', emoji: '⭐'),
  XpStoreItem(id: 'outfit_legendary_2', name: 'Shepherd Staff', cost: 2000, category: 'outfit_legendary', emoji: '🪄'),
];

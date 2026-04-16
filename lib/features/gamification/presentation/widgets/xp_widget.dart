import 'package:flutter/material.dart';

class XpWidget extends StatelessWidget {
  final int xpBalance;
  final int xpTotal;
  const XpWidget({super.key, required this.xpBalance, required this.xpTotal});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.star, color: Color(0xFFFFD700), size: 16),
            const SizedBox(width: 4),
            TweenAnimationBuilder<int>(
              tween: IntTween(begin: 0, end: xpBalance),
              duration: const Duration(milliseconds: 600),
              builder: (_, val, __) => Text(
                '$val XP',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: const Color(0xFFFFD700),
                    ),
              ),
            ),
          ],
        ),
        Text(
          '$xpTotal total XP',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

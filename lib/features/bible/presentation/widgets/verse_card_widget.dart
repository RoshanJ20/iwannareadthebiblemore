import 'package:flutter/material.dart';
import '../../domain/models/bible_verse.dart';
import '../services/verse_sharing_service.dart';

class VerseCardWidget extends StatelessWidget {
  final BibleVerse verse;
  final String reference;
  final VerseCardBackground background;
  const VerseCardWidget({
    super.key,
    required this.verse,
    required this.reference,
    this.background = VerseCardBackground.dark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 360,
      height: 640,
      decoration: BoxDecoration(
        color: background == VerseCardBackground.light
            ? Colors.white
            : background == VerseCardBackground.dark
                ? const Color(0xFF1A1A2E)
                : null,
        gradient: background == VerseCardBackground.gradient
            ? const LinearGradient(
                colors: [Color(0xFF1A1A2E), Color(0xFF6C63FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
      ),
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '"${verse.text}"',
            style: TextStyle(
              fontSize: 22,
              color: background == VerseCardBackground.light ? Colors.black : Colors.white,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '— $reference',
            style: TextStyle(
              fontSize: 16,
              color: background == VerseCardBackground.light ? Colors.black54 : Colors.white70,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'iwannareadthebiblemore',
            style: TextStyle(
              fontSize: 12,
              color: background == VerseCardBackground.light ? Colors.black38 : Colors.white38,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

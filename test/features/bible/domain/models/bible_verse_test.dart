import 'package:flutter_test/flutter_test.dart';
import 'package:iwannareadthebiblemore/features/bible/domain/models/bible_verse.dart';

void main() {
  test('BibleVerse can be constructed', () {
    expect(
      () => const BibleVerse(number: 1, text: 'In the beginning'),
      returnsNormally,
    );
  });
}

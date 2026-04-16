import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iwannareadthebiblemore/features/bible/bible_providers.dart';

void main() {
  test('bookListProvider returns 66 books', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final books = container.read(bookListProvider);
    expect(books.length, 66);
    expect(books.first.id, 'GEN');
    expect(books.last.id, 'REV');
  });
}

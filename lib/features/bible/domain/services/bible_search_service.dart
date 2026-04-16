import '../models/bible_book.dart';
import '../models/bible_verse.dart';
import '../repositories/bible_repository.dart';

class SearchResult {
  final BibleBook book;
  final int chapterNumber;
  final BibleVerse verse;
  const SearchResult({
    required this.book,
    required this.chapterNumber,
    required this.verse,
  });
}

class BibleSearchService {
  final BibleRepository _repo;
  const BibleSearchService(this._repo);

  /// Searches chapter 1 of each book for verses containing [query].
  /// Only searches cached chapters to avoid excessive loading.
  Future<List<SearchResult>> search(String query, {int maxResults = 50}) async {
    if (query.trim().length < 3) return [];
    final results = <SearchResult>[];
    final books = _repo.getBooks();
    for (final book in books) {
      try {
        final chapter = await _repo.getChapter(book.id, 1);
        for (final verse in chapter.verses) {
          if (verse.text.toLowerCase().contains(query.toLowerCase())) {
            results.add(SearchResult(book: book, chapterNumber: 1, verse: verse));
            if (results.length >= maxResults) return results;
          }
        }
      } catch (_) {
        continue;
      }
    }
    return results;
  }
}

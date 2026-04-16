# Bible Content Feature — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the full Bible reading experience — offline KJV/WEB, API.Bible with Hive caching, chapter reader with verse interactions (highlight, note, share), search, and bookmarks.

**Architecture:** Feature-first clean architecture under lib/features/bible/. BibleRepository interface with two implementations: LocalBibleRepository (bundled JSON assets) and ApiBibleRepository (HTTP + Hive cache). Annotations stored in Firestore with optimistic Hive write-through. Riverpod providers expose book lists, chapter content, and annotations as streams.

**Tech Stack:** Flutter/Dart, Riverpod, Hive, http, Firestore (annotations), share_plus

---

## Task 1: Bible domain models & repository interfaces

**Files:**
- Create: `lib/features/bible/domain/models/bible_book.dart`
- Create: `lib/features/bible/domain/models/bible_chapter.dart`
- Create: `lib/features/bible/domain/models/bible_verse.dart`
- Create: `lib/features/bible/domain/models/annotation.dart`
- Create: `lib/features/bible/domain/repositories/bible_repository.dart`
- Create: `lib/features/bible/domain/repositories/annotation_repository.dart`
- Test: `test/features/bible/domain/models/bible_verse_test.dart`

Models:
```dart
// bible_verse.dart
class BibleVerse {
  final int number;
  final String text;
  const BibleVerse({required this.number, required this.text});
}

// bible_chapter.dart
class BibleChapter {
  final int number;
  final List<BibleVerse> verses;
  const BibleChapter({required this.number, required this.verses});
}

// bible_book.dart
class BibleBook {
  final String id; // e.g. 'GEN'
  final String name; // e.g. 'Genesis'
  final int chapterCount;
  const BibleBook({required this.id, required this.name, required this.chapterCount});
}

// annotation.dart
enum AnnotationType { highlight, note }
class Annotation {
  final String id;
  final String bookId;
  final int chapterId;
  final int verseNumber;
  final AnnotationType type;
  final String? color; // hex string, for highlights
  final String? text;  // for notes
  const Annotation({required this.id, required this.bookId, required this.chapterId, required this.verseNumber, required this.type, this.color, this.text});
}

// bible_repository.dart
abstract class BibleRepository {
  List<BibleBook> getBooks();
  Future<BibleChapter> getChapter(String bookId, int chapterNumber);
}

// annotation_repository.dart
abstract class AnnotationRepository {
  Stream<List<Annotation>> watchAnnotations(String bookId, int chapterId);
  Future<void> saveAnnotation(Annotation annotation);
  Future<void> deleteAnnotation(String annotationId);
}
```

Steps:
- [ ] Write failing test: `expect(() => BibleVerse(number: 1, text: 'In the beginning'), returnsNormally)`
- [ ] Run: `flutter test test/features/bible/domain/models/bible_verse_test.dart` — expect FAIL (file not found)
- [ ] Create all model and interface files with code above
- [ ] Run: `flutter test test/features/bible/domain/models/bible_verse_test.dart` — expect PASS
- [ ] `git add lib/features/bible/domain test/features/bible/domain && git commit -m "feat(bible): add domain models and repository interfaces"`

---

## Task 2: Bundled KJV/WEB asset structure & LocalBibleRepository

**Files:**
- Create: `assets/bible/kjv/genesis.json` (fixture — first 3 verses only)
- Create: `assets/bible/web/genesis.json` (fixture)
- Modify: `pubspec.yaml` — add `assets/bible/kjv/` and `assets/bible/web/` asset directories
- Create: `lib/features/bible/data/local_bible_repository.dart`
- Create: `lib/core/bible_content/bible_book_list.dart` (canonical list of all 66 books with chapter counts)
- Test: `test/features/bible/data/local_bible_repository_test.dart`

JSON format:
```json
{"book": "Genesis", "bookId": "GEN", "chapters": [{"chapter": 1, "verses": [{"verse": 1, "text": "In the beginning God created the heaven and the earth."}, {"verse": 2, "text": "And the earth was without form, and void..."}, {"verse": 3, "text": "And God said, Let there be light: and there was light."}]}]}
```

Implementation:
```dart
class LocalBibleRepository implements BibleRepository {
  final String _translation; // 'kjv' or 'web'
  LocalBibleRepository(this._translation);

  @override
  List<BibleBook> getBooks() => BibleBookList.all;

  @override
  Future<BibleChapter> getChapter(String bookId, int chapterNumber) async {
    final bookFileName = bookId.toLowerCase();
    final jsonStr = await rootBundle.loadString('assets/bible/$_translation/$bookFileName.json');
    final data = json.decode(jsonStr) as Map<String, dynamic>;
    final chapters = data['chapters'] as List;
    final chapterData = chapters.firstWhere((c) => c['chapter'] == chapterNumber);
    final verses = (chapterData['verses'] as List)
        .map((v) => BibleVerse(number: v['verse'] as int, text: v['text'] as String))
        .toList();
    return BibleChapter(number: chapterNumber, verses: verses);
  }
}
```

Steps:
- [ ] Write failing test: load Genesis chapter 1 from local repo, expect 3 verses in fixture
- [ ] Run test — expect FAIL
- [ ] Create fixture JSON files and LocalBibleRepository
- [ ] Run test — expect PASS
- [ ] `git commit -m "feat(bible): add local KJV/WEB repository with asset fixture"`

---

## Task 3: API.Bible HTTP client with Hive caching

**Files:**
- Create: `lib/features/bible/data/api_bible_repository.dart`
- Create: `lib/features/bible/data/bible_hive_cache.dart`
- Test: `test/features/bible/data/api_bible_repository_test.dart`

```dart
// bible_hive_cache.dart
class BibleHiveCache {
  static const _boxName = 'bible_cache';
  Future<Box> _openBox() => Hive.openBox(_boxName);

  Future<BibleChapter?> getChapter(String key) async {
    final box = await _openBox();
    final raw = box.get(key);
    if (raw == null) return null;
    // deserialize from stored map
    final verses = (raw['verses'] as List).map((v) => BibleVerse(number: v['n'], text: v['t'])).toList();
    return BibleChapter(number: raw['num'], verses: verses);
  }

  Future<void> putChapter(String key, BibleChapter chapter) async {
    final box = await _openBox();
    await box.put(key, {'num': chapter.number, 'verses': chapter.verses.map((v) => {'n': v.number, 't': v.text}).toList()});
  }
}

// api_bible_repository.dart
const String _apiBibleKey = String.fromEnvironment('API_BIBLE_KEY', defaultValue: '');

class ApiBibleRepository implements BibleRepository {
  final http.Client _client;
  final BibleHiveCache _cache;
  ApiBibleRepository({http.Client? client, BibleHiveCache? cache})
      : _client = client ?? http.Client(),
        _cache = cache ?? BibleHiveCache();

  @override
  List<BibleBook> getBooks() => BibleBookList.all;

  @override
  Future<BibleChapter> getChapter(String bookId, int chapterNumber) async {
    final cacheKey = 'apibible_${bookId}_$chapterNumber';
    final cached = await _cache.getChapter(cacheKey);
    if (cached != null) return cached;
    // fetch from API.Bible
    final bibleId = 'de4e12af7f28f599-02'; // KJV on API.Bible
    final chapterId = '$bookId.$chapterNumber';
    final uri = Uri.parse('https://api.scripture.api.bible/v1/bibles/$bibleId/chapters/$chapterId?content-type=json&include-notes=false&include-titles=false&include-chapter-numbers=false&include-verse-numbers=true');
    final response = await _client.get(uri, headers: {'api-key': _apiBibleKey});
    if (response.statusCode != 200) throw Exception('API.Bible error: ${response.statusCode}');
    // parse response and cache
    final chapter = _parseResponse(json.decode(response.body), chapterNumber);
    await _cache.putChapter(cacheKey, chapter);
    return chapter;
  }

  BibleChapter _parseResponse(Map<String, dynamic> body, int chapterNumber) {
    // API.Bible returns content as HTML-like or JSON — parse verses
    final data = body['data'] as Map<String, dynamic>;
    final content = data['content'] as List;
    final verses = <BibleVerse>[];
    for (final item in content) {
      if (item['type'] == 'verse') {
        final verseNum = int.parse(item['number'].toString());
        final text = (item['items'] as List).map((i) => i['text'] ?? '').join(' ');
        verses.add(BibleVerse(number: verseNum, text: text.trim()));
      }
    }
    return BibleChapter(number: chapterNumber, verses: verses);
  }
}
```

Steps:
- [ ] Write failing test using MockHttpClient (mocktail), mock 200 response with sample JSON, verify chapter parsed
- [ ] Run — FAIL
- [ ] Implement ApiBibleRepository + BibleHiveCache
- [ ] Run — PASS
- [ ] `git commit -m "feat(bible): add API.Bible HTTP repository with Hive cache"`

---

## Task 4: Firestore annotation repository

**Files:**
- Create: `lib/features/bible/data/firestore_annotation_repository.dart`
- Test: `test/features/bible/data/firestore_annotation_repository_test.dart`

```dart
class FirestoreAnnotationRepository implements AnnotationRepository {
  final FirebaseFirestore _db;
  final String _userId;
  FirestoreAnnotationRepository(this._db, this._userId);

  CollectionReference get _col => _db.collection('users').doc(_userId).collection('annotations');

  @override
  Stream<List<Annotation>> watchAnnotations(String bookId, int chapterId) {
    return _col
        .where('bookId', isEqualTo: bookId)
        .where('chapterId', isEqualTo: chapterId)
        .snapshots()
        .map((snap) => snap.docs.map((d) => _fromDoc(d)).toList());
  }

  @override
  Future<void> saveAnnotation(Annotation annotation) async {
    await _col.doc(annotation.id).set({
      'bookId': annotation.bookId,
      'chapterId': annotation.chapterId,
      'verseNumber': annotation.verseNumber,
      'type': annotation.type.name,
      'color': annotation.color,
      'text': annotation.text,
    });
  }

  @override
  Future<void> deleteAnnotation(String annotationId) => _col.doc(annotationId).delete();

  Annotation _fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Annotation(
      id: doc.id,
      bookId: d['bookId'] as String,
      chapterId: d['chapterId'] as int,
      verseNumber: d['verseNumber'] as int,
      type: AnnotationType.values.byName(d['type'] as String),
      color: d['color'] as String?,
      text: d['text'] as String?,
    );
  }
}
```

Steps:
- [ ] Write failing test using FakeFirebaseFirestore: save annotation, watch, verify it appears
- [ ] Run — FAIL
- [ ] Implement
- [ ] Run — PASS
- [ ] `git commit -m "feat(bible): add Firestore annotation repository"`

---

## Task 5: Riverpod providers

**Files:**
- Create: `lib/features/bible/bible_providers.dart`
- Test: `test/features/bible/bible_providers_test.dart`

```dart
// bible_providers.dart
final currentTranslationProvider = StateProvider<String>((ref) => 'kjv');

final bibleRepositoryProvider = Provider<BibleRepository>((ref) {
  final translation = ref.watch(currentTranslationProvider);
  if (translation == 'kjv' || translation == 'web') {
    return LocalBibleRepository(translation);
  }
  return ApiBibleRepository();
});

final annotationRepositoryProvider = Provider<AnnotationRepository>((ref) {
  final user = ref.watch(authNotifierProvider).valueOrNull;
  if (user == null) throw StateError('No authenticated user');
  return FirestoreAnnotationRepository(FirebaseFirestore.instance, user.uid);
});

final bookListProvider = Provider<List<BibleBook>>((ref) {
  return ref.watch(bibleRepositoryProvider).getBooks();
});

@riverpod
Future<BibleChapter> chapter(ChapterRef ref, String bookId, int chapterNumber) async {
  return ref.watch(bibleRepositoryProvider).getChapter(bookId, chapterNumber);
}

final annotationsProvider = StreamProvider.family<List<Annotation>, ({String bookId, int chapterId})>((ref, args) {
  return ref.watch(annotationRepositoryProvider).watchAnnotations(args.bookId, args.chapterId);
});
```

Steps:
- [ ] Write failing test: bookListProvider returns non-empty list
- [ ] Run — FAIL
- [ ] Implement providers
- [ ] Run — PASS
- [ ] `git commit -m "feat(bible): add Riverpod providers for bible content"`

---

## Task 6: Bible browser screen (BookList → ChapterList)

**Files:**
- Modify: `lib/features/bible/presentation/screens/bible_screen.dart` (replace placeholder)
- Create: `lib/features/bible/presentation/screens/chapter_list_screen.dart`
- Test: `test/features/bible/presentation/bible_screen_test.dart`

```dart
// bible_screen.dart — BookListScreen
class BibleScreen extends ConsumerWidget {
  const BibleScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final books = ref.watch(bookListProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Bible')),
      body: ListView.builder(
        itemCount: books.length,
        itemBuilder: (context, i) {
          final book = books[i];
          return ListTile(
            title: Text(book.name),
            subtitle: Text('${book.chapterCount} chapters'),
            onTap: () => context.push('/bible/${book.id}'),
          );
        },
      ),
    );
  }
}

// chapter_list_screen.dart
class ChapterListScreen extends ConsumerWidget {
  final String bookId;
  const ChapterListScreen({super.key, required this.bookId});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final books = ref.watch(bookListProvider);
    final book = books.firstWhere((b) => b.id == bookId);
    return Scaffold(
      appBar: AppBar(title: Text(book.name)),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5, crossAxisSpacing: 8, mainAxisSpacing: 8),
        itemCount: book.chapterCount,
        itemBuilder: (context, i) => InkWell(
          onTap: () => context.push('/bible/${book.id}/${i + 1}'),
          child: Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Theme.of(context).colorScheme.surfaceVariant),
            alignment: Alignment.center,
            child: Text('${i + 1}'),
          ),
        ),
      ),
    );
  }
}
```

Add routes to `lib/core/navigation/routes.dart` and `app_router.dart`:
- `/bible/:bookId` → ChapterListScreen
- `/bible/:bookId/:chapterNumber` → ChapterReaderScreen (stub for now, Task 7)

Steps:
- [ ] Write widget test: BibleScreen shows list of books
- [ ] Run — FAIL
- [ ] Implement BibleScreen, ChapterListScreen
- [ ] Add routes to app_router
- [ ] Run — PASS
- [ ] `git commit -m "feat(bible): add bible browser (book list + chapter list screens)"`

---

## Task 7: Chapter reader screen

**Files:**
- Create: `lib/features/bible/presentation/screens/chapter_reader_screen.dart`
- Create: `lib/features/bible/presentation/widgets/verse_action_sheet.dart`
- Test: `test/features/bible/presentation/chapter_reader_screen_test.dart`

```dart
// chapter_reader_screen.dart
class ChapterReaderScreen extends ConsumerWidget {
  final String bookId;
  final int chapterNumber;
  const ChapterReaderScreen({super.key, required this.bookId, required this.chapterNumber});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chapterAsync = ref.watch(chapterProvider(bookId, chapterNumber));
    return Scaffold(
      appBar: AppBar(title: Text('$bookId $chapterNumber')),
      body: chapterAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (chapter) => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: chapter.verses.length,
          itemBuilder: (context, i) {
            final verse = chapter.verses[i];
            return GestureDetector(
              onLongPress: () async {
                await HapticsService.medium();
                if (!context.mounted) return;
                showModalBottomSheet(
                  context: context,
                  builder: (_) => VerseActionSheet(bookId: bookId, chapterId: chapterNumber, verse: verse),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: RichText(
                  text: TextSpan(children: [
                    TextSpan(text: '${verse.number} ', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.primary)),
                    TextSpan(text: verse.text, style: Theme.of(context).textTheme.bodyLarge),
                  ]),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// verse_action_sheet.dart
class VerseActionSheet extends StatelessWidget {
  final String bookId;
  final int chapterId;
  final BibleVerse verse;
  const VerseActionSheet({super.key, required this.bookId, required this.chapterId, required this.verse});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(leading: const Icon(Icons.highlight), title: const Text('Highlight'), onTap: () { Navigator.pop(context); _showHighlightPicker(context); }),
        ListTile(leading: const Icon(Icons.note_add), title: const Text('Add Note'), onTap: () { Navigator.pop(context); _showNoteSheet(context); }),
        ListTile(leading: const Icon(Icons.share), title: const Text('Share Verse'), onTap: () { Navigator.pop(context); _shareVerse(context); }),
        ListTile(leading: const Icon(Icons.close), title: const Text('Close'), onTap: () => Navigator.pop(context)),
      ]),
    );
  }

  void _showHighlightPicker(BuildContext context) { /* Task 8 */ }
  void _showNoteSheet(BuildContext context) { /* Task 8 */ }
  void _shareVerse(BuildContext context) { /* Task 9 */ }
}
```

Steps:
- [ ] Write test: ChapterReaderScreen renders verse text from mock chapter provider
- [ ] Run — FAIL
- [ ] Implement ChapterReaderScreen + VerseActionSheet
- [ ] Run — PASS
- [ ] `git commit -m "feat(bible): add chapter reader with verse long-press action sheet"`

---

## Task 8: Highlight & note flow

**Files:**
- Create: `lib/features/bible/presentation/widgets/highlight_picker.dart`
- Create: `lib/features/bible/presentation/widgets/note_sheet.dart`
- Modify: `lib/features/bible/presentation/widgets/verse_action_sheet.dart` — fill in _showHighlightPicker and _showNoteSheet
- Test: `test/features/bible/presentation/highlight_picker_test.dart`

```dart
// highlight_picker.dart
const _highlightColors = ['#FFD700', '#90EE90', '#87CEEB', '#FFB6C1', '#DDA0DD'];

class HighlightPicker extends ConsumerWidget {
  final String bookId;
  final int chapterId;
  final BibleVerse verse;
  const HighlightPicker({super.key, required this.bookId, required this.chapterId, required this.verse});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Choose a highlight color'),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _highlightColors.map((color) => GestureDetector(
              onTap: () async {
                await HapticsService.light();
                final annotation = Annotation(
                  id: const Uuid().v4(),
                  bookId: bookId, chapterId: chapterId,
                  verseNumber: verse.number,
                  type: AnnotationType.highlight, color: color,
                );
                await ref.read(annotationRepositoryProvider).saveAnnotation(annotation);
                if (context.mounted) Navigator.pop(context);
              },
              child: Container(width: 40, height: 40, decoration: BoxDecoration(color: Color(int.parse(color.replaceFirst('#', '0xFF'))), shape: BoxShape.circle)),
            )).toList(),
          ),
        ]),
      ),
    );
  }
}

// note_sheet.dart
class NoteSheet extends ConsumerStatefulWidget {
  final String bookId;
  final int chapterId;
  final BibleVerse verse;
  const NoteSheet({super.key, required this.bookId, required this.chapterId, required this.verse});
  @override ConsumerState<NoteSheet> createState() => _NoteSheetState();
}
class _NoteSheetState extends ConsumerState<NoteSheet> {
  final _controller = TextEditingController();
  @override void dispose() { _controller.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 16),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('Note on ${widget.bookId} ${widget.chapterId}:${widget.verse.number}', style: Theme.of(context).textTheme.titleSmall),
        TextField(controller: _controller, autofocus: true, maxLines: 4, decoration: const InputDecoration(hintText: 'Write your note...')),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () async {
            if (_controller.text.trim().isEmpty) return;
            final annotation = Annotation(id: const Uuid().v4(), bookId: widget.bookId, chapterId: widget.chapterId, verseNumber: widget.verse.number, type: AnnotationType.note, text: _controller.text.trim());
            await ref.read(annotationRepositoryProvider).saveAnnotation(annotation);
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('Save Note'),
        ),
      ]),
    );
  }
}
```

Note: add `uuid: ^4.0.0` to pubspec.yaml if not already present.

Steps:
- [ ] Write test: HighlightPicker shows 5 color circles
- [ ] Run — FAIL
- [ ] Implement HighlightPicker, NoteSheet; wire into VerseActionSheet
- [ ] Run — PASS
- [ ] `git commit -m "feat(bible): add highlight color picker and note sheet"`

---

## Task 9: Verse sharing

**Files:**
- Create: `lib/features/bible/presentation/services/verse_sharing_service.dart`
- Modify: `verse_action_sheet.dart` — fill in _shareVerse
- Test: `test/features/bible/presentation/services/verse_sharing_service_test.dart`

```dart
// verse_sharing_service.dart
enum VerseCardBackground { light, dark, gradient }

class VerseSharingService {
  static Future<void> shareVerse({
    required BuildContext context,
    required BibleVerse verse,
    required String reference, // e.g. "Genesis 1:1"
    required GlobalKey repaintKey,
    VerseCardBackground background = VerseCardBackground.dark,
  }) async {
    final boundary = repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();
    final tempDir = await getTemporaryDirectory();
    final file = await File('${tempDir.path}/verse_card.png').writeAsBytes(bytes);
    await Share.shareXFiles([XFile(file.path)], text: '"${verse.text}" — $reference\n\niwannareadthebiblemore');
  }
}

// verse_card_widget.dart — the widget captured by RepaintBoundary
class VerseCardWidget extends StatelessWidget {
  final BibleVerse verse;
  final String reference;
  final VerseCardBackground background;
  const VerseCardWidget({super.key, required this.verse, required this.reference, required this.background});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 360, height: 640, // 9:16 aspect
      decoration: BoxDecoration(
        color: background == VerseCardBackground.light ? Colors.white : background == VerseCardBackground.dark ? const Color(0xFF1A1A2E) : null,
        gradient: background == VerseCardBackground.gradient ? const LinearGradient(colors: [Color(0xFF1A1A2E), Color(0xFF6C63FF)], begin: Alignment.topLeft, end: Alignment.bottomRight) : null,
      ),
      padding: const EdgeInsets.all(40),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text('"${verse.text}"', style: TextStyle(fontSize: 22, color: background == VerseCardBackground.light ? Colors.black : Colors.white, fontStyle: FontStyle.italic)),
        const SizedBox(height: 16),
        Text('— $reference', style: TextStyle(fontSize: 16, color: background == VerseCardBackground.light ? Colors.black54 : Colors.white70)),
        const SizedBox(height: 32),
        Text('iwannareadthebiblemore', style: TextStyle(fontSize: 12, color: background == VerseCardBackground.light ? Colors.black38 : Colors.white38, letterSpacing: 1.5)),
      ]),
    );
  }
}
```

Add `path_provider: ^2.1.0` to pubspec if not present.

Steps:
- [ ] Write test: VerseCardWidget builds without error with all 3 background options
- [ ] Run — FAIL
- [ ] Implement VerseSharingService + VerseCardWidget; wire into VerseActionSheet
- [ ] Run — PASS
- [ ] `git commit -m "feat(bible): add verse image sharing with 3 background options"`

---

## Task 10: Search screen

**Files:**
- Create: `lib/features/bible/presentation/screens/bible_search_screen.dart`
- Create: `lib/features/bible/domain/services/bible_search_service.dart`
- Test: `test/features/bible/domain/services/bible_search_service_test.dart`

```dart
// bible_search_service.dart
class BibleSearchService {
  final BibleRepository _repo;
  BibleSearchService(this._repo);

  /// Searches across loaded chapters for verses containing [query].
  /// Only searches books where chapters are cached — not a full-Bible search to avoid excessive loading.
  /// For a real implementation, consider a pre-built search index.
  Future<List<SearchResult>> search(String query, {int maxResults = 50}) async {
    if (query.trim().length < 3) return [];
    final results = <SearchResult>[];
    final books = _repo.getBooks();
    for (final book in books) {
      // Only search chapter 1 of each book for demo; real implementation would index all cached chapters
      try {
        final chapter = await _repo.getChapter(book.id, 1);
        for (final verse in chapter.verses) {
          if (verse.text.toLowerCase().contains(query.toLowerCase())) {
            results.add(SearchResult(book: book, chapterNumber: 1, verse: verse));
            if (results.length >= maxResults) return results;
          }
        }
      } catch (_) { continue; } // skip books not yet cached
    }
    return results;
  }
}

class SearchResult {
  final BibleBook book;
  final int chapterNumber;
  final BibleVerse verse;
  const SearchResult({required this.book, required this.chapterNumber, required this.verse});
}

// bible_search_screen.dart
class BibleSearchScreen extends ConsumerStatefulWidget {
  const BibleSearchScreen({super.key});
  @override ConsumerState<BibleSearchScreen> createState() => _BibleSearchScreenState();
}
class _BibleSearchScreenState extends ConsumerState<BibleSearchScreen> {
  final _controller = TextEditingController();
  List<SearchResult> _results = [];
  Timer? _debounce;

  @override void dispose() { _controller.dispose(); _debounce?.cancel(); super.dispose(); }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      final service = BibleSearchService(ref.read(bibleRepositoryProvider));
      final results = await service.search(value);
      if (mounted) setState(() => _results = results);
    });
  }

  @override Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: TextField(controller: _controller, autofocus: true, onChanged: _onChanged, decoration: const InputDecoration(hintText: 'Search the Bible...', border: InputBorder.none))),
      body: ListView.builder(
        itemCount: _results.length,
        itemBuilder: (context, i) {
          final r = _results[i];
          return ListTile(
            title: Text(r.verse.text, maxLines: 2, overflow: TextOverflow.ellipsis),
            subtitle: Text('${r.book.name} ${r.chapterNumber}:${r.verse.number}'),
            onTap: () => context.push('/bible/${r.book.id}/${r.chapterNumber}'),
          );
        },
      ),
    );
  }
}
```

Add route `/bible/search` → BibleSearchScreen to app_router. Add search icon to BibleScreen AppBar.

Steps:
- [ ] Write test: BibleSearchService returns results for query "light" from fixture data
- [ ] Run — FAIL
- [ ] Implement
- [ ] Run — PASS
- [ ] `git commit -m "feat(bible): add bible search screen with debounced query"`

---

## Task 11: Bookmarks

**Files:**
- Create: `lib/features/bible/data/bookmark_repository.dart`
- Create: `lib/features/bible/presentation/screens/bookmarks_screen.dart`
- Test: `test/features/bible/data/bookmark_repository_test.dart`

```dart
// bookmark_repository.dart
class Bookmark {
  final String bookId;
  final int chapterNumber;
  final int verseNumber;
  final String verseText;
  final String reference;
  Bookmark({required this.bookId, required this.chapterNumber, required this.verseNumber, required this.verseText, required this.reference});
  Map<String, dynamic> toMap() => {'bookId': bookId, 'chapterNumber': chapterNumber, 'verseNumber': verseNumber, 'verseText': verseText, 'reference': reference};
  factory Bookmark.fromMap(Map<String, dynamic> m) => Bookmark(bookId: m['bookId'], chapterNumber: m['chapterNumber'], verseNumber: m['verseNumber'], verseText: m['verseText'], reference: m['reference']);
}

class BookmarkRepository {
  static const _boxName = 'bookmarks';
  Future<Box> _open() => Hive.openBox(_boxName);

  Future<void> addBookmark(Bookmark bookmark) async {
    final box = await _open();
    await box.put('${bookmark.bookId}_${bookmark.chapterNumber}_${bookmark.verseNumber}', bookmark.toMap());
  }

  Future<void> removeBookmark(String key) async {
    final box = await _open();
    await box.delete(key);
  }

  Future<List<Bookmark>> getBookmarks() async {
    final box = await _open();
    return box.values.map((v) => Bookmark.fromMap(Map<String, dynamic>.from(v as Map))).toList();
  }
}
```

Add bookmark icon to VerseActionSheet. Add bookmark icon to BibleScreen AppBar linking to BookmarksScreen. Add route `/bible/bookmarks`.

Steps:
- [ ] Write test: add bookmark, get bookmarks, verify it's there; remove, verify gone
- [ ] Run — FAIL
- [ ] Implement BookmarkRepository + BookmarksScreen
- [ ] Run — PASS
- [ ] `git commit -m "feat(bible): add bookmarks (Hive-only) with bookmarks screen"`

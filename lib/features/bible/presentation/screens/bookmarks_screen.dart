import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/bookmark_repository.dart';

final _bookmarkRepositoryProvider =
    Provider<BookmarkRepository>((ref) => BookmarkRepository());

final _bookmarksProvider = FutureProvider<List<Bookmark>>((ref) {
  return ref.watch(_bookmarkRepositoryProvider).getBookmarks();
});

class BookmarksScreen extends ConsumerWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarksAsync = ref.watch(_bookmarksProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Bookmarks')),
      body: bookmarksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (bookmarks) => bookmarks.isEmpty
            ? const Center(child: Text('No bookmarks yet'))
            : ListView.builder(
                itemCount: bookmarks.length,
                itemBuilder: (context, i) {
                  final b = bookmarks[i];
                  return ListTile(
                    title: Text(b.verseText, maxLines: 2, overflow: TextOverflow.ellipsis),
                    subtitle: Text(b.reference),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        await ref
                            .read(_bookmarkRepositoryProvider)
                            .removeBookmark(b.key);
                        ref.invalidate(_bookmarksProvider);
                      },
                    ),
                    onTap: () => context.push('/read/${b.bookId}/${b.chapterNumber}'),
                  );
                },
              ),
      ),
    );
  }
}

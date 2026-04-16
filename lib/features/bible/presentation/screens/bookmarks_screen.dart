import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/bible_content/book_catalog.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/navigation/routes.dart';
import '../providers/bible_providers.dart';

class BookmarksScreen extends ConsumerWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    if (userId.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textPrimary,
          title: const Text('Bookmarks'),
        ),
        body: const Center(
          child: Text(
            'Sign in to view bookmarks',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    final bookmarksAsync = ref.watch(userBookmarksProvider(userId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        title: const Text('Bookmarks'),
      ),
      body: bookmarksAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(
          child: Text('Error loading bookmarks', style: TextStyle(color: AppColors.error)),
        ),
        data: (bookmarks) {
          if (bookmarks.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bookmark_outline, size: 48, color: AppColors.textMuted),
                  SizedBox(height: 12),
                  Text(
                    'No bookmarks yet',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Long-press a verse to bookmark it',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            itemCount: bookmarks.length,
            separatorBuilder: (_, __) =>
                const Divider(color: AppColors.surfaceElevated, height: 1),
            itemBuilder: (context, index) {
              final bookmark = bookmarks[index];
              final book = kBibleBooks.firstWhere(
                (b) => b.id == bookmark.bookId,
                orElse: () => kBibleBooks.first,
              );
              final reference =
                  '${book.name} ${bookmark.chapterNumber}:${bookmark.verseNumber}';

              return ListTile(
                leading: const Icon(Icons.bookmark, color: AppColors.primary),
                title: Text(
                  reference,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                subtitle: Text(
                  bookmark.verseText,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppColors.textMuted),
                  onPressed: () {
                    final repo = ref.read(bookmarkRepositoryProvider);
                    repo.removeBookmark(userId, bookmark.id);
                  },
                ),
                onTap: () => context.go(
                  Routes.chapterReaderPath(bookmark.bookId, bookmark.chapterNumber),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

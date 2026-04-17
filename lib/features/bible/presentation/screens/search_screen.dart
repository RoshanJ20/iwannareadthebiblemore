import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/bible_content/book_catalog.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/navigation/routes.dart';
import '../providers/bible_providers.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(searchResultsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        title: TextField(
          controller: _controller,
          autofocus: true,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            hintText: 'Search scriptures...',
            hintStyle: TextStyle(color: AppColors.textMuted),
            border: InputBorder.none,
          ),
          onChanged: (v) {
            ref.read(searchQueryProvider.notifier).state = v;
          },
        ),
      ),
      body: results.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(
          child: Text('Search error', style: TextStyle(color: AppColors.error)),
        ),
        data: (verses) {
          if (_controller.text.trim().isEmpty) {
            return const Center(
              child: Text(
                'Type to search',
                style: TextStyle(color: AppColors.textMuted),
              ),
            );
          }

          if (verses.isEmpty) {
            return const Center(
              child: Text(
                'No results found',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }

          return ListView.builder(
            itemCount: verses.length,
            itemBuilder: (context, index) {
              final verse = verses[index];
              final book = kBibleBooks.firstWhere(
                (b) => b.id == verse.bookId,
                orElse: () => kBibleBooks.first,
              );
              final reference = '${book.name} ${verse.chapterNumber}:${verse.verseNumber}';

              return ListTile(
                onTap: () => context.go(
                  Routes.chapterReaderPath(verse.bookId, verse.chapterNumber),
                ),
                title: Text(
                  reference,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                subtitle: Text(
                  verse.text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

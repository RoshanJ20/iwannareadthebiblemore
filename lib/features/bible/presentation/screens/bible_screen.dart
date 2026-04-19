import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/bible_content/book_catalog.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/navigation/routes.dart';
import '../../domain/entities/bible_book.dart';
import '../providers/bible_providers.dart';

class BibleScreen extends ConsumerWidget {
  const BibleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final translation = ref.watch(currentTranslationProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        title: const Text('Bible'),
        actions: [
          DropdownButton<String>(
            value: translation,
            dropdownColor: AppColors.surface,
            underline: const SizedBox(),
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            items: const [
              DropdownMenuItem(value: 'niv', child: Text('NIV')),
              DropdownMenuItem(value: 'esv', child: Text('ESV')),
              DropdownMenuItem(value: 'nlt', child: Text('NLT')),
              DropdownMenuItem(value: 'nasb', child: Text('NASB')),
              DropdownMenuItem(value: 'kjv', child: Text('KJV')),
              DropdownMenuItem(value: 'web', child: Text('WEB')),
            ],
            onChanged: (v) {
              if (v != null) {
                ref.read(currentTranslationProvider.notifier).state = v;
              }
            },
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.go(Routes.search),
          ),
          IconButton(
            icon: const Icon(Icons.bookmark_outline),
            onPressed: () => context.go(Routes.bookmarks),
          ),
        ],
      ),
      body: ListView(
        children: [
          _TestamentSection(
            title: 'Old Testament',
            books: kBibleBooks.where((b) => b.testament == Testament.old).toList(),
          ),
          _TestamentSection(
            title: 'New Testament',
            books: kBibleBooks
                .where((b) => b.testament == Testament.newTestament)
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _TestamentSection extends StatelessWidget {
  const _TestamentSection({required this.title, required this.books});

  final String title;
  final List<BibleBook> books;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.primary,
                ),
          ),
        ),
        ...books.map((book) => _BookTile(book: book)),
      ],
    );
  }
}

class _BookTile extends StatelessWidget {
  const _BookTile({required this.book});

  final BibleBook book;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.go(Routes.chapterListPath(book.id)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.surfaceElevated, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                book.name,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            Text(
              '${book.totalChapters} ch',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

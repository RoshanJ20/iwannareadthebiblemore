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
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        title: const Text('Scripture'),
        actions: [
          _TranslationDropdown(translation: translation, ref: ref),
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () => context.go(Routes.search),
          ),
          IconButton(
            icon: const Icon(Icons.bookmark_outline_rounded),
            onPressed: () => context.go(Routes.bookmarks),
          ),
          const SizedBox(width: 4),
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
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _TranslationDropdown extends StatelessWidget {
  const _TranslationDropdown({required this.translation, required this.ref});

  final String translation;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.textMuted.withOpacity(0.3)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: translation,
          dropdownColor: AppColors.surfaceElevated,
          icon: const Icon(Icons.expand_more, color: AppColors.textMuted, size: 16),
          style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600),
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
          padding: const EdgeInsets.fromLTRB(16, 28, 16, 4),
          child: Row(
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.primary,
                      fontSize: 20,
                    ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  height: 1,
                  color: AppColors.primary.withOpacity(0.2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${books.length} books',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
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
      splashColor: AppColors.primary.withOpacity(0.06),
      highlightColor: AppColors.primary.withOpacity(0.04),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.surfaceElevated, width: 0.8),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                book.name,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
            Text(
              '${book.totalChapters} ch',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textMuted,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

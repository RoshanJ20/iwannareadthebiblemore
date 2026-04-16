import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/bible_content/book_catalog.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/navigation/routes.dart';

class ChapterListScreen extends StatelessWidget {
  const ChapterListScreen({super.key, required this.bookId});

  final String bookId;

  @override
  Widget build(BuildContext context) {
    final book = kBibleBooks.firstWhere(
      (b) => b.id == bookId,
      orElse: () => kBibleBooks.first,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        title: Text(book.name),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1,
        ),
        itemCount: book.totalChapters,
        itemBuilder: (context, index) {
          final chapterNumber = index + 1;
          return _ChapterTile(
            bookId: bookId,
            chapterNumber: chapterNumber,
          );
        },
      ),
    );
  }
}

class _ChapterTile extends StatelessWidget {
  const _ChapterTile({
    required this.bookId,
    required this.chapterNumber,
  });

  final String bookId;
  final int chapterNumber;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go(Routes.chapterReaderPath(bookId, chapterNumber)),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            '$chapterNumber',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }
}

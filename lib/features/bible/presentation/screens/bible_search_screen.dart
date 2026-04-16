import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../bible_providers.dart';
import '../../domain/services/bible_search_service.dart';

class BibleSearchScreen extends ConsumerStatefulWidget {
  const BibleSearchScreen({super.key});

  @override
  ConsumerState<BibleSearchScreen> createState() => _BibleSearchScreenState();
}

class _BibleSearchScreenState extends ConsumerState<BibleSearchScreen> {
  final _controller = TextEditingController();
  List<SearchResult> _results = [];
  Timer? _debounce;

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      final service = BibleSearchService(ref.read(bibleRepositoryProvider));
      final results = await service.search(value);
      if (mounted) setState(() => _results = results);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          onChanged: _onChanged,
          decoration: const InputDecoration(
            hintText: 'Search the Bible...',
            border: InputBorder.none,
          ),
        ),
      ),
      body: _results.isEmpty
          ? const Center(child: Text('Type at least 3 characters to search'))
          : ListView.builder(
              itemCount: _results.length,
              itemBuilder: (context, i) {
                final r = _results[i];
                return ListTile(
                  title: Text(r.verse.text, maxLines: 2, overflow: TextOverflow.ellipsis),
                  subtitle: Text('${r.book.name} ${r.chapterNumber}:${r.verse.number}'),
                  onTap: () => context.push('/read/${r.book.id}/${r.chapterNumber}'),
                );
              },
            ),
    );
  }
}

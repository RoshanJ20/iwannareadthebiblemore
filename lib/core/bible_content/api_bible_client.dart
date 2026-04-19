import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import '../../features/bible/domain/entities/bible_verse.dart';

class ApiBibleClient {
  ApiBibleClient({required this.apiKey, http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? (kIsWeb ? _proxyBase : _directBase);

  final String apiKey;
  final http.Client _client;
  final String _baseUrl;

  static const _directBase = 'https://rest.api.bible/v1';
  // On web, route through the local proxy server to avoid CORS origin restrictions.
  static const _proxyBase = 'http://localhost:8888/proxy/v1';

  static const bibleIds = {
    'kjv': 'de4e12af7f28f599-02',
    'web': '9879dbb7cfe39e4d-04',
    'niv': '78a9f6124f344018-01',
    'esv': 'f72b840c855f362c-04',
    'nlt': '65eec8e0b60e656b-01',
    'nasb': '01b29f4b342acc35-01',
  };

  Future<List<BibleVerse>> fetchChapter(
    String bookId,
    int chapterNumber,
    String translation,
  ) async {
    final bibleId = bibleIds[translation.toLowerCase()];
    if (bibleId == null) return [];
    if (apiKey.isEmpty) return [];

    final chapterId = '$bookId.$chapterNumber';

    try {
      final uri = Uri.parse(
        '$_baseUrl/bibles/$bibleId/chapters/$chapterId',
      ).replace(queryParameters: {
        'content-type': 'json',
        'include-notes': 'false',
        'include-titles': 'false',
        'include-chapter-numbers': 'false',
        'include-verse-numbers': 'true',
        'include-verse-spans': 'false',
      });

      final response = await _client.get(
        uri,
        headers: {'api-key': apiKey},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return [];

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final data = json['data'] as Map<String, dynamic>?;
      if (data == null) return [];

      return _parseVerses(data, bookId, chapterNumber);
    } catch (_) {
      return [];
    }
  }

  Future<List<BibleVerse>> searchVerses(
    String query,
    String translation,
  ) async {
    final bibleId = bibleIds[translation.toLowerCase()];
    if (bibleId == null || apiKey.isEmpty || query.trim().isEmpty) return [];

    try {
      final uri = Uri.parse(
        '$_baseUrl/bibles/$bibleId/search',
      ).replace(queryParameters: {
        'query': query,
        'limit': '20',
      });

      final response = await _client.get(
        uri,
        headers: {'api-key': apiKey},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return [];

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final data = json['data'] as Map<String, dynamic>?;
      final verses = data?['verses'] as List<dynamic>?;
      if (verses == null) return [];

      return verses.map((v) {
        final vMap = v as Map<String, dynamic>;
        final reference = vMap['reference'] as String? ?? '';
        final parts = _parseReference(reference);
        return BibleVerse(
          bookId: parts.$1,
          chapterNumber: parts.$2,
          verseNumber: parts.$3,
          text: _stripHtml(vMap['text'] as String? ?? ''),
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  List<BibleVerse> _parseVerses(
    Map<String, dynamic> data,
    String bookId,
    int chapterNumber,
  ) {
    final content = data['content'] as List<dynamic>?;
    if (content == null) return [];

    final verses = <BibleVerse>[];
    for (final item in content) {
      final itemMap = item as Map<String, dynamic>;
      final items = itemMap['items'] as List<dynamic>?;
      if (items == null) continue;

      for (final child in items) {
        final childMap = child as Map<String, dynamic>;
        final verseId = childMap['attrs']?['verseId'] as String?;
        if (verseId == null) continue;

        final parts = verseId.split('.');
        if (parts.length < 3) continue;
        final verseNumber = int.tryParse(parts[2]);
        if (verseNumber == null) continue;

        final text = childMap['text'] as String?;
        if (text == null || text.trim().isEmpty) continue;

        if (verses.isNotEmpty && verses.last.verseNumber == verseNumber) {
          verses[verses.length - 1] = BibleVerse(
            bookId: bookId,
            chapterNumber: chapterNumber,
            verseNumber: verseNumber,
            text: '${verses.last.text}$text',
          );
        } else {
          verses.add(BibleVerse(
            bookId: bookId,
            chapterNumber: chapterNumber,
            verseNumber: verseNumber,
            text: text.trim(),
          ));
        }
      }
    }
    return verses;
  }

  (String, int, int) _parseReference(String reference) {
    return ('GEN', 1, 1);
  }

  String _stripHtml(String html) {
    return html.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  }
}

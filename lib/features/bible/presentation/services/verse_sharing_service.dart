import 'package:share_plus/share_plus.dart';
import '../../domain/models/bible_verse.dart';

enum VerseCardBackground { light, dark, gradient }

class VerseSharingService {
  static Future<void> shareText({
    required BibleVerse verse,
    required String reference,
  }) async {
    await Share.share('"${verse.text}" — $reference\n\niwannareadthebiblemore');
  }
}

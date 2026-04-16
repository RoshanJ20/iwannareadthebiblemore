import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

/// Parses custom deep-link URIs and navigates to the correct screen.
///
/// Supported schemes and paths:
/// ```
/// iwannareadthebiblemore://read/{bookId}/{chapter}  → ChapterReaderScreen
/// iwannareadthebiblemore://groups/{groupId}          → GroupDetailScreen
/// iwannareadthebiblemore://profile                   → ProfileScreen
/// ```
///
/// Usage:
/// ```dart
/// DeepLinkService.handleUri(uri, router);
/// ```
class DeepLinkService {
  DeepLinkService._();

  static const _scheme = 'iwannareadthebiblemore';

  /// Attempts to navigate to the screen indicated by [uri].
  ///
  /// Returns `true` when navigation was performed, `false` when the URI
  /// could not be handled.
  static bool handleUri(Uri uri, GoRouter router) {
    if (uri.scheme != _scheme) {
      debugPrint('[DeepLinkService] unknown scheme: ${uri.scheme}');
      return false;
    }

    final segments = uri.pathSegments;

    // iwannareadthebiblemore://read/{bookId}/{chapter}
    if (segments.length == 3 && segments[0] == 'read') {
      final bookId = segments[1];
      final chapter = int.tryParse(segments[2]);
      if (chapter != null) {
        router.go('/read/book/$bookId/chapter/$chapter');
        return true;
      }
    }

    // iwannareadthebiblemore://read  (no book/chapter — go to bible root)
    if (segments.length == 1 && segments[0] == 'read') {
      router.go('/read');
      return true;
    }

    // iwannareadthebiblemore://groups/{groupId}
    if (segments.length == 2 && segments[0] == 'groups') {
      final groupId = segments[1];
      router.go('/groups/$groupId');
      return true;
    }

    // iwannareadthebiblemore://profile
    if (segments.length == 1 && segments[0] == 'profile') {
      router.go('/profile');
      return true;
    }

    debugPrint('[DeepLinkService] unhandled URI: $uri');
    return false;
  }

  /// Parses a raw string (e.g. from a push payload) into a [Uri] and
  /// delegates to [handleUri].
  static bool handleUriString(String uriString, GoRouter router) {
    final uri = Uri.tryParse(uriString);
    if (uri == null) {
      debugPrint('[DeepLinkService] failed to parse URI: $uriString');
      return false;
    }
    return handleUri(uri, router);
  }
}

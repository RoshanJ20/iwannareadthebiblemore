abstract class Routes {
  static const login = '/login';
  static const onboarding = '/onboarding';
  static const home = '/home';
  static const read = '/read';
  static const groups = '/groups';
  static const plans = '/plans';
  static const profile = '/profile';

  // Bible sub-routes
  static const bibleSearch = '/read/search';
  static const bibleBookmarks = '/read/bookmarks';
  static String chapterReaderPath(String bookId, int chapterNumber) =>
      '/read/$bookId/$chapterNumber';

  // Gamification
  static const achievements = '/achievements';
  static const store = '/store';

  // Profile sub-routes
  static const xpStore = '/profile/xp-store';
  static const settings = '/profile/settings';
  static const notificationSettings = '/profile/settings/notifications';
}

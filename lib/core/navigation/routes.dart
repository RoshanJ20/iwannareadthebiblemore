abstract class Routes {
  static const login = '/login';
  static const home = '/home';
  static const read = '/read';
  static const groups = '/groups';
  static const plans = '/plans';
  static const profile = '/profile';
  static const achievements = '/profile/achievements';
  static const xpStore = '/profile/xp-store';

  static const chapterList = '/read/book/:bookId';
  static const chapterReader = '/read/book/:bookId/chapter/:chapterNumber';
  static const search = '/read/search';
  static const bookmarks = '/read/bookmarks';

  static const groupDetail = '/groups/:groupId';
  static const createGroup = '/groups/create';
  static const joinGroup = '/groups/join';
  static const planDetail = '/plans/:planId';

  static String chapterListPath(String bookId) => '/read/book/$bookId';
  static String chapterReaderPath(String bookId, int chapterNumber) =>
      '/read/book/$bookId/chapter/$chapterNumber';

  static String groupDetailPath(String groupId) => '/groups/$groupId';
  static String planDetailPath(String planId) => '/plans/$planId';
}

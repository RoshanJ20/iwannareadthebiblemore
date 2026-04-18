import 'package:flutter/foundation.dart';
// home_widget is mobile-only; import guarded by kIsWeb checks below.
import 'package:home_widget/home_widget.dart'
    if (dart.library.html) 'package:iwannareadthebiblemore/features/notifications/data/services/home_widget_stub.dart';

/// Service that keeps the iOS/Android home-screen widget (and iOS lock-screen
/// widget) in sync with the latest user data.
///
/// The native widget layout must be configured separately in:
///   - Android: `android/app/src/main/res/layout/home_widget.xml`
///   - iOS: a Widget Extension target in Xcode
///
/// Both widgets read data written by [HomeWidget.saveWidgetData].
class WidgetService {
  /// App group identifier used by the iOS widget extension to share data.
  /// Must match the App Group set up in the Apple Developer portal.
  static const _appGroupId = 'group.com.iwannareadthebiblemore.widget';

  /// Android widget provider class name (fully qualified).
  static const _androidWidgetProvider =
      'com.iwannareadthebiblemore.HomeWidgetProvider';

  /// iOS widget kind identifier (matches the `kind` parameter in
  /// `WidgetCenter.shared.reloadTimelines(ofKind:)`).
  static const _iOSWidgetKind = 'HomeWidget';

  /// Writes streak + verse data and triggers a widget refresh.
  ///
  /// Call this after the user completes their daily reading, and on app
  /// startup so the widget always shows current data.
  static Future<void> updateHomeWidget({
    required int streak,
    required String verseText,
    required String verseReference,
  }) async {
    try {
      await HomeWidget.setAppGroupId(_appGroupId);
      await HomeWidget.saveWidgetData<int>('streak', streak);
      await HomeWidget.saveWidgetData<String>('verse', verseText);
      await HomeWidget.saveWidgetData<String>('reference', verseReference);
      await HomeWidget.updateWidget(
        androidName: _androidWidgetProvider,
        iOSName: _iOSWidgetKind,
      );
      debugPrint('[WidgetService] home widget updated: streak=$streak');
    } catch (e) {
      // Non-fatal — widget update failure should not surface to the user.
      debugPrint('[WidgetService] failed to update widget: $e');
    }
  }

  /// Registers a callback that is invoked when the user taps the widget CTA
  /// ("Read" button) from the home screen.
  ///
  /// [onLaunch] receives the URI that the widget sends, e.g.
  /// `iwannareadthebiblemore://read`.
  static Future<void> registerInteractivityCallback(
    Future<void> Function(Uri? uri) onLaunch,
  ) async {
    try {
      await HomeWidget.setAppGroupId(_appGroupId);
      HomeWidget.widgetClicked.listen(onLaunch);
    } catch (e) {
      debugPrint('[WidgetService] failed to register widget callback: $e');
    }
  }
}

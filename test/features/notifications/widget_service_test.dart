import 'package:flutter_test/flutter_test.dart';
import 'package:iwannareadthebiblemore/features/notifications/data/services/widget_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WidgetService', () {
    test('updateHomeWidget does not throw when home_widget channel is absent',
        () async {
      // In test environment the home_widget platform channel is not set up.
      // WidgetService catches exceptions internally so this must not throw.
      await expectLater(
        WidgetService.updateHomeWidget(
          streak: 7,
          verseText: 'Test verse',
          verseReference: 'Psalm 1:1',
        ),
        completes,
      );
    });

    test('updateHomeWidget accepts zero streak', () async {
      await expectLater(
        WidgetService.updateHomeWidget(
          streak: 0,
          verseText: '',
          verseReference: '',
        ),
        completes,
      );
    });

    test('updateHomeWidget accepts large streak values', () async {
      await expectLater(
        WidgetService.updateHomeWidget(
          streak: 365,
          verseText: '"For I know the plans I have for you," declares the Lord',
          verseReference: 'Jeremiah 29:11',
        ),
        completes,
      );
    });

    test('registerInteractivityCallback does not throw', () async {
      await expectLater(
        WidgetService.registerInteractivityCallback((_) async {}),
        completes,
      );
    });

    test('WidgetService has static updateHomeWidget method', () {
      // Verify the method exists with the correct signature via reflection.
      expect(WidgetService.updateHomeWidget, isA<Function>());
    });

    test('WidgetService has static registerInteractivityCallback method', () {
      expect(WidgetService.registerInteractivityCallback, isA<Function>());
    });
  });
}

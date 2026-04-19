import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ReaderPreferences {
  const ReaderPreferences({
    this.fontSize = 18.0,
    this.lineHeight = 1.85,
    this.fontFamily = 'lora',
    this.horizontalPadding = 24.0,
  });

  final double fontSize;
  final double lineHeight;
  final String fontFamily; // 'lora' | 'system' | 'garamond'
  final double horizontalPadding;

  ReaderPreferences copyWith({
    double? fontSize,
    double? lineHeight,
    String? fontFamily,
    double? horizontalPadding,
  }) =>
      ReaderPreferences(
        fontSize: fontSize ?? this.fontSize,
        lineHeight: lineHeight ?? this.lineHeight,
        fontFamily: fontFamily ?? this.fontFamily,
        horizontalPadding: horizontalPadding ?? this.horizontalPadding,
      );
}

class ReaderPreferencesNotifier extends Notifier<ReaderPreferences> {
  static const _boxName = 'settings';

  @override
  ReaderPreferences build() {
    final box = Hive.box(_boxName);
    return ReaderPreferences(
      fontSize: (box.get('reader_font_size') as double?) ?? 18.0,
      lineHeight: (box.get('reader_line_height') as double?) ?? 1.85,
      fontFamily: (box.get('reader_font_family') as String?) ?? 'lora',
      horizontalPadding: (box.get('reader_margin') as double?) ?? 24.0,
    );
  }

  void setFontSize(double v) {
    Hive.box(_boxName).put('reader_font_size', v);
    state = state.copyWith(fontSize: v);
  }

  void setLineHeight(double v) {
    Hive.box(_boxName).put('reader_line_height', v);
    state = state.copyWith(lineHeight: v);
  }

  void setFontFamily(String v) {
    Hive.box(_boxName).put('reader_font_family', v);
    state = state.copyWith(fontFamily: v);
  }

  void setHorizontalPadding(double v) {
    Hive.box(_boxName).put('reader_margin', v);
    state = state.copyWith(horizontalPadding: v);
  }
}

final readerPreferencesProvider =
    NotifierProvider<ReaderPreferencesNotifier, ReaderPreferences>(
  ReaderPreferencesNotifier.new,
);

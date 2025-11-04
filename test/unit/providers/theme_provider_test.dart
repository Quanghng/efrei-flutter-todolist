import 'package:flutter/material.dart';
import 'package:test/test.dart';

import 'package:efrei_todolist/providers/theme_provider.dart';

void main() {
  group('ThemeProvider', () {
    test('starts in light mode', () {
      final provider = ThemeProvider();

      expect(provider.mode, ThemeMode.light);
      expect(provider.isDark, isFalse);
    });

    test('toggle switches between light and dark', () {
      final provider = ThemeProvider();

      provider.toggle();
      expect(provider.mode, ThemeMode.dark);
      expect(provider.isDark, isTrue);

      provider.toggle();
      expect(provider.mode, ThemeMode.light);
      expect(provider.isDark, isFalse);
    });
  });
}

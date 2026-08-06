import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:kriptonshare/core/localization/locale_provider.dart';
import 'package:kriptonshare/core/localization/supported_locales.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('LocaleNotifier', () {
    test('default state is the fallback locale', () {
      final notifier = LocaleNotifier();
      addTearDown(notifier.dispose);

      expect(notifier.state, kFallbackLocale);
    });

    test('setLocale updates state and persists the choice', () async {
      final notifier = LocaleNotifier();
      addTearDown(notifier.dispose);

      await notifier.setLocale('es');

      expect(notifier.state, const Locale('es'));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(kLocaleStorageKey), 'es');
    });

    test('setLocale ignores unsupported language codes', () async {
      final notifier = LocaleNotifier();
      addTearDown(notifier.dispose);

      await notifier.setLocale('ja');

      expect(notifier.state, kFallbackLocale);
    });

    test('supportedLocales contains all configured languages', () {
      final locales = LocaleNotifier.supportedLocales;

      expect(locales.map((l) => l.languageCode).toList(),
          containsAll(['en', 'es', 'fr', 'de', 'pt']));
    });

    test('initialize restores saved locale', () async {
      SharedPreferences.setMockInitialValues({kLocaleStorageKey: 'de'});

      final notifier = LocaleNotifier();
      addTearDown(notifier.dispose);

      // Wait for the async _initializeLocale to complete.
      await Future.delayed(const Duration(milliseconds: 50));

      expect(notifier.state, const Locale('de'));
    });
  });
}

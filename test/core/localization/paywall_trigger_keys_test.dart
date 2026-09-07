import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Espejo contractual del mapeo en `paywall_sheet.dart` (§10.3): cada trigger
/// contextual resuelve a un título y un cuerpo de ARB; `general` usa el par
/// por defecto. El test garantiza que las 5 localizaciones definen esas claves.
const triggers = <String, ({String title, String body})>{
  'file_size': (title: 'paywallFileSizeTitle', body: 'paywallFileSizeBody'),
  'active_links': (title: 'paywallActiveLinksTitle', body: 'paywallActiveLinksBody'),
  'monthly_quota': (title: 'paywallMonthlyQuotaTitle', body: 'paywallMonthlyQuotaBody'),
  'link_duration': (title: 'paywallDurationTitle', body: 'paywallDurationBody'),
  'storage': (title: 'paywallStorageTitle', body: 'paywallStorageBody'),
  'general': (title: 'unlockPremiumTitle', body: 'paywallBody'),
};

const alwaysRequiredKeys = <String>{
  'paywallStorageBodyBusiness',
  'paywallViewPlans',
  'paywallNotNow',
  'featureNoAds',
  'featureFileSize',
  'featureStorage',
  'featureLinkDuration',
};

const locales = <String, String>{
  'en': 'lib/l10n/app_en.arb',
  'es': 'lib/l10n/app_es.arb',
  'pt': 'lib/l10n/app_pt.arb',
  'fr': 'lib/l10n/app_fr.arb',
  'de': 'lib/l10n/app_de.arb',
};

void main() {
  group('PaywallTrigger → claves ARB', () {
    locales.forEach((locale, path) {
      final json = jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

      test('$locale define las claves de cada trigger y las de UI', () {
        triggers.forEach((trigger, keys) {
          final title = json[keys.title];
          final body = json[keys.body];
          expect(
            title,
            isA<String>(),
            reason: '$locale: falta título "$trigger" (${keys.title})',
          );
          expect(
            (title as String).trim().isNotEmpty,
            isTrue,
            reason: '$locale: título "$trigger" vacío',
          );
          expect(
            body,
            isA<String>(),
            reason: '$locale: falta cuerpo "$trigger" (${keys.body})',
          );
          expect(
            (body as String).trim().isNotEmpty,
            isTrue,
            reason: '$locale: cuerpo "$trigger" vacío',
          );
        });

        for (final key in alwaysRequiredKeys) {
          final value = json[key];
          expect(
            value,
            isA<String>(),
            reason: '$locale: falta clave de UI "$key"',
          );
          expect((value as String).trim().isNotEmpty, isTrue);
        }
      });
    });
  });
}

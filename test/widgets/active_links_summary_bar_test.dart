import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kriptonshare/l10n/app_localizations.dart';
import 'package:kriptonshare/models/active_links_summary.dart';
import 'package:kriptonshare/utils/theme.dart';
import 'package:kriptonshare/widgets/active_links_summary_bar.dart';

const int _mb = 1024 * 1024;
const int _gb = 1024 * 1024 * 1024;

Widget _app(ActiveLinksSummary summary, {Locale locale = const Locale('en')}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: ActiveLinksSummaryBar(summary: summary)),
  );
}

void main() {
  testWidgets('free sin links: "0 / 3" y "0 B used"', (tester) async {
    await tester.pumpWidget(
      _app(
        const ActiveLinksSummary(
          activeCount: 0,
          totalSizeBytes: 0,
          countLimit: 3,
        ),
      ),
    );

    expect(find.text('0 / 3 active links'), findsOneWidget);
    expect(find.text('0 B used'), findsOneWidget);
  });

  testWidgets('free con links: cantidad con denominador y tamaño en MB', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const ActiveLinksSummary(
          activeCount: 2,
          totalSizeBytes: 3 * _mb,
          countLimit: 3,
        ),
      ),
    );

    expect(find.text('2 / 3 active links'), findsOneWidget);
    expect(find.text('3.0 MB used'), findsOneWidget);
  });

  testWidgets('premium: sin denominador de cantidad y cuota en GB', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const ActiveLinksSummary(
          activeCount: 1,
          totalSizeBytes: 248 * _mb,
          storageLimitBytes: _gb,
        ),
      ),
    );

    // Cantidad: singular, sin denominador porque el plan no limita cantidad.
    expect(find.text('1 active link'), findsOneWidget);
    // Almacenamiento: se usa GB para la cuota y se mantiene en MB el usado.
    expect(find.text('248.0 MB of 1.0 GB used'), findsOneWidget);
  });

  testWidgets('business: formatea el usado en GB cuando supera 1024 MB', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const ActiveLinksSummary(
          activeCount: 4,
          totalSizeBytes: (3 * _gb) ~/ 2,
          storageLimitBytes: 5 * _gb,
        ),
      ),
    );

    expect(find.text('4 active links'), findsOneWidget);
    expect(find.text('1.5 GB of 5.0 GB used'), findsOneWidget);
  });

  testWidgets('resalta en ámbar cuando se alcanza el 80% del límite', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const ActiveLinksSummary(
          activeCount: 3,
          totalSizeBytes: _mb,
          countLimit: 3,
        ),
      ),
    );

    final linkIcon = tester.widget<Icon>(find.byIcon(Icons.link));
    expect(linkIcon.color, KriptonTheme.amber);
  });

  testWidgets('no resalta cuando está por debajo del 80%', (tester) async {
    await tester.pumpWidget(
      _app(
        const ActiveLinksSummary(
          activeCount: 1,
          totalSizeBytes: _mb,
          countLimit: 3,
        ),
      ),
    );

    final linkIcon = tester.widget<Icon>(find.byIcon(Icons.link));
    expect(linkIcon.color, KriptonTheme.electricLime);
  });

  testWidgets('localización en español', (tester) async {
    await tester.pumpWidget(
      _app(
        const ActiveLinksSummary(
          activeCount: 2,
          totalSizeBytes: 3 * _mb,
          countLimit: 3,
        ),
        locale: const Locale('es'),
      ),
    );

    expect(find.text('2 / 3 enlaces activos'), findsOneWidget);
    expect(find.text('3,0 MB usados'), findsOneWidget);
  });
}

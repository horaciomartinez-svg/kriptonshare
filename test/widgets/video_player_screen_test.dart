import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kriptonshare/l10n/app_localizations.dart';
import 'package:kriptonshare/widgets/video_player_screen.dart';

void main() {
  Widget buildSubject() {
    return const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: SecureVideoPlayerScreen(
        filePath: '/nonexistent/decrypted_video.mp4',
        fileName: 'video.mp4',
      ),
    );
  }

  // La carga usa I/O real (File.exists), así que hay que ceder el event loop
  // real antes de comprobar el estado resultante.
  Future<void> settle(WidgetTester tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pump();
  }

  testWidgets(
    'SecureVideoPlayerScreen no lanza excepción en initState',
    (tester) async {
      await settle(tester);

      // El bug original lanzaba un error de inherited widget durante
      // initState; con el fix no debe quedar ninguna excepción pendiente.
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'SecureVideoPlayerScreen muestra error con Reintentar si el archivo no existe',
    (tester) async {
      await settle(tester);

      // Nunca debe quedarse en el spinner indefinidamente.
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Could not open the video.'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    },
  );

  testWidgets(
    'Reintentar no rompe la pantalla y vuelve a intentar la carga',
    (tester) async {
      await settle(tester);

      await tester.tap(find.text('Retry'));
      await tester.pump();
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 200));
      });
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('Retry'), findsOneWidget);
    },
  );
}

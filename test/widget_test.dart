import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kriptonshare/main.dart';
import 'package:kriptonshare/core/utils/constants.dart';
import 'package:kriptonshare/providers/auth_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  // Cliente fake: el app real no está conectado a Supabase en tests unitarios.
  final fakeSupabaseClient = SupabaseClient(
    'https://fake.supabase.co',
    'fake-anon-key',
  );

  Widget buildApp() {
    return ProviderScope(
      overrides: [
        supabaseClientProvider.overrideWithValue(fakeSupabaseClient),
      ],
      child: const KriptonShareApp(),
    );
  }

  // El splash y la pantalla de auth animan con retrasos (flutter_animate usa
  // Future.delayed, cuyos timers no se cancelan al desmontar). Avanzamos el
  // reloj simulado para que esos timers se disparen y no queden pendientes.
  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(buildApp());
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 400));
    }
  }

  group('KRIPTONSHARE App', () {
    testWidgets('App builds without errors', (WidgetTester tester) async {
      // Build our app and trigger a frame.
      await pumpApp(tester);

      // Verify that the app builds without throwing
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('App has correct title', (WidgetTester tester) async {
      await pumpApp(tester);

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.title, 'KRIPTONSHARE');
    });
  });

  group('Constants', () {
    test('AppConstants has correct values', () {
      expect(AppConstants.aesKeySize, 32);
      expect(AppConstants.aesNonceSize, 12);
      expect(AppConstants.aesTagSize, 16);
      expect(AppConstants.chunkSize, 256 * 1024);
    });
  });
}

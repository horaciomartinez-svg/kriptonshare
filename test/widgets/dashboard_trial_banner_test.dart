import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kriptonshare/l10n/app_localizations.dart';
import 'package:kriptonshare/models/trial_start_outcome.dart';
import 'package:kriptonshare/models/user_model.dart';
import 'package:kriptonshare/widgets/dashboard_trial_banner.dart';

KriptonUser _user({
  String tier = 'free',
  DateTime? trialEndsAt,
}) {
  return KriptonUser(
    id: '00000000-0000-0000-0000-000000000001',
    email: 'user@example.com',
    subscriptionTier: tier,
    trialEndsAt: trialEndsAt,
    createdAt: DateTime(2026, 1, 1),
  );
}

Widget _app(
  KriptonUser user, {
  VoidCallback? onViewPlans,
  Future<TrialStartOutcome> Function()? onStartTrial,
  Locale locale = const Locale('en'),
}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: DashboardTrialBanner(
        user: user,
        onViewPlans: onViewPlans ?? () {},
        onStartTrial: onStartTrial ??
            () async => const TrialStartOutcome(started: false),
      ),
    ),
  );
}

void main() {
  group('resolveTrialBannerMode', () {
    test('free sin trial usado → invite', () {
      expect(resolveTrialBannerMode(_user()), TrialBannerMode.invite);
    });

    test('free con trial activo → countdown', () {
      expect(
        resolveTrialBannerMode(
          _user(trialEndsAt: DateTime.now().add(const Duration(days: 3))),
        ),
        TrialBannerMode.countdown,
      );
    });

    test('free con trial ya usado (expirado) → hidden', () {
      expect(
        resolveTrialBannerMode(
          _user(trialEndsAt: DateTime.now().subtract(const Duration(days: 1))),
        ),
        TrialBannerMode.hidden,
      );
    });

    test('premium y business → hidden', () {
      expect(resolveTrialBannerMode(_user(tier: 'premium')), TrialBannerMode.hidden);
      expect(resolveTrialBannerMode(_user(tier: 'business')), TrialBannerMode.hidden);
    });
  });

  group('DashboardTrialBanner', () {
    testWidgets('Free sin trial usado → invitación visible con CTA', (tester) async {
      var started = false;
      await tester.pumpWidget(
        _app(
          _user(),
          onStartTrial: () async {
            started = true;
            return const TrialStartOutcome(started: true, code: 'started');
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('14 days of Premium free. No card required.'),
        findsOneWidget,
      );
      expect(find.text('Start free trial'), findsOneWidget);

      await tester.tap(find.text('Start free trial'));
      await tester.pumpAndSettle();
      expect(started, isTrue);
    });

    testWidgets('CTA exitoso → SnackBar de éxito', (tester) async {
      await tester.pumpWidget(
        _app(
          _user(),
          onStartTrial: () async =>
              const TrialStartOutcome(started: true, code: 'started'),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Start free trial'));
      await tester.pumpAndSettle();

      expect(find.text('Try Premium: 14 days left'), findsOneWidget);
    });

    testWidgets('CTA con resultado already_used → SnackBar localizado', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          _user(),
          onStartTrial: () async => const TrialStartOutcome(
            started: false,
            code: 'already_used',
            message: 'La prueba gratuita ya fue utilizada.',
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Start free trial'));
      await tester.pumpAndSettle();

      expect(find.text("You've already used your free trial."), findsOneWidget);
    });

    testWidgets('CTA en vuelo → spinner y botón deshabilitado', (tester) async {
      final completer = Completer<TrialStartOutcome>();
      await tester.pumpWidget(
        _app(_user(), onStartTrial: () => completer.future),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Start free trial'));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);

      completer.complete(const TrialStartOutcome(started: true, code: 'started'));
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('trial activo → cuenta regresiva y sin CTA de activación', (
      tester,
    ) async {
      final user = _user(
        trialEndsAt: DateTime.now().add(const Duration(days: 3)),
      );
      await tester.pumpWidget(_app(user));
      await tester.pumpAndSettle();

      expect(find.textContaining('days left'), findsOneWidget);
      expect(find.text('Start free trial'), findsNothing);
    });

    testWidgets('trial activo → al tocar navega a planes', (tester) async {
      var viewed = false;
      final user = _user(
        trialEndsAt: DateTime.now().add(const Duration(days: 3)),
      );
      await tester.pumpWidget(_app(user, onViewPlans: () => viewed = true));
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('days left'));
      expect(viewed, isTrue);
    });

    testWidgets('premium → banner oculto', (tester) async {
      await tester.pumpWidget(_app(_user(tier: 'premium')));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.workspace_premium_outlined), findsNothing);
      expect(find.text('Start free trial'), findsNothing);
    });

    testWidgets('free con trial ya consumido → banner oculto', (tester) async {
      final user = _user(
        trialEndsAt: DateTime.now().subtract(const Duration(days: 1)),
      );
      await tester.pumpWidget(_app(user));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.workspace_premium_outlined), findsNothing);
      expect(find.text('Start free trial'), findsNothing);
    });

    testWidgets('localización en español', (tester) async {
      await tester.pumpWidget(
        _app(_user(), locale: const Locale('es')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Activar prueba gratis'), findsOneWidget);
    });
  });
}

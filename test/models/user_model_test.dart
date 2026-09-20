import 'package:flutter_test/flutter_test.dart';
import 'package:kriptonshare/models/user_model.dart';
import 'package:kriptonshare/utils/constants.dart';

KriptonUser _user({
  String tier = 'free',
  DateTime? trialEndsAt,
  int monthlyLinksGenerated = 0,
}) {
  return KriptonUser(
    id: '00000000-0000-0000-0000-000000000001',
    email: 'user@example.com',
    subscriptionTier: tier,
    trialEndsAt: trialEndsAt,
    monthlyLinksGenerated: monthlyLinksGenerated,
    createdAt: DateTime(2026, 1, 1),
  );
}

void main() {
  group('KriptonUser.effectiveTier', () {
    test('free sin trial → free', () {
      expect(_user(tier: 'free').effectiveTier, 'free');
      expect(_user().isFree, isTrue);
      expect(_user().isPremium, isFalse);
    });

    test('free con trial activo → premium', () {
      final user = _user(
        tier: 'free',
        trialEndsAt: DateTime.now().add(const Duration(days: 3)),
      );
      expect(user.effectiveTier, 'premium');
      expect(user.isFree, isFalse);
      expect(user.isPremium, isTrue);
    });

    test('free con trial expirado → free', () {
      final user = _user(
        tier: 'free',
        trialEndsAt: DateTime.now().subtract(const Duration(days: 1)),
      );
      expect(user.effectiveTier, 'free');
      expect(user.isFree, isTrue);
      expect(user.isPremium, isFalse);
    });

    test('premium → premium', () {
      final user = _user(tier: 'premium');
      expect(user.effectiveTier, 'premium');
      expect(user.isPremium, isTrue);
    });

    test('business y enterprise → business', () {
      expect(_user(tier: 'business').effectiveTier, 'business');
      expect(_user(tier: 'enterprise').effectiveTier, 'business');
      expect(_user(tier: 'enterprise').isPremium, isTrue);
    });
  });

  group('KriptonUser límites por tier efectivo', () {
    test('límites free: 20 MB y 168 h', () {
      final user = _user();
      expect(user.maxFileSizeBytes, AppConstants.freeMaxFileSizeBytes);
      expect(user.maxDurationHours, AppConstants.freeMaxDurationHours);
    });

    test('límites premium con trial: 100 MB y 720 h', () {
      final user = _user(trialEndsAt: DateTime.now().add(const Duration(days: 1)));
      expect(user.maxFileSizeBytes, AppConstants.premiumMaxFileSizeBytes);
      expect(user.maxDurationHours, AppConstants.premiumMaxDurationHours);
    });

    test('límites business: 200 MB y 1440 h', () {
      final user = _user(tier: 'business');
      expect(user.maxFileSizeBytes, AppConstants.businessMaxFileSizeBytes);
      expect(user.maxDurationHours, AppConstants.businessMaxDurationHours);
    });

    test('cuota mensual: free corta en 20 links; premium no', () {
      expect(_user(monthlyLinksGenerated: 0).canCreateLink, isTrue);
      expect(_user(monthlyLinksGenerated: 19).canCreateLink, isTrue);
      expect(_user(monthlyLinksGenerated: 20).canCreateLink, isFalse);
      expect(_user(monthlyLinksGenerated: 20).linksRemaining, 0);
      expect(
        _user(monthlyLinksGenerated: 25).linksRemaining,
        0,
        reason: 'no debe ser negativo tras pasarse de la cuota',
      );

      final premium = _user(
        tier: 'premium',
        monthlyLinksGenerated: 25,
      );
      expect(premium.canCreateLink, isTrue);
    });

    test('remainingPremiumStorageBytes es 0 para free', () {
      final user = _user();
      expect(user.remainingPremiumStorageBytes, 0);
    });
  });

  group('KriptonUser.isInTrial', () {
    test('free con trial activo → true', () {
      final user = _user(
        trialEndsAt: DateTime.now().add(const Duration(days: 3)),
      );
      expect(user.isInTrial, isTrue);
    });

    test('free con trial expirado → false', () {
      final user = _user(
        trialEndsAt: DateTime.now().subtract(const Duration(days: 1)),
      );
      expect(user.isInTrial, isFalse);
    });

    test('premium/business no cuentan como trial', () {
      expect(_user(tier: 'premium').isInTrial, isFalse);
      expect(_user(tier: 'business').isInTrial, isFalse);
    });
  });

  group('Aislamiento de tier entre cuentas', () {
    test('una cuenta Premium previa no contagia a un usuario nuevo Free', () {
      final premium = _user(
        tier: 'premium',
        trialEndsAt: DateTime.now().add(const Duration(days: 14)),
      );
      expect(premium.isPremium, isTrue);

      // Registro nuevo: free sin trial (ya no hay auto-trial en el INSERT).
      final fresh = _user();
      expect(fresh.effectiveTier, 'free');
      expect(fresh.isPremium, isFalse);
      expect(fresh.isFree, isTrue);
      expect(fresh.maxFileSizeBytes, AppConstants.freeMaxFileSizeBytes);

      // La instancia previa no se altera.
      expect(premium.isPremium, isTrue);
    });
  });

  group('Validación de tamaño del flujo de upload', () {
    const twentyFiveMb = 25 * 1024 * 1024;

    test('25 MB con trial activo pasa la validación del cliente (Premium)', () {
      final user = _user(
        trialEndsAt: DateTime.now().add(const Duration(days: 3)),
      );
      expect(user.effectiveTier, 'premium');
      expect(user.maxFileSizeBytes, AppConstants.premiumMaxFileSizeBytes);
      expect(user.exceedsFileSizeLimit(twentyFiveMb), isFalse);
      expect(user.isFree, isFalse,
          reason: 'no debe dispararse el PaywallSheet(file_size)');
    });

    test('25 MB sin trial excede el tope free y dispara paywall file_size', () {
      final user = _user();
      expect(user.maxFileSizeBytes, AppConstants.freeMaxFileSizeBytes);
      expect(user.exceedsFileSizeLimit(twentyFiveMb), isTrue);
      expect(user.isFree, isTrue,
          reason: 'se muestra PaywallSheet(trigger: file_size)');
    });

    test('trial expirado vuelve a aplicar el tope free sobre 25 MB', () {
      final user = _user(
        trialEndsAt: DateTime.now().subtract(const Duration(days: 1)),
      );
      expect(user.effectiveTier, 'free');
      expect(user.exceedsFileSizeLimit(twentyFiveMb), isTrue);
    });
  });
}

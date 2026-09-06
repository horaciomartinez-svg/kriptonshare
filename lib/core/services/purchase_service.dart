import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../../providers/auth_provider.dart';

/// Configuración de compras dentro de la app.
///
/// RevenueCat queda activo SOLO si se cumplen las dos condiciones:
///  1. Se compila con `--dart-define=ENABLE_REVENUECAT=true`.
///  2. Se provee una API key real (no la de relleno) con
///     `--dart-define=REVENUECAT_API_KEY=goog_...`.
///
/// En cualquier otro caso la app opera en modo simulación (mock): las compras
/// se resuelven localmente otorgando Premium en Supabase, sin necesidad de
/// Google Play, facturación ni RevenueCat.
class PurchaseConfig {
  PurchaseConfig._();

  static const bool _flagEnabled = bool.fromEnvironment('ENABLE_REVENUECAT');
  static const String apiKey = String.fromEnvironment(
    'REVENUECAT_API_KEY',
    defaultValue: '',
  );
  static const String _placeholderKey = 'goog_xxxxxxxxxxxxxxxxxxxxxxxxxxxxx';

  /// ¿Está RevenueCat configurado y disponible en este build?
  static bool get isRevenueCatEnabled =>
      _flagEnabled && apiKey.isNotEmpty && apiKey != _placeholderKey;
}

/// Modelo ligero de dominio para un paquete vendible.
///
/// La UI depende de estos modelos, nunca directamente de purchases_flutter.
class PurchasePackage {
  final String identifier;
  final String offeringIdentifier;
  final String? title;
  final String? price;

  const PurchasePackage({
    required this.identifier,
    this.offeringIdentifier = '',
    this.title,
    this.price,
  });
}

/// Ofertas de compra: paquetes de suscripción Premium y add-ons de storage.
class PurchaseOfferings {
  final List<PurchasePackage> currentPackages;
  final List<PurchasePackage> addonPackages;

  const PurchaseOfferings({
    this.currentPackages = const [],
    this.addonPackages = const [],
  });

  bool get isEmpty => currentPackages.isEmpty && addonPackages.isEmpty;
}

/// Contrato de compras. La implementación puede ser RevenueCat (real) o un
/// mock de simulación sin servicios externos.
abstract class IPurchaseService {
  /// `true` si se trata de la simulación (no toca RevenueCat/Google Play).
  bool get isMock;

  Future<PurchaseOfferings> getOfferings();
  Future<bool> purchasePackage(PurchasePackage package);
  Future<bool> purchaseAddon(PurchasePackage package);
  Future<bool> restorePurchases();
}

/// Implementación real basada en RevenueCat.
///
/// Se configura perezosamente en el primer uso, inicializando con el App User
/// ID del usuario actual de Supabase. Si el SDK no puede operar (key inválida,
/// Google Play sin publicar, etc.) las excepciones se propagan al notifier,
/// que automáticamente cae al mock para no bloquear la app.
class RevenueCatPurchaseServiceImpl implements IPurchaseService {
  final Ref _ref;
  bool _configured = false;

  RevenueCatPurchaseServiceImpl(this._ref);

  @override
  bool get isMock => false;

  Future<void> _ensureConfigured() async {
    if (_configured) return;
    if (!PurchaseConfig.isRevenueCatEnabled) {
      throw StateError(
        'RevenueCat desactivado: falta ENABLE_REVENUECAT=true o una '
        'REVENUECAT_API_KEY real.',
      );
    }
    final userId = _ref.read(supabaseClientProvider).auth.currentUser?.id ?? '';
    await Purchases.setLogLevel(LogLevel.info);
    await Purchases.configure(
      PurchasesConfiguration(PurchaseConfig.apiKey)..appUserID = userId,
    );
    _configured = true;
  }

  @override
  Future<PurchaseOfferings> getOfferings() async {
    await _ensureConfigured();
    final offerings = await Purchases.getOfferings();
    final current = offerings.current?.availablePackages ?? const <Package>[];
    final addons = <PurchasePackage>[];
    for (final entry in offerings.all.entries) {
      if (entry.key == offerings.current?.identifier) continue;
      for (final package in entry.value.availablePackages) {
        addons.add(_toDomain(package));
      }
    }
    return PurchaseOfferings(
      currentPackages: current.map(_toDomain).toList(),
      addonPackages: addons,
    );
  }

  PurchasePackage _toDomain(Package package) => PurchasePackage(
        identifier: package.identifier,
        offeringIdentifier: package.offeringIdentifier,
        title: package.storeProduct.title,
        price: package.storeProduct.priceString,
      );

  Future<Package> _resolvePackage(PurchasePackage purchase) async {
    final offerings = await Purchases.getOfferings();
    for (final offering in offerings.all.values) {
      for (final package in offering.availablePackages) {
        if (package.identifier == purchase.identifier) return package;
      }
    }
    throw StateError(
      'Paquete "${purchase.identifier}" no encontrado en las ofertas.',
    );
  }

  @override
  Future<bool> purchasePackage(PurchasePackage package) async {
    await _ensureConfigured();
    await Purchases.purchasePackage(await _resolvePackage(package));
    return true;
  }

  @override
  Future<bool> purchaseAddon(PurchasePackage package) async {
    await _ensureConfigured();
    await Purchases.purchasePackage(await _resolvePackage(package));
    return true;
  }

  @override
  Future<bool> restorePurchases() async {
    await _ensureConfigured();
    await Purchases.restorePurchases();
    return true;
  }
}

/// Implementación simulada (sin RevenueCat ni Google Play).
///
/// Devuelve ofertas de catálogo fijas y las compras conceden Premium
/// directamente en Supabase, permitiendo probar el flujo completo de
/// suscripción sin configurar ningún servicio externo.
class MockPurchaseServiceImpl implements IPurchaseService {
  final Ref _ref;

  MockPurchaseServiceImpl(this._ref);

  @override
  bool get isMock => true;

  @override
  Future<PurchaseOfferings> getOfferings() async {
    return const PurchaseOfferings(
      currentPackages: [
        PurchasePackage(
          identifier: 'premium_monthly',
          offeringIdentifier: 'premium',
          title: 'Kripton Premium (mensual)',
          price: r'$3.99/mes',
        ),
        PurchasePackage(
          identifier: 'premium_annual',
          offeringIdentifier: 'premium',
          title: 'Kripton Premium (anual)',
          price: r'$29.99/año',
        ),
      ],
      addonPackages: [
        PurchasePackage(
          identifier: 'storage_1gb',
          offeringIdentifier: 'storage_addons',
          title: 'Add-on +1 GB',
          price: r'$0.99/mes',
        ),
      ],
    );
  }

  Future<bool> _grantPremium() async {
    await _ref.read(authStateProvider.notifier).setPremiumSimulation(true);
    return true;
  }

  @override
  Future<bool> purchasePackage(PurchasePackage package) => _grantPremium();

  @override
  Future<bool> purchaseAddon(PurchasePackage package) => _grantPremium();

  @override
  Future<bool> restorePurchases() async => true;
}

/// Factory: elige la implementación según la configuración del build.
///
/// Sin los dart-defines de RevenueCat (o con API key de relleno) devuelve el
/// mock, de modo que la app funciona y puede probarse sin ningún servicio.
IPurchaseService createPurchaseService(Ref ref) =>
    PurchaseConfig.isRevenueCatEnabled
        ? RevenueCatPurchaseServiceImpl(ref)
        : MockPurchaseServiceImpl(ref);

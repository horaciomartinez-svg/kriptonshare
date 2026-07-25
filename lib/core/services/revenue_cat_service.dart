import 'package:purchases_flutter/purchases_flutter.dart';

/// Contrato de servicio de compras vía RevenueCat.
abstract class IRevenueCatService {
  Future<void> initialize(String userId);
  Future<CustomerInfo> purchaseSubscriptionPackage(Package package);
  Future<CustomerInfo> purchaseStorageAddon(Package package);
  Future<CustomerInfo> restorePurchases();
  Future<CustomerInfo> getCustomerStatus();
  Future<Offerings?> getOfferings();
}

/// Implementación de RevenueCat para suscripciones Premium y add-ons de storage.
///
/// IMPORTANTE: Reemplaza [_apiKey] por tu API key pública de RevenueCat
/// (goog_... para Android, appl_... para iOS) antes de publicar.
class RevenueCatServiceImpl implements IRevenueCatService {
  static const String _apiKey = String.fromEnvironment(
    'REVENUECAT_API_KEY',
    defaultValue: 'goog_xxxxxxxxxxxxxxxxxxxxxxxxxxxxx', // <- Reemplazar
  );

  @override
  Future<void> initialize(String userId) async {
    await Purchases.setLogLevel(LogLevel.info);
    final configuration = PurchasesConfiguration(_apiKey)..appUserID = userId;
    await Purchases.configure(configuration);
  }

  @override
  Future<Offerings?> getOfferings() async {
    return await Purchases.getOfferings();
  }

  @override
  Future<CustomerInfo> purchaseSubscriptionPackage(Package package) async {
    return await Purchases.purchasePackage(package);
  }

  @override
  Future<CustomerInfo> purchaseStorageAddon(Package package) async {
    // Add-on modelado como suscripción recurrente adherida al App User ID.
    return await Purchases.purchasePackage(package);
  }

  @override
  Future<CustomerInfo> restorePurchases() async {
    return await Purchases.restorePurchases();
  }

  @override
  Future<CustomerInfo> getCustomerStatus() async {
    return await Purchases.getCustomerInfo();
  }
}

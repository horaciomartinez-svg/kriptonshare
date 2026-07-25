import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../../../../core/services/revenue_cat_service.dart';

/// Estado de la pantalla de gestión de almacenamiento y compras.
class StorageUpsellState {
  final bool isLoading;
  final String? error;
  final Offerings? offerings;
  final CustomerInfo? customerInfo;

  const StorageUpsellState({
    this.isLoading = false,
    this.error,
    this.offerings,
    this.customerInfo,
  });

  StorageUpsellState copyWith({
    bool? isLoading,
    String? error,
    Offerings? offerings,
    CustomerInfo? customerInfo,
  }) {
    return StorageUpsellState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      offerings: offerings ?? this.offerings,
      customerInfo: customerInfo ?? this.customerInfo,
    );
  }
}

/// Notifier que maneja ofertas, compras y restauración de RevenueCat.
class StorageUpsellNotifier extends StateNotifier<StorageUpsellState> {
  final IRevenueCatService _revenueCat;

  StorageUpsellNotifier(this._revenueCat) : super(const StorageUpsellState());

  Future<void> loadOfferings() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final offerings = await _revenueCat.getOfferings();
      final customerInfo = await _revenueCat.getCustomerStatus();
      state = state.copyWith(
        offerings: offerings,
        customerInfo: customerInfo,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<bool> purchasePackage(Package package) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final info = await _revenueCat.purchaseSubscriptionPackage(package);
      state = state.copyWith(customerInfo: info, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return false;
    }
  }

  Future<bool> purchaseAddon(Package package) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final info = await _revenueCat.purchaseStorageAddon(package);
      state = state.copyWith(customerInfo: info, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return false;
    }
  }

  Future<void> restorePurchases() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final info = await _revenueCat.restorePurchases();
      state = state.copyWith(customerInfo: info, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }
}

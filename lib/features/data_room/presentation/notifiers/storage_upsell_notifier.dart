import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/purchase_service.dart';

/// Estado de la pantalla de gestión de almacenamiento y compras.
class StorageUpsellState {
  final bool isLoading;
  final String? error;
  final PurchaseOfferings offerings;
  final bool isMockMode;

  const StorageUpsellState({
    this.isLoading = false,
    this.error,
    this.offerings = const PurchaseOfferings(),
    this.isMockMode = false,
  });

  static const Object _unset = Object();

  StorageUpsellState copyWith({
    bool? isLoading,
    Object? error = _unset,
    PurchaseOfferings? offerings,
    bool? isMockMode,
  }) {
    return StorageUpsellState(
      isLoading: isLoading ?? this.isLoading,
      error: identical(error, _unset) ? this.error : error as String?,
      offerings: offerings ?? this.offerings,
      isMockMode: isMockMode ?? this.isMockMode,
    );
  }
}

/// Notifier que maneja ofertas, compras y restauración.
///
/// Si el servicio real (RevenueCat) falla en tiempo de ejecución, cae
/// automáticamente al mock para que el flujo continúe otorgando acceso sin
/// bloquear la app.
class StorageUpsellNotifier extends StateNotifier<StorageUpsellState> {
  final Ref _ref;
  IPurchaseService _service;

  StorageUpsellNotifier(this._ref, IPurchaseService service)
      : _service = service,
        super(StorageUpsellState(isMockMode: service.isMock));

  /// Ejecuta [op] contra el servicio actual. Si falla y el servicio era el
  /// real, conmuta al mock y reintenta una vez con él.
  Future<T> _run<T>(Future<T> Function(IPurchaseService service) op) async {
    try {
      return await op(_service);
    } catch (e) {
      debugPrint('[StorageUpsellNotifier] Fallo de ${_service.runtimeType}: $e');
      if (!_service.isMock) {
        _service = MockPurchaseServiceImpl(_ref);
        state = state.copyWith(isMockMode: true);
        return op(_service);
      }
      rethrow;
    }
  }

  Future<void> loadOfferings() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final offerings = await _run((s) => s.getOfferings());
      state = state.copyWith(offerings: offerings, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<bool> purchasePackage(PurchasePackage package) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final ok = await _run((s) => s.purchasePackage(package));
      state = state.copyWith(isLoading: false);
      return ok;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return false;
    }
  }

  Future<bool> purchaseAddon(PurchasePackage package) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final ok = await _run((s) => s.purchaseAddon(package));
      state = state.copyWith(isLoading: false);
      return ok;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return false;
    }
  }

  Future<void> restorePurchases() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _run((s) => s.restorePurchases());
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }
}

import '../utils/constants.dart';
import 'kripton_file.dart';

/// Resumen calculado de los enlaces activos del usuario.
///
/// Es lógica pura (sin Flutter) para poder testearse de forma aislada. Se
/// deriva de la misma lista que alimenta la sección "Active Links" del
/// Dashboard, por lo que no añade consultas.
class ActiveLinksSummary {
  /// Número de links vigentes (activos y no expirados).
  final int activeCount;

  /// Suma de bytes de los archivos con link activo (una vez por archivo).
  final int totalSizeBytes;

  /// Denominador del límite por cantidad de links activos, o `null` si el plan
  /// no limita esta dimensión.
  final int? countLimit;

  /// Denominador del límite de almacenamiento, o `null` si el plan no limita
  /// esta dimensión.
  final int? storageLimitBytes;

  const ActiveLinksSummary({
    this.activeCount = 0,
    this.totalSizeBytes = 0,
    this.countLimit,
    this.storageLimitBytes,
  });

  /// Construye el resumen SOLO con links vigentes ([ShareLink.isActive] y
  /// `expiresAt` futuro). El tamaño se cuenta una vez por `fileId` para
  /// reflejar "archivos con link activo", no links duplicados del mismo archivo.
  factory ActiveLinksSummary.fromLinks(
    List<ShareLink> links, {
    required String effectiveTier,
    DateTime? now,
  }) {
    final reference = now ?? DateTime.now();
    var activeCount = 0;
    for (final link in links) {
      if (!link.isActive) continue;
      if (!link.expiresAt.isAfter(reference)) continue;
      activeCount++;
    }

    final limits = limitsForTier(effectiveTier);
    return ActiveLinksSummary(
      activeCount: activeCount,
      totalSizeBytes: sumActiveFileBytes(links, now: reference),
      countLimit: limits.countLimit,
      storageLimitBytes: limits.storageLimitBytes,
    );
  }

  /// Suma de bytes de los archivos con link activo y no expirado, contando
  /// cada archivo una sola vez (aunque tenga varios links). Es la única
  /// implementación del cálculo: la consumen tanto el Dashboard como
  /// [analyticsActiveStorageProvider] de Analytics.
  static int sumActiveFileBytes(List<ShareLink> links, {DateTime? now}) {
    final reference = now ?? DateTime.now();
    final countedFileIds = <String>{};
    var total = 0;
    for (final link in links) {
      if (!link.isActive) continue;
      if (!link.expiresAt.isAfter(reference)) continue;
      if (countedFileIds.add(link.fileId)) {
        total += link.fileSizeBytes;
      }
    }
    return total;
  }

  /// Denominadores por tier (misma lógica de tier efectivo que el resto de la
  /// app: business > premium/trial > free).
  ///
  /// - Free: limita por CANTIDAD de links activos (3); sin cuota de almacenamiento.
  /// - Premium: 1 GB de almacenamiento; sin límite de cantidad.
  /// - Business: 5 GB de almacenamiento; sin límite de cantidad.
  static ({int? countLimit, int? storageLimitBytes}) limitsForTier(
    String effectiveTier,
  ) {
    switch (effectiveTier) {
      case AppConstants.tierBusiness:
        return (
          countLimit: null,
          storageLimitBytes: AppConstants.businessBaseStorageBytes,
        );
      case AppConstants.tierPremium:
        return (
          countLimit: null,
          storageLimitBytes: AppConstants.premiumBaseStorageBytes,
        );
      default:
        return (
          countLimit: AppConstants.freeMaxActiveLinks,
          storageLimitBytes: null,
        );
    }
  }

  /// Ocupación del límite de cantidad en [0, 1], o `null` si no aplica.
  double? get countRatio {
    final limit = countLimit;
    if (limit == null || limit <= 0) return null;
    return activeCount / limit;
  }

  /// Ocupación del límite de almacenamiento en [0, 1], o `null` si no aplica.
  double? get storageRatio {
    final limit = storageLimitBytes;
    if (limit == null || limit <= 0) return null;
    return totalSizeBytes / limit;
  }

  /// `true` cuando se alcanza o supera el 80 % del límite de cantidad.
  bool get isCountNearLimit {
    final ratio = countRatio;
    return ratio != null && ratio >= 0.8;
  }

  /// `true` cuando se alcanza o supera el 80 % del límite de almacenamiento.
  bool get isStorageNearLimit {
    final ratio = storageRatio;
    return ratio != null && ratio >= 0.8;
  }
}

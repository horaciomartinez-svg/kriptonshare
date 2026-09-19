import 'package:flutter_test/flutter_test.dart';
import 'package:kriptonshare/models/active_links_summary.dart';
import 'package:kriptonshare/models/kripton_file.dart';
import 'package:kriptonshare/utils/constants.dart';

const int _mb = 1024 * 1024;

ShareLink _link({
  required String id,
  String? fileId,
  int fileSizeBytes = 0,
  bool isActive = true,
  Duration expiresIn = const Duration(hours: 1),
  required DateTime now,
}) {
  return ShareLink(
    id: id,
    fileId: fileId ?? 'file-$id',
    createdBy: 'user-1',
    expiresAt: now.add(expiresIn),
    createdAt: now,
    isActive: isActive,
    fileSizeBytes: fileSizeBytes,
  );
}

void main() {
  final now = DateTime(2026, 9, 16, 12);

  group('ActiveLinksSummary.fromLinks — filtrado y totales', () {
    test('sin links devuelve 0 activos y 0 bytes', () {
      final summary = ActiveLinksSummary.fromLinks(
        const [],
        effectiveTier: 'free',
        now: now,
      );

      expect(summary.activeCount, 0);
      expect(summary.totalSizeBytes, 0);
    });

    test('excluye links revocados y expirados', () {
      final summary = ActiveLinksSummary.fromLinks(
        [
          _link(id: 'vigente', fileSizeBytes: 10 * _mb, now: now),
          _link(id: 'revocado', fileSizeBytes: 5 * _mb, isActive: false, now: now),
          _link(
            id: 'expirado',
            fileSizeBytes: 7 * _mb,
            expiresIn: const Duration(hours: -1),
            now: now,
          ),
        ],
        effectiveTier: 'premium',
        now: now,
      );

      expect(summary.activeCount, 1);
      expect(summary.totalSizeBytes, 10 * _mb);
    });

    test('no cuenta un link que expira exactamente ahora', () {
      final summary = ActiveLinksSummary.fromLinks(
        [_link(id: 'justo', fileSizeBytes: 4 * _mb, expiresIn: Duration.zero, now: now)],
        effectiveTier: 'free',
        now: now,
      );

      expect(summary.activeCount, 0);
      expect(summary.totalSizeBytes, 0);
    });

    test('suma correctamente los bytes de los links vigentes', () {
      final summary = ActiveLinksSummary.fromLinks(
        [
          _link(id: 'a', fileSizeBytes: 100 * _mb, now: now),
          _link(id: 'b', fileSizeBytes: 48 * _mb, now: now),
        ],
        effectiveTier: 'free',
        now: now,
      );

      expect(summary.activeCount, 2);
      expect(summary.totalSizeBytes, 148 * _mb);
    });

    test('cuenta el tamaño una sola vez por archivo', () {
      final summary = ActiveLinksSummary.fromLinks(
        [
          _link(id: 'l1', fileId: 'f1', fileSizeBytes: 30 * _mb, now: now),
          _link(id: 'l2', fileId: 'f1', fileSizeBytes: 30 * _mb, now: now),
        ],
        effectiveTier: 'free',
        now: now,
      );

      expect(summary.activeCount, 2, reason: 'son 2 links activos');
      expect(summary.totalSizeBytes, 30 * _mb, reason: 'pero 1 solo archivo');
    });
  });

  group('ActiveLinksSummary — denominadores por tier', () {
    test('free limita por cantidad y no define cuota de almacenamiento', () {
      final summary = ActiveLinksSummary.fromLinks(
        const [],
        effectiveTier: 'free',
        now: now,
      );

      expect(summary.countLimit, AppConstants.freeMaxActiveLinks);
      expect(summary.storageLimitBytes, isNull);
    });

    test('premium: 1 GB de almacenamiento, sin límite de cantidad', () {
      final summary = ActiveLinksSummary.fromLinks(
        const [],
        effectiveTier: 'premium',
        now: now,
      );

      expect(summary.countLimit, isNull);
      expect(summary.storageLimitBytes, AppConstants.premiumBaseStorageBytes);
    });

    test('business: 5 GB de almacenamiento, sin límite de cantidad', () {
      final summary = ActiveLinksSummary.fromLinks(
        const [],
        effectiveTier: 'business',
        now: now,
      );

      expect(summary.countLimit, isNull);
      expect(summary.storageLimitBytes, AppConstants.businessBaseStorageBytes);
    });

    test('un tier desconocido se trata como free', () {
      final summary = ActiveLinksSummary.fromLinks(
        const [],
        effectiveTier: 'enterprise',
        now: now,
      );

      expect(summary.countLimit, AppConstants.freeMaxActiveLinks);
      expect(summary.storageLimitBytes, isNull);
    });
  });

  group('ActiveLinksSummary — ratios y umbral de aviso (80%)', () {
    test('free con 3/3 links activos marca aviso de cantidad', () {
      final summary = ActiveLinksSummary.fromLinks(
        [
          _link(id: 'a', fileSizeBytes: _mb, now: now),
          _link(id: 'b', fileSizeBytes: _mb, now: now),
          _link(id: 'c', fileSizeBytes: _mb, now: now),
        ],
        effectiveTier: 'free',
        now: now,
      );

      expect(summary.countRatio, 1.0);
      expect(summary.isCountNearLimit, isTrue);
      expect(summary.isStorageNearLimit, isFalse);
    });

    test('premium justo en el 80% marca aviso de almacenamiento', () {
      final summary = ActiveLinksSummary.fromLinks(
        [
          _link(
            id: 'a',
            // ceil evita que el redondeo deje la razón justo por debajo de 0.8.
            fileSizeBytes: (AppConstants.premiumBaseStorageBytes * 0.8).ceil(),
            now: now,
          ),
        ],
        effectiveTier: 'premium',
        now: now,
      );

      expect(summary.storageRatio, closeTo(0.8, 1e-6));
      expect(summary.isStorageNearLimit, isTrue);
    });

    test('premium por debajo del 80% no marca aviso', () {
      final summary = ActiveLinksSummary.fromLinks(
        [
          _link(
            id: 'a',
            fileSizeBytes: (AppConstants.premiumBaseStorageBytes * 0.5).round(),
            now: now,
          ),
        ],
        effectiveTier: 'premium',
        now: now,
      );

      expect(summary.isStorageNearLimit, isFalse);
    });
  });
}

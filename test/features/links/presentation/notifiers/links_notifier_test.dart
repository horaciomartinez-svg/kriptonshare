import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kriptonshare/core/error/failures.dart';
import 'package:kriptonshare/features/links/domain/entities/link_entity.dart';
import 'package:kriptonshare/features/links/domain/repositories/i_links_repository.dart';
import 'package:kriptonshare/features/links/domain/usecases/delete_file.dart';
import 'package:kriptonshare/features/links/domain/usecases/get_user_links.dart';
import 'package:kriptonshare/features/links/domain/usecases/revoke_link.dart';
import 'package:kriptonshare/features/links/presentation/notifiers/links_notifier.dart';
import 'package:mocktail/mocktail.dart';

class MockLinksRepository extends Mock implements ILinksRepository {}

void main() {
  late MockLinksRepository mockLinksRepository;
  late LinksNotifier notifier;

  setUp(() {
    mockLinksRepository = MockLinksRepository();
    notifier = LinksNotifier(
      getUserLinks: GetUserLinksUseCase(mockLinksRepository),
      revokeLink: RevokeLinkUseCase(mockLinksRepository),
      deleteFile: DeleteFileUseCase(mockLinksRepository),
    );
  });

  tearDown(() {
    notifier.dispose();
  });

  group('LinksNotifier', () {
    final link = LinkEntity(
      id: 'link-1',
      fileId: 'file-1',
      createdBy: 'user-1',
      expiresAt: DateTime(2026, 12, 31),
      createdAt: DateTime(2026, 6, 1),
      accessCount: 3,
    );

    test('should load initial page and set hasMore to false when fewer than pageSize items', () async {
      // Arrange
      when(() => mockLinksRepository.getUserLinks(
            'user-1',
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
          )).thenAnswer((_) async => Right([link]));

      // Act
      await notifier.loadLinks('user-1');

      // Assert
      expect(notifier.state.isLoading, false);
      expect(notifier.state.error, isNull);
      expect(notifier.state.links.length, 1);
      expect(notifier.state.hasMore, false);
      expect(notifier.state.currentPage, 1);
    });

    test('should set hasMore to true when page is full', () async {
      // Arrange
      final fullPage = List.generate(
        LinksState.pageSize,
        (i) => link.copyWith(id: 'link-$i'),
      );
      when(() => mockLinksRepository.getUserLinks(
            'user-1',
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
          )).thenAnswer((_) async => Right(fullPage));

      // Act
      await notifier.loadLinks('user-1');

      // Assert
      expect(notifier.state.links.length, LinksState.pageSize);
      expect(notifier.state.hasMore, true);
    });

    test('should append more links on loadMore', () async {
      // Arrange
      final firstPage = List.generate(
        LinksState.pageSize,
        (i) => link.copyWith(id: 'first-$i'),
      );
      final secondPage = [link.copyWith(id: 'second-1')];

      when(() => mockLinksRepository.getUserLinks(
            'user-1',
            limit: LinksState.pageSize,
            offset: 0,
          )).thenAnswer((_) async => Right(firstPage));
      when(() => mockLinksRepository.getUserLinks(
            'user-1',
            limit: LinksState.pageSize,
            offset: LinksState.pageSize,
          )).thenAnswer((_) async => Right(secondPage));

      // Act
      await notifier.loadLinks('user-1');
      await notifier.loadMore('user-1');

      // Assert
      expect(notifier.state.links.length, LinksState.pageSize + 1);
      expect(notifier.state.hasMore, false);
      expect(notifier.state.currentPage, 2);
      expect(notifier.state.isLoadingMore, false);
    });

    test('should set error when loadLinks fails', () async {
      // Arrange
      const failure = ServerFailure('Network error');
      when(() => mockLinksRepository.getUserLinks(
            'user-1',
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
          )).thenAnswer((_) async => const Left(failure));

      // Act
      await notifier.loadLinks('user-1');

      // Assert
      expect(notifier.state.isLoading, false);
      expect(notifier.state.error, failure.message);
      expect(notifier.state.links, isEmpty);
    });
  });
}

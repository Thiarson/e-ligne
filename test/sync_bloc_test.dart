import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ligne/core/errors/sync_exception.dart';
import 'package:ligne/core/services/admin/firebase_sync_service.dart';
import 'package:ligne/ui/bloc/sync/sync_bloc.dart';
import 'package:mocktail/mocktail.dart';

// Mock classes
class MockFirebaseSyncService extends Mock implements FirebaseSyncService {
  @override
  Future<void> syncData() => super.noSuchMethod(
        Invocation.method(#syncData, []),
      ) as Future<void>;
}

void main() {
  late MockFirebaseSyncService mockSyncService;
  late SyncBloc syncBloc;

  setUp(() {
    mockSyncService = MockFirebaseSyncService();
    syncBloc = SyncBloc(syncService: mockSyncService);
  });

  tearDown(() {
    syncBloc.close();
  });

  group('SyncBloc', () {
    test('initial state is SyncInitial', () {
      expect(syncBloc.state, isA<SyncInitial>());
    });

    blocTest<SyncBloc, SyncState>(
      'emits [SyncInProgress, SyncSuccess] when sync is successful',
      build: () {
        when(() => mockSyncService.syncData()).thenAnswer((_) async {});
        return syncBloc;
      },
      act: (bloc) => bloc.add(const SyncData()),
      expect: () => [
        isA<SyncInProgress>(),
        isA<SyncSuccess>(),
      ],
      verify: (_) {
        verify(() => mockSyncService.syncData()).called(1);
      },
    );

    blocTest<SyncBloc, SyncState>(
      'emits [SyncInProgress, SyncFailure] when sync fails',
      build: () {
        when(() => mockSyncService.syncData()).thenThrow(
          const SyncException('Sync failed'),
        );
        return syncBloc;
      },
      act: (bloc) => bloc.add(const SyncData()),
      expect: () => [
        isA<SyncInProgress>(),
        isA<SyncFailure>(),
      ],
      verify: (_) {
        verify(() => mockSyncService.syncData()).called(1);
      },
    );
  });
}

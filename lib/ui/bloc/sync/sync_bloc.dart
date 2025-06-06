import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:ligne/core/errors/sync_exception.dart';
import 'package:ligne/core/services/admin/firebase_sync_service.dart';

// Events
abstract class SyncEvent extends Equatable {
  const SyncEvent();

  @override
  List<Object> get props => [];
}

class SyncData extends SyncEvent {
  const SyncData();
}

// States
abstract class SyncState extends Equatable {
  final bool isSyncing;
  final String? error;
  final bool isSynced;

  const SyncState({
    this.isSyncing = false,
    this.error,
    this.isSynced = false,
  });

  @override
  List<Object?> get props => [isSyncing, error, isSynced];
}

class SyncInitial extends SyncState {
  const SyncInitial() : super(isSyncing: false, isSynced: false);
}

class SyncInProgress extends SyncState {
  const SyncInProgress() : super(isSyncing: true, isSynced: false);
}

class SyncSuccess extends SyncState {
  const SyncSuccess() : super(isSyncing: false, isSynced: true);
}

class SyncFailure extends SyncState {
  final String errorMessage;
  
  const SyncFailure(this.errorMessage) 
      : super(isSyncing: false, error: errorMessage, isSynced: false);
}

// BLoC
class SyncBloc extends Bloc<SyncEvent, SyncState> {
  final FirebaseSyncService _syncService;

  SyncBloc({FirebaseSyncService? syncService})
      : _syncService = syncService ?? FirebaseSyncService(),
        super(const SyncInitial()) {
    on<SyncData>(_onSyncData);
  }

  Future<void> _onSyncData(SyncData event, Emitter<SyncState> emit) async {
    emit(const SyncInProgress());

    try {
      await _syncService.syncData();
      emit(const SyncSuccess());
    } on SyncException catch (e) {
      emit(SyncFailure(e.toString()));
    } catch (e) {
      emit(SyncFailure('An unexpected error occurred: $e'));
    }
  }
}

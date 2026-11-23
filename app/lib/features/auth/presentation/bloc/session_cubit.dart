import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/app_failure.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

/// What the app knows about the current session. Drives router redirects.
sealed class SessionState {
  const SessionState();
}

/// Cold start: the persisted session has not been checked yet.
final class SessionUnknown extends SessionState {
  const SessionUnknown();
}

final class SessionUnauthenticated extends SessionState {
  const SessionUnauthenticated();
}

/// Signed in but `profiles.is_active = false`; never allowed into the app.
final class SessionInactive extends SessionState {
  const SessionInactive();
}

final class SessionAuthenticated extends SessionState {
  const SessionAuthenticated(this.user);

  final AppUser user;

  @override
  bool operator ==(Object other) => other is SessionAuthenticated && other.user == user;

  @override
  int get hashCode => user.hashCode;
}

class SessionCubit extends Cubit<SessionState> {
  SessionCubit(this._repo) : super(const SessionUnknown()) {
    _subscription = _repo.events.listen(_onEvent);
    unawaited(restore());
  }

  final AuthRepository _repo;
  late final StreamSubscription<AuthEvent> _subscription;

  /// Restores the persisted session and loads the profile (role source).
  Future<void> restore() async {
    final result = await _repo.restoreSession();
    if (isClosed) {
      return;
    }
    emit(
      result.match(
        (failure) => switch (failure) {
          AccountInactiveFailure() => const SessionInactive(),
          _ => const SessionUnauthenticated(),
        },
        SessionAuthenticated.new,
      ),
    );
  }

  void _onEvent(AuthEvent event) {
    switch (event) {
      case AuthEvent.signedIn:
        unawaited(restore());
      case AuthEvent.signedOut:
        if (!isClosed) {
          emit(const SessionUnauthenticated());
        }
    }
  }

  Future<void> signOut() async {
    await _repo.signOut();
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}

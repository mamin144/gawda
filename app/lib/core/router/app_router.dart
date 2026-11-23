import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/entities/app_user.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/presentation/bloc/login_cubit.dart';
import '../../features/auth/presentation/bloc/session_cubit.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/home/presentation/pages/admin_home_page.dart';
import '../../features/home/presentation/pages/site_home_page.dart';
import '../widgets/loading_view.dart';

/// Pure redirect logic, unit-tested without a router or widget tree.
/// Role comes from the session (sourced from `profiles`), never from the URL.
String? resolveRedirect({required SessionState session, required String location}) =>
    switch (session) {
      SessionUnknown() => location == '/splash' ? null : '/splash',
      SessionUnauthenticated() || SessionInactive() => location == '/login' ? null : '/login',
      SessionAuthenticated(:final user) => _authenticatedRedirect(user.role, location),
    };

String? _authenticatedRedirect(UserRole role, String location) {
  final home = role == UserRole.admin ? '/admin' : '/site';
  if (location == '/splash' || location == '/login') {
    return home;
  }
  if (location == '/admin' && role != UserRole.admin) {
    return '/site';
  }
  if (location == '/site' && role != UserRole.siteUser) {
    return '/admin';
  }
  return null;
}

/// Re-runs router redirects whenever the session changes.
GoRouter buildRouter(SessionCubit cubit) => GoRouter(
  initialLocation: '/splash',
  refreshListenable: GoRouterRefreshStream(cubit.stream),
  redirect: (context, state) =>
      resolveRedirect(session: cubit.state, location: state.matchedLocation),
  routes: [
    GoRoute(path: '/splash', builder: (context, state) => const LoadingView()),
    GoRoute(
      path: '/login',
      builder: (context, state) => BlocProvider(
        create: (context) => LoginCubit(context.read<AuthRepository>()),
        child: const LoginPage(),
      ),
    ),
    GoRoute(path: '/admin', builder: (context, state) => const AdminHomePage()),
    GoRoute(path: '/site', builder: (context, state) => const SiteHomePage()),
  ],
);

/// Adapts a cubit stream to the [Listenable] API `go_router` expects.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}

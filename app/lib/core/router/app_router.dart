import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/presentation/admin_shell.dart';
import '../../features/auth/domain/entities/app_user.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/presentation/bloc/login_cubit.dart';
import '../../features/auth/presentation/bloc/session_cubit.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/certificates/presentation/pages/certificate_entry_page.dart';
import '../../features/home/presentation/pages/admin_home_page.dart';
import '../../features/sites/presentation/pages/sites_page.dart';
import '../../features/users/presentation/pages/users_page.dart';
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
  if (_isUnder(location, '/admin') && role != UserRole.admin) {
    return '/site';
  }
  if (_isUnder(location, '/site') && role != UserRole.siteUser) {
    return '/admin';
  }
  return null;
}

/// Segment-prefix match: `/admin` and `/admin/...`, never `/administrator`.
bool _isUnder(String location, String root) => location == root || location.startsWith('$root/');

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
    ShellRoute(
      builder: (context, state, child) => AdminShell(child: child),
      routes: [
        GoRoute(path: '/admin', builder: (context, state) => const AdminHomePage()),
        GoRoute(path: '/admin/sites', builder: (context, state) => const SitesPage()),
        GoRoute(path: '/admin/users', builder: (context, state) => const UsersPage()),
      ],
    ),
    GoRoute(path: '/site', builder: (context, state) => const CertificateEntryPage()),
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

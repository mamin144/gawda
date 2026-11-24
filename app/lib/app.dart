import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/error_view.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/presentation/bloc/session_cubit.dart';
import 'features/sites/domain/repositories/sites_repository.dart';
import 'features/users/domain/repositories/users_repository.dart';
import 'l10n/gen/app_localizations.dart';

/// Root widget: owns the session cubit and router lifecycles and wires
/// theme, Arabic RTL localization and role-based routing together.
class App extends StatefulWidget {
  const App({super.key, required this.repo, required this.sitesRepo, required this.usersRepo});

  final AuthRepository repo;
  final SitesRepository sitesRepo;
  final UsersRepository usersRepo;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final SessionCubit _cubit;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _cubit = SessionCubit(widget.repo);
    _router = buildRouter(_cubit);
  }

  @override
  void dispose() {
    _router.dispose();
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>.value(value: widget.repo),
        RepositoryProvider<SitesRepository>.value(value: widget.sitesRepo),
        RepositoryProvider<UsersRepository>.value(value: widget.usersRepo),
      ],
      child: BlocProvider<SessionCubit>.value(
        value: _cubit,
        child: MaterialApp.router(
          onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
          locale: const Locale('ar'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          routerConfig: _router,
        ),
      ),
    );
  }
}

/// Shown when compile-time configuration is missing or unsafe. Fail fast,
/// never start with a guessed URL or key.
class ConfigErrorApp extends StatelessWidget {
  const ConfigErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      locale: const Locale('ar'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: AppTheme.light(),
      home: Builder(
        builder: (context) =>
            Scaffold(body: ErrorView(message: AppLocalizations.of(context).errorConfig)),
      ),
    );
  }
}

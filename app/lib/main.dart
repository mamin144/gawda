import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/data/services/auth_service.dart';
import 'features/auth/data/services/profile_service.dart';
import 'features/sites/data/repositories/sites_repository_impl.dart';
import 'features/sites/data/services/sites_service.dart';
import 'features/users/data/repositories/users_repository_impl.dart';
import 'features/users/data/services/users_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Clean deep-linkable URLs on web (no '#' fragment); no-op on Android.
  usePathUrlStrategy();

  final AppConfig config;
  try {
    config = AppConfig.fromEnvironment();
  } on ConfigException {
    runApp(const ConfigErrorApp());
    return;
  }

  // Only the project URL and the publishable key ever reach the client.
  await Supabase.initialize(url: config.supabaseUrl, publishableKey: config.supabasePublishableKey);

  final client = Supabase.instance.client;
  final repo = AuthRepositoryImpl(
    SupabaseAuthService(client.auth),
    SupabaseProfileService(client),
  );

  runApp(
    App(
      repo: repo,
      sitesRepo: SitesRepositoryImpl(SupabaseSitesService(client)),
      usersRepo: UsersRepositoryImpl(SupabaseUsersService(client)),
    ),
  );
}

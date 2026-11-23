import 'package:flutter/material.dart';
import 'package:gawda_app/core/theme/app_theme.dart';
import 'package:gawda_app/l10n/gen/app_localizations.dart';

/// Test-only wrapper: localized Arabic RTL app with the real light theme.
Widget wrapLocalized(Widget child) => MaterialApp(
  locale: const Locale('ar'),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  theme: AppTheme.light(),
  home: child,
);

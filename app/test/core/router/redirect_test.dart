import 'package:flutter_test/flutter_test.dart';
import 'package:gawda_app/core/router/app_router.dart';
import 'package:gawda_app/features/auth/domain/entities/app_user.dart';
import 'package:gawda_app/features/auth/presentation/bloc/session_cubit.dart';

void main() {
  const admin = AppUser(id: 'a', fullName: 'مدير (seed)', role: UserRole.admin, isActive: true);
  const site = AppUser(id: 's', fullName: 'موقع (seed)', role: UserRole.siteUser, isActive: true);

  final cases = <(SessionState, String, String?)>[
    (const SessionUnknown(), '/login', '/splash'),
    (const SessionUnknown(), '/splash', null),
    (const SessionUnauthenticated(), '/admin', '/login'),
    (const SessionUnauthenticated(), '/login', null),
    (const SessionInactive(), '/site', '/login'),
    (const SessionInactive(), '/login', null),
    (const SessionAuthenticated(admin), '/login', '/admin'),
    (const SessionAuthenticated(admin), '/splash', '/admin'),
    (const SessionAuthenticated(admin), '/site', '/admin'),
    (const SessionAuthenticated(admin), '/admin', null),
    (const SessionAuthenticated(site), '/login', '/site'),
    (const SessionAuthenticated(site), '/splash', '/site'),
    (const SessionAuthenticated(site), '/admin', '/site'),
    (const SessionAuthenticated(site), '/site', null),
    // P3: every location under /admin is admin-only, every one under /site
    // is site-user-only. Segment-prefix match, so /administrator is not /admin.
    (const SessionAuthenticated(site), '/admin/sites', '/site'),
    (const SessionAuthenticated(site), '/admin/users', '/site'),
    (const SessionAuthenticated(admin), '/admin/users', null),
    (const SessionAuthenticated(admin), '/admin/sites', null),
    (const SessionAuthenticated(admin), '/site/anything', '/admin'),
    (const SessionAuthenticated(site), '/site/anything', null),
    (const SessionAuthenticated(site), '/administrator', null),
    (const SessionAuthenticated(admin), '/sites', null),
  ];

  for (final (session, location, expected) in cases) {
    test('${session.runtimeType} at $location -> ${expected ?? 'stay'}', () {
      expect(resolveRedirect(session: session, location: location), expected);
    });
  }
}

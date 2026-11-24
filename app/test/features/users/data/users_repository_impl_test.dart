import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:gawda_app/core/error/app_failure.dart';
import 'package:gawda_app/core/error/result.dart';
import 'package:gawda_app/features/auth/domain/entities/app_user.dart';
import 'package:gawda_app/features/users/data/repositories/users_repository_impl.dart';
import 'package:gawda_app/features/users/data/services/users_service.dart';
import 'package:gawda_app/features/users/domain/entities/managed_user.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockUsersService extends Mock implements UsersService {}

void main() {
  late MockUsersService service;
  late UsersRepositoryImpl repo;

  const siteA = '11111111-1111-1111-1111-111111111111';
  const siteB = '22222222-2222-2222-2222-222222222222';

  const siteUserRow = {
    'id': 'u1',
    'email': 'site.user@example.test',
    'full_name': 'مستخدم موقع (seed)',
    'role': 'site_user',
    'is_active': true,
    'invite_pending': true,
    'site_ids': [siteA, siteB],
  };
  const adminRow = {
    'id': 'u2',
    'email': 'admin@example.test',
    'full_name': 'مدير (seed)',
    'role': 'admin',
    'is_active': false,
    'invite_pending': false,
    'site_ids': <String>[],
  };

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    service = MockUsersService();
    repo = UsersRepositoryImpl(service);
  });

  Future<Result<String>> invite() => repo.invite(
    email: 'new@example.test',
    fullName: 'جديد (seed)',
    role: UserRole.siteUser,
    siteIds: const [siteA],
  );

  void inviteThrows(int status, Object? details) {
    when(
      () => service.createUser(any()),
    ).thenThrow(FunctionException(status: status, details: details));
  }

  group('list', () {
    test('maps role, invite_pending and the site_ids array to ManagedUser', () async {
      when(() => service.fetchUsers()).thenAnswer((_) async => [siteUserRow, adminRow]);

      final result = await repo.list();

      expect(result.getOrElse((_) => []), const [
        ManagedUser(
          id: 'u1',
          email: 'site.user@example.test',
          fullName: 'مستخدم موقع (seed)',
          role: UserRole.siteUser,
          isActive: true,
          invitePending: true,
          siteIds: [siteA, siteB],
        ),
        ManagedUser(
          id: 'u2',
          email: 'admin@example.test',
          fullName: 'مدير (seed)',
          role: UserRole.admin,
          isActive: false,
          invitePending: false,
          siteIds: [],
        ),
      ]);
    });

    test('treats a null site_ids as an empty list', () async {
      when(
        () => service.fetchUsers(),
      ).thenAnswer(
        (_) async => [
          <String, dynamic>{...adminRow, 'site_ids': null},
        ],
      );

      final users = (await repo.list()).getOrElse((_) => []);

      expect(users.single.siteIds, isEmpty);
    });

    test('maps P0001 forbidden to ForbiddenFailure', () async {
      when(
        () => service.fetchUsers(),
      ).thenThrow(const PostgrestException(message: 'forbidden', code: 'P0001'));

      expect(await repo.list(), const Left<AppFailure, List<ManagedUser>>(ForbiddenFailure()));
    });
  });

  group('invite', () {
    test('sends email, full_name, role (db value) and site_ids; returns the new id', () async {
      when(() => service.createUser(any())).thenAnswer((_) async => {'id': 'new-id'});

      final result = await invite();

      expect(result, const Right<AppFailure, String>('new-id'));
      verify(
        () => service.createUser({
          'email': 'new@example.test',
          'full_name': 'جديد (seed)',
          'role': 'site_user',
          'site_ids': [siteA],
        }),
      ).called(1);
    });

    test('sends role admin as "admin"', () async {
      when(() => service.createUser(any())).thenAnswer((_) async => {'id': 'x'});

      await repo.invite(
        email: 'a@example.test',
        fullName: 'a',
        role: UserRole.admin,
        siteIds: const [],
      );

      final body = verify(() => service.createUser(captureAny())).captured.single as Map;
      expect(body['role'], 'admin');
    });

    test('409 user_exists -> BusinessRuleFailure(user_exists)', () async {
      inviteThrows(409, {'error': 'user_exists'});
      expect(await invite(), const Left<AppFailure, String>(BusinessRuleFailure('user_exists')));
    });

    test('400 invalid_sites -> BusinessRuleFailure(invalid_sites)', () async {
      inviteThrows(400, {'error': 'invalid_sites'});
      expect(await invite(), const Left<AppFailure, String>(BusinessRuleFailure('invalid_sites')));
    });

    test('400 invalid_sites as a raw JSON string body is still recognised', () async {
      inviteThrows(400, '{"error":"invalid_sites"}');
      expect(await invite(), const Left<AppFailure, String>(BusinessRuleFailure('invalid_sites')));
    });

    test('400 invalid_request -> ServerFailure(code: invalid_request)', () async {
      inviteThrows(400, {'error': 'invalid_request'});
      final failure = (await invite()).getLeft().toNullable();
      expect(failure, isA<ServerFailure>().having((f) => f.code, 'code', 'invalid_request'));
    });

    test('400 with an unparseable body -> ServerFailure(code: invalid_request)', () async {
      inviteThrows(400, 'Bad Request');
      final failure = (await invite()).getLeft().toNullable();
      expect(failure, isA<ServerFailure>().having((f) => f.code, 'code', 'invalid_request'));
    });

    test('403 -> ForbiddenFailure', () async {
      inviteThrows(403, {'error': 'forbidden'});
      expect(await invite(), const Left<AppFailure, String>(ForbiddenFailure()));
    });

    for (final code in const ['config_missing', 'create_failed', 'internal_error']) {
      test('500 $code -> ServerFailure(code: $code)', () async {
        inviteThrows(500, {'error': code});
        final failure = (await invite()).getLeft().toNullable();
        expect(failure, isA<ServerFailure>().having((f) => f.code, 'code', code));
      });
    }

    test('unknown status falls back to the generic mapping', () async {
      inviteThrows(502, 'Bad Gateway');
      expect((await invite()).getLeft().toNullable(), isA<UnexpectedFailure>());
    });

    test('a transport failure (FunctionsFetchException) -> NetworkFailure', () async {
      when(
        () => service.createUser(any()),
      ).thenThrow(const FunctionsFetchException(details: 'connection refused'));
      expect(await invite(), const Left<AppFailure, String>(NetworkFailure()));
    });

    test('a success body without id -> UnexpectedFailure', () async {
      when(() => service.createUser(any())).thenAnswer((_) async => {'user_id': 'x'});
      expect((await invite()).getLeft().toNullable(), isA<UnexpectedFailure>());
    });
  });

  group('update', () {
    test('sends only full_name, role (db value) and is_active for the given id', () async {
      when(() => service.updateProfile(any(), any())).thenAnswer((_) async {});

      final result = await repo.update(
        'u1',
        fullName: 'اسم (seed)',
        role: UserRole.siteUser,
        isActive: false,
      );

      expect(result.isRight(), isTrue);
      verify(
        () => service.updateProfile('u1', {
          'full_name': 'اسم (seed)',
          'role': 'site_user',
          'is_active': false,
        }),
      ).called(1);
    });

    test('maps P0001 last_admin to BusinessRuleFailure', () async {
      when(
        () => service.updateProfile(any(), any()),
      ).thenThrow(const PostgrestException(message: 'last_admin', code: 'P0001'));

      expect(
        await repo.update('u2', fullName: 'x', role: UserRole.siteUser, isActive: true),
        const Left<AppFailure, void>(BusinessRuleFailure('last_admin')),
      );
    });

    test('maps P0001 cannot_change_self to BusinessRuleFailure', () async {
      when(
        () => service.updateProfile(any(), any()),
      ).thenThrow(const PostgrestException(message: 'cannot_change_self', code: 'P0001'));

      expect(
        await repo.update('u2', fullName: 'x', role: UserRole.admin, isActive: false),
        const Left<AppFailure, void>(BusinessRuleFailure('cannot_change_self')),
      );
    });
  });

  group('setSites', () {
    test('calls admin_set_user_sites with p_user and p_site_ids', () async {
      when(() => service.rpc(any(), any())).thenAnswer((_) async => null);

      final result = await repo.setSites('u1', const [siteA, siteB]);

      expect(result.isRight(), isTrue);
      verify(
        () => service.rpc('admin_set_user_sites', {
          'p_user': 'u1',
          'p_site_ids': [siteA, siteB],
        }),
      ).called(1);
    });

    test('maps P0001 invalid_target to BusinessRuleFailure', () async {
      when(
        () => service.rpc(any(), any()),
      ).thenThrow(const PostgrestException(message: 'invalid_target', code: 'P0001'));

      expect(
        await repo.setSites('u2', const []),
        const Left<AppFailure, void>(BusinessRuleFailure('invalid_target')),
      );
    });
  });
}

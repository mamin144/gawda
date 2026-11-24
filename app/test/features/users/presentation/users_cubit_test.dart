import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:gawda_app/core/error/app_failure.dart';
import 'package:gawda_app/features/auth/domain/entities/app_user.dart';
import 'package:gawda_app/features/sites/domain/entities/site.dart';
import 'package:gawda_app/features/sites/domain/repositories/sites_repository.dart';
import 'package:gawda_app/features/users/domain/entities/managed_user.dart';
import 'package:gawda_app/features/users/domain/repositories/users_repository.dart';
import 'package:gawda_app/features/users/presentation/bloc/users_cubit.dart';
import 'package:mocktail/mocktail.dart';

class MockUsersRepository extends Mock implements UsersRepository {}

class MockSitesRepository extends Mock implements SitesRepository {}

void main() {
  late MockUsersRepository usersRepo;
  late MockSitesRepository sitesRepo;

  const alpha = Site(id: 's1', code: 'ALPHA', name: 'برج الشمال', isActive: true);
  final beta = Site(
    id: 's2',
    code: 'BETA',
    name: 'Old Depot',
    isActive: false,
    archivedAt: DateTime.utc(2026, 11, 1),
  );
  const gamma = Site(id: 's3', code: 'GAM-1', name: 'Gamma Tower', isActive: true);
  final sites = [alpha, beta, gamma];
  const activeSites = [alpha, gamma];

  const admin = ManagedUser(
    id: 'u1',
    email: 'admin@example.test',
    fullName: 'مدير النظام',
    role: UserRole.admin,
    isActive: true,
    invitePending: false,
    siteIds: [],
  );
  const siteUser = ManagedUser(
    id: 'u2',
    email: 'site.user@example.test',
    fullName: 'سامي الموقع',
    role: UserRole.siteUser,
    isActive: true,
    invitePending: false,
    siteIds: ['s1'],
  );
  const pending = ManagedUser(
    id: 'u3',
    email: 'pending@example.test',
    fullName: 'دعوة جديدة',
    role: UserRole.siteUser,
    isActive: true,
    invitePending: true,
    siteIds: [],
  );
  const users = [admin, siteUser, pending];

  setUp(() {
    usersRepo = MockUsersRepository();
    sitesRepo = MockSitesRepository();
    when(() => usersRepo.list()).thenAnswer((_) async => const Right(users));
    when(() => sitesRepo.list()).thenAnswer((_) async => Right(sites));
  });

  group('load', () {
    blocTest<UsersCubit, UsersState>(
      'emits Loading then Loaded with users and only active sites',
      build: () => UsersCubit(usersRepo, sitesRepo),
      act: (cubit) => cubit.load(),
      expect: () => [
        const UsersLoading(),
        const UsersLoaded(users: users, activeSites: activeSites),
      ],
    );

    blocTest<UsersCubit, UsersState>(
      'emits Error when the users repository fails',
      setUp: () =>
          when(() => usersRepo.list()).thenAnswer((_) async => const Left(NetworkFailure())),
      build: () => UsersCubit(usersRepo, sitesRepo),
      act: (cubit) => cubit.load(),
      expect: () => [const UsersLoading(), const UsersError(NetworkFailure())],
    );

    blocTest<UsersCubit, UsersState>(
      'emits Error when the sites repository fails',
      setUp: () =>
          when(() => sitesRepo.list()).thenAnswer((_) async => const Left(ServerFailure())),
      build: () => UsersCubit(usersRepo, sitesRepo),
      act: (cubit) => cubit.load(),
      expect: () => [const UsersLoading(), const UsersError(ServerFailure())],
    );
  });

  group('visible users', () {
    test('query matches name or email, case-insensitive and trimmed', () {
      expect(
        const UsersLoaded(users: users, activeSites: activeSites, query: '  ADMIN ').visibleUsers,
        [admin],
      );
      expect(
        const UsersLoaded(users: users, activeSites: activeSites, query: 'سامي').visibleUsers,
        [siteUser],
      );
      expect(
        const UsersLoaded(
          users: users,
          activeSites: activeSites,
          query: 'example.test',
        ).visibleUsers.length,
        3,
      );
    });

    blocTest<UsersCubit, UsersState>(
      'setQuery keeps the list and stores the raw query',
      build: () => UsersCubit(usersRepo, sitesRepo),
      act: (cubit) async {
        await cubit.load();
        cubit.setQuery('سامي');
      },
      skip: 2,
      expect: () => [const UsersLoaded(users: users, activeSites: activeSites, query: 'سامي')],
    );
  });

  group('actions', () {
    blocTest<UsersCubit, UsersState>(
      'invite success forwards the values, reloads and returns true',
      setUp: () => when(
        () => usersRepo.invite(
          email: 'new@example.test',
          fullName: 'New User',
          role: UserRole.siteUser,
          siteIds: const ['s1'],
        ),
      ).thenAnswer((_) async => const Right('u4')),
      build: () => UsersCubit(usersRepo, sitesRepo),
      act: (cubit) async {
        await cubit.load();
        expect(
          await cubit.invite(
            email: 'new@example.test',
            fullName: 'New User',
            role: UserRole.siteUser,
            siteIds: const ['s1'],
          ),
          isTrue,
        );
      },
      verify: (_) {
        verify(
          () => usersRepo.invite(
            email: 'new@example.test',
            fullName: 'New User',
            role: UserRole.siteUser,
            siteIds: const ['s1'],
          ),
        ).called(1);
        verify(() => usersRepo.list()).called(2);
      },
    );

    blocTest<UsersCubit, UsersState>(
      'invite failure returns false and keeps the list with actionError',
      setUp: () => when(
        () => usersRepo.invite(
          email: 'taken@example.test',
          fullName: 'Taken',
          role: UserRole.siteUser,
          siteIds: const [],
        ),
      ).thenAnswer((_) async => const Left(BusinessRuleFailure('user_exists'))),
      build: () => UsersCubit(usersRepo, sitesRepo),
      act: (cubit) async {
        await cubit.load();
        expect(
          await cubit.invite(
            email: 'taken@example.test',
            fullName: 'Taken',
            role: UserRole.siteUser,
            siteIds: const [],
          ),
          isFalse,
        );
      },
      skip: 2,
      expect: () => [
        const UsersLoaded(
          users: users,
          activeSites: activeSites,
          actionError: BusinessRuleFailure('user_exists'),
        ),
      ],
    );

    blocTest<UsersCubit, UsersState>(
      'update success returns true and reloads',
      setUp: () => when(
        () => usersRepo.update(
          'u2',
          fullName: 'سامي الجديد',
          role: UserRole.siteUser,
          isActive: false,
        ),
      ).thenAnswer((_) async => const Right(null)),
      build: () => UsersCubit(usersRepo, sitesRepo),
      act: (cubit) async {
        await cubit.load();
        expect(
          await cubit.update(
            'u2',
            fullName: 'سامي الجديد',
            role: UserRole.siteUser,
            isActive: false,
          ),
          isTrue,
        );
      },
      verify: (_) {
        verify(
          () => usersRepo.update(
            'u2',
            fullName: 'سامي الجديد',
            role: UserRole.siteUser,
            isActive: false,
          ),
        ).called(1);
        verify(() => usersRepo.list()).called(2);
      },
    );

    blocTest<UsersCubit, UsersState>(
      'setSites success returns true and reloads',
      setUp: () =>
          when(() => usersRepo.setSites('u2', const ['s3']))
              .thenAnswer((_) async => const Right(null)),
      build: () => UsersCubit(usersRepo, sitesRepo),
      act: (cubit) async {
        await cubit.load();
        expect(await cubit.setSites('u2', const ['s3']), isTrue);
      },
      verify: (_) {
        verify(() => usersRepo.setSites('u2', const ['s3'])).called(1);
        verify(() => usersRepo.list()).called(2);
      },
    );

    blocTest<UsersCubit, UsersState>(
      'a successful reload clears a previous actionError',
      setUp: () {
        when(
          () => usersRepo.invite(
            email: 'taken@example.test',
            fullName: 'Taken',
            role: UserRole.siteUser,
            siteIds: const [],
          ),
        ).thenAnswer((_) async => const Left(ForbiddenFailure()));
        when(
          () => usersRepo.setSites('u2', const ['s3']),
        ).thenAnswer((_) async => const Right(null));
      },
      build: () => UsersCubit(usersRepo, sitesRepo),
      act: (cubit) async {
        await cubit.load();
        await cubit.invite(
          email: 'taken@example.test',
          fullName: 'Taken',
          role: UserRole.siteUser,
          siteIds: const [],
        );
        await cubit.setSites('u2', const ['s3']);
      },
      verify: (cubit) => expect((cubit.state as UsersLoaded).actionError, isNull),
    );
  });
}

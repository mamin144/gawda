import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:gawda_app/core/error/app_failure.dart';
import 'package:gawda_app/features/sites/domain/entities/site.dart';
import 'package:gawda_app/features/sites/domain/repositories/sites_repository.dart';
import 'package:gawda_app/features/sites/presentation/bloc/sites_cubit.dart';
import 'package:mocktail/mocktail.dart';

class MockSitesRepository extends Mock implements SitesRepository {}

void main() {
  late MockSitesRepository repo;

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

  setUp(() {
    repo = MockSitesRepository();
    when(() => repo.list()).thenAnswer((_) async => Right(sites));
  });

  group('load', () {
    blocTest<SitesCubit, SitesState>(
      'emits Loading then Loaded with the active filter by default',
      build: () => SitesCubit(repo),
      act: (cubit) => cubit.load(),
      expect: () => [const SitesLoading(), SitesLoaded(sites: sites)],
      verify: (cubit) {
        final state = cubit.state as SitesLoaded;
        expect(state.filter, SitesFilter.active);
        expect(state.query, '');
      },
    );

    blocTest<SitesCubit, SitesState>(
      'emits Loading then Error when the repository fails',
      setUp: () => when(() => repo.list()).thenAnswer((_) async => const Left(NetworkFailure())),
      build: () => SitesCubit(repo),
      act: (cubit) => cubit.load(),
      expect: () => [const SitesLoading(), const SitesError(NetworkFailure())],
    );
  });

  group('visible sites', () {
    test('active filter shows only active sites', () {
      expect(SitesLoaded(sites: sites).visibleSites, [alpha, gamma]);
    });

    blocTest<SitesCubit, SitesState>(
      'setFilter(archived) shows only archived sites',
      build: () => SitesCubit(repo),
      act: (cubit) async {
        await cubit.load();
        cubit.setFilter(SitesFilter.archived);
      },
      skip: 2,
      expect: () => [SitesLoaded(sites: sites, filter: SitesFilter.archived)],
      verify: (cubit) => expect((cubit.state as SitesLoaded).visibleSites, [beta]),
    );

    test('all filter shows every site', () {
      expect(SitesLoaded(sites: sites, filter: SitesFilter.all).visibleSites, sites);
    });

    test('query matches code or name, case-insensitive and trimmed', () {
      final byCode = SitesLoaded(sites: sites, filter: SitesFilter.all, query: '  gam ');
      expect(byCode.visibleSites, [gamma]);
      final byName = SitesLoaded(sites: sites, filter: SitesFilter.all, query: 'DEPOT');
      expect(byName.visibleSites, [beta]);
      final arabic = SitesLoaded(sites: sites, query: 'الشمال');
      expect(arabic.visibleSites, [alpha]);
    });

    blocTest<SitesCubit, SitesState>(
      'setQuery keeps the filter and stores the raw query',
      build: () => SitesCubit(repo),
      act: (cubit) async {
        await cubit.load();
        cubit.setQuery('alp');
      },
      skip: 2,
      expect: () => [SitesLoaded(sites: sites, query: 'alp')],
    );
  });

  group('actions', () {
    blocTest<SitesCubit, SitesState>(
      'create success returns true and reloads keeping filter and query',
      setUp: () =>
          when(
            () => repo.create(code: 'NEW', name: 'New Site'),
          ).thenAnswer(
            (_) async => const Right(Site(id: 's4', code: 'NEW', name: 'New Site', isActive: true)),
          ),
      build: () => SitesCubit(repo),
      act: (cubit) async {
        await cubit.load();
        cubit.setFilter(SitesFilter.all);
        expect(await cubit.create('NEW', 'New Site'), isTrue);
      },
      verify: (cubit) {
        verify(() => repo.create(code: 'NEW', name: 'New Site')).called(1);
        verify(() => repo.list()).called(2);
        expect((cubit.state as SitesLoaded).filter, SitesFilter.all);
      },
    );

    blocTest<SitesCubit, SitesState>(
      'create failure returns false and keeps the list with actionError',
      setUp: () => when(
        () => repo.create(code: 'ALPHA', name: 'Dup'),
      ).thenAnswer((_) async => const Left(DuplicateFailure())),
      build: () => SitesCubit(repo),
      act: (cubit) async {
        await cubit.load();
        expect(await cubit.create('ALPHA', 'Dup'), isFalse);
      },
      skip: 2,
      expect: () => [SitesLoaded(sites: sites, actionError: const DuplicateFailure())],
    );

    blocTest<SitesCubit, SitesState>(
      'update failure with code_locked keeps the list with actionError',
      setUp: () => when(
        () => repo.update('s1', code: 'X', name: 'Y'),
      ).thenAnswer((_) async => const Left(BusinessRuleFailure('code_locked'))),
      build: () => SitesCubit(repo),
      act: (cubit) async {
        await cubit.load();
        expect(await cubit.update('s1', 'X', 'Y'), isFalse);
      },
      skip: 2,
      expect: () => [
        SitesLoaded(sites: sites, actionError: const BusinessRuleFailure('code_locked')),
      ],
    );

    blocTest<SitesCubit, SitesState>(
      'setArchived success returns true and reloads',
      setUp: () => when(
        () => repo.setArchived('s1', archived: true),
      ).thenAnswer((_) async => Right(alpha.copyWith(isActive: false))),
      build: () => SitesCubit(repo),
      act: (cubit) async {
        await cubit.load();
        expect(await cubit.setArchived('s1', archived: true), isTrue);
      },
      verify: (_) {
        verify(() => repo.setArchived('s1', archived: true)).called(1);
        verify(() => repo.list()).called(2);
      },
    );

    blocTest<SitesCubit, SitesState>(
      'a successful reload clears a previous actionError',
      setUp: () {
        when(() => repo.create(code: 'A', name: 'B'))
            .thenAnswer((_) async => const Left(ForbiddenFailure()));
        when(
          () => repo.setArchived('s1', archived: true),
        ).thenAnswer((_) async => Right(alpha.copyWith(isActive: false)));
      },
      build: () => SitesCubit(repo),
      act: (cubit) async {
        await cubit.load();
        await cubit.create('A', 'B');
        await cubit.setArchived('s1', archived: true);
      },
      verify: (cubit) => expect((cubit.state as SitesLoaded).actionError, isNull),
    );
  });
}

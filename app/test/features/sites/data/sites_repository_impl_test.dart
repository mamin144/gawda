import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:gawda_app/core/error/app_failure.dart';
import 'package:gawda_app/features/sites/data/repositories/sites_repository_impl.dart';
import 'package:gawda_app/features/sites/data/services/sites_service.dart';
import 'package:gawda_app/features/sites/domain/entities/site.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSitesService extends Mock implements SitesService {}

void main() {
  late MockSitesService service;
  late SitesRepositoryImpl repo;
  final fixedNow = DateTime.utc(2026, 11, 24, 10, 30, 15, 123);

  const activeRow = {
    'id': 's1',
    'code': 'A01',
    'name': 'موقع أ (seed)',
    'is_active': true,
    'archived_at': null,
  };
  const archivedRow = {
    'id': 's2',
    'code': 'B02',
    'name': 'موقع ب (seed)',
    'is_active': false,
    'archived_at': '2026-11-20T08:00:00+00:00',
  };

  setUp(() {
    service = MockSitesService();
    repo = SitesRepositoryImpl(service, now: () => fixedNow);
  });

  group('list', () {
    test('maps rows to sites keeping the service order (ordered by code)', () async {
      when(() => service.fetchSites()).thenAnswer((_) async => [activeRow, archivedRow]);

      final result = await repo.list();

      expect(result.isRight(), isTrue);
      expect(result.getOrElse((_) => []), [
        const Site(id: 's1', code: 'A01', name: 'موقع أ (seed)', isActive: true, archivedAt: null),
        Site(
          id: 's2',
          code: 'B02',
          name: 'موقع ب (seed)',
          isActive: false,
          archivedAt: DateTime.utc(2026, 11, 20, 8),
        ),
      ]);
    });

    test('maps a thrown network error to NetworkFailure', () async {
      when(() => service.fetchSites()).thenThrow(const SocketException('offline'));

      expect(await repo.list(), const Left<AppFailure, List<Site>>(NetworkFailure()));
    });
  });

  group('create', () {
    test('inserts code and name and returns the created site', () async {
      when(() => service.insertSite(any())).thenAnswer((_) async => activeRow);

      final result = await repo.create(code: 'a01', name: 'موقع أ (seed)');

      expect(
        result,
        const Right<AppFailure, Site>(
          Site(id: 's1', code: 'A01', name: 'موقع أ (seed)', isActive: true, archivedAt: null),
        ),
      );
      verify(() => service.insertSite({'code': 'a01', 'name': 'موقع أ (seed)'})).called(1);
    });

    test('maps a 23505 unique violation to Left(DuplicateFailure())', () async {
      when(() => service.insertSite(any())).thenThrow(
        const PostgrestException(message: 'duplicate key value', code: '23505'),
      );

      expect(
        await repo.create(code: 'A01', name: 'x'),
        const Left<AppFailure, Site>(DuplicateFailure()),
      );
    });
  });

  group('update', () {
    test('updates code and name of the given id', () async {
      when(() => service.updateSite(any(), any())).thenAnswer((_) async => activeRow);

      final result = await repo.update('s1', code: 'A01', name: 'موقع أ (seed)');

      expect(result.isRight(), isTrue);
      verify(() => service.updateSite('s1', {'code': 'A01', 'name': 'موقع أ (seed)'})).called(1);
    });

    test('maps P0001 code_locked to BusinessRuleFailure', () async {
      when(() => service.updateSite(any(), any())).thenThrow(
        const PostgrestException(message: 'code_locked', code: 'P0001'),
      );

      expect(
        await repo.update('s1', code: 'Z99', name: 'x'),
        const Left<AppFailure, Site>(BusinessRuleFailure('code_locked')),
      );
    });
  });

  group('setArchived', () {
    test('archived:true sends is_active false and archived_at now (UTC ISO)', () async {
      when(() => service.updateSite(any(), any())).thenAnswer((_) async => archivedRow);

      final result = await repo.setArchived('s2', archived: true);

      expect(result.isRight(), isTrue);
      verify(
        () => service.updateSite('s2', {
          'is_active': false,
          'archived_at': fixedNow.toUtc().toIso8601String(),
        }),
      ).called(1);
    });

    test('archived:false sends is_active true and archived_at null together', () async {
      when(() => service.updateSite(any(), any())).thenAnswer((_) async => activeRow);

      await repo.setArchived('s1', archived: false);

      verify(() => service.updateSite('s1', {'is_active': true, 'archived_at': null})).called(1);
    });

    test('maps P0001 forbidden to ForbiddenFailure', () async {
      when(() => service.updateSite(any(), any())).thenThrow(
        const PostgrestException(message: 'forbidden', code: 'P0001'),
      );

      expect(
        await repo.setArchived('s1', archived: true),
        const Left<AppFailure, Site>(ForbiddenFailure()),
      );
    });
  });
}

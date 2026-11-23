import 'package:flutter_test/flutter_test.dart';
import 'package:gawda_app/features/auth/data/models/profile_row.dart';
import 'package:gawda_app/features/auth/domain/entities/app_user.dart';

void main() {
  const seedRow = {
    'id': '5eed0000-0000-0000-0000-000000000001',
    'full_name': 'مستخدم تجريبي (seed)',
    'role': 'site_user',
    'is_active': true,
  };

  test('parses the exact profiles columns and maps site_user', () {
    final user = ProfileRow.fromJson(seedRow).toDomain();
    expect(user.id, '5eed0000-0000-0000-0000-000000000001');
    expect(user.fullName, 'مستخدم تجريبي (seed)');
    expect(user.role, UserRole.siteUser);
    expect(user.isActive, isTrue);
  });

  test('maps admin role', () {
    final row = Map<String, dynamic>.from(seedRow)..['role'] = 'admin';
    expect(ProfileRow.fromJson(row).toDomain().role, UserRole.admin);
  });

  test('unknown role fails fast with FormatException', () {
    final row = Map<String, dynamic>.from(seedRow)..['role'] = 'superadmin';
    expect(() => ProfileRow.fromJson(row).toDomain(), throwsFormatException);
  });

  test('missing is_active key fails fast', () {
    final row = Map<String, dynamic>.from(seedRow)..remove('is_active');
    expect(() => ProfileRow.fromJson(row), throwsA(isA<TypeError>()));
  });

  test('toJson round-trips the database column names', () {
    final json = ProfileRow.fromJson(seedRow).toJson();
    expect(json['full_name'], 'مستخدم تجريبي (seed)');
    expect(json['is_active'], isTrue);
    expect(json.containsKey('fullName'), isFalse);
  });
}

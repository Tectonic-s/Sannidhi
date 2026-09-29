import 'package:flutter_test/flutter_test.dart';
import 'package:sannidhi/core/models/user_model.dart';
import 'package:sannidhi/providers/auth_provider.dart';

void main() {
  group('UserModel and UserRole Tests', () {
    test('UserRole parser handles roles correctly', () {
      expect(UserRole.fromString('admin'), UserRole.admin);
      expect(UserRole.fromString('staff'), UserRole.staff);
      expect(UserRole.fromString('devotee'), UserRole.devotee);
      expect(UserRole.fromString('unknown'), UserRole.devotee);
      expect(UserRole.fromString(null), UserRole.devotee);
    });

    test('UserModel JSON serialization', () {
      final user = UserModel(
        id: 'usr-123',
        name: 'Arun Kumar',
        email: 'arun@example.com',
        phone: '9876543210',
        role: UserRole.staff,
        token: 'mock-jwt-token',
      );

      final json = user.toJson();
      expect(json['id'], 'usr-123');
      expect(json['role'], 'staff');
      expect(json['token'], 'mock-jwt-token');

      final deserialized = UserModel.fromJson(json);
      expect(deserialized.id, 'usr-123');
      expect(deserialized.isStaff, isTrue);
      expect(deserialized.isAdmin, isFalse);
      expect(deserialized.isDevotee, isFalse);
    });

    test('AuthProvider initializes in unauthenticated state', () {
      final auth = AuthProvider();
      expect(auth.isAuthenticated, isFalse);
      expect(auth.currentUser, isNull);
      expect(auth.token, isEmpty);
    });
  });
}

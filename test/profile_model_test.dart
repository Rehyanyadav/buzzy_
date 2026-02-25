import 'package:flutter_test/flutter_test.dart';
import 'package:buzzy/features/auth/data/profile_repository.dart';

void main() {
  group('ProfileModel Tests', () {
    test('fromJson should parse correctly', () {
      final json = {
        'id': 'user123',
        'display_name': 'Test User',
        'email': 'test@example.com',
        'partner_id': 'partner456',
        'mood_emoji': '😊',
        'last_seen': '2023-10-01T12:00:00Z',
      };

      final profile = ProfileModel.fromJson(json);

      expect(profile.id, 'user123');
      expect(profile.displayName, 'Test User');
      expect(profile.email, 'test@example.com');
      expect(profile.partnerId, 'partner456');
      expect(profile.moodEmoji, '😊');
      expect(profile.lastSeen, isNotNull);
    });

    test('default mood_emoji should be 🤍', () {
      final json = {'id': 'user123'};

      final profile = ProfileModel.fromJson(json);

      expect(profile.id, 'user123');
      expect(profile.moodEmoji, '🤍');
    });
  });
}

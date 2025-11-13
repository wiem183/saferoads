import 'package:flutter_test/flutter_test.dart';
import 'package:covoiturage_app/models/amende.dart';

void main() {
  group('Amende Model Tests', () {
    test('Amende.fromJson creates correct instance', () {
      final json = {
        'id': 'test-id-1',
        'userId': 'user-123',
        'agentId': 'agent-456',
        'photoUrl': 'https://example.com/photo.jpg',
        'location': 'Avenue Habib Bourguiba, Tunis',
        'type': 'speeding',
        'amount': 150.0,
      };

      final amende = Amende.fromJson(json);

      expect(amende.id, 'test-id-1');
      expect(amende.userId, 'user-123');
      expect(amende.agentId, 'agent-456');
      expect(amende.location, 'Avenue Habib Bourguiba, Tunis');
      expect(amende.type, AmendeType.speeding);
      expect(amende.amount, 150.0);
    });

    test('Amende.toJson converts correctly', () {
      final amende = Amende(
        id: 'test-id-1',
        userId: 'user-123',
        agentId: 'agent-456',
        photoUrl: 'https://example.com/photo.jpg',
        location: 'Avenue Habib Bourguiba, Tunis',
        type: AmendeType.speeding,
        amount: 150.0,
      );

      final json = amende.toJson();

      expect(json['id'], 'test-id-1');
      expect(json['userId'], 'user-123');
      expect(json['type'], 'speeding');
      expect(json['amount'], 150.0);
    });

    test('Amende.isValid returns true for valid data', () {
      final amende = Amende(
        id: 'test-id-1',
        userId: 'user-123',
        agentId: 'agent-456',
        location: 'Test Location',
        type: AmendeType.parking,
        amount: 100.0,
      );

      expect(amende.isValid(), true);
    });

    test('Amende.isValid returns false for invalid data', () {
      final amende = Amende(
        id: '',
        userId: 'user-123',
        agentId: 'agent-456',
        location: 'Test Location',
        type: AmendeType.parking,
        amount: 100.0,
      );

      expect(amende.isValid(), false);
    });

    test('getTypeLabel returns French labels', () {
      expect(
        Amende(
          id: '1',
          userId: 'u1',
          agentId: 'a1',
          location: 'loc',
          type: AmendeType.speeding,
          amount: 100,
        ).getTypeLabel(),
        'Excès de vitesse',
      );

      expect(
        Amende(
          id: '1',
          userId: 'u1',
          agentId: 'a1',
          location: 'loc',
          type: AmendeType.parking,
          amount: 100,
        ).getTypeLabel(),
        'Stationnement interdit',
      );
    });
  });
}

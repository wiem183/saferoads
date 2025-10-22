import 'package:flutter_test/flutter_test.dart';
import 'package:covoiturage_app/models/announcement.dart';

void main() {
  test('Announcement validation', () {
    final ann = Announcement(
      id: '1',
      origin: 'Tunis',
      destination: 'Sousse',
      departureDateTime: DateTime.now(),
      availableSeats: 2,
      price: 10.0,
      carModel: 'Car',
      driverName: 'Driver',
      driverPhone: '12345678',
    );
    expect(ann.isValid(), true);

    final invalidAnn = Announcement(
      id: '2',
      origin: '',
      destination: 'Sousse',
      departureDateTime: DateTime.now(),
      availableSeats: 0,
      price: -1,
      carModel: 'Car',
      driverName: 'Driver',
      driverPhone: '123',
    );
    expect(invalidAnn.isValid(), false);
  });
}
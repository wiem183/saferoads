import 'package:covoiturage_app/models/announcement.dart';

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
  driverEmail: 'driver@example.com', // ← ajouté
);

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
  driverEmail: '', // ← ajouté
);

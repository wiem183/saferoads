import 'package:covoiturage_app/models/parking.dart';

class ParkingService {
  final List<Parking> _parkings = [];

  List<Parking> getAll() => _parkings;

  void addParking(Parking parking) => _parkings.add(parking);

  void updateParking(String id, Parking updated) {
    final index = _parkings.indexWhere((p) => p.id == id);
    if (index != -1) _parkings[index] = updated;
  }

  void deleteParking(String id) =>
      _parkings.removeWhere((p) => p.id == id);
}

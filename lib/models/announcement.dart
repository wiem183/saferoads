import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'reservation.dart';

class Announcement {
  String id;
  String origin;
  String destination;
  LatLng? originLatLng; 
  LatLng? destinationLatLng; 
  DateTime departureDateTime;
  int availableSeats;
  double price;
  String carModel;
  String driverName;
  String driverPhone;
  List<Reservation> reservations;

  Announcement({
    required this.id,
    required this.origin,
    required this.destination,
    this.originLatLng, 
    this.destinationLatLng, 
    required this.departureDateTime,
    required this.availableSeats,
    required this.price,
    required this.carModel,
    required this.driverName,
    required this.driverPhone,
    this.reservations = const [],
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'],
      origin: json['origin'],
      destination: json['destination'],
      originLatLng: json['originLatLng'] != null
          ? LatLng(json['originLatLng']['lat'], json['originLatLng']['lng'])
          : null,
      destinationLatLng: json['destinationLatLng'] != null
          ? LatLng(json['destinationLatLng']['lat'], json['destinationLatLng']['lng'])
          : null,
      departureDateTime: DateTime.parse(json['departureDateTime']),
      availableSeats: json['availableSeats'],
      price: json['price'],
      carModel: json['carModel'],
      driverName: json['driverName'],
      driverPhone: json['driverPhone'],
      reservations: (json['reservations'] as List)
          .map((r) => Reservation.fromJson(r))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'origin': origin,
      'destination': destination,
      'originLatLng': originLatLng != null
          ? {'lat': originLatLng!.latitude, 'lng': originLatLng!.longitude}
          : null,
      'destinationLatLng': destinationLatLng != null
          ? {'lat': destinationLatLng!.latitude, 'lng': destinationLatLng!.longitude}
          : null,
      'departureDateTime': departureDateTime.toIso8601String(),
      'availableSeats': availableSeats,
      'price': price,
      'carModel': carModel,
      'driverName': driverName,
      'driverPhone': driverPhone,
      'reservations': reservations.map((r) => r.toJson()).toList(),
    };
  }

  bool isValid() {
    return origin.isNotEmpty &&
        destination.isNotEmpty &&
        availableSeats > 0 &&
        price > 0 &&
        driverPhone.length == 8 &&
        int.tryParse(driverPhone) != null;
  }
}
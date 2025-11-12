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
  String driverEmail;
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
    required this.driverEmail,
    this.reservations = const [],
  });

  // --- Conversion JSON → Objet AVEC GESTION DES NULLS ---
  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'] ?? '', // Gestion du null
      origin: json['origin'] ?? 'Non spécifiée', // Gestion du null
      destination: json['destination'] ?? 'Non spécifiée', // Gestion du null
      originLatLng: json['originLatLng'] != null
          ? LatLng(
              (json['originLatLng']['lat'] ?? 0.0).toDouble(),
              (json['originLatLng']['lng'] ?? 0.0).toDouble(),
            )
          : null,
      destinationLatLng: json['destinationLatLng'] != null
          ? LatLng(
              (json['destinationLatLng']['lat'] ?? 0.0).toDouble(),
              (json['destinationLatLng']['lng'] ?? 0.0).toDouble(),
            )
          : null,
      departureDateTime: DateTime.parse(
        json['departureDateTime'] ?? DateTime.now().toIso8601String(),
      ),
      availableSeats: (json['availableSeats'] ?? 1).toInt(),
      price: (json['price'] ?? 0.0).toDouble(),
      carModel: json['carModel'] ?? 'Modèle non spécifié', // Gestion du null
      driverName: json['driverName'] ?? 'Nom non spécifié', // Gestion du null
      driverPhone: json['driverPhone'] ?? '', // Gestion du null
      driverEmail: json['driverEmail'] ?? '', // Gestion du null
      reservations: (json['reservations'] as List? ?? [])
          .map((r) => Reservation.fromJson(r))
          .toList(),
    );
  }

  // --- Conversion Objet → JSON ---
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'origin': origin,
      'destination': destination,
      'originLatLng': originLatLng != null
          ? {'lat': originLatLng!.latitude, 'lng': originLatLng!.longitude}
          : null,
      'destinationLatLng': destinationLatLng != null
          ? {
              'lat': destinationLatLng!.latitude,
              'lng': destinationLatLng!.longitude,
            }
          : null,
      'departureDateTime': departureDateTime.toIso8601String(),
      'availableSeats': availableSeats,
      'price': price,
      'carModel': carModel,
      'driverName': driverName,
      'driverPhone': driverPhone,
      'driverEmail': driverEmail,
      'reservations': reservations.map((r) => r.toJson()).toList(),
    };
  }

  // --- Validation simple de l'annonce ---
  bool isValid() {
    return origin.isNotEmpty &&
        destination.isNotEmpty &&
        availableSeats > 0 &&
        price > 0 &&
        driverPhone.length == 8 &&
        int.tryParse(driverPhone) != null &&
        driverEmail.isNotEmpty &&
        driverEmail.contains('@');
  }
}

// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/parking.dart';
import 'parking_form_screen.dart';
import 'reservation_screen.dart';

class ParkingDetailsScreen extends StatelessWidget {
  final String parkingId;

  const ParkingDetailsScreen({super.key, required this.parkingId});

  @override
  Widget build(BuildContext context) {
    final docRef = FirebaseFirestore.instance.collection('parkings').doc(parkingId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails du parking'),
        backgroundColor: Colors.green,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: docRef.get(),
        builder: (context, snapshot) {
          // 🔹 État : chargement
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 🔹 État : pas de données
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('⚠️ Parking introuvable.'));
          }

          // 🔹 Debug : affichage des données brutes Firestore
          print("📦 Données Firestore: ${snapshot.data!.data()}");

          // 🔹 Transformation en modèle Parking
          final parking = Parking.fromJson(
            snapshot.data!.data() as Map<String, dynamic>,
            snapshot.data!.id,
          );

          // 🔹 Construction de l'UI
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    parking.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Chip(
                        label: Text(
                          parking.status.toUpperCase(),
                          style: const TextStyle(color: Colors.white),
                        ),
                        backgroundColor: parking.status == 'open'
                            ? Colors.green
                            : parking.status == 'full'
                                ? Colors.orange
                                : Colors.grey,
                      ),
                      const SizedBox(width: 10),
                      if (parking.isEcoFriendly)
                        const Chip(
                          label: Text("Eco-Friendly"),
                          backgroundColor: Colors.greenAccent,
                        ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  _buildDetail("🅿️ Capacité totale", "${parking.capacity}"),
                  _buildDetail("🚗 Places disponibles", "${parking.availableSpots}"),
                  _buildDetail("💰 Prix / heure", "${parking.pricePerHour} dt"),
                  _buildDetail("📍 Latitude", "${parking.latitude}"),
                  _buildDetail("📍 Longitude", "${parking.longitude}"),

                  const SizedBox(height: 30),

                  // 🔹 Boutons d’action
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ParkingFormScreen(existingParking: parking),
                            ),
                          );
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('Modifier'),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        onPressed: () async {
                          await docRef.delete();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Parking supprimé')),
                          );
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.delete),
                        label: const Text('Supprimer'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 25),

                  // 🔹 Bouton Réserver une place
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ReservationScreen(
                            announcementId: 'default', // champ requis, non utilisé ici
                            parkingId: parking.id,
                            parkingName: parking.name,
                            pricePerHour: parking.pricePerHour,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.calendar_today),
                    label: const Text(
                      'Réserver une place',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // 🔹 Widget utilitaire pour afficher chaque info
  Widget _buildDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 16, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}

import 'package:covoiturage_app/screens/reservation_screen.dart' show ReservationScreen;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/parking.dart';
import 'parking_form_screen.dart';
import 'parking_details_screen.dart';

class ParkingListScreen extends StatelessWidget {
  const ParkingListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final CollectionReference parkings =
        FirebaseFirestore.instance.collection('parkings');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Liste des parkings'),
        backgroundColor: Colors.green,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: parkings.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('❌ Erreur de chargement.'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text('Aucun parking disponible.'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final parking = Parking.fromJson(
                doc.data() as Map<String, dynamic>,
                doc.id,
              );

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  title: Text(parking.name),
                  subtitle: Text(
                    "${parking.status} • ${parking.availableSpots}/${parking.capacity} places",
                  ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.calendar_today, color: Colors.green),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReservationScreen(
                          announcementId: 'default', // si requis
                          parkingId: parking.id,
                          parkingName: parking.name,
                          pricePerHour: parking.pricePerHour,
                        ),
                      ),
                    );
                  },
                ),
                const Icon(Icons.arrow_forward_ios, size: 18),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ParkingDetailsScreen(parkingId: parking.id),
                ),
              );
            },
          ),
        );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ParkingFormScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

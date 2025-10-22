import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/reservation_controller.dart';
import '../styles/styles.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Historique des réservations',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).brightness == Brightness.dark
                ? Styles.darkDefaultLightWhiteColor
                : Styles.defaultRedColor,
          ),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: Consumer<ReservationController>(
        builder: (context, controller, child) {
          if (controller.reservations.isEmpty) {
            return Center(
              child: Text(
                'Aucun trajet pour le moment.',
                style: TextStyle(
                  fontSize: 18,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Styles.darkDefaultGreyColor
                      : Styles.defaultGreyColor,
                ),
              ),
            );
          }
          return ListView.builder(
            padding: EdgeInsets.all(Styles.defaultPadding),
            itemCount: controller.reservations.length,
            itemBuilder: (_, i) {
              final r = controller.reservations[i];
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: Styles.defaultBorderRadius),
                child: ListTile(
                  leading: Icon(
                    Icons.history,
                    color: Styles.defaultBlueColor,
                  ),
                  title: Text(
                    '${r.reserverName} (${r.reserverPhone})',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Styles.darkDefaultLightWhiteColor
                          : Styles.defaultRedColor,
                    ),
                  ),
                  subtitle: Text(
                    'Sièges: ${r.seatsReserved} • ${r.paymentMethod == 'cash' ? 'Espèces' : 'Carte crédit'}',
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Styles.darkDefaultGreyColor
                          : Styles.defaultGreyColor,
                    ),
                  ),
                  trailing: Text(
                    '${r.seatsReserved} siège(s)',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
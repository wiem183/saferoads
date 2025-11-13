// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../controllers/announcement_controller.dart';
import '../models/announcement.dart';
import '../services/storage_service.dart';
import 'driver_edit_screen.dart';

class MyRidesScreen extends StatelessWidget {
  const MyRidesScreen({super.key});

  String get _myPhone => StorageService.getString('myPhone');

  @override
  Widget build(BuildContext context) {
    final controller = context.read<AnnouncementController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes trajets publiés'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      body: StreamBuilder<List<Announcement>>(
        stream: controller.myRidesStream(_myPhone),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Erreur : ${snapshot.error}'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final rides = snapshot.data!;
          if (rides.isEmpty) return const Center(child: Text('Aucun trajet publié.'));

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: rides.length,
            itemBuilder: (_, i) {
              final ann = rides[i];
              return Dismissible(
                key: Key(ann.id),
                background: _leftBg(),
                secondaryBackground: _rightBg(),
                confirmDismiss: (dir) async {
                  if (dir == DismissDirection.startToEnd) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => DriverEditScreen(announcement: ann)),
                    );
                    return false;
                  } else if (dir == DismissDirection.endToStart) {
                    final bool? ok = await _showDeleteDialog(context);
                    if (ok == true) controller.deleteAnnouncement(ann.id);
                    return false;
                  }
                  return false;
                },
                child: _rideCard(ann),
              );
            },
          );
        },
      ),
    );
  }

  Widget _rideCard(Announcement ann) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(.15), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(DateFormat('HH:mm').format(ann.departureDateTime),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text('${ann.price.toStringAsFixed(0)} TND',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red)),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.location_on, size: 18, color: Colors.red),
            const SizedBox(width: 4),
            Expanded(child: Text(ann.origin, style: const TextStyle(fontSize: 15))),
          ]),
          const SizedBox(height: 4),
          Row(children: [
            const Icon(Icons.location_on_outlined, size: 18, color: Colors.grey),
            const SizedBox(width: 4),
            Expanded(child: Text(ann.destination, style: const TextStyle(fontSize: 15))),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            const CircleAvatar(radius: 18, backgroundColor: Colors.grey, child: Icon(Icons.person, color: Colors.white)),
            const SizedBox(width: 10),
            Expanded(child: Text(ann.driverName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500))),
          ]),
        ],
      ),
    );
  }

  Widget _leftBg() => Container(
    alignment: Alignment.centerLeft,
    padding: const EdgeInsets.only(left: 20),
    decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(12)),
    child: const Row(children: [
      Icon(Icons.edit, color: Colors.white),
      SizedBox(width: 8),
      Text('Modifier', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    ]),
  );

  Widget _rightBg() => Container(
    alignment: Alignment.centerRight,
    padding: const EdgeInsets.only(right: 20),
    decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(12)),
    child: const Row(mainAxisAlignment: MainAxisAlignment.end, children: [
      Icon(Icons.delete, color: Colors.white),
      SizedBox(width: 8),
      Text('Supprimer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    ]),
  );

  Future<bool?> _showDeleteDialog(BuildContext context) => showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Supprimer le trajet'),
      content: const Text('Voulez-vous vraiment supprimer ce trajet ?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
        ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer')),
      ],
    ),
  );
}

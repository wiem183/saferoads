// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/parking.dart';

class ParkingFormScreen extends StatefulWidget {
  final Parking? existingParking;
  const ParkingFormScreen({super.key, this.existingParking});

  @override
  State<ParkingFormScreen> createState() => _ParkingFormScreenState();
}

class _ParkingFormScreenState extends State<ParkingFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firestore = FirebaseFirestore.instance.collection('parkings');

  late String _name;
  late double _latitude;
  late double _longitude;
  late int _capacity;
  late int _availableSpots;
  late String _status;
  late double _pricePerHour;
  bool _isEcoFriendly = false;

  @override
  void initState() {
    super.initState();
    final p = widget.existingParking;
    _name = p?.name ?? '';
    _latitude = p?.latitude ?? 0.0;
    _longitude = p?.longitude ?? 0.0;
    _capacity = p?.capacity ?? 0;
    _availableSpots = p?.availableSpots ?? 0;
    _status = p?.status ?? 'open';
    _pricePerHour = p?.pricePerHour ?? 0.0;
    _isEcoFriendly = p?.isEcoFriendly ?? false;
  }

  Future<void> _saveForm() async {
  if (!_formKey.currentState!.validate()) return;
  _formKey.currentState!.save();

  // 🧠 Si l'utilisateur n'a pas précisé le nombre de places disponibles,
  // on l'initialise automatiquement à la capacité totale.
  if (_availableSpots <= 0) {
    _availableSpots = _capacity;
  }

  final data = {
    'name': _name,
    'latitude': _latitude,
    'longitude': _longitude,
    'capacity': _capacity,
    'available_spots': _availableSpots,
    'status': _status,
    'price_per_hour': _pricePerHour,
    'isEcoFriendly': _isEcoFriendly,
  };

  try {
    /*if (widget.existingParking == null) {
      await _firestore.add(data);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Parking ajouté avec succès !'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      await _firestore.doc(widget.existingParking!.id).update(data);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Parking mis à jour avec succès !'),
          backgroundColor: Colors.green,
        ),
      );
    }*/
    if (widget.existingParking == null) {
  final ref = await _firestore.add(data);
  print('✅ Parking ajouté → id=${ref.id} / path=${ref.path}');
  final snap = await ref.get();
  print('📄 Relecture immédiate → exists=${snap.exists} data=${snap.data()}');
} else {
  await _firestore.doc(widget.existingParking!.id).update(data);
  print('✅ Parking mis à jour → id=${widget.existingParking!.id}');
  final snap = await _firestore.doc(widget.existingParking!.id).get();
  print('📄 Relecture immédiate → exists=${snap.exists} data=${snap.data()}');
}


    Navigator.pop(context);
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❌ Erreur : $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingParking == null
            ? 'Ajouter un parking'
            : 'Modifier le parking'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                initialValue: _name,
                decoration: const InputDecoration(labelText: 'Nom'),
                validator: (v) => v == null || v.isEmpty ? 'Nom requis' : null,
                onSaved: (v) => _name = v!,
              ),
              TextFormField(
                initialValue: _latitude.toString(),
                decoration: const InputDecoration(labelText: 'Latitude'),
                keyboardType: TextInputType.number,
                validator: (v) => double.tryParse(v ?? '') == null
                    ? 'Latitude invalide'
                    : null,
                onSaved: (v) => _latitude = double.parse(v!),
              ),
              TextFormField(
                initialValue: _longitude.toString(),
                decoration: const InputDecoration(labelText: 'Longitude'),
                keyboardType: TextInputType.number,
                validator: (v) => double.tryParse(v ?? '') == null
                    ? 'Longitude invalide'
                    : null,
                onSaved: (v) => _longitude = double.parse(v!),
              ),
              TextFormField(
                initialValue: _capacity.toString(),
                decoration: const InputDecoration(labelText: 'Capacité totale'),
                keyboardType: TextInputType.number,
                validator: (v) =>
                    int.tryParse(v ?? '') == null ? 'Nombre invalide' : null,
                onSaved: (v) => _capacity = int.parse(v!),
              ),
              TextFormField(
                initialValue: _availableSpots.toString(),
                decoration:
                    const InputDecoration(labelText: 'Places disponibles'),
                keyboardType: TextInputType.number,
                validator: (v) =>
                    int.tryParse(v ?? '') == null ? 'Nombre invalide' : null,
                onSaved: (v) => _availableSpots = int.parse(v!),
              ),
              TextFormField(
                initialValue: _pricePerHour.toString(),
                decoration: const InputDecoration(labelText: 'Prix / heure (€)'),
                keyboardType: TextInputType.number,
                validator: (v) =>
                    double.tryParse(v ?? '') == null ? 'Prix invalide' : null,
                onSaved: (v) => _pricePerHour = double.parse(v!),
              ),
              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: const InputDecoration(labelText: 'Statut'),
                items: const [
                  DropdownMenuItem(value: 'open', child: Text('Ouvert')),
                  DropdownMenuItem(value: 'full', child: Text('Complet')),
                  DropdownMenuItem(value: 'closed', child: Text('Fermé')),
                ],
                onChanged: (v) => _status = v!,
              ),
              SwitchListTile(
                title: const Text('Eco-Friendly (EcoRoads)'),
                value: _isEcoFriendly,
                onChanged: (v) => setState(() => _isEcoFriendly = v),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: _saveForm,
                child: const Text('Enregistrer'),
              )
            ],
          ),
        ),
      ),
    );
  }
}

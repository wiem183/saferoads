import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/announcement.dart';
import '../controllers/announcement_controller.dart';
import '../styles/styles.dart';
import 'map_screen.dart';

class DriverEditScreen extends StatefulWidget {
  final Announcement announcement;
  const DriverEditScreen({required this.announcement, super.key});

  @override
  State<DriverEditScreen> createState() => _DriverEditScreenState();
}

class _DriverEditScreenState extends State<DriverEditScreen> {
  final _formKey = GlobalKey<FormState>();

  late String origin;
  late String destination;
  late DateTime departure;
  late int seats;
  late double price;
  late String carModel;
  late String driverName;
  late String driverPhone;
  late String driverEmail; // <-- nouveau champ ajouté
  LatLng? originLat;
  LatLng? destLat;

  late GoogleMapController _mapCtrl;
  final Set<Polyline> _polylines = {};
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    final a = widget.announcement;
    origin = a.origin;
    destination = a.destination;
    departure = a.departureDateTime;
    seats = a.availableSeats;
    price = a.price;
    carModel = a.carModel;
    driverName = a.driverName;
    driverPhone = a.driverPhone;
    driverEmail = a.driverEmail; // <-- initialisé depuis l'annonce
    originLat = a.originLatLng;
    destLat = a.destinationLatLng;
    _drawRoute();
  }

  void _drawRoute() {
    if (originLat == null || destLat == null) return;
    _markers
      ..clear()
      ..addAll([
        Marker(
          markerId: const MarkerId('o'),
          position: originLat!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
        Marker(
          markerId: const MarkerId('d'),
          position: destLat!,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
        ),
      ]);
    _polylines.add(
      Polyline(
        polylineId: const PolylineId('route'),
        points: [originLat!, destLat!],
        color: Styles.defaultBlueColor,
        width: 4,
      ),
    );
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: departure,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(departure),
    );
    if (time != null) {
      setState(
        () => departure = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        ),
      );
    }
  }

  Future<void> _selectOnMap(bool isOrigin) async {
    final res = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            MapScreen(selectionMode: isOrigin ? 'origin' : 'destination'),
      ),
    );
    if (res == null) return;
    setState(() {
      if (isOrigin) {
        origin = res['place'];
        originLat = res['latLng'];
      } else {
        destination = res['place'];
        destLat = res['latLng'];
      }
      _drawRoute();
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final updated = Announcement(
      id: widget.announcement.id,
      origin: origin,
      destination: destination,
      originLatLng: originLat,
      destinationLatLng: destLat,
      departureDateTime: departure,
      availableSeats: seats,
      price: price,
      carModel: carModel,
      driverName: driverName,
      driverPhone: driverPhone,
      driverEmail: driverEmail, // <-- champ ajouté ici
      reservations: widget.announcement.reservations,
    );
    await context.read<AnnouncementController>().addAnnouncement(updated);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Supprimer le trajet'),
        content: const Text('Voulez-vous vraiment supprimer ce trajet ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(d, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await context.read<AnnouncementController>().deleteAnnouncement(
      widget.announcement.id,
    );
    if (mounted) Navigator.pop(context);
  }

  Widget _glassCard(Widget child) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: (dark ? Colors.grey[850] : Colors.white)?.withOpacity(0.85),
        boxShadow: [
          BoxShadow(
            color: (dark ? Colors.black : Colors.grey.shade400).withOpacity(
              0.2,
            ),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Modifier le trajet'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: dark ? Colors.white : Colors.black,
        centerTitle: true,
      ),
      floatingActionButton: _floatingButtons(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: dark
                ? [const Color(0xFF0F2027), const Color(0xFF203A43)]
                : [Colors.blue.shade50, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 100, 16, 100),
            children: [
              if (originLat != null && destLat != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: SizedBox(
                    height: 200,
                    child: GoogleMap(
                      onMapCreated: (c) => _mapCtrl = c,
                      initialCameraPosition: CameraPosition(
                        target: originLat!,
                        zoom: 10,
                      ),
                      markers: _markers,
                      polylines: _polylines,
                      zoomControlsEnabled: false,
                      myLocationButtonEnabled: false,
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              _glassCard(
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _locationField(
                        label: 'Origine',
                        value: origin,
                        onChanged: (v) => setState(() => origin = v),
                        onMapSelect: () => _selectOnMap(true),
                        icon: Icons.location_on,
                      ),
                      const Divider(),
                      _locationField(
                        label: 'Destination',
                        value: destination,
                        onChanged: (v) => setState(() => destination = v),
                        onMapSelect: () => _selectOnMap(false),
                        icon: Icons.flag,
                      ),
                      const Divider(),
                      _dateTile(),
                      const Divider(),
                      _inputField(
                        'Sièges disponibles',
                        seats.toString(),
                        (v) => seats = int.tryParse(v) ?? 1,
                        TextInputType.number,
                      ),
                      _inputField(
                        'Prix (TND)',
                        price.toStringAsFixed(0),
                        (v) => price = double.tryParse(v) ?? 0,
                        const TextInputType.numberWithOptions(decimal: true),
                      ),
                      _inputField(
                        'Modèle voiture',
                        carModel,
                        (v) => carModel = v,
                        TextInputType.text,
                      ),
                      _inputField(
                        'Nom chauffeur',
                        driverName,
                        (v) => driverName = v,
                        TextInputType.text,
                      ),
                      _inputField(
                        'Téléphone (8 chiffres)',
                        driverPhone,
                        (v) => driverPhone = v,
                        TextInputType.phone,
                        validator: (v) =>
                            (v?.length == 8) ? null : '8 chiffres requis',
                      ),
                      _inputField(
                        'Email chauffeur', // <-- nouveau champ ajouté
                        driverEmail,
                        (v) => driverEmail = v,
                        TextInputType.emailAddress,
                        validator: (v) => (v != null && v.contains('@'))
                            ? null
                            : 'Email valide requis',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _locationField({
    required String label,
    required String value,
    required Function(String) onChanged,
    required VoidCallback onMapSelect,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Styles.defaultBlueColor),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                initialValue: value,
                decoration: InputDecoration(
                  labelText: label,
                  hintText: "Entrez l'adresse",
                ),
                onChanged: onChanged,
                validator: (v) => v!.isEmpty ? 'Requis' : null,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.map_outlined),
              onPressed: onMapSelect,
            ),
          ],
        ),
      ],
    );
  }

  Widget _dateTile() {
    return ListTile(
      leading: Icon(Icons.calendar_today, color: Styles.defaultBlueColor),
      title: Text(DateFormat('dd/MM/yyyy – HH:mm').format(departure)),
      trailing: IconButton(
        icon: const Icon(Icons.edit_calendar),
        onPressed: _pickDateTime,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _inputField(
    String label,
    String initial,
    Function(String) onChanged,
    TextInputType type, {
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        initialValue: initial,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.white.withOpacity(0.85),
        ),
        keyboardType: type,
        onChanged: onChanged,
        validator: validator ?? (v) => v!.isEmpty ? 'Requis' : null,
      ),
    );
  }

  Widget _floatingButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        FloatingActionButton.extended(
          onPressed: _delete,
          heroTag: 'deleteBtn',
          backgroundColor: Colors.redAccent,
          icon: const Icon(Icons.delete_forever),
          label: const Text('Supprimer'),
        ),
        FloatingActionButton.extended(
          onPressed: _save,
          heroTag: 'saveBtn',
          backgroundColor: Styles.defaultBlueColor,
          icon: const Icon(Icons.save_alt),
          label: const Text('Sauvegarder'),
        ),
      ],
    );
  }
}

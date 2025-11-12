import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/signalement_service.dart';
import '../models/signalement.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // for FirebaseFirestore
import 'package:intl/intl.dart'; // for DateFormat
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../services/cloudinary_service.dart';
import 'package:geolocator/geolocator.dart';




class SignalementsMapScreen extends StatefulWidget {
  @override
  _SignalementsMapScreenState createState() => _SignalementsMapScreenState();
}

class _SignalementsMapScreenState extends State<SignalementsMapScreen> {
  final SignalementService _service = SignalementService();
  final MapController _mapController = MapController();
  List<Signalement> _signalements = [];
  LatLng? _currentPosition;
  Signalement? _focusedSignalement;


  @override
  void initState() {
    super.initState();
    _service.getSignalementsStream().listen((data) {
      setState(() {
        _signalements = data;
      });
    });
    _getUserLocation();
    _determinePosition();


  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied.');
    }

    // Get current position
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);

      // Move the map camera to user location
      _mapController.move(_currentPosition!, 15.0); // zoom level 15
    });
  }


  Future<void> _getUserLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return; // Location services are not enabled
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
    });
  }

  Signalement? _findNearestSignalement(LatLng center) {
    const maxDistanceMeters = 100; // distance threshold for preview
    final Distance distance = Distance();

    Signalement? nearest;
    double nearestDistance = double.infinity;

    for (var s in _signalements) {
      double d = distance(center, LatLng(s.latitude, s.longitude));
      if (d < nearestDistance && d < maxDistanceMeters) {
        nearest = s;
        nearestDistance = d;
      }
    }
    return nearest;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('SafeRoad - Signalements')),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          center:  _currentPosition ?? LatLng(36.8065, 10.1815),
          zoom: 15.0,
          minZoom: 3.0,   // optional: minimum zoom out
          maxZoom: 18.0,  // optional: maximum zoom in
          interactiveFlags: InteractiveFlag.all,
          onTap: (tapPosition, point) {
            _showAddSignalementForm(point);
          },
          onPositionChanged: (position, hasGesture) {
            // Detect zoom level change
            double zoom = position.zoom ?? 0;
            LatLng center = position.center ?? _mapController.center;

            if (zoom >= 16) {
              // Find nearest signalement to center
              Signalement? nearest = _findNearestSignalement(center);
              if (nearest != null) {
                setState(() {
                  _focusedSignalement = nearest;
                });
              }
            } else {
              setState(() {
                _focusedSignalement = null;
              });
            }
          },

        ),

        children: [
          TileLayer(
            urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
            subdomains: ['a', 'b', 'c'],
          ),
          MarkerLayer(
            markers: [
              // User location marker
              if (_currentPosition != null)
                Marker(
                  width: 80,
                  height: 80,
                  point: _currentPosition!,
                  builder: (_) => Icon(Icons.my_location, color: Colors.blue, size: 40),
                ),
              // Signalement markers
              ..._signalements.map((s) => Marker(
                width: 80,
                height: 80,
                point: LatLng(s.latitude, s.longitude),
                builder: (ctx) => GestureDetector(
                  onTap: () async {
                    // Fetch user name from Firestore (if you store it)
                    String userName = 'Utilisateur inconnu';
                    try {
                      final doc = await FirebaseFirestore.instance
                          .collection('users')
                          .doc(s.userId)
                          .get();
                      if (doc.exists && doc.data()!.containsKey('name')) {
                        userName = doc['name'];
                      }
                    } catch (_) {}

                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: Text(s.type),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Description: ${s.description}'),
                            SizedBox(height: 4),
                            Text('Confirmations: ${s.confirmations}'),
                            SizedBox(height: 4),
                            Text('Signalé par: $userName'),
                            SizedBox(height: 4),
                            Text('Date: ${DateFormat('dd/MM/yyyy HH:mm').format(s.date)}'),
                            if (s.photoUrl != null && s.photoUrl!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Image.network(s.photoUrl!, height: 150),
                              ),
                          ],
                        ),
                        actions: [
                          if (s.userId == FirebaseAuth.instance.currentUser!.uid) ...[
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context); // Close current dialog first
                                _showEditSignalementForm(s);
                              },
                              child: Text('Modifier'),
                            ),
                            TextButton(
                              onPressed: () async {
                                await _service.deleteSignalement(s.id);
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Signalement supprimé avec succès')),
                                );
                              },
                              child: Text('Supprimer', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                          TextButton(
                            onPressed: () {
                              _service.confirmSignalement(s.id);
                              Navigator.pop(context);
                            },
                            child: Text('Confirmer'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('Fermer'),
                          ),
                        ],

                      ),
                    );
                  },
                  child: Icon(
                    _getMarkerIcon(s.type),
                    color: _getMarkerColor(s.type),
                    size: 40,
                  ),
                ),
              )),
            ],
          ),

          // ✅ Small preview card overlay
          if (_focusedSignalement != null)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: AnimatedOpacity(
                opacity: 1.0,
                duration: Duration(milliseconds: 300),
                child: Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_focusedSignalement!.photoUrl != null &&
                            _focusedSignalement!.photoUrl!.isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              _focusedSignalement!.photoUrl!,
                              height: 60,
                              width: 60,
                              fit: BoxFit.cover,
                            ),
                          ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_focusedSignalement!.type,
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              Text(
                                _focusedSignalement!.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 4),
                              Text(
                                DateFormat('dd/MM HH:mm').format(_focusedSignalement!.date),
                                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          Positioned(
            top: 16,
            right: 16,
            child: Column(
              children: [
                FloatingActionButton(
                  mini: true,
                  heroTag: "zoom_in",
                  onPressed: () {
                    _mapController.move(_mapController.center, _mapController.zoom + 1);
                  },
                  child: Icon(Icons.add),
                ),
                SizedBox(height: 8),
                FloatingActionButton(
                  mini: true,
                  heroTag: "zoom_out",
                  onPressed: () {
                    _mapController.move(_mapController.center, _mapController.zoom - 1);
                  },
                  child: Icon(Icons.remove),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Color _getMarkerColor(String type) {
    switch (type) {
      case 'Accident':
        return Colors.red;
      case 'Obstacle':
        return Colors.orange;
      case 'Route endommagée':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getMarkerIcon(String type) {
    switch (type) {
      case 'Accident':
        return Icons.dangerous;
      case 'Obstacle':
        return Icons.report_problem;
      case 'Route endommagée':
        return Icons.terrain;
      default:
        return Icons.location_on;
    }
  }

  void _showAddSignalementForm(LatLng point) {
    final _formKey = GlobalKey<FormState>();
    String? selectedType;
    String description = '';
    XFile? pickedImage; // holds selected image

    final List<String> types = ['Accident', 'Obstacle', 'Route endommagée'];
    final ImagePicker picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: StatefulBuilder(
          builder: (context, setModalState) => Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Nouveau Signalement',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

                // Dropdown for type
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(labelText: 'Type de signalement'),
                  value: selectedType,
                  items: types
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (val) => setModalState(() => selectedType = val),
                  validator: (val) => val == null || val.isEmpty ? 'Champ requis' : null,
                ),

                // Description
                TextFormField(
                  decoration: InputDecoration(labelText: 'Description'),
                  validator: (val) => val == null || val.isEmpty ? 'Champ requis' : null,
                  onSaved: (val) => description = val!,
                ),

                SizedBox(height: 12),

                // Image picker
                Row(
                  children: [
                    ElevatedButton.icon(
                      icon: Icon(Icons.photo),
                      label: Text('Ajouter une photo'),
                      onPressed: () async {
                        final image = await picker.pickImage(source: ImageSource.gallery);
                        if (image != null) {
                          setModalState(() => pickedImage = image);
                        }
                      },
                    ),
                    SizedBox(width: 8),
                    if (pickedImage != null) Text('Image sélectionnée')
                  ],
                ),

                SizedBox(height: 12),
                ElevatedButton(
                  child: Text('Ajouter'),
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();

                      String? photoUrl;
                      if (pickedImage != null) {
                        // Upload image to Cloudinary
                        try {
                          photoUrl = await CloudinaryService.uploadImage(File(pickedImage!.path));
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Erreur lors de l\'upload de l\'image'))
                          );
                          return;
                        }
                      }

                      final newSignalement = Signalement(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        type: selectedType!,
                        description: description,
                        latitude: point.latitude,
                        longitude: point.longitude,
                        date: DateTime.now(),
                        confirmations: 0,
                        userId: FirebaseAuth.instance.currentUser!.uid,
                        photoUrl: photoUrl,
                      );

                      await _service.addSignalement(newSignalement);
                      Navigator.pop(context);
                    }
                  },
                ),

                SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }


  void _showEditSignalementForm(Signalement signalement) {
    final _formKey = GlobalKey<FormState>();
    String? selectedType = signalement.type;
    String description = signalement.description;
    XFile? pickedImage;
    final ImagePicker picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: StatefulBuilder(
          builder: (context, setModalState) => Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Modifier le Signalement',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(labelText: 'Type'),
                  value: selectedType,
                  items: ['Accident', 'Obstacle', 'Route endommagée']
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (val) => setModalState(() => selectedType = val),
                ),
                TextFormField(
                  initialValue: description,
                  decoration: InputDecoration(labelText: 'Description'),
                  onSaved: (val) => description = val!,
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    ElevatedButton.icon(
                      icon: Icon(Icons.photo),
                      label: Text('Changer la photo'),
                      onPressed: () async {
                        final image =
                        await picker.pickImage(source: ImageSource.gallery);
                        if (image != null) {
                          setModalState(() => pickedImage = image);
                        }
                      },
                    ),
                    SizedBox(width: 8),
                    if (pickedImage != null) Text('Nouvelle image sélectionnée'),
                  ],
                ),
                SizedBox(height: 12),
                ElevatedButton(
                  child: Text('Mettre à jour'),
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();

                      String? newPhotoUrl = signalement.photoUrl;

                      // Upload new image if picked
                      if (pickedImage != null) {
                        try {
                          newPhotoUrl = await CloudinaryService.uploadImage(
                              File(pickedImage!.path));
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Erreur lors du changement d\'image')),
                          );
                          return;
                        }
                      }

                      final updatedSignalement = Signalement(
                        id: signalement.id,
                        type: selectedType!,
                        description: description,
                        latitude: signalement.latitude,
                        longitude: signalement.longitude,
                        date: DateTime.now(),
                        confirmations: signalement.confirmations,
                        userId: signalement.userId,
                        photoUrl: newPhotoUrl,
                      );

                      await _service.updateSignalement(updatedSignalement);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Signalement mis à jour')),
                      );
                    }
                  },
                ),
                SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }




}

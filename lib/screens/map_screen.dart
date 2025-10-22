import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../controllers/announcement_controller.dart';
import '../styles/styles.dart';

class MapScreen extends StatefulWidget {
  final String? selectionMode; 

  const MapScreen({super.key, this.selectionMode});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  static const CameraPosition _tunisia = CameraPosition(target: LatLng(34.0, 9.0), zoom: 6.0);
  static final LatLngBounds _tunisiaBounds = LatLngBounds(
    southwest: const LatLng(30.0, 7.0),
    northeast: const LatLng(37.5, 12.0),
  );
  LatLng? _selectedPosition;
  String? _selectedPlace;

  @override
  void initState() {
    super.initState();
    _selectedPosition = null;
    _selectedPlace = null;
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  String _getPlaceNameFromLatLng(LatLng position) {

    if (position.latitude >= 36.7 && position.latitude <= 36.9 && position.longitude >= 10.1 && position.longitude <= 10.3) {
      return 'Tunis';
    } else if (position.latitude >= 35.7 && position.latitude <= 35.9 && position.longitude >= 10.5 && position.longitude <= 10.7) {
      return 'Sousse';
    } else if (position.latitude >= 34.7 && position.latitude <= 34.9 && position.longitude >= 10.7 && position.longitude <= 10.9) {
      return 'Sfax';
    }
    return 'Lieu sélectionné (${position.latitude.toStringAsFixed(2)}, ${position.longitude.toStringAsFixed(2)})';
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = Provider.of<AnnouncementController>(context);
    final isSelectionMode = widget.selectionMode != null;

    final announcementMarkers = ctrl.announcements.asMap().entries.map((e) {
      final a = e.value;
      final latLng = a.originLatLng ?? LatLng(34.0 + (e.key * 0.2), 9.0 + (e.key * 0.4)); // Fallback for demo
      return Marker(
        markerId: MarkerId(a.id),
        position: latLng,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: InfoWindow(
          title: '${a.origin} → ${a.destination}',
          snippet: '${a.price.toStringAsFixed(2)} TND',
        ),
        onTap: () => showModalBottomSheet(
          context: context,
          builder: (_) => Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${a.origin} → ${a.destination}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Styles.darkDefaultLightWhiteColor
                        : Styles.defaultRedColor,
                  ),
                ),
                Text('${a.carModel} • ${a.driverName}'),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Styles.defaultBlueColor,
                    shape: RoundedRectangleBorder(borderRadius: Styles.defaultBorderRadius),
                  ),
                  child: const Text('Fermer'),
                ),
              ],
            ),
          ),
        ),
      );
    }).toSet();

    final selectionMarker = _selectedPosition != null
        ? {
            Marker(
              markerId: const MarkerId('selection'),
              position: _selectedPosition!,
              icon: BitmapDescriptor.defaultMarkerWithHue(
                widget.selectionMode == 'origin' ? BitmapDescriptor.hueRed : BitmapDescriptor.hueGreen,
              ),
              infoWindow: InfoWindow(title: _selectedPlace ?? 'Lieu sélectionné'),
            ),
          }
        : <Marker>{};

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isSelectionMode ? 'Sélectionner ${widget.selectionMode == 'origin' ? 'l\'origine' : 'la destination'}' : 'Carte',
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? Styles.darkDefaultLightWhiteColor
                : Styles.defaultRedColor,
          ),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: GoogleMap(
        initialCameraPosition: _tunisia,
        onMapCreated: (controller) {
          _mapController = controller;
          _mapController!.setMapStyle(null); 
        },
        markers: isSelectionMode ? selectionMarker : announcementMarkers,
        onTap: isSelectionMode
            ? (LatLng position) {
                if (_tunisiaBounds.contains(position)) {
                  setState(() {
                    _selectedPosition = position;
                    _selectedPlace = _getPlaceNameFromLatLng(position);
                    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(position, 12));
                  });
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Veuillez sélectionner un lieu en Tunisie'),
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(borderRadius: Styles.defaultBorderRadius),
                    ),
                  );
                }
              }
            : null,
        minMaxZoomPreference: const MinMaxZoomPreference(6, 15),
        cameraTargetBounds: CameraTargetBounds(_tunisiaBounds),
        myLocationEnabled: false,
        zoomControlsEnabled: true,
      ),
      floatingActionButton: isSelectionMode && _selectedPosition != null
          ? FloatingActionButton(
              onPressed: () {
                Navigator.pop(context, {
                  'place': _selectedPlace,
                  'latLng': _selectedPosition,
                });
              },
              backgroundColor: Styles.defaultBlueColor,
              child: const Icon(Icons.check, color: Colors.white),
            )
          : null,
    );
  }
}
import 'package:covoiturage_app/screens/my_rides_screen.dart';
import 'package:covoiturage_app/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/announcement.dart';
import '../controllers/announcement_controller.dart';
import '../controllers/auth_controller.dart';
import '../styles/styles.dart';
import 'map_screen.dart';

class DriverCreateScreen extends StatefulWidget {
  const DriverCreateScreen({super.key});

  @override
  _DriverCreateScreenState createState() => _DriverCreateScreenState();
}

class _DriverCreateScreenState extends State<DriverCreateScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  String origin = '';
  String destination = '';
  DateTime? departure;
  int seats = 0;
  double price = 0.0;
  String carModel = '';
  String driverName = '';
  String driverPhone = '';
  LatLng? originLatLng;
  LatLng? destinationLatLng;
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _seatsController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _carModelController = TextEditingController();
  final TextEditingController _driverNameController = TextEditingController();
  final TextEditingController _driverPhoneController = TextEditingController();
  int _currentStep = 0;
  late AnimationController _animationController;
  late Animation<double> _buttonScaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _buttonScaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Auto-fill user info from authenticated user
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authController = Provider.of<AuthController>(
        context,
        listen: false,
      );
      final user = authController.currentUser;
      if (user != null) {
        setState(() {
          driverName = user.name;
          driverPhone = user.phone;
          _driverNameController.text = user.name;
          _driverPhoneController.text = user.phone;
        });
      }
    });
  }

  @override
  void dispose() {
    _dateController.dispose();
    _seatsController.dispose();
    _priceController.dispose();
    _carModelController.dispose();
    _driverNameController.dispose();
    _driverPhoneController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 2) {
      if (_formKey.currentState!.validate()) {
        setState(() => _currentStep++);
      } else {
        _animationController.forward().then(
          (_) => _animationController.reverse(),
        );
      }
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final ann = Announcement(
        id: DateTime.now().toString(),
        origin: origin,
        destination: destination,
        originLatLng: originLatLng,
        destinationLatLng: destinationLatLng,
        departureDateTime: departure ?? DateTime.now(),
        availableSeats: seats,
        price: price,
        carModel: carModel,
        driverName: driverName,
        driverPhone: driverPhone,
      );
      Provider.of<AnnouncementController>(
        context,
        listen: false,
      ).addAnnouncement(ann);
      await StorageService.setString('myPhone', driverPhone);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Trajet posté avec succès !'),
          backgroundColor: Styles.darkDefaultYellowColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: Styles.defaultBorderRadius,
          ),
          action: SnackBarAction(
            label: 'OK',
            textColor: Styles.darkDefaultLightWhiteColor,
            onPressed: () {},
          ),
        ),
      );
    } else {
      _animationController.forward().then(
        (_) => _animationController.reverse(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Poster un trajet',
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
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 28),
          onPressed: () => Navigator.pop(context),
          color: Theme.of(context).brightness == Brightness.dark
              ? Styles.darkDefaultBlueColor
              : Styles.defaultBlueColor,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            LinearProgressIndicator(
              value: (_currentStep + 1) / 3,
              color: Styles.defaultBlueColor,
              backgroundColor: Styles.defaultLightGreyColor,
              minHeight: 6,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: Styles.defaultPadding,
                  vertical: Styles.defaultPadding,
                ),
                child: Form(key: _formKey, child: _buildStepContent()),
              ),
            ),
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Lieu de départ et arrivée'),
            const SizedBox(height: 16),
            _buildMapPreview(origin, originLatLng, 'Origine', Colors.red),
            _buildTextField(
              label: 'Origine',
              hint: 'Entrez la ville de départ',
              onChanged: (val) => setState(() => origin = val),
              icon: Icons.location_on,
              validator: (val) => val!.isEmpty ? 'Entrez une origine' : null,
            ),
            const SizedBox(height: 16),
            _buildMapButton(
              context,
              label: 'Choisir l\'origine sur la carte',
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MapScreen(selectionMode: 'origin'),
                  ),
                );
                if (result != null && result is Map<String, dynamic>) {
                  setState(() {
                    origin = result['place'] as String;
                    originLatLng = result['latLng'] as LatLng;
                  });
                }
              },
            ),
            const SizedBox(height: 24),
            _buildMapPreview(
              destination,
              destinationLatLng,
              'Destination',
              Colors.green,
            ),
            _buildTextField(
              label: 'Destination',
              hint: 'Entrez la ville d\'arrivée',
              onChanged: (val) => setState(() => destination = val),
              icon: Icons.flag,
              validator: (val) =>
                  val!.isEmpty ? 'Entrez une destination' : null,
            ),
            const SizedBox(height: 16),
            _buildMapButton(
              context,
              label: 'Choisir la destination sur la carte',
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MapScreen(selectionMode: 'destination'),
                  ),
                );
                if (result != null && result is Map<String, dynamic>) {
                  setState(() {
                    destination = result['place'] as String;
                    destinationLatLng = result['latLng'] as LatLng;
                  });
                }
              },
            ),
          ],
        );
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Détails du trajet'),
            const SizedBox(height: 16),
            _buildTextField(
              label: 'Date/Heure départ',
              hint: 'Sélectionnez la date et l\'heure',
              controller: _dateController,
              readOnly: true,
              onTap: () async {
                DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2100),
                  builder: (context, child) => Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ColorScheme.light(
                        primary: Styles.defaultBlueColor,
                        onPrimary: Colors.white,
                      ),
                    ),
                    child: child!,
                  ),
                );
                if (picked != null) {
                  TimeOfDay? time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                    builder: (context, child) => Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: ColorScheme.light(
                          primary: Styles.defaultBlueColor,
                          onPrimary: Colors.white,
                        ),
                      ),
                      child: child!,
                    ),
                  );
                  if (time != null) {
                    setState(() {
                      departure = DateTime(
                        picked.year,
                        picked.month,
                        picked.day,
                        time.hour,
                        time.minute,
                      );
                      _dateController.text = DateFormat(
                        'dd/MM/yyyy HH:mm',
                      ).format(departure!);
                    });
                  }
                }
              },
              icon: Icons.calendar_today,
              validator: (val) =>
                  departure != null ? null : 'Sélectionnez une date',
            ),
            const SizedBox(height: 24),
            _buildTextField(
              label: 'Sièges disponibles',
              hint: 'Nombre de sièges',
              controller: _seatsController,
              keyboardType: TextInputType.number,
              onChanged: (val) =>
                  setState(() => seats = int.tryParse(val) ?? 0),
              icon: Icons.event_seat,
              validator: (val) =>
                  (int.tryParse(val!) != null && int.parse(val) > 0)
                  ? null
                  : 'Entrez un nombre valide',
            ),
            const SizedBox(height: 24),
            _buildTextField(
              label: 'Prix (TND)',
              hint: 'Prix par siège',
              controller: _priceController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (val) =>
                  setState(() => price = double.tryParse(val) ?? 0.0),
              icon: Icons.attach_money,
              validator: (val) =>
                  (double.tryParse(val!) != null && double.parse(val) > 0)
                  ? null
                  : 'Entrez un prix valide',
            ),
          ],
        );
      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Informations du chauffeur'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Styles.darkDefaultYellowColor.withOpacity(0.1)
                    : Styles.defaultYellowColor.withOpacity(0.1),
                borderRadius: Styles.defaultBorderRadius,
                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Styles.darkDefaultYellowColor.withOpacity(0.3)
                      : Styles.defaultYellowColor.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Styles.darkDefaultYellowColor
                        : Styles.defaultYellowColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Ces informations proviennent de votre compte et ne peuvent pas être modifiées',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Styles.darkDefaultGreyColor
                            : Styles.defaultGreyColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: 'Nom chauffeur',
              hint: 'Votre nom',
              controller: _driverNameController,
              readOnly: true,
              icon: Icons.person,
              validator: (val) => val!.isEmpty ? 'Entrez votre nom' : null,
            ),
            const SizedBox(height: 24),
            _buildTextField(
              label: 'Téléphone',
              hint: 'Numéro de téléphone',
              controller: _driverPhoneController,
              readOnly: true,
              keyboardType: TextInputType.phone,
              validator: (val) =>
                  (val?.length == 8 && int.tryParse(val!) != null)
                  ? null
                  : 'Numéro invalide (8 chiffres)',
              icon: Icons.phone,
            ),
            const SizedBox(height: 24),
            _buildTextField(
              label: 'Modèle voiture',
              hint: 'Entrez le modèle de la voiture',
              controller: _carModelController,
              onChanged: (val) => setState(() => carModel = val),
              icon: Icons.directions_car,
              validator: (val) =>
                  val!.isEmpty ? 'Entrez un modèle de voiture' : null,
            ),
          ],
        );
      default:
        return const SizedBox();
    }
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).brightness == Brightness.dark
            ? Styles.darkDefaultLightWhiteColor
            : Styles.defaultRedColor,
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    TextEditingController? controller,
    bool readOnly = false,
    void Function()? onTap,
    void Function(String)? onChanged,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    IconData? icon,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Styles.darkDefaultLightGreyColor
            : Styles.defaultLightGreyColor,
        borderRadius: Styles.defaultBorderRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        onTap: onTap,
        onChanged: onChanged,
        keyboardType: keyboardType,
        validator: validator,
        style: TextStyle(
          fontSize: 16,
          color: Theme.of(context).brightness == Brightness.dark
              ? Styles.darkDefaultLightWhiteColor
              : Styles.defaultRedColor,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: icon != null
              ? Icon(
                  icon,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Styles.darkDefaultYellowColor
                      : Styles.defaultYellowColor,
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(Styles.defaultPadding),
          labelStyle: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? Styles.darkDefaultGreyColor
                : Styles.defaultGreyColor,
          ),
          hintStyle: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? Styles.darkDefaultGreyColor.withOpacity(0.6)
                : Styles.defaultGreyColor.withOpacity(0.6),
          ),
        ),
      ),
    );
  }

  Widget _buildMapButton(
    BuildContext context, {
    required String label,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTapDown: (_) => _animationController.forward(),
      onTapUp: (_) {
        _animationController.reverse();
        onPressed();
      },
      onTapCancel: () => _animationController.reverse(),
      child: ScaleTransition(
        scale: _buttonScaleAnimation,
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: Styles.defaultPadding / 1.2,
            horizontal: Styles.defaultPadding,
          ),
          decoration: BoxDecoration(
            borderRadius: Styles.defaultBorderRadius,
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Styles.darkDefaultBlueColor
                  : Styles.defaultBlueColor,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.map,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Styles.darkDefaultBlueColor
                    : Styles.defaultBlueColor,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Styles.darkDefaultLightWhiteColor
                      : Styles.defaultRedColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapPreview(
    String location,
    LatLng? latLng,
    String label,
    Color markerColor,
  ) {
    return location.isNotEmpty && latLng != null
        ? Container(
            height: 120,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              borderRadius: Styles.defaultBorderRadius,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: Styles.defaultBorderRadius,
              child: GoogleMap(
                initialCameraPosition: CameraPosition(target: latLng, zoom: 12),
                markers: {
                  Marker(
                    markerId: MarkerId(label),
                    position: latLng,
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                      markerColor == Colors.red
                          ? BitmapDescriptor.hueRed
                          : BitmapDescriptor.hueGreen,
                    ),
                    infoWindow: InfoWindow(title: location),
                  ),
                },
                liteModeEnabled: true,
                zoomControlsEnabled: false,
                myLocationButtonEnabled: false,
              ),
            ),
          )
        : const SizedBox();
  }

  Widget _buildNavigationButtons() {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: Styles.defaultPadding,
        vertical: Styles.defaultPadding / 1.5,
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _currentStep > 0 ? _previousStep : null,
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Styles.darkDefaultBlueColor
                      : Styles.defaultBlueColor,
                ),
                padding: EdgeInsets.symmetric(
                  vertical: Styles.defaultPadding / 1.2,
                ),
              ),
              child: Text(
                'Précédent',
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Styles.darkDefaultLightWhiteColor
                      : Styles.defaultRedColor,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: _currentStep < 2
                  ? () {
                      if (_formKey.currentState!.validate()) {
                        _nextStep();
                      } else {
                        _animationController.forward().then(
                          (_) => _animationController.reverse(),
                        );
                      }
                    }
                  : () {
                      if (_formKey.currentState!.validate()) {
                        _submitForm();

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Trajet ajouté avec succès'),
                            backgroundColor: Colors.green,
                            duration: Duration(seconds: 2),
                          ),
                        );

                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const MyRidesScreen(),
                            ),
                            (route) => false,
                          );
                        });
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Styles.defaultBlueColor,
                padding: EdgeInsets.symmetric(
                  vertical: Styles.defaultPadding / 1.2,
                ),
              ),
              child: Text(
                _currentStep < 2 ? 'Suivant' : 'Terminer',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

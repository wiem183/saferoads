import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/reservation.dart';
import '../controllers/announcement_controller.dart';
import '../controllers/reservation_controller.dart';
import '../services/payment_service.dart';
import '../styles/styles.dart';
import 'history_screen.dart';

class ReservationScreen extends StatefulWidget {
  final String announcementId;

  const ReservationScreen({super.key, required this.announcementId});

  @override
  _ReservationScreenState createState() => _ReservationScreenState();
}

class _ReservationScreenState extends State<ReservationScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  String name = '';
  String phone = '';
  String email = ''; // ← CHAMP EMAIL AJOUTÉ
  int seats = 1;
  String payment = 'cash';
  String cardNumber = '';
  String expiryDate = '';
  String cvv = '';
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
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _submitReservation() async {
    if (_formKey.currentState!.validate()) {
      Reservation res = Reservation(
        reserverName: name,
        reserverPhone: phone,
        reserverEmail: email, // ← EMAIL UTILISÉ ICI
        seatsReserved: seats,
        paymentMethod: payment,
      );
      bool success = await Provider.of<ReservationController>(
        context,
        listen: false,
      ).reserveSeats(widget.announcementId, res);
      if (success) {
        if (payment == 'credit') {
          bool paymentSuccess = await PaymentService.processCreditCardPayment(
            cardNumber,
            expiryDate,
            cvv,
          );
          if (paymentSuccess) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Paiement réussi !')));
          } else {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Erreur de paiement')));
            return;
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'OK, merci. Vous payez en espèces lors de la rencontre.',
              ),
            ),
          );
        }
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const HistoryScreen()),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Erreur de réservation')));
      }
    } else {
      _animationController.forward().then(
        (_) => _animationController.reverse(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: EdgeInsets.all(Styles.defaultPadding),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Styles.defaultGreyColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  'Réserver un siège',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Styles.darkDefaultLightWhiteColor
                        : Styles.defaultRedColor,
                  ),
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  label: 'Votre nom',
                  hint: 'Entrez votre nom',
                  onChanged: (val) => name = val,
                  icon: Icons.person,
                  validator: (val) => val!.isEmpty ? 'Nom requis' : null,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  label: 'Téléphone (8 chiffres)',
                  hint: 'Entrez votre numéro de téléphone',
                  keyboardType: TextInputType.phone,
                  onChanged: (val) => phone = val,
                  icon: Icons.phone,
                  validator: (val) =>
                      (val!.length == 8 && int.tryParse(val) != null)
                      ? null
                      : 'Numéro invalide (8 chiffres)',
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  label: 'Email', // ← CHAMP EMAIL AJOUTÉ
                  hint: 'Entrez votre email',
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (val) => email = val,
                  icon: Icons.email,
                  validator: (val) => (val!.isNotEmpty && val.contains('@'))
                      ? null
                      : 'Email invalide',
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  label: 'Sièges à réserver',
                  hint: 'Nombre de sièges',
                  keyboardType: TextInputType.number,
                  onChanged: (val) => seats = int.tryParse(val) ?? 1,
                  icon: Icons.event_seat,
                  validator: (val) =>
                      (int.tryParse(val!) != null && int.parse(val) > 0)
                      ? null
                      : 'Entrez un nombre valide',
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: payment,
                  decoration: InputDecoration(
                    labelText: 'Méthode de paiement',
                    border: OutlineInputBorder(
                      borderRadius: Styles.defaultBorderRadius,
                    ),
                    contentPadding: EdgeInsets.all(Styles.defaultPadding),
                  ),
                  items: ['cash', 'credit']
                      .map(
                        (p) => DropdownMenuItem(
                          value: p,
                          child: Text(p == 'cash' ? 'Espèces' : 'Carte crédit'),
                        ),
                      )
                      .toList(),
                  onChanged: (val) => setState(() => payment = val!),
                ),
                if (payment == 'credit') ...[
                  const SizedBox(height: 16),
                  _buildTextField(
                    label: 'Numéro de carte',
                    hint: 'Entrez le numéro de carte',
                    keyboardType: TextInputType.number,
                    onChanged: (val) => cardNumber = val,
                    icon: Icons.credit_card,
                    validator: (val) =>
                        val!.length >= 16 ? null : 'Numéro de carte invalide',
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    label: 'Date d\'expiration (MM/YY)',
                    hint: 'Entrez la date d\'expiration',
                    keyboardType: TextInputType.datetime,
                    onChanged: (val) => expiryDate = val,
                    icon: Icons.calendar_month,
                    validator: (val) => val!.contains('/') && val.length == 5
                        ? null
                        : 'Format invalide (MM/YY)',
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    label: 'CVV',
                    hint: 'Entrez le CVV',
                    keyboardType: TextInputType.number,
                    onChanged: (val) => cvv = val,
                    icon: Icons.lock,
                    validator: (val) =>
                        val!.length == 3 ? null : 'CVV invalide (3 chiffres)',
                  ),
                ],
                const SizedBox(height: 24),
                Center(
                  child: GestureDetector(
                    onTapDown: (_) => _animationController.forward(),
                    onTapUp: (_) {
                      _animationController.reverse();
                      _submitReservation();
                    },
                    onTapCancel: () => _animationController.reverse(),
                    child: ScaleTransition(
                      scale: _buttonScaleAnimation,
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          vertical: Styles.defaultPadding,
                          horizontal: Styles.defaultPadding * 2,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Styles.defaultBlueColor,
                              Styles.defaultYellowColor,
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: Styles.defaultBorderRadius,
                          boxShadow: [
                            BoxShadow(
                              color: Styles.defaultBlueColor.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          'Confirmer',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    void Function(String)? onChanged,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    IconData? icon,
  }) {
    return TextFormField(
      onChanged: onChanged,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon != null
            ? Icon(icon, color: Styles.defaultYellowColor)
            : null,
        border: OutlineInputBorder(borderRadius: Styles.defaultBorderRadius),
        contentPadding: EdgeInsets.all(Styles.defaultPadding),
        filled: true,
        fillColor: Styles.defaultLightGreyColor.withOpacity(0.5),
      ),
    );
  }
}

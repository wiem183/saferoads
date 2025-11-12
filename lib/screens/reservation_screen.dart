// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously, deprecated_member_use

import 'dart:typed_data';
import 'dart:ui' as ui;
// <-- AJOUTER
import 'dart:convert'; // <-- assure-toi d'avoir cet import



import 'package:flutter/material.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server/gmail.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/reservation.dart';
import '../controllers/reservation_controller.dart';
import '../services/payment_service.dart';
import '../styles/styles.dart';
import 'history_screen.dart';

class ReservationScreen extends StatefulWidget {
  final String announcementId;
  final String parkingId;
  final String parkingName;
  final double pricePerHour;

  const ReservationScreen({
    super.key,
    required this.announcementId,
    required this.parkingId,
    required this.parkingName,
    required this.pricePerHour,
  });

  @override
  _ReservationScreenState createState() => _ReservationScreenState();
}

class _ReservationScreenState extends State<ReservationScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  String name = '';
  String phone = '';
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

    // 🔹 Test d’envoi automatique au démarrage (tu peux le supprimer après test)
    _sendEmail(
      "nermine.ghouibii@gmail.com",
      "Test de démarrage SafeRoad 🚗",
      "Ceci est un test automatique pour vérifier le service mailer ✅",
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// 📨 Envoi d’un e-mail de confirmation via Gmail (SMTP)
Future<void> _sendEmail(String to, String subject, String message) async {
  try {
    print("🚀 Connexion SMTP à Gmail...");

    final smtpServer = gmail(
      'nermine.ghouibii@gmail.com',
      'rbfs hocz wofw imkz', // mot de passe d’application Gmail
    );

    // 1) Données + génération du QR en bytes (PNG)
    final qrData =
        'Parking: ${widget.parkingName}\nPrix: ${widget.pricePerHour} dt/h\nNom: $name\nTéléphone: $phone\nDate: ${DateTime.now()}';
    final qrBytes = await _buildQrPngBytes(qrData);

    // 2) Encodage Base64 pour insertion inline
    final qrBase64 = base64Encode(qrBytes);
    final qrImgTag =
        '<img alt="QR de votre réservation" src="data:image/png;base64,$qrBase64" style="width:220px;height:220px;display:block;margin:12px 0;border:1px solid #eee;border-radius:8px" />';

    // 3) Corps HTML joli + le QR inline
    final htmlBody = '''
      <div style="font-family:system-ui,-apple-system,Segoe UI,Roboto,Arial,sans-serif;line-height:1.5;color:#222">
        <h2 style="margin:0 0 8px">Confirmation de réservation SafeRoad 🚗</h2>
        <p>${message.replaceAll('\n', '<br/>')}</p>
        <p><strong>Parking :</strong> ${widget.parkingName}<br/>
           <strong>Tarif :</strong> ${widget.pricePerHour.toStringAsFixed(2)} dt/h<br/>
           <strong>Nom :</strong> $name<br/>
           <strong>Téléphone :</strong> $phone<br/>
           <strong>Date :</strong> ${DateTime.now().toString().substring(0,16)}
        </p>
        <p>Présentez ce QR code à l'entrée :</p>
        $qrImgTag
        <p style="font-size:12px;color:#666">Si l'image ne s'affiche pas, activez “Afficher les images” dans votre client mail.</p>
      </div>
    ''';

    // 4) Message (HTML inline + texte fallback)
    final email = Message()
      ..from = Address('nermine.ghouibii@gmail.com', 'SafeRoad App')
      ..recipients.add(to)
      ..subject = subject
      ..text = message // fallback texte
      ..html = htmlBody; // ✅ QR inline ici

    final sendReport = await send(email, smtpServer);
    print('✅ E-mail envoyé avec QR inline : ${sendReport.toString()}');
  } on MailerException catch (e) {
    print('❌ Erreur Mailer : ${e.toString()}');
    for (var p in e.problems) {
      print('🔸 ${p.code}: ${p.msg}');
    }
  } catch (e) {
    print('⚠️ Erreur inattendue : $e');
  }
}

  Future<Uint8List> _buildQrPngBytes(String data) async {
  final painter = QrPainter(
    data: data,
    version: QrVersions.auto,
    gapless: true,
  );
  final uiImage = await painter.toImage(512);
  final byteData = await uiImage.toByteData(format: ui.ImageByteFormat.png);
  return byteData!.buffer.asUint8List();
}

  /// 🔹 Soumission de la réservation
  Future<void> _submitReservation() async {
    if (_formKey.currentState!.validate()) {
      Reservation res = Reservation(
        reserverName: name,
        reserverPhone: phone,
        seatsReserved: seats,
        paymentMethod: payment,
      );

      print("🚗 Tentative de réservation parking pour ID: ${widget.parkingId}");

      print("⏳ Envoi des données de réservation au contrôleur...");
bool success =
    await Provider.of<ReservationController>(context, listen: false)
        .reserveSeatsOrParking(
  announcementId: widget.announcementId,
  parkingId: widget.parkingId,
  res: res,
);
print("📬 Résultat du contrôleur : $success");


      if (success) {
        print("✅ Réservation confirmée, préparation de l’e-mail...");

        if (payment == 'credit') {
          bool paymentSuccess = await PaymentService.processCreditCardPayment(
              cardNumber, expiryDate, cvv);
          if (paymentSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('✅ Paiement réussi !')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('❌ Erreur de paiement')),
            );
            return;
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('💵 Paiement en espèces sur place confirmé.')),
          );
        }

        // ✅ Envoi automatique du mail de confirmation
        print("📤 Tentative d’envoi d’email...");
        await _sendEmail(
          "nermine.ghouibii@gmail.com",
          "Confirmation de réservation SafeRoad 🚗",
          "Votre réservation pour ${widget.parkingName} est confirmée.\n"
          "Prix : ${widget.pricePerHour} dt/heure\n"
          "Merci d’avoir choisi SafeRoad 💚",
        );
        print("✅ Fin de l’envoi d’e-mail.");

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HistoryScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur de réservation ❌')),
        );
      }
    } else {
      _animationController.forward().then((_) => _animationController.reverse());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Réserver une place - ${widget.parkingName}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: EdgeInsets.all(Styles.defaultPadding),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tarif : ${widget.pricePerHour.toStringAsFixed(2)} dt/heure',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 24),
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
                  label: 'Durée (en heures)',
                  hint: 'Ex: 2',
                  keyboardType: TextInputType.number,
                  onChanged: (val) => seats = int.tryParse(val) ?? 1,
                  icon: Icons.timer,
                  validator: (val) =>
                      (int.tryParse(val!) != null && int.parse(val) > 0)
                          ? null
                          : 'Entrez un nombre valide',
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: payment,
                  decoration: InputDecoration(
                    labelText: 'Méthode de paiement',
                    border: OutlineInputBorder(
                        borderRadius: Styles.defaultBorderRadius),
                    contentPadding: EdgeInsets.all(Styles.defaultPadding),
                  ),
                  items: ['cash', 'credit']
                      .map((p) => DropdownMenuItem(
                            value: p,
                            child: Text(
                                p == 'cash' ? 'Espèces' : 'Carte de crédit'),
                          ))
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
                    validator: (val) =>
                        val!.contains('/') && val.length == 5
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
                              Styles.defaultYellowColor
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
                        child: const Text(
                          'Confirmer',
                          textAlign: TextAlign.center,
                          style: TextStyle(
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
        prefixIcon:
            icon != null ? Icon(icon, color: Styles.defaultYellowColor) : null,
        border: OutlineInputBorder(borderRadius: Styles.defaultBorderRadius),
        contentPadding: EdgeInsets.all(Styles.defaultPadding),
        filled: true,
        fillColor: Styles.defaultLightGreyColor.withOpacity(0.5),
      ),
    );
  }
}

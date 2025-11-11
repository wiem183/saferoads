import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../models/user.dart' as models;
import '../models/user_statistics.dart';
import '../services/statistics_service.dart';
import '../styles/styles.dart';
import '../utils/validators.dart';
import 'dart:math' as math;
import 'calendar_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isEditing = false;
  bool _isDangerZoneExpanded = false;

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    final authController = Provider.of<AuthController>(context, listen: false);
    final user = authController.currentUser;

    _nameController = TextEditingController(text: user?.name ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      final authController = Provider.of<AuthController>(
        context,
        listen: false,
      );
      final currentUser = authController.currentUser;

      if (currentUser != null) {
        final updatedUser = models.User(
          id: currentUser.id,
          email: _emailController.text.trim(),
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          createdAt: currentUser.createdAt,
        );

        await authController.updateUser(updatedUser);

        if (mounted) {
          setState(() => _isEditing = false);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Profil mis à jour avec succès'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: Styles.defaultBorderRadius,
              ),
            ),
          );
        }
      }
    }
  }

  void _cancelEditing() {
    final authController = Provider.of<AuthController>(context, listen: false);
    final user = authController.currentUser;

    setState(() {
      _isEditing = false;
      _nameController.text = user?.name ?? '';
      _emailController.text = user?.email ?? '';
      _phoneController.text = user?.phone ?? '';
    });
  }

  Future<void> _showDeactivateDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Styles.defaultYellowColor,
                size: 28,
              ),
              const SizedBox(width: 8),
              const Text('Désactiver le compte'),
            ],
          ),
          content: const SingleChildScrollView(
            child: Text(
              'Êtes-vous sûr de vouloir désactiver votre compte?\n\n'
              '• Votre profil sera masqué\n'
              '• Vous serez déconnecté\n'
              '• Vous pourrez réactiver votre compte en vous reconnectant',
              style: TextStyle(fontSize: 16),
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: Styles.defaultBorderRadius,
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Annuler',
                style: TextStyle(
                  color: isDark
                      ? Styles.darkDefaultGreyColor
                      : Styles.defaultGreyColor,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _deactivateAccount();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Styles.defaultYellowColor,
                shape: RoundedRectangleBorder(
                  borderRadius: Styles.defaultBorderRadius,
                ),
              ),
              child: const Text(
                'Désactiver',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showDeleteDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.delete_forever,
                color: Styles.defaultRedColor,
                size: 28,
              ),
              const SizedBox(width: 8),
              const Text('Supprimer le compte'),
            ],
          ),
          content: const SingleChildScrollView(
            child: Text(
              'ATTENTION: Cette action est IRRÉVERSIBLE!\n\n'
              '• Toutes vos données seront supprimées définitivement\n'
              '• Vos trajets et réservations seront perdus\n'
              '• Vous ne pourrez pas récupérer votre compte\n\n'
              'Êtes-vous absolument sûr de vouloir continuer?',
              style: TextStyle(fontSize: 16),
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: Styles.defaultBorderRadius,
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Annuler',
                style: TextStyle(
                  color: isDark
                      ? Styles.darkDefaultGreyColor
                      : Styles.defaultGreyColor,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteAccount();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Styles.defaultRedColor,
                shape: RoundedRectangleBorder(
                  borderRadius: Styles.defaultBorderRadius,
                ),
              ),
              child: const Text(
                'Supprimer définitivement',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deactivateAccount() async {
    final authController = Provider.of<AuthController>(context, listen: false);

    final success = await authController.deactivateAccount();

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Compte désactivé avec succès'),
            backgroundColor: Styles.defaultYellowColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: Styles.defaultBorderRadius,
            ),
          ),
        );
        // Navigate to login screen
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              authController.errorMessage ?? 'Erreur lors de la désactivation',
            ),
            backgroundColor: Styles.defaultRedColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: Styles.defaultBorderRadius,
            ),
          ),
        );
      }
    }
  }

  Future<void> _deleteAccount() async {
    final authController = Provider.of<AuthController>(context, listen: false);

    final success = await authController.deleteAccount();

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Compte supprimé avec succès'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: Styles.defaultBorderRadius,
            ),
          ),
        );
        // Navigate to login screen
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              authController.errorMessage ?? 'Erreur lors de la suppression',
            ),
            backgroundColor: Styles.defaultRedColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: Styles.defaultBorderRadius,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthController>(context);
    final user = authController.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mon Profil'), centerTitle: true),
        body: const Center(child: Text('Aucun utilisateur connecté')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Mon Profil',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isDark
                ? Styles.darkDefaultLightWhiteColor
                : Styles.defaultRedColor,
          ),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(
          color: isDark ? Styles.darkDefaultBlueColor : Styles.defaultBlueColor,
        ),
        actions: [
          if (!_isEditing) ...[
            IconButton(
              icon: const Icon(Icons.calendar_today),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CalendarScreen()),
                );
              },
              tooltip: 'Calendrier',
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
              tooltip: 'Modifier',
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(Styles.defaultPadding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Profile Picture
              _buildProfilePicture(user, isDark),
              const SizedBox(height: 24),

              // User Info Card
              _buildInfoCard(user, isDark),
              const SizedBox(height: 24),

              // Editable Fields
              if (_isEditing) ...[
                _buildEditableSection(isDark),
                const SizedBox(height: 24),
                _buildActionButtons(isDark),
              ] else ...[
                _buildReadOnlySection(user, isDark),
              ],

              const SizedBox(height: 24),

              // Statistics Card
              _buildStatisticsCard(isDark),

              const SizedBox(height: 32),

              // Danger Zone
              if (!_isEditing) _buildDangerZone(isDark),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDangerZone(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Styles.darkDefaultLightGreyColor
            : Styles.defaultLightGreyColor,
        borderRadius: Styles.defaultBorderRadius,
        border: Border.all(
          color: Styles.defaultRedColor.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header - Clickable to expand/collapse
          InkWell(
            onTap: () {
              setState(() {
                _isDangerZoneExpanded = !_isDangerZoneExpanded;
              });
            },
            borderRadius: Styles.defaultBorderRadius,
            child: Padding(
              padding: EdgeInsets.all(Styles.defaultPadding),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Styles.defaultRedColor,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Zone de danger',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Styles.defaultRedColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Actions irréversibles concernant votre compte',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark
                                ? Styles.darkDefaultGreyColor
                                : Styles.defaultGreyColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _isDangerZoneExpanded
                        ? Icons.expand_less
                        : Icons.expand_more,
                    color: Styles.defaultRedColor,
                    size: 28,
                  ),
                ],
              ),
            ),
          ),
          // Expandable content
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: EdgeInsets.only(
                left: Styles.defaultPadding,
                right: Styles.defaultPadding,
                bottom: Styles.defaultPadding,
              ),
              child: Column(
                children: [
                  Divider(
                    color: Styles.defaultRedColor.withOpacity(0.2),
                    thickness: 1,
                  ),
                  const SizedBox(height: 12),
                  // Deactivate Account Button
                  _buildDangerButton(
                    icon: Icons.pause_circle_outline,
                    label: 'Désactiver le compte',
                    description: 'Masquer temporairement votre profil',
                    color: Styles.defaultYellowColor,
                    onPressed: _showDeactivateDialog,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  // Delete Account Button
                  _buildDangerButton(
                    icon: Icons.delete_forever,
                    label: 'Supprimer le compte',
                    description: 'Supprimer définitivement toutes vos données',
                    color: Styles.defaultRedColor,
                    onPressed: _showDeleteDialog,
                    isDark: isDark,
                  ),
                ],
              ),
            ),
            crossFadeState: _isDangerZoneExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }

  Widget _buildDangerButton({
    required IconData icon,
    required String label,
    required String description,
    required Color color,
    required VoidCallback onPressed,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: Styles.defaultBorderRadius,
      child: Container(
        padding: EdgeInsets.all(Styles.defaultPadding),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: Styles.defaultBorderRadius,
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? Styles.darkDefaultGreyColor
                          : Styles.defaultGreyColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: color),
          ],
        ),
      ),
    );
  }

  Widget _buildProfilePicture(models.User user, bool isDark) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 60,
            backgroundColor: isDark
                ? Styles.darkDefaultBlueColor
                : Styles.defaultBlueColor,
            child: Text(
              user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        if (_isEditing)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark
                    ? Styles.darkDefaultYellowColor
                    : Styles.defaultYellowColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
              ),
              child: const Icon(
                Icons.camera_alt,
                size: 20,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInfoCard(models.User user, bool isDark) {
    return Container(
      padding: EdgeInsets.all(Styles.defaultPadding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  Styles.darkDefaultBlueColor,
                  Styles.darkDefaultBlueColor.withOpacity(0.7),
                ]
              : [
                  Styles.defaultBlueColor,
                  Styles.defaultBlueColor.withOpacity(0.7),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: Styles.defaultBorderRadius,
      ),
      child: Column(
        children: [
          Text(
            user.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.calendar_today, size: 16, color: Colors.white70),
              const SizedBox(width: 4),
              Text(
                'Membre depuis ${_formatDate(user.createdAt)}',
                style: const TextStyle(fontSize: 14, color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEditableSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Informations personnelles', isDark),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _nameController,
          label: 'Nom complet',
          icon: Icons.person,
          isDark: isDark,
          validator: Validators.validateName,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _emailController,
          label: 'Email',
          icon: Icons.email,
          isDark: isDark,
          keyboardType: TextInputType.emailAddress,
          validator: Validators.validateEmail,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _phoneController,
          label: 'Téléphone',
          icon: Icons.phone,
          isDark: isDark,
          keyboardType: TextInputType.phone,
          validator: Validators.validatePhone,
        ),
      ],
    );
  }

  Widget _buildReadOnlySection(models.User user, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Informations personnelles', isDark),
        const SizedBox(height: 16),
        _buildInfoRow(
          icon: Icons.person,
          label: 'Nom complet',
          value: user.name,
          isDark: isDark,
        ),
        const SizedBox(height: 16),
        _buildInfoRow(
          icon: Icons.email,
          label: 'Email',
          value: user.email,
          isDark: isDark,
        ),
        const SizedBox(height: 16),
        _buildInfoRow(
          icon: Icons.phone,
          label: 'Téléphone',
          value: user.phone,
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: isDark
            ? Styles.darkDefaultLightWhiteColor
            : Styles.defaultRedColor,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Styles.darkDefaultLightGreyColor
            : Styles.defaultLightGreyColor,
        borderRadius: Styles.defaultBorderRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        style: TextStyle(
          fontSize: 16,
          color: isDark
              ? Styles.darkDefaultLightWhiteColor
              : Styles.defaultRedColor,
        ),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(
            icon,
            color: isDark
                ? Styles.darkDefaultYellowColor
                : Styles.defaultYellowColor,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(Styles.defaultPadding),
          labelStyle: TextStyle(
            color: isDark
                ? Styles.darkDefaultGreyColor
                : Styles.defaultGreyColor,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Container(
      padding: EdgeInsets.all(Styles.defaultPadding),
      decoration: BoxDecoration(
        color: isDark
            ? Styles.darkDefaultLightGreyColor
            : Styles.defaultLightGreyColor,
        borderRadius: Styles.defaultBorderRadius,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark
                  ? Styles.darkDefaultYellowColor.withOpacity(0.1)
                  : Styles.defaultYellowColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: isDark
                  ? Styles.darkDefaultYellowColor
                  : Styles.defaultYellowColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? Styles.darkDefaultGreyColor
                        : Styles.defaultGreyColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? Styles.darkDefaultLightWhiteColor
                        : Styles.defaultRedColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _cancelEditing,
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: isDark
                    ? Styles.darkDefaultGreyColor
                    : Styles.defaultGreyColor,
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: Styles.defaultBorderRadius,
              ),
            ),
            child: Text(
              'Annuler',
              style: TextStyle(
                fontSize: 16,
                color: isDark
                    ? Styles.darkDefaultGreyColor
                    : Styles.defaultGreyColor,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _saveChanges,
            style: ElevatedButton.styleFrom(
              backgroundColor: Styles.defaultBlueColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: Styles.defaultBorderRadius,
              ),
            ),
            child: const Text(
              'Enregistrer',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticsCard(bool isDark) {
    final authController = Provider.of<AuthController>(context, listen: false);
    final userPhone = authController.currentUser?.phone ?? '';
    final statisticsService = StatisticsService();

    return Container(
      padding: EdgeInsets.all(Styles.defaultPadding),
      decoration: BoxDecoration(
        color: isDark
            ? Styles.darkDefaultLightGreyColor
            : Styles.defaultLightGreyColor,
        borderRadius: Styles.defaultBorderRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: FutureBuilder<UserStatistics>(
        future: statisticsService.calculateUserStatistics(userPhone),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: CircularProgressIndicator(),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Erreur de chargement des statistiques',
                style: TextStyle(color: Colors.red),
              ),
            );
          }

          final stats = snapshot.data ?? UserStatistics();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Statistiques Analytiques',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? Styles.darkDefaultLightWhiteColor
                          : Styles.defaultRedColor,
                    ),
                  ),
                  Icon(
                    Icons.analytics_outlined,
                    color: Styles.defaultBlueColor,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Statistiques Conducteur
              if (stats.totalTripsPublished > 0) ...[
                _buildSectionHeader('En tant que Conducteur', isDark),
                const SizedBox(height: 12),
                _buildAnalyticalStatRow(
                  icon: Icons.directions_car,
                  label: 'Trajets publiés',
                  value: '${stats.totalTripsPublished}',
                  subtitle:
                      '${stats.completedTrips} terminés • ${stats.upcomingTrips} à venir',
                  color: Colors.blue,
                  isDark: isDark,
                ),
                const SizedBox(height: 8),
                _buildAnalyticalStatRow(
                  icon: Icons.attach_money,
                  label: 'Revenu total',
                  value: '${stats.totalRevenue.toStringAsFixed(2)} DT',
                  subtitle:
                      'Moyenne: ${stats.averagePricePerSeat.toStringAsFixed(2)} DT/siège',
                  color: Colors.green,
                  isDark: isDark,
                ),
                const SizedBox(height: 8),
                _buildPercentageStatRow(
                  icon: Icons.people,
                  label: 'Taux d\'occupation',
                  percentage: stats.averageOccupancyRate,
                  subtitle:
                      '${stats.totalSeatsBooked}/${stats.totalSeatsOffered} sièges réservés',
                  color: Colors.orange,
                  isDark: isDark,
                ),
                if (stats.totalDistanceKm > 0) ...[
                  const SizedBox(height: 8),
                  _buildAnalyticalStatRow(
                    icon: Icons.route,
                    label: 'Distance parcourue',
                    value: '${stats.totalDistanceKm.toStringAsFixed(0)} km',
                    subtitle: 'Total cumulé de vos trajets',
                    color: Colors.purple,
                    isDark: isDark,
                  ),
                ],
                const SizedBox(height: 16),
              ],

              // Statistiques Passager
              if (stats.totalReservationsMade > 0) ...[
                _buildSectionHeader('En tant que Passager', isDark),
                const SizedBox(height: 12),
                _buildAnalyticalStatRow(
                  icon: Icons.confirmation_number,
                  label: 'Réservations',
                  value: '${stats.totalReservationsMade}',
                  subtitle: '${stats.totalSeatsReserved} sièges au total',
                  color: Colors.teal,
                  isDark: isDark,
                ),
                const SizedBox(height: 8),
                _buildAnalyticalStatRow(
                  icon: Icons.payments,
                  label: 'Dépenses',
                  value: '${stats.totalMoneySpent.toStringAsFixed(2)} DT',
                  subtitle:
                      'Moyenne: ${stats.averagePricePerReservation.toStringAsFixed(2)} DT/siège',
                  color: Colors.red,
                  isDark: isDark,
                ),
                const SizedBox(height: 8),
                _buildAnalyticalStatRow(
                  icon: Icons.savings,
                  label: 'Économies réalisées',
                  value: '${stats.totalMoneySaved.toStringAsFixed(2)} DT',
                  subtitle:
                      '${stats.averageSavingsPerTrip.toStringAsFixed(2)} DT/trajet en moyenne',
                  color: Colors.greenAccent[700]!,
                  isDark: isDark,
                ),
                const SizedBox(height: 8),
                _buildAnalyticalStatRow(
                  icon: Icons.eco,
                  label: 'CO₂ économisé',
                  value: '${stats.co2SavedKg.toStringAsFixed(1)} kg',
                  subtitle: 'Impact environnemental positif',
                  color: Colors.lightGreen,
                  isDark: isDark,
                ),
              ],

              // Message si aucune activité
              if (stats.totalTripsPublished == 0 &&
                  stats.totalReservationsMade == 0) ...[
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.analytics_outlined,
                          size: 48,
                          color: isDark
                              ? Styles.darkDefaultGreyColor
                              : Styles.defaultGreyColor,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Aucune activité encore',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? Styles.darkDefaultGreyColor
                                : Styles.defaultGreyColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Publiez un trajet ou réservez une place\npour voir vos statistiques',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark
                                ? Styles.darkDefaultGreyColor
                                : Styles.defaultGreyColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: Styles.defaultBlueColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark
                ? Styles.darkDefaultLightWhiteColor
                : Styles.defaultRedColor,
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyticalStatRow({
    required IconData icon,
    required String label,
    required String value,
    required String subtitle,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? Styles.darkDefaultLightWhiteColor
                        : Styles.defaultRedColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? Styles.darkDefaultGreyColor
                        : Styles.defaultGreyColor,
                  ),
                ),
              ],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPercentageStatRow({
    required IconData icon,
    required String label,
    required double percentage,
    required String subtitle,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? Styles.darkDefaultLightWhiteColor
                            : Styles.defaultRedColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? Styles.darkDefaultGreyColor
                            : Styles.defaultGreyColor,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Barre de progression
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: math.min(percentage / 100, 1.0),
              backgroundColor: isDark
                  ? Styles.darkDefaultGreyColor.withOpacity(0.3)
                  : Styles.defaultGreyColor.withOpacity(0.3),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays < 30) {
      return '${difference.inDays} jours';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months mois';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${years > 1 ? "ans" : "an"}';
    }
  }
}

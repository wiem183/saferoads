import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../models/user.dart' as models;
import '../styles/styles.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isEditing = false;

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
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
              tooltip: 'Modifier',
            ),
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

              const SizedBox(height: 20),
            ],
          ),
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
          validator: (val) => val!.isEmpty ? 'Entrez votre nom' : null,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _emailController,
          label: 'Email',
          icon: Icons.email,
          isDark: isDark,
          keyboardType: TextInputType.emailAddress,
          validator: (val) {
            if (val!.isEmpty) return 'Entrez votre email';
            if (!val.contains('@')) return 'Email invalide';
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _phoneController,
          label: 'Téléphone',
          icon: Icons.phone,
          isDark: isDark,
          keyboardType: TextInputType.phone,
          validator: (val) {
            if (val!.isEmpty) return 'Entrez votre numéro';
            if (val.length != 8 || int.tryParse(val) == null) {
              return 'Numéro invalide (8 chiffres)';
            }
            return null;
          },
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statistiques',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark
                  ? Styles.darkDefaultLightWhiteColor
                  : Styles.defaultRedColor,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.directions_car,
                  label: 'Trajets publiés',
                  value: '0',
                  color: Colors.blue,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.history,
                  label: 'Réservations',
                  value: '0',
                  color: Colors.green,
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: Styles.defaultBorderRadius,
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: isDark
                  ? Styles.darkDefaultGreyColor
                  : Styles.defaultGreyColor,
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

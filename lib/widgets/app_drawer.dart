import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../styles/styles.dart';
import '../screens/login_screen.dart';
import '../screens/help_support_screen.dart';
import '../screens/search_screen.dart';
import '../screens/history_screen.dart';
import '../screens/my_rides_screen.dart';

class AppDrawer extends StatelessWidget {
  final Function(int)? onPageChanged;

  const AppDrawer({super.key, this.onPageChanged});

  void _navigateToPage(BuildContext context, int pageIndex) {
    if (onPageChanged != null) {
      onPageChanged!(pageIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthController>(context);
    final user = authController.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: Column(
          children: [
            // Header with user info
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(Styles.defaultPadding * 1.5),
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
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person,
                      size: 50,
                      color: isDark
                          ? Styles.darkDefaultBlueColor
                          : Styles.defaultBlueColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // User name
                  Text(
                    user?.name ?? 'Utilisateur',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // User email
                  Text(
                    user?.email ?? '',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // User phone
                  Row(
                    children: [
                      Icon(
                        Icons.phone,
                        size: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        user?.phone ?? '',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Menu items
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(vertical: Styles.defaultPadding),
                children: [
                  _buildDrawerItem(
                    context,
                    icon: Icons.add_circle_outline,
                    title: 'Publier un trajet',
                    onTap: () {
                      Navigator.pop(context);
                      _navigateToPage(context, 0);
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.person_outline,
                    title: 'Mon Profil',
                    onTap: () {
                      Navigator.pop(context);
                      _navigateToPage(context, 1);
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.search,
                    title: 'Rechercher un trajet',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SearchScreen()),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.history,
                    title: 'Historique',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const HistoryScreen(),
                        ),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.directions_car,
                    title: 'Mes Trajets',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MyRidesScreen(),
                        ),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.settings,
                    title: 'Paramètres',
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Paramètres - À venir'),
                          backgroundColor: isDark
                              ? Styles.darkDefaultYellowColor
                              : Styles.defaultYellowColor,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.help_outline,
                    title: 'Aide & Support',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const HelpSupportScreen(),
                        ),
                      );
                    },
                  ),
                  Divider(
                    height: 32,
                    thickness: 1,
                    indent: Styles.defaultPadding,
                    endIndent: Styles.defaultPadding,
                    color: isDark
                        ? Styles.darkDefaultGreyColor
                        : Styles.defaultGreyColor.withOpacity(0.3),
                  ),
                  // Logout button
                  _buildDrawerItem(
                    context,
                    icon: Icons.logout,
                    title: 'Déconnexion',
                    iconColor: Colors.red,
                    textColor: Colors.red,
                    onTap: () async {
                      // Show confirmation dialog
                      final shouldLogout = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: Theme.of(
                            context,
                          ).scaffoldBackgroundColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: Styles.defaultBorderRadius,
                          ),
                          title: Text(
                            'Déconnexion',
                            style: TextStyle(
                              color: isDark
                                  ? Styles.darkDefaultLightWhiteColor
                                  : Styles.defaultRedColor,
                            ),
                          ),
                          content: Text(
                            'Êtes-vous sûr de vouloir vous déconnecter?',
                            style: TextStyle(
                              color: isDark
                                  ? Styles.darkDefaultGreyColor
                                  : Styles.defaultGreyColor,
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
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
                              onPressed: () => Navigator.pop(context, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                              child: const Text(
                                'Déconnexion',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      );

                      if (shouldLogout == true && context.mounted) {
                        await authController.signOut();
                        if (context.mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (_) => const LoginScreen(),
                            ),
                            (route) => false,
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
            // App version
            Padding(
              padding: EdgeInsets.all(Styles.defaultPadding),
              child: Text(
                'Version 1.0.0',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? Styles.darkDefaultGreyColor
                      : Styles.defaultGreyColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      leading: Icon(
        icon,
        color:
            iconColor ??
            (isDark
                ? Styles.darkDefaultYellowColor
                : Styles.defaultYellowColor),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color:
              textColor ??
              (isDark
                  ? Styles.darkDefaultLightWhiteColor
                  : Styles.defaultRedColor),
        ),
      ),
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(
        horizontal: Styles.defaultPadding * 1.5,
        vertical: 4,
      ),
    );
  }
}

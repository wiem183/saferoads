import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../styles/styles.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Données pour la recherche
  final List<Map<String, dynamic>> _features = [
    {
      'icon': Icons.warning_amber,
      'title': 'Signalement en temps réel',
      'description':
          'Signalez les dangers routiers : accidents, routes endommagées, obstacles, et aidez à sécuriser les routes.',
      'color': Colors.orange,
    },
    {
      'icon': Icons.cloud,
      'title': 'Alertes météorologiques',
      'description':
          'Recevez des alertes sur les conditions météorologiques et les informations de circulation en temps réel.',
      'color': Colors.blue,
    },
    {
      'icon': Icons.receipt_long,
      'title': 'Suivi des amendes',
      'description':
          'Consultez votre historique d\'amendes, vos points de permis et effectuez des paiements en ligne.',
      'color': Colors.red,
    },
    {
      'icon': Icons.bar_chart,
      'title': 'Statistiques administratives',
      'description':
          'Outil d\'analyse des zones accidentogènes pour améliorer la sécurité routière.',
      'color': Colors.purple,
    },
    {
      'icon': Icons.directions_car,
      'title': 'Covoiturage',
      'description':
          'Partagez vos trajets, économisez et contribuez à réduire l\'empreinte carbone.',
      'color': Colors.green,
    },
  ];

  final List<Map<String, String>> _faqs = [
    {
      'question': 'Comment signaler un danger ?',
      'answer':
          'Utilisez la fonctionnalité de signalement en temps réel disponible sur la page principale. Sélectionnez le type de danger et sa localisation.',
    },
    {
      'question': 'Comment publier un trajet de covoiturage ?',
      'answer':
          'Accédez à l\'onglet "Publier", renseignez les détails de votre trajet (origine, destination, date, prix) et validez.',
    },
    {
      'question': 'Mes données sont-elles sécurisées ?',
      'answer':
          'Oui, toutes vos données sont cryptées et stockées de manière sécurisée. Nous respectons la confidentialité de vos informations.',
    },
    {
      'question': 'Comment consulter mes points de permis ?',
      'answer':
          'Rendez-vous dans la section "Suivi des amendes" pour consulter vos points de permis et votre historique.',
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matchesSearch(String text) {
    if (_searchQuery.isEmpty) return true;
    return text.toLowerCase().contains(_searchQuery.toLowerCase());
  }

  List<Map<String, dynamic>> get _filteredFeatures {
    return _features
        .where(
          (feature) =>
              _matchesSearch(feature['title']) ||
              _matchesSearch(feature['description']),
        )
        .toList();
  }

  List<Map<String, String>> get _filteredFAQs {
    return _faqs
        .where(
          (faq) =>
              _matchesSearch(faq['question']!) ||
              _matchesSearch(faq['answer']!),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Aide & Support',
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
      ),
      body: Column(
        children: [
          // Barre de recherche
          _buildSearchBar(isDark),
          // Contenu défilable
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(Styles.defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App Description
                  if (_searchQuery.isEmpty) ...[
                    _buildHeaderCard(context, isDark),
                    const SizedBox(height: 24),
                  ],

                  // Features Section
                  if (_filteredFeatures.isNotEmpty) ...[
                    _buildSectionTitle('Fonctionnalités principales', isDark),
                    const SizedBox(height: 12),
                    ..._filteredFeatures.map((feature) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildFeatureCard(
                          context,
                          isDark,
                          icon: feature['icon'],
                          title: feature['title'],
                          description: feature['description'],
                          color: feature['color'],
                        ),
                      );
                    }),
                    const SizedBox(height: 24),
                  ],

                  // FAQ Section
                  if (_filteredFAQs.isNotEmpty) ...[
                    _buildSectionTitle('Questions fréquentes', isDark),
                    const SizedBox(height: 12),
                    ..._filteredFAQs.map((faq) {
                      return _buildFAQItem(
                        context,
                        isDark,
                        question: faq['question']!,
                        answer: faq['answer']!,
                      );
                    }),
                    const SizedBox(height: 24),
                  ],

                  // Message si aucun résultat
                  if (_searchQuery.isNotEmpty &&
                      _filteredFeatures.isEmpty &&
                      _filteredFAQs.isEmpty) ...[
                    _buildNoResults(isDark),
                    const SizedBox(height: 24),
                  ],

                  // Contact Section (toujours visible)
                  if (_searchQuery.isEmpty) ...[
                    _buildSectionTitle('Contactez-nous', isDark),
                    const SizedBox(height: 12),
                    _buildContactCard(
                      context,
                      isDark,
                      icon: Icons.email,
                      title: 'Email',
                      subtitle: 'support@saferoad.tn',
                      onTap: () => _launchEmail('support@saferoad.tn'),
                    ),
                    const SizedBox(height: 12),
                    _buildContactCard(
                      context,
                      isDark,
                      icon: Icons.phone,
                      title: 'Téléphone',
                      subtitle: '+216 71 000 000',
                      onTap: () => _launchPhone('+21671000000'),
                    ),
                    const SizedBox(height: 12),
                    _buildContactCard(
                      context,
                      isDark,
                      icon: Icons.language,
                      title: 'Site Web',
                      subtitle: 'www.saferoad.tn',
                      onTap: () => _launchWebsite('https://www.saferoad.tn'),
                    ),
                    const SizedBox(height: 12),
                    _buildContactCard(
                      context,
                      isDark,
                      icon: Icons.facebook,
                      title: 'Facebook',
                      subtitle: '@SafeRoadTunisie',
                      onTap: () => _launchWebsite(
                        'https://www.facebook.com/SafeRoadTunisie',
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Emergency Numbers
                    _buildSectionTitle('Numéros d\'urgence', isDark),
                    const SizedBox(height: 12),
                    _buildEmergencyCard(
                      context,
                      isDark,
                      '197',
                      'Police Nationale',
                    ),
                    const SizedBox(height: 8),
                    _buildEmergencyCard(
                      context,
                      isDark,
                      '198',
                      'Protection Civile',
                    ),
                    const SizedBox(height: 8),
                    _buildEmergencyCard(
                      context,
                      isDark,
                      '190',
                      'Urgences SAMU',
                    ),
                    const SizedBox(height: 32),

                    // Version Info
                    Center(
                      child: Text(
                        'SafeRoad v1.0.0\nApplication citoyenne de sécurité routière',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? Styles.darkDefaultGreyColor
                              : Styles.defaultGreyColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return Container(
      padding: EdgeInsets.all(Styles.defaultPadding),
      decoration: BoxDecoration(
        color: isDark
            ? Styles.darkDefaultLightGreyColor
            : Styles.defaultLightGreyColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        decoration: InputDecoration(
          hintText: 'Rechercher dans l\'aide...',
          hintStyle: TextStyle(
            color: isDark
                ? Styles.darkDefaultGreyColor
                : Styles.defaultGreyColor,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: isDark
                ? Styles.darkDefaultBlueColor
                : Styles.defaultBlueColor,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: isDark
                        ? Styles.darkDefaultGreyColor
                        : Styles.defaultGreyColor,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          filled: true,
          fillColor: isDark
              ? Styles.darkDefaultLightGreyColor.withOpacity(0.5)
              : Colors.white,
          border: OutlineInputBorder(
            borderRadius: Styles.defaultBorderRadius,
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 12,
            horizontal: 16,
          ),
        ),
        style: TextStyle(
          color: isDark
              ? Styles.darkDefaultLightWhiteColor
              : Styles.defaultRedColor,
        ),
      ),
    );
  }

  Widget _buildNoResults(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: isDark
                ? Styles.darkDefaultGreyColor.withOpacity(0.5)
                : Styles.defaultGreyColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun résultat trouvé',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark
                  ? Styles.darkDefaultLightWhiteColor
                  : Styles.defaultRedColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Essayez avec d\'autres mots-clés',
            style: TextStyle(
              fontSize: 14,
              color: isDark
                  ? Styles.darkDefaultGreyColor
                  : Styles.defaultGreyColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context, bool isDark) {
    return Container(
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
        borderRadius: Styles.defaultBorderRadius,
      ),
      child: Column(
        children: [
          Icon(Icons.shield_outlined, size: 60, color: Colors.white),
          const SizedBox(height: 16),
          const Text(
            'SafeRoad',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Application citoyenne dédiée à la sécurité routière et à l\'amélioration de la fluidité du trafic en Tunisie',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.white, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: isDark
            ? Styles.darkDefaultLightWhiteColor
            : Styles.defaultRedColor,
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context,
    bool isDark, {
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? Styles.darkDefaultGreyColor
                        : Styles.defaultGreyColor,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem(
    BuildContext context,
    bool isDark, {
    required String question,
    required String answer,
  }) {
    return ExpansionTile(
      tilePadding: EdgeInsets.symmetric(horizontal: Styles.defaultPadding),
      backgroundColor: isDark
          ? Styles.darkDefaultLightGreyColor
          : Styles.defaultLightGreyColor,
      collapsedBackgroundColor: isDark
          ? Styles.darkDefaultLightGreyColor
          : Styles.defaultLightGreyColor,
      shape: RoundedRectangleBorder(borderRadius: Styles.defaultBorderRadius),
      collapsedShape: RoundedRectangleBorder(
        borderRadius: Styles.defaultBorderRadius,
      ),
      title: Text(
        question,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: isDark
              ? Styles.darkDefaultLightWhiteColor
              : Styles.defaultRedColor,
        ),
      ),
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            Styles.defaultPadding,
            0,
            Styles.defaultPadding,
            Styles.defaultPadding,
          ),
          child: Text(
            answer,
            style: TextStyle(
              fontSize: 14,
              color: isDark
                  ? Styles.darkDefaultGreyColor
                  : Styles.defaultGreyColor,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContactCard(
    BuildContext context,
    bool isDark, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: Styles.defaultBorderRadius,
      child: Container(
        padding: EdgeInsets.all(Styles.defaultPadding),
        decoration: BoxDecoration(
          color: isDark
              ? Styles.darkDefaultLightGreyColor
              : Styles.defaultLightGreyColor,
          borderRadius: Styles.defaultBorderRadius,
          border: Border.all(
            color: isDark
                ? Styles.darkDefaultBlueColor.withOpacity(0.3)
                : Styles.defaultBlueColor.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark
                    ? Styles.darkDefaultBlueColor.withOpacity(0.1)
                    : Styles.defaultBlueColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isDark
                    ? Styles.darkDefaultBlueColor
                    : Styles.defaultBlueColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? Styles.darkDefaultGreyColor
                          : Styles.defaultGreyColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
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
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: isDark
                  ? Styles.darkDefaultGreyColor
                  : Styles.defaultGreyColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyCard(
    BuildContext context,
    bool isDark,
    String number,
    String label,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Styles.defaultPadding,
        vertical: Styles.defaultPadding * 0.75,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.red.withOpacity(0.1)
            : Colors.red.withOpacity(0.05),
        borderRadius: Styles.defaultBorderRadius,
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.phone, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  number,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                Text(
                  label,
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
          IconButton(
            onPressed: () => _launchPhone(number),
            icon: const Icon(Icons.call, color: Colors.red),
          ),
        ],
      ),
    );
  }

  Future<void> _launchEmail(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=Support SafeRoad',
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  Future<void> _launchPhone(String phone) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  Future<void> _launchWebsite(String url) async {
    final Uri webUri = Uri.parse(url);
    if (await canLaunchUrl(webUri)) {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    }
  }
}

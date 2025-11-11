import 'package:covoiturage_app/models/announcement.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/announcement_controller.dart';
import '../widgets/announcement_card.dart';
import '../styles/styles.dart';
import 'map_screen.dart';
import 'announcement_details_screen.dart';
import 'driver_edit_screen.dart';

class AnnouncementListScreen extends StatelessWidget {
  final bool isPassenger;
  final String origin;
  final String destination;
  final DateTime departureDateTime;
  final int seats;

  const AnnouncementListScreen({
    super.key,
    required this.isPassenger,
    required this.origin,
    required this.destination,
    required this.departureDateTime,
    required this.seats,
  });

  @override
  Widget build(BuildContext context) {
    final controller = context.read<AnnouncementController>();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 150.0,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                isPassenger ? 'Annonces disponibles' : 'Mes annonces',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Styles.darkDefaultLightWhiteColor
                      : Styles.defaultRedColor,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).brightness == Brightness.dark
                          ? Styles.darkDefaultBlueColor
                          : Styles.defaultBlueColor,
                      Theme.of(context).brightness == Brightness.dark
                          ? Styles.darkDefaultYellowColor
                          : Styles.defaultYellowColor,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  Icons.map,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Styles.darkDefaultLightWhiteColor
                      : Colors.white,
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MapScreen()),
                ),
              ),
            ],
          ),
          StreamBuilder<List<Announcement>>(
            stream: controller.announcementsStream,
            builder: (context, snap) {
              if (snap.hasError) {
                return SliverToBoxAdapter(
                  child: Center(child: Text('Erreur: ${snap.error}')),
                );
              }
              if (!snap.hasData) {
                return const SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              List<Announcement> list = snap.data!;

              // CORRECTION : Gestion des valeurs nulles
              if (origin.isNotEmpty) {
                list = list
                    .where(
                      (a) =>
                          a.origin != null &&
                          a.origin.toLowerCase().contains(origin.toLowerCase()),
                    )
                    .toList();
              }
              if (destination.isNotEmpty) {
                list = list
                    .where(
                      (a) =>
                          a.destination != null &&
                          a.destination.toLowerCase().contains(
                            destination.toLowerCase(),
                          ),
                    )
                    .toList();
              }
              list = list.where((a) => a.availableSeats >= seats).toList();

              if (list.isEmpty) {
                return SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(Styles.defaultPadding),
                      child: Text(
                        'Aucune annonce disponible',
                        style: TextStyle(
                          fontSize: 18,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Styles.darkDefaultGreyColor
                              : Styles.defaultGreyColor,
                        ),
                      ),
                    ),
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final ann = list[index];
                  return InkWell(
                    onTap: () => Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (_, __, ___) => isPassenger
                            ? AnnouncementDetailsScreen(announcement: ann)
                            : DriverEditScreen(announcement: ann),
                        transitionsBuilder: (_, animation, __, child) =>
                            FadeTransition(opacity: animation, child: child),
                      ),
                    ),
                    splashColor: Styles.defaultBlueColor.withOpacity(0.2),
                    borderRadius: Styles.defaultBorderRadius,
                    child: Hero(
                      tag: ann.id,
                      child: AnnouncementCard(announcement: ann),
                    ),
                  );
                }, childCount: list.length),
              );
            },
          ),
        ],
      ),
      floatingActionButton: isPassenger
          ? null
          : FloatingActionButton(
              onPressed: () => Navigator.pushNamed(context, '/driver_create'),
              backgroundColor: Styles.defaultBlueColor,
              tooltip: 'Ajouter un trajet',
              child: const Icon(Icons.add, color: Colors.white),
            ),
    );
  }
}

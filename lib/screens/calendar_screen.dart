import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../styles/styles.dart';
import '../controllers/auth_controller.dart';
import '../models/announcement.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Announcement>> _announcementEvents = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadAnnouncements();
  }

  Future<void> _loadAnnouncements() async {
    final authController = Provider.of<AuthController>(context, listen: false);
    final userPhone = authController.currentUser?.phone ?? '';

    if (userPhone.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      // Récupérer toutes vos annonces
      final announcementsSnapshot = await _db
          .collection('announcements')
          .where('driverPhone', isEqualTo: userPhone)
          .get();

      Map<DateTime, List<Announcement>> events = {};

      for (var announcementDoc in announcementsSnapshot.docs) {
        final announcementData = announcementDoc.data();
        final announcement = Announcement.fromJson(announcementData);

        // Extraire juste la date (sans l'heure)
        final date = DateTime(
          announcement.departureDateTime.year,
          announcement.departureDateTime.month,
          announcement.departureDateTime.day,
        );

        if (!events.containsKey(date)) {
          events[date] = [];
        }

        events[date]!.add(announcement);
      }

      setState(() {
        _announcementEvents = events;
        _isLoading = false;
      });
    } catch (e) {
      print('Erreur de chargement des annonces: $e');
      setState(() => _isLoading = false);
    }
  }

  List<Announcement> _getEventsForDay(DateTime day) {
    final date = DateTime(day.year, day.month, day.day);
    return _announcementEvents[date] ?? [];
  }

  // Obtenir la couleur d'alarme selon la proximité du trajet
  Color _getAlarmColor(DateTime departureDateTime) {
    final now = DateTime.now();
    final difference = departureDateTime.difference(now);

    if (difference.isNegative) {
      return Colors.grey; // Passé
    } else if (difference.inHours < 24) {
      return Colors.red; // Moins de 24h (URGENT)
    } else if (difference.inDays < 7) {
      return Colors.orange; // 1-7 jours (Bientôt)
    } else {
      return Colors.green; // Plus de 7 jours (OK)
    }
  }

  // Obtenir le label de proximité
  String _getProximityLabel(DateTime departureDateTime) {
    final now = DateTime.now();
    final difference = departureDateTime.difference(now);

    if (difference.isNegative) {
      return 'Terminé';
    } else if (difference.inHours < 1) {
      return 'IMMINENT !';
    } else if (difference.inHours < 24) {
      return 'Aujourd\'hui (${difference.inHours}h)';
    } else if (difference.inDays == 1) {
      return 'Demain';
    } else if (difference.inDays < 7) {
      return 'Dans ${difference.inDays} jours';
    } else {
      return 'Dans ${(difference.inDays / 7).floor()} semaines';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Mes Trajets Publiés',
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Calendrier
                Container(
                  margin: EdgeInsets.all(Styles.defaultPadding),
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
                  child: TableCalendar(
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _focusedDay,
                    calendarFormat: _calendarFormat,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    eventLoader: _getEventsForDay,
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                    },
                    onFormatChanged: (format) {
                      setState(() {
                        _calendarFormat = format;
                      });
                    },
                    onPageChanged: (focusedDay) {
                      _focusedDay = focusedDay;
                    },
                    calendarStyle: CalendarStyle(
                      todayDecoration: BoxDecoration(
                        color: Styles.defaultYellowColor.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: BoxDecoration(
                        color: isDark
                            ? Styles.darkDefaultBlueColor
                            : Styles.defaultBlueColor,
                        shape: BoxShape.circle,
                      ),
                      markersMaxCount: 3,
                      outsideDaysVisible: false,
                    ),
                    headerStyle: HeaderStyle(
                      titleCentered: true,
                      formatButtonVisible: true,
                      formatButtonShowsNext: false,
                      titleTextStyle: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? Styles.darkDefaultLightWhiteColor
                            : Styles.defaultRedColor,
                      ),
                    ),
                    // Marqueurs colorés selon la proximité
                    calendarBuilders: CalendarBuilders(
                      markerBuilder: (context, day, events) {
                        if (events.isEmpty) return null;

                        // Trouver le trajet le plus proche de ce jour
                        final announcements = events.cast<Announcement>();
                        final closestAnnouncement = announcements.reduce(
                          (a, b) =>
                              a.departureDateTime.isBefore(b.departureDateTime)
                              ? a
                              : b,
                        );

                        final alarmColor = _getAlarmColor(
                          closestAnnouncement.departureDateTime,
                        );

                        return Positioned(
                          bottom: 1,
                          child: Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: alarmColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: alarmColor.withOpacity(0.5),
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // Légende des couleurs
                _buildColorLegend(isDark),

                // Liste des trajets pour le jour sélectionné
                Expanded(child: _buildAnnouncementsList(isDark)),
              ],
            ),
    );
  }

  Widget _buildColorLegend(bool isDark) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: Styles.defaultPadding,
        vertical: 8,
      ),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? Styles.darkDefaultLightGreyColor.withOpacity(0.5)
            : Styles.defaultLightGreyColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Styles.darkDefaultGreyColor.withOpacity(0.3)
              : Styles.defaultGreyColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildLegendItem(Colors.red, '< 24h', 'Urgent'),
          _buildLegendItem(Colors.orange, '1-7j', 'Bientôt'),
          _buildLegendItem(Colors.green, '> 7j', 'OK'),
          _buildLegendItem(Colors.grey, 'Passé', 'Terminé'),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String duration, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              duration,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 9, color: Colors.grey),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAnnouncementsList(bool isDark) {
    final events = _selectedDay != null ? _getEventsForDay(_selectedDay!) : [];

    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              size: 80,
              color: isDark
                  ? Styles.darkDefaultGreyColor.withOpacity(0.5)
                  : Styles.defaultGreyColor.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun trajet',
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
              'Pas de trajet publié pour ce jour',
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

    return ListView.builder(
      padding: EdgeInsets.all(Styles.defaultPadding),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final announcement = events[index];
        return _buildAnnouncementCard(announcement, isDark);
      },
    );
  }

  Widget _buildAnnouncementCard(Announcement announcement, bool isDark) {
    final isPast = announcement.departureDateTime.isBefore(DateTime.now());
    final totalSeatsReserved = announcement.reservations.fold<int>(
      0,
      (sum, r) => sum + r.seatsReserved,
    );

    // Obtenir la couleur et le label d'alarme
    final alarmColor = _getAlarmColor(announcement.departureDateTime);
    final proximityLabel = _getProximityLabel(announcement.departureDateTime);

    // Icône selon la proximité
    IconData alarmIcon;
    if (isPast) {
      alarmIcon = Icons.check_circle;
    } else if (alarmColor == Colors.red) {
      alarmIcon = Icons.warning_amber;
    } else if (alarmColor == Colors.orange) {
      alarmIcon = Icons.access_time;
    } else {
      alarmIcon = Icons.schedule;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(Styles.defaultPadding),
      decoration: BoxDecoration(
        color: isDark
            ? Styles.darkDefaultLightGreyColor
            : Styles.defaultLightGreyColor,
        borderRadius: Styles.defaultBorderRadius,
        border: Border.all(color: alarmColor.withOpacity(0.5), width: 3),
        boxShadow: [
          BoxShadow(
            color: alarmColor.withOpacity(0.2),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header avec statut d'alarme et heure
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: alarmColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: alarmColor, width: 1.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(alarmIcon, size: 18, color: alarmColor),
                    const SizedBox(width: 6),
                    Text(
                      proximityLabel,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: alarmColor,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                DateFormat('HH:mm').format(announcement.departureDateTime),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? Styles.darkDefaultBlueColor
                      : Styles.defaultBlueColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Trajet
          Row(
            children: [
              Icon(Icons.trip_origin, color: Styles.defaultBlueColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  announcement.origin,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? Styles.darkDefaultLightWhiteColor
                        : Styles.defaultRedColor,
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10),
            child: Container(
              width: 2,
              height: 20,
              color: Styles.defaultGreyColor.withOpacity(0.3),
            ),
          ),
          Row(
            children: [
              Icon(Icons.location_on, color: Styles.defaultRedColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  announcement.destination,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? Styles.darkDefaultLightWhiteColor
                        : Styles.defaultRedColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Détails
          Divider(
            color: isDark
                ? Styles.darkDefaultGreyColor.withOpacity(0.3)
                : Styles.defaultGreyColor.withOpacity(0.3),
          ),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoChip(
                Icons.event_seat,
                '$totalSeatsReserved sièges réservés',
                isDark,
              ),
              _buildInfoChip(
                Icons.attach_money,
                '${announcement.price.toStringAsFixed(2)} DT',
                isDark,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoChip(
                Icons.directions_car,
                announcement.carModel,
                isDark,
              ),
              _buildInfoChip(
                Icons.people,
                '${announcement.reservations.length} passagers',
                isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? Styles.darkDefaultBlueColor.withOpacity(0.1)
            : Styles.defaultBlueColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isDark
                ? Styles.darkDefaultBlueColor
                : Styles.defaultBlueColor,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? Styles.darkDefaultLightWhiteColor
                  : Styles.defaultRedColor,
            ),
          ),
        ],
      ),
    );
  }
}

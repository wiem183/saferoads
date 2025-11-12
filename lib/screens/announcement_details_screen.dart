// ignore_for_file: library_private_types_in_public_api, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/announcement.dart';
import '../styles/styles.dart';
import 'reservation_screen.dart';

class AnnouncementDetailsScreen extends StatefulWidget {
  final Announcement announcement;

  const AnnouncementDetailsScreen({super.key, required this.announcement});

  @override
  _AnnouncementDetailsScreenState createState() => _AnnouncementDetailsScreenState();
}

class _AnnouncementDetailsScreenState extends State<AnnouncementDetailsScreen>
    with SingleTickerProviderStateMixin {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                '${widget.announcement.origin} → ${widget.announcement.destination}',
                style: TextStyle(
                  fontSize: 20,
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
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Styles.darkDefaultLightWhiteColor
                    : Colors.white,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(Styles.defaultPadding),
              child: Hero(
                tag: widget.announcement.id,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Styles.darkDefaultLightGreyColor.withOpacity(0.7)
                          : Styles.defaultLightGreyColor.withOpacity(0.7),
                      borderRadius: Styles.defaultBorderRadius,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Styles.darkDefaultGreyColor.withOpacity(0.3)
                            : Styles.defaultGreyColor.withOpacity(0.3),
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(Styles.defaultPadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow(
                            context,
                            icon: Icons.calendar_today,
                            text:
                                'Départ: ${DateFormat('dd MMM yyyy, HH:mm').format(widget.announcement.departureDateTime)}',
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            context,
                            icon: Icons.event_seat,
                            text: 'Sièges disponibles: ${widget.announcement.availableSeats}',
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            context,
                            icon: Icons.attach_money,
                            text: 'Prix: ${widget.announcement.price.toStringAsFixed(2)} TND',
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            context,
                            icon: Icons.directions_car,
                            text: 'Voiture: ${widget.announcement.carModel}',
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            context,
                            icon: Icons.person,
                            text:
                                'Chauffeur: ${widget.announcement.driverName} (${widget.announcement.driverPhone})',
                          ),
                          const SizedBox(height: 20),
                          if (widget.announcement.availableSeats > 0)
                            Center(
                              child: GestureDetector(
                                onTapDown: (_) => _animationController.forward(),
                                onTapUp: (_) {
                                  _animationController.reverse();
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (_) => ReservationScreen(
                                      announcementId: widget.announcement.id, parkingId: '', parkingName: '', pricePerHour: 0.0,
                                    ),
                                  );
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
                                          color: Styles.defaultBlueColor
                                              .withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      'Réserver',
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
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, {required IconData icon, required String text}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).brightness == Brightness.dark
              ? Styles.darkDefaultYellowColor
              : Styles.defaultYellowColor,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Styles.darkDefaultLightWhiteColor
                  : Styles.defaultRedColor,
            ),
          ),
        ),
      ],
    );
  }
}
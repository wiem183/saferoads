// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/announcement.dart';
import '../styles/styles.dart';

class AnnouncementCard extends StatelessWidget {
  final Announcement announcement;

  const AnnouncementCard({super.key, required this.announcement});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: Styles.defaultPadding,
        vertical: Styles.defaultPadding / 2,
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).brightness == Brightness.dark
                  ? Styles.darkDefaultLightGreyColor
                  : Styles.defaultLightGreyColor,
              Theme.of(context).brightness == Brightness.dark
                  ? Styles.darkDefaultGreyColor.withOpacity(0.8)
                  : Styles.defaultLightWhiteColor.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: Styles.defaultBorderRadius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(Styles.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      '${announcement.origin} → ${announcement.destination}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Styles.darkDefaultLightWhiteColor
                            : Styles.defaultRedColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Styles.defaultBlueColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${announcement.price.toStringAsFixed(2)} TND',
                      style: TextStyle(
                        fontSize: 14,
                        color: Styles.defaultBlueColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                DateFormat('dd MMM yyyy, HH:mm').format(announcement.departureDateTime),
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Styles.darkDefaultGreyColor
                      : Styles.defaultGreyColor,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.event_seat,
                    size: 16,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Styles.darkDefaultYellowColor
                        : Styles.defaultYellowColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${announcement.availableSeats} sièges disponibles',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Styles.darkDefaultGreyColor
                          : Styles.defaultGreyColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
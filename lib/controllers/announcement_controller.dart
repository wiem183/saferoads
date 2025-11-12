import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/announcement.dart';

class AnnouncementController with ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<Announcement>> get announcementsStream =>
      _db.collection('announcements')
          .snapshots()
          .map((snap) =>
              snap.docs.map((d) => Announcement.fromJson(d.data())).toList());

  Stream<List<Announcement>> myRidesStream(String phone) =>
      _db.collection('announcements')
          .where('driverPhone', isEqualTo: phone)
          .snapshots()
          .map((snap) =>
              snap.docs.map((d) => Announcement.fromJson(d.data())).toList());

  Future<void> addAnnouncement(Announcement ann) async {
    await _db.collection('announcements').doc(ann.id).set(ann.toJson());
  }

  Future<void> deleteAnnouncement(String id) async {
    await _db.collection('announcements').doc(id).delete();
  }

  final List<Announcement> _local = [];
  List<Announcement> get announcements => _local;
}
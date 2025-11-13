import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/amende.dart';

class AmendeController with ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _collection = 'amendes';

  // CREATE: Add a new fine (agent/admin only)
  Future<String> createAmende({
    required String userId,
    required String agentId,
    String? photoUrl,
    required String location,
    required AmendeType type,
    required double amount,
  }) async {
    try {
      final amendeId = const Uuid().v4();
      final amende = Amende(
        id: amendeId,
        userId: userId,
        agentId: agentId,
        photoUrl: photoUrl,
        location: location,
        type: type,
        amount: amount,
      );

      await _db.collection(_collection).doc(amendeId).set(amende.toJson());
      notifyListeners();
      return amendeId;
    } catch (e) {
      throw Exception('Failed to create amende: $e');
    }
  }

  // READ: Get all fines for a specific user
  Stream<List<Amende>> getUserAmendesStream(String userId) {
    return _db
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => Amende.fromJson(d.data()))
            .toList());
  }

  // READ: Get a specific fine by ID
  Future<Amende?> getAmendeById(String amendeId) async {
    try {
      final doc = await _db.collection(_collection).doc(amendeId).get();
      if (doc.exists && doc.data() != null) {
        return Amende.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get amende: $e');
    }
  }

  // READ: Get fines created by a specific agent
  Stream<List<Amende>> getAgentAmendesStream(String agentId) {
    return _db
        .collection(_collection)
        .where('agentId', isEqualTo: agentId)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => Amende.fromJson(d.data()))
            .toList());
  }

  // DELETE: Delete an amende
  Future<void> deleteAmende(String amendeId) async {
    try {
      await _db.collection(_collection).doc(amendeId).delete();
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to delete amende: $e');
    }
  }

  // UPDATE: Update an amende
  Future<void> updateAmende(String amendeId, Map<String, dynamic> data) async {
    try {
      await _db.collection(_collection).doc(amendeId).update(data);
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to update amende: $e');
    }
  }

  // Utility: Get total amount for a user
  Future<double> getTotalAmount(String userId) async {
    try {
      final snap = await _db
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .get();

      double total = 0;
      for (var doc in snap.docs) {
        total += (doc.data()['amount'] as num).toDouble();
      }
      return total;
    } catch (e) {
      throw Exception('Failed to calculate total: $e');
    }
  }

  // Utility: Get total count of amendes for a user
  Future<int> getAmendesTotalCount(String userId) async {
    try {
      final snap = await _db
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .get();
      return snap.docs.length;
    } catch (e) {
      throw Exception('Failed to get count: $e');
    }
  }
}

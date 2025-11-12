import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/signalement.dart';

class SignalementService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _collection = 'signalements';

  /// Add a new signalement
  Future<void> addSignalement(Signalement signalement) async {
    try {
      await _db.collection(_collection).doc(signalement.id).set(signalement.toJson());
    } catch (e) {
      print('Error adding signalement: $e');
      rethrow;
    }
  }

  /// Update an existing signalement (e.g., increment confirmations)
  Future<void> updateSignalement(Signalement updatedSignalement) async {
    await FirebaseFirestore.instance
        .collection('signalements')
        .doc(updatedSignalement.id)
        .update({
      'type': updatedSignalement.type,
      'description': updatedSignalement.description,
      'photoUrl': updatedSignalement.photoUrl,
      'date': updatedSignalement.date.toIso8601String(),
    });
  }

  Future<void> deleteSignalement(String id) async {
    await FirebaseFirestore.instance
        .collection('signalements')
        .doc(id)
        .delete();
  }


  /// Stream all signalements (real-time updates)
  Stream<List<Signalement>> getSignalementsStream() {
    return _db.collection(_collection).snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => Signalement.fromJson(doc.data())).toList()
    );
  }

  /// Get a single signalement by ID
  Future<Signalement?> getSignalementById(String id) async {
    try {
      final doc = await _db.collection(_collection).doc(id).get();
      if (doc.exists) {
        return Signalement.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error fetching signalement: $e');
      return null;
    }
  }

  /// Increment confirmations for a signalement
  Future<void> confirmSignalement(String id) async {
    try {
      final docRef = _db.collection(_collection).doc(id);
      await _db.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) return;
        final currentConfirmations = snapshot.get('confirmations') as int;
        transaction.update(docRef, {'confirmations': currentConfirmations + 1});
      });
    } catch (e) {
      print('Error confirming signalement: $e');
      rethrow;
    }
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

class BlogReaction {
  final String userId;
  final String type;
  final DateTime reactedAt;

  const BlogReaction({
    required this.userId,
    required this.type,
    required this.reactedAt,
  });

  factory BlogReaction.fromJson(Map<String, dynamic> json) {
    return BlogReaction(
      userId: json['userId'] ?? '',
      type: json['type'] ?? 'like',
      reactedAt: _parseTimestamp(json['reactedAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'type': type,
      'reactedAt': reactedAt.toIso8601String(),
    };
  }

  static DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}

class BlogFavorite {
  final String userId;
  final DateTime favoritedAt;

  const BlogFavorite({
    required this.userId,
    required this.favoritedAt,
  });

  factory BlogFavorite.fromJson(Map<String, dynamic> json) {
    return BlogFavorite(
      userId: json['userId'] ?? '',
      favoritedAt: BlogReaction._parseTimestamp(json['favoritedAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'favoritedAt': favoritedAt.toIso8601String(),
    };
  }
}


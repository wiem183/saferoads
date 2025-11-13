import 'package:cloud_firestore/cloud_firestore.dart';

class BlogMedia {
  final String id;
  final String url;
  final String type; // e.g. image, video
  final String? thumbnailUrl;
  final DateTime uploadedAt;

  const BlogMedia({
    required this.id,
    required this.url,
    required this.type,
    this.thumbnailUrl,
    required this.uploadedAt,
  });

  factory BlogMedia.fromJson(Map<String, dynamic> json) {
    return BlogMedia(
      id: json['id'] ?? '',
      url: json['url'] ?? '',
      type: json['type'] ?? 'image',
      thumbnailUrl: json['thumbnailUrl'],
      uploadedAt: _parseTimestamp(json['uploadedAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'type': type,
      'thumbnailUrl': thumbnailUrl,
      'uploadedAt': uploadedAt.toIso8601String(),
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


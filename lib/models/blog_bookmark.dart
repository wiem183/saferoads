import 'package:cloud_firestore/cloud_firestore.dart';

import 'blog_post.dart';

class BlogBookmark {
  final String postId;
  final DateTime? savedAt;
  final BlogPost? post;

  const BlogBookmark({
    required this.postId,
    this.savedAt,
    this.post,
  });

  factory BlogBookmark.fromMap(String docId, Map<String, dynamic> data) {
    final savedAt = _parseTimestamp(data['createdAt']);

    BlogPost? post;
    final snapshot = data['postSnapshot'];
    if (snapshot is Map) {
      final map = Map<String, dynamic>.from(snapshot);
      map['id'] = map['id'] ?? docId;
      post = BlogPost.fromJson(map);
    }

    return BlogBookmark(
      postId: docId,
      savedAt: savedAt,
      post: post,
    );
  }

  String get title => post?.title ?? 'Publication indisponible';
  String get authorName => post?.authorName ?? '';

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







import 'package:cloud_firestore/cloud_firestore.dart';

class BlogComment {
  final String id;
  final String postId;
  final String authorId;
  final String authorName;
  final String content;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? parentCommentId;
  final List<String> likedBy;
  final int repliesCount;

  BlogComment({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorName,
    required this.content,
    required this.createdAt,
    this.updatedAt,
    this.parentCommentId,
    this.likedBy = const [],
    this.repliesCount = 0,
  });

  factory BlogComment.fromJson(Map<String, dynamic> json) {
    return BlogComment(
      id: json['id'] ?? '',
      postId: json['postId'] ?? '',
      authorId: json['authorId'] ?? '',
      authorName: json['authorName'] ?? 'Anonyme',
      content: json['content'] ?? '',
      createdAt: _parseTimestamp(json['createdAt']) ?? DateTime.now(),
      updatedAt: _parseTimestamp(json['updatedAt']),
      parentCommentId: json['parentCommentId'],
      likedBy: List<String>.from(json['likedBy'] ?? const []),
      repliesCount: (json['repliesCount'] ?? 0).toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'postId': postId,
      'authorId': authorId,
      'authorName': authorName,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'parentCommentId': parentCommentId,
      'likedBy': likedBy,
      'repliesCount': repliesCount,
    };
  }

  bool isValid() {
    return content.trim().isNotEmpty && authorId.isNotEmpty && postId.isNotEmpty;
  }

  BlogComment copyWith({
    String? id,
    String? postId,
    String? authorId,
    String? authorName,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? parentCommentId,
    List<String>? likedBy,
    int? repliesCount,
  }) {
    return BlogComment(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      parentCommentId: parentCommentId ?? this.parentCommentId,
      likedBy: likedBy ?? this.likedBy,
      repliesCount: repliesCount ?? this.repliesCount,
    );
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


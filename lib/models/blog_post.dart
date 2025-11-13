import 'package:cloud_firestore/cloud_firestore.dart';

import 'blog_media.dart';
import 'blog_reaction.dart';

class BlogPost {
  final String id;
  final String authorId;
  final String authorName;
  final String title;
  final String content;
  final String? imageUrl;
  final String postType;
  final List<String> tags;
  final List<BlogMedia> media;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? publishedAt;
  final bool isDraft;
  final List<BlogReaction> reactions;
  final List<String> favoritedBy;
  final int commentsCount;

  static const String defaultPostType = 'general';

  BlogPost({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.title,
    required this.content,
    required this.createdAt,
    this.imageUrl,
    this.postType = defaultPostType,
    this.tags = const [],
    this.media = const [],
    this.updatedAt,
    this.publishedAt,
    this.isDraft = false,
    this.reactions = const [],
    this.favoritedBy = const [],
    this.commentsCount = 0,
  });

  factory BlogPost.fromJson(Map<String, dynamic> json) {
    final createdAt = _parseTimestamp(json['createdAt']);
    final updatedAt = _tryParseTimestamp(json['updatedAt']);

    final mediaList = List<BlogMedia>.from(
      _parseMedia(json['media'] ?? json['attachments']),
    );
    final imageUrlValue = json['imageUrl'];
    if (mediaList.isEmpty && imageUrlValue is String && imageUrlValue.isNotEmpty) {
      mediaList.add(
        BlogMedia(
          id: json['imageId'] is String && (json['imageId'] as String).isNotEmpty
              ? json['imageId']
              : (json['id'] ?? ''),
          url: imageUrlValue,
          type: 'image',
          uploadedAt: createdAt ?? DateTime.now(),
        ),
      );
    }

    return BlogPost(
      id: json['id'] ?? '',
      authorId: json['authorId'] ?? '',
      authorName: json['authorName'] ?? 'Anonyme',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      imageUrl: json['imageUrl'],
      postType: json['postType'] ?? defaultPostType,
      tags: _parseTags(json['tags']),
      media: mediaList,
      createdAt: createdAt ?? DateTime.now(),
      updatedAt: updatedAt,
      publishedAt: _tryParseTimestamp(json['publishedAt']),
      isDraft: json['isDraft'] ?? false,
      reactions: (json['reactions'] as List? ?? [])
          .map((raw) => BlogReaction.fromJson(Map<String, dynamic>.from(raw)))
          .toList(),
      favoritedBy: List<String>.from(json['favoritedBy'] ?? const []),
      commentsCount: (json['commentsCount'] ?? 0).toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'authorId': authorId,
      'authorName': authorName,
      'title': title,
      'content': content,
      'imageUrl': imageUrl ?? (media.isNotEmpty ? media.first.url : null),
      'postType': postType,
      'tags': tags,
      'media': media.map((item) => item.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'publishedAt': publishedAt?.toIso8601String(),
      'isDraft': isDraft,
      'reactions': reactions.map((reaction) => reaction.toJson()).toList(),
      'favoritedBy': favoritedBy,
      'commentsCount': commentsCount,
    };
  }

  bool isValid() {
    return title.trim().isNotEmpty &&
        content.trim().isNotEmpty &&
        authorId.isNotEmpty &&
        postType.trim().isNotEmpty;
  }

  BlogPost copyWith({
    String? id,
    String? authorId,
    String? authorName,
    String? title,
    String? content,
    String? imageUrl,
    String? postType,
    List<String>? tags,
    List<BlogMedia>? media,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? publishedAt,
    bool? isDraft,
    List<BlogReaction>? reactions,
    List<String>? favoritedBy,
    int? commentsCount,
  }) {
    return BlogPost(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      title: title ?? this.title,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      postType: postType ?? this.postType,
      tags: tags ?? this.tags,
      media: media ?? this.media,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      publishedAt: publishedAt ?? this.publishedAt,
      isDraft: isDraft ?? this.isDraft,
      reactions: reactions ?? this.reactions,
      favoritedBy: favoritedBy ?? this.favoritedBy,
      commentsCount: commentsCount ?? this.commentsCount,
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

  static DateTime? _tryParseTimestamp(dynamic value) {
    final parsed = _parseTimestamp(value);
    return parsed;
  }

  static List<String> _parseTags(dynamic value) {
    if (value == null) return const [];
    if (value is List) {
      return value
          .whereType<String>()
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();
    }
    if (value is String && value.isNotEmpty) {
      return value
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();
    }
    return const [];
  }

  static List<BlogMedia> _parseMedia(dynamic value) {
    if (value == null) return const [];
    if (value is List) {
      return value
          .whereType<Map>()
          .map((raw) => BlogMedia.fromJson(Map<String, dynamic>.from(raw)))
          .toList();
    }
    return const [];
  }
}


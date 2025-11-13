import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/blog_bookmark.dart';
import '../models/blog_media.dart';
import '../models/blog_post.dart';
import '../models/blog_reaction.dart';
import '../models/comment.dart';
import 'cloudinary_service.dart';

class BlogService {
  static const String postsCollection = 'blog_posts';
  static const String bookmarksSubcollection = 'blog_bookmarks';

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _postsRef =>
      _db.collection(postsCollection);

  CollectionReference<Map<String, dynamic>> _userBookmarksRef(String userId) =>
      _db.collection('users').doc(userId).collection(bookmarksSubcollection);

  Stream<List<BlogPost>> getPostsStream({int? limit}) {
    Query<Map<String, dynamic>> query =
        _postsRef.orderBy('createdAt', descending: true);

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => BlogPost.fromJson({
                  ...doc.data(),
                  'id': doc.id,
                }),
              )
              .toList(),
        );
  }

  Future<BlogPost?> getPostById(String id) async {
    final doc = await _postsRef.doc(id).get();
    if (!doc.exists) return null;
    return BlogPost.fromJson({
      ...doc.data()!,
      'id': doc.id,
    });
  }

  Future<String> createPost(BlogPost draft) async {
    final docRef = draft.id.isNotEmpty ? _postsRef.doc(draft.id) : _postsRef.doc();
    final now = FieldValue.serverTimestamp();
    final data = {
      ...draft.toJson(),
      'id': docRef.id,
      'createdAt': now,
      'updatedAt': now,
      'publishedAt': draft.isDraft ? null : now,
      'commentsCount': draft.commentsCount,
    };
    await docRef.set(data);
    return docRef.id;
  }

  Future<void> updatePost(BlogPost post) async {
    final data = {
      ...post.toJson(),
      'updatedAt': FieldValue.serverTimestamp(),
      'publishedAt': post.isDraft
          ? null
          : (post.publishedAt ?? FieldValue.serverTimestamp()),
    };
    await _postsRef.doc(post.id).update(data);
  }

  Future<void> setDraftStatus({
    required String postId,
    required bool isDraft,
  }) async {
    await _postsRef.doc(postId).update({
      'isDraft': isDraft,
      'publishedAt': isDraft ? null : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<BlogPost>> getUserDrafts(String authorId) {
    return _postsRef
        .where('authorId', isEqualTo: authorId)
        .where('isDraft', isEqualTo: true)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => BlogPost.fromJson({
                  ...doc.data(),
                  'id': doc.id,
                }),
              )
              .toList(),
        );
  }

  Future<void> deletePost(String postId) async {
    final batch = _db.batch();
    final postRef = _postsRef.doc(postId);
    final comments = await postRef.collection('comments').get();
    for (final comment in comments.docs) {
      batch.delete(comment.reference);
    }
    batch.delete(postRef);
    await batch.commit();
  }

  Stream<List<BlogComment>> getCommentsStream(String postId) {
    return _postsRef
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => BlogComment.fromJson({
                  ...doc.data(),
                  'id': doc.id,
                }),
              )
              .toList(),
        );
  }

  Future<String> addComment(String postId, BlogComment comment) async {
    final commentsRef = _postsRef.doc(postId).collection('comments');
    final docRef = comment.id.isNotEmpty ? commentsRef.doc(comment.id) : commentsRef.doc();

    await _db.runTransaction((transaction) async {
      transaction.set(docRef, {
        ...comment.toJson(),
        'id': docRef.id,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      transaction.update(
        _postsRef.doc(postId),
        {'commentsCount': FieldValue.increment(1)},
      );
    });

    return docRef.id;
  }

  Future<void> deleteComment(String postId, String commentId) async {
    final postRef = _postsRef.doc(postId);
    final commentRef = postRef.collection('comments').doc(commentId);

    await _db.runTransaction((transaction) async {
      transaction.delete(commentRef);
      transaction.update(
        postRef,
        {'commentsCount': FieldValue.increment(-1)},
      );
    });
  }

  Future<void> toggleFavorite({
    required String postId,
    required String userId,
  }) async {
    final postRef = _postsRef.doc(postId);

    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(postRef);
      if (!snapshot.exists) return;

      final favoritedBy = List<String>.from(snapshot.get('favoritedBy') ?? const []);

      if (favoritedBy.contains(userId)) {
        favoritedBy.remove(userId);
      } else {
        favoritedBy.add(userId);
      }

      transaction.update(postRef, {'favoritedBy': favoritedBy});
    });
  }

  Future<void> toggleReaction({
    required String postId,
    required String userId,
    required String reactionType,
  }) async {
    final postRef = _postsRef.doc(postId);

    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(postRef);
      if (!snapshot.exists) return;

      final rawReactions = (snapshot.data()?['reactions'] as List?) ?? [];

      final reactions = rawReactions
          .map((raw) => BlogReaction.fromJson(Map<String, dynamic>.from(raw)))
          .toList();

      final existingIndex =
          reactions.indexWhere((reaction) => reaction.userId == userId);

      if (existingIndex != -1) {
        final existing = reactions[existingIndex];
        if (existing.type == reactionType) {
          reactions.removeAt(existingIndex);
        } else {
          reactions[existingIndex] = BlogReaction(
            userId: userId,
            type: reactionType,
            reactedAt: DateTime.now(),
          );
        }
      } else {
        reactions.add(
          BlogReaction(
            userId: userId,
            type: reactionType,
            reactedAt: DateTime.now(),
          ),
        );
      }

      transaction.update(postRef, {
        'reactions': reactions.map((reaction) => reaction.toJson()).toList(),
      });
    });
  }

  Future<void> toggleCommentLike({
    required String postId,
    required String commentId,
    required String userId,
  }) async {
    final commentRef =
        _postsRef.doc(postId).collection('comments').doc(commentId);

    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(commentRef);
      if (!snapshot.exists) return;

      final likedBy = List<String>.from(snapshot.get('likedBy') ?? const []);

      if (likedBy.contains(userId)) {
        likedBy.remove(userId);
      } else {
        likedBy.add(userId);
      }

      transaction.update(commentRef, {'likedBy': likedBy});
    });
  }

  Future<BlogMedia?> uploadImageMedia(File file) async {
    final url = await CloudinaryService.uploadImage(file);
    if (url == null) return null;
    return BlogMedia(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      url: url,
      type: 'image',
      uploadedAt: DateTime.now(),
    );
  }

  Stream<List<BlogBookmark>> bookmarksStream(String userId) {
    return _userBookmarksRef(userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => BlogBookmark.fromMap(
                  doc.id,
                  doc.data(),
                ),
              )
              .toList(),
        );
  }

  Future<void> addBookmark({
    required String userId,
    required BlogPost post,
  }) async {
    final ref = _userBookmarksRef(userId).doc(post.id);
    await ref.set(
      {
        'postId': post.id,
        'createdAt': FieldValue.serverTimestamp(),
        'postSnapshot': post.toJson(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> removeBookmark({
    required String userId,
    required String postId,
  }) async {
    await _userBookmarksRef(userId).doc(postId).delete();
  }

  Future<void> toggleBookmark({
    required String userId,
    required BlogPost post,
  }) async {
    final ref = _userBookmarksRef(userId).doc(post.id);
    final doc = await ref.get();
    if (doc.exists) {
      await ref.delete();
    } else {
      await addBookmark(userId: userId, post: post);
    }
  }
}


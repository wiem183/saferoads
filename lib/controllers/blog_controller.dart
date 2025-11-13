import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/blog_bookmark.dart';
import '../models/blog_media.dart';
import '../models/blog_post.dart';
import '../models/comment.dart';
import '../services/blog_service.dart';

class BlogController extends ChangeNotifier {
  final BlogService _service;

  StreamSubscription<List<BlogPost>>? _postsSubscription;
  StreamSubscription<List<BlogBookmark>>? _bookmarkSubscription;
  StreamSubscription<List<BlogPost>>? _draftsSubscription;
  final Map<String, StreamSubscription<List<BlogComment>>> _commentSubscriptions =
      {};

  List<BlogPost> _posts = [];
  List<BlogPost> _drafts = [];
  final Map<String, List<BlogComment>> _postComments = {};
  Set<String> _bookmarkedPostIds = {};
  List<BlogBookmark> _bookmarks = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<BlogPost> get posts => _posts;
  List<BlogPost> get drafts => UnmodifiableListView(_drafts);
  List<BlogBookmark> get bookmarks => UnmodifiableListView(_bookmarks);
  Set<String> get bookmarkedPostIds => _bookmarkedPostIds;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<BlogComment> commentsFor(String postId) =>
      _postComments[postId] ?? const [];

  BlogController({BlogService? blogService})
      : _service = blogService ?? BlogService() {
    _subscribeToPosts();
  }

  void _subscribeToPosts() {
    _postsSubscription?.cancel();
    _postsSubscription = _service.getPostsStream().listen(
      (data) {
        _posts = data;
        notifyListeners();
      },
      onError: (Object e) {
        _setError(e);
      },
    );
  }

  void listenToComments(String postId) {
    if (_commentSubscriptions.containsKey(postId)) {
      return;
    }

    final subscription = _service.getCommentsStream(postId).listen(
      (comments) {
        _postComments[postId] = comments;
        notifyListeners();
      },
      onError: (Object e) {
        _setError(e);
      },
    );

    _commentSubscriptions[postId] = subscription;
  }

  void watchBookmarks(String? userId) {
    _bookmarkSubscription?.cancel();
    if (userId == null || userId.isEmpty) {
      if (_bookmarkedPostIds.isNotEmpty) {
        _bookmarkedPostIds = {};
        _bookmarks = [];
        notifyListeners();
      }
      return;
    }
    _bookmarkSubscription = _service.bookmarksStream(userId).listen(
      (entries) {
        _bookmarks = entries;
        _bookmarkedPostIds =
            entries.map((bookmark) => bookmark.postId).toSet();
        notifyListeners();
      },
      onError: (Object e) => _setError(e),
    );
  }

  void watchDrafts(String? userId) {
    _draftsSubscription?.cancel();
    if (userId == null || userId.isEmpty) {
      if (_drafts.isNotEmpty) {
        _drafts = [];
        notifyListeners();
      }
      return;
    }
    _draftsSubscription = _service.getUserDrafts(userId).listen(
      (draftList) {
        _drafts = draftList;
        notifyListeners();
      },
      onError: (Object e) => _setError(e),
    );
  }

  bool isBookmarked(String postId) => _bookmarkedPostIds.contains(postId);

  Future<BlogMedia?> uploadImageMedia(File file) async {
    try {
      return await _service.uploadImageMedia(file);
    } catch (e) {
      _setError(e);
      return null;
    }
  }

  Future<String?> createPost(BlogPost post) async {
    if (!post.isValid()) {
      _setError('Post invalide');
      return null;
    }

    _setLoading(true);
    try {
      final id = await _service.createPost(post);
      _clearError();
      return id;
    } catch (e) {
      _setError(e);
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updatePost(BlogPost post) async {
    if (!post.isValid()) {
      _setError('Post invalide');
      return false;
    }

    _setLoading(true);
    try {
      await _service.updatePost(post);
      _clearError();
      return true;
    } catch (e) {
      _setError(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deletePost(String postId) async {
    _setLoading(true);
    try {
      await _service.deletePost(postId);
      _postComments.remove(postId);
      if (_bookmarkedPostIds.remove(postId)) {
        notifyListeners();
      }
      final subscription = _commentSubscriptions.remove(postId);
      await subscription?.cancel();
      _clearError();
      return true;
    } catch (e) {
      _setError(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<String?> addComment(String postId, BlogComment comment) async {
    if (!comment.isValid()) {
      _setError('Commentaire invalide');
      return null;
    }

    _setLoading(true);
    try {
      final id = await _service.addComment(postId, comment);
      _clearError();
      return id;
    } catch (e) {
      _setError(e);
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteComment(String postId, String commentId) async {
    _setLoading(true);
    try {
      await _service.deleteComment(postId, commentId);
      _clearError();
      return true;
    } catch (e) {
      _setError(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> toggleFavorite({
    required String postId,
    required String userId,
  }) async {
    try {
      await _service.toggleFavorite(postId: postId, userId: userId);
    } catch (e) {
      _setError(e);
    }
  }

  Future<void> toggleBookmark({
    required BlogPost post,
    required String userId,
  }) async {
    try {
      await _service.toggleBookmark(userId: userId, post: post);
    } catch (e) {
      _setError(e);
    }
  }

  Future<void> removeBookmark({
    required String postId,
    required String userId,
  }) async {
    try {
      await _service.removeBookmark(userId: userId, postId: postId);
    } catch (e) {
      _setError(e);
    }
  }

  Future<void> setDraftStatus({
    required String postId,
    required bool isDraft,
  }) async {
    try {
      await _service.setDraftStatus(postId: postId, isDraft: isDraft);
    } catch (e) {
      _setError(e);
    }
  }

  Future<void> toggleReaction({
    required String postId,
    required String userId,
    required String reactionType,
  }) async {
    try {
      await _service.toggleReaction(
        postId: postId,
        userId: userId,
        reactionType: reactionType,
      );
    } catch (e) {
      _setError(e);
    }
  }

  Future<void> toggleCommentLike({
    required String postId,
    required String commentId,
    required String userId,
  }) async {
    try {
      await _service.toggleCommentLike(
        postId: postId,
        commentId: commentId,
        userId: userId,
      );
    } catch (e) {
      _setError(e);
    }
  }

  void _setLoading(bool value) {
    if (_isLoading != value) {
      _isLoading = value;
      notifyListeners();
    }
  }

  void _setError(Object error) {
    _errorMessage = error.toString();
    notifyListeners();
  }

  void _clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _postsSubscription?.cancel();
    _bookmarkSubscription?.cancel();
    _draftsSubscription?.cancel();
    for (final subscription in _commentSubscriptions.values) {
      subscription.cancel();
    }
    super.dispose();
  }
}


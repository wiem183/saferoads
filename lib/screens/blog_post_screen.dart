import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../controllers/blog_controller.dart';
import '../models/blog_post.dart';
import '../models/blog_reaction.dart';
import '../models/comment.dart';
import '../widgets/blog_comment_form.dart';
import '../widgets/blog_media_carousel.dart';
import 'blog_compose_screen.dart';

class BlogPostScreen extends StatefulWidget {
  final String postId;

  const BlogPostScreen({super.key, required this.postId});

  @override
  State<BlogPostScreen> createState() => _BlogPostScreenState();
}

class _BlogPostScreenState extends State<BlogPostScreen> {
  bool _initialised = false;
  String? _lastUserId;

  static const Map<String, String> _postTypeLabels = {
    'general': 'Discussion',
    'safety_tip': 'Conseil sécurité',
    'incident_report': 'Retour d\'incident',
    'news': 'Actualité',
  };

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final blogController = context.read<BlogController>();
    if (!_initialised) {
      blogController.listenToComments(widget.postId);
      _initialised = true;
    }

    final auth = Provider.of<AuthController>(context);
    final userId = auth.currentUser?.id;
    if (_lastUserId != userId) {
      blogController.watchBookmarks(userId);
      _lastUserId = userId;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<BlogController, AuthController>(
      builder: (context, blogController, authController, _) {
        final post = blogController.posts
            .where((element) => element.id == widget.postId)
            .cast<BlogPost?>()
            .firstWhere((element) => element != null, orElse: () => null);

        if (post == null) {
          return const Scaffold(
            body: Padding(
              padding: EdgeInsets.all(16),
              child: _PostDetailShimmer(),
            ),
          );
        }

        final currentUser = authController.currentUser;
        final comments = blogController.commentsFor(widget.postId);
        final DateFormat dateFormatter = DateFormat('dd MMM yyyy • HH:mm');
        final reactionSummary = _buildReactionSummary(post.reactions);
        final userReaction = currentUser == null
            ? null
            : post.reactions
                .where((reaction) => reaction.userId == currentUser.id)
                .map((reaction) => reaction.type)
                .cast<String?>()
                .firstWhere((_) => true, orElse: () => null);
        final isFavorited =
            currentUser != null && post.favoritedBy.contains(currentUser.id);
        final isBookmarked =
            currentUser != null && blogController.isBookmarked(post.id);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Publication'),
            actions: [
              if (currentUser?.id == post.authorId)
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _openComposer(post),
                  tooltip: 'Modifier',
                ),
              if (currentUser != null)
                IconButton(
                  icon: Icon(
                    isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                  ),
                  tooltip: isBookmarked
                      ? 'Retirer des favoris'
                      : 'Ajouter aux favoris',
                  onPressed: () => blogController.toggleBookmark(
                    post: post,
                    userId: currentUser.id,
                  ),
                ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (post.isDraft)
                        Card(
                          color:
                              Theme.of(context).colorScheme.primaryContainer,
                          elevation: 0,
                          child: const Padding(
                            padding: EdgeInsets.all(12),
                            child: Text(
                              'Ce contenu est enregistré en brouillon. Seul vous pouvez le voir.',
                            ),
                          ),
                        ),
                      Text(
                        post.title,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Par ${post.authorName} • ${dateFormatter.format(post.publishedAt ?? post.createdAt)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Chip(
                            label: Text(_typeLabel(post.postType)),
                            avatar:
                                const Icon(Icons.category_outlined, size: 16),
                          ),
                          if (post.tags.isNotEmpty)
                            ...post.tags.map(
                              (tag) => Chip(
                                label: Text('#$tag'),
                              ),
                            ),
                        ],
                      ),
                      if (post.media.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Hero(
                          tag: 'post-image-${post.id}',
                          child: Material(
                            color: Colors.transparent,
                            child: BlogMediaCarousel(
                              media: post.media,
                              height: 240,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Text(
                        post.content,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 24),
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          _ReactionButton(
                            icon: Icons.thumb_up,
                            label: '${reactionSummary['like'] ?? 0}',
                            isActive: userReaction == 'like',
                            onTap: currentUser == null
                                ? null
                                : () => blogController.toggleReaction(
                                      postId: post.id,
                                      userId: currentUser.id,
                                      reactionType: 'like',
                                    ),
                          ),
                          _ReactionButton(
                            icon: Icons.favorite,
                            label: '${post.favoritedBy.length}',
                            isActive: isFavorited,
                            onTap: currentUser == null
                                ? null
                                : () => blogController.toggleFavorite(
                                      postId: post.id,
                                      userId: currentUser.id,
                                    ),
                          ),
                          _ReactionButton(
                            icon: Icons.comment,
                            label: '${post.commentsCount}',
                            onTap: () {},
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Divider(color: Theme.of(context).dividerColor),
                      const SizedBox(height: 16),
                      Text(
                        'Commentaires (${comments.length})',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      if (comments.isEmpty)
                        const Text(
                          'Soyez le premier à commenter cette publication.',
                        )
                      else
                        ...comments.map(
                          (comment) => _CommentTile(
                            comment: comment,
                            currentUserId: currentUser?.id,
                            onToggleLike: currentUser == null
                                ? null
                                : () => blogController.toggleCommentLike(
                                      postId: post.id,
                                      commentId: comment.id,
                                      userId: currentUser.id,
                                    ),
                          ),
                        ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
              if (currentUser != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: BlogCommentForm(
                    isSubmitting: blogController.isLoading,
                    onSubmit: (text) async {
                      final comment = BlogComment(
                        id: '',
                        postId: post.id,
                        authorId: currentUser.id,
                        authorName: currentUser.name,
                        content: text,
                        createdAt: DateTime.now(),
                      );
                      await blogController.addComment(post.id, comment);
                    },
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Connectez-vous pour participer à la discussion.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  String _typeLabel(String value) =>
      _postTypeLabels[value] ?? _postTypeLabels['general']!;

  void _openComposer(BlogPost post) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlogComposeScreen(existingPost: post),
      ),
    );
  }

  Map<String, int> _buildReactionSummary(List<BlogReaction> reactions) {
    final Map<String, int> summary = {};
    for (final reaction in reactions) {
      summary.update(reaction.type, (value) => value + 1, ifAbsent: () => 1);
    }
    return summary;
  }
}

class _PostDetailShimmer extends StatefulWidget {
  const _PostDetailShimmer();
  @override
  State<_PostDetailShimmer> createState() => _PostDetailShimmerState();
}

class _PostDetailShimmerState extends State<_PostDetailShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).cardColor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _block(base),
        const SizedBox(height: 12),
        _block(base, height: 180),
        const SizedBox(height: 12),
        _block(base, height: 18),
        const SizedBox(height: 8),
        _block(base, height: 18, widthFactor: 0.7),
      ],
    );
  }

  Widget _block(Color base, {double height = 24, double widthFactor = 1.0}) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Container(
            height: height,
            decoration: BoxDecoration(
              color: base,
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                begin: Alignment(-1.0 + _controller.value * 2, 0),
                end: Alignment(1.0 + _controller.value * 2, 0),
                colors: [
                  base.withOpacity(0.9),
                  base.withOpacity(0.7),
                  base.withOpacity(0.9),
                ],
                stops: const [0.1, 0.3, 0.4],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ReactionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback? onTap;

  const _ReactionButton({
    required this.icon,
    required this.label,
    this.isActive = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        isActive ? Theme.of(context).colorScheme.primary : Colors.grey[600];
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  final BlogComment comment;
  final String? currentUserId;
  final VoidCallback? onToggleLike;

  const _CommentTile({
    required this.comment,
    required this.currentUserId,
    this.onToggleLike,
  });

  @override
  Widget build(BuildContext context) {
    final bool isLiked =
        currentUserId != null && comment.likedBy.contains(currentUserId);
    final DateFormat formatter = DateFormat('dd/MM/yyyy HH:mm');

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  comment.authorName,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                Text(
                  formatter.format(comment.createdAt),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(comment.content),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.thumb_up,
                    size: 18,
                    color: isLiked
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey,
                  ),
                  onPressed: onToggleLike,
                ),
                Text(
                  '${comment.likedBy.length}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


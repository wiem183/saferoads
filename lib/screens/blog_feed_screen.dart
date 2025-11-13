import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../controllers/blog_controller.dart';
import '../models/blog_post.dart';
import '../widgets/app_drawer.dart';
import '../widgets/blog_media_carousel.dart';
import 'blog_compose_screen.dart';
import 'blog_post_screen.dart';

class BlogFeedScreen extends StatefulWidget {
  const BlogFeedScreen({super.key});

  @override
  State<BlogFeedScreen> createState() => _BlogFeedScreenState();
}

class _BlogFeedScreenState extends State<BlogFeedScreen> {
  String? _lastUserId;
  String _searchTitle = '';
  String _searchTags = '';
  String _selectedTypeFilter = 'all';
  String? _pressedPostId;

  static const Map<String, String> _postTypeLabels = {
    'general': 'Discussion',
    'safety_tip': 'Conseil sécurité',
    'incident_report': 'Retour d\'incident',
    'news': 'Actualité',
  };
  static const List<MapEntry<String, String>> _filterTypes = [
    MapEntry('all', 'Tous les types'),
    MapEntry('general', 'Discussion'),
    MapEntry('safety_tip', 'Conseil sécurité'),
    MapEntry('incident_report', 'Retour d\'incident'),
    MapEntry('news', 'Actualité'),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = Provider.of<AuthController>(context);
    final userId = auth.currentUser?.id;
    if (userId != _lastUserId) {
      final controller = context.read<BlogController>();
      controller.watchBookmarks(userId);
      controller.watchDrafts(userId);
      _lastUserId = userId;
    }
  }

  Future<void> _openComposer({BlogPost? draft}) async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => BlogComposeScreen(existingPost: draft),
      ),
    );

    if (!mounted || result == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result == 'draft'
              ? 'Brouillon enregistré'
              : 'Publication mise en ligne avec succès',
        ),
      ),
    );
  }

  Future<void> _confirmPublishDraft(BlogPost draft) async {
    final shouldPublish = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Publier ce brouillon ?'),
        content: const Text(
          'La publication sera visible par tous les utilisateurs.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Publier'),
          ),
        ],
      ),
    );

    if (shouldPublish != true) return;

    final controller = context.read<BlogController>();
    await controller.setDraftStatus(postId: draft.id, isDraft: false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Brouillon publié')),
    );
  }

  String _typeLabel(String value) =>
      _postTypeLabels[value] ?? _postTypeLabels['general']!;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Communauté SafeRoad'),
      ),
      drawer: const AppDrawer(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openComposer(),
        child: const Icon(Icons.edit),
      ),
      body: Consumer2<BlogController, AuthController>(
        builder: (context, blogController, authController, _) {
          final userId = authController.currentUser?.id;
          final publishedPosts =
              blogController.posts.where((post) => !post.isDraft).toList();
          final drafts = userId != null
              ? blogController.drafts.where((d) => d.authorId == userId).toList()
              : const <BlogPost>[];

          if (blogController.isLoading && publishedPosts.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (publishedPosts.isEmpty) {
            return _EmptyState(onCreatePost: () => _openComposer());
          }

          return RefreshIndicator(
            onRefresh: () async {
              await Future<void>.delayed(const Duration(milliseconds: 300));
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).primaryColor.withOpacity(0.10),
                          Colors.transparent,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Text(
                      'Communauté',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Search and filters (mobile‑first)
                        AnimatedSize(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOut,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOut,
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor.withOpacity(0.95),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            margin: const EdgeInsets.only(bottom: 10),
                            child: LayoutBuilder(
                              builder: (ctx, box) {
                                final isMobile = box.maxWidth < 600;
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (isMobile)
                                      ...[
                                        TextField(
                                          decoration: const InputDecoration(
                                            labelText: 'Rechercher par titre',
                                            prefixIcon: Icon(Icons.search),
                                          ),
                                          onChanged: (v) => setState(() {
                                            _searchTitle = v.trim().toLowerCase();
                                          }),
                                        ),
                                        const SizedBox(height: 8),
                                        DropdownButtonFormField<String>(
                                          value: _selectedTypeFilter,
                                          decoration: const InputDecoration(
                                            labelText: 'Type',
                                            prefixIcon: Icon(Icons.filter_list),
                                          ),
                                          items: _filterTypes
                                              .map(
                                                (e) => DropdownMenuItem<String>(
                                                  value: e.key,
                                                  child: Text(e.value),
                                                ),
                                              )
                                              .toList(),
                                          onChanged: (v) {
                                            if (v == null) return;
                                            setState(() => _selectedTypeFilter = v);
                                          },
                                        ),
                                      ]
                                    else
                                      Row(
                                        children: [
                                          Expanded(
                                            child: TextField(
                                              decoration: const InputDecoration(
                                                labelText: 'Rechercher par titre',
                                                prefixIcon: Icon(Icons.search),
                                              ),
                                              onChanged: (v) => setState(() {
                                                _searchTitle = v.trim().toLowerCase();
                                              }),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          DropdownButton<String>(
                                            value: _selectedTypeFilter,
                                            items: _filterTypes
                                                .map(
                                                  (e) => DropdownMenuItem<String>(
                                                    value: e.key,
                                                    child: Text(e.value),
                                                  ),
                                                )
                                                .toList(),
                                            onChanged: (v) {
                                              if (v == null) return;
                                              setState(() => _selectedTypeFilter = v);
                                            },
                                          ),
                                        ],
                                      ),
                                    const SizedBox(height: 8),
                                    TextField(
                                      decoration: const InputDecoration(
                                        labelText: 'Tags (séparés par des virgules)',
                                        prefixIcon: Icon(Icons.tag),
                                        hintText: 'ex: sécurité, route',
                                      ),
                                      onChanged: (v) => setState(() {
                                        _searchTags = v.trim().toLowerCase();
                                      }),
                                    ),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton.icon(
                                        onPressed: () {
                                          setState(() {
                                            _searchTitle = '';
                                            _searchTags = '';
                                            _selectedTypeFilter = 'all';
                                          });
                                        },
                                        icon: const Icon(Icons.clear),
                                        label: const Text('Effacer'),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                        if (userId != null && drafts.isNotEmpty)
                          _DraftSection(
                            drafts: drafts,
                            onEdit: (post) => _openComposer(draft: post),
                            onPublish: (post) => _confirmPublishDraft(post),
                          ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverLayoutBuilder(
                    builder: (context, constraints) {
                      final posts = _applyFilters(publishedPosts);
                      final isWide = constraints.crossAxisExtent >= 900;
                      if (!isWide) {
                        return _FeedSliverList(
                          posts: posts,
                          userId: userId,
                          isBookmarked: (id) => blogController.isBookmarked(id),
                          onToggleFavorite: (postId) => blogController.toggleFavorite(
                            postId: postId,
                            userId: userId!,
                          ),
                          onToggleReaction: (postId) => blogController.toggleReaction(
                            postId: postId,
                            userId: userId!,
                            reactionType: 'like',
                          ),
                          onToggleBookmark: (post) => blogController.toggleBookmark(
                            post: post,
                            userId: userId!,
                          ),
                          pressedPostId: _pressedPostId,
                          onPressChanged: (pressed, id) =>
                              setState(() => _pressedPostId = pressed ? id : null),
                        );
                      }

                      // Faux masonry: split into two columns by running total height heuristic
                      final left = <BlogPost>[];
                      final right = <BlogPost>[];
                      double hLeft = 0, hRight = 0;
                      for (final p in posts) {
                        final estHeight = 140.0 +
                            (p.media.isNotEmpty ? 120.0 : 0) +
                            (p.content.length.clamp(0, 240) / 12.0);
                        if (hLeft <= hRight) {
                          left.add(p);
                          hLeft += estHeight;
                        } else {
                          right.add(p);
                          hRight += estHeight;
                        }
                      }

                      return SliverToBoxAdapter(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                children: left
                                    .map((post) => Padding(
                                          padding: const EdgeInsets.only(bottom: 12),
                                          child: KeyedSubtree(
                                            key: ValueKey(post.id),
                                            child: _buildCardFor(post, userId, blogController),
                                          ),
                                        ))
                                    .toList(),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                children: right
                                    .map((post) => Padding(
                                          padding: const EdgeInsets.only(bottom: 12),
                                          child: KeyedSubtree(
                                            key: ValueKey(post.id),
                                            child: _buildCardFor(post, userId, blogController),
                                          ),
                                        ))
                                    .toList(),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<BlogPost> _applyFilters(List<BlogPost> source) {
    final title = _searchTitle;
    final type = _selectedTypeFilter;
    final tagList = _searchTags.isEmpty
        ? const <String>[]
        : _searchTags
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();

    return source.where((post) {
      if (type != 'all' && post.postType != type) return false;

      if (title.isNotEmpty &&
          !post.title.toLowerCase().contains(title)) {
        return false;
      }

      if (tagList.isNotEmpty) {
        final postTagsLower = post.tags.map((t) => t.toLowerCase()).toSet();
        final allMatch = tagList.every((t) => postTagsLower.contains(t));
        if (!allMatch) return false;
      }

      return true;
    }).toList();
  }

  Widget _buildCardFor(BlogPost post, String? userId, BlogController blogController) {
    final reaction = userId == null
        ? null
        : post.reactions
            .where((r) => r.userId == userId)
            .map((r) => r.type)
            .cast<String?>()
            .firstWhere((_) => true, orElse: () => null);
    final favorited = userId != null && post.favoritedBy.contains(userId);

    return _BlogPostCard(
      post: post,
      typeLabel: _postTypeLabels[post.postType] ?? 'Discussion',
      userReaction: reaction,
      isFavorited: favorited,
      isBookmarked: blogController.isBookmarked(post.id),
      isPressed: _pressedPostId == post.id,
      onPressChanged: (pressed) =>
          setState(() => _pressedPostId = pressed ? post.id : null),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => BlogPostScreen(postId: post.id),
          ),
        );
      },
      onToggleFavorite: userId == null
          ? null
          : () => blogController.toggleFavorite(
                postId: post.id,
                userId: userId,
              ),
      onToggleReaction: userId == null
          ? null
          : () => blogController.toggleReaction(
                postId: post.id,
                userId: userId,
                reactionType: 'like',
              ),
      onToggleBookmark: userId == null
          ? null
          : () => blogController.toggleBookmark(
                post: post,
                userId: userId,
              ),
    );
  }
 
}

class _FeedSliverList extends StatelessWidget {
  final List<BlogPost> posts;
  final String? userId;
  final bool Function(String) isBookmarked;
  final void Function(String) onToggleFavorite;
  final void Function(String) onToggleReaction;
  final void Function(BlogPost) onToggleBookmark;
  final String? pressedPostId;
  final void Function(bool, String) onPressChanged;

  const _FeedSliverList({
    required this.posts,
    required this.userId,
    required this.isBookmarked,
    required this.onToggleFavorite,
    required this.onToggleReaction,
    required this.onToggleBookmark,
    required this.pressedPostId,
    required this.onPressChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) {
      return const SliverToBoxAdapter(
        child: _ShimmerFeedPlaceholder(),
      );
    }
    return SliverList.separated(
      itemCount: posts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final post = posts[index];
        final reaction =
            userId == null ? null : post.reactions.where((r) => r.userId == userId).map((r) => r.type).cast<String?>().firstWhere((_) => true, orElse: () => null);
        final favorited = userId != null && post.favoritedBy.contains(userId);

        return KeyedSubtree(
          key: ValueKey(post.id),
          child: _BlogPostCard(
          post: post,
          typeLabel: _BlogFeedScreenState._postTypeLabels[post.postType] ?? 'Discussion',
          userReaction: reaction,
          isFavorited: favorited,
          isBookmarked: isBookmarked(post.id),
          isPressed: pressedPostId == post.id,
          onPressChanged: (pressed) => onPressChanged(pressed, post.id),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => BlogPostScreen(postId: post.id),
              ),
            );
          },
          onToggleFavorite: userId == null ? null : () => onToggleFavorite(post.id),
          onToggleReaction: userId == null ? null : () => onToggleReaction(post.id),
          onToggleBookmark: userId == null ? null : () => onToggleBookmark(post),
        ),
        );
      },
    );
  }
}

class _ShimmerFeedPlaceholder extends StatefulWidget {
  const _ShimmerFeedPlaceholder();

  @override
  State<_ShimmerFeedPlaceholder> createState() => _ShimmerFeedPlaceholderState();
}

class _ShimmerFeedPlaceholderState extends State<_ShimmerFeedPlaceholder>
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
      children: List.generate(3, (i) => i).map((_) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _ShimmerCard(baseColor: base, controller: _controller),
        );
      }).toList(),
    );
  }
}

class _ShimmerCard extends StatelessWidget {
  final Color baseColor;
  final AnimationController controller;

  const _ShimmerCard({required this.baseColor, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Container(
          height: 160,
          decoration: BoxDecoration(
            color: baseColor,
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment(-1.0 + controller.value * 2, 0),
              end: Alignment(1.0 + controller.value * 2, 0),
              colors: [
                baseColor.withOpacity(0.9),
                baseColor.withOpacity(0.7),
                baseColor.withOpacity(0.9),
              ],
              stops: const [0.1, 0.3, 0.4],
            ),
          ),
        );
      },
    );
  }
}

class _DraftSection extends StatelessWidget {
  final List<BlogPost> drafts;
  final ValueChanged<BlogPost> onEdit;
  final Future<void> Function(BlogPost) onPublish;

  const _DraftSection({
    required this.drafts,
    required this.onEdit,
    required this.onPublish,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8, top: 4),
          child: Text(
            'Mes brouillons',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        SizedBox(
          height: 170,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: drafts.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final draft = drafts[index];
              return SizedBox(
                width: 260,
                child: Card(
                  elevation: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          draft.title.isEmpty ? 'Sans titre' : draft.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          draft.updatedAt != null
                              ? 'Mis à jour le ${_formatDate(draft.updatedAt!)}'
                              : 'Créé le ${_formatDate(draft.createdAt)}',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Colors.grey),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: () => onEdit(draft),
                                child: const Text('Continuer'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => onPublish(draft),
                                child: const Text('Publier'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}

class _BlogPostCard extends StatelessWidget {
  final BlogPost post;
  final String typeLabel;
  final String? userReaction;
  final bool isFavorited;
  final bool isBookmarked;
  final bool isPressed;
  final VoidCallback? onTap;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onToggleReaction;
  final VoidCallback? onToggleBookmark;
  final ValueChanged<bool>? onPressChanged;

  const _BlogPostCard({
    required this.post,
    required this.typeLabel,
    required this.userReaction,
    required this.isFavorited,
    required this.isBookmarked,
    this.isPressed = false,
    this.onTap,
    this.onToggleFavorite,
    this.onToggleReaction,
    this.onToggleBookmark,
    this.onPressChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final contentPreview = post.content;

    return AnimatedScale(
      scale: isPressed ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: Card(
        elevation: 2,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          onHighlightChanged: (v) => onPressChanged?.call(v),
          child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      post.title,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  if (onToggleBookmark != null)
                    IconButton(
                      onPressed: onToggleBookmark,
                      icon: Icon(
                        isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                        color:
                            isBookmarked ? theme.colorScheme.primary : null,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  Chip(
                    label: Text(typeLabel),
                    avatar: const Icon(Icons.category, size: 16),
                    visualDensity: VisualDensity.compact,
                  ),
                  if (post.tags.isNotEmpty)
                    ...post.tags.take(4).map(
                          (tag) => Chip(
                            label: Text('#$tag'),
                            backgroundColor:
                                theme.chipTheme.backgroundColor?.withOpacity(0.8),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                ],
              ),
              if (post.media.isNotEmpty) ...[
                const SizedBox(height: 12),
                Hero(
                  tag: 'post-image-${post.id}',
                  child: Material(
                    color: Colors.transparent,
                    child: BlogMediaCarousel(
                      media: post.media,
                      height: 160,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                contentPreview,
                style: theme.textTheme.bodyMedium,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                children: [
                  _AnimatedIconChip(
                    icon: Icons.thumb_up,
                    value: post.reactions.length,
                    isActive: userReaction == 'like',
                    onTap: onToggleReaction,
                  ),
                  _AnimatedIconChip(
                    icon: Icons.comment,
                    value: post.commentsCount,
                    onTap: onTap,
                  ),
                  _AnimatedIconChip(
                    icon: Icons.favorite,
                    value: post.favoritedBy.length,
                    isActive: isFavorited,
                    onTap: onToggleFavorite,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Par ${post.authorName}',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }
}

class _IconChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback? onTap;

  const _IconChip({
    required this.icon,
    required this.label,
    this.isActive = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? Theme.of(context).colorScheme.primary : null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
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
    );
  }
}

class _AnimatedIconChip extends StatefulWidget {
  final IconData icon;
  final int value;
  final bool isActive;
  final VoidCallback? onTap;

  const _AnimatedIconChip({
    required this.icon,
    required this.value,
    this.isActive = false,
    this.onTap,
  });

  @override
  State<_AnimatedIconChip> createState() => _AnimatedIconChipState();
}

class _AnimatedIconChipState extends State<_AnimatedIconChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 160),
      lowerBound: 0.9,
      upperBound: 1.0,
    )..value = 1.0;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _tap() async {
    await _controller.reverse();
    await _controller.forward();
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isActive ? Theme.of(context).colorScheme.primary : null;

    return ScaleTransition(
      scale: _controller,
      child: InkWell(
        onTap: _tap,
        borderRadius: BorderRadius.circular(16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(widget.icon, size: 18, color: color),
            const SizedBox(width: 4),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: Text(
                '${widget.value}',
                key: ValueKey(widget.value),
                style: TextStyle(color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onCreatePost;

  const _EmptyState({required this.onCreatePost});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.forum, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Aucune publication pour le moment.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onCreatePost,
              child: const Text('Créer la première publication'),
            ),
          ],
        ),
      ),
    );
  }
}



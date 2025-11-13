import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../controllers/blog_controller.dart';
import '../models/blog_bookmark.dart';
import '../widgets/blog_media_carousel.dart';
import 'blog_post_screen.dart';

class BookmarksScreen extends StatelessWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes favoris'),
      ),
      body: Consumer2<BlogController, AuthController>(
        builder: (context, blogController, authController, _) {
          final bookmarks = blogController.bookmarks;
          final currentUser = authController.currentUser;

          if (currentUser == null) {
            return const Center(
              child: Text('Connectez-vous pour accéder à vos favoris.'),
            );
          }

          if (bookmarks.isEmpty) {
            return const _EmptyBookmarks();
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final bookmark = bookmarks[index];
              return _BookmarkCard(
                bookmark: bookmark,
                onOpen: bookmark.post == null
                    ? null
                    : () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => BlogPostScreen(
                              postId: bookmark.post!.id,
                            ),
                          ),
                        );
                      },
                onRemove: () => blogController.removeBookmark(
                  postId: bookmark.postId,
                  userId: currentUser.id,
                ),
              );
            },
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemCount: bookmarks.length,
          );
        },
      ),
    );
  }
}

class _BookmarkCard extends StatelessWidget {
  final BlogBookmark bookmark;
  final VoidCallback? onOpen;
  final VoidCallback onRemove;

  const _BookmarkCard({
    required this.bookmark,
    required this.onOpen,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final post = bookmark.post;

    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      bookmark.title,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Retirer des favoris',
                    onPressed: onRemove,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                bookmark.savedAt != null
                    ? 'Enregistré le ${_formatDate(bookmark.savedAt!)}'
                    : 'Date inconnue',
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
              const SizedBox(height: 12),
              if (post?.media.isNotEmpty == true)
                BlogMediaCarousel(
                  media: post!.media,
                  height: 160,
                )
              else if (post?.imageUrl != null && post!.imageUrl!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    post.imageUrl!,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                )
              else
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: const Text('Aucun média'),
                ),
              const SizedBox(height: 12),
              Text(
                post?.content ?? 'La publication originale n\'est plus disponible.',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium,
              ),
              if (post?.tags.isNotEmpty == true) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: post!.tags
                      .map((tag) => Chip(label: Text('#$tag')))
                      .toList(),
                ),
              ],
              const SizedBox(height: 8),
              if (post != null)
                Text(
                  'Par ${post.authorName}',
                  style: theme.textTheme.bodySmall,
                ),
              if (onOpen == null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'La publication n\'est plus accessible.',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.error),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}

class _EmptyBookmarks extends StatelessWidget {
  const _EmptyBookmarks();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bookmark_border, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Aucune publication enregistrée.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Ajoutez vos articles favoris depuis le flux communautaire.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}







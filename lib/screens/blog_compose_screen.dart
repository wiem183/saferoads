import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../controllers/blog_controller.dart';
import '../models/blog_media.dart';
import '../models/blog_post.dart';
import '../utils/validators.dart';
import '../widgets/blog_media_carousel.dart';

class BlogComposeScreen extends StatefulWidget {
  final BlogPost? existingPost;

  const BlogComposeScreen({super.key, this.existingPost});

  @override
  State<BlogComposeScreen> createState() => _BlogComposeScreenState();
}

class _BlogComposeScreenState extends State<BlogComposeScreen> {
  static const List<MapEntry<String, String>> _postTypeOptions = [
    MapEntry('general', 'Discussion générale'),
    MapEntry('safety_tip', 'Conseil sécurité'),
    MapEntry('incident_report', 'Retour d\'incident'),
    MapEntry('news', 'Actualité'),
  ];
  static const int _maxMedia = 6;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  late String _postType;
  late List<BlogMedia> _media;
  bool _isSubmitting = false;
  bool _isUploadingMedia = false;

  BlogPost? get _existing => widget.existingPost;
  bool get _isEditing => _existing != null;

  @override
  void initState() {
    super.initState();
    final existing = _existing;
    _postType = existing?.postType ?? BlogPost.defaultPostType;
    _media = List<BlogMedia>.from(existing?.media ?? const []);
    _titleController.text = existing?.title ?? '';
    _contentController.text = existing?.content ?? '';
    _tagsController.text =
        existing != null && existing.tags.isNotEmpty ? existing.tags.join(', ') : '';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _pickImageSingle() async {
    final controller = context.read<BlogController>();
    try {
      setState(() => _isUploadingMedia = true);
      if (_media.length >= _maxMedia) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Nombre maximum de médias atteint')),
          );
        }
        return;
      }

      final file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (file == null) return;

      final media = await controller.uploadImageMedia(File(file.path));
      if (media != null) {
        setState(() => _media.add(media));
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Échec de l\'upload de l\'image. Réessayez.')),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingMedia = false);
      }
    }
  }

  List<String> _parseTags() {
    final raw = _tagsController.text.trim();
    if (raw.isEmpty) return [];
    return raw
        .split(',')
        .map((tag) => tag.trim().toLowerCase())
        .where((tag) => tag.isNotEmpty)
        .toSet()
        .toList();
  }

  Future<void> _handleSubmit({required bool asDraft}) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    final blogController = context.read<BlogController>();
    final authController = context.read<AuthController>();
    final currentUser = authController.currentUser;
    final tags = _parseTags();
    final tagValidation = Validators.validateTagList(tags);
    if (tagValidation != null) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tagValidation)),
        );
      }
      return;
    }

    final mediaValidation =
        Validators.validateMediaCount(_media.length, max: _maxMedia);
    if (mediaValidation != null) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mediaValidation)),
        );
      }
      return;
    }
    final now = DateTime.now();
    bool success = false;

    try {
      if (_isEditing) {
        final existing = _existing!;
        final updated = existing.copyWith(
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          tags: tags,
          media: List<BlogMedia>.from(_media),
          imageUrl: _media.isNotEmpty ? _media.first.url : null,
          postType: _postType,
          updatedAt: now,
          isDraft: asDraft,
          publishedAt: asDraft
              ? null
              : (existing.publishedAt == null ? now : existing.publishedAt),
        );
        success = await blogController.updatePost(updated);
      } else {
        if (currentUser == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Veuillez vous connecter pour publier.'),
              ),
            );
          }
          return;
        }

        final newPost = BlogPost(
          id: '',
          authorId: currentUser.id,
          authorName: currentUser.name,
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          imageUrl: _media.isNotEmpty ? _media.first.url : null,
          createdAt: now,
          postType: _postType,
          tags: tags,
          media: List<BlogMedia>.from(_media),
          isDraft: asDraft,
          publishedAt: asDraft ? null : now,
        );
        final id = await blogController.createPost(newPost);
        success = id != null;
      }

      if (!mounted) return;
      if (success) {
        Navigator.of(context).pop(asDraft ? 'draft' : 'published');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Modifier la publication' : 'Nouvelle publication'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  value: _postType,
                  decoration: const InputDecoration(
                    labelText: 'Type de publication',
                  ),
                  items: _postTypeOptions
                      .map(
                        (option) => DropdownMenuItem<String>(
                          value: option.key,
                          child: Text(option.value),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _postType = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Titre',
                  ),
                  validator: Validators.validateBlogTitle,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _contentController,
                  decoration: const InputDecoration(
                    labelText: 'Contenu',
                    alignLabelWithHint: true,
                  ),
                  minLines: 5,
                  maxLines: 10,
                  validator: (value) => Validators.validateBlogContent(value, minLength: 20),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _tagsController,
                  decoration: const InputDecoration(
                    labelText: 'Tags (séparés par des virgules)',
                    hintText: 'ex: sécurité, signalisation',
                  ),
                  validator: Validators.validateBlogTagsInput,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _isUploadingMedia ? null : _pickImageSingle,
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Ajouter une image'),
                    ),
                    if (_isUploadingMedia) ...[
                      const SizedBox(width: 12),
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                if (_media.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Aperçu (${_media.length})',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      BlogMediaCarousel(media: _media, height: 200),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _media
                            .map(
                              (item) => Chip(
                                label: Text(item.type.toUpperCase()),
                                avatar: const Icon(Icons.insert_photo, size: 18),
                                onDeleted: _isSubmitting
                                    ? null
                                    : () => setState(
                                          () => _media.removeWhere((m) => m.id == item.id),
                                        ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSubmitting ? null : () => _handleSubmit(asDraft: true),
                        child: const Text('Enregistrer le brouillon'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : () => _handleSubmit(asDraft: false),
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Publier'),
                      ),
                    ),
                  ],
                ),
                if (_isEditing && _existing?.isDraft == true)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: isDark ? Colors.amberAccent : Colors.blueGrey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Cette publication est actuellement enregistrée en brouillon.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}



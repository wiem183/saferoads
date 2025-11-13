import 'package:flutter/material.dart';

import '../models/blog_media.dart';

class BlogMediaCarousel extends StatefulWidget {
  final List<BlogMedia> media;
  final double height;
  final BorderRadius borderRadius;

  const BlogMediaCarousel({
    super.key,
    required this.media,
    this.height = 200,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
  });

  @override
  State<BlogMediaCarousel> createState() => _BlogMediaCarouselState();
}

class _BlogMediaCarouselState extends State<BlogMediaCarousel> {
  late final PageController _controller;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.media.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: widget.height,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: widget.borderRadius,
            child: PageView.builder(
              controller: _controller,
              itemCount: widget.media.length,
              onPageChanged: (index) => setState(() => _currentIndex = index),
              itemBuilder: (context, index) {
                final media = widget.media[index];
                if (media.type == 'image') {
                  return InkWell(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => Dialog(
                          insetPadding: const EdgeInsets.all(16),
                          child: InteractiveViewer(
                            child: Image.network(
                              media.url,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Center(
                                child: Icon(Icons.broken_image, size: 48),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    child: Image.network(
                      media.url,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(Icons.broken_image, size: 48),
                      ),
                    ),
                  );
                }

                return Container(
                  color: Colors.black12,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.videocam, size: 48, color: Colors.white70),
                      const SizedBox(height: 8),
                      Text(
                        'Vidéo non prise en charge',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.white70),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          if (widget.media.length > 1)
            Positioned(
              bottom: 8,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.media.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    height: 6,
                    width: _currentIndex == index ? 16 : 6,
                    decoration: BoxDecoration(
                      color: _currentIndex == index
                          ? Theme.of(context).colorScheme.primary
                          : Colors.white70,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}







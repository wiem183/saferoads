import 'package:covoiturage_app/models/blog_post.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('BlogPost handles legacy documents without new schema fields', () {
    final post = BlogPost.fromJson({
      'id': 'abc123',
      'authorId': 'user1',
      'authorName': 'Alice',
      'title': 'Ancien post',
      'content': 'Contenu simple',
      'createdAt': '2024-01-01T10:00:00.000Z',
    });

    expect(post.postType, equals(BlogPost.defaultPostType));
    expect(post.tags, isEmpty);
    expect(post.media, isEmpty);
    expect(post.isDraft, isFalse);
    expect(post.publishedAt, isNull);
  });
}






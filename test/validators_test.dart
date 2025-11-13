import 'package:covoiturage_app/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Validators.validateBlogTagsInput', () {
    test('accepts empty value', () {
      expect(Validators.validateBlogTagsInput(''), isNull);
    });

    test('rejects too many tags', () {
      final result = Validators.validateBlogTagsInput(
        'a,b,c,d,e,f,g,h,i',
        maxTags: 5,
      );
      expect(result, isNotNull);
    });

    test('rejects invalid characters', () {
      final result = Validators.validateBlogTagsInput('invalid tag');
      expect(result, isNotNull);
    });
  });

  group('Validators.validateMediaCount', () {
    test('allows count under limit', () {
      expect(Validators.validateMediaCount(3, max: 5), isNull);
    });

    test('rejects count over limit', () {
      final result = Validators.validateMediaCount(7, max: 6);
      expect(result, isNotNull);
    });
  });
}






import 'package:flutter_test/flutter_test.dart';
import 'package:mindload/core/youtube_utils.dart';

void main() {
  group('YouTubeUtils', () {
    group('extractYouTubeId', () {
      test('should extract ID from standard watch URLs', () {
        expect(
          YouTubeUtils.extractYouTubeId('https://www.youtube.com/watch?v=dQw4w9WgXcQ'),
          equals('dQw4w9WgXcQ'),
        );
        
        expect(
          YouTubeUtils.extractYouTubeId('https://youtube.com/watch?v=dQw4w9WgXcQ'),
          equals('dQw4w9WgXcQ'),
        );
        
        expect(
          YouTubeUtils.extractYouTubeId('http://www.youtube.com/watch?v=dQw4w9WgXcQ'),
          equals('dQw4w9WgXcQ'),
        );
      });

      test('should extract ID from youtu.be URLs', () {
        expect(
          YouTubeUtils.extractYouTubeId('https://youtu.be/dQw4w9WgXcQ'),
          equals('dQw4w9WgXcQ'),
        );
        
        expect(
          YouTubeUtils.extractYouTubeId('http://youtu.be/dQw4w9WgXcQ'),
          equals('dQw4w9WgXcQ'),
        );
      });

      test('should extract ID from embed URLs', () {
        expect(
          YouTubeUtils.extractYouTubeId('https://www.youtube.com/embed/dQw4w9WgXcQ'),
          equals('dQw4w9WgXcQ'),
        );
        
        expect(
          YouTubeUtils.extractYouTubeId('https://youtube.com/embed/dQw4w9WgXcQ'),
          equals('dQw4w9WgXcQ'),
        );
      });

      test('should extract ID from shorts URLs', () {
        expect(
          YouTubeUtils.extractYouTubeId('https://www.youtube.com/shorts/dQw4w9WgXcQ'),
          equals('dQw4w9WgXcQ'),
        );
        
        expect(
          YouTubeUtils.extractYouTubeId('https://youtube.com/shorts/dQw4w9WgXcQ'),
          equals('dQw4w9WgXcQ'),
        );
      });

      test('should extract ID from URLs with additional parameters', () {
        expect(
          YouTubeUtils.extractYouTubeId('https://www.youtube.com/watch?v=dQw4w9WgXcQ&t=123s'),
          equals('dQw4w9WgXcQ'),
        );
        
        expect(
          YouTubeUtils.extractYouTubeId('https://youtu.be/dQw4w9WgXcQ?t=123'),
          equals('dQw4w9WgXcQ'),
        );
        
        expect(
          YouTubeUtils.extractYouTubeId('https://www.youtube.com/watch?v=dQw4w9WgXcQ&list=PL123&index=1'),
          equals('dQw4w9WgXcQ'),
        );
      });

      test('should extract ID from URLs without protocol', () {
        expect(
          YouTubeUtils.extractYouTubeId('www.youtube.com/watch?v=dQw4w9WgXcQ'),
          equals('dQw4w9WgXcQ'),
        );
        
        expect(
          YouTubeUtils.extractYouTubeId('youtube.com/watch?v=dQw4w9WgXcQ'),
          equals('dQw4w9WgXcQ'),
        );
        
        expect(
          YouTubeUtils.extractYouTubeId('youtu.be/dQw4w9WgXcQ'),
          equals('dQw4w9WgXcQ'),
        );
      });

      test('should handle mixed text with YouTube URLs', () {
        expect(
          YouTubeUtils.extractYouTubeId('Check out this video: https://www.youtube.com/watch?v=dQw4w9WgXcQ'),
          equals('dQw4w9WgXcQ'),
        );
        
        expect(
          YouTubeUtils.extractYouTubeId('Video link: youtu.be/dQw4w9WgXcQ and some other text'),
          equals('dQw4w9WgXcQ'),
        );
      });

      test('should return null for invalid URLs', () {
        expect(YouTubeUtils.extractYouTubeId(''), isNull);
        expect(YouTubeUtils.extractYouTubeId('   '), isNull);
        expect(YouTubeUtils.extractYouTubeId('not a youtube url'), isNull);
        expect(YouTubeUtils.extractYouTubeId('https://example.com'), isNull);
        expect(YouTubeUtils.extractYouTubeId('https://youtube.com'), isNull);
        expect(YouTubeUtils.extractYouTubeId('https://youtube.com/watch'), isNull);
        expect(YouTubeUtils.extractYouTubeId('https://youtube.com/watch?v='), isNull);
        expect(YouTubeUtils.extractYouTubeId('https://youtube.com/watch?v=123'), isNull); // Too short
        expect(YouTubeUtils.extractYouTubeId('https://youtube.com/watch?v=123456789012'), isNull); // Too long
      });

      test('should handle edge cases', () {
        expect(
          YouTubeUtils.extractYouTubeId('https://www.youtube.com/watch?v=dQw4w9WgXcQ&v=anotherID'),
          equals('dQw4w9WgXcQ'),
        );
        
        expect(
          YouTubeUtils.extractYouTubeId('https://www.youtube.com/watch?list=PL123&v=dQw4w9WgXcQ'),
          equals('dQw4w9WgXcQ'),
        );
      });
    });

    group('isYouTubeLink', () {
      test('should return true for valid YouTube URLs', () {
        expect(YouTubeUtils.isYouTubeLink('https://www.youtube.com/watch?v=dQw4w9WgXcQ'), isTrue);
        expect(YouTubeUtils.isYouTubeLink('https://youtu.be/dQw4w9WgXcQ'), isTrue);
        expect(YouTubeUtils.isYouTubeLink('https://www.youtube.com/embed/dQw4w9WgXcQ'), isTrue);
        expect(YouTubeUtils.isYouTubeLink('https://www.youtube.com/shorts/dQw4w9WgXcQ'), isTrue);
      });

      test('should return false for invalid URLs', () {
        expect(YouTubeUtils.isYouTubeLink(''), isFalse);
        expect(YouTubeUtils.isYouTubeLink('not a youtube url'), isFalse);
        expect(YouTubeUtils.isYouTubeLink('https://example.com'), isFalse);
        expect(YouTubeUtils.isYouTubeLink('https://youtube.com'), isFalse);
      });
    });

    group('isValidVideoId', () {
      test('should return true for valid video IDs', () {
        expect(YouTubeUtils.isValidVideoId('dQw4w9WgXcQ'), isTrue);
        expect(YouTubeUtils.isValidVideoId('12345678901'), isTrue);
        expect(YouTubeUtils.isValidVideoId('abc-def_ghi'), isTrue);
        expect(YouTubeUtils.isValidVideoId('ABCDEFGHIJK'), isTrue);
      });

      test('should return false for invalid video IDs', () {
        expect(YouTubeUtils.isValidVideoId(''), isFalse);
        expect(YouTubeUtils.isValidVideoId('1234567890'), isFalse); // Too short
        expect(YouTubeUtils.isValidVideoId('123456789012'), isFalse); // Too long
        expect(YouTubeUtils.isValidVideoId('1234567890!'), isFalse); // Invalid character
        expect(YouTubeUtils.isValidVideoId('1234567890@'), isFalse); // Invalid character
      });
    });

    group('getThumbnailUrl', () {
      test('should generate valid thumbnail URLs', () {
        expect(
          YouTubeUtils.getThumbnailUrl('dQw4w9WgXcQ'),
          equals('https://img.youtube.com/vi/dQw4w9WgXcQ/hqdefault.jpg'),
        );
        
        expect(
          YouTubeUtils.getThumbnailUrl('dQw4w9WgXcQ', quality: 'maxresdefault'),
          equals('https://img.youtube.com/vi/dQw4w9WgXcQ/maxresdefault.jpg'),
        );
      });

      test('should return empty string for invalid video ID', () {
        expect(YouTubeUtils.getThumbnailUrl(''), equals(''));
        expect(YouTubeUtils.getThumbnailUrl('123'), equals(''));
      });

      test('should handle different quality options', () {
        final videoId = 'dQw4w9WgXcQ';
        expect(YouTubeUtils.getThumbnailUrl(videoId, quality: 'default'), contains('default.jpg'));
        expect(YouTubeUtils.getThumbnailUrl(videoId, quality: 'hqdefault'), contains('hqdefault.jpg'));
        expect(YouTubeUtils.getThumbnailUrl(videoId, quality: 'mqdefault'), contains('mqdefault.jpg'));
        expect(YouTubeUtils.getThumbnailUrl(videoId, quality: 'sddefault'), contains('sddefault.jpg'));
        expect(YouTubeUtils.getThumbnailUrl(videoId, quality: 'maxresdefault'), contains('maxresdefault.jpg'));
      });

      test('should fallback to hqdefault for invalid quality', () {
        expect(
          YouTubeUtils.getThumbnailUrl('dQw4w9WgXcQ', quality: 'invalid'),
          equals('https://img.youtube.com/vi/dQw4w9WgXcQ/hqdefault.jpg'),
        );
      });
    });

    group('getEmbedUrl', () {
      test('should generate valid embed URLs', () {
        expect(
          YouTubeUtils.getEmbedUrl('dQw4w9WgXcQ'),
          equals('https://www.youtube.com/embed/dQw4w9WgXcQ'),
        );
      });

      test('should return empty string for invalid video ID', () {
        expect(YouTubeUtils.getEmbedUrl(''), equals(''));
        expect(YouTubeUtils.getEmbedUrl('123'), equals(''));
      });
    });

    group('getWatchUrl', () {
      test('should generate valid watch URLs', () {
        expect(
          YouTubeUtils.getWatchUrl('dQw4w9WgXcQ'),
          equals('https://www.youtube.com/watch?v=dQw4w9WgXcQ'),
        );
      });

      test('should return empty string for invalid video ID', () {
        expect(YouTubeUtils.getWatchUrl(''), equals(''));
        expect(YouTubeUtils.getWatchUrl('123'), equals(''));
      });
    });

    group('extractChannelId', () {
      test('should extract channel IDs from various formats', () {
        expect(
          YouTubeUtils.extractChannelId('https://www.youtube.com/channel/UC123456789'),
          equals('UC123456789'),
        );
        
        expect(
          YouTubeUtils.extractChannelId('https://www.youtube.com/c/ChannelName'),
          equals('ChannelName'),
        );
        
        expect(
          YouTubeUtils.extractChannelId('https://www.youtube.com/user/username'),
          equals('username'),
        );
      });

      test('should return null for non-channel URLs', () {
        expect(YouTubeUtils.extractChannelId('https://www.youtube.com/watch?v=dQw4w9WgXcQ'), isNull);
        expect(YouTubeUtils.extractChannelId('not a youtube url'), isNull);
      });
    });

    group('isChannelLink', () {
      test('should return true for channel URLs', () {
        expect(YouTubeUtils.isChannelLink('https://www.youtube.com/channel/UC123456789'), isTrue);
        expect(YouTubeUtils.isChannelLink('https://www.youtube.com/c/ChannelName'), isTrue);
        expect(YouTubeUtils.isChannelLink('https://www.youtube.com/user/username'), isTrue);
      });

      test('should return false for non-channel URLs', () {
        expect(YouTubeUtils.isChannelLink('https://www.youtube.com/watch?v=dQw4w9WgXcQ'), isFalse);
        expect(YouTubeUtils.isChannelLink('not a youtube url'), isFalse);
      });
    });

    group('isPlaylistLink', () {
      test('should return true for playlist URLs', () {
        expect(YouTubeUtils.isPlaylistLink('https://www.youtube.com/playlist?list=PL123456789'), isTrue);
      });

      test('should return false for non-playlist URLs', () {
        expect(YouTubeUtils.isPlaylistLink('https://www.youtube.com/watch?v=dQw4w9WgXcQ'), isFalse);
        expect(YouTubeUtils.isPlaylistLink('not a youtube url'), isFalse);
      });
    });

    group('extractPlaylistId', () {
      test('should extract playlist IDs', () {
        expect(
          YouTubeUtils.extractPlaylistId('https://www.youtube.com/playlist?list=PL123456789'),
          equals('PL123456789'),
        );
      });

      test('should return null for non-playlist URLs', () {
        expect(YouTubeUtils.extractPlaylistId('https://www.youtube.com/watch?v=dQw4w9WgXcQ'), isNull);
        expect(YouTubeUtils.extractPlaylistId('not a youtube url'), isNull);
      });
    });
  });
}

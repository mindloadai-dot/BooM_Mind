import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:mindload/core/youtube_utils.dart';

/// Test service for verifying YouTube functionality across platforms
class YouTubeTestService {
  static final YouTubeTestService _instance = YouTubeTestService._internal();
  factory YouTubeTestService() => _instance;
  YouTubeTestService._internal();

  /// Test YouTube URL detection on different platforms
  Future<Map<String, dynamic>> testYouTubeFunctionality() async {
    final results = <String, dynamic>{};

    // Test URLs
    final testUrls = [
      'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
      'https://youtu.be/dQw4w9WgXcQ',
      'https://m.youtube.com/watch?v=dQw4w9WgXcQ',
      'https://www.youtube.com/embed/dQw4w9WgXcQ',
      'https://www.youtube.com/shorts/dQw4w9WgXcQ',
      'https://youtube.com/watch?v=dQw4w9WgXcQ&t=30s',
      'dQw4w9WgXcQ', // Direct video ID
    ];

    results['platform'] = _getPlatformInfo();
    results['testUrls'] = <String, dynamic>{};

    for (final url in testUrls) {
      final videoId = YouTubeUtils.extractYouTubeId(url);
      final isValid = YouTubeUtils.isValidVideoId(videoId ?? '');
      final isVideoUrl = YouTubeUtils.isVideoUrl(url);
      final normalizedUrl = YouTubeUtils.normalizeUrl(url);

      results['testUrls'][url] = {
        'extractedVideoId': videoId,
        'isValidVideoId': isValid,
        'isVideoUrl': isVideoUrl,
        'normalizedUrl': normalizedUrl,
        'thumbnailUrl':
            videoId != null ? YouTubeUtils.getThumbnailUrl(videoId) : null,
        'embedUrl': videoId != null ? YouTubeUtils.getEmbedUrl(videoId) : null,
        'watchUrl': videoId != null ? YouTubeUtils.getWatchUrl(videoId) : null,
        'mobileUrl':
            videoId != null ? YouTubeUtils.getMobileUrl(videoId) : null,
      };
    }

    // Test edge cases
    results['edgeCases'] = <String, dynamic>{
      'emptyString': YouTubeUtils.extractYouTubeId(''),
      'whitespaceOnly': YouTubeUtils.extractYouTubeId('   '),
      'invalidUrl': YouTubeUtils.extractYouTubeId('https://example.com'),
      'channelUrl': YouTubeUtils.isChannelLink(
          'https://www.youtube.com/channel/UC_x5XG1OV2P6uZZ5FSM9Ttw'),
      'playlistUrl': YouTubeUtils.isPlaylistLink(
          'https://www.youtube.com/playlist?list=PLbpi6ZahtOH6BlcNQn_4xIqj0vq41GtSi'),
    };

    return results;
  }

  /// Get platform information
  Map<String, dynamic> _getPlatformInfo() {
    return {
      'isWeb': kIsWeb,
      'isIOS': !kIsWeb && Platform.isIOS,
      'isAndroid': !kIsWeb && Platform.isAndroid,
      'platform': kIsWeb ? 'Web' : Platform.operatingSystem,
      'version': kIsWeb ? 'Web' : Platform.operatingSystemVersion,
    };
  }

  /// Test specific YouTube URL formats
  Future<Map<String, dynamic>> testSpecificFormats() async {
    final results = <String, dynamic>{};

    // Test various YouTube URL formats
    final formatTests = [
      {
        'name': 'Standard Watch URL',
        'url': 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        'expectedId': 'dQw4w9WgXcQ'
      },
      {
        'name': 'Short URL',
        'url': 'https://youtu.be/dQw4w9WgXcQ',
        'expectedId': 'dQw4w9WgXcQ'
      },
      {
        'name': 'Mobile URL',
        'url': 'https://m.youtube.com/watch?v=dQw4w9WgXcQ',
        'expectedId': 'dQw4w9WgXcQ'
      },
      {
        'name': 'Embed URL',
        'url': 'https://www.youtube.com/embed/dQw4w9WgXcQ',
        'expectedId': 'dQw4w9WgXcQ'
      },
      {
        'name': 'Shorts URL',
        'url': 'https://www.youtube.com/shorts/dQw4w9WgXcQ',
        'expectedId': 'dQw4w9WgXcQ'
      },
      {
        'name': 'URL with Parameters',
        'url':
            'https://www.youtube.com/watch?v=dQw4w9WgXcQ&t=30s&feature=share',
        'expectedId': 'dQw4w9WgXcQ'
      },
      {
        'name': 'Direct Video ID',
        'url': 'dQw4w9WgXcQ',
        'expectedId': 'dQw4w9WgXcQ'
      },
    ];

    results['formatTests'] = <String, dynamic>{};

    for (final test in formatTests) {
      final videoId = YouTubeUtils.extractYouTubeId(test['url'] as String);
      final isValid = videoId == test['expectedId'];

      results['formatTests'][test['name'] as String] = {
        'input': test['url'],
        'expectedId': test['expectedId'],
        'actualId': videoId,
        'isValid': isValid,
        'error':
            isValid ? null : 'Expected ${test['expectedId']}, got $videoId',
      };
    }

    return results;
  }

  /// Run comprehensive YouTube functionality test
  Future<Map<String, dynamic>> runComprehensiveTest() async {
    final results = <String, dynamic>{};

    try {
      results['basicFunctionality'] = await testYouTubeFunctionality();
      results['formatTests'] = await testSpecificFormats();
      results['timestamp'] = DateTime.now().toIso8601String();
      results['success'] = true;
    } catch (e) {
      results['error'] = e.toString();
      results['success'] = false;
    }

    return results;
  }
}

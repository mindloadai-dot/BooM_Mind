/// YouTube utilities for extracting video IDs and validating URLs
class YouTubeUtils {
  /// Extract YouTube video ID from various URL formats
  /// Covers watch?v=, youtu.be/, embed/, shorts/, & extra params
  /// Enhanced for better cross-platform compatibility
  static String? extractYouTubeId(String input) {
    if (input.trim().isEmpty) return null;

    // Clean the input - remove extra whitespace and normalize
    final cleanInput = input.trim();

    // Primary regex pattern for common YouTube URL formats
    final rx = RegExp(
      r'(?:https?:\/\/)?(?:www\.|m\.)?(?:youtube\.com\/(?:watch\?v=|embed\/|shorts\/|v\/)|youtu\.be\/)([A-Za-z0-9_-]{11})(?:\?|&|$)',
      caseSensitive: false,
    );

    final match = rx.firstMatch(cleanInput);
    if (match != null) return match.group(1);

    // Enhanced fallback for watch?v=ID buried in query parameters
    try {
      final uri = Uri.parse(cleanInput);
      if (uri.host.contains('youtube') &&
          uri.queryParameters['v']?.length == 11) {
        final videoId = uri.queryParameters['v']!;
        // Additional validation to ensure it's a proper YouTube video ID
        if (_looksLikeYouTubeId(videoId)) {
          return videoId;
        }
      }

      // Handle youtu.be URLs with query parameters
      if (uri.host == 'youtu.be' && uri.pathSegments.isNotEmpty) {
        final pathSegment = uri.pathSegments.first;
        if (pathSegment.length == 11 && _looksLikeYouTubeId(pathSegment)) {
          return pathSegment;
        }
      }
    } catch (_) {
      // Invalid URI format, continue to next fallback
    }

    // Additional fallback for embedded URLs with extra parameters
    final embeddedRx = RegExp(
      r'(?:https?:\/\/)?(?:www\.|m\.)?youtube\.com\/embed\/([A-Za-z0-9_-]{11})',
      caseSensitive: false,
    );

    final embeddedMatch = embeddedRx.firstMatch(cleanInput);
    if (embeddedMatch != null) return embeddedMatch.group(1);

    // Handle mobile YouTube URLs
    final mobileRx = RegExp(
      r'(?:https?:\/\/)?m\.youtube\.com\/watch\?v=([A-Za-z0-9_-]{11})',
      caseSensitive: false,
    );

    final mobileMatch = mobileRx.firstMatch(cleanInput);
    if (mobileMatch != null) return mobileMatch.group(1);

    // Handle YouTube Shorts URLs
    final shortsRx = RegExp(
      r'(?:https?:\/\/)?(?:www\.|m\.)?youtube\.com\/shorts\/([A-Za-z0-9_-]{11})',
      caseSensitive: false,
    );

    final shortsMatch = shortsRx.firstMatch(cleanInput);
    if (shortsMatch != null) return shortsMatch.group(1);

    // Final fallback - only try to extract if the input contains YouTube domain
    // This prevents false positives from random text
    if (cleanInput.toLowerCase().contains('youtube.com') || 
        cleanInput.toLowerCase().contains('youtu.be')) {
      final fallbackRx = RegExp(r'[A-Za-z0-9_-]{11}');
      final fallbackMatch = fallbackRx.firstMatch(cleanInput);
      if (fallbackMatch != null) {
        final potentialId = fallbackMatch.group(0)!;
        // Validate it looks like a YouTube ID
        if (_looksLikeYouTubeId(potentialId)) {
          return potentialId;
        }
      }
    }

    return null;
  }

  /// Check if input contains a valid YouTube link
  static bool isYouTubeLink(String input) {
    return extractYouTubeId(input) != null;
  }

  /// Validate YouTube video ID format (11 characters, alphanumeric + underscore + dash)
  static bool isValidVideoId(String videoId) {
    if (videoId.length != 11) return false;

    final validChars = RegExp(r'^[A-Za-z0-9_-]+$');
    return validChars.hasMatch(videoId);
  }

  /// Less strict validation for YouTube ID - just checks if it looks reasonable
  static bool _looksLikeYouTubeId(String id) {
    if (id.length != 11) return false;

    // Check if it contains mostly alphanumeric characters
    final alphanumericCount = RegExp(r'[A-Za-z0-9]').allMatches(id).length;
    final letterCount = RegExp(r'[A-Za-z]').allMatches(id).length;
    final specialCharCount = RegExp(r'[_-]').allMatches(id).length;

    // Should be mostly alphanumeric with few special characters
    // AND should contain at least some letters (YouTube IDs typically have letters)
    return alphanumericCount >= 8 && specialCharCount <= 3 && letterCount >= 2;
  }

  /// Generate YouTube thumbnail URL with fallback quality options
  static String getThumbnailUrl(String videoId,
      {String quality = 'hqdefault'}) {
    if (!isValidVideoId(videoId)) return '';

    final validQualities = [
      'default',
      'hqdefault',
      'mqdefault',
      'sddefault',
      'maxresdefault'
    ];
    final finalQuality =
        validQualities.contains(quality) ? quality : 'hqdefault';

    return 'https://img.youtube.com/vi/$videoId/$finalQuality.jpg';
  }

  /// Generate YouTube embed URL
  static String getEmbedUrl(String videoId) {
    if (!isValidVideoId(videoId)) return '';
    return 'https://www.youtube.com/embed/$videoId';
  }

  /// Generate YouTube watch URL
  static String getWatchUrl(String videoId) {
    if (!isValidVideoId(videoId)) return '';
    return 'https://www.youtube.com/watch?v=$videoId';
  }

  /// Generate mobile-friendly YouTube URL
  static String getMobileUrl(String videoId) {
    if (!isValidVideoId(videoId)) return '';
    return 'https://m.youtube.com/watch?v=$videoId';
  }

  /// Extract channel ID from YouTube URL (if present)
  static String? extractChannelId(String input) {
    final channelRx = RegExp(
      r'(?:https?:\/\/)?(?:www\.|m\.)?youtube\.com\/(?:channel\/|c\/|user\/)([A-Za-z0-9_-]+)',
      caseSensitive: false,
    );

    final match = channelRx.firstMatch(input.trim());
    return match?.group(1);
  }

  /// Check if URL is a YouTube channel link
  static bool isChannelLink(String input) {
    return extractChannelId(input) != null;
  }

  /// Check if URL is a YouTube playlist link
  static bool isPlaylistLink(String input) {
    final playlistRx = RegExp(
      r'(?:https?:\/\/)?(?:www\.|m\.)?youtube\.com\/playlist\?list=([A-Za-z0-9_-]+)',
      caseSensitive: false,
    );

    return playlistRx.hasMatch(input.trim());
  }

  /// Extract playlist ID from YouTube URL
  static String? extractPlaylistId(String input) {
    final playlistRx = RegExp(
      r'(?:https?:\/\/)?(?:www\.|m\.)?youtube\.com\/playlist\?list=([A-Za-z0-9_-]+)',
      caseSensitive: false,
    );

    final match = playlistRx.firstMatch(input.trim());
    return match?.group(1);
  }

  /// Normalize YouTube URL to standard format
  static String normalizeUrl(String input) {
    final videoId = extractYouTubeId(input);
    if (videoId != null) {
      return getWatchUrl(videoId);
    }
    return input;
  }

  /// Check if URL is a valid YouTube video (not channel, playlist, etc.)
  static bool isVideoUrl(String input) {
    final videoId = extractYouTubeId(input);
    if (videoId == null) return false;

    // Exclude channel and playlist URLs
    return !isChannelLink(input) && !isPlaylistLink(input);
  }
}

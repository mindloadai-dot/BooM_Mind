/// YouTube utilities for extracting video IDs and validating URLs
class YouTubeUtils {
  /// Extract YouTube video ID from various URL formats
  /// Covers watch?v=, youtu.be/, embed/, shorts/, & extra params
  static String? extractYouTubeId(String input) {
    if (input.trim().isEmpty) return null;
    
    // Primary regex pattern for common YouTube URL formats
    final rx = RegExp(
      r'(?:https?:\/\/)?(?:www\.)?(?:youtube\.com\/(?:watch\?v=|embed\/|shorts\/)|youtu\.be\/)([A-Za-z0-9_-]{11})',
      caseSensitive: false,
    );
    
    final match = rx.firstMatch(input.trim());
    if (match != null) return match.group(1);
    
    // Fallback for watch?v=ID buried in query parameters
    try {
      final uri = Uri.parse(input.trim());
      if (uri.host.contains('youtube') && uri.queryParameters['v']?.length == 11) {
        return uri.queryParameters['v'];
      }
    } catch (_) {
      // Invalid URI format, continue to next fallback
    }
    
    // Additional fallback for embedded URLs with extra parameters
    final embeddedRx = RegExp(
      r'(?:https?:\/\/)?(?:www\.)?youtube\.com\/embed\/([A-Za-z0-9_-]{11})',
      caseSensitive: false,
    );
    
    final embeddedMatch = embeddedRx.firstMatch(input.trim());
    if (embeddedMatch != null) return embeddedMatch.group(1);
    
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
  
  /// Generate YouTube thumbnail URL
  static String getThumbnailUrl(String videoId, {String quality = 'hqdefault'}) {
    if (!isValidVideoId(videoId)) return '';
    
    final validQualities = ['default', 'hqdefault', 'mqdefault', 'sddefault', 'maxresdefault'];
    final finalQuality = validQualities.contains(quality) ? quality : 'hqdefault';
    
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
  
  /// Extract channel ID from YouTube URL (if present)
  static String? extractChannelId(String input) {
    final channelRx = RegExp(
      r'(?:https?:\/\/)?(?:www\.)?youtube\.com\/(?:channel\/|c\/|user\/)([A-Za-z0-9_-]+)',
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
      r'(?:https?:\/\/)?(?:www\.)?youtube\.com\/playlist\?list=([A-Za-z0-9_-]+)',
      caseSensitive: false,
    );
    
    return playlistRx.hasMatch(input.trim());
  }
  
  /// Extract playlist ID from YouTube URL
  static String? extractPlaylistId(String input) {
    final playlistRx = RegExp(
      r'(?:https?:\/\/)?(?:www\.)?youtube\.com\/playlist\?list=([A-Za-z0-9_-]+)',
      caseSensitive: false,
    );
    
    final match = playlistRx.firstMatch(input.trim());
    return match?.group(1);
  }
}

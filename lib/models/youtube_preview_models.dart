/// YouTube preview data returned from the preview endpoint
class YouTubePreview {
  final String videoId;
  final String title;
  final String channel;
  final int durationSeconds;
  final String thumbnail;
  final bool captionsAvailable;
  final String? primaryLang;
  final int estimatedTokens;
  final int estimatedMindLoadTokens;
  final bool blocked;
  final String? blockReason;
  final YouTubeLimits limits;

  const YouTubePreview({
    required this.videoId,
    required this.title,
    required this.channel,
    required this.durationSeconds,
    required this.thumbnail,
    required this.captionsAvailable,
    this.primaryLang,
    required this.estimatedTokens,
    required this.estimatedMindLoadTokens,
    required this.blocked,
    this.blockReason,
    required this.limits,
  });

  factory YouTubePreview.fromJson(Map<String, dynamic> json) {
    return YouTubePreview(
      videoId: json['videoId'] as String,
      title: json['title'] as String,
      channel: json['channel'] as String,
      durationSeconds: json['durationSeconds'] as int,
      thumbnail: json['thumbnail'] as String,
      captionsAvailable: json['captionsAvailable'] as bool,
      primaryLang: json['primaryLang'] as String?,
      estimatedTokens: json['estimatedTokens'] as int,
      estimatedMindLoadTokens: json['estimatedMindLoadTokens'] as int,
      blocked: json['blocked'] as bool,
      blockReason: json['blockReason'] as String?,
      limits: YouTubeLimits.fromJson(json['limits'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'videoId': videoId,
      'title': title,
      'channel': channel,
      'durationSeconds': durationSeconds,
      'thumbnail': thumbnail,
      'captionsAvailable': captionsAvailable,
      'primaryLang': primaryLang,
      'estimatedTokens': estimatedTokens,
      'estimatedMindLoadTokens': estimatedMindLoadTokens,
      'blocked': blocked,
      'blockReason': blockReason,
      'limits': limits.toJson(),
    };
  }

  /// Format duration as HH:MM:SS
  String get formattedDuration {
    final hours = durationSeconds ~/ 3600;
    final minutes = (durationSeconds % 3600) ~/ 60;
    final seconds = durationSeconds % 60;
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  /// Check if user can proceed with ingest
  bool get canProceed => !blocked && captionsAvailable;

  /// Get status pill text
  String get statusText {
    if (!captionsAvailable) return 'No transcript found';
    if (primaryLang != null) return 'Transcript detected • ${primaryLang!.toUpperCase()}';
    return 'Transcript detected';
  }

  /// Get status pill color
  String get statusColor {
    if (!captionsAvailable) return 'warning';
    if (blocked) return 'error';
    return 'success';
  }

  /// Create a copy of this object with the given fields replaced
  YouTubePreview copyWith({
    String? videoId,
    String? title,
    String? channel,
    int? durationSeconds,
    String? thumbnail,
    bool? captionsAvailable,
    String? primaryLang,
    int? estimatedTokens,
    int? estimatedMindLoadTokens,
    bool? blocked,
    String? blockReason,
    YouTubeLimits? limits,
  }) {
    return YouTubePreview(
      videoId: videoId ?? this.videoId,
      title: title ?? this.title,
      channel: channel ?? this.channel,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      thumbnail: thumbnail ?? this.thumbnail,
      captionsAvailable: captionsAvailable ?? this.captionsAvailable,
      primaryLang: primaryLang ?? this.primaryLang,
      estimatedTokens: estimatedTokens ?? this.estimatedTokens,
      estimatedMindLoadTokens: estimatedMindLoadTokens ?? this.estimatedMindLoadTokens,
      blocked: blocked ?? this.blocked,
      blockReason: blockReason ?? this.blockReason,
      limits: limits ?? this.limits,
    );
  }
}

/// YouTube limits and plan information
class YouTubeLimits {
  final int maxDurationSeconds;
  final String plan;
  final int monthlyYoutubeIngests;
  final int youtubeIngestsRemaining;

  const YouTubeLimits({
    required this.maxDurationSeconds,
    required this.plan,
    required this.monthlyYoutubeIngests,
    required this.youtubeIngestsRemaining,
  });

  factory YouTubeLimits.fromJson(Map<String, dynamic> json) {
    return YouTubeLimits(
      maxDurationSeconds: json['maxDurationSeconds'] as int,
      plan: json['plan'] as String,
      monthlyYoutubeIngests: json['monthlyYoutubeIngests'] as int,
      youtubeIngestsRemaining: json['youtubeIngestsRemaining'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'maxDurationSeconds': maxDurationSeconds,
      'plan': plan,
      'monthlyYoutubeIngests': monthlyYoutubeIngests,
      'youtubeIngestsRemaining': youtubeIngestsRemaining,
    };
  }

  /// Check if video duration is within plan limits
  bool get isWithinDurationLimit => maxDurationSeconds > 0;

  /// Get formatted max duration
  String get formattedMaxDuration {
    final hours = maxDurationSeconds ~/ 3600;
    final minutes = (maxDurationSeconds % 3600) ~/ 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }
}

/// YouTube ingest request
class YouTubeIngestRequest {
  final String videoId;
  final String? preferredLanguage;

  const YouTubeIngestRequest({
    required this.videoId,
    this.preferredLanguage,
  });

  Map<String, dynamic> toJson() {
    return {
      'videoId': videoId,
      if (preferredLanguage != null) 'preferredLanguage': preferredLanguage,
    };
  }
}

/// YouTube ingest response
class YouTubeIngestResponse {
  final String materialId;
  final String status;
  final String? error;
  final int mlTokensCharged;
  final int inputTokens;

  const YouTubeIngestResponse({
    required this.materialId,
    required this.status,
    this.error,
    required this.mlTokensCharged,
    required this.inputTokens,
  });

  factory YouTubeIngestResponse.fromJson(Map<String, dynamic> json) {
    return YouTubeIngestResponse(
      materialId: json['materialId'] as String,
      status: json['status'] as String,
      error: json['error'] as String?,
      mlTokensCharged: json['mlTokensCharged'] as int,
      inputTokens: json['inputTokens'] as int,
    );
  }

  bool get isSuccess => status == 'processed' || status == 'already_exists';
  bool get isAlreadyExists => status == 'already_exists';
}

/// YouTube ingest error types
enum YouTubeIngestError {
  invalidUrl,
  noTranscript,
  transcriptUnavailable,
  overPlanLimit,
  insufficientTokens,
  overBudget,
  videoNotFound,
  videoPrivate,
  videoAgeRestricted,
  videoRemoved,
  networkError,
  serverError,
  unknown,
}

/// Extension to get error messages
extension YouTubeIngestErrorExtension on YouTubeIngestError {
  String get message {
    switch (this) {
      case YouTubeIngestError.invalidUrl:
        return 'Invalid YouTube URL or video ID';
      case YouTubeIngestError.noTranscript:
        return 'No transcript available for this video';
      case YouTubeIngestError.transcriptUnavailable:
        return 'Transcript is not available';
      case YouTubeIngestError.overPlanLimit:
        return 'Video exceeds your plan duration limit';
      case YouTubeIngestError.insufficientTokens:
        return 'Insufficient MindLoad Tokens';
      case YouTubeIngestError.overBudget:
        return 'Over monthly budget limit';
      case YouTubeIngestError.videoNotFound:
        return 'Video not found or removed';
      case YouTubeIngestError.videoPrivate:
        return 'Private video - transcript unavailable';
      case YouTubeIngestError.videoAgeRestricted:
        return 'Age-restricted video - transcript unavailable';
      case YouTubeIngestError.videoRemoved:
        return 'Video has been removed';
      case YouTubeIngestError.networkError:
        return 'Network error - please try again';
      case YouTubeIngestError.serverError:
        return 'Server error - please try again later';
      case YouTubeIngestError.unknown:
        return 'Unknown error occurred';
    }
  }

  String get shortMessage {
    switch (this) {
      case YouTubeIngestError.invalidUrl:
        return 'Invalid URL';
      case YouTubeIngestError.noTranscript:
        return 'No transcript';
      case YouTubeIngestError.transcriptUnavailable:
        return 'Unavailable';
      case YouTubeIngestError.overPlanLimit:
        return 'Over limit';
      case YouTubeIngestError.insufficientTokens:
        return 'No tokens';
      case YouTubeIngestError.overBudget:
        return 'Over budget';
      case YouTubeIngestError.videoNotFound:
        return 'Not found';
      case YouTubeIngestError.videoPrivate:
        return 'Private';
      case YouTubeIngestError.videoAgeRestricted:
        return 'Age restricted';
      case YouTubeIngestError.videoRemoved:
        return 'Removed';
      case YouTubeIngestError.networkError:
        return 'Network error';
      case YouTubeIngestError.serverError:
        return 'Server error';
      case YouTubeIngestError.unknown:
        return 'Error';
    }
  }
}

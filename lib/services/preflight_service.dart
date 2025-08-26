import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mindload/services/mindload_token_service.dart';
import 'package:mindload/services/auth_service.dart'; // Added import for AuthService

/// Preflight request model
class PreflightRequest {
  final String sourceType; // 'text', 'pdf', 'youtube'
  final int? words;
  final int? minutes;
  final bool? hasCaptions;
  final String depth; // 'quick', 'standard', 'deep'
  final String? sourceId; // For YouTube videos, PDFs, etc.

  PreflightRequest({
    required this.sourceType,
    this.words,
    this.minutes,
    this.hasCaptions,
    required this.depth,
    this.sourceId,
  });

  Map<String, dynamic> toJson() {
    return {
      'sourceType': sourceType,
      'words': words,
      'minutes': minutes,
      'hasCaptions': hasCaptions,
      'depth': depth,
      'sourceId': sourceId,
    };
  }
}

/// Preflight response model
class PreflightResponse {
  final int tokensRequired;
  final List<String> warnings;
  final String preflightId;
  final bool isValid;
  final String? error;

  PreflightResponse({
    required this.tokensRequired,
    required this.warnings,
    required this.preflightId,
    required this.isValid,
    this.error,
  });

  factory PreflightResponse.fromJson(Map<String, dynamic> json) {
    return PreflightResponse(
      tokensRequired: json['tokensRequired'] ?? 0,
      warnings: List<String>.from(json['warnings'] ?? []),
      preflightId: json['preflightId'] ?? '',
      isValid: json['isValid'] ?? false,
      error: json['error'],
    );
  }

  factory PreflightResponse.error(String error) {
    return PreflightResponse(
      tokensRequired: 0,
      warnings: [],
      preflightId: '',
      isValid: false,
      error: error,
    );
  }
}

/// Preflight Service
/// Handles token estimation and validation before operations
class PreflightService {
  static final PreflightService _instance = PreflightService._internal();
  factory PreflightService() => _instance;
  PreflightService._internal();

  final MindloadTokenService _tokenService = MindloadTokenService();
  
  // Base URL for API calls
  static const String _baseUrl = 'https://api.mindload.ai'; // Replace with actual API URL

  /// Perform preflight check for text input
  Future<PreflightResponse> preflightText({
    required String text,
    required String depth,
  }) async {
    final words = text.split(' ').length;
    final tokens = _tokenService.tokensForText(text);
    
    return PreflightResponse(
      tokensRequired: tokens,
      warnings: _generateTextWarnings(text, depth),
      preflightId: _generatePreflightId('text', text, depth),
      isValid: true,
    );
  }

  /// Perform preflight check for YouTube link
  Future<PreflightResponse> preflightYouTube({
    required String videoId,
    required int durationMinutes,
    required bool hasCaptions,
    required String depth,
    String language = 'en',
  }) async {
    final tokens = _tokenService.tokensForYouTube(
      durationMinutes: durationMinutes,
      hasCaptions: hasCaptions,
      language: language,
    );

    return PreflightResponse(
      tokensRequired: tokens,
      warnings: _generateYouTubeWarnings(durationMinutes, hasCaptions, depth),
      preflightId: _generatePreflightId('youtube', videoId, depth),
      isValid: true,
    );
  }

  /// Perform preflight check for PDF
  Future<PreflightResponse> preflightPdf({
    required int pageCount,
    required int estimatedWordsPerPage,
    required String depth,
  }) async {
    final tokens = _tokenService.tokensForPdf(pageCount, estimatedWordsPerPage);

    return PreflightResponse(
      tokensRequired: tokens,
      warnings: _generatePdfWarnings(pageCount, depth),
      preflightId: _generatePreflightId('pdf', '$pageCount:$estimatedWordsPerPage', depth),
      isValid: true,
    );
  }

  /// Perform server-side preflight (for complex validation)
  Future<PreflightResponse> serverPreflight(PreflightRequest request) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/preflight'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await _getAuthToken()}',
        },
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return PreflightResponse.fromJson(data);
      } else {
        return PreflightResponse.error('Server error: ${response.statusCode}');
      }
    } catch (e) {
      return PreflightResponse.error('Network error: $e');
    }
  }

  /// Generate warnings for text input
  List<String> _generateTextWarnings(String text, String depth) {
    final warnings = <String>[];
    final words = text.split(' ').length;

    if (words > 10000) {
      warnings.add('Large text detected. Consider breaking into smaller sections.');
    }

    if (depth == 'deep' && words > 5000) {
      warnings.add('Deep analysis on large text may take longer and use more tokens.');
    }

    if (text.length < 50) {
      warnings.add('Very short text may not generate comprehensive content.');
    }

    return warnings;
  }

  /// Generate warnings for YouTube videos
  List<String> _generateYouTubeWarnings(int durationMinutes, bool hasCaptions, String depth) {
    final warnings = <String>[];

    if (durationMinutes > 120) {
      warnings.add('Long video detected. Consider shorter segments for better results.');
    }

    if (!hasCaptions) {
      warnings.add('No captions available. Audio transcription will be used.');
    }

    if (depth == 'deep' && durationMinutes > 60) {
      warnings.add('Deep analysis on long videos may take significant time.');
    }

    return warnings;
  }

  /// Generate warnings for PDFs
  List<String> _generatePdfWarnings(int pageCount, String depth) {
    final warnings = <String>[];

    if (pageCount > 50) {
      warnings.add('Large PDF detected. Consider processing in sections.');
    }

    if (depth == 'deep' && pageCount > 20) {
      warnings.add('Deep analysis on large PDFs may take significant time.');
    }

    return warnings;
  }

  /// Generate preflight ID for tracking
  String _generatePreflightId(String sourceType, String sourceId, String depth) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final data = '$sourceType:$sourceId:$depth:$timestamp';
    return _tokenService.generateSourceHash(
      sourceId: data,
      depth: depth,
    );
  }

  /// Get authentication token (implement based on your auth system)
  Future<String> _getAuthToken() async {
    // Get actual auth token from AuthService
    try {
      final authService = AuthService.instance;
      if (authService.currentUser != null) {
        return authService.currentUser!.uid;
      }
      return '';
    } catch (e) {
      return '';
    }
  }

  /// Validate preflight response
  bool isValidPreflight(PreflightResponse response) {
    return response.isValid && 
           response.tokensRequired > 0 && 
           response.preflightId.isNotEmpty;
  }

  /// Check if user can proceed with operation
  bool canProceed(PreflightResponse response, int availableTokens) {
    return isValidPreflight(response) && 
           _tokenService.canAfford(response.tokensRequired, availableTokens);
  }
}

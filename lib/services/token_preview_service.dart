import 'package:mindload/models/pricing_models.dart';
import 'package:mindload/services/token_service.dart';
import 'package:mindload/services/auth_service.dart';

class TokenPreviewService {
  static final TokenPreviewService _instance = TokenPreviewService._internal();
  static TokenPreviewService get instance => _instance;

  TokenPreviewService._internal();

  // Constant copy snippets
  static const String TOKEN_EQUIVALENCE = "1 token ≈ 1,000 words or ~5 minutes of YouTube.";

  // Preview for text generation
  Future<TokenConsumptionPreview> previewTextGeneration({
    required int wordCount,
    bool useWelcomeBonus = true,
  }) async {
    final requiredTokens = TokenPricingRules.calculateTextGenerationTokens(wordCount);
    return _generatePreview(
      requiredTokens: requiredTokens,
      actionType: 'text_generation',
      details: {
        'words': wordCount,
        'sets': 1,
      },
      useWelcomeBonus: useWelcomeBonus,
    );
  }

  // Preview for YouTube ingest
  Future<TokenConsumptionPreview> previewYouTubeIngest({
    required String videoUrl,
    required int durationMinutes,
    bool useWelcomeBonus = true,
  }) async {
    // Validate YouTube URL
    if (!_isValidYouTubeUrl(videoUrl)) {
      return TokenConsumptionPreview(
        isValid: false,
        errorMessage: 'Invalid YouTube URL. Use youtube.com/watch?v=… or youtu.be/…',
      );
    }

    final requiredTokens = TokenPricingRules.calculateYouTubeTokens(durationMinutes);
    return _generatePreview(
      requiredTokens: requiredTokens,
      actionType: 'youtube_ingest',
      details: {
        'minutes': durationMinutes,
        'videoUrl': videoUrl,
      },
      useWelcomeBonus: useWelcomeBonus,
    );
  }

  // Preview for regenerating content
  Future<TokenConsumptionPreview> previewRegenerate({
    required int itemCount, 
    required bool isCards,
    bool useWelcomeBonus = true,
  }) async {
    final requiredTokens = TokenPricingRules.calculateRegenerateTokens(itemCount, isCards);
    return _generatePreview(
      requiredTokens: requiredTokens,
      actionType: 'regenerate',
      details: {
        'items': itemCount,
        'type': isCards ? 'cards' : 'mcqs',
        'sets': isCards 
          ? (itemCount / TokenPricingRules.CARD_SET_SIZE).ceil() 
          : (itemCount / TokenPricingRules.MCQ_SET_SIZE).ceil(),
      },
      useWelcomeBonus: useWelcomeBonus,
    );
  }

  // Preview for reorganizing content
  Future<TokenConsumptionPreview> previewReorganize({
    required int setCount,
    bool useWelcomeBonus = true,
  }) async {
    final requiredTokens = TokenPricingRules.calculateReorganizeTokens(setCount);
    return _generatePreview(
      requiredTokens: requiredTokens,
      actionType: 'reorganize',
      details: {
        'sets': setCount,
      },
      useWelcomeBonus: useWelcomeBonus,
    );
  }

  // Internal method to generate preview
  Future<TokenConsumptionPreview> _generatePreview({
    required int requiredTokens,
    required String actionType,
    required Map<String, dynamic> details,
    bool useWelcomeBonus = true,
  }) async {
    final user = AuthService.instance.currentUser;
    if (user == null) {
      return TokenConsumptionPreview(
        isValid: false,
        errorMessage: 'User not authenticated',
      );
    }

    // Fetch user's token account
    final tokenAccount = await TokenService.instance.fetchUserTokenAccount(user.uid);

    // Determine available free actions and welcome bonus
    final freeActionsLeft = tokenAccount.freeActions;
    final hasWelcomeBonus = useWelcomeBonus && tokenAccount.welcomeBonus > 0;
    final monthlyTokens = tokenAccount.monthlyTokens;

    // Calculate token consumption
    int tokensToConsume = requiredTokens;
    int balanceBefore = monthlyTokens;
    int balanceAfter = balanceBefore;
    int freeActionsUsed = 0;
    bool usingWelcomeBonus = false;

    // Consume free actions first
    if (freeActionsLeft >= tokensToConsume) {
      freeActionsUsed = tokensToConsume;
      tokensToConsume = 0;
    } else if (freeActionsLeft > 0) {
      tokensToConsume -= freeActionsLeft;
      freeActionsUsed = freeActionsLeft;
    }

    // Use welcome bonus if enabled and free actions insufficient
    if (tokensToConsume > 0 && hasWelcomeBonus) {
      usingWelcomeBonus = true;
      balanceAfter = (balanceBefore - tokensToConsume).clamp(0, balanceBefore);
    }

    return TokenConsumptionPreview(
      isValid: true,
      requiredTokens: requiredTokens,
      freeActionsLeft: freeActionsLeft - freeActionsUsed,
      actionType: actionType,
      details: details,
      balanceBefore: balanceBefore,
      balanceAfter: balanceAfter,
      freeActionsUsed: freeActionsUsed,
      usingWelcomeBonus: usingWelcomeBonus,
    );
  }

  // YouTube URL validation
  bool _isValidYouTubeUrl(String url) {
    final youtubeRegex = RegExp(
      r'^(https?\:\/\/)?(www\.youtube\.com\/watch\?v=|youtu\.be\/)([a-zA-Z0-9_-]{11})',
      caseSensitive: false,
    );
    return youtubeRegex.hasMatch(url);
  }
}

class TokenConsumptionPreview {
  final bool isValid;
  final String? errorMessage;
  final int requiredTokens;
  final int freeActionsLeft;
  final String actionType;
  final Map<String, dynamic> details;
  final int balanceBefore;
  final int balanceAfter;
  final int freeActionsUsed;
  final bool usingWelcomeBonus;

  const TokenConsumptionPreview({
    this.isValid = true,
    this.errorMessage,
    this.requiredTokens = 0,
    this.freeActionsLeft = 0,
    this.actionType = '',
    this.details = const {},
    this.balanceBefore = 0,
    this.balanceAfter = 0,
    this.freeActionsUsed = 0,
    this.usingWelcomeBonus = false,
  });

  // Generate human-readable preview text
  String get previewText {
    if (!isValid) return errorMessage ?? 'Invalid token preview';

    final List<String> previewParts = [];

    // Action-specific preview
    switch (actionType) {
      case 'text_generation':
        previewParts.add('Requested ${details['words']} words → $requiredTokens token(s).');
        break;
      case 'youtube_ingest':
        previewParts.add('Duration ~${details['minutes']} min → $requiredTokens token(s).');
        break;
      case 'regenerate':
        final type = details['type'] == 'cards' ? 'cards' : 'MCQs';
        previewParts.add('Requested ${details['items']} $type (~${details['sets']} set(s)) → $requiredTokens token(s).');
        break;
      case 'reorganize':
        previewParts.add('Re-organizing ${details['sets']} set(s) → $requiredTokens token(s).');
        break;
    }

    // Free actions and welcome bonus
    if (freeActionsUsed > 0) {
      previewParts.add('Free actions used: $freeActionsUsed');
      previewParts.add('Free actions left: $freeActionsLeft/20');
    }

    if (usingWelcomeBonus) {
      previewParts.add('Using Welcome Bonus');
    }

    // Balance change
    if (balanceBefore != balanceAfter) {
      previewParts.add('Balance: $balanceBefore → $balanceAfter');
    }

    return previewParts.join(' ');
  }
}

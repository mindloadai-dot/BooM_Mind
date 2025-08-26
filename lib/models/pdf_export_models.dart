

// PDF export options
class PdfExportOptions {
  final String setId;
  final bool includeFlashcards;
  final bool includeQuiz;
  final String style; // 'compact', 'standard', 'spaced'
  final String pageSize; // 'Letter', 'A4'
  final bool includeMindloadBranding; // Control MindLoad branding inclusion
  final int? maxPages; // override default limit
  final int? maxFileSizeMB; // override default limit

  const PdfExportOptions({
    required this.setId,
    this.includeFlashcards = true,
    this.includeQuiz = true,
    this.style = 'standard',
    this.pageSize = 'A4',
    this.includeMindloadBranding = true, // Default to true for branding
    this.maxPages,
    this.maxFileSizeMB,
  });

  // Create from JSON
  factory PdfExportOptions.fromJson(Map<String, dynamic> json) {
    return PdfExportOptions(
      setId: json['setId'] as String,
      includeFlashcards: json['includeFlashcards'] as bool? ?? true,
      includeQuiz: json['includeQuiz'] as bool? ?? true,
      style: json['style'] as String? ?? 'standard',
      pageSize: json['pageSize'] as String? ?? 'A4',
      includeMindloadBranding: json['includeMindloadBranding'] as bool? ?? true,
      maxPages: json['maxPages'] as int?,
      maxFileSizeMB: json['maxFileSizeMB'] as int?,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'setId': setId,
      'includeFlashcards': includeFlashcards,
      'includeQuiz': includeQuiz,
      'style': style,
      'pageSize': pageSize,
      'includeMindloadBranding': includeMindloadBranding,
      'maxPages': maxPages,
      'maxFileSizeMB': maxFileSizeMB,
    };
  }

  // Get effective max pages
  int get effectiveMaxPages => maxPages ?? 300;

  // Get effective max file size in bytes
  int get effectiveMaxFileSizeBytes => (maxFileSizeMB ?? 25) * 1024 * 1024;

  // Create a copy with updated values
  PdfExportOptions copyWith({
    String? setId,
    bool? includeFlashcards,
    bool? includeQuiz,
    String? style,
    String? pageSize,
    bool? includeMindloadBranding,
    int? maxPages,
    int? maxFileSizeMB,
  }) {
    return PdfExportOptions(
      setId: setId ?? this.setId,
      includeFlashcards: includeFlashcards ?? this.includeFlashcards,
      includeQuiz: includeQuiz ?? this.includeQuiz,
      style: style ?? this.style,
      pageSize: pageSize ?? this.pageSize,
      includeMindloadBranding: includeMindloadBranding ?? this.includeMindloadBranding,
      maxPages: maxPages ?? this.maxPages,
      maxFileSizeMB: maxFileSizeMB ?? this.maxFileSizeMB,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PdfExportOptions &&
        other.setId == setId &&
        other.includeFlashcards == includeFlashcards &&
        other.includeQuiz == includeQuiz &&
        other.style == style &&
        other.pageSize == pageSize &&
        other.includeMindloadBranding == includeMindloadBranding &&
        other.maxPages == maxPages &&
        other.maxFileSizeMB == maxFileSizeMB;
  }

  @override
  int get hashCode {
    return Object.hash(
      setId,
      includeFlashcards,
      includeQuiz,
      style,
      pageSize,
      includeMindloadBranding,
      maxPages,
      maxFileSizeMB,
    );
  }

  @override
  String toString() {
    return 'PdfExportOptions(setId: $setId, includeFlashcards: $includeFlashcards, includeQuiz: $includeQuiz, style: $style, pageSize: $pageSize, includeMindloadBranding: $includeMindloadBranding, maxPages: $maxPages, maxFileSizeMB: $maxFileSizeMB)';
  }
}

// PDF export progress
class PdfExportProgress {
  final int currentPage;
  final int totalPages;
  final int currentItem;
  final int totalItems;
  final String currentOperation; // 'processing', 'rendering', 'compressing'
  final double percentage;
  final DateTime startedAt;

  const PdfExportProgress({
    required this.currentPage,
    required this.totalPages,
    required this.currentItem,
    required this.totalItems,
    required this.currentOperation,
    required this.percentage,
    required this.startedAt,
  });

  // Create from JSON
  factory PdfExportProgress.fromJson(Map<String, dynamic> json) {
    return PdfExportProgress(
      currentPage: json['currentPage'] as int? ?? 0,
      totalPages: json['totalPages'] as int? ?? 0,
      currentItem: json['currentItem'] as int? ?? 0,
      totalItems: json['totalItems'] as int? ?? 0,
      currentOperation: json['currentOperation'] as String? ?? 'processing',
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
      startedAt: DateTime.parse(json['startedAt'] as String),
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'currentPage': currentPage,
      'totalPages': totalPages,
      'currentItem': currentItem,
      'totalItems': totalItems,
      'currentOperation': currentOperation,
      'percentage': percentage,
      'startedAt': startedAt.toIso8601String(),
    };
  }

  // Create a copy with updated values
  PdfExportProgress copyWith({
    int? currentPage,
    int? totalPages,
    int? currentItem,
    int? totalItems,
    String? currentOperation,
    double? percentage,
    DateTime? startedAt,
  }) {
    return PdfExportProgress(
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      currentItem: currentItem ?? this.currentItem,
      totalItems: totalItems ?? this.totalItems,
      currentOperation: currentOperation ?? this.currentOperation,
      percentage: percentage ?? this.percentage,
      startedAt: startedAt ?? this.startedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PdfExportProgress &&
        other.currentPage == currentPage &&
        other.totalPages == totalPages &&
        other.currentItem == currentItem &&
        other.totalItems == totalItems &&
        other.currentOperation == currentOperation &&
        other.percentage == percentage &&
        other.startedAt == startedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      currentPage,
      totalPages,
      currentItem,
      totalItems,
      currentOperation,
      percentage,
      startedAt,
    );
  }

  @override
  String toString() {
    return 'PdfExportProgress(currentPage: $currentPage/$totalPages, currentItem: $currentItem/$totalItems, operation: $currentOperation, ${(percentage * 100).toStringAsFixed(1)}%, startedAt: $startedAt)';
  }
}

// PDF export result
class PdfExportResult {
  final bool success;
  final String? filePath;
  final int? pages;
  final int? bytes;
  final String? checksum;
  final String? errorCode;
  final String? errorMessage;
  final Duration duration;

  const PdfExportResult({
    required this.success,
    this.filePath,
    this.pages,
    this.bytes,
    this.checksum,
    this.errorCode,
    this.errorMessage,
    required this.duration,
  });

  // Create a copy with updated values
  PdfExportResult copyWith({
    bool? success,
    String? filePath,
    int? pages,
    int? bytes,
    String? checksum,
    String? errorCode,
    String? errorMessage,
    Duration? duration,
  }) {
    return PdfExportResult(
      success: success ?? this.success,
      filePath: filePath ?? this.filePath,
      pages: pages ?? this.pages,
      bytes: bytes ?? this.bytes,
      checksum: checksum ?? this.checksum,
      errorCode: errorCode ?? this.errorCode,
      errorMessage: errorMessage ?? this.errorMessage,
      duration: duration ?? this.duration,
    );
  }

  // Success result
  factory PdfExportResult.success({
    required String filePath,
    required int pages,
    required int bytes,
    required String checksum,
    required Duration duration,
  }) {
    return PdfExportResult(
      success: true,
      filePath: filePath,
      pages: pages,
      bytes: bytes,
      checksum: checksum,
      duration: duration,
    );
  }

  // Failure result
  factory PdfExportResult.failure({
    required String errorCode,
    required String errorMessage,
    required Duration duration,
  }) {
    return PdfExportResult(
      success: false,
      errorCode: errorCode,
      errorMessage: errorMessage,
      duration: duration,
    );
  }

  // Create from JSON
  factory PdfExportResult.fromJson(Map<String, dynamic> json) {
    return PdfExportResult(
      success: json['success'] as bool? ?? false,
      filePath: json['filePath'] as String?,
      pages: json['pages'] as int?,
      bytes: json['bytes'] as int?,
      checksum: json['checksum'] as String?,
      errorCode: json['errorCode'] as String?,
      errorMessage: json['errorMessage'] as String?,
      duration: Duration(milliseconds: json['durationMs'] as int? ?? 0),
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'filePath': filePath,
      'pages': pages,
      'bytes': bytes,
      'checksum': checksum,
      'errorCode': errorCode,
      'errorMessage': errorMessage,
      'durationMs': duration.inMilliseconds,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PdfExportResult &&
        other.success == success &&
        other.filePath == filePath &&
        other.pages == pages &&
        other.bytes == bytes &&
        other.checksum == checksum &&
        other.errorCode == errorCode &&
        other.errorMessage == errorMessage &&
        other.duration == duration;
  }

  @override
  int get hashCode {
    return Object.hash(
      success,
      filePath,
      pages,
      bytes,
      checksum,
      errorCode,
      errorMessage,
      duration,
    );
  }

  @override
  String toString() {
    if (success) {
      return 'PdfExportResult.success(filePath: $filePath, pages: $pages, bytes: $bytes, checksum: $checksum, duration: $duration)';
    } else {
      return 'PdfExportResult.failure(errorCode: $errorCode, errorMessage: $errorMessage, duration: $duration)';
    }
  }
}

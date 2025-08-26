import 'package:flutter/foundation.dart';

// PDF export audit record
class PdfAuditRecord {
  final String auditId;
  final String uid; // hashed/opaque user ID
  final String setId;
  final String appVersion;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final Map<String, int> itemCounts; // { 'cards': number, 'questions': number }
  final String style;
  final String pageSize;
  final int? pages;
  final int? bytes;
  final String? checksum; // sha256 of final PDF
  final String status; // 'started', 'success', 'failed', 'cancelled'
  final String? errorCode;
  final String? errorMessage;

  const PdfAuditRecord({
    required this.auditId,
    required this.uid,
    required this.setId,
    required this.appVersion,
    required this.startedAt,
    this.finishedAt,
    required this.itemCounts,
    required this.style,
    required this.pageSize,
    this.pages,
    this.bytes,
    this.checksum,
    required this.status,
    this.errorCode,
    this.errorMessage,
  });

  // Create from JSON
  factory PdfAuditRecord.fromJson(Map<String, dynamic> json) {
    return PdfAuditRecord(
      auditId: json['auditId'] as String,
      uid: json['uid'] as String,
      setId: json['setId'] as String,
      appVersion: json['appVersion'] as String,
      startedAt: DateTime.parse(json['startedAt'] as String),
      finishedAt: json['finishedAt'] != null 
          ? DateTime.parse(json['finishedAt'] as String) 
          : null,
      itemCounts: Map<String, int>.from(json['itemCounts'] as Map),
      style: json['style'] as String,
      pageSize: json['pageSize'] as String,
      pages: json['pages'] as int?,
      bytes: json['bytes'] as int?,
      checksum: json['checksum'] as String?,
      status: json['status'] as String,
      errorCode: json['errorCode'] as String?,
      errorMessage: json['errorMessage'] as String?,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'auditId': auditId,
      'uid': uid,
      'setId': setId,
      'appVersion': appVersion,
      'startedAt': startedAt.toIso8601String(),
      'finishedAt': finishedAt?.toIso8601String(),
      'itemCounts': itemCounts,
      'style': style,
      'pageSize': pageSize,
      'pages': pages,
      'bytes': bytes,
      'checksum': checksum,
      'status': status,
      'errorCode': errorCode,
      'errorMessage': errorMessage,
    };
  }

  // Create a copy with updated values
  PdfAuditRecord copyWith({
    String? auditId,
    String? uid,
    String? setId,
    String? appVersion,
    DateTime? startedAt,
    DateTime? finishedAt,
    Map<String, int>? itemCounts,
    String? style,
    String? pageSize,
    int? pages,
    int? bytes,
    String? checksum,
    String? status,
    String? errorCode,
    String? errorMessage,
  }) {
    return PdfAuditRecord(
      auditId: auditId ?? this.auditId,
      uid: uid ?? this.uid,
      setId: setId ?? this.setId,
      appVersion: appVersion ?? this.appVersion,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      itemCounts: itemCounts ?? this.itemCounts,
      style: style ?? this.style,
      pageSize: pageSize ?? this.pageSize,
      pages: pages ?? this.pages,
      bytes: bytes ?? this.bytes,
      checksum: checksum ?? this.checksum,
      status: status ?? this.status,
      errorCode: errorCode ?? this.errorCode,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  // Mark as started
  factory PdfAuditRecord.started({
    required String auditId,
    required String uid,
    required String setId,
    required String appVersion,
    required Map<String, int> itemCounts,
    required String style,
    required String pageSize,
  }) {
    return PdfAuditRecord(
      auditId: auditId,
      uid: uid,
      setId: setId,
      appVersion: appVersion,
      startedAt: DateTime.now(),
      itemCounts: itemCounts,
      style: style,
      pageSize: pageSize,
      status: 'started',
    );
  }

  // Mark as successful
  PdfAuditRecord markSuccess({
    required int pages,
    required int bytes,
    required String checksum,
  }) {
    return copyWith(
      status: 'success',
      finishedAt: DateTime.now(),
      pages: pages,
      bytes: bytes,
      checksum: checksum,
    );
  }

  // Mark as failed
  PdfAuditRecord markFailed({
    required String errorCode,
    required String errorMessage,
  }) {
    return copyWith(
      status: 'failed',
      finishedAt: DateTime.now(),
      errorCode: errorCode,
      errorMessage: errorMessage,
    );
  }

  // Mark as cancelled
  PdfAuditRecord markCancelled() {
    return copyWith(
      status: 'cancelled',
      finishedAt: DateTime.now(),
    );
  }

  // Get duration
  Duration? get duration {
    if (finishedAt == null) return null;
    return finishedAt!.difference(startedAt);
  }

  // Get total items
  int get totalItems {
    return itemCounts.values.fold(0, (sum, count) => sum + count);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PdfAuditRecord &&
        other.auditId == auditId &&
        other.uid == uid &&
        other.setId == setId &&
        other.appVersion == appVersion &&
        other.startedAt == startedAt &&
        other.finishedAt == finishedAt &&
        mapEquals(other.itemCounts, itemCounts) &&
        other.style == style &&
        other.pageSize == pageSize &&
        other.pages == pages &&
        other.bytes == bytes &&
        other.checksum == checksum &&
        other.status == status &&
        other.errorCode == errorCode &&
        other.errorMessage == errorMessage;
  }

  @override
  int get hashCode {
    return Object.hash(
      auditId,
      uid,
      setId,
      appVersion,
      startedAt,
      finishedAt,
      Object.hashAll(itemCounts.values),
      style,
      pageSize,
      pages,
      bytes,
      checksum,
      status,
      errorCode,
      errorMessage,
    );
  }

  @override
  String toString() {
    return 'PdfAuditRecord(auditId: $auditId, setId: $setId, status: $status, pages: $pages, bytes: $bytes, duration: $duration)';
  }
}

// PDF audit service interface
abstract class PdfAuditService {
  // Create a new audit record
  Future<PdfAuditRecord> createAuditRecord({
    required String uid,
    required String setId,
    required String appVersion,
    required Map<String, int> itemCounts,
    required String style,
    required String pageSize,
  });

  // Update audit record
  Future<bool> updateAuditRecord(PdfAuditRecord record);

  // Get audit records for user
  Future<List<PdfAuditRecord>> getAuditRecords(String uid);

  // Clean up old audit records
  Future<int> cleanupOldRecords(String uid);

  // Get audit statistics
  Future<Map<String, dynamic>> getAuditStats(String uid);
}

// In-memory PDF audit service implementation
class InMemoryPdfAuditService implements PdfAuditService {
  final Map<String, List<PdfAuditRecord>> _userAudits = {};
  final int _maxRecordsPerUser = 50;

  @override
  Future<PdfAuditRecord> createAuditRecord({
    required String uid,
    required String setId,
    required String appVersion,
    required Map<String, int> itemCounts,
    required String style,
    required String pageSize,
  }) async {
    final auditId = _generateAuditId();
    final record = PdfAuditRecord.started(
      auditId: auditId,
      uid: uid,
      setId: setId,
      appVersion: appVersion,
      itemCounts: itemCounts,
      style: style,
      pageSize: pageSize,
    );

    // Add to user's audit list
    _userAudits.putIfAbsent(uid, () => []);
    _userAudits[uid]!.add(record);

    // Clean up old records if needed
    await cleanupOldRecords(uid);

    return record;
  }

  @override
  Future<bool> updateAuditRecord(PdfAuditRecord record) async {
    final userAudits = _userAudits[record.uid];
    if (userAudits == null) return false;

    final index = userAudits.indexWhere((r) => r.auditId == record.auditId);
    if (index == -1) return false;

    userAudits[index] = record;
    return true;
  }

  @override
  Future<List<PdfAuditRecord>> getAuditRecords(String uid) async {
    return _userAudits[uid] ?? [];
  }

  @override
  Future<int> cleanupOldRecords(String uid) async {
    final userAudits = _userAudits[uid];
    if (userAudits == null) return 0;

    final initialCount = userAudits.length;
    if (initialCount <= _maxRecordsPerUser) return 0;

    // Remove oldest records (keep most recent)
    userAudits.sort((a, b) => b.startedAt.compareTo(a.startedAt));
    userAudits.removeRange(_maxRecordsPerUser, userAudits.length);

    return initialCount - userAudits.length;
  }

  @override
  Future<Map<String, dynamic>> getAuditStats(String uid) async {
    final userAudits = _userAudits[uid] ?? [];
    
    int totalExports = 0;
    int successfulExports = 0;
    int failedExports = 0;
    int cancelledExports = 0;
    int totalPages = 0;
    int totalBytes = 0;
    Duration totalDuration = Duration.zero;

    for (final audit in userAudits) {
      totalExports++;
      
      switch (audit.status) {
        case 'success':
          successfulExports++;
          totalPages += audit.pages ?? 0;
          totalBytes += audit.bytes ?? 0;
          if (audit.duration != null) {
            totalDuration += audit.duration!;
          }
          break;
        case 'failed':
          failedExports++;
          break;
        case 'cancelled':
          cancelledExports++;
          break;
      }
    }

    return {
      'totalExports': totalExports,
      'successfulExports': successfulExports,
      'failedExports': failedExports,
      'cancelledExports': cancelledExports,
      'totalPages': totalPages,
      'totalBytes': totalBytes,
      'totalDurationMs': totalDuration.inMilliseconds,
      'successRate': totalExports > 0 ? successfulExports / totalExports : 0.0,
    };
  }

  // Generate unique audit ID
  String _generateAuditId() {
    return 'audit_${DateTime.now().millisecondsSinceEpoch}_${_generateRandomString(8)}';
  }

  // Generate random string
  String _generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = DateTime.now().microsecond;
    return String.fromCharCodes(
      Iterable.generate(length, (_) => chars.codeUnitAt(random % chars.length)),
    );
  }

  // Clear all data (for testing)
  void clear() {
    _userAudits.clear();
  }
}

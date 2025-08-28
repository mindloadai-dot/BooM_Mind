
import 'dart:convert';
import 'package:mindload/config/storage_config.dart';
import 'package:mindload/models/study_data.dart';

// Study set metadata for storage management
class StudySetMetadata {
  final String setId;
  final String title;
  final String? content; // Optional content field
  final bool isPinned;
  final int bytes;
  final int items;
  final DateTime lastOpenedAt;
  final DateTime lastStudied; // Add lastStudied property
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isArchived; // archived to cloud but metadata kept locally

  const StudySetMetadata({
    required this.setId,
    required this.title,
    this.content,
    required this.isPinned,
    required this.bytes,
    required this.items,
    required this.lastOpenedAt,
    required this.lastStudied,
    required this.createdAt,
    required this.updatedAt,
    this.isArchived = false,
  });

  // Create from JSON
  factory StudySetMetadata.fromJson(Map<String, dynamic> json) {
    return StudySetMetadata(
      setId: json['setId'] as String,
      title: json['title'] as String,
      content: json['content'] as String?,
      isPinned: json['isPinned'] as bool? ?? false,
      bytes: json['bytes'] as int? ?? 0,
      items: json['items'] as int? ?? 0,
      lastOpenedAt: DateTime.parse(json['lastOpenedAt'] as String),
      lastStudied: DateTime.parse(json['lastStudied'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      isArchived: json['isArchived'] as bool? ?? false,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'setId': setId,
      'title': title,
      'content': content,
      'isPinned': isPinned,
      'bytes': bytes,
      'items': items,
      'lastOpenedAt': lastOpenedAt.toIso8601String(),
      'lastStudied': lastStudied.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isArchived': isArchived,
    };
  }

  // Create a copy with updated values
  StudySetMetadata copyWith({
    String? setId,
    String? title,
    String? content,
    bool? isPinned,
    int? bytes,
    int? items,
    DateTime? lastOpenedAt,
    DateTime? lastStudied,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isArchived,
  }) {
    return StudySetMetadata(
      setId: setId ?? this.setId,
      title: title ?? this.title,
      content: content ?? this.content,
      isPinned: isPinned ?? this.isPinned,
      bytes: bytes ?? this.bytes,
      items: items ?? this.items,
      lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
      lastStudied: lastStudied ?? this.lastStudied,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isArchived: isArchived ?? this.isArchived,
    );
  }

  // Update last opened timestamp
  StudySetMetadata markOpened() {
    return copyWith(
      lastOpenedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  // Factory method to create StudySet from metadata
  factory StudySetMetadata.fromStudySet(StudySet studySet) {
    final content = studySet.content.isNotEmpty ? studySet.content : null;
    final totalItems = studySet.flashcards.length + studySet.quizzes.length;
    final bytes = jsonEncode(studySet.toJson()).length;
    
    return StudySetMetadata(
      setId: studySet.id,
      title: studySet.title,
      content: content,
      isPinned: false,
      bytes: bytes,
      items: totalItems,
      lastOpenedAt: studySet.lastStudied,
      lastStudied: studySet.lastStudied,
      createdAt: studySet.createdAt ?? studySet.createdDate,
      updatedAt: studySet.updatedAt ?? studySet.lastStudied,
      isArchived: false,
    );
  }
  // Note: This creates a minimal StudySet - full data should be loaded separately
  Map<String, dynamic> toStudySetData() {
    return {
      'id': setId,
      'title': title,
      'content': content ?? '',
      'flashcards': [],
      'quizQuestions': [],
      'quizzes': [],
      'createdDate': createdAt.toIso8601String(),
      'lastStudied': lastStudied.toIso8601String(),
      'notificationsEnabled': true,
      'deadlineDate': null,
      'category': null,
      'description': null,
      'sourceType': null,
      'sourceLength': null,
      'tags': [],
      'isArchived': isArchived,
    };
  }



  // Toggle pin status
  StudySetMetadata togglePin() {
    return copyWith(
      isPinned: !isPinned,
      updatedAt: DateTime.now(),
    );
  }

  // Mark as archived
  StudySetMetadata markArchived() {
    return copyWith(
      isArchived: true,
      updatedAt: DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StudySetMetadata &&
        other.setId == setId &&
        other.title == title &&
        other.isPinned == isPinned &&
        other.bytes == bytes &&
        other.items == items &&
        other.lastOpenedAt == lastOpenedAt &&
        other.lastStudied == lastStudied &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.isArchived == isArchived;
  }

  @override
  int get hashCode {
    return Object.hash(
      setId,
      title,
      isPinned,
      bytes,
      items,
      lastOpenedAt,
      lastStudied,
      createdAt,
      updatedAt,
      isArchived,
    );
  }

  @override
  String toString() {
    return 'StudySetMetadata(setId: $setId, title: $title, isPinned: $isPinned, bytes: $bytes, items: $items, lastOpenedAt: $lastOpenedAt, lastStudied: $lastStudied, isArchived: $isArchived)';
  }
}

// Storage totals for monitoring
class StorageTotals {
  final int totalBytes;
  final int totalSets;
  final int totalItems;
  final DateTime lastUpdated;

  StorageTotals({
    required this.totalBytes,
    required this.totalSets,
    required this.totalItems,
    required this.lastUpdated,
  });

  // Create from JSON
  factory StorageTotals.fromJson(Map<String, dynamic> json) {
    return StorageTotals(
      totalBytes: json['totalBytes'] as int? ?? 0,
      totalSets: json['totalSets'] as int? ?? 0,
      totalItems: json['totalItems'] as int? ?? 0,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'totalBytes': totalBytes,
      'totalSets': totalSets,
      'totalItems': totalItems,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  // Create a copy with updated values
  StorageTotals copyWith({
    int? totalBytes,
    int? totalSets,
    int? totalItems,
    DateTime? lastUpdated,
  }) {
    return StorageTotals(
      totalBytes: totalBytes ?? this.totalBytes,
      totalSets: totalSets ?? this.totalSets,
      totalItems: totalItems ?? this.totalItems,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  // Get usage percentage
  double getUsagePercentage(int budgetMB) {
    final budgetBytes = budgetMB * 1024 * 1024;
    if (budgetBytes == 0) return 0.0;
    return totalBytes / budgetBytes;
  }

  // Check if over any limits
  bool isOverAnyLimit(int budgetMB) {
    return totalBytes > (budgetMB * 1024 * 1024) ||
           totalSets > StorageConfig.maxLocalSets ||
           totalItems > StorageConfig.maxLocalItems;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StorageTotals &&
        other.totalBytes == totalBytes &&
        other.totalSets == totalSets &&
        other.totalItems == totalItems &&
        other.lastUpdated == lastUpdated;
  }

  @override
  int get hashCode {
    return Object.hash(totalBytes, totalSets, totalItems, lastUpdated);
  }

  @override
  String toString() {
    return 'StorageTotals(totalBytes: $totalBytes, totalSets: $totalSets, totalItems: $totalItems, lastUpdated: $lastUpdated)';
  }
}

// Eviction result
class EvictionResult {
  final int freedBytes;
  final int evictedSets;
  final List<String> evictedSetIds;

  const EvictionResult({
    required this.freedBytes,
    required this.evictedSets,
    required this.evictedSetIds,
  });

  @override
  String toString() {
    return 'EvictionResult(freedBytes: $freedBytes, evictedSets: $evictedSets, evictedSetIds: $evictedSetIds)';
  }
}

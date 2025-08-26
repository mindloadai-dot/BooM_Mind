import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// Define DayPart enum here to avoid circular dependency
enum DayPart { morning, midday, afternoon, evening, late }

enum NotificationStyle { cram, coach, mindful, toughLove }
enum NotificationCategory { studyNow, streakSave, examAlert, inactivityNudge, eventTrigger, promotional }
enum Platform { ios, android }
enum ConsentType { essential, promotional, analytics, marketing }

class TimeWindow {
  final String start;
  final String end;

  const TimeWindow({
    required this.start,
    required this.end,
  });

  Map<String, dynamic> toJson() => {
    'start': start,
    'end': end,
  };

  factory TimeWindow.fromJson(Map<String, dynamic> json) => TimeWindow(
    start: json['start'] as String,
    end: json['end'] as String,
  );

  @override
  bool operator ==(Object other) =>
    identical(this, other) ||
    other is TimeWindow &&
    runtimeType == other.runtimeType &&
    start == other.start &&
    end == other.end;

  @override
  int get hashCode => start.hashCode ^ end.hashCode;
}

class QuietHours {
  final String start;
  final String end;

  const QuietHours({
    required this.start,
    required this.end,
  });

  Map<String, dynamic> toJson() => {
    'start': start,
    'end': end,
  };

  factory QuietHours.fromJson(Map<String, dynamic> json) => QuietHours(
    start: json['start'] as String,
    end: json['end'] as String,
  );

  @override
  bool operator ==(Object other) =>
    identical(this, other) ||
    other is QuietHours &&
    runtimeType == other.runtimeType &&
    start == other.start &&
    end == other.end;

  @override
  int get hashCode => start.hashCode ^ end.hashCode;
}

class ExamEntry {
  final String course;
  final DateTime examDate;

  const ExamEntry({
    required this.course,
    required this.examDate,
  });

  Map<String, dynamic> toJson() => {
    'course': course,
    'examDate': Timestamp.fromDate(examDate),
  };

  factory ExamEntry.fromJson(Map<String, dynamic> json) => ExamEntry(
    course: json['course'] as String,
    examDate: (json['examDate'] as Timestamp).toDate(),
  );

  @override
  bool operator ==(Object other) =>
    identical(this, other) ||
    other is ExamEntry &&
    runtimeType == other.runtimeType &&
    course == other.course &&
    examDate == other.examDate;

  @override
  int get hashCode => course.hashCode ^ examDate.hashCode;
}

class PromotionalConsent {
  final bool hasConsented;
  final DateTime? consentedAt;
  final DateTime? revokedAt;
  final bool canReceive;
  final String consentSource; // 'in_app', 'system_settings'

  const PromotionalConsent({
    required this.hasConsented,
    this.consentedAt,
    this.revokedAt,
    required this.canReceive,
    required this.consentSource,
  });

  factory PromotionalConsent.defaultConsent() => PromotionalConsent(
    hasConsented: false,
    canReceive: false,
    consentSource: 'default',
  );

  Map<String, dynamic> toJson() => {
    'hasConsented': hasConsented,
    'consentedAt': consentedAt != null ? Timestamp.fromDate(consentedAt!) : null,
    'revokedAt': revokedAt != null ? Timestamp.fromDate(revokedAt!) : null,
    'canReceive': canReceive,
    'consentSource': consentSource,
  };

  factory PromotionalConsent.fromJson(Map<String, dynamic> json) => PromotionalConsent(
    hasConsented: json['hasConsented'] as bool? ?? false,
    consentedAt: json['consentedAt'] != null ? (json['consentedAt'] as Timestamp).toDate() : null,
    revokedAt: json['revokedAt'] != null ? (json['revokedAt'] as Timestamp).toDate() : null,
    canReceive: json['canReceive'] as bool? ?? false,
    consentSource: json['consentSource'] as String? ?? 'default',
  );

  PromotionalConsent copyWith({
    bool? hasConsented,
    DateTime? consentedAt,
    DateTime? revokedAt,
    bool? canReceive,
    String? consentSource,
  }) => PromotionalConsent(
    hasConsented: hasConsented ?? this.hasConsented,
    consentedAt: consentedAt ?? this.consentedAt,
    revokedAt: revokedAt ?? this.revokedAt,
    canReceive: canReceive ?? this.canReceive,
    consentSource: consentSource ?? this.consentSource,
  );
}

class NotificationPermissionStatus {
  final bool systemPermissionGranted;
  final bool appNotificationsEnabled;
  final DateTime? lastChecked;
  final bool gracefulDegradationActive;

  const NotificationPermissionStatus({
    required this.systemPermissionGranted,
    required this.appNotificationsEnabled,
    this.lastChecked,
    required this.gracefulDegradationActive,
  });

  factory NotificationPermissionStatus.defaultStatus() => NotificationPermissionStatus(
    systemPermissionGranted: false,
    appNotificationsEnabled: true,
    gracefulDegradationActive: false,
  );

  Map<String, dynamic> toJson() => {
    'systemPermissionGranted': systemPermissionGranted,
    'appNotificationsEnabled': appNotificationsEnabled,
    'lastChecked': lastChecked != null ? Timestamp.fromDate(lastChecked!) : null,
    'gracefulDegradationActive': gracefulDegradationActive,
  };

  factory NotificationPermissionStatus.fromJson(Map<String, dynamic> json) => NotificationPermissionStatus(
    systemPermissionGranted: json['systemPermissionGranted'] as bool? ?? false,
    appNotificationsEnabled: json['appNotificationsEnabled'] as bool? ?? true,
    lastChecked: json['lastChecked'] != null ? (json['lastChecked'] as Timestamp).toDate() : null,
    gracefulDegradationActive: json['gracefulDegradationActive'] as bool? ?? false,
  );

  NotificationPermissionStatus copyWith({
    bool? systemPermissionGranted,
    bool? appNotificationsEnabled,
    DateTime? lastChecked,
    bool? gracefulDegradationActive,
  }) => NotificationPermissionStatus(
    systemPermissionGranted: systemPermissionGranted ?? this.systemPermissionGranted,
    appNotificationsEnabled: appNotificationsEnabled ?? this.appNotificationsEnabled,
    lastChecked: lastChecked ?? this.lastChecked,
    gracefulDegradationActive: gracefulDegradationActive ?? this.gracefulDegradationActive,
  );
}

class NotificationAnalytics {
  final int opens;
  final int dismissals;
  final DateTime? lastOpenAt;
  final int streakDays;

  const NotificationAnalytics({
    required this.opens,
    required this.dismissals,
    this.lastOpenAt,
    required this.streakDays,
  });

  Map<String, dynamic> toJson() => {
    'opens': opens,
    'dismissals': dismissals,
    'lastOpenAt': lastOpenAt != null ? Timestamp.fromDate(lastOpenAt!) : null,
    'streakDays': streakDays,
  };

  factory NotificationAnalytics.fromJson(Map<String, dynamic> json) => NotificationAnalytics(
    opens: json['opens'] as int? ?? 0,
    dismissals: json['dismissals'] as int? ?? 0,
    lastOpenAt: json['lastOpenAt'] != null ? (json['lastOpenAt'] as Timestamp).toDate() : null,
    streakDays: json['streakDays'] as int? ?? 0,
  );

  NotificationAnalytics copyWith({
    int? opens,
    int? dismissals,
    DateTime? lastOpenAt,
    int? streakDays,
  }) => NotificationAnalytics(
    opens: opens ?? this.opens,
    dismissals: dismissals ?? this.dismissals,
    lastOpenAt: lastOpenAt ?? this.lastOpenAt,
    streakDays: streakDays ?? this.streakDays,
  );
}

class PushToken {
  final String token;
  final Platform platform;
  final DateTime createdAt;

  const PushToken({
    required this.token,
    required this.platform,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'token': token,
    'platform': platform.name,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  factory PushToken.fromJson(Map<String, dynamic> json) => PushToken(
    token: json['token'] as String,
    platform: Platform.values.firstWhere((p) => p.name == json['platform']),
    createdAt: (json['createdAt'] as Timestamp).toDate(),
  );
}

class UserNotificationPreferences {
  final String uid;
  final NotificationStyle notificationStyle;
  final int frequencyPerDay;
  final Set<NotificationCategory> enabledCategories;
  final List<DayPart> selectedDayparts;
  final bool quietHours;
  final TimeOfDay quietStart;
  final TimeOfDay quietEnd;
  final bool eveningDigest;
  final TimeOfDay digestTime;
  final bool stoEnabled;
  final bool timeSensitive;
  final String timezone;
  final List<ExamEntry> exams;
  final NotificationAnalytics analytics;
  final List<PushToken> pushTokens;
  final PromotionalConsent promotionalConsent;
  final NotificationPermissionStatus permissionStatus;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Legacy fields for backward compatibility
  final List<TimeWindow> timeWindows;
  final bool allowTimeSensitive;

  const UserNotificationPreferences({
    required this.uid,
    required this.notificationStyle,
    required this.frequencyPerDay,
    this.enabledCategories = const {},
    this.selectedDayparts = const [],
    this.quietHours = true,
    this.quietStart = const TimeOfDay(hour: 22, minute: 0),
    this.quietEnd = const TimeOfDay(hour: 7, minute: 0),
    this.eveningDigest = true,
    this.digestTime = const TimeOfDay(hour: 20, minute: 30),
    this.stoEnabled = true,
    this.timeSensitive = false,
    required this.timezone,
    required this.exams,
    required this.analytics,
    required this.pushTokens,
    required this.promotionalConsent,
    required this.permissionStatus,
    required this.createdAt,
    required this.updatedAt,
    // Legacy fields
    this.timeWindows = const [],
    this.allowTimeSensitive = false,
  });

  factory UserNotificationPreferences.defaultPreferences(String uid) => UserNotificationPreferences(
    uid: uid,
    notificationStyle: NotificationStyle.coach,
    frequencyPerDay: 1,
    // ALL NOTIFICATION CATEGORIES AUTOMATICALLY ENABLED - No user toggles
    enabledCategories: {
      NotificationCategory.studyNow,
      NotificationCategory.streakSave,
      NotificationCategory.inactivityNudge,
      NotificationCategory.eventTrigger,
    },
    selectedDayparts: [DayPart.evening],
    quietHours: true,
    quietStart: const TimeOfDay(hour: 22, minute: 0),
    quietEnd: const TimeOfDay(hour: 7, minute: 0),
    eveningDigest: true,
    digestTime: const TimeOfDay(hour: 20, minute: 30),
    stoEnabled: true,
    timeSensitive: false,
    timezone: "America/Chicago",
    exams: const [],
    analytics: const NotificationAnalytics(opens: 0, dismissals: 0, streakDays: 0),
    pushTokens: const [],
    promotionalConsent: const PromotionalConsent(hasConsented: false, canReceive: false, consentSource: 'default'),
    permissionStatus: const NotificationPermissionStatus(systemPermissionGranted: false, appNotificationsEnabled: true, gracefulDegradationActive: false),
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    // Legacy fields
    timeWindows: const [
      TimeWindow(start: "08:00", end: "10:00"),
      TimeWindow(start: "13:00", end: "15:00"),
      TimeWindow(start: "17:00", end: "19:00"),
    ],
    allowTimeSensitive: true,
  );

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'notificationStyle': notificationStyle.name,
    'frequencyPerDay': frequencyPerDay,
    'enabledCategories': enabledCategories.map((c) => c.name).toList(),
    'selectedDayparts': selectedDayparts.map((d) => d.name).toList(),
    'quietHours': quietHours,
    'quietStart': {'hour': quietStart.hour, 'minute': quietStart.minute},
    'quietEnd': {'hour': quietEnd.hour, 'minute': quietEnd.minute},
    'eveningDigest': eveningDigest,
    'digestTime': {'hour': digestTime.hour, 'minute': digestTime.minute},
    'stoEnabled': stoEnabled,
    'timeSensitive': timeSensitive,
    'timezone': timezone,
    'exams': exams.map((exam) => exam.toJson()).toList(),
    'analytics': analytics.toJson(),
    'pushTokens': pushTokens.map((token) => token.toJson()).toList(),
    'promotionalConsent': promotionalConsent.toJson(),
    'permissionStatus': permissionStatus.toJson(),
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
    // Legacy fields for backward compatibility
    'timeWindows': timeWindows.map((tw) => tw.toJson()).toList(),
    'allowTimeSensitive': allowTimeSensitive,
  };

  factory UserNotificationPreferences.fromJson(Map<String, dynamic> json) => UserNotificationPreferences(
    uid: json['uid'] as String,
    notificationStyle: NotificationStyle.values.firstWhere(
      (style) => style.name == json['notificationStyle'],
      orElse: () => NotificationStyle.coach,
    ),
    frequencyPerDay: json['frequencyPerDay'] as int? ?? 1,
    // ALL NOTIFICATION CATEGORIES AUTOMATICALLY ENABLED - Ignore any stored preferences
    enabledCategories: {
      NotificationCategory.studyNow,
      NotificationCategory.streakSave,
      NotificationCategory.inactivityNudge,
      NotificationCategory.eventTrigger,
    },
    selectedDayparts: (json['selectedDayparts'] as List<dynamic>?)
        ?.map((d) => DayPart.values.firstWhere((dp) => dp.name == d))
        .toList() ?? [DayPart.evening],
    quietHours: json['quietHours'] as bool? ?? true,
    quietStart: json['quietStart'] != null 
        ? TimeOfDay(hour: json['quietStart']['hour'] as int, minute: json['quietStart']['minute'] as int)
        : const TimeOfDay(hour: 22, minute: 0),
    quietEnd: json['quietEnd'] != null 
        ? TimeOfDay(hour: json['quietEnd']['hour'] as int, minute: json['quietEnd']['minute'] as int)
        : const TimeOfDay(hour: 7, minute: 0),
    eveningDigest: json['eveningDigest'] as bool? ?? true,
    digestTime: json['digestTime'] != null 
        ? TimeOfDay(hour: json['digestTime']['hour'] as int, minute: json['digestTime']['minute'] as int)
        : const TimeOfDay(hour: 20, minute: 30),
    stoEnabled: json['stoEnabled'] as bool? ?? true,
    timeSensitive: json['timeSensitive'] as bool? ?? false,
    timezone: json['timezone'] as String? ?? "America/Chicago",
    exams: (json['exams'] as List<dynamic>?)
        ?.map((exam) => ExamEntry.fromJson(exam as Map<String, dynamic>))
        .toList() ?? [],
    analytics: json['analytics'] != null
        ? NotificationAnalytics.fromJson(json['analytics'] as Map<String, dynamic>)
        : const NotificationAnalytics(opens: 0, dismissals: 0, streakDays: 0),
    pushTokens: (json['pushTokens'] as List<dynamic>?)
        ?.map((token) => PushToken.fromJson(token as Map<String, dynamic>))
        .toList() ?? [],
    promotionalConsent: json['promotionalConsent'] != null
        ? PromotionalConsent.fromJson(json['promotionalConsent'] as Map<String, dynamic>)
        : PromotionalConsent.defaultConsent(),
    permissionStatus: json['permissionStatus'] != null
        ? NotificationPermissionStatus.fromJson(json['permissionStatus'] as Map<String, dynamic>)
        : NotificationPermissionStatus.defaultStatus(),
    createdAt: json['createdAt'] != null
        ? (json['createdAt'] as Timestamp).toDate()
        : DateTime.now(),
    updatedAt: json['updatedAt'] != null
        ? (json['updatedAt'] as Timestamp).toDate()
        : DateTime.now(),
    // Legacy fields for backward compatibility
    timeWindows: (json['timeWindows'] as List<dynamic>?)
        ?.map((tw) => TimeWindow.fromJson(tw as Map<String, dynamic>))
        .toList() ?? [],
    allowTimeSensitive: json['allowTimeSensitive'] as bool? ?? false,
  );

  UserNotificationPreferences copyWith({
    String? uid,
    NotificationStyle? notificationStyle,
    int? frequencyPerDay,
    Set<NotificationCategory>? enabledCategories,
    List<DayPart>? selectedDayparts,
    bool? quietHours,
    TimeOfDay? quietStart,
    TimeOfDay? quietEnd,
    bool? eveningDigest,
    TimeOfDay? digestTime,
    bool? stoEnabled,
    bool? timeSensitive,
    String? timezone,
    List<ExamEntry>? exams,
    NotificationAnalytics? analytics,
    List<PushToken>? pushTokens,
    PromotionalConsent? promotionalConsent,
    NotificationPermissionStatus? permissionStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
    // Legacy fields
    List<TimeWindow>? timeWindows,
    bool? allowTimeSensitive,
  }) => UserNotificationPreferences(
    uid: uid ?? this.uid,
    notificationStyle: notificationStyle ?? this.notificationStyle,
    frequencyPerDay: frequencyPerDay ?? this.frequencyPerDay,
    enabledCategories: enabledCategories ?? this.enabledCategories,
    selectedDayparts: selectedDayparts ?? this.selectedDayparts,
    quietHours: quietHours ?? this.quietHours,
    quietStart: quietStart ?? this.quietStart,
    quietEnd: quietEnd ?? this.quietEnd,
    eveningDigest: eveningDigest ?? this.eveningDigest,
    digestTime: digestTime ?? this.digestTime,
    stoEnabled: stoEnabled ?? this.stoEnabled,
    timeSensitive: timeSensitive ?? this.timeSensitive,
    timezone: timezone ?? this.timezone,
    exams: exams ?? this.exams,
    analytics: analytics ?? this.analytics,
    pushTokens: pushTokens ?? this.pushTokens,
    promotionalConsent: promotionalConsent ?? this.promotionalConsent,
    permissionStatus: permissionStatus ?? this.permissionStatus,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    // Legacy fields
    timeWindows: timeWindows ?? this.timeWindows,
    allowTimeSensitive: allowTimeSensitive ?? this.allowTimeSensitive,
  );
}

class NotificationRecord {
  final String id;
  final String uid;
  final String title;
  final String body;
  final NotificationStyle style;
  final NotificationCategory category;
  final DateTime sentAt;
  final DateTime? openedAt;
  final String? action;
  final String? deepLink;
  final Platform platform;
  final Map<String, dynamic>? metadata;

  const NotificationRecord({
    required this.id,
    required this.uid,
    required this.title,
    required this.body,
    required this.style,
    required this.category,
    required this.sentAt,
    this.openedAt,
    this.action,
    this.deepLink,
    required this.platform,
    this.metadata,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'uid': uid,
    'title': title,
    'body': body,
    'style': style.name,
    'category': category.name,
    'sentAt': Timestamp.fromDate(sentAt),
    'openedAt': openedAt != null ? Timestamp.fromDate(openedAt!) : null,
    'action': action,
    'deepLink': deepLink,
    'platform': platform.name,
    'metadata': metadata,
  };

  factory NotificationRecord.fromJson(Map<String, dynamic> json) => NotificationRecord(
    id: json['id'] as String,
    uid: json['uid'] as String,
    title: json['title'] as String,
    body: json['body'] as String,
    style: NotificationStyle.values.firstWhere((s) => s.name == json['style']),
    category: NotificationCategory.values.firstWhere((c) => c.name == json['category']),
    sentAt: (json['sentAt'] as Timestamp).toDate(),
    openedAt: json['openedAt'] != null ? (json['openedAt'] as Timestamp).toDate() : null,
    action: json['action'] as String?,
    deepLink: json['deepLink'] as String?,
    platform: Platform.values.firstWhere((p) => p.name == json['platform']),
    metadata: json['metadata'] as Map<String, dynamic>?,
  );

  NotificationRecord copyWith({
    String? id,
    String? uid,
    String? title,
    String? body,
    NotificationStyle? style,
    NotificationCategory? category,
    DateTime? sentAt,
    DateTime? openedAt,
    String? action,
    String? deepLink,
    Platform? platform,
    Map<String, dynamic>? metadata,
  }) => NotificationRecord(
    id: id ?? this.id,
    uid: uid ?? this.uid,
    title: title ?? this.title,
    body: body ?? this.body,
    style: style ?? this.style,
    category: category ?? this.category,
    sentAt: sentAt ?? this.sentAt,
    openedAt: openedAt ?? this.openedAt,
    action: action ?? this.action,
    deepLink: deepLink ?? this.deepLink,
    platform: platform ?? this.platform,
    metadata: metadata ?? this.metadata,
  );
}

class ScheduledNotification {
  final DateTime sendAt;
  final NotificationStyle style;
  final NotificationCategory category;
  final String? deepLink;
  final Map<String, dynamic>? metadata;

  const ScheduledNotification({
    required this.sendAt,
    required this.style,
    required this.category,
    this.deepLink,
    this.metadata,
  });

  Map<String, dynamic> toJson() => {
    'sendAt': Timestamp.fromDate(sendAt),
    'style': style.name,
    'category': category.name,
    'deepLink': deepLink,
    'metadata': metadata,
  };

  factory ScheduledNotification.fromJson(Map<String, dynamic> json) => ScheduledNotification(
    sendAt: (json['sendAt'] as Timestamp).toDate(),
    style: NotificationStyle.values.firstWhere((s) => s.name == json['style']),
    category: NotificationCategory.values.firstWhere((c) => c.name == json['category']),
    deepLink: json['deepLink'] as String?,
    metadata: json['metadata'] as Map<String, dynamic>?,
  );
}

class NotificationSchedule {
  final String uid;
  final List<ScheduledNotification> next48h;
  final DateTime computedAt;

  const NotificationSchedule({
    required this.uid,
    required this.next48h,
    required this.computedAt,
  });

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'next48h': next48h.map((sn) => sn.toJson()).toList(),
    'computedAt': Timestamp.fromDate(computedAt),
  };

  factory NotificationSchedule.fromJson(Map<String, dynamic> json) => NotificationSchedule(
    uid: json['uid'] as String,
    next48h: (json['next48h'] as List<dynamic>?)
        ?.map((sn) => ScheduledNotification.fromJson(sn as Map<String, dynamic>))
        .toList() ?? [],
    computedAt: json['computedAt'] != null
        ? (json['computedAt'] as Timestamp).toDate()
        : DateTime.now(),
  );
}

class NotificationTemplate {
  final String title;
  final String body;
  final Map<String, dynamic>? metadata;

  const NotificationTemplate({
    required this.title,
    required this.body,
    this.metadata,
  });

  NotificationTemplate copyWith({
    String? title,
    String? body,
    Map<String, dynamic>? metadata,
  }) {
    return NotificationTemplate(
      title: title ?? this.title,
      body: body ?? this.body,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'body': body,
    'metadata': metadata,
  };

  factory NotificationTemplate.fromJson(Map<String, dynamic> json) => NotificationTemplate(
    title: json['title'] as String,
    body: json['body'] as String,
    metadata: json['metadata'] as Map<String, dynamic>?,
  );
}

/// **NOTIFICATION CANDIDATE**
/// Represents a potential notification that can be scheduled and delivered
class NotificationCandidate {
  final String id;
  final NotificationCategory category;
  final NotificationStyle style;
  final String title;
  final String body;
  final String? deepLink;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime? scheduledFor;

  NotificationCandidate({
    required this.id,
    required this.category,
    required this.style,
    required this.title,
    required this.body,
    this.deepLink,
    this.metadata,
    required this.createdAt,
    this.scheduledFor,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'category': category.name,
    'style': style.name,
    'title': title,
    'body': body,
    'deepLink': deepLink,
    'metadata': metadata,
    'createdAt': Timestamp.fromDate(createdAt),
    'scheduledFor': scheduledFor != null ? Timestamp.fromDate(scheduledFor!) : null,
  };

  factory NotificationCandidate.fromJson(Map<String, dynamic> json) => NotificationCandidate(
    id: json['id'] as String,
    category: NotificationCategory.values.firstWhere((c) => c.name == json['category']),
    style: NotificationStyle.values.firstWhere((s) => s.name == json['style']),
    title: json['title'] as String,
    body: json['body'] as String,
    deepLink: json['deepLink'] as String?,
    metadata: json['metadata'] as Map<String, dynamic>?,
    createdAt: (json['createdAt'] as Timestamp).toDate(),
    scheduledFor: json['scheduledFor'] != null ? (json['scheduledFor'] as Timestamp).toDate() : null,
  );

  NotificationCandidate copyWith({
    String? id,
    NotificationCategory? category,
    NotificationStyle? style,
    String? title,
    String? body,
    String? deepLink,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? scheduledFor,
  }) => NotificationCandidate(
    id: id ?? this.id,
    category: category ?? this.category,
    style: style ?? this.style,
    title: title ?? this.title,
    body: body ?? this.body,
    deepLink: deepLink ?? this.deepLink,
    metadata: metadata ?? this.metadata,
    createdAt: createdAt ?? this.createdAt,
    scheduledFor: scheduledFor ?? this.scheduledFor,
  );
}

// **ORCHESTRATOR RESULT CLASSES**

/// Base result class
abstract class OperationResult {
  final bool success;
  final String? message;
  final DateTime timestamp;

  const OperationResult({
    required this.success,
    this.message,
    required this.timestamp,
  });
}

/// Style update result
class StyleUpdateResult extends OperationResult {
  final NotificationStyle? newStyle;
  final NotificationStyle? previousStyle;

  const StyleUpdateResult({
    required super.success,
    super.message,
    required super.timestamp,
    this.newStyle,
    this.previousStyle,
  });

  factory StyleUpdateResult.success(NotificationStyle newStyle, NotificationStyle? previousStyle) =>
      StyleUpdateResult(
        success: true,
        newStyle: newStyle,
        previousStyle: previousStyle,
        timestamp: DateTime.now(),
        message: 'Notification style updated successfully',
      );

  factory StyleUpdateResult.failure(String message) => StyleUpdateResult(
    success: false,
    message: message,
    timestamp: DateTime.now(),
  );
}

/// Frequency update result
class FrequencyUpdateResult extends OperationResult {
  final int? newFrequency;
  final int? previousFrequency;

  const FrequencyUpdateResult({
    required super.success,
    super.message,
    required super.timestamp,
    this.newFrequency,
    this.previousFrequency,
  });

  factory FrequencyUpdateResult.success(int newFrequency, int? previousFrequency) =>
      FrequencyUpdateResult(
        success: true,
        newFrequency: newFrequency,
        previousFrequency: previousFrequency,
        timestamp: DateTime.now(),
        message: 'Notification frequency updated successfully',
      );

  factory FrequencyUpdateResult.failure(String message) => FrequencyUpdateResult(
    success: false,
    message: message,
    timestamp: DateTime.now(),
  );
}

/// Quiet hours update result
class QuietHoursUpdateResult extends OperationResult {
  final String? newStartTime;
  final String? newEndTime;

  const QuietHoursUpdateResult({
    required super.success,
    super.message,
    required super.timestamp,
    this.newStartTime,
    this.newEndTime,
  });

  factory QuietHoursUpdateResult.success(String startTime, String endTime) =>
      QuietHoursUpdateResult(
        success: true,
        newStartTime: startTime,
        newEndTime: endTime,
        timestamp: DateTime.now(),
        message: 'Quiet hours updated successfully',
      );

  factory QuietHoursUpdateResult.failure(String message) => QuietHoursUpdateResult(
    success: false,
    message: message,
    timestamp: DateTime.now(),
  );
}

/// Time-sensitive permission update result
class TimeSensitiveUpdateResult extends OperationResult {
  final bool? enabled;

  const TimeSensitiveUpdateResult({
    required super.success,
    super.message,
    required super.timestamp,
    this.enabled,
  });

  factory TimeSensitiveUpdateResult.success(bool enabled) => TimeSensitiveUpdateResult(
    success: true,
    enabled: enabled,
    timestamp: DateTime.now(),
    message: 'Time-sensitive notifications ${enabled ? 'enabled' : 'disabled'}',
  );

  factory TimeSensitiveUpdateResult.failure(String message) => TimeSensitiveUpdateResult(
    success: false,
    message: message,
    timestamp: DateTime.now(),
  );
}

/// Exam attachment result
class ExamAttachmentResult extends OperationResult {
  final String? studySetId;
  final String? courseName;
  final DateTime? examDate;
  final List<String>? countdownWindows;

  const ExamAttachmentResult({
    required super.success,
    super.message,
    required super.timestamp,
    this.studySetId,
    this.courseName,
    this.examDate,
    this.countdownWindows,
  });

  factory ExamAttachmentResult.success({
    required String studySetId,
    required String courseName,
    required DateTime examDate,
    required List<String> countdownWindows,
  }) => ExamAttachmentResult(
    success: true,
    studySetId: studySetId,
    courseName: courseName,
    examDate: examDate,
    countdownWindows: countdownWindows,
    timestamp: DateTime.now(),
    message: 'Exam attached successfully with ${countdownWindows.length} countdown alerts',
  );

  factory ExamAttachmentResult.failure(String message) => ExamAttachmentResult(
    success: false,
    message: message,
    timestamp: DateTime.now(),
  );
}

// **MISSING SUPPORTING CLASSES FOR ORCHESTRATOR**

/// Notification style option for UI
class NotificationStyleOption {
  final NotificationStyle style;
  final String displayName;
  final String description;
  final String icon;

  const NotificationStyleOption({
    required this.style,
    required this.displayName,
    required this.description,
    required this.icon,
  });
}

/// Exam countdown info
class ExamCountdownInfo {
  final String course;
  final DateTime examDate;
  final Duration timeUntilExam;
  final ExamUrgencyLevel urgencyLevel;
  final List<String> activeCountdowns;

  const ExamCountdownInfo({
    required this.course,
    required this.examDate,
    required this.timeUntilExam,
    required this.urgencyLevel,
    required this.activeCountdowns,
  });
}

enum ExamUrgencyLevel { low, medium, high, urgent, critical }

/// SLO report for admin dashboard
class SLOReport {
  final double p50Latency;
  final double p90Latency;
  final double p99Latency;
  final double successRate;
  final int totalNotifications;
  final SLOCompliance sloCompliance;
  final Duration reportPeriod;
  final DateTime generatedAt;

  const SLOReport({
    required this.p50Latency,
    required this.p90Latency,
    required this.p99Latency,
    required this.successRate,
    required this.totalNotifications,
    required this.sloCompliance,
    required this.reportPeriod,
    required this.generatedAt,
  });
}

class SLOCompliance {
  final bool p50Met;
  final bool successMet;
  final bool overallCompliant;

  const SLOCompliance({
    required this.p50Met,
    required this.successMet,
    required this.overallCompliant,
  });
}

/// System health status
enum HealthLevel { healthy, degraded, critical }

class SystemHealthStatus {
  final HealthLevel overallHealth;
  final int activeUsers;
  final bool firebaseConnected;
  final bool localNotificationsWorking;
  final List<String> issues;
  final DateTime checkedAt;

  const SystemHealthStatus({
    required this.overallHealth,
    required this.activeUsers,
    required this.firebaseConnected,
    required this.localNotificationsWorking,
    required this.issues,
    required this.checkedAt,
  });
}

/// Delivery analytics
class DeliveryAnalytics {
  final int totalDelivered;
  final double averageLatency;
  final Map<String, int> deliveryByPlatform;
  final Map<String, int> deliveryByCategory;
  final Map<String, double> successRateByStyle;

  const DeliveryAnalytics({
    required this.totalDelivered,
    required this.averageLatency,
    required this.deliveryByPlatform,
    required this.deliveryByCategory,
    required this.successRateByStyle,
  });
}

/// Alert status for admin dashboard
class AlertStatus {
  final String alertId;
  final String title;
  final String description;
  final AlertSeverity severity;
  final DateTime triggeredAt;
  final bool acknowledged;

  const AlertStatus({
    required this.alertId,
    required this.title,
    required this.description,
    required this.severity,
    required this.triggeredAt,
    required this.acknowledged,
  });
}

enum AlertSeverity { info, warning, error, critical }

/// Dashboard metrics for real-time monitoring
class DashboardMetrics {
  final int notificationsPerMinute;
  final double currentP50Latency;
  final double currentSuccessRate;
  final int activeUsers;
  final Map<String, int> categoryBreakdown;
  final DateTime timestamp;

  const DashboardMetrics({
    required this.notificationsPerMinute,
    required this.currentP50Latency,
    required this.currentSuccessRate,
    required this.activeUsers,
    required this.categoryBreakdown,
    required this.timestamp,
  });
}

/// User notification insights
class UserNotificationInsights {
  final String userId;
  final NotificationAnalytics analytics;
  final Map<String, double> categoryEngagement;
  final Map<String, double> stylePerformance;
  final List<String> recommendations;
  final DateTime generatedAt;

  const UserNotificationInsights({
    required this.userId,
    required this.analytics,
    required this.categoryEngagement,
    required this.stylePerformance,
    required this.recommendations,
    required this.generatedAt,
  });
}

/// **MISSING SERVICE RESULT CLASSES**

/// Notification delivery result
class NotificationDeliveryResult {
  final bool success;
  final String? deliveryId;
  final DateTime? scheduledTime;
  final String? errorMessage;
  final Duration? latency;

  const NotificationDeliveryResult({
    required this.success,
    this.deliveryId,
    this.scheduledTime,
    this.errorMessage,
    this.latency,
  });

  factory NotificationDeliveryResult.success({
    required String deliveryId,
    DateTime? scheduledTime,
    Duration? latency,
  }) => NotificationDeliveryResult(
    success: true,
    deliveryId: deliveryId,
    scheduledTime: scheduledTime,
    latency: latency,
  );

  factory NotificationDeliveryResult.failure(String error) => NotificationDeliveryResult(
    success: false,
    errorMessage: error,
  );
}

/// Service initialization result
class ServiceInitResult {
  final bool success;
  final String? errorMessage;
  final DateTime timestamp;

  const ServiceInitResult({
    required this.success,
    this.errorMessage,
    required this.timestamp,
  });

  factory ServiceInitResult.success() => ServiceInitResult(
    success: true,
    timestamp: DateTime.now(),
  );

  factory ServiceInitResult.failure(String error) => ServiceInitResult(
    success: false,
    errorMessage: error,
    timestamp: DateTime.now(),
  );
}
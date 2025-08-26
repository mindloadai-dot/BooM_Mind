import 'package:cloud_firestore/cloud_firestore.dart';

// Firebase data models for IAP-only payment system
// Following the exact collection structure specified in requirements

enum UserTier {
  free,
  proMonthly,
  proAnnual,
}

enum Platform {
  ios,
  android,
  unknown,
}

enum EntitlementStatus {
  none,
  active,
  grace,
  onHold,
  paused,
  expired,
}

enum IapEventStatus {
  pending,
  processed,
  skipped,
}

enum IapEventType {
  subscribed,
  didRenew,
  expired,
  didFailToRenew,
  refund,
  revoke,
  upgrade,
  downgrade,
  priceIncreaseConsent,
  purchased,
  acknowledged,
  canceled,
  resumed,
  refunded,
  revoked,
  priceChangeConfirmed,
}

// users/{uid} collection model
class FirebaseUser {
  final String uid;
  final UserTier tier;
  final int credits;
  final DateTime? renewalDate;
  final Platform platform;
  final bool introUsed;
  final String countryCode; // ISO-3166
  final String languageCode; // BCP-47
  final String timezone; // IANA

  const FirebaseUser({
    required this.uid,
    required this.tier,
    required this.credits,
    this.renewalDate,
    required this.platform,
    this.introUsed = false,
    required this.countryCode,
    required this.languageCode,
    required this.timezone,
  });

  Map<String, dynamic> toMap() {
    return {
      'tier': tier.name,
      'credits': credits,
      'renewalDate': renewalDate != null ? Timestamp.fromDate(renewalDate!) : null,
      'platform': platform.name,
      'introUsed': introUsed,
      'countryCode': countryCode,
      'languageCode': languageCode,
      'timezone': timezone,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory FirebaseUser.fromMap(Map<String, dynamic> map, String uid) {
    return FirebaseUser(
      uid: uid,
      tier: UserTier.values.firstWhere(
        (e) => e.name == map['tier'],
        orElse: () => UserTier.free,
      ),
      credits: map['credits'] ?? 3,
      renewalDate: map['renewalDate'] != null
          ? (map['renewalDate'] as Timestamp).toDate()
          : null,
      platform: Platform.values.firstWhere(
        (e) => e.name == map['platform'],
        orElse: () => Platform.unknown,
      ),
      introUsed: map['introUsed'] ?? false,
      countryCode: map['countryCode'] ?? 'US',
      languageCode: map['languageCode'] ?? 'en',
      timezone: map['timezone'] ?? 'America/Chicago',
    );
  }

  FirebaseUser copyWith({
    UserTier? tier,
    int? credits,
    DateTime? renewalDate,
    Platform? platform,
    bool? introUsed,
    String? countryCode,
    String? languageCode,
    String? timezone,
  }) {
    return FirebaseUser(
      uid: uid,
      tier: tier ?? this.tier,
      credits: credits ?? this.credits,
      renewalDate: renewalDate ?? this.renewalDate,
      platform: platform ?? this.platform,
      introUsed: introUsed ?? this.introUsed,
      countryCode: countryCode ?? this.countryCode,
      languageCode: languageCode ?? this.languageCode,
      timezone: timezone ?? this.timezone,
    );
  }
}

// entitlements/{uid} collection model (single doc per user)
class UserEntitlement {
  final String uid;
  final EntitlementStatus status;
  final String? productId;
  final Platform? platform;
  final DateTime? startAt;
  final DateTime? endAt;
  final bool autoRenew;
  final String? latestTransactionId;
  final DateTime? lastVerifiedAt;

  const UserEntitlement({
    required this.uid,
    required this.status,
    this.productId,
    this.platform,
    this.startAt,
    this.endAt,
    this.autoRenew = true,
    this.latestTransactionId,
    this.lastVerifiedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'status': status.name,
      'productId': productId,
      'platform': platform?.name,
      'startAt': startAt != null ? Timestamp.fromDate(startAt!) : null,
      'endAt': endAt != null ? Timestamp.fromDate(endAt!) : null,
      'autoRenew': autoRenew,
      'latestTransactionId': latestTransactionId,
      'lastVerifiedAt': lastVerifiedAt != null ? Timestamp.fromDate(lastVerifiedAt!) : null,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory UserEntitlement.fromMap(Map<String, dynamic> map, String uid) {
    return UserEntitlement(
      uid: uid,
      status: EntitlementStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => EntitlementStatus.none,
      ),
      productId: map['productId'],
      platform: map['platform'] != null
          ? Platform.values.firstWhere(
              (e) => e.name == map['platform'],
              orElse: () => Platform.unknown,
            )
          : null,
      startAt: map['startAt'] != null ? (map['startAt'] as Timestamp).toDate() : null,
      endAt: map['endAt'] != null ? (map['endAt'] as Timestamp).toDate() : null,
      autoRenew: map['autoRenew'] ?? true,
      latestTransactionId: map['latestTransactionId'],
      lastVerifiedAt: map['lastVerifiedAt'] != null
          ? (map['lastVerifiedAt'] as Timestamp).toDate()
          : null,
    );
  }
}

// iapEvents/{eventId} collection model (idempotency)
class IapEvent {
  final String eventId;
  final Platform platform;
  final IapEventType type;
  final String transactionId;
  final String? purchaseToken;
  final String? uid;
  final DateTime processedAt;
  final IapEventStatus status;
  final Map<String, dynamic> raw;

  const IapEvent({
    required this.eventId,
    required this.platform,
    required this.type,
    required this.transactionId,
    this.purchaseToken,
    this.uid,
    required this.processedAt,
    required this.status,
    required this.raw,
  });

  Map<String, dynamic> toMap() {
    return {
      'platform': platform.name,
      'type': type.name,
      'transactionId': transactionId,
      'purchaseToken': purchaseToken,
      'uid': uid,
      'processedAt': Timestamp.fromDate(processedAt),
      'status': status.name,
      'raw': raw,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory IapEvent.fromMap(Map<String, dynamic> map, String eventId) {
    return IapEvent(
      eventId: eventId,
      platform: Platform.values.firstWhere(
        (e) => e.name == map['platform'],
        orElse: () => Platform.unknown,
      ),
      type: IapEventType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => IapEventType.purchased,
      ),
      transactionId: map['transactionId'],
      purchaseToken: map['purchaseToken'],
      uid: map['uid'],
      processedAt: (map['processedAt'] as Timestamp).toDate(),
      status: IapEventStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => IapEventStatus.pending,
      ),
      raw: map['raw'] ?? {},
    );
  }
}

// creditLedger/{uid}/{entryId} collection model
class CreditLedgerEntry {
  final String entryId;
  final String uid;
  final int delta;
  final String reason;
  final String sourceEventId;
  final DateTime createdAt;

  const CreditLedgerEntry({
    required this.entryId,
    required this.uid,
    required this.delta,
    required this.reason,
    required this.sourceEventId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'delta': delta,
      'reason': reason,
      'sourceEventId': sourceEventId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory CreditLedgerEntry.fromMap(Map<String, dynamic> map, String entryId, String uid) {
    return CreditLedgerEntry(
      entryId: entryId,
      uid: uid,
      delta: map['delta'],
      reason: map['reason'],
      sourceEventId: map['sourceEventId'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}

// receipts/{uid}/{platform}_{transactionId} collection model
class Receipt {
  final String receiptId;
  final String uid;
  final String status;
  final DateTime lastVerifiedAt;
  final Map<String, dynamic> raw;

  const Receipt({
    required this.receiptId,
    required this.uid,
    required this.status,
    required this.lastVerifiedAt,
    required this.raw,
  });

  Map<String, dynamic> toMap() {
    return {
      'status': status,
      'lastVerifiedAt': Timestamp.fromDate(lastVerifiedAt),
      'raw': raw,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory Receipt.fromMap(Map<String, dynamic> map, String receiptId, String uid) {
    return Receipt(
      receiptId: receiptId,
      uid: uid,
      status: map['status'],
      lastVerifiedAt: (map['lastVerifiedAt'] as Timestamp).toDate(),
      raw: map['raw'] ?? {},
    );
  }
}

// Remote Config Keys for international IAP compliance
class RemoteConfigKeys {
  // Product availability flags
  static const String introEnabled = 'intro_enabled';
  static const String annualIntroEnabled = 'annual_intro_enabled';
  static const String logicPackEnabled = 'logic_pack_enabled';
  
  // System operation flags
  static const String iapOnlyMode = 'iap_only_mode';
  static const String manageLinksEnabled = 'manage_links_enabled';
  
  // Default values (as per requirements)
  static const Map<String, dynamic> defaults = {
    introEnabled: true,
    annualIntroEnabled: true,
    logicPackEnabled: true,
    iapOnlyMode: true,
    manageLinksEnabled: true,
  };
}

// Credit quota rules for international tier system
class CreditQuotas {
  static const int free = 5; // Free tier: 5 credits/month (aligns with app copy)
  static const int pro = 60; // Pro tier: 60 credits/month  
  static const int introMonth = 30; // Intro month: 30 credits during 0.99 month
  static const int starterPackBonus = 5; // Starter Pack: +5 immediate credits
  static const int rolloverCap = 30; // Pro only: max 30 credits rollover per month
}

// Telemetry events for IAP (non-PII)
enum IapTelemetryEvent {
  paywallView,
  purchaseStart,
  purchaseSuccess,
  purchaseFail,
  restoreSuccess,
  refundReceived,
  entitlementChanged,
}

class IapTelemetryData {
  final IapTelemetryEvent event;
  final DateTime timestamp;
  final Map<String, dynamic> parameters;

  const IapTelemetryData({
    required this.event,
    required this.timestamp,
    required this.parameters,
  });

  Map<String, dynamic> toMap() {
    return {
      'event': event.name,
      'timestamp': Timestamp.fromDate(timestamp),
      'parameters': parameters,
    };
  }
}
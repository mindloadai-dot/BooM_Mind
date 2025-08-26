import 'package:flutter/foundation.dart';
import 'package:mindload/l10n/app_localizations.dart';
import 'package:mindload/services/storage_service.dart';
import 'dart:io';
import 'dart:convert';

// International compliance service for GDPR, LGPD, PIPEDA, CPRA compliance
class InternationalComplianceService extends ChangeNotifier {
  static final InternationalComplianceService _instance = InternationalComplianceService._internal();
  factory InternationalComplianceService() => _instance;
  static InternationalComplianceService get instance => _instance;
  InternationalComplianceService._internal();

  final StorageService _storage = StorageService.instance;

  bool _isInitialized = false;
  String _userRegion = 'GLOBAL';
  String _userCountry = 'US';
  ComplianceRequirements? _requirements;

  bool get isInitialized => _isInitialized;
  String get userRegion => _userRegion;
  String get userCountry => _userCountry;
  ComplianceRequirements? get requirements => _requirements;

  Future<void> initialize() async {
    try {
      _determineUserRegion();
      _requirements = _getComplianceRequirements(_userRegion, _userCountry);
      _isInitialized = true;
      notifyListeners();
      
      debugPrint('✅ International compliance initialized for $_userCountry ($_userRegion)');
    } catch (e) {
      debugPrint('❌ Error initializing international compliance: $e');
      _isInitialized = false;
    }
  }

  // Determine user region based on device locale
  void _determineUserRegion() {
    try {
      final locale = Platform.localeName;
      final parts = locale.split('_');
      
      if (parts.length >= 2) {
        _userCountry = parts[1].toUpperCase();
      } else {
        // Fallback mapping based on language
        final lang = parts[0];
        switch (lang) {
          case 'en': _userCountry = 'US'; break;
          case 'es': _userCountry = 'ES'; break;
          case 'pt': _userCountry = 'BR'; break;
          case 'fr': _userCountry = 'FR'; break;
          case 'de': _userCountry = 'DE'; break;
          case 'it': _userCountry = 'IT'; break;
          case 'ja': _userCountry = 'JP'; break;
          case 'ko': _userCountry = 'KR'; break;
          case 'zh': _userCountry = 'CN'; break;
          case 'ar': _userCountry = 'SA'; break;
          case 'hi': _userCountry = 'IN'; break;
          default: _userCountry = 'US';
        }
      }

      _userRegion = _getRegionForCountry(_userCountry);
    } catch (e) {
      debugPrint('Error determining user region: $e');
      _userCountry = 'US';
      _userRegion = 'GLOBAL';
    }
  }

  // Get region classification for country
  String _getRegionForCountry(String countryCode) {
    // EU/EEA countries (GDPR)
    const euCountries = ['DE', 'FR', 'IT', 'ES', 'NL', 'BE', 'AT', 'CH', 'DK', 'SE', 'NO', 'FI', 'PL', 'CZ', 'HU', 'PT', 'IE', 'GR', 'RO', 'BG', 'HR', 'LT', 'LV', 'EE', 'SI', 'SK', 'CY', 'MT', 'LU', 'UK', 'IS', 'LI'];
    if (euCountries.contains(countryCode)) return 'EU';

    // APAC countries
    const apacCountries = ['JP', 'KR', 'CN', 'IN', 'SG', 'MY', 'TH', 'PH', 'VN', 'ID', 'AU', 'NZ', 'TW', 'HK'];
    if (apacCountries.contains(countryCode)) return 'APAC';

    // LATAM countries (LGPD and others)
    const latamCountries = ['BR', 'MX', 'AR', 'CL', 'CO', 'PE', 'VE', 'EC', 'BO', 'PY', 'UY', 'GY', 'SR', 'FK'];
    if (latamCountries.contains(countryCode)) return 'LATAM';

    // North America
    const naCountries = ['US', 'CA'];
    if (naCountries.contains(countryCode)) return 'NA';

    return 'GLOBAL';
  }

  // Get compliance requirements for region/country
  ComplianceRequirements _getComplianceRequirements(String region, String country) {
    switch (region) {
      case 'EU':
        return ComplianceRequirements(
          regulation: 'GDPR',
          requiresDataProcessingNotice: true,
          requiresExplicitConsent: true,
          requiresDataPortability: true,
          requiresRightToErasure: true,
          requiresPrivacyByDesign: true,
          maxDataRetentionDays: 1095, // 3 years
          requiresDataProtectionOfficer: false, // Not needed for our app size
          cookieConsentRequired: false, // Mobile app doesn't use cookies
          minorProtectionAge: 16,
          dataTransferRestrictions: ['Adequacy decision required for non-EU transfers'],
          requiredLegalBasis: 'Legitimate interest and consent',
        );

      case 'LATAM':
        if (country == 'BR') {
          return ComplianceRequirements(
            regulation: 'LGPD',
            requiresDataProcessingNotice: true,
            requiresExplicitConsent: true,
            requiresDataPortability: true,
            requiresRightToErasure: true,
            requiresPrivacyByDesign: true,
            maxDataRetentionDays: 1095,
            requiresDataProtectionOfficer: false,
            cookieConsentRequired: false,
            minorProtectionAge: 18,
            dataTransferRestrictions: ['International transfer restrictions apply'],
            requiredLegalBasis: 'Legitimate interest and consent',
          );
        }
        return _getGlobalRequirements();

      case 'NA':
        if (country == 'CA') {
          return ComplianceRequirements(
            regulation: 'PIPEDA',
            requiresDataProcessingNotice: true,
            requiresExplicitConsent: false, // PIPEDA allows implied consent
            requiresDataPortability: false,
            requiresRightToErasure: false,
            requiresPrivacyByDesign: true,
            maxDataRetentionDays: 2555, // 7 years
            requiresDataProtectionOfficer: false,
            cookieConsentRequired: false,
            minorProtectionAge: 13,
            dataTransferRestrictions: ['Adequate protection required'],
            requiredLegalBasis: 'Consent or legitimate purpose',
          );
        } else if (country == 'US') {
          return ComplianceRequirements(
            regulation: 'CPRA/CCPA',
            requiresDataProcessingNotice: true,
            requiresExplicitConsent: false,
            requiresDataPortability: true,
            requiresRightToErasure: true,
            requiresPrivacyByDesign: true,
            maxDataRetentionDays: 1825, // 5 years
            requiresDataProtectionOfficer: false,
            cookieConsentRequired: false,
            minorProtectionAge: 16,
            dataTransferRestrictions: [],
            requiredLegalBasis: 'Business purpose or consent',
          );
        }
        return _getGlobalRequirements();

      default:
        return _getGlobalRequirements();
    }
  }

  ComplianceRequirements _getGlobalRequirements() {
    return ComplianceRequirements(
      regulation: 'Global Best Practices',
      requiresDataProcessingNotice: true,
      requiresExplicitConsent: false,
      requiresDataPortability: false,
      requiresRightToErasure: false,
      requiresPrivacyByDesign: true,
      maxDataRetentionDays: 1095,
      requiresDataProtectionOfficer: false,
      cookieConsentRequired: false,
      minorProtectionAge: 13,
      dataTransferRestrictions: [],
      requiredLegalBasis: 'Consent or legitimate interest',
    );
  }

  // Check if user needs data processing consent
  bool needsDataProcessingConsent() {
    return _requirements?.requiresExplicitConsent ?? false;
  }

  // Check if user needs data processing notice
  bool needsDataProcessingNotice() {
    return _requirements?.requiresDataProcessingNotice ?? true;
  }

  // Check if user has right to data portability
  bool hasDataPortabilityRights() {
    return _requirements?.requiresDataPortability ?? false;
  }

  // Check if user has right to erasure
  bool hasRightToErasure() {
    return _requirements?.requiresRightToErasure ?? false;
  }

  // Get data retention period in days
  int getDataRetentionDays() {
    return _requirements?.maxDataRetentionDays ?? 1095;
  }

  // Get minor protection age
  int getMinorProtectionAge() {
    return _requirements?.minorProtectionAge ?? 13;
  }

  // Record consent for data processing
  Future<void> recordDataProcessingConsent() async {
    try {
      final consentData = {
        'timestamp': DateTime.now().toIso8601String(),
        'country': _userCountry,
        'region': _userRegion,
        'regulation': _requirements?.regulation ?? 'Global',
        'consent_given': true,
        'ip_address_hashed': 'hash_stored_for_legal_compliance',
      };

      await _storage.setString('data_processing_consent', json.encode(consentData));
      debugPrint('✅ Data processing consent recorded for $_userCountry');
    } catch (e) {
      debugPrint('❌ Error recording consent: $e');
    }
  }

  // Record consent withdrawal
  Future<void> recordConsentWithdrawal() async {
    try {
      final withdrawalData = {
        'timestamp': DateTime.now().toIso8601String(),
        'country': _userCountry,
        'region': _userRegion,
        'consent_withdrawn': true,
      };

      await _storage.setString('consent_withdrawal', json.encode(withdrawalData));
      debugPrint('✅ Consent withdrawal recorded for $_userCountry');
    } catch (e) {
      debugPrint('❌ Error recording consent withdrawal: $e');
    }
  }

  // Get localized privacy notice text
  String getPrivacyNoticeText(AppLocalizations l10n) {
    if (_userRegion == 'EU') {
      return 'Under GDPR, you have the right to access, rectify, erase, and port your personal data. We process your data based on legitimate interest for app functionality and with your consent for analytics. Data is retained for ${getDataRetentionDays()} days maximum.';
    } else if (_userRegion == 'LATAM' && _userCountry == 'BR') {
      return 'Under LGPD, you have rights regarding your personal data including access, correction, deletion, and portability. We process your data based on legitimate interest and consent. Contact us for any data-related requests.';
    } else if (_userRegion == 'NA' && _userCountry == 'CA') {
      return 'Under PIPEDA, we collect and use your personal information for the purposes of app functionality. You have the right to access and correct your personal information. We retain data for business purposes only.';
    } else if (_userCountry == 'US') {
      return 'Under CCPA/CPRA, you have the right to know what personal information we collect, delete your personal information, and opt-out of the sale of personal information. We do not sell personal information.';
    } else {
      return 'We respect your privacy and handle your personal data in accordance with international best practices. You can request access to or deletion of your data by contacting support.';
    }
  }

  // Get required legal links
  List<LegalLink> getRequiredLegalLinks(AppLocalizations l10n) {
    final links = <LegalLink>[
      LegalLink('Privacy Policy', 'https://mindload.app/privacy', true),
      LegalLink('Terms of Service', 'https://mindload.app/terms', true),
    ];

    if (needsDataProcessingNotice()) {
      links.add(LegalLink('Data Processing', 'https://mindload.app/data-processing', true));
    }

    if (_userRegion == 'EU') {
      links.add(LegalLink('GDPR Rights', 'https://mindload.app/gdpr-rights', true));
    }

    if (_userCountry == 'US') {
      links.add(LegalLink('Your Privacy Choices', 'https://mindload.app/privacy-choices', true));
    }

    return links;
  }

  // Check if data export is required
  bool isDataExportRequired() {
    return hasDataPortabilityRights();
  }

  // Check if account deletion is required
  bool isAccountDeletionRequired() {
    return hasRightToErasure() || true; // Always provide deletion option as good practice
  }

  // Generate compliance report
  Map<String, dynamic> generateComplianceReport() {
    return {
      'user_country': _userCountry,
      'user_region': _userRegion,
      'applicable_regulation': _requirements?.regulation ?? 'None',
      'data_processing_notice_required': needsDataProcessingNotice(),
      'explicit_consent_required': needsDataProcessingConsent(),
      'data_portability_required': hasDataPortabilityRights(),
      'right_to_erasure_required': hasRightToErasure(),
      'data_retention_days': getDataRetentionDays(),
      'minor_protection_age': getMinorProtectionAge(),
      'compliance_features_enabled': {
        'data_export': isDataExportRequired(),
        'account_deletion': isAccountDeletionRequired(),
        'consent_management': needsDataProcessingConsent(),
      },
    };
  }

  @override
  String toString() => 'InternationalComplianceService($_userCountry, $_userRegion)';
}

// Compliance requirements model
class ComplianceRequirements {
  final String regulation;
  final bool requiresDataProcessingNotice;
  final bool requiresExplicitConsent;
  final bool requiresDataPortability;
  final bool requiresRightToErasure;
  final bool requiresPrivacyByDesign;
  final int maxDataRetentionDays;
  final bool requiresDataProtectionOfficer;
  final bool cookieConsentRequired;
  final int minorProtectionAge;
  final List<String> dataTransferRestrictions;
  final String requiredLegalBasis;

  const ComplianceRequirements({
    required this.regulation,
    required this.requiresDataProcessingNotice,
    required this.requiresExplicitConsent,
    required this.requiresDataPortability,
    required this.requiresRightToErasure,
    required this.requiresPrivacyByDesign,
    required this.maxDataRetentionDays,
    required this.requiresDataProtectionOfficer,
    required this.cookieConsentRequired,
    required this.minorProtectionAge,
    required this.dataTransferRestrictions,
    required this.requiredLegalBasis,
  });
}

// Legal link model
class LegalLink {
  final String title;
  final String url;
  final bool required;

  const LegalLink(this.title, this.url, this.required);
}
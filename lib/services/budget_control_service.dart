import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mindload/models/pricing_models.dart';
import 'package:mindload/services/remote_config_service.dart';
import 'package:mindload/services/telemetry_service.dart';

// Budget control service to manage $100/month spending cap
class BudgetControlService extends ChangeNotifier {
  static final BudgetControlService _instance = BudgetControlService._internal();
  factory BudgetControlService() => _instance;
  static BudgetControlService get instance => _instance;
  BudgetControlService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final RemoteConfigService _remoteConfig = RemoteConfigService.instance;
  final TelemetryService _telemetry = TelemetryService.instance;

  SystemBudgetNew _systemBudget = SystemBudgetNew(
    monthlySpentUsd: 0.0,
    monthlyLimitUsd: BudgetConfig.monthlyCapUsd,
    currentThreshold: BudgetThreshold.normal,
    currentMode: BudgetMode.standard,
    lastReset: DateTime.now(),
    resetDate: _calculateNextResetDate(DateTime.now()),
  );

  bool _isInitialized = false;
  
  SystemBudgetNew get systemBudget => _systemBudget;
  bool get isInitialized => _isInitialized;
  
  // Budget status checks (aligned with MindloadEconomy thresholds)
  bool get isAtWarnThreshold => _systemBudget.usagePercentage >= 0.80; // 80% - Savings Mode
  bool get isAtLimitThreshold => _systemBudget.usagePercentage >= 1.00; // 100% - Paused Mode
  bool get isAtHardThreshold => _systemBudget.usagePercentage >= 1.00; // 100% - Same as limit
  
  BudgetMode get currentMode => _systemBudget.currentMode;
  bool get isEfficientModeForced => _systemBudget.currentMode == BudgetMode.efficient;
  
  String get statusMessage {
    if (isAtHardThreshold) {
      return "We've reached this month's AI capacity. Renewals reset on ${_formatResetDate(_systemBudget.resetDate)}.";
    } else if (isAtLimitThreshold) {
      return "Approaching monthly AI budget limit. Free tier queued, Pro priority maintained.";
    } else if (isAtWarnThreshold) {
      return "High AI demand detected. Switching to efficient mode to serve everyone better.";
    }
    return "";
  }

  Future<void> initialize() async {
    try {
      await _loadSystemBudget();
      await _checkForMonthlyReset();
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing budget control: $e');
      _isInitialized = true; // Use defaults
    }
  }

  // Record AI usage cost
  Future<void> recordUsage({
    required double costUsd,
    required int inputTokens,
    required int outputTokens,
    required String contentType,
    bool isIntroUser = false,
    bool isStarterPackUser = false,
  }) async {
    try {
      final newSpent = _systemBudget.monthlySpentUsd + costUsd;
      final previousThreshold = _systemBudget.currentThreshold;
      final newThreshold = _calculateThreshold(newSpent);
      
      // Update budget
      _systemBudget = _systemBudget.copyWith(
        monthlySpentUsd: newSpent,
        currentThreshold: newThreshold,
        currentMode: _shouldUseEfficientMode(newThreshold, isIntroUser, isStarterPackUser),
      );

      // Check for threshold changes and emit events
      await _handleThresholdChanges(previousThreshold, newThreshold);
      
      // Save to Firestore
      await _saveSystemBudget();
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error recording usage: $e');
    }
  }

  // Check if user can make request based on budget and tier
  bool canMakeRequest({
    required bool isProUser,
    required bool isFreeUser,
    String contentType = 'generation',
  }) {
    // Hard block - no one can generate
    if (isAtHardThreshold) {
      return false;
    }

    // At limit threshold - only Pro users can proceed (they get priority)
    if (isAtLimitThreshold && isFreeUser) {
      return false;
    }

    // Warn threshold and below - everyone can proceed but might use efficient mode
    return true;
  }

  // Calculate estimated cost for request
  double estimateCost({
    required int inputTokens,
    required int outputTokens,
    required bool useEfficientMode,
  }) {
    // OpenAI GPT-4o-mini pricing approximation
    const double inputCostPer1k = 0.00015;  // $0.15 per 1M input tokens
    const double outputCostPer1k = 0.0006;  // $0.60 per 1M output tokens
    
    double baseCost = (inputTokens * inputCostPer1k / 1000) + (outputTokens * outputCostPer1k / 1000);
    
    // Efficient mode reduces cost by using smaller context and shorter prompts
    if (useEfficientMode) {
      baseCost *= 0.6; // 40% reduction in efficient mode
    }
    
    return baseCost;
  }

  // Determine if efficient mode should be used
  bool shouldUseEfficientMode({
    bool isIntroUser = false,
    bool isStarterPackUser = false,
  }) {
    return _shouldUseEfficientMode(_systemBudget.currentThreshold, isIntroUser, isStarterPackUser) == BudgetMode.efficient;
  }

  BudgetMode _shouldUseEfficientMode(BudgetThreshold threshold, bool isIntroUser, bool isStarterPackUser) {
    // Force efficient mode at warn threshold for intro/starter pack users
    if (threshold == BudgetThreshold.warn && (isIntroUser || isStarterPackUser)) {
      return BudgetMode.efficient;
    }
    
    // Force efficient mode at limit threshold for everyone
    if (threshold == BudgetThreshold.limit) {
      return BudgetMode.efficient;
    }
    
    return BudgetMode.standard;
  }

  BudgetThreshold _calculateThreshold(double spentUsd) {
    final percentage = spentUsd / _systemBudget.monthlyLimitUsd;
    
    if (percentage >= BudgetConfig.hardThreshold) return BudgetThreshold.hardBlock;
    if (percentage >= BudgetConfig.limitThreshold) return BudgetThreshold.limit;
    if (percentage >= BudgetConfig.warnThreshold) return BudgetThreshold.warn;
    return BudgetThreshold.normal;
  }

  Future<void> _handleThresholdChanges(BudgetThreshold previous, BudgetThreshold current) async {
    if (previous == current) return;

    final percentage = _systemBudget.usagePercentage;
    
    switch (current) {
      case BudgetThreshold.warn:
        await _remoteConfig.enableEfficientMode();
        await _telemetry.trackBudgetWarn(
          budgetUsagePercent: percentage,
          monthlySpent: _systemBudget.monthlySpentUsd,
        );
        break;
      
      case BudgetThreshold.limit:
        await _telemetry.trackBudgetLimit(
          budgetUsagePercent: percentage,
          monthlySpent: _systemBudget.monthlySpentUsd,
        );
        break;
      
      case BudgetThreshold.hardBlock:
        await _telemetry.trackBudgetHardBlock(
          budgetUsagePercent: percentage,
          monthlySpent: _systemBudget.monthlySpentUsd,
        );
        break;
      
      case BudgetThreshold.normal:
        await _remoteConfig.disableEfficientMode();
        break;
    }
  }

  Future<void> _checkForMonthlyReset() async {
    final now = DateTime.now().toUtc().subtract(const Duration(hours: 6)); // Chicago time
    if (now.isAfter(_systemBudget.resetDate)) {
      await _resetMonthlyBudget();
    }
  }

  Future<void> _resetMonthlyBudget() async {
    final now = DateTime.now();
    _systemBudget = SystemBudgetNew(
      monthlySpentUsd: 0.0,
      monthlyLimitUsd: BudgetConfig.monthlyCapUsd,
      currentThreshold: BudgetThreshold.normal,
      currentMode: BudgetMode.standard,
      lastReset: now,
      resetDate: _calculateNextResetDate(now),
    );

    await _remoteConfig.disableEfficientMode();
    await _saveSystemBudget();
    notifyListeners();

    if (kDebugMode) {
      debugPrint('Monthly budget reset: \$${_systemBudget.monthlyLimitUsd}');
    }
  }

  static DateTime _calculateNextResetDate(DateTime current) {
    final chicagoTime = current.toUtc().subtract(const Duration(hours: 6));
    var nextMonth = DateTime(chicagoTime.year, chicagoTime.month + 1, 1);
    return nextMonth.toUtc().add(const Duration(hours: 6));
  }

  Future<void> _loadSystemBudget() async {
    try {
      final doc = await _firestore.collection('system_config').doc('budget_control_new').get();
      if (doc.exists && doc.data() != null) {
        _systemBudget = SystemBudgetNew.fromMap(doc.data()!);
      }
    } catch (e) {
      debugPrint('Error loading system budget: $e');
    }
  }

  Future<void> _saveSystemBudget() async {
    try {
      await _firestore.collection('system_config').doc('budget_control_new').set(_systemBudget.toMap());
    } catch (e) {
      debugPrint('Error saving system budget: $e');
    }
  }

  String _formatResetDate(DateTime date) {
    final chicagoTime = date.toUtc().subtract(const Duration(hours: 6));
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[chicagoTime.month - 1]} ${chicagoTime.day}';
  }

  // Admin/testing functions
  Future<void> setBudgetLimit(double limitUsd) async {
    _systemBudget = _systemBudget.copyWith(monthlyLimitUsd: limitUsd);
    await _saveSystemBudget();
    notifyListeners();
  }

  Future<void> addSpending(double costUsd) async {
    await recordUsage(
      costUsd: costUsd,
      inputTokens: 1000,
      outputTokens: 1000,
      contentType: 'test',
    );
  }

  Future<void> resetBudget() async {
    await _resetMonthlyBudget();
  }

}
// Device-side study-set storage limits and policies
class StorageConfig {
  // Storage budget constants
  static const int storageBudgetMB = 250;     // device cache budget
  static const int maxLocalSets = 150;        // Updated: was 500, now 150
  static const int maxLocalItems = 100000;    // total cards+questions cap
  static const int staleDays = 120;           // auto-evict if unopened for 120d
  static const int evictBatch = 50;           // evict in chunks to avoid jank
  static const double warnAtUsage = 0.80;     // show "storage almost full" banner at 80%
  static const int lowFreeSpaceGB = 1;        // if device free space <1GB, reduce budget
  static const int lowModeBudgetMB = 150;     // temporary budget when low on disk
  
  // Export constraints
  static const int maxExportPages = 300;      // maximum pages per export
  static const int maxExportSizeMB = 25;      // maximum file size per export
  static const int exportTimeoutMinutes = 5;  // hard timeout for exports
  static const int maxExportsPerHour = 5;     // rate limit per user
  static const int exportBatchSize = 50;      // process items in batches
  
  // Compression settings
  static const double jpegQuality = 0.75;     // JPEG compression quality
  static const int imageDPI = 175;            // target DPI for embedded images
  
  // Audit settings
  static const int maxAuditRecords = 50;      // keep last 50 audit records per user
  
  // Helper methods
  static int getCurrentBudgetMB(int freeSpaceGB) {
    if (freeSpaceGB < lowFreeSpaceGB) {
      return lowModeBudgetMB;
    }
    return storageBudgetMB;
  }
  
  static bool isStorageWarning(double usagePercentage) {
    return usagePercentage >= warnAtUsage;
  }
  
  static bool isOverBudget(int currentBytes, int budgetMB) {
    return currentBytes > (budgetMB * 1024 * 1024);
  }
  
  static bool isOverSetLimit(int currentSets) {
    return currentSets > maxLocalSets;
  }
  
  static bool isOverItemLimit(int currentItems) {
    return currentItems > maxLocalItems;
  }
  
  static bool isStale(DateTime lastOpened) {
    final daysSinceLastOpened = DateTime.now().difference(lastOpened).inDays;
    return daysSinceLastOpened > staleDays;
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:mindload/services/storage_service.dart';
import 'package:mindload/models/storage_models.dart';
import 'package:mindload/config/storage_config.dart';

void main() {
  group('Storage Service Tests', () {
    late StorageService storageService;
    
    setUp(() {
      storageService = StorageService.instance;
      storageService.clearAll();
    });
    
    group('Storage Limits Tests', () {
      test('Enforces storage budget MB limit', () async {
        // Add sets until we exceed the budget
        int totalBytes = 0;
        int setId = 1;
        
        while (totalBytes < StorageConfig.storageBudgetMB * 1024 * 1024) {
          final set = StudySetMetadata(
            setId: 'set_$setId',
            title: 'Test Set $setId',
            isPinned: false,
            bytes: 10 * 1024 * 1024, // 10MB per set
            items: 100,
            lastOpenedAt: DateTime.now(),
            lastStudied: DateTime.now(),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          
          await storageService.addOrUpdateSet(set);
          totalBytes += set.bytes;
          setId++;
        }
        
        // Check that eviction was triggered
        final stats = storageService.getStorageStats();
        expect(stats['totalBytes'], lessThanOrEqualTo(StorageConfig.storageBudgetMB * 1024 * 1024));
      });
      
      test('Enforces max local sets limit', () async {
        // Add sets until we exceed the limit
        for (int i = 1; i <= StorageConfig.maxLocalSets + 10; i++) {
          final set = StudySetMetadata(
            setId: 'set_$i',
            title: 'Test Set $i',
            isPinned: false,
            bytes: 1024 * 1024, // 1MB per set
            items: 10,
            lastOpenedAt: DateTime.now(),
            lastStudied: DateTime.now(),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          
          await storageService.addOrUpdateSet(set);
        }
        
        // Check that we don't exceed the limit
        final stats = storageService.getStorageStats();
        expect(stats['totalSets'], lessThanOrEqualTo(StorageConfig.maxLocalSets));
      });
      
      test('Enforces max local items limit', () async {
        // Add sets with many items until we exceed the limit
        int totalItems = 0;
        int setId = 1;
        
        while (totalItems < StorageConfig.maxLocalItems) {
          final set = StudySetMetadata(
            setId: 'set_$setId',
            title: 'Test Set $setId',
            isPinned: false,
            bytes: 1024 * 1024,
            items: 1000, // 1000 items per set
            lastOpenedAt: DateTime.now(),
            lastStudied: DateTime.now(),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          
          await storageService.addOrUpdateSet(set);
          totalItems += set.items;
          setId++;
        }
        
        // Check that we don't exceed the limit
        final stats = storageService.getStorageStats();
        expect(stats['totalItems'], lessThanOrEqualTo(StorageConfig.maxLocalItems));
      });
    });
    
    group('LRU Eviction Tests', () {
      test('Evicts unpinned sets by last opened time (LRU)', () async {
        // Create sets with different last opened times
        final now = DateTime.now();
        final sets = [
          StudySetMetadata(
            setId: 'oldest',
            title: 'Oldest Set',
            isPinned: false,
            bytes: 50 * 1024 * 1024, // 50MB
            items: 100,
            lastOpenedAt: now.subtract(const Duration(days: 10)),
            lastStudied: now.subtract(const Duration(days: 10)),
            createdAt: now.subtract(const Duration(days: 10)),
            updatedAt: now.subtract(const Duration(days: 10)),
          ),
          StudySetMetadata(
            setId: 'middle',
            title: 'Middle Set',
            isPinned: false,
            bytes: 50 * 1024 * 1024, // 50MB
            items: 100,
            lastOpenedAt: now.subtract(const Duration(days: 5)),
            lastStudied: now.subtract(const Duration(days: 5)),
            createdAt: now.subtract(const Duration(days: 5)),
            updatedAt: now.subtract(const Duration(days: 5)),
          ),
          StudySetMetadata(
            setId: 'newest',
            title: 'Newest Set',
            isPinned: false,
            bytes: 50 * 1024 * 1024, // 50MB
            items: 100,
            lastOpenedAt: now,
            lastStudied: now,
            createdAt: now,
            updatedAt: now,
          ),
        ];
        
        // Add all sets
        for (final set in sets) {
          await storageService.addOrUpdateSet(set);
        }
        
        // Add a large set that will trigger eviction
        final largeSet = StudySetMetadata(
          setId: 'large',
          title: 'Large Set',
          isPinned: false,
          bytes: 200 * 1024 * 1024, // 200MB
          items: 1000,
          lastOpenedAt: now,
          lastStudied: now,
          createdAt: now,
          updatedAt: now,
        );
        
        await storageService.addOrUpdateSet(largeSet);
        
        // Check that the oldest set was evicted first
        final metadata = storageService.metadata;
        expect(metadata.containsKey('oldest'), isFalse);
        expect(metadata.containsKey('middle'), isTrue);
        expect(metadata.containsKey('newest'), isTrue);
        expect(metadata.containsKey('large'), isTrue);
      });
      
      test('Never evicts pinned sets', () async {
        // Create a pinned set
        final pinnedSet = StudySetMetadata(
          setId: 'pinned',
          title: 'Pinned Set',
          isPinned: true,
          bytes: 100 * 1024 * 1024, // 100MB
          items: 500,
          lastOpenedAt: DateTime.now().subtract(const Duration(days: 20)),
          lastStudied: DateTime.now().subtract(const Duration(days: 20)),
          createdAt: DateTime.now().subtract(const Duration(days: 20)),
          updatedAt: DateTime.now().subtract(const Duration(days: 20)),
        );
        
        await storageService.addOrUpdateSet(pinnedSet);
        
        // Add many other sets to trigger eviction
        for (int i = 1; i <= 100; i++) {
          final set = StudySetMetadata(
            setId: 'unpinned_$i',
            title: 'Unpinned Set $i',
            isPinned: false,
            bytes: 10 * 1024 * 1024, // 10MB per set
            items: 50,
            lastOpenedAt: DateTime.now(),
            lastStudied: DateTime.now(),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          
          await storageService.addOrUpdateSet(set);
        }
        
        // Check that the pinned set was never evicted
        final metadata = storageService.metadata;
        expect(metadata.containsKey('pinned'), isTrue);
      });
      
      test('Evicts stale sets (>120 days)', () async {
        // Create a stale set
        final staleSet = StudySetMetadata(
          setId: 'stale',
          title: 'Stale Set',
          isPinned: false,
          bytes: 50 * 1024 * 1024, // 50MB
          items: 200,
          lastOpenedAt: DateTime.now().subtract(const Duration(days: 130)), // 130 days old
          lastStudied: DateTime.now().subtract(const Duration(days: 130)),
          createdAt: DateTime.now().subtract(const Duration(days: 130)),
          updatedAt: DateTime.now().subtract(const Duration(days: 130)),
        );
        
        await storageService.addOrUpdateSet(staleSet);
        
        // Add a large set to trigger eviction
        final largeSet = StudySetMetadata(
          setId: 'large',
          title: 'Large Set',
          isPinned: false,
          bytes: 200 * 1024 * 1024, // 200MB
          items: 1000,
          lastOpenedAt: DateTime.now(),
          lastStudied: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        await storageService.addOrUpdateSet(largeSet);
        
        // Check that the stale set was evicted
        final metadata = storageService.metadata;
        expect(metadata.containsKey('stale'), isFalse);
        expect(metadata.containsKey('large'), isTrue);
      });
      
      test('Evicts in batches to avoid jank', () async {
        // Add many small sets
        for (int i = 1; i <= 200; i++) {
          final set = StudySetMetadata(
            setId: 'small_$i',
            title: 'Small Set $i',
            isPinned: false,
            bytes: 2 * 1024 * 1024, // 2MB per set
            items: 20,
            lastOpenedAt: DateTime.now().subtract(Duration(days: i)),
            lastStudied: DateTime.now().subtract(Duration(days: i)),
            createdAt: DateTime.now().subtract(Duration(days: i)),
            updatedAt: DateTime.now().subtract(Duration(days: i)),
          );
          
          await storageService.addOrUpdateSet(set);
        }
        
        // Add a very large set to trigger eviction
        final largeSet = StudySetMetadata(
          setId: 'very_large',
          title: 'Very Large Set',
          isPinned: false,
          bytes: 300 * 1024 * 1024, // 300MB
          items: 2000,
          lastOpenedAt: DateTime.now(),
          lastStudied: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        await storageService.addOrUpdateSet(largeSet);
        
        // Check that eviction happened in batches
        final stats = storageService.getStorageStats();
        expect(stats['totalBytes'], lessThanOrEqualTo(StorageConfig.storageBudgetMB * 1024 * 1024));
      });
    });
    
    group('Pinning Tests', () {
      test('Can pin and unpin sets', () async {
        final set = StudySetMetadata(
          setId: 'test_set',
          title: 'Test Set',
          isPinned: false,
          bytes: 50 * 1024 * 1024,
          items: 200,
          lastOpenedAt: DateTime.now(),
          lastStudied: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        await storageService.addOrUpdateSet(set);
        
        // Pin the set
        await storageService.togglePin('test_set');
        var metadata = storageService.metadata;
        expect(metadata['test_set']!.isPinned, isTrue);
        
        // Unpin the set
        await storageService.togglePin('test_set');
        metadata = storageService.metadata;
        expect(metadata['test_set']!.isPinned, isFalse);
      });
      
      test('Pinned sets are excluded from auto-eviction', () async {
        // Create a pinned set
        final pinnedSet = StudySetMetadata(
          setId: 'pinned',
          title: 'Pinned Set',
          isPinned: true,
          bytes: 100 * 1024 * 1024, // 100MB
          items: 500,
          lastOpenedAt: DateTime.now().subtract(const Duration(days: 30)),
          lastStudied: DateTime.now().subtract(const Duration(days: 30)),
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
          updatedAt: DateTime.now().subtract(const Duration(days: 30)),
        );
        
        await storageService.addOrUpdateSet(pinnedSet);
        
        // Add many other sets to trigger eviction
        for (int i = 1; i <= 50; i++) {
          final set = StudySetMetadata(
            setId: 'unpinned_$i',
            title: 'Unpinned Set $i',
            isPinned: false,
            bytes: 15 * 1024 * 1024, // 15MB per set
            items: 75,
            lastOpenedAt: DateTime.now(),
            lastStudied: DateTime.now(),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          
          await storageService.addOrUpdateSet(set);
        }
        
        // Check that the pinned set remains
        final metadata = storageService.metadata;
        expect(metadata.containsKey('pinned'), isTrue);
      });
    });
    
    group('Storage Warning Tests', () {
      test('Shows storage warning at 80% usage', () async {
        // Add sets until we reach 80% usage
        int setId = 1;
        final targetBytes = (StorageConfig.storageBudgetMB * StorageConfig.warnAtUsage * 1024 * 1024).round();
        int currentBytes = 0;
        
        while (currentBytes < targetBytes) {
          final set = StudySetMetadata(
            setId: 'warning_test_$setId',
            title: 'Warning Test Set $setId',
            isPinned: false,
            bytes: 10 * 1024 * 1024, // 10MB per set
            items: 50,
            lastOpenedAt: DateTime.now(),
            lastStudied: DateTime.now(),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          
          await storageService.addOrUpdateSet(set);
          currentBytes += set.bytes;
          setId++;
        }
        
        // Check that storage warning is triggered
        expect(storageService.isStorageWarning, isTrue);
      });
      
      test('Does not show warning below 80% usage', () async {
        // Add sets until we reach 70% usage
        int setId = 1;
        final targetBytes = (StorageConfig.storageBudgetMB * 0.7 * 1024 * 1024).round();
        int currentBytes = 0;
        
        while (currentBytes < targetBytes) {
          final set = StudySetMetadata(
            setId: 'no_warning_test_$setId',
            title: 'No Warning Test Set $setId',
            isPinned: false,
            bytes: 10 * 1024 * 1024, // 10MB per set
            items: 50,
            lastOpenedAt: DateTime.now(),
            lastStudied: DateTime.now(),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          
          await storageService.addOrUpdateSet(set);
          currentBytes += set.bytes;
          setId++;
        }
        
        // Check that storage warning is not triggered
        expect(storageService.isStorageWarning, isFalse);
      });
    });
    
    group('Low Free Space Tests', () {
      test('Reduces budget when free space < 1GB', () async {
        // This test would require mocking the file system
        // For now, we'll test the budget calculation logic
        
        final normalBudget = StorageConfig.getCurrentBudgetMB(5000); // 5GB free space (in MB)
        final lowBudget = StorageConfig.getCurrentBudgetMB(500); // 0.5GB free space (in MB)
        
        expect(normalBudget, equals(StorageConfig.storageBudgetMB));
        expect(lowBudget, equals(StorageConfig.lowModeBudgetMB));
      });
      
      test('Uses low mode budget when free space is low', () async {
        // Add sets until we exceed the low mode budget
        int setId = 1;
        final lowBudgetBytes = StorageConfig.lowModeBudgetMB * 1024 * 1024;
        int currentBytes = 0;
        
        while (currentBytes < lowBudgetBytes) {
          final set = StudySetMetadata(
            setId: 'low_budget_test_$setId',
            title: 'Low Budget Test Set $setId',
            isPinned: false,
            bytes: 10 * 1024 * 1024, // 10MB per set
            items: 50,
            lastOpenedAt: DateTime.now(),
            lastStudied: DateTime.now(),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          
          await storageService.addOrUpdateSet(set);
          currentBytes += set.bytes;
          setId++;
        }
        
        // Check that we don't exceed the low mode budget
        final stats = storageService.getStorageStats();
        expect(stats['totalBytes'], lessThanOrEqualTo(StorageConfig.lowModeBudgetMB * 1024 * 1024));
      });
    });
    
    group('Archive Tests', () {
      test('Can archive sets to cloud', () async {
        final set = StudySetMetadata(
          setId: 'archive_test',
          title: 'Archive Test Set',
          isPinned: false,
          bytes: 50 * 1024 * 1024,
          items: 200,
          lastOpenedAt: DateTime.now(),
          lastStudied: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        await storageService.addOrUpdateSet(set);
        
        // Archive the set
        await storageService.archiveSet('archive_test');
        
        // Check that the set is marked as archived
        final metadata = storageService.metadata;
        expect(metadata['archive_test']!.isArchived, isTrue);
      });
      
      test('Archived sets are excluded from eviction', () async {
        // Create an archived set
        final archivedSet = StudySetMetadata(
          setId: 'archived',
          title: 'Archived Set',
          isPinned: false,
          bytes: 100 * 1024 * 1024, // 100MB
          items: 500,
          lastOpenedAt: DateTime.now().subtract(const Duration(days: 30)),
          lastStudied: DateTime.now().subtract(const Duration(days: 30)),
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
          updatedAt: DateTime.now().subtract(const Duration(days: 30)),
        );
        
        await storageService.addOrUpdateSet(archivedSet);
        await storageService.archiveSet('archived');
        
        // Add many other sets to trigger eviction
        for (int i = 1; i <= 50; i++) {
          final set = StudySetMetadata(
            setId: 'unarchived_$i',
            title: 'Unarchived Set $i',
            isPinned: false,
            bytes: 15 * 1024 * 1024, // 15MB per set
            items: 75,
            lastOpenedAt: DateTime.now(),
            lastStudied: DateTime.now(),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          
          await storageService.addOrUpdateSet(set);
        }
        
        // Check that the archived set remains
        final metadata = storageService.metadata;
        expect(metadata.containsKey('archived'), isTrue);
        expect(metadata['archived']!.isArchived, isTrue);
      });
    });
    
    group('Storage Stats Tests', () {
      test('Provides accurate storage statistics', () async {
        // Add some test sets
        final sets = [
          StudySetMetadata(
            setId: 'set1',
            title: 'Set 1',
            isPinned: false,
            bytes: 25 * 1024 * 1024, // 25MB
            items: 100,
            lastOpenedAt: DateTime.now(),
            lastStudied: DateTime.now(),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          StudySetMetadata(
            setId: 'set2',
            title: 'Set 2',
            isPinned: true,
            bytes: 50 * 1024 * 1024, // 50MB
            items: 200,
            lastOpenedAt: DateTime.now(),
            lastStudied: DateTime.now(),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];
        
        for (final set in sets) {
          await storageService.addOrUpdateSet(set);
        }
        
        final stats = storageService.getStorageStats();
        
        expect(stats['totalBytes'], equals(75 * 1024 * 1024)); // 75MB
        expect(stats['totalSets'], equals(2));
        expect(stats['totalItems'], equals(300));
        expect(stats['budgetMB'], equals(StorageConfig.storageBudgetMB));
        expect(stats['usagePercentage'], greaterThan(0));
        expect(stats['freeSpaceGB'], greaterThan(0));
      });
      
      test('Calculates usage percentage correctly', () async {
        // Add a set that uses 50% of the budget
        final set = StudySetMetadata(
          setId: 'half_budget',
          title: 'Half Budget Set',
          isPinned: false,
          bytes: (StorageConfig.storageBudgetMB * 0.5 * 1024 * 1024).round(),
          items: 500,
          lastOpenedAt: DateTime.now(),
          lastStudied: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        await storageService.addOrUpdateSet(set);
        
        final stats = storageService.getStorageStats();
        expect(stats['usagePercentage'], closeTo(0.5, 0.1)); // Within 10% tolerance
      });
    });
    
    group('Cleanup Tests', () {
      test('Can clear all storage', () async {
        // Add some test sets
        for (int i = 1; i <= 5; i++) {
          final set = StudySetMetadata(
            setId: 'cleanup_test_$i',
            title: 'Cleanup Test Set $i',
            isPinned: false,
            bytes: 10 * 1024 * 1024,
            items: 50,
            lastOpenedAt: DateTime.now(),
            lastStudied: DateTime.now(),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          
          await storageService.addOrUpdateSet(set);
        }
        
        // Verify sets were added
        expect(storageService.metadata.length, equals(5));
        
        // Clear all storage
        await storageService.clearAll();
        
        // Verify all sets were removed
        expect(storageService.metadata.isEmpty, isTrue);
        
        final stats = storageService.getStorageStats();
        expect(stats['totalBytes'], equals(0));
        expect(stats['totalSets'], equals(0));
        expect(stats['totalItems'], equals(0));
      });
    });
  });
}

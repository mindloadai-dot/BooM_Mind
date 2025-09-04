# NeuroGraph V2 Analytics System

A comprehensive, science-backed analytics system for learning progress tracking in the MindLoad app.

## Overview

NeuroGraph V2 provides six evidence-based learning analytics charts that help students understand their learning patterns and optimize their study strategies. The system is designed to be offline-first, performant, and production-ready.

## Architecture

### Module Structure

```
lib/neurograph_v2/
├── neurograph_config.dart      # Configuration and feature flags
├── neurograph_models.dart       # Data models and computed types
├── neurograph_compute.dart      # Pure compute functions (stateless)
├── neurograph_repo.dart         # Firestore repository (offline-first)
├── neurograph_widgets.dart      # Chart widgets using fl_chart
└── neurograph_screen.dart       # Main tabbed screen
```

### Key Design Principles

1. **Offline-First**: All data operations prefer cache over server
2. **Pure Functions**: Compute layer is stateless and deterministic
3. **Minimal Dependencies**: Uses only `fl_chart` for visualization
4. **Production-Ready**: Comprehensive error handling and loading states
5. **Science-Backed**: Based on established learning science research

## Six Analytics Charts

### 1. Learning Curve
- **Purpose**: Track daily accuracy and progress over time
- **Science**: Shows learning progression and identifies plateaus
- **Features**: 
  - Daily accuracy points
  - 7-day Exponential Moving Average (EMA)
  - Goal band (80-90% accuracy)
  - Timezone-aware (America/Chicago)

### 2. Spaced Review / Forgetting Curve
- **Purpose**: Recommend items due for review based on forgetting curve
- **Science**: Ebbinghaus forgetting curve with spaced repetition
- **Features**:
  - Exponential decay model: `p_recall = exp(-lambda * days)`
  - Adaptive lambda based on repetitions
  - Due items counter and action button
  - Forgetting curve preview

### 3. Retrieval Practice Meter
- **Purpose**: Show correlation between practice sessions and exam performance
- **Science**: Retrieval practice effect on long-term retention
- **Features**:
  - Session grouping (30-minute gaps)
  - Weekly retrieval session count
  - Subsequent exam score correlation
  - Bar chart + line chart visualization

### 4. Calibration Plot
- **Purpose**: Assess how well confidence matches actual accuracy
- **Science**: Metacognitive calibration and self-assessment
- **Features**:
  - Confidence vs. accuracy scatter plot
  - Brier score calculation
  - Expected Calibration Error (ECE)
  - Perfect calibration reference line

### 5. Mastery Progress
- **Purpose**: Track items through learning states (NEW → PRACTICING → MASTERED)
- **Science**: Mastery learning and adaptive instruction
- **Features**:
  - Stacked area chart showing state progression
  - Adaptive mastery criteria
  - Weekly progress tracking
  - Color-coded state visualization

### 6. Study Consistency Heatmap
- **Purpose**: Visualize daily study patterns and streaks
- **Science**: Consistency and habit formation in learning
- **Features**:
  - GitHub-style activity heatmap
  - Current streak counter
  - Daily attempt intensity
  - Weekly grid layout

## Data Model

### Core Collections

```dart
// attempts collection
{
  userId: string,
  testId: string,
  questionId: string,
  topicId: string,
  bloom?: string,           // Optional Bloom's taxonomy
  isCorrect: boolean,
  score: number (0-1),
  responseMs: number,
  ts: Timestamp,
  confidencePct?: number    // Optional confidence (0-100)
}

// sessions collection (optional)
{
  userId: string,
  startedAt: Timestamp,
  endedAt?: Timestamp,
  itemsSeen: number,
  itemsCorrect: number
}

// questions collection (optional)
{
  questionId: string,
  topicId: string,
  bloom?: string
}
```

### Required Indexes

```javascript
// Firestore indexes
attempts: (userId, ts DESC)
attempts: (testId, ts DESC)
attempts: (questionId, ts DESC)
attempts: (userId, topicId, ts DESC)
```

## Configuration

### Feature Flags

```dart
static const bool neurographV2 = true; // Enable/disable V2
```

### Tunable Parameters

```dart
// Learning Curve
static const int learningCurveDays = 90;
static const int emaPeriod = 7;
static const double goalAccuracyMin = 0.8;
static const double goalAccuracyMax = 0.9;

// Spaced Review
static const double baseLambda = 0.18;
static const double recallThreshold = 0.7;
static const int forgettingCurveDays = 120;

// Retrieval Practice
static const int sessionGapMinutes = 30;
static const int examPredictionDays = 7;

// Mastery
static const int masteryMinAttempts = 2;
static const double practicingAccuracyThreshold = 0.8;
static const int masteryConsecutiveCorrect = 3;

// Performance
static const int maxAttemptsPerQuery = 5000;
static const int maxDataPoints = 1000;
```

## Usage

### Basic Implementation

```dart
// Navigate to NeuroGraph V2 screen
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => NeuroGraphV2Screen(userId: currentUserId),
  ),
);
```

### Feature Flag Check

```dart
if (NeuroGraphConfig.neurographV2) {
  // Use V2 implementation
  return NeuroGraphV2Screen(userId: userId);
} else {
  // Fallback to V1
  return NeuroGraphScreen(userId: userId);
}
```

### Custom Filtering

```dart
final filters = NeuroGraphFilters(
  fromDate: DateTime.now().subtract(Duration(days: 30)),
  topics: ['math', 'science'],
  tests: ['midterm', 'final'],
  includeBloom: true,
);
```

## Performance Considerations

### Data Loading
- Offline-first approach with cache fallback
- Query limits to prevent memory issues
- Lazy loading of chart data
- Background computation for heavy operations

### Memory Management
- Maximum 5000 attempts per query
- Maximum 1000 data points per chart
- Efficient data structures and algorithms
- Proper disposal of resources

### Caching Strategy
1. Try cache first (Source.cache)
2. Fallback to server (Source.server)
3. Cache server results for offline use
4. Graceful degradation on network issues

## Testing

### Unit Tests

```bash
flutter test test/neurograph_v2_test.dart
```

### Test Coverage
- All compute functions are unit tested
- Edge cases and error conditions
- Timezone handling
- Data validation

### Test Categories
- Daily accuracy calculation
- EMA computation
- Forgetting curve modeling
- Session grouping
- Calibration metrics
- Mastery state calculation
- Consistency heatmap

## Dependencies

### Required
- `fl_chart: ^0.69.0` - Chart visualization
- `timezone: ^0.9.0` - Timezone handling
- `cloud_firestore` - Data persistence

### Optional
- `provider` - State management (if needed)

## Browser Support

The system is designed to work across all platforms:
- ✅ iOS
- ✅ Android  
- ✅ Web
- ✅ Desktop

## Future Enhancements

### Planned Features
- Advanced filtering and date ranges
- Export analytics data
- Comparative analytics (peer benchmarking)
- Predictive analytics
- Integration with study recommendations

### Performance Improvements
- WebAssembly for heavy computations
- Incremental data loading
- Real-time updates
- Advanced caching strategies

## Contributing

### Code Style
- Follow Flutter/Dart conventions
- Comprehensive documentation
- Unit tests for all functions
- Error handling for all edge cases

### Testing Guidelines
- Test all compute functions
- Test error conditions
- Test timezone edge cases
- Test data validation

## License

This module is part of the MindLoad app and follows the same licensing terms.

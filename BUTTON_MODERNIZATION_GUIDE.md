# Mindload Button Modernization Guide

This guide explains how to modernize all clickable buttons throughout the Mindload app to align with the semantic theme and provide a consistent, accessible user experience.

## Overview

The app now includes a comprehensive button system that replaces direct usage of Flutter's `ElevatedButton`, `OutlinedButton`, and `TextButton` with semantic, themed buttons that automatically adapt to the app's design tokens.

## New Button System Components

### Core Button Classes

1. **`MindloadButton`** - The base button class with full customization
2. **`PrimaryButton`** - Main action buttons (e.g., "Save", "Continue", "Submit")
3. **`SecondaryButton`** - Alternative action buttons (e.g., "Cancel", "Back")
4. **`SuccessButton`** - Confirmation/success actions (e.g., "Confirm", "Activate")
5. **`DestructiveButton`** - Dangerous actions (e.g., "Delete", "Remove", "Sign Out")
6. **`WarningButton`** - Caution actions (e.g., "Archive", "Suspend")
7. **`MindloadTextButton`** - Minimal emphasis actions
8. **`IconOnlyButton`** - Compact icon-only actions
9. **`MindloadFAB`** - Floating action buttons

### Layout Components

1. **`ButtonGroup`** - Group related buttons with consistent spacing
2. **`ButtonRow`** - Horizontal button layout with equal width distribution
3. **`ButtonColumn`** - Vertical button layout with full width

### Utility Classes

1. **`ButtonHelpers`** - Static methods for button transformations
2. **`ButtonPresets`** - Pre-configured button configurations

## Migration Examples

### Before (Old Style)

```dart
// Old ElevatedButton with manual styling
ElevatedButton(
  onPressed: _saveChanges,
  style: ElevatedButton.styleFrom(
    backgroundColor: context.tokens.primary,
    foregroundColor: context.tokens.onPrimary,
    padding: const EdgeInsets.symmetric(vertical: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  ),
  child: const Text('Save Changes'),
)

// Old OutlinedButton with manual styling
OutlinedButton(
  onPressed: _cancel,
  style: OutlinedButton.styleFrom(
    side: BorderSide(color: context.tokens.outline),
    padding: const EdgeInsets.symmetric(vertical: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  ),
  child: const Text('Cancel'),
)
```

### After (New Style)

```dart
// New semantic buttons
PrimaryButton(
  onPressed: _saveChanges,
  child: const Text('Save Changes'),
)

SecondaryButton(
  onPressed: _cancel,
  child: const Text('Cancel'),
)
```

## Button Variants and Use Cases

### PrimaryButton
- **Use for**: Main actions, primary CTAs, form submissions
- **Examples**: "Save Changes", "Continue", "Submit", "Start Session"
- **Visual**: Filled background with primary color

```dart
PrimaryButton(
  onPressed: _startSession,
  icon: Icons.play_arrow,
  child: const Text('Start Ultra Session'),
)
```

### SecondaryButton
- **Use for**: Alternative actions, secondary CTAs, navigation
- **Examples**: "Cancel", "Back", "Learn More", "Settings"
- **Visual**: Outlined style with secondary emphasis

```dart
SecondaryButton(
  onPressed: _navigateToSettings,
  icon: Icons.settings,
  child: const Text('Settings'),
)
```

### DestructiveButton
- **Use for**: Dangerous or destructive actions
- **Examples**: "Delete", "Remove", "Sign Out", "Archive"
- **Visual**: Error color scheme with warning styling

```dart
DestructiveButton(
  onPressed: _deleteItem,
  icon: Icons.delete,
  child: const Text('Delete Item'),
)
```

### SuccessButton
- **Use for**: Confirmation and success actions
- **Examples**: "Confirm", "Activate", "Enable", "Complete"
- **Visual**: Success color scheme

```dart
SuccessButton(
  onPressed: _confirmAction,
  icon: Icons.check,
  child: const Text('Confirm'),
)
```

## Button Sizes

### ButtonSize.small (44x44 iOS, 48x48 Android)
- Use for: Compact interfaces, toolbars, inline actions
- Example: Icon buttons, small form buttons

### ButtonSize.medium (48x48) - Default
- Use for: Standard buttons, most UI elements
- Example: Form buttons, navigation buttons

### ButtonSize.large (56x height)
- Use for: Prominent actions, main CTAs
- Example: Primary action buttons, floating action buttons

## Advanced Features

### Loading States
```dart
PrimaryButton(
  onPressed: _isLoading ? null : _saveChanges,
  loading: _isLoading,
  child: const Text('Save Changes'),
)
```

### Icons
```dart
PrimaryButton(
  onPressed: _action,
  icon: Icons.save,
  iconPosition: IconPosition.start, // or IconPosition.end
  child: const Text('Save'),
)
```

### Full Width
```dart
PrimaryButton(
  onPressed: _action,
  fullWidth: true,
  child: const Text('Full Width Button'),
)
```

### Rounded Style
```dart
PrimaryButton(
  onPressed: _action,
  rounded: true,
  child: const Text('Rounded Button'),
)
```

### Custom Elevation
```dart
PrimaryButton(
  onPressed: _action,
  elevation: 4,
  child: const Text('Elevated Button'),
)
```

## Layout Patterns

### Button Row (Equal Width)
```dart
ButtonRow(
  children: [
    SecondaryButton(
      onPressed: _cancel,
      child: const Text('Cancel'),
    ),
    PrimaryButton(
      onPressed: _save,
      child: const Text('Save'),
    ),
  ],
)
```

### Button Column (Full Width)
```dart
ButtonColumn(
  children: [
    PrimaryButton(
      onPressed: _primaryAction,
      child: const Text('Primary Action'),
    ),
    SecondaryButton(
      onPressed: _secondaryAction,
      child: const Text('Secondary Action'),
    ),
  ],
)
```

### Button Group (Custom Spacing)
```dart
ButtonGroup(
  direction: Axis.horizontal,
  spacing: 16.0,
  children: [
    IconOnlyButton(
      onPressed: _edit,
      icon: Icons.edit,
    ),
    IconOnlyButton(
      onPressed: _delete,
      icon: Icons.delete,
    ),
  ],
)
```

## Migration Checklist

### Phase 1: Import and Basic Usage
- [ ] Import `package:mindload/widgets/mindload_button_system.dart`
- [ ] Replace `ElevatedButton` with `PrimaryButton`
- [ ] Replace `OutlinedButton` with `SecondaryButton`
- [ ] Replace `TextButton` with `MindloadTextButton`

### Phase 2: Enhanced Features
- [ ] Add appropriate icons to buttons
- [ ] Implement loading states where needed
- [ ] Use proper button sizes for context
- [ ] Apply full-width styling where appropriate

### Phase 3: Layout Optimization
- [ ] Replace manual button layouts with `ButtonRow`/`ButtonColumn`
- [ ] Use `ButtonGroup` for related button sets
- [ ] Implement consistent spacing throughout

### Phase 4: Advanced Features
- [ ] Add semantic labels for accessibility
- [ ] Implement tooltips for complex actions
- [ ] Use appropriate button variants for action types
- [ ] Test with different theme modes

## Common Migration Patterns

### Form Buttons
```dart
// Before
Row(
  children: [
    Expanded(
      child: OutlinedButton(
        onPressed: _cancel,
        child: const Text('Cancel'),
      ),
    ),
    const SizedBox(width: 16),
    Expanded(
      child: ElevatedButton(
        onPressed: _save,
        child: const Text('Save'),
      ),
    ),
  ],
)

// After
ButtonRow(
  children: [
    SecondaryButton(
      onPressed: _cancel,
      child: const Text('Cancel'),
    ),
    PrimaryButton(
      onPressed: _save,
      child: const Text('Save'),
    ),
  ],
)
```

### Dialog Actions
```dart
// Before
actions: [
  TextButton(
    onPressed: () => Navigator.pop(context),
    child: const Text('Cancel'),
  ),
  ElevatedButton(
    onPressed: _confirm,
    child: const Text('Confirm'),
  ),
]

// After
actions: [
  SecondaryButton(
    onPressed: () => Navigator.pop(context),
    child: const Text('Cancel'),
  ),
  PrimaryButton(
    onPressed: _confirm,
    child: const Text('Confirm'),
  ),
]
```

### Icon Buttons
```dart
// Before
IconButton(
  onPressed: _action,
  icon: const Icon(Icons.edit),
)

// After
IconOnlyButton(
  onPressed: _action,
  icon: Icons.edit,
  variant: ButtonVariant.outline,
)
```

## Benefits of the New System

1. **Consistency**: All buttons automatically use the app's semantic tokens
2. **Accessibility**: Built-in support for semantic labels, tooltips, and proper hit targets
3. **Maintainability**: Centralized button styling and behavior
4. **Performance**: Optimized rendering and state management
5. **Theme Support**: Automatic adaptation to light/dark themes and custom themes
6. **Internationalization**: Built-in support for RTL languages
7. **Responsive Design**: Automatic adaptation to different screen sizes

## Troubleshooting

### Common Issues

1. **Import Conflicts**: If you see naming conflicts, use the `Mindload` prefix versions
2. **Missing Properties**: Some old button properties may not have direct equivalents
3. **Layout Changes**: New buttons may have different default spacing

### Solutions

1. **Use `MindloadTextButton`** instead of `TextButton` to avoid conflicts
2. **Check the `ButtonHelpers`** class for transformation methods
3. **Use `ButtonRow`/`ButtonColumn`** for consistent layouts

## Examples by Screen Type

### Profile Screen
- Primary actions: Edit Profile, Save Changes
- Secondary actions: Cancel, Back
- Destructive actions: Sign Out, Delete Account

### Settings Screen
- Primary actions: Save Settings, Apply Changes
- Secondary actions: Reset to Defaults, Cancel
- Navigation: Back to Profile

### Paywall Screen
- Primary actions: Subscribe, Start Trial
- Secondary actions: Restore Purchases, Terms of Service
- Navigation: Close, Back

### Upload Screen
- Primary actions: Upload, Process, Generate
- Secondary actions: Cancel, Clear, Preview
- Destructive actions: Remove File

## Testing

### Visual Testing
- [ ] Test buttons in light theme
- [ ] Test buttons in dark theme
- [ ] Test buttons in custom themes
- [ ] Verify proper contrast ratios

### Accessibility Testing
- [ ] Test with screen readers
- [ ] Verify semantic labels
- [ ] Test keyboard navigation
- [ ] Verify proper hit targets

### Responsive Testing
- [ ] Test on different screen sizes
- [ ] Test in landscape/portrait
- [ ] Verify button scaling
- [ ] Test touch targets

## Conclusion

The new button system provides a modern, consistent, and accessible way to implement buttons throughout the Mindload app. By following this guide, you can ensure that all buttons align with the semantic theme and provide an excellent user experience.

For additional help or questions, refer to the `mindload_button_system.dart` file or consult the development team.

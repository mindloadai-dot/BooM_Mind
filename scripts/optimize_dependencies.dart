#!/usr/bin/env dart

import 'dart:io';

void main() async {
  print('🔍 Analyzing dependencies for App Store optimization...\n');

  // Read pubspec.yaml
  final pubspecFile = File('pubspec.yaml');
  if (!await pubspecFile.exists()) {
    print('❌ pubspec.yaml not found');
    exit(1);
  }

  final content = await pubspecFile.readAsString();
  final lines = content.split('\n');

  // Analyze dependencies
  final dependencies = <String, String>{};
  final devDependencies = <String, String>{};
  bool inDependencies = false;
  bool inDevDependencies = false;

  for (final line in lines) {
    final trimmed = line.trim();

    if (trimmed == 'dependencies:') {
      inDependencies = true;
      inDevDependencies = false;
      continue;
    }

    if (trimmed == 'dev_dependencies:') {
      inDependencies = false;
      inDevDependencies = true;
      continue;
    }

    if (trimmed.startsWith('flutter:') ||
        trimmed.startsWith('dependency_overrides:')) {
      inDependencies = false;
      inDevDependencies = false;
      continue;
    }

    if (inDependencies && trimmed.contains(':')) {
      final parts = trimmed.split(':');
      if (parts.length >= 2) {
        dependencies[parts[0].trim()] = parts[1].trim();
      }
    }

    if (inDevDependencies && trimmed.contains(':')) {
      final parts = trimmed.split(':');
      if (parts.length >= 2) {
        devDependencies[parts[0].trim()] = parts[1].trim();
      }
    }
  }

  print('📊 Dependency Analysis Results:\n');

  // Heavy dependencies that might impact IPA size
  final heavyDependencies = {
    'syncfusion_flutter_pdf': 'Large PDF library - consider alternatives',
    'google_fonts':
        'Downloads fonts at runtime - consider embedding only needed fonts',
    'firebase_core': 'Firebase base - essential but large',
    'cloud_firestore': 'Firestore client - large but necessary',
    'firebase_storage': 'Storage client - large but necessary',
    'just_audio': 'Audio processing - large but necessary',
    'audio_service': 'Audio service - large but necessary',
    'image_picker': 'Image picker - consider alternatives',
    'cached_network_image': 'Network image caching - large but useful',
  };

  print('⚠️  Heavy Dependencies (Potential Size Impact):');
  for (final dep in heavyDependencies.keys) {
    if (dependencies.containsKey(dep)) {
      print('   • $dep: ${heavyDependencies[dep]}');
    }
  }

  print('\n✅ Optimization Recommendations:\n');

  print('1. 🎵 Audio Assets (40+ MB):');
  print('   • Move audio files to CDN/dynamic loading');
  print('   • Compress audio files (reduce bitrate)');
  print('   • Use streaming instead of bundled files');

  print('\n2. 📦 Dependencies:');
  print('   • Consider removing unused dependencies');
  print('   • Use conditional imports for optional features');
  print('   • Split into multiple smaller packages');

  print('\n3. 🏗️  Build Optimizations:');
  print('   • Enable tree shaking (--tree-shake-icons)');
  print('   • Use obfuscation (--obfuscate)');
  print('   • Split debug info (--split-debug-info)');
  print('   • Strip debug symbols');

  print('\n4. 🖼️  Assets:');
  print('   • Optimize images (WebP format)');
  print('   • Remove unused assets');
  print('   • Use vector graphics where possible');

  print('\n5. 📱 App Store Specific:');
  print('   • Use App Thinning');
  print('   • Enable Bitcode (if supported)');
  print('   • Optimize for specific device families');

  // Calculate estimated size impact
  final totalDeps = dependencies.length + devDependencies.length;
  final heavyDeps = heavyDependencies.keys
      .where((dep) => dependencies.containsKey(dep))
      .length;

  print('\n📈 Size Impact Estimation:');
  print('   • Total dependencies: $totalDeps');
  print('   • Heavy dependencies: $heavyDeps');
  print(
      '   • Estimated IPA size: ${_estimateIpaSize(totalDeps, heavyDeps)} MB');

  print('\n🎯 Priority Actions:');
  print('   1. Move audio assets to dynamic loading (saves ~40 MB)');
  print('   2. Enable build optimizations (saves ~10-20 MB)');
  print('   3. Review and remove unused dependencies (saves ~5-15 MB)');
  print('   4. Optimize images and assets (saves ~2-5 MB)');

  print('\n✅ Analysis complete!');
}

String _estimateIpaSize(int totalDeps, int heavyDeps) {
  // Rough estimation based on dependency count and types
  final baseSize = 50; // Base Flutter app size
  final depSize = totalDeps * 2; // ~2MB per dependency
  final heavyDepSize = heavyDeps * 5; // ~5MB per heavy dependency

  return ((baseSize + depSize + heavyDepSize) / 1.5).round().toString();
}

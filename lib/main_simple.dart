import 'package:flutter/material.dart';
import 'package:mindload/screens/social_auth_screen.dart';
import 'package:mindload/theme.dart';
import 'package:mindload/services/mindload_economy_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize Theme Manager
    await ThemeManager.instance.loadTheme();
  } catch (e) {
    // Continue with default theme
  }

  try {
    // Initialize Mindload Economy Service
    await MindloadEconomyService.instance.initialize();
  } catch (e) {
    // Continue without economy service
  }
  
  runApp(const MinimalCogniFlowApp());
}

class MinimalCogniFlowApp extends StatelessWidget {
  const MinimalCogniFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mindload - AI Study Companion',
      debugShowCheckedModeBanner: false,
      theme: ThemeManager.instance.darkTheme,
      home: const SocialAuthScreen(),
    );
  }
}
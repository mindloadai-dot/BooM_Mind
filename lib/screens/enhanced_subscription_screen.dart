import 'package:flutter/material.dart';
import 'package:mindload/screens/my_plan_screen.dart';

class EnhancedSubscriptionScreen extends StatefulWidget {
  const EnhancedSubscriptionScreen({super.key});

  @override
  State<EnhancedSubscriptionScreen> createState() => _EnhancedSubscriptionScreenState();
}

class _EnhancedSubscriptionScreenState extends State<EnhancedSubscriptionScreen> {
  @override
  void initState() {
    super.initState();
    // Redirect to the new My Plan screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const MyPlanScreen(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Redirecting...'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Redirecting to new subscription management...'),
          ],
        ),
      ),
    );
  }
}
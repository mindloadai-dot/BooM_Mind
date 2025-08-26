import 'package:flutter/material.dart';
import 'package:mindload/screens/my_plan_screen.dart';

class TiersBenefitsScreen extends StatefulWidget {
  const TiersBenefitsScreen({super.key});

  @override
  State<TiersBenefitsScreen> createState() => _TiersBenefitsScreenState();
}

class _TiersBenefitsScreenState extends State<TiersBenefitsScreen> {
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
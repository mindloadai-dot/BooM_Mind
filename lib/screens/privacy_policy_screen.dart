import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mindload/widgets/mindload_app_bar.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: MindloadAppBarFactory.secondary(title: 'Privacy Policy'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha:  0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.security,
                    color: Theme.of(context).colorScheme.primary,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'YOUR PRIVACY MATTERS',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Last updated: ${DateTime.now().month}/${DateTime.now().day}/${DateTime.now().year}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha:  0.7),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Data We Collect Section
            _buildSection(
              context,
              'DATA WE COLLECT',
              Icons.data_usage,
              [
                'Study progress and performance analytics',
                'Quiz results and learning preferences', 
                'Device push token for notifications (if permitted)',
                'Authentication information (email, name from SSO providers)',
                'App usage patterns for AI coaching optimization',
                'Timezone and notification preference settings',
              ],
            ),

            const SizedBox(height: 20),

            // How We Use Data Section
            _buildSection(
              context,
              'HOW WE USE YOUR DATA',
              Icons.psychology,
              [
                'Personalize your AI study coach experience',
                'Send study reminders and coaching notifications (with your consent)',
                'Track your learning progress and achievements',
                'Improve app performance and user experience',
                'Provide customer support when requested',
                'Ensure app security and prevent abuse',
              ],
            ),

            const SizedBox(height: 20),

            // Firebase Integration Section
            _buildSection(
              context,
              'FIREBASE SERVICES & DATA HANDLING',
              Icons.cloud_sync,
              [
                'Firebase Authentication: Securely manages your login credentials',
                'Firestore Database: Stores your study data and preferences',
                'Firebase Analytics: Anonymous usage analytics for app improvement',
                'Firebase Cloud Messaging: Delivers personalized notifications',
                'Firebase Functions: Processes AI coaching logic server-side',
                'All Firebase data is encrypted in transit and at rest',
              ],
            ),

            const SizedBox(height: 20),

            // Notification Privacy Section
            _buildSection(
              context,
              'NOTIFICATION PRIVACY',
              Icons.notifications_none,
              [
                'Essential notifications work without system permission',
                'Promotional messages require explicit opt-in consent',
                'No sensitive personal information is included in notifications',
                'All notification content is privacy-compliant',
                'You can revoke consent anytime in Profile settings',
                'Notification analytics help improve coaching effectiveness',
              ],
            ),

            const SizedBox(height: 20),

            // Data Sharing Section
            _buildSection(
              context,
              'DATA SHARING & THIRD PARTIES',
              Icons.share,
              [
                'We never sell your personal data to third parties',
                'Firebase services (Google) process data under strict privacy agreements',
                'OpenAI API processes study content for flashcard generation (no personal data)',
                'Anonymous analytics may be shared for research purposes',
                'Legal compliance may require data disclosure in extreme cases',
              ],
            ),

            const SizedBox(height: 20),

            // Your Rights Section
            _buildSection(
              context,
              'YOUR PRIVACY RIGHTS',
              Icons.verified_user,
              [
                'Access: Request a copy of your stored data',
                'Rectification: Update or correct your information',
                'Erasure: Delete your account and all associated data',
                'Portability: Export your data in machine-readable format',
                'Objection: Opt out of non-essential data processing',
                'Consent Withdrawal: Revoke permissions at any time',
              ],
            ),

            const SizedBox(height: 20),

            // Data Retention Section
            _buildSection(
              context,
              'DATA RETENTION',
              Icons.schedule,
              [
                'Study progress: Retained while account is active',
                'Notification history: 90 days maximum',
                'Analytics data: Anonymized after 24 months',
                'Account deletion: All data removed within 30 days',
                'Backup retention: 90 days for recovery purposes',
              ],
            ),

            const SizedBox(height: 20),

            // Contact & Compliance Section
            _buildSection(
              context,
              'GDPR & CCPA COMPLIANCE',
              Icons.gavel,
              [
                'Full compliance with GDPR (European Union) and CCPA (California)',
                'Data Processing Agreements with all service providers',
                'Privacy Impact Assessments conducted regularly',
                'Data Protection Officer available for privacy concerns',
                'Regular security audits and vulnerability assessments',
              ],
            ),

            const SizedBox(height: 32),

            // Contact Information
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha:  0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha:  0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.contact_support,
                        color: Theme.of(context).colorScheme.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'QUESTIONS ABOUT PRIVACY?',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Contact our Data Protection Team:\nprivacy@mindload.app',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _sendPrivacyEmail(),
                      icon: const Icon(Icons.email),
                      label: const Text('CONTACT PRIVACY TEAM'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    IconData icon,
    List<String> items,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha:  0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(top: 8, right: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Text(
                    item,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  void _sendPrivacyEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'privacy@mindload.app',
      query: 'subject=Privacy Policy Inquiry&body=Hello Mindload Privacy Team,\n\nI have a question about...',
    );

    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Could not launch email: $e');
      }
    }
  }
}
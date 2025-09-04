import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mindload/widgets/mindload_app_bar.dart';
import 'package:mindload/widgets/unified_design_system.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: MindloadAppBarFactory.secondary(title: 'Privacy Policy'),
      body: SingleChildScrollView(
        padding: UnifiedSpacing.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            UnifiedCard(
              padding: UnifiedSpacing.cardPadding,
              borderRadius: UnifiedBorderRadius.lgRadius,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  UnifiedIcon(
                    Icons.security,
                    color: Theme.of(context).colorScheme.primary,
                    size: 48,
                  ),
                  SizedBox(height: UnifiedSpacing.sm),
                  UnifiedText(
                    'YOUR PRIVACY MATTERS',
                    style: UnifiedTypography.headlineSmall.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  SizedBox(height: UnifiedSpacing.sm),
                  UnifiedText(
                    'Last updated: ${DateTime.now().month}/${DateTime.now().day}/${DateTime.now().year}',
                    style: UnifiedTypography.bodyMedium.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onPrimaryContainer
                          .withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: UnifiedSpacing.lg),

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

            SizedBox(height: UnifiedSpacing.lg),

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

            SizedBox(height: UnifiedSpacing.lg),

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

            SizedBox(height: UnifiedSpacing.lg),

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

            SizedBox(height: UnifiedSpacing.lg),

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

            SizedBox(height: UnifiedSpacing.lg),

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

            SizedBox(height: UnifiedSpacing.lg),

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

            SizedBox(height: UnifiedSpacing.lg),

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

            SizedBox(height: UnifiedSpacing.xxl),

            // Contact Information
            UnifiedCard(
              padding: UnifiedSpacing.cardPadding,
              borderRadius: UnifiedBorderRadius.mdRadius,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      UnifiedIcon(
                        Icons.contact_support,
                        color: Theme.of(context).colorScheme.primary,
                        size: 24,
                      ),
                      SizedBox(width: UnifiedSpacing.sm),
                      UnifiedText(
                        'QUESTIONS ABOUT PRIVACY?',
                        style: UnifiedTypography.titleMedium.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: UnifiedSpacing.sm),
                  UnifiedText(
                    'Contact our Data Protection Team:\nprivacy@mindload.app',
                    style: UnifiedTypography.bodyMedium.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  SizedBox(height: UnifiedSpacing.md),
                  UnifiedButton(
                    onPressed: () => _sendPrivacyEmail(),
                    fullWidth: true,
                    icon: Icons.email,
                    child: UnifiedText('CONTACT PRIVACY TEAM'),
                  ),
                ],
              ),
            ),

            SizedBox(height: UnifiedSpacing.xxl),
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
    return UnifiedCard(
      padding: UnifiedSpacing.cardPadding,
      borderRadius: UnifiedBorderRadius.mdRadius,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              UnifiedIcon(
                icon,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              SizedBox(width: UnifiedSpacing.sm),
              Expanded(
                child: UnifiedText(
                  title,
                  style: UnifiedTypography.titleMedium.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: UnifiedSpacing.md),
          ...items.map((item) => Padding(
                padding: EdgeInsets.only(bottom: UnifiedSpacing.sm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      margin: EdgeInsets.only(
                          top: UnifiedSpacing.sm, right: UnifiedSpacing.sm),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: UnifiedText(
                        item,
                        style: UnifiedTypography.bodyMedium.copyWith(
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
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
      query:
          'subject=Privacy Policy Inquiry&body=Hello Mindload Privacy Team,\n\nI have a question about...',
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

import 'package:flutter/material.dart';
import 'package:mindload/services/notification_service.dart';
// Removed import: enhanced_notification_copy_library - service removed
import 'package:mindload/models/notification_models.dart';
import 'package:mindload/firestore/firestore_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mindload/widgets/mindload_app_bar.dart';

class NotificationInboxScreen extends StatefulWidget {
  const NotificationInboxScreen({super.key});

  @override
  State<NotificationInboxScreen> createState() => _NotificationInboxScreenState();
}

class _NotificationInboxScreenState extends State<NotificationInboxScreen>
    with TickerProviderStateMixin {
  final NotificationService _notificationService = NotificationService.instance;
  final FirestoreRepository _repository = FirestoreRepository.instance;
  
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  List<NotificationRecord> _notifications = [];
  bool _isLoading = true;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadNotifications();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    _fadeController.forward();
  }

  Future<void> _loadNotifications() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Load real notifications from Firestore
      final notifications = await _loadNotificationsFromFirestore(user.uid);
      
      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('Error loading notifications: $e');
    }
  }

  Future<List<NotificationRecord>> _loadNotificationsFromFirestore(String uid) async {
    try {
      // Get notifications from Firestore
      final notificationsQuery = await FirebaseFirestore.instance
          .collection('notifications')
          .where('uid', isEqualTo: uid)
          .orderBy('sentAt', descending: true)
          .limit(50)
          .get();

      return notificationsQuery.docs.map((doc) {
        final data = doc.data();
        return NotificationRecord(
          id: doc.id,
          uid: data['uid'] ?? uid,
          title: data['title'] ?? 'Notification',
          body: data['body'] ?? '',
          style: _parseNotificationStyle(data['style']),
          category: _parseNotificationCategory(data['category']),
          sentAt: (data['sentAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          openedAt: (data['openedAt'] as Timestamp?)?.toDate(),
          deepLink: data['deepLink'],
          platform: _parsePlatform(data['platform']),
        );
      }).toList();
    } catch (e) {
      debugPrint('Error loading notifications from Firestore: $e');
      // Return empty list instead of mock data
      return [];
    }
  }

  NotificationStyle _parseNotificationStyle(dynamic style) {
    if (style == null) return NotificationStyle.coach;
    switch (style.toString().toLowerCase()) {
      case 'coach':
        return NotificationStyle.coach;
      case 'cram':
        return NotificationStyle.cram;
      case 'toughlove':
        return NotificationStyle.toughLove;
      case 'mindful':
        return NotificationStyle.mindful;
      default:
        return NotificationStyle.coach;
    }
  }

  NotificationCategory _parseNotificationCategory(dynamic category) {
    if (category == null) return NotificationCategory.studyNow;
    switch (category.toString().toLowerCase()) {
      case 'studynow':
        return NotificationCategory.studyNow;
      case 'streaksave':
        return NotificationCategory.streakSave;
      case 'examalert':
        return NotificationCategory.examAlert;
      case 'weeklyreview':
        return NotificationCategory.studyNow; // Map to existing category
      case 'achievement':
        return NotificationCategory.studyNow; // Map to existing category
      case 'eventtrigger':
        return NotificationCategory.eventTrigger;
      case 'inactivitynudge':
        return NotificationCategory.inactivityNudge;
      default:
        return NotificationCategory.studyNow;
    }
  }

  Platform _parsePlatform(dynamic platform) {
    if (platform == null) return Platform.android;
    switch (platform.toString().toLowerCase()) {
      case 'ios':
        return Platform.ios;
      case 'android':
        return Platform.android;
      default:
        return Platform.android;
    }
  }

  List<NotificationRecord> get _filteredNotifications {
    if (_selectedFilter == 'all') return _notifications;
    
    final category = NotificationCategory.values.firstWhere(
      (c) => c.name == _selectedFilter,
      orElse: () => NotificationCategory.studyNow,
    );
    
    return _notifications.where((n) => n.category == category).toList();
  }

  Future<void> _handleNotificationTap(NotificationRecord notification) async {
    // Mark as opened if not already opened
    if (notification.openedAt == null) {
      // Track notification open - simplified for unified system
      debugPrint('📱 Notification opened: ${notification.id}');
    }
    
    // Handle deep link
    if (notification.deepLink != null) {
      await _handleDeepLink(notification.deepLink!);
    }
  }

  Future<void> _handleDeepLink(String deepLink) async {
    try {
      // For demonstration, we'll just show a snackbar
      // In a real implementation, this would navigate to the appropriate screen
      if (mounted) {
        String message;
        switch (deepLink) {
          case 'cogniflow://study':
            message = 'Opening study session...';
            break;
          case 'cogniflow://quiz':
            message = 'Opening quiz...';
            break;
          case 'cogniflow://schedule':
            message = 'Opening schedule...';
            break;
          default:
            message = 'Opening $deepLink...';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error handling deep link: $e');
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: MindloadAppBarFactory.secondary(
        title: 'Notifications',
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _selectedFilter = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'all',
                child: Text('All Notifications'),
              ),
              const PopupMenuItem(
                value: 'studyNow',
                child: Text('Study Reminders'),
              ),
              const PopupMenuItem(
                value: 'streakSave',
                child: Text('Streak Alerts'),
              ),
              const PopupMenuItem(
                value: 'examAlert',
                child: Text('Exam Alerts'),
              ),
              const PopupMenuItem(
                value: 'eventTrigger',
                child: Text('New Content'),
              ),
            ],
            icon: const Icon(Icons.filter_list),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  _buildStatsHeader(theme),
                  Expanded(
                    child: _buildNotificationList(theme),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatsHeader(ThemeData theme) {
    final totalCount = _notifications.length;
    final openedCount = _notifications.where((n) => n.openedAt != null).length;
    final openRate = totalCount > 0 ? (openedCount / totalCount * 100).round() : 0;
    
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withValues(alpha:  0.1),
            theme.colorScheme.secondary.withValues(alpha:  0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha:  0.2),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              theme,
              'Total',
              totalCount.toString(),
              Icons.notifications,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: theme.colorScheme.outline.withValues(alpha:  0.3),
          ),
          Expanded(
            child: _buildStatItem(
              theme,
              'Opened',
              openedCount.toString(),
              Icons.mark_email_read,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: theme.colorScheme.outline.withValues(alpha:  0.3),
          ),
          Expanded(
            child: _buildStatItem(
              theme,
              'Open Rate',
              '$openRate%',
              Icons.trending_up,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(ThemeData theme, String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: theme.colorScheme.primary,
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha:  0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationList(ThemeData theme) {
    final filteredNotifications = _filteredNotifications;
    
    if (filteredNotifications.isEmpty) {
      return _buildEmptyState(theme);
    }
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: filteredNotifications.length,
      itemBuilder: (context, index) {
        final notification = filteredNotifications[index];
        return _buildNotificationCard(theme, notification);
      },
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 64,
            color: theme.colorScheme.onSurface.withValues(alpha:  0.4),
          ),
          const SizedBox(height: 16),
          Text(
            _selectedFilter == 'all' 
                ? 'No Notifications Yet'
                : 'No ${_getFilterDisplayName()} Found',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface.withValues(alpha:  0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedFilter == 'all'
                ? 'Your notification history will appear here'
                : 'Try selecting a different filter',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha:  0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(ThemeData theme, NotificationRecord notification) {
    final isOpened = notification.openedAt != null;
    final categoryColor = _getCategoryColor(notification.category);
    final timeAgo = _formatTimeAgo(notification.sentAt);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 0,
        color: isOpened 
            ? theme.colorScheme.surface
            : theme.colorScheme.primaryContainer.withValues(alpha:  0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isOpened 
                ? theme.colorScheme.outline.withValues(alpha:  0.2)
                : theme.colorScheme.primary.withValues(alpha:  0.3),
            width: isOpened ? 1 : 2,
          ),
        ),
        child: InkWell(
          onTap: () => _handleNotificationTap(notification),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: categoryColor.withValues(alpha:  0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _getCategoryIcon(notification.category),
                        color: categoryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                notification.title,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (!isOpened)
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            timeAgo,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha:  0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: categoryColor.withValues(alpha:  0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getCategoryDisplayName(notification.category),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: categoryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  notification.body,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha:  0.8),
                    height: 1.4,
                  ),
                ),
                if (notification.deepLink != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.launch,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Tap to open',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
                if (isOpened && notification.openedAt != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 16,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Opened ${_formatTimeAgo(notification.openedAt!)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(NotificationCategory category) {
    switch (category) {
      case NotificationCategory.studyNow:
        return Icons.play_arrow;
      case NotificationCategory.streakSave:
        return Icons.local_fire_department;
      case NotificationCategory.examAlert:
        return Icons.warning;
      case NotificationCategory.inactivityNudge:
        return Icons.schedule;
      case NotificationCategory.eventTrigger:
        return Icons.new_releases;
      case NotificationCategory.promotional:
        return Icons.campaign;
    }
  }

  Color _getCategoryColor(NotificationCategory category) {
    switch (category) {
      case NotificationCategory.studyNow:
        return Colors.blue;
      case NotificationCategory.streakSave:
        return Colors.orange;
      case NotificationCategory.examAlert:
        return Colors.red;
      case NotificationCategory.inactivityNudge:
        return Colors.amber;
      case NotificationCategory.eventTrigger:
        return Colors.green;
      case NotificationCategory.promotional:
        return Colors.purple;
    }
  }

  String _getCategoryDisplayName(NotificationCategory category) {
    switch (category) {
      case NotificationCategory.studyNow:
        return 'Study';
      case NotificationCategory.streakSave:
        return 'Streak';
      case NotificationCategory.examAlert:
        return 'Exam';
      case NotificationCategory.inactivityNudge:
        return 'Reminder';
      case NotificationCategory.eventTrigger:
        return 'New';
      case NotificationCategory.promotional:
        return 'Promo';
    }
  }

  String _getFilterDisplayName() {
    switch (_selectedFilter) {
      case 'studyNow':
        return 'Study Reminders';
      case 'streakSave':
        return 'Streak Alerts';
      case 'examAlert':
        return 'Exam Alerts';
      case 'eventTrigger':
        return 'New Content Notifications';
      default:
        return 'Notifications';
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
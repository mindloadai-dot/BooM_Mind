import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:mindload/services/mindload_economy_service.dart';
import 'package:mindload/services/auth_service.dart';
import 'package:mindload/services/haptic_feedback_service.dart';
import 'package:mindload/services/user_profile_service.dart';
import 'package:mindload/services/working_notification_service.dart';
import 'package:mindload/services/local_image_storage_service.dart';
import 'package:mindload/services/notification_test_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;

import 'package:mindload/screens/my_plan_screen.dart';
import 'package:mindload/screens/achievements_screen.dart';
import 'package:mindload/screens/settings_screen.dart';
import 'package:mindload/screens/notification_settings_screen.dart';
import 'package:mindload/screens/privacy_policy_screen.dart';
import 'package:mindload/theme.dart';
import 'package:mindload/widgets/mindload_app_bar.dart';
import 'package:mindload/widgets/mindload_button_system.dart';
import 'package:timezone/timezone.dart' as tz;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  late AnimationController _headerController;
  late AnimationController _statsController;
  late AnimationController _actionsController;
  late AnimationController _settingsController;

  late Animation<double> _headerFadeAnimation;
  late Animation<Offset> _headerSlideAnimation;
  late Animation<double> _statsScaleAnimation;
  late Animation<double> _actionsFadeAnimation;
  late Animation<double> _settingsSlideAnimation;

  bool _biometricEnabled = false;
  bool _hapticEnabled = true;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
    _initializeHapticFeedback();
  }

  @override
  void dispose() {
    _headerController.dispose();
    _statsController.dispose();
    _actionsController.dispose();
    _settingsController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _headerFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeOut),
    );
    _headerSlideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeOutCubic),
    );

    _statsController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _statsScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _statsController, curve: Curves.elasticOut),
    );

    _actionsController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _actionsFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _actionsController, curve: Curves.easeIn),
    );

    _settingsController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _settingsSlideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _settingsController, curve: Curves.easeOutCubic),
    );
  }

  void _startAnimations() {
    _headerController.forward();
    Future.delayed(
        const Duration(milliseconds: 200), () => _statsController.forward());
    Future.delayed(
        const Duration(milliseconds: 400), () => _actionsController.forward());
    Future.delayed(
        const Duration(milliseconds: 600), () => _settingsController.forward());
  }

  void _initializeHapticFeedback() async {
    await HapticFeedbackService().initialize();
    setState(() {
      _hapticEnabled = HapticFeedbackService().isEnabled;
    });
  }

  /// Load profile image from local storage
  Future<void> _loadProfileImage() async {
    try {
      final imagePath =
          await LocalImageStorageService.instance.getProfileImagePath();
      setState(() {
        // Update the profile picture display
        // The _buildProfilePictureSection will automatically use the latest image
      });
    } catch (e) {
      if (kDebugMode) {
        print('Failed to load profile image: $e');
      }
    }
  }

  void _toggleBiometric(bool value) {
    setState(() {
      _biometricEnabled = value;
    });
    // TODO: Implement actual biometric toggle functionality
    // This would typically involve:
    // 1. Checking if biometrics are available
    // 2. Authenticating the user
    // 3. Saving the preference to secure storage
    // 4. Updating the app's authentication flow
  }

  void _toggleHapticFeedback(bool value) {
    setState(() {
      _hapticEnabled = value;
    });
    // Update the haptic feedback service
    HapticFeedbackService().toggleHapticFeedback(value);
    // Provide haptic feedback for the toggle
    if (value) {
      HapticFeedbackService().success();
    }
  }

  /// Build initials avatar when no profile picture is available
  Widget _buildInitialsAvatar(BuildContext context) {
    final userProfile = UserProfileService.instance;
    final displayName = userProfile.displayName;
    final initials = _getInitials(displayName);

    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.tokens.primary,
            context.tokens.secondary,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: context.tokens.onPrimary,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  /// Generate initials from display name
  String _getInitials(String name) {
    if (name.isEmpty || name == 'User') {
      return 'U';
    }

    final words = name.trim().split(' ');
    if (words.length == 1) {
      // Single word - take first two characters
      return words[0].substring(0, words[0].length > 1 ? 2 : 1).toUpperCase();
    } else {
      // Multiple words - take first character of first two words
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
  }

  /// Show profile picture options dialog
  void _showProfilePictureOptions() {
    HapticFeedbackService().lightImpact();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: context.tokens.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: context.tokens.outline.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Text(
                'Profile Picture',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: context.tokens.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),

            const SizedBox(height: 16),

            // Options
            ListTile(
              leading: Icon(Icons.camera_alt, color: context.tokens.primary),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _takePhoto();
              },
            ),

            ListTile(
              leading: Icon(Icons.photo_library, color: context.tokens.primary),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromGallery();
              },
            ),

            // Show remove option only if user has a profile picture
            FutureBuilder<bool>(
              future: LocalImageStorageService.instance.hasProfileImage(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data == true) {
                  return ListTile(
                    leading: Icon(Icons.delete, color: context.tokens.error),
                    title: Text(
                      'Remove Photo',
                      style: TextStyle(color: context.tokens.error),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _removeProfilePicture();
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// Take photo using camera
  Future<void> _takePhoto() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 90,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (image != null) {
        await _processAndSaveImage(image);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error taking photo: $e');
      }
      _showErrorSnackBar('Failed to take photo. Please try again.');
    }
  }

  /// Pick image from gallery
  Future<void> _pickImageFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 90,
      );

      if (image != null) {
        await _processAndSaveImage(image);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error picking image: $e');
      }
      _showErrorSnackBar('Failed to pick image. Please try again.');
    }
  }

  /// Process and save the selected image
  Future<void> _processAndSaveImage(XFile imageFile) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Convert XFile to File
      final File originalFile = File(imageFile.path);

      // Process the image to create a square, non-distorted version
      final File processedFile = await _processImageToSquare(originalFile);

      // Save the processed image
      final savedPath = await LocalImageStorageService.instance
          .saveProfileImage(processedFile);

      // Clean up temporary file if it's different from original
      if (processedFile.path != originalFile.path) {
        try {
          await processedFile.delete();
        } catch (e) {
          // Ignore cleanup errors
        }
      }

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      if (savedPath != null) {
        setState(() {}); // Refresh the UI
        HapticFeedbackService().success();
        _showSuccessSnackBar('Profile picture updated successfully!');
      } else {
        _showErrorSnackBar('Failed to save profile picture. Please try again.');
      }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted) Navigator.pop(context);

      if (kDebugMode) {
        print('Error processing image: $e');
      }
      _showErrorSnackBar('Failed to process image. Please try again.');
    }
  }

  /// Process image to create a square, non-distorted version
  Future<File> _processImageToSquare(File originalFile) async {
    try {
      // Read the original image
      final Uint8List imageBytes = await originalFile.readAsBytes();
      final img.Image? originalImage = img.decodeImage(imageBytes);

      if (originalImage == null) {
        throw Exception('Failed to decode image');
      }

      // Calculate the size for the square (use the smaller dimension to avoid distortion)
      final int size = originalImage.width < originalImage.height
          ? originalImage.width
          : originalImage.height;

      // Calculate crop coordinates to center the square
      final int cropX = (originalImage.width - size) ~/ 2;
      final int cropY = (originalImage.height - size) ~/ 2;

      // Crop the image to a square
      final img.Image croppedImage = img.copyCrop(
        originalImage,
        x: cropX,
        y: cropY,
        width: size,
        height: size,
      );

      // Resize to 512x512 for optimal profile picture size
      final img.Image resizedImage = img.copyResize(
        croppedImage,
        width: 512,
        height: 512,
        interpolation: img.Interpolation.cubic,
      );

      // Encode as JPEG with high quality
      final Uint8List processedBytes = Uint8List.fromList(
        img.encodeJpg(resizedImage, quality: 95),
      );

      // Create a temporary file for the processed image
      final Directory tempDir = Directory.systemTemp;
      final String tempPath =
          '${tempDir.path}/processed_profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final File processedFile = File(tempPath);

      // Write the processed image
      await processedFile.writeAsBytes(processedBytes);

      return processedFile;
    } catch (e) {
      if (kDebugMode) {
        print('Error processing image to square: $e');
      }
      // If processing fails, return the original file
      return originalFile;
    }
  }

  /// Remove profile picture
  Future<void> _removeProfilePicture() async {
    try {
      final success =
          await LocalImageStorageService.instance.deleteProfileImage();

      if (success) {
        setState(() {}); // Refresh the UI
        HapticFeedbackService().success();
        _showSuccessSnackBar('Profile picture removed successfully!');
      } else {
        _showErrorSnackBar(
            'Failed to remove profile picture. Please try again.');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error removing profile picture: $e');
      }
      _showErrorSnackBar('Failed to remove profile picture. Please try again.');
    }
  }

  /// Show success snackbar
  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: context.tokens.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Show error snackbar
  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: context.tokens.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.tokens.surface,
      appBar: const MindloadAppBar(title: 'Profile'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileHeader(),
            const SizedBox(height: 24),
            _buildQuickStats(),
            const SizedBox(height: 24),
            _buildQuickActions(),
            const SizedBox(height: 24),
            _buildSettingsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return FadeTransition(
      opacity: _headerFadeAnimation,
      child: SlideTransition(
        position: _headerSlideAnimation,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                context.tokens.primary.withOpacity(0.1),
                context.tokens.secondary.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: context.tokens.outline.withOpacity(0.2),
            ),
          ),
          child: Row(
            children: [
              // Profile Avatar
              GestureDetector(
                onTap: _showProfilePictureOptions,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        context.tokens.primary,
                        context.tokens.secondary,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: context.tokens.primary.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: FutureBuilder<String?>(
                      future: LocalImageStorageService.instance
                          .getProfileImagePath(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData && snapshot.data != null) {
                          // Show profile picture
                          return Image.file(
                            File(snapshot.data!),
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              // Fallback to initials if image fails to load
                              return _buildInitialsAvatar(context);
                            },
                          );
                        } else {
                          // Show initials
                          return _buildInitialsAvatar(context);
                        }
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),

              // User Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getDisplayName(),
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: context.tokens.textPrimary,
                              ),
                    ),
                    const SizedBox(height: 8),
                    Consumer<MindloadEconomyService>(
                      builder: (context, economyService, child) {
                        final userEconomy = economyService.userEconomy;
                        if (userEconomy == null) {
                          return Text(
                            'Loading...',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: context.tokens.textSecondary,
                                ),
                          );
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${userEconomy.tier.name} Plan',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: context.tokens.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${userEconomy.creditsRemaining} tokens remaining',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: context.tokens.textSecondary,
                                  ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Edit Profile Button
              IconButton(
                onPressed: () {
                  // For now, show a simple edit dialog since there's no dedicated edit profile screen
                  _showEditProfileDialog();
                },
                icon: Icon(
                  Icons.edit,
                  color: context.tokens.primary,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: context.tokens.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return ScaleTransition(
      scale: _statsScaleAnimation,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: context.tokens.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: context.tokens.outline.withOpacity(0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics,
                  color: context.tokens.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Quick Stats',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: context.tokens.textPrimary,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Consumer<MindloadEconomyService>(
              builder: (context, economyService, child) {
                final userEconomy = economyService.userEconomy;
                if (userEconomy == null) {
                  return const Center(child: CircularProgressIndicator());
                }

                return Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Monthly Tokens',
                        '${userEconomy.monthlyQuota}',
                        Icons.flash_on,
                        context.tokens.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        'Used This Month',
                        '${userEconomy.creditsUsedThisMonth}',
                        Icons.trending_up,
                        context.tokens.secondary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        'Rollover',
                        '${userEconomy.rolloverCredits}',
                        Icons.savings,
                        context.tokens.secondary,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.tokens.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return FadeTransition(
      opacity: _actionsFadeAnimation,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: context.tokens.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: context.tokens.outline.withOpacity(0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.bolt,
                  color: context.tokens.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Quick Actions',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: context.tokens.textPrimary,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildActionCard(
              'My Plan & Tokens',
              'Manage your subscription and token balance',
              Icons.card_membership,
              context.tokens.primary,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MyPlanScreen()),
              ),
            ),
            const SizedBox(height: 12),
            _buildActionCard(
              'Achievements',
              'View your progress and earned badges',
              Icons.emoji_events,
              context.tokens.secondary,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const AchievementsScreen()),
              ),
            ),
            const SizedBox(height: 12),
            _buildActionCard(
              'Notification Settings',
              'Customize your study reminders',
              Icons.notifications,
              context.tokens.outline,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const NotificationSettingsScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(String title, String subtitle, IconData icon,
      Color color, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withOpacity(0.2),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: context.tokens.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: context.tokens.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: context.tokens.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsSection() {
    return SlideTransition(
      position:
          Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
        CurvedAnimation(
            parent: _settingsController, curve: Curves.easeOutCubic),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: context.tokens.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: context.tokens.outline.withOpacity(0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.settings,
                  color: context.tokens.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Settings & Preferences',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: context.tokens.textPrimary,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            _buildSettingsTile(
              'App Settings',
              'Customize app appearance and behavior',
              Icons.palette,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              ),
            ),
            const SizedBox(height: 12),

            _buildSettingsTile(
              'Account Security',
              'Manage password and security settings',
              Icons.security,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              ),
            ),
            const SizedBox(height: 12),

            // Biometric Authentication Toggle
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.tokens.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: context.tokens.outline.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: context.tokens.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.fingerprint,
                      color: context.tokens.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Biometric Authentication',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: context.tokens.textPrimary,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Use fingerprint, face ID, or PIN for quick access',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: context.tokens.textSecondary,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _biometricEnabled,
                    onChanged: _toggleBiometric,
                    activeColor: context.tokens.primary,
                    activeTrackColor: context.tokens.primary.withOpacity(0.3),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Haptic Feedback Toggle
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.tokens.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: context.tokens.outline.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: context.tokens.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.vibration,
                      color: context.tokens.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Haptic Feedback',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: context.tokens.textPrimary,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Feel vibrations for interactions and feedback',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: context.tokens.textSecondary,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _hapticEnabled,
                    onChanged: _toggleHapticFeedback,
                    activeColor: context.tokens.primary,
                    activeTrackColor: context.tokens.primary.withOpacity(0.3),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            _buildSettingsTile(
              'Data & Privacy',
              'Control your data and privacy settings',
              Icons.privacy_tip,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const PrivacyPolicyScreen()),
              ),
            ),
            const SizedBox(height: 20),

            // Sign Out Button
            DestructiveButton(
              onPressed: _showSignOutDialog,
              fullWidth: true,
              icon: Icons.logout,
              child: const Text('Sign Out'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTile(
      String title, String subtitle, IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.tokens.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: context.tokens.outline.withOpacity(0.2),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: context.tokens.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: context.tokens.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: context.tokens.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: context.tokens.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: context.tokens.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getDisplayName() {
    final user = AuthService.instance.currentUser;
    if (user?.displayName != null && user!.displayName.isNotEmpty) {
      return user.displayName;
    }
    if (user?.email != null) {
      return user!.email.split('@')[0];
    }
    return 'User';
  }

  void _showEditProfileDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const EditProfileDialog(),
    );

    // Refresh profile picture after dialog is closed
    _loadProfileImage();
  }

  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.tokens.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              Icons.logout,
              color: context.tokens.error,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              'Sign Out',
              style: TextStyle(
                color: context.tokens.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to sign out? You can sign back in anytime.',
          style: TextStyle(color: context.tokens.textSecondary),
        ),
        actions: [
          SecondaryButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          DestructiveButton(
            onPressed: () {
              Navigator.pop(context);
              AuthService.instance.signOut();
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}

/// Simplified Edit Profile Dialog with core functionality
class EditProfileDialog extends StatefulWidget {
  const EditProfileDialog({super.key});

  @override
  State<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nicknameController = TextEditingController();
  String? _savedImagePath;
  String? _tempImagePath; // Temporary path for new image before saving
  bool _isImageLoading = false; // Loading state for image operations
  String _selectedTimeZone = '';
  bool _quietHoursEnabled = false;
  TimeOfDay _quietHoursStart = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _quietHoursEnd = const TimeOfDay(hour: 7, minute: 0);
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  void _initializeData() async {
    final userProfile = UserProfileService.instance;
    _nicknameController.text = userProfile.nickname ?? '';
    _selectedTimeZone = userProfile.timezone ?? tz.local.name;
    _quietHoursEnabled = userProfile.quietHoursEnabled;

    // Load saved profile image
    _savedImagePath =
        await LocalImageStorageService.instance.getProfileImagePath();

    // Parse saved quiet hours
    try {
      final startParts = userProfile.quietHoursStart.split(':');
      final endParts = userProfile.quietHoursEnd.split(':');
      if (startParts.length == 2 && endParts.length == 2) {
        _quietHoursStart = TimeOfDay(
          hour: int.parse(startParts[0]),
          minute: int.parse(startParts[1]),
        );
        _quietHoursEnd = TimeOfDay(
          hour: int.parse(endParts[0]),
          minute: int.parse(endParts[1]),
        );
      }
    } catch (e) {
      // Use defaults if parsing fails
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Dialog(
      backgroundColor: tokens.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        child: Column(
          children: [
            _buildHeader(tokens),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildNicknameSection(tokens),
                      const SizedBox(height: 24),
                      _buildEditProfilePictureSection(tokens),
                      const SizedBox(height: 24),
                      _buildTimeZoneSection(tokens),
                      const SizedBox(height: 24),
                      _buildQuietHoursSection(tokens),
                      const SizedBox(height: 24),
                      _buildNotificationStyleSection(tokens),
                      const SizedBox(height: 24),
                      _buildAchievementsSection(tokens),
                    ],
                  ),
                ),
              ),
            ),
            _buildActionButtons(tokens),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(SemanticTokens tokens) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: tokens.primary.withOpacity(0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.edit, color: tokens.primary, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Edit Profile',
                  style: TextStyle(
                    color: tokens.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Personalize your Mindload experience',
                  style: TextStyle(
                    color: tokens.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.close, color: tokens.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildNicknameSection(SemanticTokens tokens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Display Nickname',
          style: TextStyle(
            color: tokens.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '2-24 characters, letters/numbers/underscores/emojis allowed',
          style: TextStyle(
            color: tokens.textSecondary,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _nicknameController,
          decoration: InputDecoration(
            hintText: 'Enter your nickname',
            filled: true,
            fillColor: tokens.surface,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: tokens.outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: tokens.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: tokens.primary, width: 2),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Nickname is required';
            }
            final trimmed = value.trim();
            if (trimmed.length < 2) {
              return 'Nickname must be at least 2 characters';
            }
            if (trimmed.length > 24) {
              return 'Nickname must be 24 characters or less';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildProfilePictureSection(SemanticTokens tokens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Profile Picture',
          style: TextStyle(
            color: tokens.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Profile pictures are stored locally on your device',
          style: TextStyle(
            color: tokens.textSecondary,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: tokens.outline, width: 3),
            ),
            child: ClipOval(
              child: _buildMainProfileImageDisplay(tokens),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildProfilePictureActions(tokens),
      ],
    );
  }

  /// Build profile image display widget for main profile screen
  Widget _buildMainProfileImageDisplay(SemanticTokens tokens) {
    return FutureBuilder<String?>(
      future: LocalImageStorageService.instance.getProfileImagePath(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: tokens.outline.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(tokens.primary),
                ),
              ),
            ),
          );
        }

        final imagePath = snapshot.data;
        if (imagePath != null) {
          return Image.file(
            File(imagePath),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              if (kDebugMode) {
                print('Failed to load profile image: $error');
              }
              return _buildInitialsAvatar(tokens);
            },
          );
        }

        return _buildInitialsAvatar(tokens);
      },
    );
  }

  /// Build profile picture action buttons
  Widget _buildProfilePictureActions(SemanticTokens tokens) {
    return FutureBuilder<String?>(
      future: LocalImageStorageService.instance.getProfileImagePath(),
      builder: (context, snapshot) {
        final imagePath = snapshot.data;
        if (imagePath != null) {
          return SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _removeImage,
              icon: const Icon(Icons.delete_rounded),
              label: const Text('Remove Profile Picture'),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: tokens.outline),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildTimeZoneSection(SemanticTokens tokens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Time Zone',
          style: TextStyle(
            color: tokens.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Auto-detected: ${_getLocalTimePreview()}',
          style: TextStyle(
            color: tokens.textSecondary,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: tokens.surface,
            border: Border.all(color: tokens.outline),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.location_on, color: tokens.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Time Zone',
                      style: TextStyle(
                        color: tokens.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _selectedTimeZone,
                      style: TextStyle(
                        color: tokens.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuietHoursSection(SemanticTokens tokens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Quiet Hours',
                style: TextStyle(
                  color: tokens.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Switch(
              value: _quietHoursEnabled,
              onChanged: (value) {
                setState(() {
                  _quietHoursEnabled = value;
                });
              },
              activeColor: tokens.primary,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Notifications will be suppressed during quiet hours',
          style: TextStyle(
            color: tokens.textSecondary,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 16),
        if (_quietHoursEnabled) ...[
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _selectTime(context, true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: tokens.outline),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Start Time',
                          style: TextStyle(
                            color: tokens.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          _quietHoursStart.format(context),
                          style: TextStyle(
                            color: tokens.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: GestureDetector(
                  onTap: () => _selectTime(context, false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: tokens.outline),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'End Time',
                          style: TextStyle(
                            color: tokens.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          _quietHoursEnd.format(context),
                          style: TextStyle(
                            color: tokens.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildNotificationStyleSection(SemanticTokens tokens) {
    final userProfile = UserProfileService.instance;
    final currentStyle = userProfile.notificationStyle;
    final availableStyles = userProfile.availableStyles;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notification Style',
          style: TextStyle(
            color: tokens.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Choose how notifications are delivered to you',
          style: TextStyle(
            color: tokens.textSecondary,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 16),

        // Style Selection
        for (final style in availableStyles) ...[
          _buildStyleOption(tokens, style, currentStyle == style),
          if (style != availableStyles.last) const SizedBox(height: 12),
        ],

        const SizedBox(height: 16),

        // Current Style Preview
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: tokens.primary.withOpacity(0.1),
            border: Border.all(color: tokens.primary),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current Style Preview',
                style: TextStyle(
                  color: tokens.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _getStylePreviewText(currentStyle),
                style: TextStyle(
                  color: tokens.textSecondary,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStyleOption(
      SemanticTokens tokens, String style, bool isSelected) {
    final styleInfo = UserProfileService.instance.getStyleInfo(style);
    final emoji = styleInfo['emoji'] as String;
    final name = styleInfo['name'] as String;
    final description = styleInfo['description'] as String;

    return GestureDetector(
      onTap: () => _updateNotificationStyle(style),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? tokens.primary.withOpacity(0.1) : tokens.surface,
          border: Border.all(
            color: isSelected ? tokens.primary : tokens.outline,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? tokens.primary
                    : tokens.outline.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Center(
                child: Text(
                  emoji,
                  style: TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      color: tokens.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: tokens.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: tokens.primary,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  /// Build profile picture section for edit dialog
  Widget _buildEditProfilePictureSection(SemanticTokens tokens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Profile Picture',
          style: TextStyle(
            color: tokens.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Add a personal touch to your profile',
          style: TextStyle(
            color: tokens.textSecondary,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Recommended: Square images (400x400) for best results',
          style: TextStyle(
            color: tokens.textSecondary,
            fontSize: 10,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 16),

        // Profile Picture Display
        Center(
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: tokens.outline, width: 3),
            ),
            child: ClipOval(
              child: _buildProfileImageDisplay(tokens),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Action Buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isImageLoading ? null : _pickImageFromGallery,
                icon: const Icon(Icons.photo_library),
                label: const Text('Gallery'),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: tokens.outline),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isImageLoading ? null : _takePhotoWithCamera,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Camera'),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: tokens.outline),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Remove button (only show if there's an image)
        if (_savedImagePath != null || _tempImagePath != null)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isImageLoading ? null : _removeProfileImage,
              icon: const Icon(Icons.delete_rounded),
              label: const Text('Remove Picture'),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: tokens.error),
                foregroundColor: tokens.error,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

        // Loading indicator
        if (_isImageLoading) ...[
          const SizedBox(height: 16),
          Center(
            child: Column(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(tokens.primary),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Processing image...',
                  style: TextStyle(
                    color: tokens.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// Build profile image display widget
  Widget _buildProfileImageDisplay(SemanticTokens tokens) {
    // Show temp image if available (newly selected)
    if (_tempImagePath != null) {
      return Image.file(
        File(_tempImagePath!),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            _buildEditInitialsAvatar(tokens),
      );
    }

    // Show saved image if available
    if (_savedImagePath != null) {
      return Image.file(
        File(_savedImagePath!),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            _buildEditInitialsAvatar(tokens),
      );
    }

    // Show initials avatar as fallback
    return _buildEditInitialsAvatar(tokens);
  }

  /// Build initials avatar widget for edit dialog
  Widget _buildEditInitialsAvatar(SemanticTokens tokens) {
    final userProfile = UserProfileService.instance;
    final displayName = userProfile.displayName;
    final initials = _getInitials(displayName);

    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: tokens.primary.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: tokens.primary,
            fontSize: 48,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  /// Get initials from display name
  String _getInitials(String displayName) {
    if (displayName.isEmpty) return '?';

    final parts = displayName.trim().split(' ');
    if (parts.length == 1) {
      return parts[0].substring(0, 1).toUpperCase();
    }

    return '${parts[0].substring(0, 1).toUpperCase()}${parts[parts.length - 1].substring(0, 1).toUpperCase()}';
  }

  /// Pick image from gallery
  Future<void> _pickImageFromGallery() async {
    try {
      setState(() {
        _isImageLoading = true;
      });

      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        await _processAndSetImage(image.path);
      } else {
        // User cancelled the picker
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('No image selected'),
              backgroundColor: context.tokens.textSecondary,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Failed to pick image from gallery';
        if (e.toString().contains('permission')) {
          errorMessage =
              'Permission denied. Please grant photo library access in settings.';
        } else if (e.toString().contains('camera')) {
          errorMessage =
              'Camera access denied. Please grant camera permission in settings.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: context.tokens.error,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Settings',
              textColor: context.tokens.surface,
              onPressed: () {
                // TODO: Open app settings
              },
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isImageLoading = false;
        });
      }
    }
  }

  /// Take photo with camera
  Future<void> _takePhotoWithCamera() async {
    try {
      setState(() {
        _isImageLoading = true;
      });

      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        await _processAndSetImage(image.path);
      } else {
        // User cancelled the camera
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('No photo taken'),
              backgroundColor: context.tokens.textSecondary,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Failed to take photo';
        if (e.toString().contains('permission')) {
          errorMessage =
              'Camera permission denied. Please grant camera access in settings.';
        } else if (e.toString().contains('camera')) {
          errorMessage =
              'Camera not available. Please check your device camera.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: context.tokens.error,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Settings',
              textColor: context.tokens.surface,
              onPressed: () {
                // TODO: Open app settings
              },
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isImageLoading = false;
        });
      }
    }
  }

  /// Process and set the selected image
  Future<void> _processAndSetImage(String imagePath) async {
    try {
      // Validate image file
      final file = File(imagePath);
      if (!await file.exists()) {
        throw Exception('Image file not found');
      }

      // Check file size (max 10MB)
      final fileSize = await file.length();
      if (fileSize > 10 * 1024 * 1024) {
        throw Exception('Image file too large (max 10MB)');
      }

      // Process image (resize, compress, etc.)
      final processedPath = await _processImage(imagePath);

      setState(() {
        _tempImagePath = processedPath;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Image selected successfully!'),
            backgroundColor: context.tokens.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to process image: $e'),
            backgroundColor: context.tokens.error,
          ),
        );
      }
    }
  }

  /// Process image for optimal profile picture display
  Future<String> _processImage(String imagePath) async {
    try {
      // Read image file
      final bytes = await File(imagePath).readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Resize to optimal profile picture size (400x400)
      final resized = img.copyResize(
        image,
        width: 400,
        height: 400,
        interpolation: img.Interpolation.cubic,
      );

      // Convert to JPEG for better compression
      final processedBytes = img.encodeJpg(resized, quality: 90);

      // Save to temporary directory
      final tempDir = Directory.systemTemp;
      final tempFile = File(
          '${tempDir.path}/profile_temp_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await tempFile.writeAsBytes(processedBytes);

      return tempFile.path;
    } catch (e) {
      // If processing fails, return original path
      return imagePath;
    }
  }

  /// Remove profile image
  Future<void> _removeProfileImage() async {
    try {
      setState(() {
        _isImageLoading = true;
      });

      // Clear temporary image
      if (_tempImagePath != null) {
        final tempFile = File(_tempImagePath!);
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
        _tempImagePath = null;
      }

      // Remove saved image
      if (_savedImagePath != null) {
        await LocalImageStorageService.instance.deleteProfileImage();
        _savedImagePath = null;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile picture removed successfully!'),
            backgroundColor: context.tokens.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove profile picture: $e'),
            backgroundColor: context.tokens.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isImageLoading = false;
        });
      }
    }
  }

  String _getStylePreviewText(String style) {
    final userProfile = UserProfileService.instance;
    final nickname = userProfile.displayName;

    switch (style) {
      case 'mindful':
        return '🧘 Gentle reminder: Study session ready for $nickname\nTake your time, $nickname';
      case 'coach':
        return '🏆 Come on, $nickname! Study session ready!\nYou\'re absolutely crushing it!';
      case 'toughlove':
        return '💪 Listen up, $nickname! Study session ready!\nStop making excuses and get to work!';
      case 'cram':
        return '🚨 URGENT: Study session ready - $nickname!\nMAXIMUM INTENSITY NOW!';
      default:
        return 'Study session ready - $nickname';
    }
  }

  void _updateNotificationStyle(String newStyle) async {
    try {
      await UserProfileService.instance.updateNotificationStyle(newStyle);
      setState(() {});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Notification style updated to: ${UserProfileService.instance.getStyleDisplayName(newStyle)}'),
            backgroundColor: context.tokens.success,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update notification style: $e'),
            backgroundColor: context.tokens.error,
          ),
        );
      }
    }
  }

  Widget _buildAchievementsSection(SemanticTokens tokens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Achievements',
          style: TextStyle(
            color: tokens.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: tokens.success.withOpacity(0.1),
            border: Border.all(color: tokens.success),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: tokens.success),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Completed',
                      style: TextStyle(
                        color: tokens.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '12 achievements earned',
                      style: TextStyle(
                        color: tokens.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: tokens.success,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '12',
                  style: TextStyle(
                    color: tokens.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _viewAllGoals,
            icon: const Icon(Icons.visibility),
            label: const Text('View All Goals & Pick Targets'),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: tokens.primary),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(SemanticTokens tokens) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: tokens.surface,
        border: Border(
          top: BorderSide(color: tokens.outline),
        ),
      ),
      child: Column(
        children: [
          // Test Notification Button
          SecondaryButton(
            onPressed: _testPersonalizedNotification,
            icon: Icons.notifications,
            fullWidth: true,
            child: const Text('Test Personalized Notification'),
          ),
          const SizedBox(height: 12),

          // Comprehensive Test Button
          SecondaryButton(
            onPressed: _runComprehensiveTest,
            icon: Icons.science,
            fullWidth: true,
            child: const Text('Run Comprehensive Notification Test'),
          ),
          const SizedBox(height: 16),

          // Action Buttons Row
          ButtonRow(
            children: [
              SecondaryButton(
                onPressed: _revertChanges,
                child: const Text('Revert Changes'),
              ),
              PrimaryButton(
                onPressed: _isLoading ? null : _saveChanges,
                loading: _isLoading,
                child: const Text('Save Changes'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInitialsAvatar(SemanticTokens tokens) {
    final userProfile = UserProfileService.instance;
    final initials = userProfile.displayName
        .split(' ')
        .take(2)
        .map((name) => name.isNotEmpty ? name[0].toUpperCase() : '')
        .join('');

    return Container(
      color: tokens.primary.withOpacity(0.1),
      child: Center(
        child: Text(
          initials.isNotEmpty ? initials : 'U',
          style: TextStyle(
            color: tokens.primary,
            fontSize: 48,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  String _getLocalTimePreview() {
    final now = DateTime.now();
    final weekday =
        ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][now.weekday - 1];
    final hour = now.hour;
    final minute = now.minute;
    final ampm = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final displayMinute = minute.toString().padLeft(2, '0');

    return '$weekday $displayHour:$displayMinute $ampm';
  }

  void _removeImage() async {
    try {
      await LocalImageStorageService.instance.deleteProfileImage();
      // The FutureBuilder will automatically update the UI
      setState(() {});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile picture removed successfully!'),
            backgroundColor: context.tokens.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove profile picture: $e'),
            backgroundColor: context.tokens.error,
          ),
        );
      }
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? selectedTime = await showTimePicker(
      context: context,
      initialTime: isStartTime ? _quietHoursStart : _quietHoursEnd,
    );

    if (selectedTime != null) {
      setState(() {
        if (isStartTime) {
          _quietHoursStart = selectedTime;
        } else {
          _quietHoursEnd = selectedTime;
        }
      });
    }
  }

  void _viewAllGoals() {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AchievementsScreen(),
      ),
    );
  }

  void _revertChanges() {
    _initializeData();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userProfile = UserProfileService.instance;

      // Save nickname
      if (_nicknameController.text.trim().isNotEmpty) {
        await userProfile.updateNickname(_nicknameController.text.trim());
      }

      // Save timezone
      if (_selectedTimeZone.isNotEmpty) {
        await userProfile.updateTimezone(_selectedTimeZone);
      }

      // Save quiet hours
      await userProfile.updateQuietHours(
        enabled: _quietHoursEnabled,
        start:
            '${_quietHoursStart.hour.toString().padLeft(2, '0')}:${_quietHoursStart.minute.toString().padLeft(2, '0')}',
        end:
            '${_quietHoursEnd.hour.toString().padLeft(2, '0')}:${_quietHoursEnd.minute.toString().padLeft(2, '0')}',
      );

      // Save profile picture locally if a new one was selected
      if (_tempImagePath != null) {
        try {
          // Convert path to File object and save to local storage
          final imageFile = File(_tempImagePath!);
          final savedPath = await LocalImageStorageService.instance
              .saveProfileImage(imageFile);

          if (savedPath != null) {
            // Update the saved image path
            _savedImagePath = savedPath;
            _tempImagePath = null;

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Profile picture saved successfully!'),
                  backgroundColor: context.tokens.success,
                ),
              );
            }
          } else {
            throw Exception('Failed to save profile picture');
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to save profile picture: $e'),
                backgroundColor: context.tokens.error,
              ),
            );
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile updated successfully!'),
            backgroundColor: context.tokens.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: context.tokens.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _testPersonalizedNotification() async {
    try {
      final userProfile = UserProfileService.instance;
      final displayName = userProfile.displayName;

      await WorkingNotificationService.instance.showNotificationNow(
        title: '🧪 TEST NOTIFICATION - $displayName',
        body:
            'This is a personalized notification test using your nickname: $displayName',
        payload: 'test_personalized',
        isHighPriority: true,
        channelType: 'study_reminders',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Personalized notification sent to: $displayName'),
            backgroundColor: context.tokens.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send test notification: $e'),
            backgroundColor: context.tokens.error,
          ),
        );
      }
    }
  }

  /// Run comprehensive notification system test
  void _runComprehensiveTest() async {
    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                const Text('🚀 Starting comprehensive notification test...'),
            backgroundColor: context.tokens.primary,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      // Run the comprehensive test
      await NotificationTestService.instance.runComprehensiveTest();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                const Text('🎉 Comprehensive notification test completed!'),
            backgroundColor: context.tokens.success,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Comprehensive test failed: $e'),
            backgroundColor: context.tokens.error,
          ),
        );
      }
    }
  }
}

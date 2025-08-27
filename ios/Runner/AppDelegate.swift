import Flutter
import UIKit
import Firebase
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    // Initialize Firebase if GoogleService-Info.plist exists
    if let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") {
      FirebaseApp.configure()
    }
    
    // Configure notifications with enhanced iOS support
    UNUserNotificationCenter.current().delegate = self
    
    // Request comprehensive notification permissions for iOS
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().requestAuthorization(
        options: [.alert, .badge, .sound, .provisional]
      ) { granted, error in
        print("iOS Notification permission granted: \(granted)")
        if let error = error {
          print("iOS Notification permission error: \(error)")
        }
        
        // Configure notification categories for better user experience
        self.setupNotificationCategories()
      }
    }
    
    // Register for remote notifications
    application.registerForRemoteNotifications()
    
    // Configure background app refresh for better notification delivery
    application.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalMinimum)
    
    // Register Flutter plugins
    GeneratedPluginRegistrant.register(with: self)
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  // Set up iOS notification categories for better user experience
  private func setupNotificationCategories() {
    if #available(iOS 10.0, *) {
      // Study Reminders Category
      let studyRemindersCategory = UNNotificationCategory(
        identifier: "mindload_study_reminders",
        actions: [],
        intentIdentifiers: [],
        options: [.allowAnnouncement]
      )
      
      // Deadlines Category
      let deadlinesCategory = UNNotificationCategory(
        identifier: "mindload_deadlines",
        actions: [],
        intentIdentifiers: [],
        options: [.allowAnnouncement]
      )
      
      // Achievements Category
      let achievementsCategory = UNNotificationCategory(
        identifier: "mindload_achievements",
        actions: [],
        intentIdentifiers: [],
        options: [.allowAnnouncement]
      )
      
      // General Category
      let generalCategory = UNNotificationCategory(
        identifier: "mindload_notifications",
        actions: [],
        intentIdentifiers: [],
        options: [.allowAnnouncement]
      )
      
      // Register all categories
      UNUserNotificationCenter.current().setNotificationCategories([
        studyRemindersCategory,
        deadlinesCategory,
        achievementsCategory,
        generalCategory
      ])
      
      print("✅ iOS notification categories configured successfully")
    }
  }
  
  // Handle notification when app is in foreground with enhanced options
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    if #available(iOS 14.0, *) {
      completionHandler([.banner, .sound, .badge])
    } else {
      completionHandler([.alert, .sound, .badge])
    }
  }
  
  // Handle notification tap with enhanced response handling
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    // Handle notification response
    let userInfo = response.notification.request.content.userInfo
    print("📱 Notification tapped: \(userInfo)")
    
    completionHandler()
  }
  
  // Background app refresh for better notification delivery
  override func application(
    _ application: UIApplication,
    performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
  ) {
    // Allow background processing for notifications
    completionHandler(.newData)
  }
  
  // Handle successful registration for remote notifications
  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    print("✅ Successfully registered for remote notifications with token")
    
    // Convert token to string for debugging
    let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
    let token = tokenParts.joined()
    print("📱 Device Token: \(token)")
  }
  
  // Handle failed registration for remote notifications
  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    print("❌ Failed to register for remote notifications: \(error)")
  }
  
  // Handle notification settings changes
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    openSettingsFor notification: UNNotification?
  ) {
    print("📱 User opened notification settings")
  }
}

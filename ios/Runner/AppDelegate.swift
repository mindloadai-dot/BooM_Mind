import Flutter
import UIKit
import Firebase
import GoogleSignIn
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  
  // Flutter method channel for communication
  private let NOTIFICATION_CHANNEL = "com.mindload.app/notifications"
  private var notificationChannel: FlutterMethodChannel?
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    // Initialize Firebase if GoogleService-Info.plist exists
    if let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") {
      FirebaseApp.configure()
      print("✅ Firebase configured successfully")
    }
    
    // Set up Flutter method channel
    if let controller = window?.rootViewController as? FlutterViewController {
      notificationChannel = FlutterMethodChannel(
        name: NOTIFICATION_CHANNEL,
        binaryMessenger: controller.binaryMessenger
      )
      setupMethodChannelHandlers()
    }
    
    // Configure notifications with enhanced iOS support
    UNUserNotificationCenter.current().delegate = self
    
    // Request comprehensive notification permissions including critical alerts
    requestNotificationPermissions()
    
    // Register for remote notifications
    application.registerForRemoteNotifications()
    
    // Configure background app refresh for better notification delivery
    application.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalMinimum)
    
    // Handle notification if app was launched from one
    if let notification = launchOptions?[UIApplication.LaunchOptionsKey.remoteNotification] as? [String: AnyObject] {
      handleNotificationLaunch(notification)
    }
    
    // Register Flutter plugins
    GeneratedPluginRegistrant.register(with: self)
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  // Request comprehensive notification permissions
  private func requestNotificationPermissions() {
    if #available(iOS 10.0, *) {
      let options: UNAuthorizationOptions = [
        .alert, .badge, .sound, .provisional, .criticalAlert, .announcement
      ]
      
      UNUserNotificationCenter.current().requestAuthorization(options: options) { granted, error in
        print("🍎 iOS Notification permission granted: \(granted)")
        
        if let error = error {
          print("❌ iOS Notification permission error: \(error)")
        }
        
        if granted {
          DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
            self.setupNotificationCategories()
            self.notifyFlutterPermissionResult(granted: true)
          }
        } else {
          self.notifyFlutterPermissionResult(granted: false)
        }
      }
    }
  }
  
  // Set up Flutter method channel handlers
  private func setupMethodChannelHandlers() {
    notificationChannel?.setMethodCallHandler({ [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
      switch call.method {
      case "requestPermissions":
        self?.requestNotificationPermissions()
        result(nil)
      case "checkPermissions":
        self?.checkNotificationPermissions(result: result)
      case "openSettings":
        if #available(iOS 10.0, *) {
          UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
              if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
              }
            }
          }
        }
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    })
  }
  
  // Check current notification permissions
  private func checkNotificationPermissions(result: @escaping FlutterResult) {
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().getNotificationSettings { settings in
        let authStatus = settings.authorizationStatus
        let isGranted = authStatus == .authorized || authStatus == .provisional
        
        DispatchQueue.main.async {
          result([
            "granted": isGranted,
            "authorizationStatus": self.authorizationStatusString(authStatus),
            "alertSetting": self.notificationSettingString(settings.alertSetting),
            "badgeSetting": self.notificationSettingString(settings.badgeSetting),
            "soundSetting": self.notificationSettingString(settings.soundSetting),
            "criticalAlertSetting": self.notificationSettingString(settings.criticalAlertSetting),
            "lockScreenSetting": self.notificationSettingString(settings.lockScreenSetting),
            "notificationCenterSetting": self.notificationSettingString(settings.notificationCenterSetting)
          ])
        }
      }
    } else {
      result(["granted": false, "error": "iOS version not supported"])
    }
  }
  
  // Convert authorization status to string
  private func authorizationStatusString(_ status: UNAuthorizationStatus) -> String {
    switch status {
    case .notDetermined: return "notDetermined"
    case .denied: return "denied"
    case .authorized: return "authorized"
    case .provisional: return "provisional"
    case .ephemeral: return "ephemeral"
    @unknown default: return "unknown"
    }
  }
  
  // Convert notification setting to string
  private func notificationSettingString(_ setting: UNNotificationSetting) -> String {
    switch setting {
    case .notSupported: return "notSupported"
    case .disabled: return "disabled"
    case .enabled: return "enabled"
    @unknown default: return "unknown"
    }
  }
  
  // Notify Flutter about permission result
  private func notifyFlutterPermissionResult(granted: Bool) {
    notificationChannel?.invokeMethod("onPermissionResult", arguments: ["granted": granted])
  }
  
  // Set up comprehensive iOS notification categories with actions
  private func setupNotificationCategories() {
    if #available(iOS 10.0, *) {
      
      // Study Reminders Category with Actions
      let startStudyAction = UNNotificationAction(
        identifier: "start_study",
        title: "Start Studying",
        options: [.foreground]
      )
      let postponeAction = UNNotificationAction(
        identifier: "postpone",
        title: "Postpone 30 min",
        options: []
      )
      let studyRemindersCategory = UNNotificationCategory(
        identifier: "mindload_study_reminders",
        actions: [startStudyAction, postponeAction],
        intentIdentifiers: [],
        options: [.allowAnnouncement, .allowInCarPlay]
      )
      
      // Pop Quiz Category with Actions
      let takeQuizAction = UNNotificationAction(
        identifier: "take_quiz",
        title: "Take Quiz",
        options: [.foreground]
      )
      let skipQuizAction = UNNotificationAction(
        identifier: "skip",
        title: "Skip",
        options: []
      )
      let popQuizCategory = UNNotificationCategory(
        identifier: "mindload_pop_quiz",
        actions: [takeQuizAction, skipQuizAction],
        intentIdentifiers: [],
        options: [.allowAnnouncement, .allowInCarPlay]
      )
      
      // Deadlines Category with Actions
      let viewDeadlineAction = UNNotificationAction(
        identifier: "view_deadline",
        title: "View Details",
        options: [.foreground]
      )
      let setReminderAction = UNNotificationAction(
        identifier: "set_reminder",
        title: "Set Reminder",
        options: []
      )
      let deadlinesCategory = UNNotificationCategory(
        identifier: "mindload_deadlines",
        actions: [viewDeadlineAction, setReminderAction],
        intentIdentifiers: [],
        options: [.allowAnnouncement, .allowInCarPlay]
      )
      
      // Achievements Category with Actions
      let viewAchievementAction = UNNotificationAction(
        identifier: "view_achievement",
        title: "View Achievement",
        options: [.foreground]
      )
      let shareAction = UNNotificationAction(
        identifier: "share",
        title: "Share",
        options: [.foreground]
      )
      let achievementsCategory = UNNotificationCategory(
        identifier: "mindload_achievements",
        actions: [viewAchievementAction, shareAction],
        intentIdentifiers: [],
        options: [.allowAnnouncement]
      )
      
      // Promotions Category with Actions
      let viewOfferAction = UNNotificationAction(
        identifier: "view_offer",
        title: "View Offer",
        options: [.foreground]
      )
      let dismissAction = UNNotificationAction(
        identifier: "dismiss",
        title: "Dismiss",
        options: [.destructive]
      )
      let promotionsCategory = UNNotificationCategory(
        identifier: "mindload_promotions",
        actions: [viewOfferAction, dismissAction],
        intentIdentifiers: [],
        options: []
      )
      
      // General Category with Basic Actions
      let openAppAction = UNNotificationAction(
        identifier: "open_app",
        title: "Open App",
        options: [.foreground]
      )
      let generalCategory = UNNotificationCategory(
        identifier: "mindload_notifications",
        actions: [openAppAction],
        intentIdentifiers: [],
        options: [.allowAnnouncement]
      )
      
      // Register all categories
      UNUserNotificationCenter.current().setNotificationCategories([
        studyRemindersCategory,
        popQuizCategory,
        deadlinesCategory,
        achievementsCategory,
        promotionsCategory,
        generalCategory
      ])
      
      print("✅ iOS notification categories configured with actions")
    }
  }
  
  // Handle notification when app is in foreground
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    print("📱 Notification received in foreground: \(notification.request.content.title)")
    
    // Always show notifications even when app is in foreground
    if #available(iOS 14.0, *) {
      completionHandler([.banner, .sound, .badge])
    } else {
      completionHandler([.alert, .sound, .badge])
    }
  }
  
  // Handle notification tap and actions
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    let userInfo = response.notification.request.content.userInfo
    let actionIdentifier = response.actionIdentifier
    
    print("📱 Notification action: \(actionIdentifier)")
    print("📱 Notification userInfo: \(userInfo)")
    
    // Handle different actions
    switch actionIdentifier {
    case "start_study":
      handleNotificationAction("start_study", userInfo: userInfo)
    case "postpone":
      handleNotificationAction("postpone", userInfo: userInfo)
    case "take_quiz":
      handleNotificationAction("take_quiz", userInfo: userInfo)
    case "skip":
      handleNotificationAction("skip", userInfo: userInfo)
    case "view_deadline":
      handleNotificationAction("view_deadline", userInfo: userInfo)
    case "set_reminder":
      handleNotificationAction("set_reminder", userInfo: userInfo)
    case "view_achievement":
      handleNotificationAction("view_achievement", userInfo: userInfo)
    case "share":
      handleNotificationAction("share", userInfo: userInfo)
    case "view_offer":
      handleNotificationAction("view_offer", userInfo: userInfo)
    case "dismiss":
      handleNotificationAction("dismiss", userInfo: userInfo)
    case "open_app":
      handleNotificationAction("open_app", userInfo: userInfo)
    case UNNotificationDefaultActionIdentifier:
      // Default tap action
      handleNotificationTap(userInfo: userInfo)
    case UNNotificationDismissActionIdentifier:
      // Notification dismissed
      print("📱 Notification dismissed")
    default:
      print("📱 Unknown action identifier: \(actionIdentifier)")
    }
    
    completionHandler()
  }
  
  // Handle notification tap (when user taps notification without action)
  private func handleNotificationTap(userInfo: [AnyHashable: Any]) {
    if let deepLink = userInfo["deepLink"] as? String {
      handleDeepLink(deepLink)
    } else {
      // Default action - open app
      notificationChannel?.invokeMethod("onNotificationTapped", arguments: userInfo)
    }
  }
  
  // Handle specific notification actions
  private func handleNotificationAction(_ action: String, userInfo: [AnyHashable: Any]) {
    let payload = [
      "action": action,
      "userInfo": userInfo
    ] as [String : Any]
    
    notificationChannel?.invokeMethod("onNotificationAction", arguments: payload)
    
    // Handle specific actions that don't require Flutter
    switch action {
    case "postpone":
      // Reschedule notification for 30 minutes later
      schedulePostponedNotification(userInfo: userInfo)
    case "dismiss":
      // Just dismiss, no action needed
      break
    default:
      // For actions that require Flutter, send to Flutter
      break
    }
  }
  
  // Handle deep linking from notifications
  private func handleDeepLink(_ deepLink: String) {
    print("🔗 Handling deep link: \(deepLink)")
    notificationChannel?.invokeMethod("onDeepLink", arguments: ["deepLink": deepLink])
  }
  
  // Handle app launch from notification
  private func handleNotificationLaunch(_ userInfo: [String: AnyObject]) {
    print("🚀 App launched from notification: \(userInfo)")
    notificationChannel?.invokeMethod("onNotificationLaunch", arguments: userInfo)
  }
  
  // Schedule postponed notification
  private func schedulePostponedNotification(userInfo: [AnyHashable: Any]) {
    if #available(iOS 10.0, *) {
      let content = UNMutableNotificationContent()
      content.title = (userInfo["title"] as? String) ?? "Study Reminder"
      content.body = "⏰ Postponed reminder: Time to continue your studies!"
      content.sound = .default
      content.badge = NSNumber(value: 1)
      
      // Schedule for 30 minutes from now
      let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 30 * 60, repeats: false)
      let request = UNNotificationRequest(
        identifier: "postponed_\(Date().timeIntervalSince1970)",
        content: content,
        trigger: trigger
      )
      
      UNUserNotificationCenter.current().add(request) { error in
        if let error = error {
          print("❌ Failed to schedule postponed notification: \(error)")
        } else {
          print("✅ Postponed notification scheduled for 30 minutes")
        }
      }
    }
  }
  
  // Background app refresh for better notification delivery
  override func application(
    _ application: UIApplication,
    performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
  ) {
    print("🔄 Background fetch triggered")
    // Perform background tasks to keep notifications fresh
    completionHandler(.newData)
  }
  
  // Handle successful remote notification registration
  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    print("✅ Successfully registered for remote notifications")
    
    // Convert token to string for debugging and sending to backend
    let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
    let token = tokenParts.joined()
    print("📱 Device Token (first 20 chars): \(String(token.prefix(20)))...")
    
    // Send token to Flutter
    notificationChannel?.invokeMethod("onDeviceToken", arguments: ["token": token])
  }
  
  // Handle failed remote notification registration
  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    print("❌ Failed to register for remote notifications: \(error)")
    notificationChannel?.invokeMethod("onDeviceTokenError", arguments: ["error": error.localizedDescription])
  }
  
  // Handle remote notifications received while app is running
  override func application(
    _ application: UIApplication,
    didReceiveRemoteNotification userInfo: [AnyHashable : Any],
    fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
  ) {
    print("📱 Remote notification received: \(userInfo)")
    
    // Handle background data fetching if needed
    notificationChannel?.invokeMethod("onRemoteNotification", arguments: userInfo)
    
    completionHandler(.newData)
  }
  
  // Handle notification settings changes
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    openSettingsFor notification: UNNotification?
  ) {
    print("⚙️ User opened notification settings")
    notificationChannel?.invokeMethod("onNotificationSettingsOpened", arguments: nil)
  }
  
  // Handle app becoming active
  override func applicationDidBecomeActive(_ application: UIApplication) {
    super.applicationDidBecomeActive(application)
    
    // Clear badge count when app becomes active
    application.applicationIconBadgeNumber = 0
    
    // Check notification permission status and update Flutter
    checkNotificationPermissions { result in
      self.notificationChannel?.invokeMethod("onPermissionStatusChanged", arguments: result)
    }
  }
  
  // Handle app entering background
  override func applicationDidEnterBackground(_ application: UIApplication) {
    super.applicationDidEnterBackground(application)
    print("📱 App entered background")
  }
  
  // Handle app termination
  override func applicationWillTerminate(_ application: UIApplication) {
    super.applicationWillTerminate(application)
    print("📱 App will terminate")
  }
  
  // CRITICAL: Handle URL opening for Google Sign-In
  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey : Any] = [:]
  ) -> Bool {
    print("🔗 Handling URL: \(url.absoluteString)")
    
    // Handle Google Sign-In URL
    if GIDSignIn.sharedInstance.handle(url) {
      print("✅ Google Sign-In handled URL successfully")
      return true
    }
    
    // Fallback to super implementation
    return super.application(app, open: url, options: options)
  }
}

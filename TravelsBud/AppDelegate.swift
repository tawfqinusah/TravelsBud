import UIKit
import Firebase
import FirebaseCore
import FirebaseMessaging
import FirebaseAnalytics
import UserNotifications
import FirebaseAppCheck
import FirebaseFirestore
import Network

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
    private var networkMonitor: NWPathMonitor?
    private var isConnected = true

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Configure App Check for Debug
        #if DEBUG
        let providerFactory = AppCheckDebugProviderFactory()
        AppCheck.setAppCheckProviderFactory(providerFactory)
        #endif
        
        // Firebase configuration
        FirebaseApp.configure()
        
        // Enable Analytics
        Analytics.setAnalyticsCollectionEnabled(true)
        
        // Register for notifications
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self  // Assign the delegate here
        
        // Request permission to receive notifications
        requestNotificationPermission(application)
        
        // Setup network monitoring
        setupNetworkMonitoring()
        
        return true
    }
    
    private func setupNetworkMonitoring() {
        networkMonitor = NWPathMonitor()
        let queue = DispatchQueue(label: "NetworkMonitor")
        
        networkMonitor?.pathUpdateHandler = { [weak self] path in
            let newConnectionState = path.status == .satisfied
            let previousState = self?.isConnected ?? false
            self?.isConnected = newConnectionState
            
            if !previousState && newConnectionState {
                // Network was restored - trigger reconnection
                DispatchQueue.main.async {
                    // Reinitialize Firebase connection
                    let db = Firestore.firestore()
                    db.enableNetwork { error in
                        if let error = error {
                            print("Error re-enabling Firestore: \(error.localizedDescription)")
                        }
                    }
                }
            }
        }
        
        networkMonitor?.start(queue: queue)
    }
    
    // MARK: UISceneSession Lifecycle
    func application(_ application: UIApplication,
                    configurationForConnecting connectingSceneSession: UISceneSession,
                    options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication,
                    didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    }
    
    // Request notification permission (Updated for iOS 14+)
    func requestNotificationPermission(_ application: UIApplication) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                DispatchQueue.main.async {
                    application.registerForRemoteNotifications()
                }
            }
        }
    }
    
    // This function is called when FCM token is refreshed
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken else { return }
        print("FCM Token: \(token)")
        // Save or send the token to your backend if needed
    }
    
    // Handle incoming notifications when the app is in the foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // For iOS 14+, use .banner, .badge, and .sound
        completionHandler([.badge, .sound, .banner])  // Display notifications as banners
    }
}

import Flutter
import UIKit
import FirebaseCore
import FirebaseMessaging

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Configure before native APNs callbacks. Dart Firebase.initializeApp()
    // will reuse this default app. Preserve startup when config is absent.
    if FirebaseApp.app() == nil,
       Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil {
      FirebaseApp.configure()
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    // UIScene initializes Flutter plugins after the application launch callback.
    // Explicitly request APNs registration once the plugins have registered.
    DispatchQueue.main.async {
      guard FirebaseApp.app() != nil else {
        NSLog("Push native: Firebase is unavailable; check the bundled GoogleService-Info.plist.")
        return
      }
      NSLog("Push native: requesting APNs registration.")
      UIApplication.shared.registerForRemoteNotifications()
    }
  }

  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    if FirebaseApp.app() != nil {
      // Ensure getAPNSToken() can read Apple's token; do not log the token itself.
      Messaging.messaging().apnsToken = deviceToken
      NSLog("Push native: APNs token received and passed to Firebase (%ld bytes).", deviceToken.count)
    } else {
      NSLog("Push native: APNs token received, but Firebase is unavailable.")
    }
    // Preserve forwarding to Flutter plugins and their lifecycle handlers.
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    let nativeError = error as NSError
    NSLog("Push native: APNs registration failed [%@/%ld]: %@",
          nativeError.domain, nativeError.code, nativeError.localizedDescription)
    super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
  }
}

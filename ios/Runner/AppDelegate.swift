import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    let launched = super.application(
      application,
      didFinishLaunchingWithOptions: launchOptions
    )
    if let controller = window?.rootViewController as? FlutterViewController {
      let notifications = FlutterMethodChannel(
        name: "com.ntspsc.app/notifications",
        binaryMessenger: controller.binaryMessenger
      )
      notifications.setMethodCallHandler { call, result in
        guard call.method == "setBadgeCount",
              let arguments = call.arguments as? [String: Any],
              let count = arguments["count"] as? Int else {
          result(FlutterMethodNotImplemented)
          return
        }
        UIApplication.shared.applicationIconBadgeNumber = max(0, count)
        result(nil)
      }
    }
    return launched
  }
}

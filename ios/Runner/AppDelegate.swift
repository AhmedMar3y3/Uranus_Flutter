import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let fileOpenerChannel = "uranus/file_opener"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if let controller = window?.rootViewController as? FlutterViewController {
      registerFileOpener(binaryMessenger: controller.binaryMessenger)
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  private func registerFileOpener(binaryMessenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: fileOpenerChannel, binaryMessenger: binaryMessenger)
    channel.setMethodCallHandler { call, result in
      guard call.method == "open" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard
        let args = call.arguments as? [String: Any],
        let text = args["url"] as? String,
        let url = URL(string: text)
      else {
        result(FlutterError(code: "invalid_url", message: "File is not ready yet.", details: nil))
        return
      }

      UIApplication.shared.open(url, options: [:]) { opened in
        if opened {
          result(nil)
        } else {
          result(FlutterError(code: "no_viewer", message: "No app is available to open this file.", details: nil))
        }
      }
    }
  }
}

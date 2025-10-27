import Flutter
import UIKit

final class SecureWindow: UIWindow {
  override func snapshotView(afterScreenUpdates afterUpdates: Bool) -> UIView? {
    return makeBlankSnapshot(for: bounds)
  }

  override func resizableSnapshotView(
    from rect: CGRect,
    afterScreenUpdates afterUpdates: Bool,
    withCapInsets capInsets: UIEdgeInsets
  ) -> UIView? {
    return makeBlankSnapshot(for: rect)
  }

  override func drawHierarchy(in rect: CGRect, afterScreenUpdates afterUpdates: Bool) -> Bool {
    UIColor.white.setFill()
    UIRectFill(rect)
    return true
  }

  private func makeBlankSnapshot(for rect: CGRect) -> UIView {
    let view = UIView(frame: rect)
    view.backgroundColor = .white
    return view
  }
}

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var privacyOverlay: UIView?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    ensureSecureWindow()

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleScreenCaptureChange),
      name: UIScreen.capturedDidChangeNotification,
      object: nil
    )

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleScreenshotNotification),
      name: UIApplication.userDidTakeScreenshotNotification,
      object: nil
    )

    if UIScreen.main.isCaptured {
      addPrivacyOverlay()
    }

    let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)

    ensureSecureWindow()

    return result
  }

  override func applicationWillResignActive(_ application: UIApplication) {
    super.applicationWillResignActive(application)
    addPrivacyOverlay()
  }

  override func applicationDidBecomeActive(_ application: UIApplication) {
    super.applicationDidBecomeActive(application)
    if !UIScreen.main.isCaptured {
      removePrivacyOverlay()
    }
  }

  private func addPrivacyOverlay() {
    guard let window = window else { return }

    if privacyOverlay == nil {
      let overlay = UIView(frame: window.bounds)
      overlay.backgroundColor = UIColor.white
      overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
      overlay.isUserInteractionEnabled = false
      window.addSubview(overlay)
      privacyOverlay = overlay
    } else if let overlay = privacyOverlay {
      overlay.isHidden = false
      overlay.frame = window.bounds
      window.bringSubviewToFront(overlay)
    }
  }

  private func removePrivacyOverlay() {
    privacyOverlay?.removeFromSuperview()
    privacyOverlay = nil
  }

  @objc private func handleScreenCaptureChange() {
    if UIScreen.main.isCaptured {
      addPrivacyOverlay()
    } else if UIApplication.shared.applicationState == .active {
      removePrivacyOverlay()
    }
  }

  @objc private func handleScreenshotNotification() {
    addPrivacyOverlay()

    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
      guard let self = self else { return }
      if !UIScreen.main.isCaptured && UIApplication.shared.applicationState == .active {
        self.removePrivacyOverlay()
      }
    }
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  private func ensureSecureWindow() {
    guard let currentWindow = window else {
      window = SecureWindow(frame: UIScreen.main.bounds)
      return
    }

    guard !(currentWindow is SecureWindow) else {
      return
    }

    let secureWindow = SecureWindow(frame: currentWindow.frame)
    secureWindow.rootViewController = currentWindow.rootViewController
    secureWindow.windowLevel = currentWindow.windowLevel
    secureWindow.makeKeyAndVisible()
    window = secureWindow
  }
}

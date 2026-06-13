import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  
  private var secureField: UITextField?
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    let controller = window?.rootViewController as! FlutterViewController
    
    // KRIPTONSHARE iOS Anti-Capture Hack
    // Exploit UITextField.isSecureTextEntry to prevent screenshots
    setupSecureField()
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  /// Sets up the UITextField hack to prevent screenshots
  private func setupSecureField() {
    guard let window = self.window else { return }
    
    let field = UITextField()
    field.isSecureTextEntry = true
    field.isUserInteractionEnabled = false
    field.frame = window.bounds
    
    // Re-parent FlutterViewController's view into the secure field's layer
    window.addSubview(field)
    field.layer.superlayer?.addSublayer(window.layer)
    
    self.secureField = field
  }
  
  /// Enable secure view (called from Flutter via MethodChannel)
  @objc func enableSecureView() {
    guard let window = self.window else { return }
    
    if secureField == nil {
      let field = UITextField()
      field.isSecureTextEntry = true
      field.isUserInteractionEnabled = false
      field.frame = window.bounds
      window.addSubview(field)
      field.layer.superlayer?.addSublayer(window.layer)
      secureField = field
    }
  }
  
  /// Disable secure view (called from Flutter via MethodChannel)
  @objc func disableSecureView() {
    secureField?.removeFromSuperview()
    secureField = nil
  }
  
  override func applicationWillResignActive(_ application: UIApplication) {
    // Pause any sensitive operations
    super.applicationWillResignActive(application)
  }
  
  override func applicationDidBecomeActive(_ application: UIApplication) {
    // Re-enable secure view when app becomes active
    setupSecureField()
    super.applicationDidBecomeActive(application)
  }
}

import Cocoa
import FlutterMacOS
import Sparkle
import os.log

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
    
  var updaterController: SPUStandardUpdaterController!

  override func applicationDidFinishLaunching(_ aNotification: Notification) {
      print("🔥 App launched")
    
      updaterController = SPUStandardUpdaterController(
          startingUpdater: true,
          updaterDelegate: nil,
          userDriverDelegate: nil
      )
        
      print("🔥 Sparkle initialized")
    
      self.updaterController.updater.checkForUpdates()
      
      super.applicationDidFinishLaunching(aNotification)
    // RegisterGeneratedPlugins(registry: self)  <-- Removed, not needed.
  }
}

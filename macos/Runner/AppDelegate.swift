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
    
  let updaterDelegate = UpdaterLoggerDelegate()

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

class UpdaterLoggerDelegate: NSObject, SPUUpdaterDelegate, SPUDownloadDataDelegate {

    func updater(_ updater: SPUUpdater, willDownloadUpdate item: SUAppcastItem, with request: URLRequest) {
        print("🔥 Sparkle will start downloading update from: \(request.url?.absoluteString ?? "unknown")")
    }

    func updater(_ updater: SPUUpdater, didDownloadUpdate item: SUAppcastItem, downloadData: SPUDownloadData) {
        // This is where you can see the temporary file
        if let tempURL = downloadData.fileURL {
            print("🔥 Sparkle downloaded zip to temporary path: \(tempURL.path)")
        } else {
            print("⚠️ Could not get temporary zip path")
        }
    }
}

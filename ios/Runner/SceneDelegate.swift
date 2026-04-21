import Flutter
import UIKit
import UniformTypeIdentifiers

class SceneDelegate: FlutterSceneDelegate, UIDocumentPickerDelegate {
  private static let bookmarkKey = "ios_folder_bookmark"
  private var pendingResult: FlutterResult?

  override func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
    super.scene(scene, willConnectTo: session, options: connectionOptions)

    guard let controller = window?.rootViewController as? FlutterViewController else { return }
    let channel = FlutterMethodChannel(name: "dev.eintim.wiiudownloader/bookmark",
                                       binaryMessenger: controller.binaryMessenger)

    channel.setMethodCallHandler { [weak self] (call, result) in
      switch call.method {
      case "pickAndBookmarkFolder":
        self?.pickAndBookmarkFolder(controller: controller, result: result)
      case "resolveBookmark":
        self?.resolveBookmark(result: result)
      case "startAccessingBookmark":
        self?.startAccessingBookmark(result: result)
      case "stopAccessingBookmark":
        self?.stopAccessingBookmark(result: result)
      case "hasBookmark":
        let has = UserDefaults.standard.data(forKey: SceneDelegate.bookmarkKey) != nil
        result(has)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }


  private func pickAndBookmarkFolder(controller: FlutterViewController, result: @escaping FlutterResult) {
    pendingResult = result
    let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.folder])
    picker.allowsMultipleSelection = false
    picker.delegate = self
    controller.present(picker, animated: true)
  }

  private func resolveBookmark(result: @escaping FlutterResult) {
    guard let data = UserDefaults.standard.data(forKey: SceneDelegate.bookmarkKey) else {
      result(FlutterError(code: "NO_BOOKMARK", message: "No folder bookmark saved", details: nil))
      return
    }
    do {
      var isStale = false
      let url = try URL(resolvingBookmarkData: data,
                        options: [],
                        relativeTo: nil,
                        bookmarkDataIsStale: &isStale)
      if isStale {
        if url.startAccessingSecurityScopedResource() {
          defer { url.stopAccessingSecurityScopedResource() }
          let newData = try url.bookmarkData(options: [],
                                             includingResourceValuesForKeys: nil,
                                             relativeTo: nil)
          UserDefaults.standard.set(newData, forKey: SceneDelegate.bookmarkKey)
        }
      }
      result(url.path)
    } catch {
      result(FlutterError(code: "RESOLVE_FAILED", message: error.localizedDescription, details: nil))
    }
  }

  private func startAccessingBookmark(result: @escaping FlutterResult) {
    guard let data = UserDefaults.standard.data(forKey: SceneDelegate.bookmarkKey) else {
      result(FlutterError(code: "NO_BOOKMARK", message: "No folder bookmark saved", details: nil))
      return
    }
    do {
      var isStale = false
      let url = try URL(resolvingBookmarkData: data,
                        options: [],
                        relativeTo: nil,
                        bookmarkDataIsStale: &isStale)
      let success = url.startAccessingSecurityScopedResource()
      if success && isStale {
        if let newData = try? url.bookmarkData(options: [],
                                                includingResourceValuesForKeys: nil,
                                                relativeTo: nil) {
          UserDefaults.standard.set(newData, forKey: SceneDelegate.bookmarkKey)
        }
      }
      result(success ? url.path : nil)
    } catch {
      result(FlutterError(code: "ACCESS_FAILED", message: error.localizedDescription, details: nil))
    }
  }

  private func stopAccessingBookmark(result: @escaping FlutterResult) {
    guard let data = UserDefaults.standard.data(forKey: SceneDelegate.bookmarkKey) else {
      result(nil)
      return
    }
    do {
      var isStale = false
      let url = try URL(resolvingBookmarkData: data,
                        options: [],
                        relativeTo: nil,
                        bookmarkDataIsStale: &isStale)
      url.stopAccessingSecurityScopedResource()
      result(nil)
    } catch {
      result(nil)
    }
  }

  func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
    guard let url = urls.first else {
      pendingResult?(FlutterError(code: "NO_SELECTION", message: "No folder selected", details: nil))
      pendingResult = nil
      return
    }

    guard url.startAccessingSecurityScopedResource() else {
      pendingResult?(FlutterError(code: "ACCESS_DENIED", message: "Cannot access selected folder", details: nil))
      pendingResult = nil
      return
    }
    defer { url.stopAccessingSecurityScopedResource() }

    do {
      let bookmarkData = try url.bookmarkData(options: [],
                                               includingResourceValuesForKeys: nil,
                                               relativeTo: nil)
      UserDefaults.standard.set(bookmarkData, forKey: SceneDelegate.bookmarkKey)
      pendingResult?(url.path)
    } catch {
      pendingResult?(FlutterError(code: "BOOKMARK_FAILED", message: error.localizedDescription, details: nil))
    }
    pendingResult = nil
  }

  func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    pendingResult?(nil)
    pendingResult = nil
  }
}

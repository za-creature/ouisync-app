import Cocoa
import FlutterMacOS
import Common
import FileProvider
import LaunchAtLogin


class MainFlutterWindow: NSWindow {
    var fileProviderProxy: FileProviderProxy? = nil
    var flutterMethodChannel: FlutterMethodChannel? = nil
    let methodChannelName: String = "org.equalitie.ouisync/native"

    override func awakeFromNib() {
        let flutterViewController = FlutterViewController()
        let windowFrame = self.frame
        self.contentViewController = flutterViewController
        self.setFrame(windowFrame, display: true)

        let flutterBinaryMessenger = flutterViewController.engine.binaryMessenger
        setupFlutterToExtensionProxy(flutterBinaryMessenger)
        setupFlutterMethodChannel(flutterBinaryMessenger)
        setupFlutterAutostartChannel(flutterBinaryMessenger)

        RegisterGeneratedPlugins(registry: flutterViewController)

        super.awakeFromNib()
    }

    // ------------------------------------------------------------------
    // Autostart requires some custom platform integration as per:
    // https://pub.dev/packages/launch_at_startup#macos-support
    // ------------------------------------------------------------------
    fileprivate func setupFlutterAutostartChannel(_ binaryMessenger: FlutterBinaryMessenger) {
        FlutterMethodChannel(name: "launch_at_startup",
                             binaryMessenger: binaryMessenger)
        .setMethodCallHandler { call, result in
            switch call.method {
            case "launchAtStartupSetEnabled":
                if let arguments = call.arguments as? [String: Any],
                   let value = arguments["setEnabledValue"] as? Bool {
                    LaunchAtLogin.isEnabled = value
                }
                fallthrough
            case "launchAtStartupIsEnabled": result(LaunchAtLogin.isEnabled)
            default: result(FlutterMethodNotImplemented)
            }
        }
    }

    // ------------------------------------------------------------------
    // Setup proxy between flutter and the file provider extension
    // ------------------------------------------------------------------
    fileprivate func setupFlutterToExtensionProxy(_ binaryMessenger: FlutterBinaryMessenger) {
        if fileProviderProxy == nil {
            fileProviderProxy = FileProviderProxy(binaryMessenger)
        }
    }

    // ------------------------------------------------------------------
    // Setup handing of message from flutter to this app instance
    // ------------------------------------------------------------------
    fileprivate func setupFlutterMethodChannel(_ binaryMessenger: FlutterBinaryMessenger) {
        let channel = FlutterMethodChannel(name: methodChannelName, binaryMessenger: binaryMessenger)
        channel.setMethodCallHandler({ [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            guard let self = self else { return }
            handleFlutterMethodCall(call, result: result)
        })
        flutterMethodChannel = channel
    }

    private func handleFlutterMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getDefaultRepositoriesDirectory":
            let commonDirs = Common.Directories()
            result(commonDirs.repositoriesPath)
        case "getMountRootDirectory":
            let manager = NSFileProviderManager(for: ouisyncFileProviderDomain)!
            Task {
                let userVisibleRootUrl = try! await manager.getUserVisibleURL(for: .rootContainer)
                var path = userVisibleRootUrl.path(percentEncoded: false)
                if path.last == "/" {
                    path = String(path.dropLast())
                }
                result(path)
            }
        default:
            result(FlutterMethodNotImplemented)
            fatalError("Unknown method '\(call.method)' passed to channel '\(methodChannelName)'")
        }
    }
}


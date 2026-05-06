import SwiftUI
import WebKit
import CoreHaptics
import Photos

struct CloudWebView: UIViewRepresentable {
    @Binding var isLoaded: Bool
    
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        if #available(iOS 14.0, *) {
            configuration.limitsNavigationsToAppBoundDomains = false
        }
        
        let prefs = WKWebpagePreferences()
        if #available(iOS 14.0, *) {
            prefs.allowsContentJavaScript = true
        }
        configuration.defaultWebpagePreferences = prefs
        
        let userContentController = WKUserContentController()
        
        // 1. Inject Better xCloud UserScript
        if let scriptPath = Bundle.main.path(forResource: "better-xcloud.user", ofType: "js"),
           let scriptSource = try? String(contentsOfFile: scriptPath) {
            let userScript = WKUserScript(source: scriptSource, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
            userContentController.addUserScript(userScript)
        }
        
        // 2. CSS to prevent zooming, text selection and allow full screen feel
        let cssString = """
        var style = document.createElement('style');
        style.innerHTML = 'body { -webkit-user-select: none; user-select: none; touch-action: none; overscroll-behavior: none; }';
        document.head.appendChild(style);
        """
        let cssScript = WKUserScript(source: cssString, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        userContentController.addUserScript(cssScript)
        
        // 3. Prepare AppInterface for the userscript bridge
        let bridgeScript = """
        window.AppInterface = {
            vibrate: function(data, intensity) {
                window.webkit.messageHandlers.AppInterface.postMessage({type: 'vibrate', data: data, intensity: intensity});
            },
            saveScreenshot: function(name, data) {
                window.webkit.messageHandlers.AppInterface.postMessage({type: 'saveScreenshot', name: name, data: data});
            },
            closeApp: function() {
                window.webkit.messageHandlers.AppInterface.postMessage({type: 'closeApp'});
            }
        };
        """
        let interfaceScript = WKUserScript(source: bridgeScript, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        userContentController.addUserScript(interfaceScript)
        
        context.coordinator.messageHandler.delegate = context.coordinator
        userContentController.add(context.coordinator.messageHandler, name: "AppInterface")
        
        configuration.userContentController = userContentController
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.scrollView.showsVerticalScrollIndicator = false
        webView.scrollView.showsHorizontalScrollIndicator = false
        webView.scrollView.bounces = false
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        
        if let url = URL(string: "https://www.xbox.com/play") {
            webView.load(URLRequest(url: url))
        }
        
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        context.coordinator.parent = self
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate, BridgeProtocol {
        var parent: CloudWebView
        let messageHandler = BridgeMessageHandler()
        
        init(_ parent: CloudWebView) {
            self.parent = parent
            super.init()
            messageHandler.delegate = self
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation {
                    self.parent.isLoaded = true
                }
            }
        }
        
        // Handle JS Alerts
        func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
            let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in completionHandler() }))
            if let vc = UIApplication.shared.windows.first?.rootViewController {
                vc.present(alert, animated: true, completion: nil)
            } else {
                completionHandler()
            }
        }
        
        func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
            let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in completionHandler(true) }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in completionHandler(false) }))
            if let vc = UIApplication.shared.windows.first?.rootViewController {
                vc.present(alert, animated: true, completion: nil)
            } else {
                completionHandler(false)
            }
        }
        
        // Implement BridgeProtocol
        func handleVibrate(data: Any?, intensity: Any?) {
            // Simplified CoreHaptics implementation - using UIImpactFeedbackGenerator for quick response
            DispatchQueue.main.async {
                let generator = UIImpactFeedbackGenerator(style: .heavy)
                generator.impactOccurred()
            }
        }
        
        func handleSaveScreenshot(name: String, base64Data: String) {
            guard let data = Data(base64Encoded: base64Data.components(separatedBy: ",").last ?? base64Data),
                  let image = UIImage(data: data) else {
                return
            }
            
            PHPhotoLibrary.requestAuthorization { status in
                if status == .authorized || status == .limited {
                    UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                }
            }
        }
        
        func handleCloseApp() {
            // iOS doesn't allow programmatic exit, but we can suspend the app
            UIControl().sendAction(#selector(URLSessionTask.suspend), to: UIApplication.shared, for: nil)
        }
    }
}

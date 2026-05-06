import Foundation
import WebKit

protocol BridgeProtocol: AnyObject {
    func handleVibrate(data: Any?, intensity: Any?)
    func handleSaveScreenshot(name: String, base64Data: String)
    func handleCloseApp()
}

class BridgeMessageHandler: NSObject, WKScriptMessageHandler {
    weak var delegate: BridgeProtocol?
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let body = message.body as? [String: Any],
              let type = body["type"] as? String else {
            return
        }
        
        switch type {
        case "vibrate":
            delegate?.handleVibrate(data: body["data"], intensity: body["intensity"])
        case "saveScreenshot":
            if let name = body["name"] as? String, let data = body["data"] as? String {
                delegate?.handleSaveScreenshot(name: name, base64Data: data)
            }
        case "closeApp":
            delegate?.handleCloseApp()
        default:
            print("Unhandled message type: \(type)")
        }
    }
}

#if canImport(UIKit) && canImport(WebKit) && canImport(SwiftUI)
import UIKit
import WebKit

extension WebViewController {
    func openExternalLink(_ url: URL) -> Bool {
        guard let scheme = url.scheme?.lowercased() else { return false }
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let host = url.host?.lowercased()
        let pairing = (host == "wc" || url.lastPathComponent.lowercased() == "wc")
            && components?.queryItems?.contains { $0.name == "uri" && $0.value?.hasPrefix("wc:") == true } == true
        let universalLink = scheme == "https" && pairing
        let appSchemes = ["metamask", "trust", "trustwallet", "wc", "tg", "vk", "vkauthorize", "steam", "itms-apps", "mailto", "tel"]
        guard universalLink || appSchemes.contains(scheme) || (pairing && !WKWebView.handlesURLScheme(scheme)) else { return false }

        let options: [UIApplication.OpenExternalURLOptionsKey: Any] = universalLink ? [.universalLinksOnly: true] : [:]
        UIApplication.shared.open(url, options: options) { [weak self] opened in
            guard !opened else { return }
            let walletSchemes = ["metamask.app.link": "metamask", "link.metamask.io": "metamask", "link.trustwallet.com": "trust"]
            if universalLink, let host, let wallet = walletSchemes[host], let query = components?.percentEncodedQuery,
               let nativeURL = URL(string: "\(wallet)://wc?\(query)") {
                UIApplication.shared.open(nativeURL) { success in
                    if !success { self?.showExternalAppUnavailable() }
                }
            } else {
                self?.showExternalAppUnavailable()
            }
        }
        return true
    }

    private func showExternalAppUnavailable() {
        guard presentedViewController == nil else { return }
        let alert = UIAlertController(title: "Could not open the app", message: "Check that the selected app is installed and try again.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
#endif

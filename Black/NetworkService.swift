import Foundation
#if canImport(UIKit)
import UIKit
#endif

struct RegistrationResponse: Decodable, Sendable {
    let success: Bool
    let app_data: String?

    var contentURL: String? {
        guard success, let urlString = app_data, !urlString.isEmpty else {
            return nil
        }
        return urlString
    }
}

struct RegistrationRequest: Codable, Sendable {
    let bundle: String
    let push_token: String
    let advertising_id: String
    let appsflyer_id: String
}

@MainActor

final class NetworkService {
    static let shared = NetworkService()

    private let session: URLSession
    private let registrationGate = RegistrationGate()

    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.httpCookieStorage = HTTPCookieStorage.shared
        configuration.httpShouldSetCookies = true
        configuration.httpCookieAcceptPolicy = .always
        configuration.timeoutIntervalForRequest = AppConfiguration.networkTimeout
        configuration.timeoutIntervalForResource = AppConfiguration.networkTimeout

        self.session = URLSession(configuration: configuration)
    }

    init(session: URLSession) {
        self.session = session
    }

    private func getBundleIdentifier() -> String {
        Bundle.main.bundleIdentifier ?? ""
    }

    func performRegistration(
        pushToken: String = "",
        advertisingId: String = "",
        appsflyerId: String = "",
        completion: @escaping (DisplayMode, String?) -> Void
    ) {
        let gate = registrationGate
        guard gate.begin(completion) else { return }
        SessionVault.restore()
        if let cached = DataCache.shared.contentURL, !cached.isEmpty {
            gate.finish(.webContent, cached)
            return
        }
        if DataCache.shared.wasRegistrationAttempted {
            gate.finish(.nativeInterface, nil)
            return
        }

        let bundle = getBundleIdentifier()
        let requestBody = RegistrationRequest(
            bundle: bundle,
            push_token: pushToken,
            advertising_id: advertisingId,
            appsflyer_id: appsflyerId
        )

        guard let url = URL(string: AppConfiguration.registrationEndpoint) else {
            gate.finish(.nativeInterface, nil)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        #if canImport(UIKit)
        request.setValue(AppConfiguration.defaultUserAgent, forHTTPHeaderField: "User-Agent")
        #endif

        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
        } catch {
            gate.finish(.nativeInterface, nil)
            return
        }

        Task {
            do {
                let (data, response) = try await session.data(for: request)
                let http = response as? HTTPURLResponse
                SessionVault.store(response: http)
                SessionVault.persist()
                guard let http, (200..<300).contains(http.statusCode) else {
                    let cached = Self.cachedResult()
                    gate.finish(cached.0, cached.1)
                    return
                }
                let registrationData = try JSONDecoder().decode(RegistrationResponse.self, from: data)
                    if let contentURL = registrationData.contentURL {
                        DataCache.shared.saveContentURL(contentURL)
                        gate.finish(.webContent, contentURL)
                    } else {
                        DataCache.shared.wasRegistrationAttempted = true
                        let cached = Self.cachedResult()
                        gate.finish(cached.0, cached.1)
                    }
            } catch {
                let cached = Self.cachedResult()
                gate.finish(cached.0, cached.1)
            }
        }
    }

    private static func cachedResult() -> (DisplayMode, String?) {
        if let cached = DataCache.shared.contentURL, !cached.isEmpty {
            return (.webContent, cached)
        }
        return (.nativeInterface, nil)
    }

    func verifyURLAvailability(urlString: String, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: urlString) else { completion(false); return }
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        Task {
            do {
                let (_, response) = try await session.data(for: request)
                let code = (response as? HTTPURLResponse)?.statusCode ?? 500
                completion(code != 404 && code < 500)
            } catch { completion(false) }
        }
    }
}

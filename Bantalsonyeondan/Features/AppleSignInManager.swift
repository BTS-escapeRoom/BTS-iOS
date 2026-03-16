//
//  SignInManager.swift
//  Bantalsonyeondan
//
//  Created by Copilot on 12/03/25.
//

import Foundation
import AuthenticationServices
import UIKit
import WebKit

// MARK: - Apple Sign In helper
struct AppleSignInResult {
    let authorizationCode: String
    let state: String
}

final class AppleSignInManager: NSObject {
    static let shared = AppleSignInManager()

    private var continuation: CheckedContinuation<AppleSignInResult, Error>?
    private var expectedState: String?

    func signInWithAppleAsync(state: String, nonce: String) async throws -> AppleSignInResult {
        if continuation != nil {
            throw NSError(domain: "AppleSignIn", code: -1, userInfo: [NSLocalizedDescriptionKey: "Another sign-in is in progress"])
        }

        expectedState = state

        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.state = state
        request.nonce = nonce

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self

        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<AppleSignInResult, Error>) in
            self.continuation = continuation
            controller.performRequests()
        }
    }
}

extension AppleSignInManager: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            continuation?.resume(throwing: NSError(domain: "AppleSignIn", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid credential type"]))
            continuation = nil
            expectedState = nil
            return
        }

        guard let codeData = credential.authorizationCode,
              let code = String(data: codeData, encoding: .utf8) else {
            continuation?.resume(throwing: NSError(domain: "AppleSignIn", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing authorization code"]))
            continuation = nil
            expectedState = nil
            return
        }

        let state = credential.state ?? ""
        let result = AppleSignInResult(authorizationCode: code, state: state)
        continuation?.resume(returning: result)
        continuation = nil
        expectedState = nil
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        continuation?.resume(throwing: error)
        continuation = nil
        expectedState = nil
    }
}

extension AppleSignInManager: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        if #available(iOS 15.0, *) {
            return UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first { $0.isKeyWindow } ?? ASPresentationAnchor()
        } else {
            return UIApplication.shared.windows.first { $0.isKeyWindow } ?? ASPresentationAnchor()
        }
    }
}

// MARK: - Naver Sign In
struct NaverSignInResult {
    enum Outcome: Equatable {
        case success
        case signup
        case emptyNickname
    }

    let outcome: Outcome
    let callbackURL: URL
}

private struct NaverSignInConfiguration {
    let authorizeURL: URL
    let callbackURL: URL
    let callbackScheme: String

    static func load(bundle: Bundle = .main) throws -> NaverSignInConfiguration {
        let baseAuthorizeRedirectURI = (bundle.object(forInfoDictionaryKey: "NaverAuthorizeRedirectURI") as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let callbackURIString = (bundle.object(forInfoDictionaryKey: "NaverRedirectURI") as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        guard !baseAuthorizeRedirectURI.isEmpty else { throw NaverSignInError.configurationMissing("Info.plist의 NaverAuthorizeRedirectURI를 설정해주세요.") }
        guard var components = URLComponents(string: baseAuthorizeRedirectURI) else { throw NaverSignInError.configurationMissing("NaverAuthorizeRedirectURI 형식이 올바르지 않습니다.") }
        guard let callbackURL = URL(string: callbackURIString) else { throw NaverSignInError.configurationMissing("Info.plist의 NaverRedirectURI를 설정해주세요.") }
        guard let callbackScheme = callbackURL.scheme, !callbackScheme.isEmpty else { throw NaverSignInError.configurationMissing("NaverRedirectURI는 URL 스킴이 포함된 값이어야 합니다.") }

        var queryItems = components.queryItems ?? []
        queryItems.removeAll { $0.name == "return-url" }
        queryItems.append(URLQueryItem(name: "return-url", value: callbackURL.absoluteString))
        components.percentEncodedQuery = queryItems
            .compactMap { item -> String? in
                guard let value = item.value else { return item.name }
                let encodedName = item.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? item.name
                let encodedValue = value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? value
                return "\(encodedName)=\(encodedValue)"
            }
            .joined(separator: "&")

        guard let authorizeURL = components.url else {
            throw NaverSignInError.configurationMissing("구성된 Naver authorize URL이 올바르지 않습니다.")
        }

        #if DEBUG
        print("[DEBUG] Naver authorize URL: \(authorizeURL.absoluteString)")
        print("[DEBUG] Naver callback URL: \(callbackURL.absoluteString)")
        #endif

        return NaverSignInConfiguration(
            authorizeURL: authorizeURL,
            callbackURL: callbackURL,
            callbackScheme: callbackScheme
        )
    }
}

private enum NaverSignInError: LocalizedError {
    case configurationMissing(String)
    case loginInProgress
    case cancelled
    case failedToStartSession
    case missingCallbackURL
    case invalidCallbackURL
    case missingResult
    case authorizationFailed(String)

    var errorDescription: String? {
        switch self {
        case let .configurationMissing(msg): return msg
        case .loginInProgress: return "네이버 로그인이 이미 진행 중입니다."
        case .cancelled: return "네이버 로그인이 취소되었어요."
        case .failedToStartSession: return "네이버 로그인 화면을 시작하지 못했어요."
        case .missingCallbackURL: return "네이버 로그인 응답을 받지 못했어요."
        case .invalidCallbackURL: return "네이버 로그인 복귀 URL이 올바르지 않아요."
        case .missingResult: return "네이버 로그인 결과를 확인하지 못했어요."
        case let .authorizationFailed(message): return message
        }
    }
}

final class NaverSignInManager: NSObject {
    static let shared = NaverSignInManager()

    private var authenticationSession: ASWebAuthenticationSession?
    private var continuation: CheckedContinuation<NaverSignInResult, Error>?
    private var expectedCallbackURL: URL?

    @MainActor
    func signInWithNaverAsync() async throws -> NaverSignInResult {
        if continuation != nil { throw NaverSignInError.loginInProgress }

        let configuration = try NaverSignInConfiguration.load()
        expectedCallbackURL = configuration.callbackURL

        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<NaverSignInResult, Error>) in
            self.continuation = continuation

            let session = ASWebAuthenticationSession(
                url: configuration.authorizeURL,
                callbackURLScheme: configuration.callbackScheme
            ) { [weak self] callbackURL, error in
                self?.handleNaverCallback(callbackURL: callbackURL, error: error)
            }
            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = false
            authenticationSession = session

            guard session.start() else {
                completeNaverSignIn(with: .failure(NaverSignInError.failedToStartSession))
                return
            }
        }
    }

    private func handleNaverCallback(callbackURL: URL?, error: Error?) {
        #if DEBUG
        if let callbackURL {
            print("[DEBUG] Naver callback received in app: \(callbackURL.absoluteString)")
        }
        if let error {
            print("[DEBUG] Naver callback error: \(error.localizedDescription)")
        }
        #endif

        if let nsError = error as? ASWebAuthenticationSessionError,
           nsError.code == .canceledLogin {
            completeNaverSignIn(with: .failure(NaverSignInError.cancelled))
            return
        }

        if let error {
            completeNaverSignIn(with: .failure(error))
            return
        }

        guard let callbackURL else {
            completeNaverSignIn(with: .failure(NaverSignInError.missingCallbackURL))
            return
        }

        do {
            let result = try parseCallbackURL(callbackURL)
            completeNaverSignIn(with: .success(result))
        } catch {
            completeNaverSignIn(with: .failure(error))
        }
    }

    private func parseCallbackURL(_ callbackURL: URL) throws -> NaverSignInResult {
        guard let expectedCallbackURL else {
            throw NaverSignInError.invalidCallbackURL
        }

        #if DEBUG
        print("[DEBUG] Expected Naver callback URL: \(expectedCallbackURL.absoluteString)")
        #endif

        guard callbackURL.scheme == expectedCallbackURL.scheme,
              callbackURL.host == expectedCallbackURL.host,
              normalizedPath(callbackURL) == normalizedPath(expectedCallbackURL) else {
            throw NaverSignInError.invalidCallbackURL
        }

        let queryItems = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)?.queryItems ?? []

        if let errorDescription = queryItems.first(where: { $0.name == "error_description" })?.value,
           !errorDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw NaverSignInError.authorizationFailed(errorDescription)
        }

        if let errorValue = queryItems.first(where: { $0.name == "error" })?.value,
           !errorValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw NaverSignInError.authorizationFailed(errorValue)
        }

        guard let rawResult = queryItems.first(where: { $0.name == "result" })?.value?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased(),
              !rawResult.isEmpty else {
            throw NaverSignInError.missingResult
        }

        let outcome: NaverSignInResult.Outcome
        switch rawResult {
        case "success":
            outcome = .success
        case "signup":
            outcome = .signup
        case "emptynickname":
            outcome = .emptyNickname
        case "cancel", "cancelled":
            throw NaverSignInError.cancelled
        default:
            throw NaverSignInError.authorizationFailed(rawResult)
        }

        return NaverSignInResult(outcome: outcome, callbackURL: callbackURL)
    }

    private func normalizedPath(_ url: URL) -> String {
        let path = url.path.isEmpty ? "/" : url.path
        return path.hasSuffix("/") && path.count > 1 ? String(path.dropLast()) : path
    }

    private func completeNaverSignIn(with result: Result<NaverSignInResult, Error>) {
        authenticationSession = nil
        expectedCallbackURL = nil

        switch result {
        case let .success(naverResult):
            continuation?.resume(returning: naverResult)
        case let .failure(error):
            continuation?.resume(throwing: error)
        }
        continuation = nil
    }

    @MainActor
    func handleOpenURL(_ url: URL) {
        guard continuation != nil else { return }
        handleNaverCallback(callbackURL: url, error: nil)
    }
 }

 extension NaverSignInManager: ASWebAuthenticationPresentationContextProviding {
     func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
         if #available(iOS 15.0, *) {
             return UIApplication.shared.connectedScenes
                 .compactMap { $0 as? UIWindowScene }
                 .flatMap { $0.windows }
                 .first { $0.isKeyWindow } ?? ASPresentationAnchor()
         }

         return UIApplication.shared.windows.first { $0.isKeyWindow } ?? ASPresentationAnchor()
     }
 }

 // MARK: - WKWebView fallback UI
 private final class WebAuthViewController: UIViewController, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {
     private let url: URL
     private let callbackScheme: String
     private let onIntercept: (URL) -> Void
     private let onCancel: () -> Void
     private var webView: WKWebView!

     init(url: URL, callbackScheme: String, onIntercept: @escaping (URL) -> Void, onCancel: @escaping () -> Void) {
         self.url = url
         self.callbackScheme = callbackScheme
         self.onIntercept = onIntercept
         self.onCancel = onCancel
         super.init(nibName: nil, bundle: nil)
     }

     required init?(coder: NSCoder) {
         // provide safe defaults for storyboard instantiation
         self.url = URL(string: "about:blank")!
         self.callbackScheme = ""
         self.onIntercept = { _ in }
         self.onCancel = { }
         super.init(coder: coder)
         #if DEBUG
         print("[DEBUG] WebAuthViewController init via coder")
         #endif
     }

     deinit {
         #if DEBUG
         print("[DEBUG] WebAuthViewController deinit")
         #endif
         // Clean up script handler
         webView?.configuration.userContentController.removeScriptMessageHandler(forName: "authHandler")
     }

     override func viewDidLoad() {
         super.viewDidLoad()
         view.backgroundColor = .systemBackground

         // Inject JS to notify native when location changes (pushState/replaceState/popstate and polling fallback)
         let js = """
         (function(){
             try {
                 var lastHref = location.href;
                 function notify(){
                     try { window.webkit.messageHandlers.authHandler.postMessage(location.href); } catch(e){}
                 }
                 var _push = history.pushState;
                 history.pushState = function(){ _push.apply(this, arguments); notify(); };
                 var _replace = history.replaceState;
                 history.replaceState = function(){ _replace.apply(this, arguments); notify(); };
                 window.addEventListener('popstate', function(){ notify(); });
                 setInterval(function(){ if(location.href !== lastHref){ lastHref = location.href; notify(); } }, 500);
             } catch(e) {}
         })();
         """

         let contentController = WKUserContentController()
         let userScript = WKUserScript(source: js, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
         contentController.addUserScript(userScript)
         contentController.add(self, name: "authHandler")

         let config = WKWebViewConfiguration()
         config.userContentController = contentController

         webView = WKWebView(frame: .zero, configuration: config)
         webView.navigationDelegate = self
         webView.uiDelegate = self
         webView.translatesAutoresizingMaskIntoConstraints = false
         view.addSubview(webView)

         NSLayoutConstraint.activate([
             webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
             webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
             webView.topAnchor.constraint(equalTo: view.topAnchor),
             webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
         ])

         navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelTapped))
         navigationItem.title = "로그인"

         webView.load(URLRequest(url: url))
     }

     @objc private func cancelTapped() {
         onCancel()
         dismiss(animated: true, completion: nil)
     }

     // Navigation delegate: intercept custom-scheme navigations
     func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
         if let u = navigationAction.request.url {
             #if DEBUG
             print("[DEBUG] WebAuthView URL navigation: \(u.absoluteString)")
             #endif
             if u.scheme?.lowercased() == callbackScheme.lowercased() {
                 onIntercept(u)
                 decisionHandler(.cancel)
                 dismiss(animated: true, completion: nil)
                 return
             }
         }
         decisionHandler(.allow)
     }

     // Handle target=_blank links by opening in same webview
     func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
         if navigationAction.targetFrame == nil {
             webView.load(navigationAction.request)
         }
         return nil
     }

     // WKScriptMessageHandler: receive JS notifications about location changes
     func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
         guard message.name == "authHandler" else { return }
         if let href = message.body as? String, let u = URL(string: href) {
             #if DEBUG
             print("[DEBUG] WebAuthView JS reported location: \(href)")
             #endif
             if u.scheme?.lowercased() == callbackScheme.lowercased() {
                 onIntercept(u)
                 dismiss(animated: true, completion: nil)
             }
         }
     }
}

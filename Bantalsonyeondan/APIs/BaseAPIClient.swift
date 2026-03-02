//
//  BaseAPIClient.swift
//  Bantalsonyeondan
//
//  Created by 이상현 on 2/19/25.
//

import Foundation

//MARK: BaseAPIClient
protocol BaseAPIClientProtocol {
    /// 네트워크 요청을 위한 기본 URL
    var baseURL: URL { get }
    /// 인증 토큰 등 공통 헤더에 필요한 값
    var bearerToken: String? { get }
    
    /// 실제 요청을 담당하는 메서드 (제네릭)
    /// - path: 경로
    /// - method: HTTP 메서드 (기본 GET)
    /// - query: 쿼리 파라미터
    /// - body: POST/PUT/DELETE 등에 필요한 JSON 바디
    func request<T: Decodable>(
        _ path: String,
        method: String,
        query: Encodable?,
        body: Encodable?,
        headers: [String: String]
    ) async throws -> T
}

extension BaseAPIClientProtocol {
    
    var baseURL: URL {
        APIConfig.baseURL
    }
    
    var bearerToken: String? {
        APIConfig.bearerToken
    }
    
    // 디폴트 값 부여: method = GET, query = nil, body = nil
    func request<T: Decodable>(
        _ path: String,
        method: String = "GET",
        query: Encodable? = nil,
        body: Encodable? = nil,
        headers: [String: String] = [:]
    ) async throws -> T {
        
        // 1) URLComponents 구성
        guard var urlComponents = URLComponents(
            url: baseURL.appendingPathComponent(path),
            resolvingAgainstBaseURL: false
        ) else {
            throw URLError(.badURL)
        }
        
        // 2) 쿼리 파라미터 추가
        if let query = query {
            let params = try query.asDictionary()
            urlComponents.queryItems = params.flatMap { key, value in
                if let values = value as? [Any] {
                    return values.map { URLQueryItem(name: key, value: String(describing: $0)) }
                }
                return [URLQueryItem(name: key, value: String(describing: value))]
            }
        }
        
        guard let finalURL = urlComponents.url else {
            throw URLError(.badURL)
        }
        
        // 2) URLRequest 생성
        var request = URLRequest(url: finalURL)
        request.httpMethod = method
        request.addValue("*/*", forHTTPHeaderField: "Accept")
        
        if !finalURL.absoluteString.contains("auth"), let bearerToken {
            request.addValue(bearerToken, forHTTPHeaderField: "Authorization")
        }
        
        // 4) 바디가 있다면 JSON 인코딩
        if let body = body {
            request.httpBody = try JSONEncoder().encode(body)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        for (key, value) in headers {
            let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedValue.isEmpty else { continue }
            request.setValue(trimmedValue, forHTTPHeaderField: key)
        }
#if DEBUG
        print("[DEBUG] Request\n\(request.debugDescription)")
#endif
        // 5) URLSession 요청
        let (data, httpResponse) = try await executeRequestWithAuthRetry(
            request,
            shouldRetryOnUnauthorized: true
        )
        
        guard httpResponse.statusCode == 200 else {
            let responseString = String(data: data, encoding: .utf8) ?? "No response body"
            let displayMessage = apiErrorMessage(statusCode: httpResponse.statusCode, data: data)
            let description = "\n[DEBUG] Error Status code: \(httpResponse.statusCode)\nResponse: \(responseString)"

            if httpResponse.statusCode == 401 {
                let unauthorizedError = URLError(
                    .userAuthenticationRequired,
                    userInfo: [NSLocalizedDescriptionKey: displayMessage]
                )
#if DEBUG
                print("[DEBUG] Response\nfrom \(path):\n\(description)\n")
#endif
                throw unauthorizedError
            }

            let error = URLError(.badServerResponse, userInfo: [NSLocalizedDescriptionKey: displayMessage])
#if DEBUG
            print("[DEBUG] Response\nfrom \(path):\n\(description)\n")
#endif
            throw error
        }
        
#if DEBUG
        if let responseString = String(data: data, encoding: .utf8) {
            print("[DEBUG] Response\nfrom \(path):\n\(responseString)\n")
        }
#endif
        // 6) JSON 디코딩
        return try JSONDecoder().decode(BaseResponse<T>.self, from: data).data
    }

    private func executeRequestWithAuthRetry(
        _ request: URLRequest,
        shouldRetryOnUnauthorized: Bool
    ) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard httpResponse.statusCode == 401,
              shouldRetryOnUnauthorized,
              request.value(forHTTPHeaderField: "Authorization") != nil else {
            return (data, httpResponse)
        }

        guard await refreshAccessTokenIfPossible() else {
            return (data, httpResponse)
        }

        var retryRequest = request
        if let bearerToken {
            retryRequest.setValue(bearerToken, forHTTPHeaderField: "Authorization")
        } else {
            retryRequest.setValue(nil, forHTTPHeaderField: "Authorization")
        }

#if DEBUG
        print("[DEBUG] Retry Request\n\(retryRequest.debugDescription)")
#endif
        return try await executeRequestWithAuthRetry(
            retryRequest,
            shouldRetryOnUnauthorized: false
        )
    }

    private func refreshAccessTokenIfPossible() async -> Bool {
        guard let session = AuthSessionStore.currentSession else {
            return false
        }

        let refreshToken = session.refreshToken?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !refreshToken.isEmpty else {
            expireSession()
            return false
        }

        do {
            let refreshedSession = try await AuthRefreshCoordinator.shared.refreshSessionIfNeeded {
                try await reissueSession(currentSession: session, refreshToken: refreshToken)
            }
            AuthSessionStore.currentSession = refreshedSession
            return true
        } catch {
#if DEBUG
            print("[DEBUG] Refresh failed: \(error.localizedDescription)")
#endif
            expireSession()
            return false
        }
    }

    private func reissueSession(
        currentSession: UserSession,
        refreshToken: String
    ) async throws -> UserSession {
        var request = URLRequest(url: APIConfig.reissueURL)
        request.httpMethod = "POST"
        request.setValue("*/*", forHTTPHeaderField: "Accept")
        request.setValue("refresh-token=\(refreshToken)", forHTTPHeaderField: "Cookie")

#if DEBUG
        print("[DEBUG] Refresh Request\n\(request.debugDescription)")
#endif

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard httpResponse.statusCode == 200 else {
            let responseString = String(data: data, encoding: .utf8) ?? "No response body"
            throw URLError(
                .userAuthenticationRequired,
                userInfo: [NSLocalizedDescriptionKey: responseString]
            )
        }

        let decodedAuthResponse = try? JSONDecoder()
            .decode(BaseResponse<AuthResponse>.self, from: data)
            .data

        let headerAccessToken = httpResponse
            .headerValue(for: "access-token")?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let bodyAccessToken = decodedAuthResponse?.accessToken
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let accessToken = sanitizeToken(bodyAccessToken ?? headerAccessToken ?? "")

        guard !accessToken.isEmpty else {
            throw URLError(
                .cannotParseResponse,
                userInfo: [NSLocalizedDescriptionKey: "Missing access token from reissue response."]
            )
        }

        let bodyRefreshToken = decodedAuthResponse?.refreshToken?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let cookieRefreshToken = extractRefreshTokenCookie(
            from: httpResponse,
            requestURL: request.url
        )
        let nextRefreshToken = bodyRefreshToken
            ?? cookieRefreshToken
            ?? refreshToken

        return UserSession(
            accessToken: accessToken,
            refreshToken: nextRefreshToken,
            memberId: decodedAuthResponse?.memberId ?? currentSession.memberId,
            role: decodedAuthResponse?.role ?? currentSession.role,
            isNewUser: decodedAuthResponse?.isNewUser ?? currentSession.isNewUser
        )
    }

    private func extractRefreshTokenCookie(
        from response: HTTPURLResponse,
        requestURL: URL?
    ) -> String? {
        guard let requestURL else { return nil }

        var headerFields: [String: String] = [:]
        for (key, value) in response.allHeaderFields {
            guard let key = key as? String else { continue }
            headerFields[key] = String(describing: value)
        }

        let cookies = HTTPCookie.cookies(
            withResponseHeaderFields: headerFields,
            for: requestURL
        )

        return cookies
            .first(where: { $0.name.caseInsensitiveCompare("refresh-token") == .orderedSame })?
            .value
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func sanitizeToken(_ token: String) -> String {
        token
            .replacingOccurrences(of: "Bearer ", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func expireSession() {
        AuthSessionStore.clearAll()
        Task { @MainActor in
            NotificationCenter.default.post(name: .authSessionExpired, object: nil)
        }
    }

    private func apiErrorMessage(statusCode: Int, data: Data) -> String {
        if let serverMessage = decodeServerMessage(from: data), !serverMessage.isEmpty {
            return serverMessage
        }
        switch statusCode {
        case 400:
            return "요청값이 올바르지 않아요."
        case 401:
            return "로그인이 만료되었어요. 다시 로그인해주세요."
        case 403:
            return "접근 권한이 없어요."
        case 404:
            return "요청한 정보를 찾을 수 없어요."
        case 500...599:
            return "서버 오류가 발생했어요. 잠시 후 다시 시도해주세요."
        default:
            return "요청 처리 중 오류가 발생했어요. 잠시 후 다시 시도해주세요."
        }
    }

    private func decodeServerMessage(from data: Data) -> String? {
        struct ErrorEnvelope: Decodable {
            let message: String?
            let code: String?
        }
        guard let envelope = try? JSONDecoder().decode(ErrorEnvelope.self, from: data) else {
            return nil
        }
        return envelope.message?.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

extension URLRequest {
    var debugDescription: String {
        var desc = "1. HTTP Method: \(self.httpMethod ?? "N/A")\n\n"
        desc += "2. URL: \(self.url?.absoluteString ?? "N/A")\n\n"
        desc += "3. Headers: \(self.allHTTPHeaderFields ?? [:])\n\n"
        if let httpBody = self.httpBody, let bodyString = String(data: httpBody, encoding: .utf8) {
            desc += "4. HTTP Body: \(bodyString)\n"
        } else {
            desc += "4. HTTP Body: None\n"
        }
        return desc
    }
}

extension Encodable {
    /// Encodable → [String: Any] 변환
    func asDictionary() throws -> [String: Any] {
        let data = try JSONEncoder().encode(self)
        let jsonObj = try JSONSerialization.jsonObject(with: data, options: [])
        guard let dict = jsonObj as? [String: Any] else {
            return [:]
        }
        return dict
    }
}

extension HTTPURLResponse {
    func headerValue(for name: String) -> String? {
        for (key, value) in allHeaderFields {
            guard let keyString = key as? String else { continue }
            if keyString.caseInsensitiveCompare(name) == .orderedSame {
                return String(describing: value)
            }
        }
        return nil
    }
}

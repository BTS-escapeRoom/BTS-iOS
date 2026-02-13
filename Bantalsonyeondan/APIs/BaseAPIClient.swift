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
    var bearerToken: String { get }
    
    /// 실제 요청을 담당하는 메서드 (제네릭)
    /// - path: 경로
    /// - method: HTTP 메서드 (기본 GET)
    /// - query: 쿼리 파라미터
    /// - body: POST/PUT/DELETE 등에 필요한 JSON 바디
    func request<T: Decodable>(
        _ path: String,
        method: String,
        query: Encodable?,
        body: Encodable?
    ) async throws -> T
}

extension BaseAPIClientProtocol {
    
    var baseURL: URL {
        APIConfig.baseURL
    }
    
    var bearerToken: String {
        APIConfig.bearerToken
    }
    
    // 디폴트 값 부여: method = GET, query = nil, body = nil
    func request<T: Decodable>(
        _ path: String,
        method: String = "GET",
        query: Encodable? = nil,
        body: Encodable? = nil
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
        
        if !finalURL.absoluteString.contains("auth") {
            request.addValue(bearerToken, forHTTPHeaderField: "Authorization")
        }
        
        // 4) 바디가 있다면 JSON 인코딩
        if let body = body {
            request.httpBody = try JSONEncoder().encode(body)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
#if DEBUG
        print("[DEBUG] Request\n\(request.debugDescription)")
#endif
        // 5) URLSession 요청
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        guard httpResponse.statusCode == 200 else {
            let responseString = String(data: data, encoding: .utf8) ?? "No response body"
            let description = "\n[DEBUG] Error Status code: \(httpResponse.statusCode)\nResponse: \(responseString)"
            let error = URLError(.badServerResponse, userInfo: [NSLocalizedDescriptionKey: description])
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

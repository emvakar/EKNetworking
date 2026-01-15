//
//  MockURLProtocol.swift
//  EKNetworkingTests
//
//  Created by Egor Solovev on 15.01.2026.
//  Copyright © 2026 TAXCOM. All rights reserved.
//

import Foundation

/// Simple mock for intercepting URLSession requests in tests
/// This replaces real network calls with predefined responses
final class MockURLProtocol: URLProtocol {
    
    // MARK: - Mock Response Storage
    
    /// Stores mock responses by URL pattern
    /// Key: URL string (can be partial match)
    /// Value: Mock response data
    static var mockResponses: [String: MockResponse] = [:]
    
    /// Stores all requests that were made (useful for verification)
    static var requestHistory: [URLRequest] = []
    
    /// Mock response data
    struct MockResponse {
        let data: Data
        let statusCode: Int
        let headers: [String: String]?
        
        init(data: Data, statusCode: Int, headers: [String: String]? = nil) {
            self.data = data
            self.statusCode = statusCode
            self.headers = headers
        }
        
        /// Convenience for JSON responses
        static func json(_ jsonObject: Any, statusCode: Int = 200) -> MockResponse {
            let data = (try? JSONSerialization.data(withJSONObject: jsonObject)) ?? Data()
            return MockResponse(data: data, statusCode: statusCode, headers: ["Content-Type": "application/json"])
        }
    }
    
    // MARK: - Setup/Teardown
    
    static func startMocking() {
        URLProtocol.registerClass(MockURLProtocol.self)
    }
    
    static func stopMocking() {
        URLProtocol.unregisterClass(MockURLProtocol.self)
        mockResponses.removeAll()
        requestHistory.removeAll()
    }
    
    // MARK: - URLProtocol Implementation
    
    override class func canInit(with request: URLRequest) -> Bool {
        // Intercept all requests
        return true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        // Record this request
        MockURLProtocol.requestHistory.append(request)
        
        // Find matching mock response
        guard let url = request.url?.absoluteString,
              let mockResponse = Self.findMockResponse(for: url) else {
            // No mock found - fail with error
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }
        
        // Create HTTP response
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: mockResponse.statusCode,
            httpVersion: "HTTP/1.1",
            headerFields: mockResponse.headers
        )!
        
        // Send response to client
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: mockResponse.data)
        client?.urlProtocolDidFinishLoading(self)
    }
    
    override func stopLoading() {
        // Required by protocol, but we don't need to do anything
    }
    
    // MARK: - Helper Methods
    
    /// Finds a mock response that matches the URL
    /// Supports partial matching (e.g., "/posts" matches "https://api.com/posts")
    private static func findMockResponse(for url: String) -> MockResponse? {
        // Try exact match first
        if let response = mockResponses[url] {
            return response
        }
        
        // Try partial match (useful for base URLs)
        for (pattern, response) in mockResponses {
            if url.contains(pattern) {
                return response
            }
        }
        
        return nil
    }
}

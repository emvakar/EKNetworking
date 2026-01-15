//
//  EKNetworkingUnitTests.swift
//  EKNetworkingTests
//
//  Created by Egor Solovev on 15.01.2026.
//  Copyright © 2026 TAXCOM. All rights reserved.
//

import XCTest
import Foundation
@testable import EKNetworking

final class EKNetworkingUnitTests: XCTestCase {
    
    var wrapper: EKNetworkRequestWrapper!
    
    override func setUp() {
        super.setUp()
        
        MockURLProtocol.startMocking()
        
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        let mockSession = URLSession(configuration: configuration)
        
        wrapper = EKNetworkRequestWrapper(logEnable: false, session: mockSession)
    }
    
    override func tearDown() {
        MockURLProtocol.stopMocking()
        wrapper = nil
        super.tearDown()
    }
    
    // MARK: - Test 1: Simple GET Request (Success)
    
    func testGETRequestSuccess() {
        let mockData: [String: Any] = ["id": 1, "title": "Test Post", "userId": 1]
        MockURLProtocol.mockResponses["/posts/1"] = .json(mockData, statusCode: 200)
        
        let expectation = XCTestExpectation(description: "GET request completes")
        let request = MockGETRequest(path: "/posts/1")
        
        wrapper.runRequest(
            request: request,
            baseURL: "https://api.example.com",
            authToken: nil,
            progressResult: nil,
            timeoutInSeconds: 10
        ) { statusCode, response, error in
            XCTAssertEqual(statusCode, 200, "Should return 200 OK")
            XCTAssertNotNil(response, "Response should not be nil")
            XCTAssertNil(error, "Error should be nil on success")
            
            if let responseData = response?.data,
               let json = try? JSONSerialization.jsonObject(with: responseData) as? [String: Any] {
                XCTAssertEqual(json["id"] as? Int, 1)
                XCTAssertEqual(json["title"] as? String, "Test Post")
            } else {
                XCTFail("Could not parse response JSON")
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Test 2: POST Request with JSON Body
    
    func testPOSTRequestWithBody() {
        let mockResponse: [String: Any] = ["id": 101, "title": "Created Post", "userId": 1]
        MockURLProtocol.mockResponses["/posts"] = .json(mockResponse, statusCode: 201)
        
        let expectation = XCTestExpectation(description: "POST request completes")
        let request = MockPOSTRequest(
            path: "/posts",
            body: ["title": "New Post", "userId": 1]
        )
        
        wrapper.runRequest(
            request: request,
            baseURL: "https://api.example.com",
            authToken: nil,
            progressResult: nil,
            timeoutInSeconds: 10
        ) { statusCode, response, error in
            XCTAssertEqual(statusCode, 201, "Should return 201 Created")
            XCTAssertNotNil(response, "Response should not be nil")
            XCTAssertNil(error, "Error should be nil on success")
            
            if let lastRequest = MockURLProtocol.requestHistory.last,
               let bodyData = lastRequest.httpBody,
               let bodyJson = try? JSONSerialization.jsonObject(with: bodyData) as? [String: Any] {
                XCTAssertEqual(bodyJson["title"] as? String, "New Post")
                XCTAssertEqual(bodyJson["userId"] as? Int, 1)
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Test 3: Error Handling (404 Not Found)
    
    func testHandles404Error() {
        let errorData: [String: Any] = ["error": "Not found"]
        MockURLProtocol.mockResponses["/posts/999"] = .json(errorData, statusCode: 404)
        
        let expectation = XCTestExpectation(description: "404 error handled")
        let request = MockGETRequest(path: "/posts/999")
        
        wrapper.runRequest(
            request: request,
            baseURL: "https://api.example.com",
            authToken: nil,
            progressResult: nil,
            timeoutInSeconds: 10
        ) { statusCode, response, error in
            XCTAssertEqual(statusCode, 404, "Should return 404")
            XCTAssertNil(response, "Response should be nil on error")
            XCTAssertNotNil(error, "Error should not be nil")
            
            XCTAssertEqual(error?.statusCode, 404)
            XCTAssertEqual(error?.type, .notFound)
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Test 4: Authorization Header (Bearer Token)
    
    func testBearerTokenHeader() {
        let mockData: [String: Any] = ["data": "secret"]
        MockURLProtocol.mockResponses["/protected"] = .json(mockData, statusCode: 200)
        
        let expectation = XCTestExpectation(description: "Auth header sent")
        let request = MockAuthGETRequest(path: "/protected")
        
        wrapper.runRequest(
            request: request,
            baseURL: "https://api.example.com",
            authToken: { "test-token-123" },
            progressResult: nil,
            timeoutInSeconds: 10
        ) { statusCode, response, error in
            if let lastRequest = MockURLProtocol.requestHistory.last {
                let authHeader = lastRequest.value(forHTTPHeaderField: "Authorization")
                XCTAssertEqual(authHeader, "Bearer test-token-123", "Should include Bearer token")
            } else {
                XCTFail("No request was captured")
            }
            
            XCTAssertEqual(statusCode, 200)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Test 5: URL Parameters Encoding
    
    func testURLParametersEncoding() {
        let mockData: [[String: Any]] = [["id": 1]]
        MockURLProtocol.mockResponses["/search"] = .json(mockData, statusCode: 200)
        
        let expectation = XCTestExpectation(description: "URL params encoded")
        let request = MockParamsGETRequest(
            path: "/search",
            params: ["userId": 1, "limit": 10]
        )
        
        wrapper.runRequest(
            request: request,
            baseURL: "https://api.example.com",
            authToken: nil,
            progressResult: nil,
            timeoutInSeconds: 10
        ) { statusCode, response, error in
            if let lastRequest = MockURLProtocol.requestHistory.last,
               let url = lastRequest.url?.absoluteString {
                XCTAssertTrue(url.contains("userId=1"), "URL should contain userId parameter")
                XCTAssertTrue(url.contains("limit=10"), "URL should contain limit parameter")
            } else {
                XCTFail("No request was captured")
            }
            
            XCTAssertEqual(statusCode, 200)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Test 6: Main Thread Completion
    
    func testCompletionOnMainThread() {
        let mockData: [[String: Any]] = []
        MockURLProtocol.mockResponses["/posts"] = .json(mockData, statusCode: 200)
        
        let expectation = XCTestExpectation(description: "Completion on main thread")
        let request = MockGETRequest(path: "/posts")
        
        wrapper.runRequest(
            request: request,
            baseURL: "https://api.example.com",
            authToken: nil,
            progressResult: nil,
            timeoutInSeconds: 10
        ) { statusCode, response, error in
            // CRITICAL: Verify we're on main thread
            XCTAssertTrue(Thread.isMainThread, "Completion must run on main thread")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
}

// MARK: - Mock Request Types (for unit tests)

private struct MockGETRequest: EKNetworkRequest {
    let path: String
    var method: EKRequestHTTPMethod { .get }
    var urlParameters: [String: Any]? { nil }
    var bodyParameters: [String: Any]? { nil }
    var headers: [String: String]? { nil }
    var array: [Any]? { nil }
    var multipartBody: [EKMultipartFormData]? { nil }
    var authHeader: AuthHeader { .bearerToken }
    
    // Manual Codable conformance (not used in tests)
    init(from decoder: Decoder) throws { fatalError("Not implemented") }
    func encode(to encoder: Encoder) throws { }
    
    init(path: String) {
        self.path = path
    }
}

private struct MockPOSTRequest: EKNetworkRequest {
    let path: String
    let body: [String: Any]
    
    var method: EKRequestHTTPMethod { .post }
    var urlParameters: [String: Any]? { nil }
    var bodyParameters: [String: Any]? { body }
    var headers: [String: String]? { nil }
    var array: [Any]? { nil }
    var multipartBody: [EKMultipartFormData]? { nil }
    var authHeader: AuthHeader { .bearerToken }
    
    // Manual Codable conformance
    init(from decoder: Decoder) throws { fatalError("Not implemented") }
    func encode(to encoder: Encoder) throws { }
    
    init(path: String, body: [String: Any]) {
        self.path = path
        self.body = body
    }
}

private struct MockAuthGETRequest: EKNetworkRequest {
    let path: String
    var method: EKRequestHTTPMethod { .get }
    var urlParameters: [String: Any]? { nil }
    var bodyParameters: [String: Any]? { nil }
    var headers: [String: String]? { nil }
    var array: [Any]? { nil }
    var multipartBody: [EKMultipartFormData]? { nil }
    var authHeader: AuthHeader { .bearerToken }
    
    init(from decoder: Decoder) throws { fatalError("Not implemented") }
    func encode(to encoder: Encoder) throws { }
    
    init(path: String) {
        self.path = path
    }
}

private struct MockParamsGETRequest: EKNetworkRequest {
    let path: String
    let params: [String: Any]
    
    var method: EKRequestHTTPMethod { .get }
    var urlParameters: [String: Any]? { params }
    var bodyParameters: [String: Any]? { nil }
    var headers: [String: String]? { nil }
    var array: [Any]? { nil }
    var multipartBody: [EKMultipartFormData]? { nil }
    var authHeader: AuthHeader { .bearerToken }
    
    init(from decoder: Decoder) throws { fatalError("Not implemented") }
    func encode(to encoder: Encoder) throws { }
    
    init(path: String, params: [String: Any]) {
        self.path = path
        self.params = params
    }
}

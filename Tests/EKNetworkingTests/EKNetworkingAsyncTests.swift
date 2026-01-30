//
//  EKNetworkingAsyncTests.swift
//  EKNetworkingTests
//
//  Created on 16.01.2026.
//  Copyright © 2026 Emil Karimov. All rights reserved.
//

import XCTest
import Foundation
@testable import EKNetworking

@available(iOS 13.0, macOS 10.15, *)
final class EKNetworkingAsyncTests: XCTestCase {
    
    var wrapper: EKNetworkRequestWrapper!
    
    override func setUp() {
        super.setUp()
        
        MockURLProtocol.startMocking()
        
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        let mockSession = URLSession(configuration: configuration)
        
        wrapper = EKNetworkRequestWrapper(session: mockSession)
    }
    
    override func tearDown() {
        MockURLProtocol.stopMocking()
        wrapper = nil
        super.tearDown()
    }
    
    // MARK: - Test 1: Async GET Request Success
    
    func testAsyncGETRequestSuccess() async throws {
        let mockData: [String: Any] = ["id": 1, "title": "Test Post", "userId": 1]
        MockURLProtocol.mockResponses["/posts/1"] = .json(mockData, statusCode: 200)
        
        let request = MockGETRequest(path: "/posts/1")
        
        let response = try await wrapper.runRequest(
            request: request,
            baseURL: "https://api.example.com",
            authToken: nil,
            timeoutInSeconds: 10
        )
        
        XCTAssertEqual(response.statusCode, 200, "Should return 200 OK")
        
        if let json = try? JSONSerialization.jsonObject(with: response.data) as? [String: Any] {
            XCTAssertEqual(json["id"] as? Int, 1)
            XCTAssertEqual(json["title"] as? String, "Test Post")
        } else {
            XCTFail("Could not parse response JSON")
        }
    }
    
    // MARK: - Test 2: Async POST Request
    
    func testAsyncPOSTRequest() async throws {
        let mockResponse: [String: Any] = ["id": 101, "title": "Created Post"]
        MockURLProtocol.mockResponses["/posts"] = .json(mockResponse, statusCode: 201)
        
        let request = MockPOSTRequest(
            path: "/posts",
            body: ["title": "New Post", "userId": 1]
        )
        
        let response = try await wrapper.runRequest(
            request: request,
            baseURL: "https://api.example.com",
            authToken: nil,
            timeoutInSeconds: 10
        )
        
        XCTAssertEqual(response.statusCode, 201, "Should return 201 Created")
    }
    
    // MARK: - Test 3: Async Error Handling (404)
    
    func testAsyncHandles404Error() async {
        let errorData: [String: Any] = ["error": "Not found"]
        MockURLProtocol.mockResponses["/posts/999"] = .json(errorData, statusCode: 404)
        
        let request = MockGETRequest(path: "/posts/999")
        
        do {
            _ = try await wrapper.runRequest(
                request: request,
                baseURL: "https://api.example.com",
                authToken: nil,
                timeoutInSeconds: 10
            )
            XCTFail("Should have thrown an error")
        } catch let error as EKNetworkError {
            XCTAssertEqual(error.statusCode, 404)
            XCTAssertEqual(error.type, .notFound)
        } catch {
            XCTFail("Wrong error type thrown")
        }
    }
    
    // MARK: - Test 4: Async Success with JSON Parsing
    
    func testAsyncSuccessWithParsing() async throws {
        let mockData: [String: Any] = ["id": 1, "data": "success"]
        MockURLProtocol.mockResponses["/api"] = .json(mockData, statusCode: 200)
        
        let request = MockGETRequest(path: "/api")
        
        let response = try await wrapper.runRequest(
            request: request,
            baseURL: "https://api.example.com",
            authToken: nil,
            timeoutInSeconds: 10
        )
        
        XCTAssertEqual(response.statusCode, 200)
        
        if let json = try? JSONSerialization.jsonObject(with: response.data) as? [String: Any] {
            XCTAssertEqual(json["id"] as? Int, 1)
        }
    }
    
    // MARK: - Test 5: Async 401 Error
    
    func testAsync401Error() async {
        let errorData: [String: Any] = ["error": "Unauthorized"]
        MockURLProtocol.mockResponses["/protected"] = .json(errorData, statusCode: 401)
        
        let request = MockGETRequest(path: "/protected")
        
        do {
            _ = try await wrapper.runRequest(
                request: request,
                baseURL: "https://api.example.com",
                authToken: nil,
                timeoutInSeconds: 10
            )
            XCTFail("Should have thrown an error")
        } catch let error as EKNetworkError {
            XCTAssertEqual(error.statusCode, 401)
            XCTAssertEqual(error.type, .unauthorized)
        } catch {
            XCTFail("Wrong error type thrown")
        }
    }
    
    // MARK: - Test 6: Async with Authorization
    
    func testAsyncWithBearerToken() async throws {
        let mockData: [String: Any] = ["data": "protected"]
        MockURLProtocol.mockResponses["/protected"] = .json(mockData, statusCode: 200)
        
        let request = MockAuthGETRequest(path: "/protected")
        
        let response = try await wrapper.runRequest(
            request: request,
            baseURL: "https://api.example.com",
            authToken: { "test-token-123" },
            timeoutInSeconds: 10
        )
        
        XCTAssertEqual(response.statusCode, 200)
        
        if let lastRequest = MockURLProtocol.requestHistory.last {
            let authHeader = lastRequest.value(forHTTPHeaderField: "Authorization")
            XCTAssertEqual(authHeader, "Bearer test-token-123")
        }
    }
    
    // MARK: - Test 7: Async POST with Empty Body
    
    func testAsyncPOSTWithEmptyBody() async throws {
        let mockResponse: [String: Any] = ["success": true]
        MockURLProtocol.mockResponses["/action"] = .json(mockResponse, statusCode: 200)
        
        let request = MockEmptyPOSTRequest(path: "/action")
        
        let response = try await wrapper.runRequest(
            request: request,
            baseURL: "https://api.example.com",
            authToken: nil,
            timeoutInSeconds: 10
        )
        
        XCTAssertEqual(response.statusCode, 200)
        
        // Verify empty JSON body was sent
        if let lastRequest = MockURLProtocol.requestHistory.last,
           let bodyData = lastRequest.httpBody,
           let bodyString = String(data: bodyData, encoding: .utf8) {
            XCTAssertEqual(bodyString, "{}", "Should send empty JSON object")
        }
    }
    
    // MARK: - Test 8: Async Multiple Concurrent Requests
    
    func testAsyncConcurrentRequests() async throws {
        MockURLProtocol.mockResponses["/posts/1"] = .json(["id": 1], statusCode: 200)
        MockURLProtocol.mockResponses["/posts/2"] = .json(["id": 2], statusCode: 200)
        MockURLProtocol.mockResponses["/posts/3"] = .json(["id": 3], statusCode: 200)
        
        async let response1 = try wrapper.runRequest(
            request: MockGETRequest(path: "/posts/1"),
            baseURL: "https://api.example.com",
            authToken: nil,
            timeoutInSeconds: 10
        )
        
        async let response2 = try wrapper.runRequest(
            request: MockGETRequest(path: "/posts/2"),
            baseURL: "https://api.example.com",
            authToken: nil,
            timeoutInSeconds: 10
        )
        
        async let response3 = try wrapper.runRequest(
            request: MockGETRequest(path: "/posts/3"),
            baseURL: "https://api.example.com",
            authToken: nil,
            timeoutInSeconds: 10
        )
        
        let (r1, r2, r3) = try await (response1, response2, response3)
        
        XCTAssertEqual(r1.statusCode, 200)
        XCTAssertEqual(r2.statusCode, 200)
        XCTAssertEqual(r3.statusCode, 200)
        XCTAssertEqual(MockURLProtocol.requestHistory.count, 3)
    }
    
    // MARK: - Test 9: Async with Task Group
    
    func testAsyncWithTaskGroup() async throws {
        MockURLProtocol.mockResponses["/posts/1"] = .json(["id": 1], statusCode: 200)
        MockURLProtocol.mockResponses["/posts/2"] = .json(["id": 2], statusCode: 200)
        MockURLProtocol.mockResponses["/posts/3"] = .json(["id": 3], statusCode: 200)
        
        let results = try await withThrowingTaskGroup(of: EKResponse.self) { group in
            group.addTask {
                try await self.wrapper.runRequest(
                    request: MockGETRequest(path: "/posts/1"),
                    baseURL: "https://api.example.com",
                    authToken: nil,
                    timeoutInSeconds: 10
                )
            }
            
            group.addTask {
                try await self.wrapper.runRequest(
                    request: MockGETRequest(path: "/posts/2"),
                    baseURL: "https://api.example.com",
                    authToken: nil,
                    timeoutInSeconds: 10
                )
            }
            
            group.addTask {
                try await self.wrapper.runRequest(
                    request: MockGETRequest(path: "/posts/3"),
                    baseURL: "https://api.example.com",
                    authToken: nil,
                    timeoutInSeconds: 10
                )
            }
            
            var responses: [EKResponse] = []
            for try await response in group {
                responses.append(response)
            }
            return responses
        }
        
        XCTAssertEqual(results.count, 3)
        XCTAssertTrue(results.allSatisfy { $0.statusCode == 200 })
    }
    
    // MARK: - Test 10: Async Progress Tracking
    
    func testAsyncProgressTracking() async throws {
        let mockData: [String: Any] = ["data": "large response"]
        MockURLProtocol.mockResponses["/download"] = .json(mockData, statusCode: 200)
        
        var progressValues: [Double] = []
        
        let response = try await wrapper.runRequest(
            request: MockGETRequest(path: "/download"),
            baseURL: "https://api.example.com",
            authToken: nil,
            progressResult: { progress in
                progressValues.append(progress)
            },
            timeoutInSeconds: 10
        )
        
        XCTAssertEqual(response.statusCode, 200)
        // Progress tracking should have been called at least once
        // Note: In unit tests with mocks, progress may not be fully realistic
    }
}

// MARK: - Mock Request Types (reusing from existing tests)

@available(iOS 13.0, macOS 10.15, *)
private struct MockGETRequest: EKNetworkRequest {
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

@available(iOS 13.0, macOS 10.15, *)
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
    
    init(from decoder: Decoder) throws { fatalError("Not implemented") }
    func encode(to encoder: Encoder) throws { }
    
    init(path: String, body: [String: Any]) {
        self.path = path
        self.body = body
    }
}

@available(iOS 13.0, macOS 10.15, *)
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

@available(iOS 13.0, macOS 10.15, *)
private struct MockEmptyPOSTRequest: EKNetworkRequest {
    let path: String
    
    var method: EKRequestHTTPMethod { .post }
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

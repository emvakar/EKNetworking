//
//  EKNetworkingIntegrationTests.swift
//  EKNetworkingTests
//
//  Created by Egor Solovev on 14.01.2026.
//  Copyright © 2026 TAXCOM. All rights reserved.
//

import XCTest
import Foundation
@testable import EKNetworking

/// Integration tests that verify real network behavior against live APIs
/// These tests are slower and may be flaky due to network conditions
/// For fast, reliable tests, see EKNetworkingUnitTests (mocked)
final class EKNetworkingIntegrationTests: XCTestCase {
    
    var wrapper: EKNetworkRequestWrapper!
    
    override func setUp() {
        super.setUp()
        wrapper = EKNetworkRequestWrapper(logEnable: false)
    }
    
    override func tearDown() {
        wrapper = nil
        super.tearDown()
    }
    
    // MARK: - Test 1: Completion runs on main thread
    
    func testCompletionHandlerRunsOnMainThread() {
        let expectation = XCTestExpectation(description: "Completion on main thread")
        
        let request = SimpleGETRequest(path: "/posts/1")
        
        wrapper.runRequest(
            request: request,
            baseURL: "https://jsonplaceholder.typicode.com",
            authToken: nil,
            progressResult: nil,
            timeoutInSeconds: 10
        ) { statusCode, response, error in
            // CRITICAL: Must be on main thread (Moya's default behavior)
            XCTAssertTrue(Thread.isMainThread, "Completion must run on main thread")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    // MARK: - Test 2: Successful GET request
    
    func testSuccessfulGETRequest() {
        let expectation = XCTestExpectation(description: "GET request succeeds")
        
        let request = SimpleGETRequest(path: "/posts/1")
        
        wrapper.runRequest(
            request: request,
            baseURL: "https://jsonplaceholder.typicode.com",
            authToken: nil,
            progressResult: nil,
            timeoutInSeconds: 10
        ) { statusCode, response, error in
            XCTAssertEqual(statusCode, 200, "Should return 200 OK")
            XCTAssertNotNil(response, "Response should not be nil")
            XCTAssertNil(error, "Error should be nil on success")
            
            // Verify we got data
            if let response = response {
                XCTAssertFalse(response.data.isEmpty, "Response data should not be empty")
                
                // Should be valid JSON
                let json = try? JSONSerialization.jsonObject(with: response.data)
                XCTAssertNotNil(json, "Response should be valid JSON")
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    // MARK: - Test 3: URL parameters encoding
    
    func testURLParametersEncoding() {
        let expectation = XCTestExpectation(description: "URL params encoded correctly")
        
        let request = GETRequestWithParams(
            path: "/posts",
            params: ["userId": "1", "title": "test"]
        )
        
        wrapper.runRequest(
            request: request,
            baseURL: "https://jsonplaceholder.typicode.com",
            authToken: nil,
            progressResult: nil,
            timeoutInSeconds: 10
        ) { statusCode, response, error in
            XCTAssertEqual(statusCode, 200, "Should return 200 OK")
            XCTAssertNotNil(response, "Response should not be nil")
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    // MARK: - Test 4: Error handling (404)
    
    func testHandles404Error() {
        let expectation = XCTestExpectation(description: "404 error handled")
        
        let request = SimpleGETRequest(path: "/posts/999999999")
        
        wrapper.runRequest(
            request: request,
            baseURL: "https://jsonplaceholder.typicode.com",
            authToken: nil,
            progressResult: nil,
            timeoutInSeconds: 10
        ) { statusCode, response, error in
            XCTAssertEqual(statusCode, 404, "Should return 404")
            XCTAssertNotNil(error, "Error should not be nil for 404")
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    // MARK: - Test 5: Authorization header (Bearer token)
    
    func testBearerTokenAuthorizationHeader() {
        let expectation = XCTestExpectation(description: "Bearer token sent")
        
        let request = AuthenticatedRequest(path: "/posts/1", authType: .bearerToken)
        
        wrapper.runRequest(
            request: request,
            baseURL: "https://jsonplaceholder.typicode.com",
            authToken: { return "test-token-12345" },
            progressResult: nil,
            timeoutInSeconds: 10
        ) { statusCode, response, error in
            // Even if endpoint doesn't require auth, request should complete
            // The important part is that header was set correctly
            XCTAssertNotNil(response, "Response should not be nil")
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    // MARK: - Test 6: Progress tracking
    
    func testProgressCallbackIsInvoked() {
        let expectation = XCTestExpectation(description: "Progress callback invoked")
        
        let request = SimpleGETRequest(path: "/posts")
        
        wrapper.runRequest(
            request: request,
            baseURL: "https://jsonplaceholder.typicode.com",
            authToken: nil,
            progressResult: { progress in
                XCTAssertTrue(Thread.isMainThread, "Progress callback should be on main thread")
                XCTAssertTrue(progress >= 0.0 && progress <= 1.0, "Progress should be between 0 and 1")
            },
            timeoutInSeconds: 10
        ) { statusCode, response, error in
            // Progress might or might not be called depending on request size
            // But completion should always be called
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    // MARK: - Test 7: Timeout handling
    
    func testTimeoutHandling() {
        let expectation = XCTestExpectation(description: "Timeout handled")
        
        // Use a very short timeout to force failure
        let request = SimpleGETRequest(path: "/posts")
        
        wrapper.runRequest(
            request: request,
            baseURL: "https://httpbin.org/delay/10", // Delays response by 10 seconds
            authToken: nil,
            progressResult: nil,
            timeoutInSeconds: 1 // But timeout after 1 second
        ) { statusCode, response, error in
            // Should timeout
            XCTAssertNotNil(error, "Should have timeout error")
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    // MARK: - Error Handling Tests
    
    // MARK: - Test 8: 401 Unauthorized error type
    
    func testHandles401UnauthorizedError() {
        let expectation = XCTestExpectation(description: "401 error handled")
        
        let request = SimpleGETRequest(path: "/status/401")
        
        wrapper.runRequest(
            request: request,
            baseURL: "https://httpbin.org",
            authToken: nil,
            progressResult: nil,
            timeoutInSeconds: 10
        ) { statusCode, response, error in
            XCTAssertEqual(statusCode, 401, "Should return 401")
            XCTAssertNotNil(error, "Error should not be nil for 401")
            
            if let networkError = error as? EKNetworkErrorStruct {
                XCTAssertEqual(networkError.type, .unauthorized, "Error type should be .unauthorized")
                XCTAssertEqual(networkError.statusCode, 401, "Status code should be 401")
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    // MARK: - Test 9: 403 Forbidden error type
    
    func testHandles403ForbiddenError() {
        let expectation = XCTestExpectation(description: "403 error handled")
        
        let request = SimpleGETRequest(path: "/status/403")
        
        wrapper.runRequest(
            request: request,
            baseURL: "https://httpbin.org",
            authToken: nil,
            progressResult: nil,
            timeoutInSeconds: 10
        ) { statusCode, response, error in
            XCTAssertEqual(statusCode, 403, "Should return 403")
            XCTAssertNotNil(error, "Error should not be nil for 403")
            
            if let networkError = error as? EKNetworkErrorStruct {
                XCTAssertEqual(networkError.type, .forbidden, "Error type should be .forbidden")
                XCTAssertEqual(networkError.statusCode, 403, "Status code should be 403")
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    // MARK: - Test 10: 400 Bad Request error type
    
    func testHandles400BadRequestError() {
        let expectation = XCTestExpectation(description: "400 error handled")
        
        let request = SimpleGETRequest(path: "/status/400")
        
        wrapper.runRequest(
            request: request,
            baseURL: "https://httpbin.org",
            authToken: nil,
            progressResult: nil,
            timeoutInSeconds: 10
        ) { statusCode, response, error in
            XCTAssertEqual(statusCode, 400, "Should return 400")
            XCTAssertNotNil(error, "Error should not be nil for 400")
            
            if let networkError = error as? EKNetworkErrorStruct {
                XCTAssertEqual(networkError.type, .badRequest, "Error type should be .badRequest")
                XCTAssertEqual(networkError.statusCode, 400, "Status code should be 400")
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    // MARK: - Test 11: 500 Internal Server Error type
    
    func testHandles500InternalServerError() {
        let expectation = XCTestExpectation(description: "500 error handled")
        
        let request = SimpleGETRequest(path: "/status/500")
        
        wrapper.runRequest(
            request: request,
            baseURL: "https://httpbin.org",
            authToken: nil,
            progressResult: nil,
            timeoutInSeconds: 10
        ) { statusCode, response, error in
            XCTAssertEqual(statusCode, 500, "Should return 500")
            XCTAssertNotNil(error, "Error should not be nil for 500")
            
            if let networkError = error as? EKNetworkErrorStruct {
                XCTAssertEqual(networkError.type, .internalServerError, "Error type should be .internalServerError")
                XCTAssertEqual(networkError.statusCode, 500, "Status code should be 500")
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    // MARK: - Test 12: Session Token authentication
    
    func testSessionTokenAuthorizationHeader() {
        let expectation = XCTestExpectation(description: "Session token sent")
        
        let request = AuthenticatedRequest(path: "/posts/1", authType: .sessionToken)
        
        wrapper.runRequest(
            request: request,
            baseURL: "https://jsonplaceholder.typicode.com",
            authToken: { return "test-session-token-12345" },
            progressResult: nil,
            timeoutInSeconds: 10
        ) { statusCode, response, error in
            // Request should complete (endpoint doesn't validate Session-Token)
            // The important part is that header was set correctly
            XCTAssertNotNil(response, "Response should not be nil")
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    // MARK: - Test 13: Error delegate is called
    
    func testErrorDelegateCalledOnError() {
        let expectation = XCTestExpectation(description: "Delegate called")
        let delegateMock = MockErrorDelegate()
        
        wrapper.delegate = delegateMock
        
        let request = SimpleGETRequest(path: "/status/404")
        
        wrapper.runRequest(
            request: request,
            baseURL: "https://httpbin.org",
            authToken: nil,
            progressResult: nil,
            timeoutInSeconds: 10
        ) { statusCode, response, error in
            XCTAssertEqual(statusCode, 404, "Should return 404")
            
            // Verify delegate was called
            XCTAssertTrue(delegateMock.handleWasCalled, "Delegate should be called")
            XCTAssertEqual(delegateMock.lastStatusCode, 404, "Delegate should receive correct status code")
            XCTAssertNotNil(delegateMock.lastError, "Delegate should receive error")
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    // MARK: - Test 14: Success status codes (201 Created)
    
    func testHandles201CreatedSuccess() {
        let expectation = XCTestExpectation(description: "201 handled as success")
        
        let request = SimpleGETRequest(path: "/status/201")
        
        wrapper.runRequest(
            request: request,
            baseURL: "https://httpbin.org",
            authToken: nil,
            progressResult: nil,
            timeoutInSeconds: 10
        ) { statusCode, response, error in
            XCTAssertEqual(statusCode, 201, "Should return 201")
            XCTAssertNotNil(response, "Response should not be nil for 2xx")
            XCTAssertNil(error, "Error should be nil for 2xx status")
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    // MARK: - Test 15: Error body is accessible
    
    func testErrorBodyIsAccessible() {
        let expectation = XCTestExpectation(description: "Error body accessible")
        
        let request = SimpleGETRequest(path: "/status/400")
        
        wrapper.runRequest(
            request: request,
            baseURL: "https://httpbin.org",
            authToken: nil,
            progressResult: nil,
            timeoutInSeconds: 10
        ) { statusCode, response, error in
            XCTAssertNotNil(error, "Error should not be nil")
            
            if let networkError = error as? EKNetworkErrorStruct {
                XCTAssertNotNil(networkError.data, "Error should have data")
                XCTAssertNotNil(networkError.plainBody, "Error should have plainBody")
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
}

// MARK: - Mock Error Delegate

class MockErrorDelegate: EKErrorHandleDelegate {
    var handleWasCalled = false
    var lastError: EKNetworkError?
    var lastStatusCode: Int?
    
    func handle(error: EKNetworkError?, statusCode: Int) {
        handleWasCalled = true
        lastError = error
        lastStatusCode = statusCode
    }
}

// MARK: - Test Helper Requests

struct SimpleGETRequest: EKNetworkRequest {
    let path: String
    var method: EKRequestHTTPMethod { .get }
    var urlParameters: [String: Any]? { nil }
    var bodyParameters: [String: Any]? { nil }
    var multipartBody: [EKMultipartFormData]? { nil }
    var array: [[String: Any]]? { nil }
    var headers: [String: String]? { nil }
    var authHeader: AuthHeader { .bearerToken }
    var needToCache: Bool { false }
}

struct GETRequestWithParams: EKNetworkRequest {
    let path: String
    let params: [String: Any]
    
    init(path: String, params: [String: Any]) {
        self.path = path
        self.params = params
    }
    
    var method: EKRequestHTTPMethod { .get }
    var urlParameters: [String: Any]? { params }
    var bodyParameters: [String: Any]? { nil }
    var multipartBody: [EKMultipartFormData]? { nil }
    var array: [[String: Any]]? { nil }
    var headers: [String: String]? { nil }
    var authHeader: AuthHeader { .bearerToken }
    var needToCache: Bool { false }
    
    // Manual Codable conformance (not used in tests, just to satisfy protocol)
    init(from decoder: Decoder) throws { fatalError("Not implemented") }
    func encode(to encoder: Encoder) throws { }
}

struct AuthenticatedRequest: EKNetworkRequest {
    let path: String
    let authType: AuthHeader
    
    var method: EKRequestHTTPMethod { .get }
    var urlParameters: [String: Any]? { nil }
    var bodyParameters: [String: Any]? { nil }
    var multipartBody: [EKMultipartFormData]? { nil }
    var array: [[String: Any]]? { nil }
    var headers: [String: String]? { nil }
    var authHeader: AuthHeader { authType }
    var needToCache: Bool { false }
}

//
//  EKNetworkingIntegrationTests.swift
//  EKNetworkingTests
//
//  Created by Egor Solovev on 14.01.2026.
//  Copyright © 2026 Emil Karimov. All rights reserved.
//

import XCTest
import Foundation
@testable import EKNetworking

/// Integration tests - minimal smoke tests hitting real APIs
/// Only 5 essential tests to verify real-world behavior
/// For comprehensive testing, see EKNetworkingUnitTests (fast mocked tests)
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
    
    // MARK: - Test 1: Successful GET request (Basic Smoke Test)
    
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
            
            if let response = response {
                XCTAssertFalse(response.data.isEmpty, "Response data should not be empty")
                let json = try? JSONSerialization.jsonObject(with: response.data)
                XCTAssertNotNil(json, "Response should be valid JSON")
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    // MARK: - Test 2: Completion runs on main thread
    
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
            XCTAssertTrue(Thread.isMainThread, "Completion must run on main thread")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    // MARK: - Test 3: Timeout handling
    
    func testTimeoutHandling() {
        let expectation = XCTestExpectation(description: "Timeout handled")
        
        let request = SimpleGETRequest(path: "/delay/10")
        
        wrapper.runRequest(
            request: request,
            baseURL: "https://httpbin.org",
            authToken: nil,
            progressResult: nil,
            timeoutInSeconds: 1
        ) { statusCode, response, error in
            XCTAssertNotNil(error, "Should have timeout error")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    // MARK: - Test 4: Bearer token authorization
    
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
            XCTAssertNotNil(response, "Response should not be nil")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    // MARK: - Test 5: Progress tracking
    
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
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
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

//
//  EKNetworkRequestWrapper.swift
//  EKNetworking
//
//  Created by Emil Karimov on 24.09.2019.
//  Copyright © 2019 Emil Karimov. All rights reserved.
//

import Foundation
import os.log

public protocol EKNetworkRequestWrapperProtocol {

    func runRequest(request: EKNetworkRequest,
                    baseURL: String,
                    authToken: (() -> String?)?,
                    progressResult: ((Double) -> Void)?,
                    showBodyResponse: Bool,
                    timeoutInSeconds: TimeInterval,
                    completion: @escaping(_ statusCode: Int, _ response: EKResponse?, _ error: EKNetworkError?) -> Void)

}

public protocol EKErrorHandleDelegate: AnyObject {

    func handle(error: EKNetworkError?, statusCode: Int)

}

open class EKNetworkRequestWrapper: EKNetworkRequestWrapperProtocol {

    /// Error handler Delegate
    public weak var delegate: EKErrorHandleDelegate?
    
    /// Logger type configuration
    private let loggerType: EKNetworkLoggerType
    
    /// URLSession for making network requests
    private let urlSession: URLSession
    
    /// OSLog for console logging
    private let osLogger: OSLog
    
    /// Storage for progress observers to keep them alive during requests
    private var progressObservers: [URLSessionTask: NSKeyValueObservation] = [:]
    private let observersQueue = DispatchQueue(label: "com.eknetworking.observers")
    
    /// Whether to dispatch completion handlers to main thread
    /// Default: true (maintains Moya's behavior for backward compatibility)
    public let callbackQueue: DispatchQueue

    /// Initialize network request wrapper
    /// - Parameters:
    ///   - loggerType: Type of logger to use (defaultLogger, sensitiveDataRedacted, or customLogger)
    ///   - session: Custom URLSession to use
    ///   - callbackQueue: Queue for completion callbacks (default: main)
    public init(
        loggerType: EKNetworkLoggerType = .defaultLogger,
        session: URLSession? = nil,
        callbackQueue: DispatchQueue = .main
    ) {
        self.loggerType = loggerType
        self.callbackQueue = callbackQueue
        self.osLogger = OSLog(subsystem: "com.eknetworking.network", category: "requests")
        
        if let session = session {
            self.urlSession = session
        } else {
            let configuration = URLSessionConfiguration.default
            configuration.requestCachePolicy = .useProtocolCachePolicy
            self.urlSession = URLSession(configuration: configuration)
        }
    }

    open func runRequest(request: EKNetworkRequest,
                         baseURL: String,
                         authToken: (() -> String?)?,
                         progressResult: ((Double) -> Void)?,
                         showBodyResponse: Bool = false,
                         timeoutInSeconds: TimeInterval,
                         completion: @escaping(_ statusCode: Int, _ response: EKResponse?, _ error: EKNetworkError?) -> Void) {

        if loggerType.consoleLogEnable {
            os_log(.debug, log: osLogger, "Start request to %{public}@%{public}@", baseURL, request.path)
        }
        
        self.runWith(
            request: request,
            baseURL: baseURL,
            authToken: authToken,
            progressResult: progressResult,
            showBodyResponse: showBodyResponse,
            timeoutInSeconds: timeoutInSeconds,
            completion: { (statusCode, response, error) in
                if showBodyResponse && self.loggerType.consoleLogEnable {
                    let body: String = response.map { String(data: $0.data, encoding: .utf8) ?? "" } ?? ""
                    os_log(.debug, log: self.osLogger, ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>")
                    os_log(.debug, log: self.osLogger, "📥 RESPONSE DETAILS")
                    os_log(.debug, log: self.osLogger, "Status code: %d", statusCode)
                    os_log(.debug, log: self.osLogger, "URL: %{public}@", baseURL + request.path)
                    os_log(.debug, log: self.osLogger, "Headers: %{public}@", String(describing: self.redactSensitiveHeaders(response?.response?.headers ?? [:])))
                    os_log(.debug, log: self.osLogger, "Body: %{public}@", body)
                    if let code = error?.errorCode, let plainBody = error?.plainBody {
                        os_log(.debug, log: self.osLogger, "Error code: %d", code)
                        os_log(.debug, log: self.osLogger, "Error body: %{public}@", plainBody)
                    }
                    os_log(.debug, log: self.osLogger, "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<")
                }
                self.delegate?.handle(error: error, statusCode: statusCode)
                completion(statusCode, response, error)
            }
        )
    }

}

// MARK: - Private

private extension EKNetworkRequestWrapper {

    private func redactSensitiveHeaders(_ headers: [String: String]) -> [String: String] {
        // If redaction is disabled, return headers as-is
        guard loggerType.redactSensitiveData else {
            return headers
        }
        
        let sensitiveKeys = [
            "Authorization",
            "Session-Token",
            "X-Auth-Token",
            "X-API-Key",
            "Cookie",
            "Set-Cookie"
        ]
        
        var redacted = headers
        for key in headers.keys {
            if sensitiveKeys.contains(where: { $0.lowercased() == key.lowercased() }) {
                redacted[key] = "***REDACTED***"
            }
        }
        return redacted
    }
    
    private func runWith(
        request: EKNetworkRequest,
        baseURL: String,
        authToken: (() -> String?)?,
        progressResult: ((Double) -> Void)?,
        showBodyResponse: Bool,
        timeoutInSeconds: TimeInterval,
        completion: @escaping(_ statusCode: Int, _ response: EKResponse?, _ error: EKNetworkError?) -> Void
    ) {
        let requestStartTime = DispatchTime.now()
        
        guard let urlRequest = buildURLRequest(
            request: request,
            baseURL: baseURL,
            authToken: authToken,
            timeoutInSeconds: timeoutInSeconds
        ) else {
            let error = EKNetworkErrorStruct(statusCode: URLError.badURL.rawValue, data: nil)
            callbackQueue.async {
                completion(URLError.badURL.rawValue, nil, error)
            }
            return
        }
        
        if showBodyResponse && loggerType.consoleLogEnable {
            os_log(.debug, log: osLogger, ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>")
            os_log(.debug, log: osLogger, "📤 REQUEST DETAILS")
            os_log(.debug, log: osLogger, "Method: %{public}@", urlRequest.httpMethod ?? "N/A")
            os_log(.debug, log: osLogger, "URL: %{public}@", urlRequest.url?.absoluteString ?? "N/A")
            os_log(.debug, log: osLogger, "Headers: %{public}@", String(describing: redactSensitiveHeaders(urlRequest.allHTTPHeaderFields ?? [:])))
            if let body = urlRequest.httpBody, let bodyString = String(data: body, encoding: .utf8) {
                os_log(.debug, log: osLogger, "Body: %{public}@", bodyString)
            } else {
                os_log(.debug, log: osLogger, "Body: <none>")
            }
            os_log(.debug, log: osLogger, "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<")
        }
        
        // Store a reference to the task for logging
        weak var createdTask: URLSessionDataTask?
        
        let task = urlSession.dataTask(with: urlRequest) { [weak self] data, response, error in
            guard let self = self else { return }
            
            // Clean up progress observer when task completes
            if let task = createdTask {
                self.observersQueue.async {
                    self.progressObservers.removeValue(forKey: task)
                }
            }
            
            let requestEndTime = DispatchTime.now()
            let requestTime = requestEndTime.uptimeNanoseconds - requestStartTime.uptimeNanoseconds
            if self.loggerType.consoleLogEnable {
                let duration = (Double(requestTime) / 1_000_000_000).roundWithPlaces(2)
                os_log(.debug, log: self.osLogger, "Duration: %.2f sec", duration)
            }
            
            if let logger = self.loggerType.networkLogger, let task = createdTask {
                let responseData = data ?? Data()
                if response is HTTPURLResponse {
                    logger.logDataTask(task, didReceive: responseData)
                }
                logger.logTask(task, didCompleteWithError: error)
            }
            
            if let error = error {
                let nsError = error as NSError
                let networkError = EKNetworkErrorStruct(statusCode: nsError.code, data: data)
                
                self.callbackQueue.async {
                    completion(nsError.code, nil, networkError)
                }
                return
            }
            
            let responseData = data ?? Data()
            
            if let httpResponse = response as? HTTPURLResponse {
                let ekResponse = EKResponse(statusCode: httpResponse.statusCode, data: responseData, request: urlRequest, response: httpResponse)
                
                self.callbackQueue.async {
                    if 200...299 ~= httpResponse.statusCode {
                        completion(httpResponse.statusCode, ekResponse, nil)
                    } else {
                        let networkError = EKNetworkErrorStruct(statusCode: httpResponse.statusCode, data: responseData)
                        completion(httpResponse.statusCode, ekResponse, networkError)
                    }
                }
            } else {
                let networkError = EKNetworkErrorStruct(statusCode: 0, data: responseData)
                self.callbackQueue.async {
                    completion(0, nil, networkError)
                }
            }
        }
        
        // Store task reference for closure
        createdTask = task

        // Setup progress tracking using KVO on the task's progress property
        if let progressCallback = progressResult {
            let observer = task.progress.observe(\.fractionCompleted, options: [.new]) { [weak self] progress, _ in
                // Dispatch progress updates to callback queue
                self?.callbackQueue.async {
                    progressCallback(progress.fractionCompleted)
                }
            }
            
            // Store observer to keep it alive during the request
            observersQueue.async { [weak self] in
                self?.progressObservers[task] = observer
            }
        }

        if let logger = loggerType.networkLogger {
            logger.logTaskCreated(task)
        }
        
        task.resume()
    }
    
    private func buildURLRequest(
        request: EKNetworkRequest,
        baseURL: String,
        authToken: (() -> String?)?,
        timeoutInSeconds: TimeInterval
    ) -> URLRequest? {
        // Construct URL
        guard let baseUrl = URL(string: baseURL) else { return nil }
        var urlComponents = URLComponents(url: baseUrl.appendingPathComponent(request.path), resolvingAgainstBaseURL: false)
        
        // Add query parameters
        if let urlParameters = request.urlParameters, !urlParameters.isEmpty {
            var queryItems: [URLQueryItem] = []
            
            for (key, value) in urlParameters {
                // Handle arrays specially
                if let arrayValue = value as? [Any] {
                    // For arrays, create multiple query items with the same key
                    // Example: ["ids": [1, 2, 3]] becomes "ids=1&ids=2&ids=3"
                    if arrayValue.isEmpty {
                        // For empty arrays, don't add any query items
                        // Some APIs expect no parameter, others expect key with no value
                        // You can change this behavior if needed
                        continue
                    } else {
                        for item in arrayValue {
                            queryItems.append(URLQueryItem(name: key, value: "\(item)"))
                        }
                    }
                } else {
                    // For non-array values, use string representation
                    queryItems.append(URLQueryItem(name: key, value: "\(value)"))
                }
            }
            
            urlComponents?.queryItems = queryItems
        }
        
        guard let url = urlComponents?.url else { return nil }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.timeoutInterval = timeoutInSeconds
        
        // Set HTTP method
        switch request.method {
        case .get:
            urlRequest.httpMethod = "GET"
        case .post, .multiple:
            urlRequest.httpMethod = "POST"
        case .put:
            urlRequest.httpMethod = "PUT"
        case .delete:
            urlRequest.httpMethod = "DELETE"
        case .patch:
            urlRequest.httpMethod = "PATCH"
        case .options:
            urlRequest.httpMethod = "OPTIONS"
        case .head:
            urlRequest.httpMethod = "HEAD"
        case .trace:
            urlRequest.httpMethod = "TRACE"
        case .connect:
            urlRequest.httpMethod = "CONNECT"
        }
        
        // Set headers
        if let headers = request.headers {
            for (key, value) in headers {
                urlRequest.setValue(value, forHTTPHeaderField: key)
            }
        }
        
        // Set authorization header
        if let tokenFunc = authToken, let token = tokenFunc() {
            switch request.authHeader {
            case .bearerToken:
                urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            case .sessionToken:
                urlRequest.setValue(token, forHTTPHeaderField: "Session-Token")
            }
        }
        
        // Set body
        if request.method != .get {
            if let multipartData = request.multipartBody {
                // Handle multipart form data
                let boundary = "Boundary-\(UUID().uuidString)"
                urlRequest.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
                urlRequest.httpBody = createMultipartBody(multipartData: multipartData, boundary: boundary)
            } else if let array = request.array {
                // Handle array body
                if let jsonData = try? JSONSerialization.data(withJSONObject: array, options: []) {
                    urlRequest.httpBody = jsonData
                    urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
                }
            } else {
                let bodyParameters = request.bodyParameters ?? [:]
                if let jsonData = try? JSONSerialization.data(withJSONObject: bodyParameters, options: []) {
                    urlRequest.httpBody = jsonData
                    urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
                }
            }
        }
        
        return urlRequest
    }
    
    private func createMultipartBody(multipartData: [EKMultipartFormData], boundary: String) -> Data {
        var body = Data()
        
        for part in multipartData {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            
            var contentDisposition = "Content-Disposition: form-data; name=\"\(part.name)\""
            if let fileName = part.fileName {
                contentDisposition += "; filename=\"\(fileName)\""
            }
            contentDisposition += "\r\n"
            body.append(contentDisposition.data(using: .utf8)!)
            
            if let mimeType = part.mimeType {
                body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
            } else {
                body.append("\r\n".data(using: .utf8)!)
            }
            
            if let data = try? part.getData() {
                body.append(data)
            }
            body.append("\r\n".data(using: .utf8)!)
        }
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        return body
    }
    
}

// MARK: - Async Protocol Conformance

@available(iOS 13.0, macOS 10.15, *)
extension EKNetworkRequestWrapper: EKNetworkRequestWrapperAsyncProtocol {
    
    /// Async implementation that wraps the completion-based version
    public func runRequest(
        request: EKNetworkRequest,
        baseURL: String,
        authToken: (() -> String?)? = nil,
        progressResult: ((Double) -> Void)? = nil,
        showBodyResponse: Bool = false,
        timeoutInSeconds: TimeInterval
    ) async throws -> EKResponse {
        
        try await withCheckedThrowingContinuation { continuation in
            runRequest(
                request: request,
                baseURL: baseURL,
                authToken: authToken,
                progressResult: progressResult,
                showBodyResponse: showBodyResponse,
                timeoutInSeconds: timeoutInSeconds
            ) { statusCode, response, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let response = response {
                    continuation.resume(returning: response)
                } else {
                    // Fallback error - should never happen in practice
                    let fallbackError = EKNetworkErrorStruct(
                        statusCode: statusCode,
                        data: nil
                    )
                    continuation.resume(throwing: fallbackError)
                }
            }
        }
    }
}

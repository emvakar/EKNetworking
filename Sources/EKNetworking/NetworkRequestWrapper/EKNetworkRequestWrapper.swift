//
//  EKNetworkRequestWrapper.swift
//  EKNetworking
//
//  Created by Emil Karimov on 24.09.2019.
//  Copyright © 2019 Emil Karimov. All rights reserved.
//

import Foundation
import Logging
import PulseLogHandler
import Pulse

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
    public var logEnable: Bool
    
    /// URLSession for making network requests
    private let urlSession: URLSession
    
    /// Network logger for Pulse integration
    private let networkLogger: NetworkLogger?
    
    /// Storage for progress observers to keep them alive during requests
    private var progressObservers: [URLSessionTask: NSKeyValueObservation] = [:]
    private let observersQueue = DispatchQueue(label: "com.eknetworking.observers")

    public init(logging: Logger? = nil, logEnable: Bool = false) {
        if let logging = logging {
            logger = logging
        }
        self.logEnable = logEnable
        
        // Create URLSession configuration
        let configuration = URLSessionConfiguration.default
        configuration.requestCachePolicy = .useProtocolCachePolicy
        self.urlSession = URLSession(configuration: configuration)
        
        // Setup network logger for Pulse if logging is enabled
        if logEnable {
            self.networkLogger = NetworkLogger()
        } else {
            self.networkLogger = nil
        }
    }

    open func runRequest(request: EKNetworkRequest,
                         baseURL: String,
                         authToken: (() -> String?)?,
                         progressResult: ((Double) -> Void)?,
                         showBodyResponse: Bool = false,
                         timeoutInSeconds: TimeInterval,
                         completion: @escaping(_ statusCode: Int, _ response: EKResponse?, _ error: EKNetworkError?) -> Void) {

        logger.debug("[NETWORK]: Start request to \(baseURL)\(request.path)")
        
        self.runWith(
            request: request,
            baseURL: baseURL,
            authToken: authToken,
            progressResult: progressResult,
            showBodyResponse: showBodyResponse,
            timeoutInSeconds: timeoutInSeconds,
            completion: { (statusCode, response, error) in
                if showBodyResponse {
                    #if DEBUG
                    let body: String = response.map { String(data: $0.data, encoding: .utf8) ?? "" } ?? ""
                    logger.debug(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>")
                    logger.debug("[NETWORK]: Response status code: \(statusCode)")
                    logger.debug("[NETWORK]: Response url: \(baseURL + request.path)")
                    logger.debug("[NETWORK]: Response headers: \(request.headers ?? [:])")
                    logger.debug("[NETWORK]: Response body: \(String(describing: body))")
                    if let code = error?.errorCode, let plainBody = error?.plainBody {
                        logger.debug("[NETWORK]: Response error code \(String(describing: code)) body: \(String(describing: plainBody))")
                    }
                    logger.debug("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<")
                    #endif
                }
                self.delegate?.handle(error: error, statusCode: statusCode)
                completion(statusCode, response, error)
            }
        )
    }

}

// MARK: - Private

private extension EKNetworkRequestWrapper {
    
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
            DispatchQueue.main.async {
                completion(URLError.badURL.rawValue, nil, error)
            }
            return
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
            logger.debug("[NETWORK]: Duration is \((Double(requestTime) / 1_000_000_000).roundWithPlaces(2)) sec")
            
            if let logger = self.networkLogger, let task = createdTask {
                let responseData = data ?? Data()
                if response is HTTPURLResponse {
                    logger.logDataTask(task, didReceive: responseData)
                }
                logger.logTask(task, didCompleteWithError: error)
            }
            
            if let error = error {
                let nsError = error as NSError
                let networkError = EKNetworkErrorStruct(statusCode: nsError.code, data: data)
                
                DispatchQueue.main.async {
                    completion(nsError.code, nil, networkError)
                }
                return
            }
            
            let responseData = data ?? Data()
            
            if let httpResponse = response as? HTTPURLResponse {
                let ekResponse = EKResponse(statusCode: httpResponse.statusCode, data: responseData, request: urlRequest, response: httpResponse)
                
                DispatchQueue.main.async {
                    if 200...299 ~= httpResponse.statusCode {
                        completion(httpResponse.statusCode, ekResponse, nil)
                    } else {
                        let networkError = EKNetworkErrorStruct(statusCode: httpResponse.statusCode, data: responseData)
                        completion(httpResponse.statusCode, nil, networkError)
                    }
                }
            } else {
                let networkError = EKNetworkErrorStruct(statusCode: 0, data: responseData)
                DispatchQueue.main.async {
                    completion(0, nil, networkError)
                }
            }
        }
        
        // Store task reference for closure
        createdTask = task

        // Setup progress tracking using KVO on the task's progress property
        if let progressCallback = progressResult {
            let observer = task.progress.observe(\.fractionCompleted, options: [.new]) { progress, _ in
                // Dispatch progress updates to main thread to match Moya's behavior
                DispatchQueue.main.async {
                    progressCallback(progress.fractionCompleted)
                }
            }
            
            // Store observer to keep it alive during the request
            observersQueue.async { [weak self] in
                self?.progressObservers[task] = observer
            }
        }

        if let logger = networkLogger {
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
            } else if let bodyParameters = request.bodyParameters, !bodyParameters.isEmpty {
                // Handle JSON body
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

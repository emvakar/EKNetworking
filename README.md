[![Swift Version](https://img.shields.io/badge/Swift-5.5-green.svg)](https://swift.org)  [![Build and Test](https://github.com/emvakar/EKNetworking/actions/workflows/tagging.yml/badge.svg?branch=master)](https://github.com/emvakar/EKNetworking/actions/workflows/tagging.yml)

## Support EKNetworking development by giving a ⭐️

## Installation

#### Swift Package Manager

```swift
    .package(url: "https://github.com/emvakar/EKNetworking.git", from: "2.0.0")
```

## Logging

EKNetworking supports logging via `EKNetworkLoggerType`:

### 1. Console logging (OSLog)

Use `.defaultLogger` or `.sensitiveDataRedacted` for built-in OSLog. View logs in Console.app or Xcode.

```swift
import EKNetworking

// Console logging (sensitive headers not redacted)
let networkWrapper = EKNetworkRequestWrapper(loggerType: .defaultLogger)

// Console logging with sensitive data redacted (tokens, cookies, etc.)
let networkWrapper = EKNetworkRequestWrapper(loggerType: .sensitiveDataRedacted)

// View logs using Console.app or terminal:
// log stream --predicate 'subsystem == "com.eknetworking.network"'
```

### 2. Custom network logger

For advanced logging (e.g. Pulse), use `.customLogger(networkLogger:)` and implement `EKNetworkLoggerProtocol`:

```swift
class MyCustomLogger: EKNetworkLoggerProtocol {
    func logTaskCreated(_ task: URLSessionTask) { /* ... */ }
    func logDataTask(_ task: URLSessionDataTask, didReceive data: Data) { /* ... */ }
    func logTask(_ task: URLSessionTask, didCompleteWithError error: Error?) { /* ... */ }
}

let customLogger = MyCustomLogger()
let networkWrapper = EKNetworkRequestWrapper(
    loggerType: .customLogger(networkLogger: customLogger)
)
```

**Note:** For Pulse integration, see [EKPulse](https://github.com/emvakar/EKPulse.git)

## Usage

> File: `NetworkRequestProvider.swift`

##

```swift
import UIKit
import EKNetworking

// Creating NetworkRequestProvider

final class NetworkRequestProvider {

    /// Your implementation: conform to EKNetworkRequestWrapperProtocol or use default EKNetworkRequestWrapper()
    let networkWrapper: EKNetworkRequestWrapperProtocol = EKNetworkRequestWrapper(loggerType: .defaultLogger)
    
    /// Your own implementation for token refreshing, subcalssing from EKNetworkTokenRefresherProtocol
    let tokenRefresher: EKNetworkTokenRefresherProtocol? = nil
    
    /// pass your account manager based on EKAccountWriteProtocol
    let accountWrite: EKAccountWriteProtocol
    
    /// pass your account manager based on EKAccountReadProtocol
    let accountRead: EKAccountReadProtocol
    
    init(networkWrapper: EKNetworkRequestWrapperProtocol = EKNetworkRequestWrapper(), tokenRefresher: NetworkTokenRefresherProtocol? = nil, accountWrite: AccountWriteProtocol, accountRead: AccountReadProtocol) {
        self.networkWrapper = networkWrapper
        self.tokenRefresher = tokenRefresher
        self.accountWrite = accountWrite
        self.accountRead = accountRead
    }

}

```



> File: `ExampleRequest.swift`

##

```swift
import EKNetworking

// Our request target ApiRequestGetTodosFeed
struct ApiRequestGetTodosFeed: EKNetworkRequest {

    let page: Int
    let per: Int
    
    var path: String { "/api/v1/posts" }

    var method: EKRequestHTTPMethod { .get }

    var urlParameters: [String : Any]? {
        return ["per": per, "page": page]
    }

    /* of course you can pass bodyParameters: [String : Any]?
    var bodyParameters: [String : Any]? {
        return ["per": per, "page": page]
    }
    */
    
    // All passed params you can see at EKNetworkRequest.swift
}

// NetworkTodoProtocol for extension

protocol NetworkTodoProtocol {
    func todosTimeline(page: Int, perPage: Int, completion: ((_ posts: [TodoModel]?, _ error: EKNetworkError?) -> Void)?)
}

extension NetworkRequestProvider: NetworkTodoProtocol {

    func todosTimeline(page: Int, perPage: Int, completion: ((_ posts: [TodoModel]?, _ error: EKNetworkError?) -> Void)?) {
        let request = ApiRequestGetTodosFeed(page: page, per: perPage)
        runRequest(request, progressResult: nil) { [weak self] statusCode, response, error in
        
            // do somthing with response
        
            // response is EKResponse
            // Represents a response from the network request
            // Contains statusCode, data, request, and response properties
        }
    }
    
}
```













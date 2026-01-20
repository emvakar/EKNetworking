# EKNetworking - URLSession Migration

## Summary

Migrated from **Moya + Alamofire** to **native URLSession** with **zero breaking changes**.

---

## What Changed

### Removed Dependencies
- ❌ Moya
- ❌ Alamofire
- ✅ Using native URLSession (built into iOS/macOS)

### New Native Types
- `EKResponse` - Native replacement for Moya's Response
- `EKMultipartFormData` - Native replacement for Moya's MultipartFormData

### Added Features
- ✅ **Swift Concurrency (async/await)** - Modern async API available through protocol
- ✅ **HTTPURLResponse.headers extension** - Moya compatibility (`response?.headers["Header-Name"]`)
- ✅ **Configurable callback queue** - Main (default) or background thread
- ✅ **Sensitive header redaction** - Security for logs (tokens, cookies)
- ✅ **POST empty body fix** - Always sends `{}` for POST/PUT (backend compatibility)
- ✅ **Enhanced logging** - Detailed request/response debugging with redaction

---

## Benefits

- **Smaller binary** - No external networking dependencies
- **Faster builds** - Fewer dependencies to compile
- **Better testability** - Dependency injection support
- **100% backward compatible** - Drop-in replacement

---

## Breaking Changes

**None!** All public APIs remain unchanged.

---

## Usage

### Option 1: Completion Handlers (original, unchanged)
```swift
let wrapper = EKNetworkRequestWrapper(logEnable: true)

wrapper.runRequest(
    request: myRequest,
    baseURL: "https://api.example.com",
    authToken: { "token" },
    progressResult: { progress in print(progress) },
    timeoutInSeconds: 30
) { statusCode, response, error in
    if let error = error {
        print("Error: \(error)")
    } else if let response = response {
        // response?.headers["Content-Type"] - Still works!
        print("Success: \(response.statusCode)")
    }
}
```

### Option 2: Async/Await (NEW! ⭐️)
```swift
// Works through the protocol!
let wrapper: EKNetworkRequestWrapperProtocol = EKNetworkRequestWrapper(logEnable: true)

do {
    let response = try await wrapper.runRequest(
        request: myRequest,
        baseURL: "https://api.example.com",
        authToken: { "token" },
        timeoutInSeconds: 30
    )
    print("Success: \(response.statusCode)")
    // response.headers["Content-Type"] - Still works!
} catch let error as EKNetworkError {
    print("Error: \(error.type)")
}
```

### Advanced Options
```swift
// Disable log redaction (for debugging only)
let wrapper = EKNetworkRequestWrapper(
    logEnable: true,
    redactSensitiveData: false  // Show real tokens in logs
)

// Background thread callbacks (completion handler version only)
let wrapper = EKNetworkRequestWrapper(
    callbackQueue: .global()  // Default is .main
)

// Custom URLSession (for testing)
let wrapper = EKNetworkRequestWrapper(
    session: mockSession
)
```

### Async/Await Advanced Examples

**Multiple concurrent requests:**
```swift
async let user = try wrapper.runRequest(
    request: GetUserRequest(),
    baseURL: baseURL,
    timeoutInSeconds: 30
)

async let posts = try wrapper.runRequest(
    request: GetPostsRequest(),
    baseURL: baseURL,
    timeoutInSeconds: 30
)

let (userData, postsData) = try await (user, posts)
```

**Using Task Groups:**
```swift
let responses = try await withThrowingTaskGroup(of: EKResponse.self) { group in
    for id in 1...10 {
        group.addTask {
            try await wrapper.runRequest(
                request: GetPostRequest(id: id),
                baseURL: baseURL,
                timeoutInSeconds: 30
            )
        }
    }
    
    var results: [EKResponse] = []
    for try await response in group {
        results.append(response)
    }
    return results
}
```

---

## Tests

**41 comprehensive tests** - All passing ✅
- 26 unit tests (completion handlers, mocked, fast)
- 10 async/await tests (mocked, fast)
- 5 integration tests (real API, smoke tests)

```bash
# Run all tests
swift test

# Run only async tests
swift test --filter EKNetworkingAsyncTests

# Run only completion handler tests
swift test --filter EKNetworkingUnitTests
```

---

## Migration Date

January 2026

---

## Notes

- **Threading**: Completion handlers dispatch to main thread by default (same as Moya)
- **Headers**: `response?.headers` works exactly like Moya (via extension)
- **Logging**: Sensitive headers (tokens, cookies) are redacted by default
- **Compatibility**: iOS 15+, macOS 13+

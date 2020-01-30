//
//  EKNetworkingProvider.swift
//  EKNetworking
//
//  Created by Emil Karimov on 26.10.2019.
//  Copyright © 2019 Emil Karimov. All rights reserved.
//

import Foundation

/// A protocol representing a minimal interface for a MoyaProvider.
/// Used by the reactive provider extensions.
public protocol EKNetworkingProviderType: AnyObject {

    associatedtype Target: TargetType

    /// Designated request-making method. Returns a `Cancellable` token to cancel the request later.
    func request(_ target: Target, callbackQueue: DispatchQueue?, progress: Moya.ProgressBlock?, completion: @escaping Moya.Completion) -> Cancellable
}

/// Request provider class. Requests should be made through this class only.
open class EKNetworkingProvider<Target: EKTargetType>: EKNetworkingProvider {

    /// Closure that defines the endpoints for the provider.
    public typealias EndpointClosure = (Target) -> Endpoint

    /// Closure that decides if and what request should be performed.
    public typealias RequestResultClosure = (Result<URLRequest, MoyaError>) -> Void

    /// Closure that resolves an `Endpoint` into a `RequestResult`.
    public typealias RequestClosure = (Endpoint, @escaping RequestResultClosure) -> Void

    /// Closure that decides if/how a request should be stubbed.
    public typealias StubClosure = (Target) -> Moya.StubBehavior

    /// A closure responsible for mapping a `TargetType` to an `EndPoint`.
    public let endpointClosure: EndpointClosure

    /// A closure deciding if and what request should be performed.
    public let requestClosure: RequestClosure

    /// A closure responsible for determining the stubbing behavior
    /// of a request for a given `TargetType`.
    public let stubClosure: StubClosure

    /// The manager for the session.
    public let manager: Manager

    /// A list of plugins.
    /// e.g. for logging, network activity indicator or credentials.
    public let plugins: [PluginType]

    public let trackInflights: Bool

    open internal(set) var inflightRequests: [Endpoint: [Moya.Completion]] = [:]

    /// Propagated to Alamofire as callback queue. If nil - the Alamofire default (as of their API in 2017 - the main queue) will be used.
    let callbackQueue: DispatchQueue?

    /// Initializes a provider.
    public init(endpointClosure: @escaping EndpointClosure = MoyaProvider.defaultEndpointMapping,
                requestClosure: @escaping RequestClosure = MoyaProvider.defaultRequestMapping,
                stubClosure: @escaping StubClosure = MoyaProvider.neverStub,
                callbackQueue: DispatchQueue? = nil,
                manager: Manager = MoyaProvider<Target>.defaultAlamofireManager(),
                plugins: [PluginType] = [],
                trackInflights: Bool = false) {

        self.endpointClosure = endpointClosure
        self.requestClosure = requestClosure
        self.stubClosure = stubClosure
        self.manager = manager
        self.plugins = plugins
        self.trackInflights = trackInflights
        self.callbackQueue = callbackQueue
    }

    /// Returns an `Endpoint` based on the token, method, and parameters by invoking the `endpointClosure`.
    open func endpoint(_ token: Target) -> Endpoint {
        return endpointClosure(token)
    }

    /// Designated request-making method. Returns a `Cancellable` token to cancel the request later.
    @discardableResult
    open func request(_ target: Target,
                      callbackQueue: DispatchQueue? = .none,
                      progress: ProgressBlock? = .none,
                      completion: @escaping Completion) -> Cancellable {

        let callbackQueue = callbackQueue ?? self.callbackQueue
        return requestNormal(target, callbackQueue: callbackQueue, progress: progress, completion: completion)
    }

    // swiftlint:disable function_parameter_count
    /// When overriding this method, take care to `notifyPluginsOfImpendingStub` and to perform the stub using the `createStubFunction` method.
    /// Note: this was previously in an extension, however it must be in the original class declaration to allow subclasses to override.
    @discardableResult
    open func stubRequest(_ target: Target, request: URLRequest, callbackQueue: DispatchQueue?, completion: @escaping Moya.Completion, endpoint: Endpoint, stubBehavior: Moya.StubBehavior) -> CancellableToken {
        let callbackQueue = callbackQueue ?? self.callbackQueue
        let cancellableToken = CancellableToken { }
        notifyPluginsOfImpendingStub(for: request, target: target)
        let plugins = self.plugins
        let stub: () -> Void = createStubFunction(cancellableToken, forTarget: target, withCompletion: completion, endpoint: endpoint, plugins: plugins, request: request)
        switch stubBehavior {
        case .immediate:
            switch callbackQueue {
            case .none:
                stub()
            case .some(let callbackQueue):
                callbackQueue.async(execute: stub)
            }
        case .delayed(let delay):
            let killTimeOffset = Int64(CDouble(delay) * CDouble(NSEC_PER_SEC))
            let killTime = DispatchTime.now() + Double(killTimeOffset) / Double(NSEC_PER_SEC)
            (callbackQueue ?? DispatchQueue.main).asyncAfter(deadline: killTime) {
                stub()
            }
        case .never:
            fatalError("Method called to stub request when stubbing is disabled.")
        }

        return cancellableToken
    }
    // swiftlint:enable function_parameter_count
}

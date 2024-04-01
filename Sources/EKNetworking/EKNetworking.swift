//
//  EKNetworking.swift
//  EKNetworking
//
//  Created by Emil Karimov on 24.09.2019.
//  Copyright © 2019 Emil Karimov. All rights reserved.
//

import Moya
import Pulse
import PulseUI
import CoreData
import Combine
import SwiftUI
import Foundation

public typealias EKMultipartFormData = MultipartFormData
public typealias EKResponse = Response

public class LogExporter {

    private let store = LoggerStore.shared
    private var shareItems: ShareItems?

    public init() { }

    public func collectLogsForSharing() async throws -> ShareItems? {
        let store = LoggerStore.shared
        let storedSessions = try await withUnsafeThrowingContinuation { continuation in
            store.backgroundContext.perform {
                let request = NSFetchRequest<LoggerSessionEntity>(entityName: "\(LoggerSessionEntity.self)")
//                request.predicate = options.predicate // important: contains sessions
                let result = Result(catching: { try store.backgroundContext.fetch(request) })
                continuation.resume(with: result)
            }
        }
        let sessions = Set(storedSessions.compactMap({ $0.id }))
        let options = LoggerStore.ExportOptions(predicate: predicate(), sessions: sessions)
        shareItems = try await prepareForSharing(store: LoggerStore.shared, options: options)
        return shareItems
    }

    public func shareLogsViewController(on viewController: UIViewController) async throws {
        if let item = try await collectLogsForSharing() {
            let shareView = ShareView(item)
            shareView.presentOnViewController(viewController)
        }
    }

}

private extension LogExporter {

    func makeCurrentDate() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "yyyy-MM-dd-HH-mm"
        return formatter.string(from: Date())
    }

    func predicate(log levels: [LoggerStore.Level] = LoggerStore.Level.allCases) -> NSPredicate? {
        var predicates: [NSPredicate] = []
        predicates.append(.init(format: "level IN %@", Set(levels).map(\.rawValue)))
        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }

    func prepareForSharing(store: LoggerStore, options: LoggerStore.ExportOptions, output: ShareStoreOutput = .store) async throws -> ShareItems {
//        switch output {
//        case .store:
//            return try await prepareStoreForSharing(store: store, as: .archive, options: options)
//        case .package:
//            return try await prepareStoreForSharing(store: store, as: .package, options: options)
//        case .text, .html:
//            let output: ShareOutput = output == .text ? .plainText : .html
//            return try await prepareForSharing(store: store, output: output, options: options)
//        case .har:
//            return try await prepareForSharing(store: store, output: .har, options: options)
//        }
        return try await prepareStoreForSharing(store: store, as: .archive, options: options)
    }

    func prepareStoreForSharing(store: LoggerStore, as docType: LoggerStore.DocumentType, options: LoggerStore.ExportOptions, output: ShareStoreOutput = .store) async throws -> ShareItems {
        let directory = TemporaryDirectory()

        let logsURL = directory.url.appendingPathComponent("logs-\(makeCurrentDate()).\(output.fileExtension)")
        try await store.export(to: logsURL, as: docType, options: options)
        return ShareItems([logsURL], cleanup: directory.remove)
    }

    func prepareForSharing(store: LoggerStore, output: ShareOutput, options: LoggerStore.ExportOptions) async throws -> ShareItems {
        let entities = try await withUnsafeThrowingContinuation { continuation in
            store.backgroundContext.perform {
                let request = NSFetchRequest<LoggerMessageEntity>(entityName: "\(LoggerMessageEntity.self)")
                request.predicate = options.predicate // important: contains sessions
                let result = Result(catching: { try store.backgroundContext.fetch(request) })
                continuation.resume(with: result)
            }
        }
        return try await ShareService.share(entities, store: store, as: output)
    }

}

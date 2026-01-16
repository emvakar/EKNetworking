//
//  EKMultipartFormData.swift
//  EKNetworking
//
//  Created by Egor Solovev on 13.01.2026.
//  Copyright © 2026 Emil Karimov. All rights reserved.
//

import Foundation

/// Represents multipart form data for file uploads.
/// Native replacement for Moya's MultipartFormData type.
public struct EKMultipartFormData {
    
    /// The provider of the data to be uploaded.
    public enum Provider {
        case data(Data)
        case file(URL)
        case stream(InputStream, UInt64)
    }
    
    /// The name of the form field.
    public let name: String
    
    /// The filename to use for the file.
    public let fileName: String?
    
    /// The MIME type of the data.
    public let mimeType: String?
    
    /// The provider of the data.
    public let provider: Provider
    
    /// Initializes a new multipart form data part with data.
    /// - Parameters:
    ///   - provider: The data provider.
    ///   - name: The form field name.
    ///   - fileName: Optional filename.
    ///   - mimeType: Optional MIME type.
    public init(provider: Provider, name: String, fileName: String? = nil, mimeType: String? = nil) {
        self.provider = provider
        self.name = name
        self.fileName = fileName
        self.mimeType = mimeType
    }
    
    /// Convenience initializer for data
    /// - Parameters:
    ///   - data: The data to upload.
    ///   - name: The form field name.
    ///   - fileName: Optional filename.
    ///   - mimeType: Optional MIME type.
    public init(data: Data, name: String, fileName: String? = nil, mimeType: String? = nil) {
        self.init(provider: .data(data), name: name, fileName: fileName, mimeType: mimeType)
    }
    
    /// Convenience initializer for file URL
    /// - Parameters:
    ///   - fileURL: The file URL to upload.
    ///   - name: The form field name.
    ///   - fileName: Optional filename (defaults to file URL's last path component).
    ///   - mimeType: Optional MIME type.
    public init(fileURL: URL, name: String, fileName: String? = nil, mimeType: String? = nil) {
        let finalFileName = fileName ?? fileURL.lastPathComponent
        self.init(provider: .file(fileURL), name: name, fileName: finalFileName, mimeType: mimeType)
    }
    
    /// Gets the data from the provider
    /// - Returns: The data to be uploaded
    /// - Throws: Error if file cannot be read
    internal func getData() throws -> Data {
        switch provider {
        case .data(let data):
            return data
        case .file(let url):
            return try Data(contentsOf: url)
        case .stream(let stream, let length):
            var data = Data()
            stream.open()
            defer { stream.close() }
            
            let bufferSize = 4096
            let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
            defer { buffer.deallocate() }
            
            while stream.hasBytesAvailable {
                let read = stream.read(buffer, maxLength: bufferSize)
                if read > 0 {
                    data.append(buffer, count: read)
                } else if read < 0 {
                    throw stream.streamError ?? NSError(domain: "EKNetworking", code: -1, userInfo: [NSLocalizedDescriptionKey: "Stream read error"])
                } else {
                    break
                }
            }
            
            return data
        }
    }
}

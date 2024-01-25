//
//  Service.swift
//
//
//  Created by Joel Joseph on 4/8/23.
//

import os
import Combine
import SwiftUI
import Foundation

/// Courrier is the service that Hermes uses to organize your API requests
@available(macOS 13.0, *)
@available(iOS 15.0, *)
public class Courrier: NSObject, ObservableObject, URLSessionDelegate {
    
    public var host:String
    public var scheme: Scheme
    
    private let logger:Logger
    private let session: URLSession
   
    public var userAgent: String = "hermes"
    public var contentType: String = "application/json"
    public var accept: String = "application/json"
    public var connection: String = "keep-alive"
    
    @Published public var uploadProgress: Double = 0.0
    @Published private var isUploading = false
    
    /// Initializer function for Courrier
    ///
    /// Sets up the logger for logging errors
    /// Sets up the url session for all of the requests in this class instance
    ///
    /// - Parameters:
    ///     - scheme: the url scheme. Default value is `https`
    ///     - host: the target server of your intended requests
    ///     - sessionConfig: types of url sessions. To learn more visit: `https://developer.apple.com/documentation/foundation/urlsession`
    public init(_ scheme: Scheme = .HTTPS, host: String, sessionConfig: URLSessionConfiguration = .default) {
        self.scheme = scheme
        self.host = host
        self.logger = Logger(subsystem: "com.josephlabs.hermes", category: "hermes")
        self.session = URLSession(configuration: sessionConfig)
    }
    
    /// Creates an HTTP request
    ///
    /// This function creates an asynchrous network call to your desired host + endpoint
    /// you can specify the requests through the headers dictionary and more.
    ///
    /// - Parameters:
    ///    - endpoint: path values and query parameters
    ///    - method: http method enum type
    ///    - body: body of the the request, a Data object
    ///    - headers: a dictionary of headers if you want to overrite or add to your requests
    ///
    /// - Throws: `NetworkError` if the response is not postive or if any errors occured.
    ///
    /// - Returns: (`Data`, `UrlRespone`) the response data and the response headers
    public func Request(_ method:Method, _ endpoint: Endpoint, body:Data? = nil, headers: [String:String]?=nil) async throws -> (Data, URLResponse) {
        
        // construct request url
        var urlComp = URLComponents()
        switch (scheme) {
        case .HTTP:
            urlComp.scheme = "http"
        case .HTTPS:
            urlComp.scheme = "https"
        }
        
        let hostValues = splitHostName(host)
        if hostValues.count > 1 {
            urlComp.host = hostValues[0]
            urlComp.port = Int(hostValues[1])
        } else {
            urlComp.host = hostValues[0]
        }
        
        urlComp.path = endpoint.path
        urlComp.queryItems = endpoint.queryItems
        
        // create url
        guard let url = urlComp.url else {
            throw NetworkError.invalidURL
        }
        
        // create url request object
        var request = URLRequest(url: url)
        
        switch (method) {
        case .GET:
            request.httpMethod = "GET"
        case .POST:
            request.httpMethod = "POST"
            request.httpBody = body
        case .PUT:
            request.httpMethod = "PUT"
            request.httpBody = body
        case .DELETE:
            request.httpMethod = "DELETE"
        }
        
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        request.setValue(accept, forHTTPHeaderField: "Accept")
        request.setValue(connection, forHTTPHeaderField: "Connection")
        if let extras = headers { // load in extra headers or overrite them
            for(header, value) in extras {
                request.setValue(value, forHTTPHeaderField: header)
            }
        }
        
        // log request
        logger.log("Making a \(request.httpMethod ?? "METHOD") request to \(url)")

        // make request
        let (data, response) = try await _request(r: request)
        return (data, response)
    }
    
    /// Creates a data upload request
    ///
    /// This function is aschrounous and can upload any data type.
    /// You can specify the data type throught the parameters.
    ///
    /// - Parameters:
    ///    - endpoint: path values and query parameters
    ///    - fileName: name of the data
    ///    - fileType: file type of the data being uploaded
    ///    - data: data to upload
    ///
    /// - Throws: `NetworkError` if the response is not postive or if any errors occured.
    public func Upload(endpoint: Endpoint, fileName: String, fileType: FileType, data: Data, headers: [String:String]?=nil) async throws -> (Data, URLResponse) {
        
        // construct request url
        var urlComp = URLComponents()
        switch (scheme) {
        case .HTTP:
            urlComp.scheme = "http"
        case .HTTPS:
            urlComp.scheme = "https"
        }
        
        let hostValues = splitHostName(host)
        if hostValues.count > 1 {
            urlComp.host = hostValues[0]
            urlComp.port = Int(hostValues[1])
        } else {
            urlComp.host = hostValues[0]
        }
        
        urlComp.path = endpoint.path
        
        // create url
        guard let url = urlComp.url else {
            throw NetworkError.invalidURL
        }
        
        // create url request object
        var request = URLRequest(url: url)
        
        // request values
        request.httpMethod = "POST"
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue(accept, forHTTPHeaderField: "Accept")
        request.setValue(connection, forHTTPHeaderField: "Connection")
        request.setValue(fileName, forHTTPHeaderField: "f")
        request.httpBody = data
        
        switch(fileType){
        case .JPG, .JPEG:
            request.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")
        case .HEIC:
            request.setValue("image/heic", forHTTPHeaderField: "Content-Type")
        case .PNG:
            request.setValue("image/png", forHTTPHeaderField: "Content-Type")
        case .WEBP:
            request.setValue("image/webp", forHTTPHeaderField: "Content-Type")
        case .MP3:
            request.setValue("audio/mpeg", forHTTPHeaderField: "Content-Type")
        case .WEBA:
            request.setValue("audio/webm", forHTTPHeaderField: "Content-Type")
        case .MP4:
            request.setValue("video/mp4", forHTTPHeaderField: "Content-Type")
        case .WEBM:
            request.setValue("video/webm", forHTTPHeaderField: "Content-Type")
        default:
            request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        }
        if let extras = headers { // set extra headers or override one
            for(header, value) in extras {
                request.setValue(value, forHTTPHeaderField: header)
            }
        }
        
        // log request
        logger.log("Making a \(request.httpMethod ?? "POST") request to \(url)")
    
        // update variable on main thread
        DispatchQueue.main.async {
            self.isUploading = true
        }
        
        // upload task
        let (data, response) = try await _upload(r: request)
        return (data, response)
    }
    
    /// Performs an HTTP request
    /// - Parameter r:`URLRequest` url request to perform
    private func _request(r: URLRequest) async throws -> (Data, URLResponse) {
        do {
            
            // do request
            let (data, resp) = try await self.session.data(for: r)
            
            // throw error if response status not under 299
            guard (resp as? HTTPURLResponse)!.statusCode <= 299 else {
                throw NetworkError.serverError(statusCode: (resp as? HTTPURLResponse)!.statusCode)
            }
            
            return (data, resp) // return data/response
            
        } catch {
            // convert error to Network Error
            let err =  _handleHttpError(error: error)
            throw err
        }
    }
    
    /// Perform an HTTP request to upload data
    /// - Parameter r:`URLRequest` url request to perform
    private func _upload(r: URLRequest) async throws -> (Data, URLResponse) {
        do {
            
            // do request
            let (data, resp) = try await self.session.data(for: r)
            
            // throw error if response status not under 299
            guard (resp as? HTTPURLResponse)!.statusCode <= 299 else {
                throw NetworkError.serverError(statusCode: (resp as? HTTPURLResponse)!.statusCode)
            }
            
            return (data, resp) // return data/response
            
        } catch {
            // convert error to Network Error
            let err =  _handleHttpError(error: error)
            throw err
        }
    }
    
    /// Handle our custom error NetworkErrhor
    /// - Parameter error:`Error` error to handle
    private func _handleHttpError(error: Error) -> NetworkError {
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet:
                return NetworkError.notConnectedToInternet
            case .timedOut:
                return NetworkError.timedOut
            case .cannotConnectToHost:
                return NetworkError.cannotConnectToHost(error)
            default:
                return NetworkError.unknown(error)
            }
        } else if let err = error as? NetworkError {
            return err
        } else {
            return NetworkError.unknown(error)
        }
    }
}


@available(iOS 15.0, *)
@available(macOS 13.0, *)
extension Courrier: URLSessionTaskDelegate, URLSessionDataDelegate {
    
    /// To keep track of how many bytes are being sent, and using it to calculate percatage of upload completion.
    /// Uses main thread to update upload progress value
    public func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        let progress = CGFloat(totalBytesSent) / CGFloat(totalBytesExpectedToSend)
        DispatchQueue.main.async {
            self.uploadProgress = progress
        }
    }
    
    /// To keep track of upload completion
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        self.isUploading = false
        self.uploadProgress = 1.0
    }
}

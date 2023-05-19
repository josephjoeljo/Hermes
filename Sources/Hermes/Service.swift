//
//  File.swift
//  
//
//  Created by Noko Anubis on 4/8/23.
//

import os
import Combine
import SwiftUI
import Foundation

@available(macOS 13.0, *)
@available(iOS 15.0, *)
public class Courrier: NSObject, ObservableObject, URLSessionDelegate {
    
    var host:String
    var apiKey: String?
    var token:String?
    var scheme: String
    
    private let logger:Logger
    private let session: URLSession
   
    var userAgent: String = "hermes-ios"
    var contentType: String = "application/json"
    var accept: String = "application/json"
    var connection: String = "close"
    
    @Published public var uploadProgress: Double = 0.0
    @Published private var isUploading = false
    
    public init(scheme: String = "https", host: String, apiKey: String?=nil, token: String?=nil) {
        self.scheme = scheme
        self.host = host
        self.apiKey = apiKey
        self.token = token
        self.logger = Logger(subsystem: "com.josephlabs.hermes", category: "hermes")
        self.session = URLSession(configuration: URLSessionConfiguration.default)
    }
    
    /// Handle our custom errro NetworkError
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
    
    /// Perform an HTTP request
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
    
    /// Creates an HTTP request
    ///
    /// This function is asynchronous and can create any request
    /// you can specify the requests through the headers dictionary and more.
    ///
    /// - Parameters:
    ///    - endpoint: path values and query parameters
    ///    - method: http method enum type
    ///    - body: body of the the request, a Data object
    ///    - headers: dictionary of headers if you want to overrite or add them
    ///
    /// - Throws: `NetworkError` if the response is not postive or if any errors occured.
    ///
    /// - Returns: (`Data`, `UrlRespone`) the response data and the response headers
    public func Request(endpoint: Endpoint, method:Method, body:Data? = nil, headers: [String:String]?=nil) async throws -> (Data, URLResponse) {
        
        // construct request url
        var urlComp = URLComponents()
        urlComp.scheme = scheme
        urlComp.host = host
        urlComp.path = endpoint.path
        urlComp.queryItems = endpoint.queryItems
        
        // create url
        guard let url = urlComp.url else {
            throw NetworkError.invalidURL
        }
        
        // create url request object
        var request = URLRequest(url: url)
        
        if (method == Method.GET) {
            request.httpMethod = "GET"
        } else if (method == Method.POST) {
            request.httpMethod = "POST"
            request.httpBody = body
        } else if (method == Method.PUT) {
            request.httpMethod = "PUT"
            request.httpBody = body
        } else if (method == Method.DELETE) {
            request.httpMethod = "DELETE"
        }
        
        // request parameters
        if let key = apiKey {
            request.setValue(key, forHTTPHeaderField: "api-key")
        }
        if let tkn = token {
            request.setValue(tkn, forHTTPHeaderField: "Authorization")
        }
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        request.setValue(accept, forHTTPHeaderField: "Accept")
        request.setValue(connection, forHTTPHeaderField: "Connection")
        if let extras = headers {
            for(header, value) in extras {
                request.setValue(value, forHTTPHeaderField: header)
            }
        }
        
        // log request
        logger.log("Making a \(request.httpMethod!) request to \(url)")

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
    ///    - fileName: string of the file name
    ///    - fileType: file type to extend the file by
    ///    - contentType: url request content type
    ///    - data: data to upload
    ///
    /// - Throws: `NetworkError` if the response is not postive or if any errors occured.
    public func Upload(endpoint: Endpoint, fileName: String, fileType: String, contentType: String, data: Data ) async throws -> (Data, URLResponse) {
        
        // construct request url
        var urlComp = URLComponents()
        urlComp.scheme = scheme
        urlComp.host = host
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
        request.setValue(fileName+fileType, forHTTPHeaderField: "X-Filename")
        request.httpBody = data
        
        switch(fileType){
        case ".jpeg":
            request.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")
        case ".heic":
            request.setValue("image/heic", forHTTPHeaderField: "Content-Type")
        default:
            request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        }
    
        
        // log request
        logger.log("Making a \(request.httpMethod!) request to \(url)")
    
        // update variable on main thread
        DispatchQueue.main.async {
            self.isUploading = true
        }
        
        // upload task
        let (data, response) = try await _upload(r: request)
        return (data, response)
    }
    
    /// Perform an HTTP request
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
}


@available(iOS 15.0, *)
@available(macOS 13.0, *)
extension Courrier: URLSessionTaskDelegate, URLSessionDataDelegate {
    
    /**
     To keep track of how many bytes are being sent, and using it to calculate percatage of upload completion.
     Uses main thread to update upload progress value
     */
    public func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        let progress = CGFloat(totalBytesSent) / CGFloat(totalBytesExpectedToSend)
        DispatchQueue.main.async {
            self.uploadProgress = progress
        }
    }
    
    /**
     To keep track of upload completion
     */
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        self.isUploading = false
        self.uploadProgress = 1.0
    }
}

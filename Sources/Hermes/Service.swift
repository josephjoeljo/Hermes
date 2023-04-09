//
//  File.swift
//  
//
//  Created by Noko Anubis on 4/8/23.
//

import os
import SwiftUI
import Foundation

@available(iOS 14.0, *)
public class Courrier: ObservableObject {
    
    var host:String
    var apiKey: String?
    var token:String?
    
    private let logger:Logger
    private let session: URLSession
   
    var userAgent: String = "hermes-ios"
    var contentType: String = "application/json"
    var accept: String = "application/json"
    var connection: String = "close"
    
    public init(host: String, apiKey: String?=nil, token: String?=nil) {
        self.host = host
        self.apiKey = apiKey
        self.token = token
        self.logger = Logger(subsystem: "com.joeljoseph.hermes", category: "hermes")
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
    /// - Parameter endpoint:`Endpoint` path values and query parameters
    /// - Parameter method: `Method` http method enum type
    /// - Parameter body: `Data` body of the the request, a Data object
    public func Request(endpoint: Endpoint, method:Method, body:Data? = nil) async throws -> (Data, URLResponse) {
        
        // construct request url
        var urlComp = URLComponents()
        urlComp.scheme = "https"
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
        
        // log request
        logger.log("Making a \(request.httpMethod!) request to \(url)")

        // make request
        let (data, response) = try await _request(r: request)
        return (data, response)
    }
}



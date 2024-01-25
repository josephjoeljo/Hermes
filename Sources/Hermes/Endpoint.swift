//
//  File.swift
//  
//
//  Created by Noko Anubis on 4/8/23.
//

import Foundation

/// Endpoint Class
///
/// This class helps us wrap up the path of our individual requests
public class Endpoint {
    public let path: String
    public let queryItems: [URLQueryItem]?
    
    /// Initalizer function for the endpoint class
    ///
    /// - Parameters:
    ///     - path: a `string` of your url path
    ///     - queryItems: an array of `URLQueryItem` to add to your url path
    public init(_ path: String, queryItems:[URLQueryItem]?=nil){
        self.path = path
        self.queryItems = queryItems
    }
}

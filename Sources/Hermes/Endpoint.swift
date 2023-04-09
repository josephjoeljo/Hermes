//
//  File.swift
//  
//
//  Created by Noko Anubis on 4/8/23.
//

import Foundation

public class Endpoint {
    public let path: String
    public let queryItems: [URLQueryItem]?
    
    public init(path: String, queryItems:[URLQueryItem]?=nil){
        self.path = path
        self.queryItems = queryItems
    }
}

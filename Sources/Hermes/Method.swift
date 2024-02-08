//
//  File.swift
//  
//
//  Created by Noko Anubis on 4/8/23.
//

import Foundation

/// Http method enum
///
/// We use this enum to specify the method of our http request
public enum Method {
    case GET
    case HEAD
    case POST
    case PUT
    case DELETE
    case CONNECT
    case OPTIONS
    case TRACE
    case PATCH
}

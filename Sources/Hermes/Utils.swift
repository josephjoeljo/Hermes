//
//  File.swift
//  
//
//  Created by Joel on 1/25/24.
//

import Foundation

/// Splits a host name
///
/// If a hostname string contains a colon for a port number we will split it and return an array containing the string values
/// 
/// If the host name does not contain a colon then we return the string as the only index in the array
///
/// - Returns
///    - an array containing the host string split [host, port]
func splitHostName(_ string: String) -> [String] {
    guard let index = string.firstIndex(of: ":") else {
        return [string]
    }
    
    let host = String(string[..<index])
    let port = String(string[index..<string.endIndex])
    return [host, String(port.dropFirst())]
}

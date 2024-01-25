//
//  File.swift
//  
//
//  Created by Noko Anubis on 4/8/23.
//

import Foundation

/// Errors thrown by the Courrier
///
/// You can use the localized description variable to get a better understanding of the error
public enum NetworkError: Error {
    case serverError(statusCode: Int)
    case invalidURL
    case timedOut
    case cannotConnectToHost(Error)
    case notConnectedToInternet
    case unknown(Error)
}

extension NetworkError: LocalizedError {
    var localizedDescription: String {
        switch self {
        case .timedOut:
            return NSLocalizedString("request timed out", comment: "")
        case .invalidURL:
            return NSLocalizedString("invalid url", comment: "")
        case .serverError(let statusCode):
            return NSLocalizedString("server error - \(statusCode)", comment: "check the status code")
        case .cannotConnectToHost(let error):
            return NSLocalizedString("cannot connect to host - \(error.localizedDescription)", comment: "")
        case .notConnectedToInternet:
            return NSLocalizedString("not connected to the internet", comment: "")
        case .unknown(let error):
            return NSLocalizedString("unexpected error - \(error.localizedDescription)", comment: "check error for details")
        }
    }
}

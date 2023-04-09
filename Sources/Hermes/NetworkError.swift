//
//  File.swift
//  
//
//  Created by Noko Anubis on 4/8/23.
//

import Foundation

enum NetworkError: Error {
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
        case .serverError:
            return NSLocalizedString("server error", comment: "check the status code")
        case .cannotConnectToHost:
            return NSLocalizedString("cannot connect to host", comment: "")
        case .notConnectedToInternet:
            return NSLocalizedString("not connected to the internet", comment: "")
        case .unknown:
            return NSLocalizedString("unknown error", comment: "check error for details")
        }
    }
}

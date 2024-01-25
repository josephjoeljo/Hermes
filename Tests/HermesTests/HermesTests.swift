import XCTest
@testable import Hermes

final class HermesTests: XCTestCase {
    
    /// Make sure we can send a delete get request
    func testGetRequest() async throws {
        let service = Courrier(.HTTPS, host: "httpbin.org")
        let endpoint = Endpoint("/get")
        let (_, resp) = try await service.Request(.GET, endpoint)
        guard let code = (resp as? HTTPURLResponse)?.statusCode else {
            return
        }
        
        XCTAssertEqual(code, 200, "Response code was not OK")
    }
    
    /// Make sure we can send a post http request
    func testPostRequest() async throws {
        let service = Courrier(.HTTPS, host: "httpbin.org")
        let endpoint = Endpoint("/post")
        let (_, resp) = try await service.Request(.POST, endpoint)
        guard let code = (resp as? HTTPURLResponse)?.statusCode else {
            return
        }
        
        XCTAssertEqual(code, 200, "Response code was not OK")
    }
    
    /// Make sure we can send a put http request
    func testPutRequest() async throws {
        let service = Courrier(.HTTPS, host: "httpbin.org")
        let endpoint = Endpoint("/put")
        let (_, resp) = try await service.Request(.PUT, endpoint)
        guard let code = (resp as? HTTPURLResponse)?.statusCode else {
            return
        }
        
        XCTAssertEqual(code, 200, "Response code was not OK")
    }
    
    /// Make sure we can send a delete http request
    func testDeleteRequest() async throws {
        let service = Courrier(.HTTPS, host: "httpbin.org")
        let endpoint = Endpoint("/delete")
        let (_, resp) = try await service.Request(.DELETE, endpoint)
        guard let code = (resp as? HTTPURLResponse)?.statusCode else {
            return
        }
        
        XCTAssertEqual(code, 200, "Response code was not OK")
    }
    
    /// Make sure we can send an http get request with a url query
    func testGetRequestQueries() async throws {
        let queryName = "hermes"
        let queryValue = "test"
        let service = Courrier(.HTTPS, host: "httpbin.org")
        let endpoint = Endpoint("/get", queryItems: [URLQueryItem(name: queryName, value: queryValue)])
        let (_, resp) = try await service.Request(.GET, endpoint)
        guard let code = (resp as? HTTPURLResponse)?.statusCode else {
            return
        }
        guard let header = (resp as? HTTPURLResponse)?.value(forHTTPHeaderField: queryName) else {
            return
        }
        
        XCTAssertEqual(code, 200, "Response code was not OK")
        XCTAssertEqual(header, queryValue, "Failed to find header")
    }
    
    /// Make sure we can send an http get request with a url query
    func testGetCustomHeader() async throws {
        let headerName = "hermes"
        let headerValue = "test"
        let service = Courrier(.HTTPS, host: "httpbin.org")
        let endpoint = Endpoint("/get")
        let (_, resp) = try await service.Request(.GET, endpoint, headers: [headerName: headerValue])
        guard let code = (resp as? HTTPURLResponse)?.statusCode else {
            return
        }
        guard let header = (resp as? HTTPURLResponse)?.value(forHTTPHeaderField: headerName) else {
            return
        }
        
        XCTAssertEqual(code, 200, "Response code was not OK")
        XCTAssertEqual(header, headerValue, "Failed to find header")
    }
    
    func testBadRequest() async throws {
        let service = Courrier(.HTTPS, host: "httpbin.org")
        let endpoint = Endpoint("/status/undefined")
        do {
            let (_, _) = try await service.Request(.GET, endpoint)
        } catch {
            let e = error as! NetworkError
            XCTAssertEqual(e.localizedDescription, NetworkError.serverError(statusCode: 400).localizedDescription)
        }
    }
    
    func testBadURL() async throws {
        let service = Courrier(.HTTPS, host: "0")
        let endpoint = Endpoint("/get")
        do {
            let (_, _) = try await service.Request(.GET, endpoint)
        } catch {
            let e = error as! NetworkError
            XCTAssertEqual(e.localizedDescription, "unexpected error - bad URL")
        }
    }
    
    func testHostWithPort() async throws {
        let service = Courrier(.HTTPS, host: "localhost:81")
        let endpoint = Endpoint("/get")
        do {
            let (_, _) = try await service.Request(.GET, endpoint)
        } catch {
            let e = error as! NetworkError
            XCTAssertEqual(e.localizedDescription, "cannot connect to host - Could not connect to the server.")
        }
    }
    
    
    func testSplittingHostname() async throws {
        let host = "localhost:8080"
        let values = splitHostName(host)
        XCTAssert(values.count > 1)
        XCTAssertEqual(values[0], "localhost")
        XCTAssertEqual(values[1], "8080")
    }
    
    func testNotSplittingHostname() async throws {
        let host = "localhost"
        let values = splitHostName(host)
        XCTAssert(values.count == 1)
        XCTAssertEqual(values[0], "localhost")
    }
}

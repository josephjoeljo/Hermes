import XCTest
@testable import Hermes

final class HermesTests: XCTestCase {
    
    func testGetRequest() async throws {
        let service = Courrier(scheme: "https", host: "httpbin.org")
        let endpoint = Endpoint(path: "/get")
        let (_, resp) = try await service.Request(endpoint: endpoint, method: .GET)
        guard let code = (resp as? HTTPURLResponse)?.statusCode else {
            return
        }
        
        XCTAssertEqual(code, 200, "Response code was not OK")
    }
    
    func testPostRequest() async throws {
        let service = Courrier(scheme: "https", host: "httpbin.org")
        let endpoint = Endpoint(path: "/post")
        let (_, resp) = try await service.Request(endpoint: endpoint, method: .POST)
        guard let code = (resp as? HTTPURLResponse)?.statusCode else {
            return
        }
        
        XCTAssertEqual(code, 200, "Response code was not OK")
    }
    
    func testPutRequest() async throws {
        let service = Courrier(scheme: "https", host: "httpbin.org")
        let endpoint = Endpoint(path: "/put")
        let (_, resp) = try await service.Request(endpoint: endpoint, method: .PUT)
        guard let code = (resp as? HTTPURLResponse)?.statusCode else {
            return
        }
        
        XCTAssertEqual(code, 200, "Response code was not OK")
    }
    
    func testDeleteRequest() async throws {
        let service = Courrier(scheme: "https", host: "httpbin.org")
        let endpoint = Endpoint(path: "/delete")
        let (_, resp) = try await service.Request(endpoint: endpoint, method: .DELETE)
        guard let code = (resp as? HTTPURLResponse)?.statusCode else {
            return
        }
        
        XCTAssertEqual(code, 200, "Response code was not OK")
    }
}

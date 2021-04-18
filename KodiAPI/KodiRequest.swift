//
//  InputRequest.swift
//  KodiAPI
//
//  Created by Pavel Prokofyev on 2/12/18.
//  Copyright © 2018 Pavel Prokofyev. All rights reserved.
//

import Foundation
import APIKit

protocol DecodableFromResponse {
    init(from e: Any) throws
}

public struct PlayerId: DecodableFromResponse {
    let id: Int
    
    init(from e: Any) throws {
        guard let dict = e as? [String: Any],
            let id = dict["playerid"] as? Int
            else { throw KodiError.UnexpectedResponse }
        
        self.id = id
    }
}

public struct PlayerSpeed: DecodableFromResponse {
    let speed: Int
    
    init(from e: Any) throws {
        guard let dict = e as? [String: Any] else { throw KodiError.UnexpectedResponse }
        
        if let result = dict["result"] as? [String: Any] {
            self.speed = result["speed"] as! Int
            return
        } else if (dict["error"] != nil) {
            // Do nothing, player just not ready
            self.speed = 0
            return
        }

        throw KodiError.UnexpectedResponse
    }
}

extension String: DecodableFromResponse {
    init(from e: Any) throws {
        guard let dict = e as? [String: Any], let result = dict["result"] as? String
            else { throw KodiError.UnexpectedResponse }
        
        self = result
    }
}

extension Array: DecodableFromResponse where Iterator.Element: DecodableFromResponse {
    init(from e: Any) throws {
        guard let dict = e as? [String: Any],
            let items = dict["result"] as? [Any]
            else { throw KodiError.UnexpectedResponse }
        
        try self = items.map { try Element.init(from: $0) }
    }
}

protocol KodiRequestProtocol: Request {}

class KodiRequest<T: DecodableFromResponse>: KodiRequestProtocol {
    typealias Response = T
    func response(from object: Any, urlResponse: HTTPURLResponse) throws -> Response {
        return try Response.init(from: object)
    }
    
    private let host: KodiHost
    private var params: [String: Any] = ["jsonrpc": "2.0"]
    
    var baseURL: URL {
        var authPart = !host.user.isEmpty ? host.user : ""
        if (!authPart.isEmpty) {
            authPart += !host.pass.isEmpty ? ":" + host.pass : ""
            authPart += "@"
        }
        
        return URL(string: "http://\(authPart)\(host.serverIp):\(host.serverPort)")!
    }
    
    init(_ host: KodiHost) {
        self.host = host
    }
    
    var parameters: Any? {
        return params
    }
    
    func setParam(_ name: String, value: Any) {
        params[name] = value
    }
    
    func getParam(_ name: String) -> Any? {
        return params[name]
    }
    
    var method: HTTPMethod {
        return .post
    }
    
    var path: String {
        return "/jsonrpc"
    }
    
    var headerFields: [String: String] {
        return ["Content-Type": "application/json"]
    }
}

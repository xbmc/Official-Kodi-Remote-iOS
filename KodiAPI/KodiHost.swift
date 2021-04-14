//
//  KodiHost.swift
//  watchapp Extension
//
//  Created by Pavel Prokofyev on 2/11/18.
//  Copyright © 2018 Pavel Prokofyev. All rights reserved.
//

import Foundation

@objc public class KodiHost: NSObject, Codable {
    public let name: String
    public let user: String
    public let pass: String
    public let serverIp: String
    private let serverPortStr: String
    
    var serverPort: Int {
        return Int(serverPortStr) ?? 8080
    }

    private enum CodingKeys: String, CodingKey {
        case name = "serverDescription"
        case serverIp = "serverIP"
        case user = "serverUser"
        case pass = "serverPass"
        case serverPortStr = "serverPort"
    }
    
    static public func create(fromDict dict: [String: Any]) -> KodiHost? {
        guard let json = try? JSONSerialization.data(withJSONObject: dict)
        else { return nil }

        return decode(fromJson: json)
    }

    @objc public static func decode(fromJson data: Data) -> KodiHost? {
        return try? JSONDecoder().decode(KodiHost.self, from: data)
    }
}

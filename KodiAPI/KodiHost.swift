//
//  KodiHost.swift
//  watchapp Extension
//
//  Created by Pavel Prokofyev on 2/11/18.
//  Copyright © 2018 Pavel Prokofyev. All rights reserved.
//

import Foundation

@objc public class KodiHost: NSObject, Codable {
    public var name: String
    public var user: String = ""
    public var pass: String = ""
    public var serverIp: String
    private var serverPortStr: String
    
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
        do {
            return decode(fromJson: try JSONSerialization.data(withJSONObject: dict))
        } catch {
            return nil
        }
    }

    @objc public static func decode(fromJson data: Data) -> KodiHost? {
        do {
            return try JSONDecoder().decode(KodiHost.self, from: data)
        }  catch {
            return nil
        }
    }
}

//
//  KodiAPI.swift
//  KodiAPI
//
//  Created by Pavel Prokofyev on 2/12/18.
//  Copyright © 2018 Pavel Prokofyev. All rights reserved.
//

import Foundation
import APIKit
import WatchConnectivity

@objc public protocol KodiAPIDelegate {
    func kodiApi(_ api: KodiAPI, response: Any)
    func kodiApi(_ api: KodiAPI, error: Error)
}

@objc public class KodiAPI: NSObject {
    @objc public static let WatchHostsKey = "WatchHosts"

    public let host: KodiHost
    @objc public var delegate: KodiAPIDelegate?
    public var session: WCSession?
    
    @objc public init(host: KodiHost) {
        self.host = host
    }
    func createRequest<T>(method name:String, args: [String: Any] = [:]) -> KodiRequest<T> {
        let request = KodiRequest<T>(host)
        request.setParam("method", value: name)
        request.setParam("id", value: arc4random())
        request.setParam("params", value: args)
        return request
    }
    
    private func sendInternal<T, R: KodiRequest<T>>(_ request: R, handler: @escaping (Result<T, SessionTaskError>) -> Void) {
        Session.send(request, handler: handler)
    }

    func send<T, R: KodiRequest<T>>(request: R) {
        sendInternal(request) { result in
            switch result {
            case .success(let res):
                self.delegate?.kodiApi(self, response: res)
                
            case .failure(let error):
                self.delegate?.kodiApi(self, error: error)
            }
        }
    }
}

@objc public extension KodiAPI {
    enum InputMethods: String {
        case Up = "Input.Up"
        case Down = "Input.Down"
        case Left = "Input.Left"
        case Right = "Input.Right"
        case Back = "Input.Back"
        case Menu = "Input.ShowOSD"
        case Select = "Input.Select"
    }
    
    enum PlayerMethods: String {
        case PlayPause = "Player.PlayPause"
        case Stop = "Player.Stop"
        case GetActivePlayers = "Player.GetActivePlayers"
    }
    
    @nonobjc private func callInput(method name: InputMethods) {
        self.send(request: self.createRequest(method: name.rawValue) as KodiRequest<String>)
    }
    
    func getActivePlayers() {
        let request: KodiRequest<[PlayerId]> = createRequest(method:
            PlayerMethods.GetActivePlayers.rawValue)
        self.send(request: request)
    }

    @nonobjc private func getActivePlayersInternal(_ handler: @escaping ([PlayerId]) -> Void) {
        let request: KodiRequest<[PlayerId]> = createRequest(method:
            PlayerMethods.GetActivePlayers.rawValue)
        self.sendInternal(request) {
            if case .success(let ids) = $0 {
                handler(ids)
            }
        }
    }
    
    func playPause() {
        getActivePlayersInternal() { playerIds in
            for playerId in playerIds {
                let request: KodiRequest<PlayerSpeed> =
                    self.createRequest(method: PlayerMethods.PlayPause.rawValue,
                                       args: ["playerid": playerId.id])
                self.send(request: request)
            }
        }
    }
    
    func stop() {
        getActivePlayersInternal() { playerIds in
            for playerId in playerIds {
                let request: KodiRequest<String> =
                    self.createRequest(method: PlayerMethods.Stop.rawValue,
                                       args: ["playerid": playerId.id])
                self.send(request: request)
            }
        }
    }
    
    func up() {
        callInput(method: .Up)
    }
    
    func down() {
        callInput(method: .Down)
    }
    
    func left() {
        callInput(method: .Left)
    }
    
    func right() {
        callInput(method: .Right)
    }
    
    func select() {
        callInput(method: .Select)
    }
    
    func back() {
        callInput(method: .Back)
    }
    
    func menu() {
        callInput(method: .Menu)
    }
    
    private func handleInput(_ name: String) -> Bool {
        guard let inputMethod = InputMethods.init(rawValue: name) else { return false }
        callInput(method: inputMethod)
        return true
    }
    
    private func handlePlayer(_ name: String) -> Bool {
        guard let playerMethod = PlayerMethods.init(rawValue: name) else { return false }
        
        switch playerMethod {
        case .PlayPause: playPause()
        case .Stop: stop()
        case .GetActivePlayers: break
        }
        
        return true
    }
    
    @discardableResult @objc func doAction(_ name: String) -> Bool {
        for method in [handleInput, handlePlayer] {
            if (method(name)) {
                return true
            }
        }
        
        return false
    }
}

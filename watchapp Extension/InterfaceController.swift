//
//  InterfaceController.swift
//  watchapp Extension
//
//  Created by Pavel Prokofyev on 2/10/18.
//  Copyright © 2018 Pavel Prokofyev. All rights reserved.
//

import WatchKit
import Foundation
import WatchConnectivity

class InterfaceController: WKInterfaceController, WCSessionDelegate  {
    let WatchHostsKey = KodiAPI.WatchHostsKey
    
    @IBOutlet var hostTable: WKInterfaceTable!
    @IBOutlet var emptyLabel: WKInterfaceLabel!
    
    var session : WCSession!
    
    var hosts = [KodiHost]()
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
    }
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]){
        updateContext(applicationContext)
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        updateContext(message)
    }
    
    func updateContext(_ context: [String: Any]) {
        guard let array = context[WatchHostsKey] as? [[String: Any]] else { return }
        
        UserDefaults.standard.setValue(array, forKey: WatchHostsKey)
        
        DispatchQueue.main.async {
            self.updateList()
        }
    }
    
    func updateList() {
        if let defaultHosts = UserDefaults.standard.array(forKey: WatchHostsKey) {
            hosts.removeAll()
            for defaultHostAny in defaultHosts {
                guard let defaultHost = defaultHostAny as? [String: Any],
                      let kodiHost = KodiHost.create(fromDict: defaultHost)
                else { continue }
                
                hosts.append(kodiHost)
            }
        }
        
        hostTable.setNumberOfRows(hosts.count, withRowType: "HostRow")
        for index in 0..<hostTable.numberOfRows {
            guard let row = hostTable.rowController(at: index) as? HostRowController else { continue }
            
            row.host = hosts[index]
        }
        
        emptyLabel.setHidden(hosts.count != 0)
    }
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        session = WCSession.default
        session.delegate = self
        session.activate()
        
        updateList()
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

    override func table(_ table: WKInterfaceTable, didSelectRowAt rowIndex: Int) {
        if (table == hostTable) {
            let api = KodiAPI(host: hosts[rowIndex])
            api.session = session
            pushController(withName: "RemoteController", context: api)
        }
    }
}

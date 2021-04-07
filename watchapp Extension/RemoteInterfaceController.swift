//
//  RemoteInterfaceController.swift
//  watchapp Extension
//
//  Created by Pavel Prokofyev on 2/11/18.
//  Copyright © 2018 Pavel Prokofyev. All rights reserved.
//

import WatchKit
import Foundation

class RemoteInterfaceController: WKInterfaceController, KodiAPIDelegate {
    
    @IBOutlet var stopButton: WKInterfaceButton!
    @IBOutlet var upButton: WKInterfaceButton!
    @IBOutlet var ppButton: WKInterfaceButton!
    @IBOutlet var leftButton: WKInterfaceButton!
    @IBOutlet var enterButton: WKInterfaceButton!
    @IBOutlet var rightButton: WKInterfaceButton!
    @IBOutlet var backButton: WKInterfaceButton!
    @IBOutlet var downButton: WKInterfaceButton!
    @IBOutlet var menuButton: WKInterfaceButton!
    
    func kodiApi(_ api: KodiAPI, response: Any) {
        DispatchQueue.main.async {
            debugPrint("response: ", (response as? String) ?? (response as AnyObject).debugDescription!)
        }
    }
    
    func kodiApi(_ api: KodiAPI, error: Error) {
        DispatchQueue.main.async {
            debugPrint("error: ", error.localizedDescription)
        }
    }
    
    var api: KodiAPI?
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        if let api = context as? KodiAPI {
            self.api = api
            api.delegate = self
            setTitle(api.host.name)
        }
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    func genericClick(_ sender: WKInterfaceButton) {
        animate(withDuration: 0.2) {
            sender.setBackgroundColor(UIColor(red: 0, green: 122/255, blue: 1, alpha: 1))
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.animate(withDuration: 0.2) {
                    sender.setBackgroundColor(nil)
                }
            }
        }
        
        WKInterfaceDevice.current().play(.click)
    }

    @IBAction func stopButtonAction() {
        genericClick(stopButton)
        api?.stop()
    }
    
    @IBAction func upButtonAction() {
        genericClick(upButton)
        api?.up()
    }
    
    @IBAction func playPauseButtonAction() {
        genericClick(ppButton)
        api?.playPause()
    }
    
    @IBAction func leftButtonAction() {
        genericClick(leftButton)
        api?.left()
    }
    
    @IBAction func enterButtonAction() {
        genericClick(enterButton)
        api?.select()
    }
    
    @IBAction func rightButtonAction() {
        genericClick(rightButton)
        api?.right()
    }
    
    @IBAction func backButtonAction() {
        genericClick(backButton)
        api?.back()
    }
    
    @IBAction func downButtonAction() {
        genericClick(downButton)
        api?.down()
    }
    
    @IBAction func menuButtonAction() {
        genericClick(menuButton)
        api?.menu()
    }
}

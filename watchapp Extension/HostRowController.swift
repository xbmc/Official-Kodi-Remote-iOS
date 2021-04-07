//
//  HostRowController.swift
//  watchapp Extension
//
//  Created by Pavel Prokofyev on 2/11/18.
//  Copyright © 2018 Pavel Prokofyev. All rights reserved.
//

import WatchKit

class HostRowController: NSObject {
    @IBOutlet var nameLabel: WKInterfaceLabel!
    
    var host: KodiHost? {
        didSet {
            guard let host = host else { return }
            nameLabel.setText(host.name)
        }
    }
}

//
//  BaseMasterViewController.h
//  Kodi Remote
//
//  Created by Buschmann on 04.06.25.
//  Copyright © 2025 Team Kodi. All rights reserved.
//

#import "tcpJSONRPC.h"

@import UIKit;

@interface BaseMasterViewController : UIViewController

@property (strong, nonatomic) tcpJSONRPC *tcpJSONRPCconnection;

@end

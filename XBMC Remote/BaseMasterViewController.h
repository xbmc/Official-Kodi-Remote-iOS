//
//  BaseMasterViewController.h
//  Kodi Remote
//
//  Created by Buschmann on 04.06.25.
//  Copyright © 2025 Team Kodi. All rights reserved.
//

#import "TcpJSONRPC.h"
#import "ClearCacheView.h"

@import UIKit;

@interface BaseMasterViewController : UIViewController

- (void)changeServerStatus:(BOOL)status infoText:(NSString*)infoText icon:(NSString*)iconName;
- (void)handleXBMCServerHasChanged:(NSNotification*)sender;
- (void)connectionStatus:(NSNotification*)note;
- (void)enterAppSettings;
- (void)startClearAppDiskCache:(ClearCacheView*)clearView;

@property (strong, nonatomic) TcpJSONRPC *tcpJSONRPCconnection;

@end

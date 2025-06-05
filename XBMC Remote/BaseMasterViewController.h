//
//  BaseMasterViewController.h
//  Kodi Remote
//
//  Created by Buschmann on 04.06.25.
//  Copyright © 2025 Team Kodi. All rights reserved.
//

#import "tcpJSONRPC.h"
#import "ClearCacheView.h"

@import UIKit;

@interface BaseMasterViewController : UIViewController

- (void)changeServerStatus:(BOOL)status infoText:(NSString*)infoText icon:(NSString*)iconName;
- (void)handleXBMCServerHasChanged:(NSNotification*)sender;
- (void)startClearAppDiskCache:(ClearCacheView*)clearView;
- (void)addClearCacheMessage;

@property (strong, nonatomic) tcpJSONRPC *tcpJSONRPCconnection;

@end

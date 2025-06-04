//
//  BaseMasterViewController.m
//  Kodi Remote
//
//  Created by Buschmann on 04.06.25.
//  Copyright © 2025 Team Kodi. All rights reserved.
//

#import "BaseMasterViewController.h"

@implementation BaseMasterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleDidEnterBackground:)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
}

- (void)handleDidEnterBackground:(NSNotification*)sender {
    [self.tcpJSONRPCconnection stopNetworkCommunication];
}

@end

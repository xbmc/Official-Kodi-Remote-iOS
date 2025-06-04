//
//  BaseMasterViewController.m
//  Kodi Remote
//
//  Created by Buschmann on 04.06.25.
//  Copyright © 2025 Team Kodi. All rights reserved.
//

#import "BaseMasterViewController.h"
#import "AppDelegate.h"

@implementation BaseMasterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleDidEnterBackground:)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleEnterForeground:)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
}

- (void)handleDidEnterBackground:(NSNotification*)sender {
    [self.tcpJSONRPCconnection stopNetworkCommunication];
}

- (void)handleEnterForeground:(NSNotification*)sender {
    if (AppDelegate.instance.serverOnLine) {
        [self.tcpJSONRPCconnection startNetworkCommunicationWithServer:AppDelegate.instance.obj.serverRawIP serverPort:AppDelegate.instance.obj.tcpPort];
    }
}

@end

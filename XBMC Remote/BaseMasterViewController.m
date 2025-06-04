//
//  BaseMasterViewController.m
//  Kodi Remote
//
//  Created by Buschmann on 04.06.25.
//  Copyright © 2025 Team Kodi. All rights reserved.
//

#import "BaseMasterViewController.h"
#import "AppDelegate.h"
#import "Utilities.h"

#define CLEARCACHE_TIMEOUT 2.0

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
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleTcpJSONRPCChangeServerStatus:)
                                                 name:@"TcpJSONRPCChangeServerStatus"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleXBMCServerHasChanged:)
                                                 name:@"XBMCServerHasChanged"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleLibraryNotification:)
                                                 name:@"AudioLibrary.OnScanFinished"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleLibraryNotification:)
                                                 name:@"AudioLibrary.OnCleanFinished"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleLibraryNotification:)
                                                 name:@"VideoLibrary.OnScanFinished"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleLibraryNotification:)
                                                 name:@"VideoLibrary.OnCleanFinished"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleLocalNetworkAccessError:)
                                                 name:@"LocalNetworkAccessError"
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

- (void)handleTcpJSONRPCChangeServerStatus:(NSNotification*)sender {
    BOOL statusValue = [[sender.userInfo objectForKey:@"status"] boolValue];
    NSString *message = [sender.userInfo objectForKey:@"message"];
    NSString *icon_connection = [sender.userInfo objectForKey:@"icon_connection"];
    [self changeServerStatus:statusValue infoText:message icon:icon_connection];
}

- (void)changeServerStatus:(BOOL)status infoText:(NSString*)infoText icon:(NSString*)iconName {
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   infoText, @"message",
                                   iconName, @"icon_connection",
                                   nil];
    AppDelegate.instance.serverOnLine = status;
    AppDelegate.instance.serverName = infoText;
    NSString *notificationName;
    if (status) {
        [self.tcpJSONRPCconnection startNetworkCommunicationWithServer:AppDelegate.instance.obj.serverRawIP serverPort:AppDelegate.instance.obj.tcpPort];
        notificationName = @"XBMCServerConnectionSuccess";
        NSString *message = [NSString stringWithFormat:LOCALIZED_STR(@"Connected to %@"), AppDelegate.instance.obj.serverDescription];
        [Utilities showMessage:message color:SUCCESS_MESSAGE_COLOR];
    }
    else {
        [self.tcpJSONRPCconnection stopNetworkCommunication];
        notificationName = @"XBMCServerConnectionFailed";
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:nil userInfo:params];
    if (status) {
        // Send trigger to start the default controller
        [[NSNotificationCenter defaultCenter] postNotificationName:@"KodiStartDefaultController" object:nil userInfo:params];
    }
}

- (void)handleXBMCServerHasChanged:(NSNotification*)sender {
    [self changeServerStatus:NO infoText:LOCALIZED_STR(@"No connection") icon:@"connection_off"];
}

- (void)handleLibraryNotification:(NSNotification*)note {
    [Utilities showMessage:note.name color:SUCCESS_MESSAGE_COLOR];
}

- (void)handleLocalNetworkAccessError:(NSNotification*)sender {
    [Utilities showLocalNetworkAccessError:self];
}

#pragma mark - App clear disk cache methods

- (void)startClearAppDiskCache:(ClearCacheView*)clearView {
    [AppDelegate.instance clearAppDiskCache];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, CLEARCACHE_TIMEOUT * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self clearAppDiskCacheFinished:clearView];
    });
}

- (void)clearAppDiskCacheFinished:(ClearCacheView*)clearView {
    [UIView animateWithDuration:0.3
                     animations:^{
        [clearView stopActivityIndicator];
        clearView.alpha = 0;
    }
                     completion:^(BOOL finished) {
        [clearView stopActivityIndicator];
        [clearView removeFromSuperview];
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        [userDefaults removeObjectForKey:@"clearcache_preference"];
    }];
}

@end

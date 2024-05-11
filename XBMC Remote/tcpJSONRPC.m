//
//  tcpJSONRPC.m
//  XBMC Remote
//
//  Created by Giovanni Messina on 22/11/12.
//  Copyright (c) 2012 joethefox inc. All rights reserved.
//

#import "tcpJSONRPC.h"
#import "AppDelegate.h"
#import "Utilities.h"
#import "VersionCheck.h"

#define SERVER_TIMEOUT 3.0
#define MRMC_TIMEWARP 14.0

NSInputStream	*inStream;
//  NSOutputStream	*outStream;
//	CFWriteStreamRef writeStream;

@implementation tcpJSONRPC

- (id)init {
    if (self = [super init]) {
        infoTitle = @"";
        heartbeatTimer = [NSTimer scheduledTimerWithTimeInterval:SERVER_TIMEOUT target:self selector:@selector(checkServer) userInfo:nil repeats:YES];
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(handleSystemOnSleep:)
                                                     name: @"System.OnSleep"
                                                   object: nil];
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(handleEnterForeground:)
                                                     name: @"UIApplicationWillEnterForegroundNotification"
                                                   object: nil];
        
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(handleDidEnterBackground:)
                                                     name: @"UIApplicationDidEnterBackgroundNotification"
                                                   object: nil];
    }
    return self;
}

- (void)handleSystemOnSleep:(NSNotification*)sender {
    AppDelegate.instance.serverTCPConnectionOpen = NO;
}

- (void)handleDidEnterBackground:(NSNotification*)sender {
    [heartbeatTimer invalidate];
}

- (void)handleEnterForeground:(NSNotification*)sender {
    heartbeatTimer = [NSTimer scheduledTimerWithTimeInterval:SERVER_TIMEOUT target:self selector:@selector(checkServer) userInfo:nil repeats:YES];
}

- (void)startNetworkCommunicationWithServer:(NSString*)server serverPort:(int)port {
    if (port == 0) {
        port = 9090;
    }
    if (!server.length) {
        return;
    }
    CFReadStreamRef readStream;
    CFStreamCreatePairWithSocketToHost(NULL, (CFStringRef)CFBridgingRetain(server), port, &readStream, NULL);
    inStream = (__bridge NSInputStream*)readStream;
    //	outStream = (__bridge NSOutputStream*)writeStream;
    inStream.delegate = self;
    //	outStream.delegate = self;
    [inStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    //	[outStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [inStream open];
    //	[outStream open];
    CFRelease((__bridge CFTypeRef)server);
}

- (NSStreamStatus)currentSocketInStatus {
    return [inStream streamStatus];
}

- (void)stopNetworkCommunication {
    AppDelegate.instance.serverTCPConnectionOpen = NO;
    NSStreamStatus current_status = [inStream streamStatus];
    if (current_status == NSStreamStatusOpen) {
        [inStream close];
        [inStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        inStream.delegate = nil;
        inStream = nil;
    }
}

- (void)stream:(NSStream*)theStream handleEvent:(NSStreamEvent)streamEvent {

    switch (streamEvent) {

        case NSStreamEventOpenCompleted:
            AppDelegate.instance.serverTCPConnectionOpen = YES;
            [self tcpConnectionNotifications:YES];
            break;
            
        case NSStreamEventHasBytesAvailable:
            if (theStream == inStream) {
                uint8_t buffer[1024];
                int len;
                while ([inStream hasBytesAvailable]) {
                    len = (int)[inStream read:buffer maxLength:sizeof(buffer)];
                    if (len > 0) {
                        NSData *output = [[NSData alloc] initWithBytes:buffer length:len];
                        if (nil != output) {
                            NSError *parseError = nil;
                            NSDictionary *notification = [NSJSONSerialization JSONObjectWithData:output options:kNilOptions error:&parseError];
                            if (parseError == nil) {
                                if (notification[@"method"] && notification[@"method"] != [NSNull null]) {
                                    NSString *method = notification[@"method"];
                                    NSDictionary *params;
                                    if (notification[@"params"] && notification[@"params"] != [NSNull null]) {
                                        params = @{@"params": notification[@"params"]};
                                    }
                                    [[NSNotificationCenter defaultCenter] postNotificationName:method object:nil userInfo:params];
                                }
                            }
                        }
                    }
                }
            }
            break;
            
        case NSStreamEventErrorOccurred:
            AppDelegate.instance.serverTCPConnectionOpen = NO;
            inCheck = NO;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"tcpJSONRPCConnectionError" object:nil userInfo:nil];
            break;

        case NSStreamEventEndEncountered:
            AppDelegate.instance.serverTCPConnectionOpen = NO;
            inCheck = NO;
            [theStream close];
            [theStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
            theStream.delegate = nil;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"tcpJSONRPCConnectionClosed" object:nil userInfo:nil];
            [self tcpConnectionNotifications:NO];
            break;
        default:
            break;
    }
}

- (void)tcpConnectionNotifications:(BOOL)hasTcpConnection {
    NSString *connectionIcon = hasTcpConnection ? @"connection_on" : @"connection_on_notcp";
    NSString *connectionName = infoTitle ?: @"";
    NSDictionary *params = @{
        @"message": connectionName,
        @"icon_connection": connectionIcon,
    };
    [[NSNotificationCenter defaultCenter] postNotificationName:@"XBMCServerConnectionSuccess" object:nil userInfo:params];
}

- (void)jsonConnectionNotifications:(BOOL)hasJsonConnection {
    NSString *connectionIcon = hasJsonConnection ? @"connection_on_notcp" : @"connection_off";
    NSString *connectionName = hasJsonConnection ? (infoTitle ?: @"") : LOCALIZED_STR(@"No connection");
    NSDictionary *params = @{
        @"status": @(hasJsonConnection),
        @"message": connectionName,
        @"icon_connection": connectionIcon,
    };
    [[NSNotificationCenter defaultCenter] postNotificationName:@"TcpJSONRPCChangeServerStatus" object:nil userInfo:params];
}

- (void)showSetupNotifications:(BOOL)showSetup {
    NSDictionary *params = @{@"showSetup": @(showSetup)};
    [[NSNotificationCenter defaultCenter] postNotificationName:@"TcpJSONRPCShowSetup" object:nil userInfo:params];
}

- (void)checkServer {
    if (inCheck) {
        return;
    }
    if (AppDelegate.instance.obj.serverIP.length == 0) {
        [self showSetupNotifications:YES];
        if (AppDelegate.instance.serverOnLine) {
            [self jsonConnectionNotifications:NO];
        }
        return;
    }
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"wol_preference"] &&
        [Utilities isValidMacAddress:AppDelegate.instance.obj.serverHWAddr]) {
        [Utilities wakeUp:AppDelegate.instance.obj.serverHWAddr];
    }
    inCheck = YES;
    
    NSDictionary *checkServerParams = @{@"properties": @[@"version", @"volume", @"name"]};
    [[Utilities getJsonRPC]
     callMethod:@"Application.GetProperties"
     withParameters:checkServerParams
     withTimeout: SERVER_TIMEOUT
     onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *error) {
        inCheck = NO;
        if (error == nil && methodError == nil) {
            if (AppDelegate.instance.serverOnLine) {
                return;
            }
            // Read JSON RPC API version
            [self readJSONRPCAPIVersion];

            // Read if ignorearticles is enabled
            [self readIgnoreArticlesEnabled];

            AppDelegate.instance.serverVolume = [methodResult[@"volume"] intValue];
            if (!AppDelegate.instance.serverOnLine) {
                if ([methodResult isKindOfClass:[NSDictionary class]]) {
                    NSDictionary *serverInfo = methodResult[@"version"];
                    AppDelegate.instance.serverVersion = [serverInfo[@"major"] intValue];
                    AppDelegate.instance.serverMinorVersion = [serverInfo[@"minor"] intValue];
                    NSString *realServerName = methodResult[@"name"];
                    if ([realServerName isEqualToString:@"MrMC"]) {
                        AppDelegate.instance.serverVersion += MRMC_TIMEWARP;
                    }
                    infoTitle = [NSString stringWithFormat:@"%@ v%@.%@ %@",
                                 AppDelegate.instance.obj.serverDescription,
                                 serverInfo[@"major"],
                                 serverInfo[@"minor"],
                                 serverInfo[@"tag"]];//, serverInfo[@"revision"]
                    [self jsonConnectionNotifications:YES];
                    [self showSetupNotifications:NO];
                }
                else {
                    if (AppDelegate.instance.serverOnLine) {
                        [self jsonConnectionNotifications:NO];
                    }
                    [self showSetupNotifications:YES];
                }
            }
        }
        else {
            if (error != nil) {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"XBMCServerConnectionError" object:nil userInfo:@{@"error_message": [error localizedDescription]}];
            }
            AppDelegate.instance.serverVolume = -1;
            if (AppDelegate.instance.serverOnLine) {
                [self jsonConnectionNotifications:NO];
            }
            [self showSetupNotifications:YES];
        }
    }];
}

- (void)readIgnoreArticlesEnabled {
    // Check if ignorearticles is enabled
    [[Utilities getJsonRPC]
     callMethod:@"Settings.GetSettingValue"
     withParameters:@{@"setting": @"filelists.ignorethewhensorting"}
     withTimeout: SERVER_TIMEOUT
     onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *error) {
        if (!error && !methodError && [methodResult isKindOfClass:[NSDictionary class]]) {
            AppDelegate.instance.isIgnoreArticlesEnabled = [methodResult[@"value"] boolValue];
        }
        else {
            AppDelegate.instance.isIgnoreArticlesEnabled = NO;
        }
    }];
}

- (void)readJSONRPCAPIVersion {
    // Read the JSON API version
    [[Utilities getJsonRPC]
     callMethod:@"JSONRPC.Version"
     withParameters:nil
     withTimeout: SERVER_TIMEOUT
     onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *error) {
        if (!error && !methodError && [methodResult isKindOfClass:[NSDictionary class]]) {
            // Kodi 11 and earlier do not support "major"/"minor"/"patch" and reply with "version" only
            if (![methodResult[@"version"] isKindOfClass:[NSNumber class]]) {
                AppDelegate.instance.APImajorVersion = [methodResult[@"version"][@"major"] intValue];
                AppDelegate.instance.APIminorVersion = [methodResult[@"version"][@"minor"] intValue];
                AppDelegate.instance.APIpatchVersion = [methodResult[@"version"][@"patch"] intValue];
            }
            else {
                AppDelegate.instance.APImajorVersion = [methodResult[@"version"] intValue];
                AppDelegate.instance.APIminorVersion = 0;
                AppDelegate.instance.APIpatchVersion = 0;
            }
        }
        [self readSorttokens];
        
        // Read 1-movie-set setting
        [self readGroupSingleItemSets];
        
        [self readShowEmptyTvShows];
    }];
}

- (void)readGroupSingleItemSets {
    // Check if GroupSingleItemSets is enabled
    if ([VersionCheck hasGroupSingleItemSetsSupport]) {
        [[Utilities getJsonRPC]
         callMethod:@"Settings.GetSettingValue"
         withParameters:@{@"setting": @"videolibrary.groupsingleitemsets"}
         withTimeout: SERVER_TIMEOUT
         onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *error) {
            if (!error && !methodError && [methodResult isKindOfClass:[NSDictionary class]]) {
                AppDelegate.instance.isGroupSingleItemSetsEnabled = [methodResult[@"value"] boolValue];
            }
            else {
                AppDelegate.instance.isGroupSingleItemSetsEnabled = YES;
            }
        }];
    }
    else {
        AppDelegate.instance.isGroupSingleItemSetsEnabled = YES;
    }
}

- (void)readShowEmptyTvShows {
    // Check if ShowEmptyTvShows is enabled
    if ([VersionCheck hasShowEmptyTvShowsSupport]) {
        [[Utilities getJsonRPC]
         callMethod:@"Settings.GetSettingValue"
         withParameters:@{@"setting": @"videolibrary.showemptytvshows"}
         withTimeout: SERVER_TIMEOUT
         onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *error) {
            if (!error && !methodError && [methodResult isKindOfClass:[NSDictionary class]]) {
                AppDelegate.instance.isShowEmptyTvShowsEnabled = [methodResult[@"value"] boolValue];
            }
            else {
                AppDelegate.instance.isShowEmptyTvShowsEnabled = YES;
            }
        }];
    }
    else {
        AppDelegate.instance.isShowEmptyTvShowsEnabled = YES;
    }
}

- (void)readSorttokens {
    NSArray *defaultTokens = @[@"The ", @"The.", @"The_"];
    // Read sort token from properties
    if ([VersionCheck hasSortTokenReadSupport]) {
        [[Utilities getJsonRPC]
         callMethod:@"Application.GetProperties"
         withParameters:@{@"properties":@[@"sorttokens"]}
         withTimeout: SERVER_TIMEOUT
         onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *error) {
            if (!error && !methodError && [methodResult isKindOfClass:[NSDictionary class]]) {
                AppDelegate.instance.KodiSorttokens = methodResult[@"sorttokens"];
            }
            else {
                AppDelegate.instance.KodiSorttokens = defaultTokens;
            }
        }];
    }
    else {
        AppDelegate.instance.KodiSorttokens = defaultTokens;
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver: self];
}

@end

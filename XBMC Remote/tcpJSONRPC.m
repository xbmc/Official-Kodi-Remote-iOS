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

#define SERVER_TIMEOUT 3.0
#define MRMC_TIMEWARP 14.0

NSInputStream	*inStream;
NSOutputStream	*outStream;
//	CFWriteStreamRef writeStream;

@implementation tcpJSONRPC

-(id)init{
    if ((self = [super init])) {
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

-(void)handleSystemOnSleep:(NSNotification *)sender{
    [AppDelegate instance].serverTCPConnectionOpen = NO;
}

- (void) handleDidEnterBackground: (NSNotification*) sender{
    [heartbeatTimer invalidate];
    heartbeatTimer = nil;
}

- (void) handleEnterForeground: (NSNotification*) sender{
    heartbeatTimer = [NSTimer scheduledTimerWithTimeInterval:SERVER_TIMEOUT target:self selector:@selector(checkServer) userInfo:nil repeats:YES];
}

- (void)startNetworkCommunicationWithServer:(NSString *)server serverPort:(int)port{
    if (port == 0) {
        port = 9090;
    }
    if ([server isEqualToString:@""]) {
        return;
    }
    CFReadStreamRef readStream;
	CFStreamCreatePairWithSocketToHost(NULL, (CFStringRef)CFBridgingRetain(server), port, &readStream, NULL);
	inStream = (__bridge NSInputStream *)readStream;
//	outStream = (__bridge NSOutputStream *)writeStream;
	[inStream setDelegate:self];
//	[outStream setDelegate:self];
	[inStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
//	[outStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[inStream open];
//	[outStream open];
    CFRelease((__bridge CFTypeRef)(server));
}

-(NSStreamStatus)currentSocketInStatus{
    return [inStream streamStatus];
}

-(void)stopNetworkCommunication{
    [AppDelegate instance].serverTCPConnectionOpen = NO;
    NSStreamStatus current_status = [inStream streamStatus];
    if (current_status == NSStreamStatusOpen) {
        [inStream close];
        [inStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [inStream setDelegate:nil];
        inStream = nil;
    }
}

- (void)stream:(NSStream *)theStream handleEvent:(NSStreamEvent)streamEvent {

	switch (streamEvent) {
    
        case NSStreamEventOpenCompleted:{
            [AppDelegate instance].serverTCPConnectionOpen = YES;
            NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                                    infoTitle, @"message",
                                    @"connection_on", @"icon_connection",
                                    nil];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"XBMCServerConnectionSuccess" object:nil userInfo:params];
        }
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
                                NSString *method = @"";
                                NSDictionary *paramsDict;
                                if (((NSNull *)notification[@"method"] != [NSNull null])) {
                                        method = notification[@"method"];
                                    if (((NSNull *)notification[@"params"] != [NSNull null])) {
                                        paramsDict = [NSDictionary dictionaryWithObject:notification[@"params"] forKey:@"params"];
                                    }
                                    [[NSNotificationCenter defaultCenter] postNotificationName:method object:nil userInfo:paramsDict];
                                }
                            }
						}
					}
				}
			}
			break;
            
		case NSStreamEventErrorOccurred:
            [AppDelegate instance].serverTCPConnectionOpen = NO;
            inCheck = NO;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"tcpJSONRPCConnectionError" object:nil userInfo:nil];
			break;
			
		case NSStreamEventEndEncountered:
            [AppDelegate instance].serverTCPConnectionOpen = NO;
            inCheck = NO;
            [theStream close];
            [theStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
            [theStream setDelegate:nil];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"tcpJSONRPCConnectionClosed" object:nil userInfo:nil];

            break;
		default:
            break;
	}    
}


-(void)noConnectionNotifications{
    NSString *infoText = LOCALIZED_STR(@"No connection");
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                            @(NO), @"status",
                            infoText, @"message",
                            @"connection_off", @"icon_connection",
                            nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"TcpJSONRPCChangeServerStatus" object:nil userInfo:params];
}

-(void)checkServer{
    if (inCheck) {
        return;
    }
    if ([[AppDelegate instance].obj.serverIP length] == 0) {
        NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys: @(YES), @"showSetup", nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"TcpJSONRPCShowSetup" object:nil userInfo:params];
        if ([AppDelegate instance].serverOnLine) {
            [self noConnectionNotifications];
        }
        return;
    }
    if ([AppDelegate instance].serverTCPConnectionOpen) {
        return;
    }
    inCheck = YES;
//    NSString *userPassword = [[AppDelegate instance].obj.serverPass isEqualToString:@""] ? @"" : [NSString stringWithFormat:@":%@", [AppDelegate instance].obj.serverPass];
//    NSString *serverJSON = [NSString stringWithFormat:@"http://%@%@@%@:%@/jsonrpc", [AppDelegate instance].obj.serverUser, userPassword, [AppDelegate instance].obj.serverIP, [AppDelegate instance].obj.serverPort];
    
    NSDictionary *checkServerParams = [NSDictionary dictionaryWithObjectsAndKeys: @[@"version", @"volume", @"name"], @"properties", nil];
    [[Utilities getJsonRPC]
     callMethod:@"Application.GetProperties"
     withParameters:checkServerParams
     withTimeout: SERVER_TIMEOUT
     onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
         inCheck = NO;
         if (error == nil && methodError == nil) {
             [AppDelegate instance].serverVolume = [methodResult[@"volume"] intValue];
             if (![AppDelegate instance].serverOnLine) {
                 if ([NSJSONSerialization isValidJSONObject:methodResult]) {
                     NSDictionary *serverInfo = methodResult[@"version"];
                     [AppDelegate instance].serverVersion = [serverInfo[@"major"] intValue];
                     [AppDelegate instance].serverMinorVersion = [serverInfo[@"minor"] intValue];
                     NSString *realServerName = methodResult[@"name"];
                     if ([realServerName isEqualToString:@"MrMC"]) {
                         [AppDelegate instance].serverVersion += MRMC_TIMEWARP;
                     }
                     infoTitle = [NSString stringWithFormat:@"%@ v%@.%@ %@",
                                          [AppDelegate instance].obj.serverDescription,
                                          serverInfo[@"major"],
                                          serverInfo[@"minor"],
                                          serverInfo[@"tag"]];//, serverInfo[@"revision"]
                     NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                                             @(YES), @"status",
                                             infoTitle, @"message",
                                             @"connection_on_notcp", @"icon_connection",
                                             nil];
                     [[NSNotificationCenter defaultCenter] postNotificationName:@"TcpJSONRPCChangeServerStatus" object:nil userInfo:params];
                     params = [NSDictionary dictionaryWithObjectsAndKeys: @(NO), @"showSetup", nil];
                     [[NSNotificationCenter defaultCenter] postNotificationName:@"TcpJSONRPCShowSetup" object:nil userInfo:params];
                 }
                 else {
                     if ([AppDelegate instance].serverOnLine) {
                         [self noConnectionNotifications];            
                     }
                     NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys: @(YES), @"showSetup", nil];
                     [[NSNotificationCenter defaultCenter] postNotificationName:@"TcpJSONRPCShowSetup" object:nil userInfo:params];
                 }
             }
         }
         else {
             if (error != nil) {
                 [[NSNotificationCenter defaultCenter] postNotificationName:@"XBMCServerConnectionError" object:nil userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[error localizedDescription], @"error_message", nil]];
             }
             [AppDelegate instance].serverVolume = -1;
             if ([AppDelegate instance].serverOnLine) {
                 [self noConnectionNotifications];
             }
             NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys: @(YES), @"showSetup", nil];
             [[NSNotificationCenter defaultCenter] postNotificationName:@"TcpJSONRPCShowSetup" object:nil userInfo:params];
         }
     }];
    // Read the JSON API version
    [[Utilities getJsonRPC]
     callMethod:@"JSONRPC.Version"
     withParameters:nil
     withTimeout: SERVER_TIMEOUT
     onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
         if (!error && !methodError) {
             [AppDelegate instance].APImajorVersion = [methodResult[@"version"][@"major"] intValue];
             [AppDelegate instance].APIminorVersion = [methodResult[@"version"][@"minor"] intValue];
             [AppDelegate instance].APIpatchVersion = [methodResult[@"version"][@"patch"] intValue];
         }
         // Read the sorttokens
         [self readSorttokens];
    }];
    // Check if ignorearticles is enabled
    [[Utilities getJsonRPC]
     callMethod:@"Settings.GetSettingValue"
     withParameters:@{@"setting": @"filelists.ignorethewhensorting"}
     withTimeout: SERVER_TIMEOUT
     onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
         if (!error && !methodError) {
             [AppDelegate instance].isIgnoreArticlesEnabled = [methodResult[@"value"] boolValue];
         }
         else {
             [AppDelegate instance].isIgnoreArticlesEnabled = NO;
         }
    }];
    // Check if groupsingleitemsets is enabled
    [[Utilities getJsonRPC]
     callMethod:@"Settings.GetSettingValue"
     withParameters:@{@"setting": @"videolibrary.groupsingleitemsets"}
     withTimeout: SERVER_TIMEOUT
     onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
         if (!error && !methodError) {
             [AppDelegate instance].isGroupSingleItemSetsEnabled = [methodResult[@"value"] boolValue];
         }
         else {
             [AppDelegate instance].isGroupSingleItemSetsEnabled = NO;
         }
    }];
}

- (void)readSorttokens {
    NSArray *defaultTokens = @[@"The ", @"The.", @"The_"];
    // Sort token can be read from API 9.5.0 on
    if (([AppDelegate instance].APImajorVersion >= 10) ||
        ([AppDelegate instance].APImajorVersion == 9 && [AppDelegate instance].APIminorVersion >= 5)) {
        [[Utilities getJsonRPC]
         callMethod:@"Application.GetProperties"
         withParameters:@{@"properties":@[@"sorttokens"]}
         withTimeout: SERVER_TIMEOUT
         onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
             if (!error && !methodError) {
                 [AppDelegate instance].KodiSorttokens = methodResult[@"sorttokens"];
             }
             else {
                 [AppDelegate instance].KodiSorttokens = defaultTokens;
             }
        }];
    }
    else {
        [AppDelegate instance].KodiSorttokens = defaultTokens;
    }
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver: self];
}

@end

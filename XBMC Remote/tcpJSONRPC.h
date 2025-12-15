//
//  tcpJSONRPC.h
//  XBMC Remote
//
//  Created by Giovanni Messina on 22/11/12.
//  Copyright (c) 2012 joethefox inc. All rights reserved.
//

#import "DSJSONRPC.h"

@import Foundation;

@interface tcpJSONRPC : NSObject <NSStreamDelegate> {
    BOOL inCheck;
    NSTimer *heartbeatTimer;
    NSString *infoTitle;
}

- (void)startNetworkCommunicationWithServer:(NSString*)server serverPort:(int)port;
- (void)stopNetworkCommunication;
- (NSStreamStatus)currentSocketInStatus;

@end

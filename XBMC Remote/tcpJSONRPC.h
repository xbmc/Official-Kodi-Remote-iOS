//
//  tcpJSONRPC.h
//  XBMC Remote
//
//  Created by Giovanni Messina on 22/11/12.
//  Copyright (c) 2012 joethefox inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface tcpJSONRPC : NSObject <NSStreamDelegate> 
- (void) startNetworkCommunicationWithServer:(NSString *)server serverPort:(int)port;
- (void) stopNetworkCommunication;

@end

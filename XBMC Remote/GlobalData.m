//
//  GlobalData.m
//  XBMC Remote
//
//  Created by Giovanni Messina on 27/3/12.
//  Copyright (c) 2012 joethefox inc. All rights reserved.
//

#import "GlobalData.h"

@implementation GlobalData

@synthesize serverDescription;
@synthesize serverUser;
@synthesize serverPass;
@synthesize serverIP;
@synthesize serverPort;
@synthesize tcpPort;
@synthesize serverHWAddr;

static GlobalData *instance = nil;
+ (GlobalData*)getInstance {
    @synchronized(self) {
        if (instance == nil) {
            instance = [GlobalData new];
        }
    }
    return instance;
}
@end

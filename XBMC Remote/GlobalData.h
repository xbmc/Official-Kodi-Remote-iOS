//
//  GlobalData.h
//  XBMC Remote
//
//  Created by Giovanni Messina on 27/3/12.
//  Copyright (c) 2012 joethefox inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GlobalData : NSObject {
    NSString *serverDescription;
    NSString *serverUser;
    NSString *serverPass;
    NSString *serverIP;
    NSString *serverPort;
    int tcpPort;
    NSString *serverHWAddr;

    
}
@property (nonatomic, strong)NSString *serverDescription;
@property (nonatomic, strong)NSString *serverUser;
@property (nonatomic, strong)NSString *serverPass;
@property (nonatomic, strong)NSString *serverIP;
@property int tcpPort;
@property (nonatomic, strong)NSString *serverPort;
@property (nonatomic, strong)NSString *serverHWAddr;

+ (GlobalData*)getInstance;
@end

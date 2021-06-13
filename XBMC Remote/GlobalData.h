//
//  GlobalData.h
//  XBMC Remote
//
//  Created by Giovanni Messina on 27/3/12.
//  Copyright (c) 2012 joethefox inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GlobalData : NSObject{    
    NSString *serverDescription; 
    NSString *serverUser; 
    NSString *serverPass; 
    NSString *serverIP; 
    NSString *serverPort;
    int tcpPort;
    NSString *serverHWAddr; 
    BOOL preferTVPosters;

    
}    
@property(nonatomic, retain)NSString *serverDescription;
@property(nonatomic, retain)NSString *serverUser;
@property(nonatomic, retain)NSString *serverPass;
@property(nonatomic, retain)NSString *serverIP;
@property int tcpPort;
@property(nonatomic, retain)NSString *serverPort;
@property(nonatomic, retain)NSString *serverHWAddr; 
@property BOOL preferTVPosters;

+(GlobalData*)getInstance;    
@end  

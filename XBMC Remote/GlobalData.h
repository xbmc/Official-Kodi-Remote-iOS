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
    BOOL preferTVPosters;

    
}    
@property(nonatomic,retain)NSString *serverDescription;    
@property(nonatomic,retain)NSString *serverUser;    
@property(nonatomic,retain)NSString *serverPass;    
@property(nonatomic,retain)NSString *serverIP;    
@property(nonatomic,retain)NSString *serverPort; 
@property BOOL preferTVPosters;

+(GlobalData*)getInstance;    
@end  

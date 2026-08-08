//
//  CustomButton.m
//  XBMC Remote
//
//  Created by Giovanni Messina on 8/4/14.
//  Copyright (c) 2014 joethefox inc. All rights reserved.
//

#import "CustomButton.h"
#import "GlobalData.h"
#import "AppDelegate.h"
#import "Utilities.h"

@implementation CustomButton

@synthesize buttons;

- (id)init {
    if (self = [super init]) {
        [self loadData];
    }
    return self;
}

- (NSString*)getServerKey {
    GlobalData *obj = [GlobalData getInstance];
    return [[NSString stringWithFormat:@"%@%@%@", obj.serverIP, obj.serverPort, obj.serverDescription] SHA256String];
}

- (void)loadData {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *filename = [NSString stringWithFormat:@"customButtons_%@.dat", [self getServerKey]];
    NSMutableArray *tempArray = [Utilities unarchivePath:paths[0] file:filename];
    
    // Use deep mutable copy to ensure all the objects in the button array are mutable as elements could
    // be edited by user or overwritten to reflect a UISwitch's state.
    buttons = (NSMutableArray*)CFBridgingRelease(CFPropertyListCreateDeepCopy(kCFAllocatorDefault,
                                                                              (CFArrayRef)tempArray,
                                                                              kCFPropertyListMutableContainers));
}

- (void)saveData {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *filename = [NSString stringWithFormat:@"customButtons_%@.dat", [self getServerKey]];
    [Utilities archivePath:paths[0] file:filename data:buttons];
}

@end

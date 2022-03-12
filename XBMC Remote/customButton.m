//
//  customButton.m
//  XBMC Remote
//
//  Created by Giovanni Messina on 8/4/14.
//  Copyright (c) 2014 joethefox inc. All rights reserved.
//

#import "customButton.h"
#import "NSString+MD5.h"
#import "GlobalData.h"
#import "AppDelegate.h"
#import "Utilities.h"

@implementation customButton

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
    if (tempArray) {
        [self setButtons:tempArray];
    }
    else {
        buttons = [NSMutableArray new];
    }
}

- (void)saveData {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *filename = [NSString stringWithFormat:@"customButtons_%@.dat", [self getServerKey]];
    [Utilities archivePath:paths[0] file:filename data:buttons];
}

@end

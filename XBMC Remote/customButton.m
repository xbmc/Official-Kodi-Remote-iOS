//
//  customButton.m
//  XBMC Remote
//
//  Created by Giovanni Messina on 8/4/14.
//  Copyright (c) 2014 joethefox inc. All rights reserved.
//

#import "customButton.h"
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
    
    // Make sure the objects in the button array are mutable. The user might edit them.
    NSMutableArray *buttonArray = [[NSMutableArray alloc] initWithCapacity:tempArray.count];
    for (id object in tempArray) {
        id mutableObject = [object mutableCopy];
        [buttonArray addObject:mutableObject];
    }
    buttons = buttonArray;
}

- (void)saveData {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *filename = [NSString stringWithFormat:@"customButtons_%@.dat", [self getServerKey]];
    [Utilities archivePath:paths[0] file:filename data:buttons];
}

@end

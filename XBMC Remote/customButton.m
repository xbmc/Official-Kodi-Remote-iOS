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

@implementation customButton

@synthesize buttons;

- (id) init {
    if (self = [super init]) {
        [self loadData];
    }
    return self;
}

-(NSString *)getServerKey {
    GlobalData *obj = [GlobalData getInstance];
    return [[NSString stringWithFormat:@"%@%@%@", obj.serverIP, obj.serverPort, obj.serverDescription] MD5String];
}

- (void)loadData {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *customButtonDatFile = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"customButtons_%@.dat", [self getServerKey]]];
    NSFileManager *fileManager1 = [NSFileManager defaultManager];
    if([fileManager1 fileExistsAtPath:customButtonDatFile]) {
        NSMutableArray *tempArray;
        tempArray = [NSKeyedUnarchiver unarchiveObjectWithFile: customButtonDatFile];
        [self setButtons:tempArray];
    }
    else {
        buttons = [[NSMutableArray alloc] init];
    }
}

- (void)saveData {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *customButtonDatFile = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"customButtons_%@.dat", [self getServerKey]]];
    if ([paths count] > 0) {
        [NSKeyedArchiver archiveRootObject:buttons toFile:customButtonDatFile];
    }
}

@end

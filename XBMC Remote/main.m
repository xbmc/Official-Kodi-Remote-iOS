//
//  main.m
//  XBMC Remote
//
//  Created by Giovanni Messina on 23/3/12.
//  Copyright (c) 2012 joethefox inc. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "AppDelegate.h"

int main(int argc, char *argv[]) {
    @autoreleasepool {
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        if ([[userDefaults objectForKey:@"lang_preference"] length]) {
            [userDefaults setObject:[NSArray arrayWithObjects:[userDefaults objectForKey:@"lang_preference"], nil] forKey:@"AppleLanguages"];
        }
        else {
            [userDefaults removeObjectForKey:@"AppleLanguages"];
        }
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}

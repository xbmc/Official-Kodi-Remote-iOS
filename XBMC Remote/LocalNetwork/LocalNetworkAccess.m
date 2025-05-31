//
//  LocalNetworkAccess.m
//  Kodi Remote
//
//  Created by Buschmann on 30.05.25.
//  Copyright © 2025 Team Kodi. All rights reserved.
//

#import "LocalNetworkAccess.h"

@import UIKit;

/* Implementation taken from stackoverflow
 * https://stackoverflow.com/questions/67058134/objective-c-ios-14-how-to-do-network-privacy-permission-check
 */

@interface LocalNetworkAccess () <NSNetServiceDelegate>

@property (nonatomic) NSNetService *service;
@property (nonatomic) void (^completion)(BOOL);
@property (nonatomic) NSTimer *timer;
@property (nonatomic) BOOL publishing;

@end

@implementation LocalNetworkAccess

- (instancetype)init {
    if (self = [super init]) {
        self.service = [[NSNetService alloc] initWithDomain:@"local." type:serviceTypeTCP name:@"LocalNetworkPrivacy" port:1100];
    }
    return self;
}

- (void)dealloc {
    [self.service stop];
}

- (void)checkAccessState:(void (^)(BOOL))completion {
    self.completion = completion;
    
    self.timer = [NSTimer scheduledTimerWithTimeInterval:2 repeats:YES block:^(NSTimer * _Nonnull timer) {
        if (UIApplication.sharedApplication.applicationState != UIApplicationStateActive) {
            return;
        }
        
        if (self.publishing) {
            [self.timer invalidate];
            self.completion(NO);
        }
        else {
            self.publishing = YES;
            self.service.delegate = self;
            [self.service publish];
        }
    }];
}


#pragma mark - NSNetServiceDelegate

- (void)netServiceDidPublish:(NSNetService *)sender {
    [self.timer invalidate];
    self.completion(YES);
}

@end



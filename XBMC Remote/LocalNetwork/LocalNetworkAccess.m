//
//  LocalNetworkAccess.m
//  Kodi Remote
//
//  Created by Buschmann on 30.05.25.
//  Copyright © 2025 Team Kodi. All rights reserved.
//

#import "LocalNetworkAccess.h"

@import UIKit;

/* Implementation inspired by stackoverflow
 * https://stackoverflow.com/questions/67058134/objective-c-ios-14-how-to-do-network-privacy-permission-check
 */

#define DISCOVERY_TIMEOUT 5.0

@interface LocalNetworkAccess () <NSNetServiceDelegate>

@property (nonatomic) NSNetService *service;
@property (nonatomic) void (^completion)(BOOL);
@property (nonatomic) NSTimer *timer;

@end

@implementation LocalNetworkAccess

- (instancetype)init {
    if (self = [super init]) {
        self.service = [[NSNetService alloc] initWithDomain:@"local." type:SERVICE_TYPE_TCP name:@"LocalNetworkPrivacy" port:1100];
    }
    return self;
}

- (void)dealloc {
    [self.service stop];
}

- (void)checkAccessState:(void (^)(BOOL))completion {
    self.completion = completion;
    
    self.service.delegate = self;
    [self.service publish];
    
    self.timer = [NSTimer scheduledTimerWithTimeInterval:DISCOVERY_TIMEOUT repeats:NO block:^(NSTimer * _Nonnull timer) {
        if (UIApplication.sharedApplication.applicationState != UIApplicationStateActive) {
            return;
        }
        
        // Discovery timed out, report failure.
        [self endDiscoveryWithSuccess:NO];
    }];
}

- (void)endDiscoveryWithSuccess:(BOOL)success {
    [self.timer invalidate];
    [self.service stop];
    self.completion(success);
}

#pragma mark - NSNetServiceDelegate

- (void)netServiceDidPublish:(NSNetService *)sender {
    [self endDiscoveryWithSuccess:YES];
}

@end



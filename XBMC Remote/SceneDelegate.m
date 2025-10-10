//
//  SceneDelegate.m
//  Kodi Remote
//
//  Created by Buschmann on 24.05.25.
//  Copyright © 2025 Team Kodi. All rights reserved.
//

#import "SceneDelegate.h"
#import "AppDelegate.h"
#import "Utilities.h"
#import "Kodi_Remote-Swift.h"

@implementation SceneDelegate

@synthesize window;

- (void)scene:(UIScene*)scene willConnectToSession:(UISceneSession*)session options:(UISceneConnectionOptions*)connectionOptions {
    // Create window using AppDelegate's controllers
    window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    window.windowScene = (UIWindowScene*)scene;
    window.rootViewController = AppDelegate.instance.appRootController;
    [window makeKeyAndVisible];
    
    // Set interface style for window
    [self setInterfaceStyleFromUserDefaults];
}

- (void)sceneWillEnterForeground:(UIScene*)scene {
    [Utilities setIdleTimerFromUserDefaults];
}

- (void)sceneDidBecomeActive:(UIScene*)scene {
    // Trigger Local Network Privacy Alert once after app launch
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        LocalNetworkAlertClass *localNetworkAlert = [LocalNetworkAlertClass new];
        [localNetworkAlert triggerLocalNetworkPrivacyAlert];
    });
}

- (void)setInterfaceStyleFromUserDefaults {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *mode = [userDefaults stringForKey:@"theme_mode"];
    if (@available(iOS 13.0, *)) {
        UIUserInterfaceStyle style = UIUserInterfaceStyleUnspecified;
        if (mode.length) {
            if ([mode isEqualToString:@"dark_mode"]) {
                style = UIUserInterfaceStyleDark;
            }
            else if ([mode isEqualToString:@"light_mode"]) {
                style = UIUserInterfaceStyleLight;
            }
        }
        window.overrideUserInterfaceStyle = style;
    }
}

@end

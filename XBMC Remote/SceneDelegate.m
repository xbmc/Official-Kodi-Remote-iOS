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
    
    // Store launch options
    launchShortcutItem = connectionOptions.shortcutItem;
    launchURLContexts = connectionOptions.URLContexts;
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
    
    // As per Apple documentation
    // https://developer.apple.com/documentation/uikit/menus_and_shortcuts/add_home_screen_quick_actions
    if (launchShortcutItem) {
        [self windowScene:(UIWindowScene*)scene performActionForShortcutItem:launchShortcutItem completionHandler:nil];
        launchShortcutItem = nil;
    }
    if (launchURLContexts) {
        [self scene:scene openURLContexts:launchURLContexts];
        launchURLContexts = nil;
    }
}

- (void)sceneDidEnterBackground:(UIScene*)scene {
    // Add the server description and address to shortcutItems, which is shown when longpressing the app icon.
    NSMutableArray *items = [[NSMutableArray alloc] initWithCapacity:AppDelegate.instance.arrayServerList.count];
    for (NSDictionary *server in AppDelegate.instance.arrayServerList) {
        UIApplicationShortcutIcon *icon = [UIApplicationShortcutIcon iconWithType:UIApplicationShortcutIconTypeFavorite];
        UIApplicationShortcutItem *shortcut = [[UIApplicationShortcutItem alloc] initWithType:@"ConnectServer"
                                                                               localizedTitle:server[@"serverDescription"]
                                                                            localizedSubtitle:server[@"serverIP"]
                                                                                         icon:icon
                                                                                     userInfo:nil];
        [items addObject:shortcut];
    }
    UIApplication.sharedApplication.shortcutItems = items;
}

- (void)windowScene:(UIWindowScene*)windowScene performActionForShortcutItem:(UIApplicationShortcutItem*)shortcutItem completionHandler:(void(^)(BOOL))completionHandler {
    // Use shortcut title (= server description) to map to server list and connect the server.
    [self connectToServerFromList:shortcutItem.localizedTitle];
}

- (void)scene:(UIScene*)scene openURLContexts:(NSSet<UIOpenURLContext*>*)URLContexts {
    // Use URL host to map to server list and connect the server.
    UIOpenURLContext *urlContext = URLContexts.allObjects.firstObject;
    NSURL *url = urlContext.URL;
    [self connectToServerFromList:url.host.stringByRemovingPercentEncoding];
}

#pragma mark - Helper

- (BOOL)connectToServerFromList:(NSString*)host {
    if (!host.length) {
        return NO;
    }
    
    // Host name needs ".local." at the end
    if ([host hasSuffix:@".local"]) {
        host = [host stringByAppendingString:@"."];
    }
    
    // Try to map server name or IP address to the list of Kodi servers
    NSInteger index = [AppDelegate.instance.arrayServerList indexOfObjectPassingTest:^BOOL(NSDictionary *obj, NSUInteger idx, BOOL *stop) {
        return [host isEqualToString:obj[@"serverDescription"]] || [host isEqualToString:obj[@"serverIP"]];
    }];
    
    // We want to connect to the desired server only. If this is not present, disconnect from any active server.
    BOOL result = NO;
    NSIndexPath *serverIndexPath;
    NSDictionary *params;
    if (index != NSNotFound) {
        serverIndexPath = [NSIndexPath indexPathForRow:index inSection:0];
        params = @{@"index": @(index)};
        result = YES;
    }
    
    // Case 1: App just starts. Set the last active server before readKodiServerParameters is called
    [Utilities saveLastServerIndex:serverIndexPath];
    
    // Case 2: App already runs. Send a notification to select the server via its index.
    [NSNotificationCenter.defaultCenter postNotificationName:@"SelectKodiServer" object:nil userInfo:params];
    
    return result;
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

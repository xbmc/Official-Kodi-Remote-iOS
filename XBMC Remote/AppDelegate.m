//
//  AppDelegate.m
//  XBMC Remote
//
//  Created by Giovanni Messina on 23/3/12.
//  Copyright (c) 2012 joethefox inc. All rights reserved.
//

#import "AppDelegate.h"
#import "mainMenu.h"
#import "MasterViewController.h"
#import "ViewControllerIPad.h"
#import "GlobalData.h"
#import "InitialSlidingViewController.h"
#import "UIImageView+WebCache.h"
#import "Utilities.h"

#include <arpa/inet.h>
#include <net/if.h>
#include <ifaddrs.h>

@implementation AppDelegate

@synthesize navigationController = _navigationController;
@synthesize windowController = _windowController;
@synthesize appRootController;
@synthesize dataFilePath;
@synthesize arrayServerList;
@synthesize serverOnLine;
@synthesize serverVersion;
@synthesize serverMinorVersion;
@synthesize obj;
@synthesize customButtonEntry;
@synthesize playlistArtistAlbums;
@synthesize playlistMovies;
@synthesize playlistMusicVideos;
@synthesize playlistTvShows;
@synthesize playlistPVR;
@synthesize globalSearchLookup;
@synthesize serverName;

+ (AppDelegate*)instance {
	return (AppDelegate*)UIApplication.sharedApplication.delegate;
}

#pragma mark - Globals

// Amount of bytes per pixel for images cached in memory (32 bit png)
#define BYTES_PER_PIXEL 4

#pragma mark - Init

- (id)init {
	if (self = [super init]) {
        NSArray *docPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        self.dataFilePath = docPaths[0];
        NSMutableArray *tempArray = [Utilities unarchivePath:self.dataFilePath file:@"serverList_saved.dat"];
        if (tempArray) {
            [self setArrayServerList:tempArray];
        }
        else {
            arrayServerList = [NSMutableArray new];
        }
        
        // Set the image in-memory cache to 25% of physical memory (but max to 512 MB). maxCost reflects the amount of pixels.
        NSInteger memorySize = [[NSProcessInfo processInfo] physicalMemory];
        NSInteger maxCost = MIN(memorySize / 4, 512 * 1024 * 1024) / BYTES_PER_PIXEL;
        [[SDImageCache sharedImageCache] setMaxMemoryCost:maxCost];
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSArray *cachePaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        self.libraryCachePath = [cachePaths[0] stringByAppendingPathComponent:@"LibraryCache"];
        [fileManager createDirectoryAtPath:self.libraryCachePath
               withIntermediateDirectories:YES
                                attributes:nil
                                     error:NULL];
        self.epgCachePath = [cachePaths[0] stringByAppendingPathComponent:@"EPGDataCache"];
        [fileManager createDirectoryAtPath:self.epgCachePath
               withIntermediateDirectories:YES
                                attributes:nil
                                     error:NULL];
    }
	return self;
	
}

- (void)registerDefaultsFromSettingsBundle {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];

    NSString *bundle = [[NSBundle mainBundle] pathForResource:@"Settings" ofType:@"bundle"];
    if (!bundle) {
        return;
    }

    NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:[bundle stringByAppendingPathComponent:@"Root.plist"]];
    NSArray *preferences = settings[@"PreferenceSpecifiers"];
    NSMutableDictionary *defaultsToRegister = [[NSMutableDictionary alloc] initWithCapacity:preferences.count];

    for (NSDictionary *prefSpecification in preferences) {
        NSString *key = prefSpecification[@"Key"];
        if (key) {
            // We can set defaults here as registerDefaults does not overwrite already defined values
            defaultsToRegister[key] = prefSpecification[@"DefaultValue"];
        }
    }

    // Register defaults
    [userDefaults registerDefaults:defaultsToRegister];
}

- (BOOL)application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary*)launchOptions {
    // iOS 13 and later use appearance for the navigationbar, from iOS 15 this is required as it else defaults to unwanted transparency
    if (@available(iOS 13, *)) {
        UINavigationBarAppearance *appearance = [[UINavigationBarAppearance alloc] init];
        [appearance configureWithOpaqueBackground];
        appearance.titleTextAttributes = @{NSForegroundColorAttributeName : UIColor.whiteColor};
        appearance.backgroundColor = NAVBAR_TINT_COLOR;
        [UINavigationBar appearance].standardAppearance = appearance;
        [UINavigationBar appearance].scrollEdgeAppearance = appearance;
    }
    
    // Load user defaults, if not yet set. Avoids need to check for nil.
    [self registerDefaultsFromSettingsBundle];
    
    [Utilities setIdleTimerFromUserDefaults];
    
    // Create GlobalDate which holds the Kodi server parameters
    obj = [GlobalData getInstance];
    
    // Create the menu tree
    mainMenuItems = [mainMenu generateMenus];
    
    // Initialize controllers
    self.serverName = LOCALIZED_STR(@"No connection");
    if (IS_IPHONE) {
        InitialSlidingViewController *initialSlidingViewController = [[InitialSlidingViewController alloc] initWithNibName:@"InitialSlidingViewController" bundle:nil];
        initialSlidingViewController.mainMenu = mainMenuItems;
        appRootController = initialSlidingViewController;
    }
    else {
        self.windowController = [[ViewControllerIPad alloc] initWithNibName:@"ViewControllerIPad" bundle:nil];
        self.windowController.mainMenu = mainMenuItems;
        appRootController = self.windowController;
    }
    return YES;
}

- (NSURL*)getServerJSONEndPoint {
    if (!obj.serverIP || !obj.serverPort) {
        return nil;
    }
    NSString *serverJSON = [NSString stringWithFormat:@"http://%@:%@/jsonrpc", obj.serverIP, obj.serverPort];
    return [NSURL URLWithString:serverJSON];
}

- (NSDictionary*)getServerHTTPHeaders {
    NSData *authCredential = [[NSString stringWithFormat:@"%@:%@", obj.serverUser, obj.serverPass] dataUsingEncoding:NSUTF8StringEncoding];
    NSString *base64AuthCredentials = [authCredential base64EncodedStringWithOptions:(NSDataBase64EncodingOptions)0];
    NSString *authValue = [NSString stringWithFormat:@"Basic %@", base64AuthCredentials];
    NSDictionary *httpHeaders = @{@"Authorization": authValue};
    return httpHeaders;
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
    NSInteger index = [self.arrayServerList indexOfObjectPassingTest:^BOOL(NSDictionary *obj, NSUInteger idx, BOOL *stop) {
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

- (void)sendWOL:(NSString*)MAC withPort:(NSInteger)WOLport {
    CFSocketRef     WOLsocket;
    WOLsocket = CFSocketCreate(kCFAllocatorDefault, PF_INET, SOCK_DGRAM, IPPROTO_UDP, 0, NULL, NULL);
    if (WOLsocket) {
        int desc = -1;
        desc = CFSocketGetNative(WOLsocket);
        int yes = -1;
        
        if (setsockopt (desc, SOL_SOCKET, SO_BROADCAST, (char*)&yes, sizeof(yes)) < 0) {
            NSLog(@"Set Socket options failed");
        }
        
        unsigned char ether_addr[6];
        
        int idx;
        
        for (idx = 0; idx + 2 <= MAC.length; idx += 3) {
            NSRange range = NSMakeRange(idx, 2);
            NSString *hexStr = [MAC substringWithRange:range];
            
            NSScanner *scanner = [NSScanner scannerWithString:hexStr];
            unsigned int intValue;
            [scanner scanHexInt:&intValue];
            
            ether_addr[idx / 3] = intValue;
        }
        
        /* Build the message to send - 6 x 0xff then 16 x MAC address */
        
        unsigned char message[102];
        unsigned char *message_ptr = message;
        
        memset(message_ptr, 0xFF, 6);
        message_ptr += 6;
        for (int i = 0; i < 16; ++i) {
            memcpy(message_ptr, ether_addr, 6);
            message_ptr += 6;
        }

        __auto_type getLocalBroadcastAddress = ^in_addr_t {
            in_addr_t broadcastAddress = 0xffffffff;
            struct ifaddrs *ifs = NULL;
            getifaddrs(&ifs);
            for (__auto_type ifIter = ifs; ifIter != NULL; ifIter = ifIter->ifa_next) {
                if (ifIter->ifa_flags & IFF_LOOPBACK || ifIter->ifa_flags & IFF_POINTOPOINT || !(ifIter->ifa_flags & IFF_RUNNING))
                    continue;
                if (!ifIter->ifa_addr || ifIter->ifa_addr->sa_family != AF_INET || !ifIter->ifa_broadaddr)
                    continue;
                broadcastAddress = ((struct sockaddr_in*)ifIter->ifa_broadaddr)->sin_addr.s_addr;
                break;
            }
            if (ifs) {
                freeifaddrs(ifs);
            }
            return broadcastAddress;
        };

        struct sockaddr_in addr;
        memset(&addr, 0, sizeof(addr));
        addr.sin_len = sizeof(addr);
        addr.sin_family = AF_INET;
        addr.sin_addr.s_addr = getLocalBroadcastAddress();
        addr.sin_port = htons(WOLport);
        
        CFDataRef message_data = CFDataCreate(NULL, (unsigned char*)&message, sizeof(message));
        CFDataRef destinationAddressData = CFDataCreate(NULL, (const UInt8*)&addr, sizeof(addr));
        
        CFSocketError CFSocketSendData_error = CFSocketSendData(WOLsocket, destinationAddressData, message_data, 30);
        
        if (CFSocketSendData_error) {
            NSLog(@"CFSocketSendData error: %li", CFSocketSendData_error);
        }
    }
}

- (BOOL)application:(UIApplication*)app openURL:(NSURL*)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id>*)options {
    // Use URL host to map to server list and connect the server.
    return [self connectToServerFromList:url.host.stringByRemovingPercentEncoding];
}

- (void)application:(UIApplication*)application performActionForShortcutItem:(UIApplicationShortcutItem*)shortcutItem completionHandler:(void(^)(BOOL))completionHandler {
    // Use shortcut title (= server description) to map to server list and connect the server.
    [self connectToServerFromList:shortcutItem.localizedTitle];
}

- (void)applicationDidReceiveMemoryWarning:(UIApplication*)application {
    [[SDImageCache sharedImageCache] clearMemory];
}

- (void)saveServerList {
    [Utilities archivePath:self.dataFilePath file:@"serverList_saved.dat" data:arrayServerList];
}

- (void)clearDiskCacheAtPath:(NSString*)cachePath {
    [[NSFileManager defaultManager] removeItemAtPath:cachePath error:NULL];
    [[NSFileManager defaultManager] createDirectoryAtPath:cachePath
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:NULL];
}

- (void)clearAppDiskCache {
    // Clear SDWebImage image cache
    [[SDImageCache sharedImageCache] clearDisk];
    
    // Clear library cache
    [self clearDiskCacheAtPath:self.libraryCachePath];
    
    // Clear EPG cache
    [self clearDiskCacheAtPath:self.epgCachePath];
    
    // Clear network cache
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
}

+ (UIWindowScene*)scene {
    NSArray *scenes= UIApplication.sharedApplication.connectedScenes.allObjects;
    UIWindowScene *scene = scenes[0];
    return scene;
}

+ (UIWindow*)keyWindow {
    /* WORKAROUND: Instead of keyWindow we return the first window. As this app only supports
     * a single window, this works and avoids a problem caused by the implementation of most app's
     * UIViewControllers which use keyWindow.safeAreaInset in viewDidLoad instead of willLayoutSubView.
    return AppDelegate.scene.keyWindow;
     */
    return AppDelegate.scene.windows.firstObject;
}

+ (UIStatusBarManager*)statusBarManager {
    return AppDelegate.scene.statusBarManager;
}

+ (UIInterfaceOrientation)interfaceOrientation {
    return AppDelegate.scene.interfaceOrientation;
}

@end

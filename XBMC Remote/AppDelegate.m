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
#import "Kodi_Remote-Swift.h"

#include <arpa/inet.h>
#include <net/if.h>
#include <ifaddrs.h>

@implementation AppDelegate

@synthesize window = _window;
@synthesize navigationController = _navigationController;
@synthesize windowController = _windowController;
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
@synthesize globalSearchMenuLookup;
@synthesize serverName;
@synthesize serverVolume;

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
    
    [self setIdleTimerFromUserDefaults];
    
    // Create and set interface style for window
    self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    [self setInterfaceStyleFromUserDefaults];
    [self.window makeKeyAndVisible];
    
    // Create GlobalDate which holds the Kodi server parameters
    obj = [GlobalData getInstance];
    
    // Create the menu tree
    mainMenuItems = [mainMenu generateMenus];
    
    // Initialize controllers
    self.serverName = LOCALIZED_STR(@"No connection");
    if (IS_IPHONE) {
        InitialSlidingViewController *initialSlidingViewController = [[InitialSlidingViewController alloc] initWithNibName:@"InitialSlidingViewController" bundle:nil];
        initialSlidingViewController.mainMenu = mainMenuItems;
        self.window.rootViewController = initialSlidingViewController;
    }
    else {
        self.windowController = [[ViewControllerIPad alloc] initWithNibName:@"ViewControllerIPad" bundle:nil];
        self.windowController.mainMenu = mainMenuItems;
        self.window.rootViewController = self.windowController;
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

- (void)setIdleTimerFromUserDefaults {
    UIApplication.sharedApplication.idleTimerDisabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"lockscreen_preference"];
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
        self.window.overrideUserInterfaceStyle = style;
    }
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

- (void)applicationWillEnterForeground:(UIApplication*)application {
    [self setIdleTimerFromUserDefaults];
}

- (void)applicationDidBecomeActive:(UIApplication*)application {
    // Trigger Local Network Privacy Alert once after app launch
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        LocalNetworkAlertClass *localNetworkAlert = [LocalNetworkAlertClass new];
        [localNetworkAlert triggerLocalNetworkPrivacyAlert];
    });
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

@end

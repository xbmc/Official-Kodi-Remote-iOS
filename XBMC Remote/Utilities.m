//
//  Utilities.m
//  XBMC Remote
//
//  Created by Giovanni Messina on 4/3/13.
//  Copyright (c) 2013 joethefox inc. All rights reserved.
//

#import <arpa/inet.h>
#import <mach/mach.h>
#import "Utilities.h"
#import "AppDelegate.h"
#import "NSString+MD5.h"
#import "SDWebImageManager.h"
#import "LocalNetworkAccess.h"

@import StoreKit;

#define GET_ROUNDED_EDGES_RADIUS(size) MAX(MIN(size.width, size.height) * 0.03, 6.0)
#define GET_ROUNDED_EDGES_PATH(rect, radius) [UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:radius];
#define RGBA(r, g, b, a) [UIColor colorWithRed:(r) / 255.0 green:(g) / 255.0 blue:(b) / 255.0 alpha:(a)]
#define GAMMA_DEC(x) pow(x, 2.2)
#define GAMMA_ENC(x) pow(x, 1/2.2)
#define XBMC_LOGO_PADDING 10
#define PERSISTENCE_KEY_VERSION @"VersionUnderReview"
#define PERSISTENCE_KEY_PLAYBACK_ATTEMPTS @"PlaybackAttempts"
#define IMAGE_SIZE_COLOR_AVERAGING CGSizeMake(64, 64) // Scale (down) to this size before averaging an image color

@implementation Utilities

+ (BOOL)isImageUsingAlpha:(CGImageRef)imageRef {
    CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(imageRef);
    int infoMask = bitmapInfo & kCGBitmapAlphaInfoMask;
    return infoMask & (kCGImageAlphaPremultipliedFirst | kCGImageAlphaPremultipliedLast | kCGImageAlphaFirst | kCGImageAlphaLast);
}

+ (CGImageRef)createLinearSRGBFromImage:(UIImage*)image size:(CGSize)size {
    CGImageRef inputImageRef = [image CGImage];
    if (inputImageRef == NULL) {
        return NULL;
    }
    
    // For averaging colors a linear color space is required.
    CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceLinearSRGB);
    if (colorSpace == NULL) {
        return NULL;
    }
    
    // Enforce images are converted to default (ARGB or RGB, 32bpp, ByteOrderDefault) before analyzing them
    size = (size.height > 0 && size.width > 0) ? size : CGSizeMake(CGImageGetWidth(inputImageRef), CGImageGetHeight(inputImageRef));
    BOOL anyAlpha = [Utilities isImageUsingAlpha:inputImageRef];
    CGContextRef context = CGBitmapContextCreate(NULL,
                                                 size.width,
                                                 size.height,
                                                 8 /* 8 bits per components */,
                                                 size.width * 4 /* 4 components for ARGB */,
                                                 colorSpace,
                                                 anyAlpha ? kCGImageAlphaPremultipliedFirst : kCGImageAlphaNoneSkipLast);
    CGColorSpaceRelease(colorSpace);
    if (context == NULL) {
        return NULL;
    }
    
    // Redraw to new format
    CGRect rect = CGRectMake(0, 0, CGBitmapContextGetWidth(context), CGBitmapContextGetHeight(context));
    CGContextDrawImage(context, rect, inputImageRef);
    CGImageRef imageRefOut = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    
    return imageRefOut;
}

+ (UIColor*)averageColorForImageRef:(CGImageRef)rawImageRef {
    CFDataRef data = CGDataProviderCopyData(CGImageGetDataProvider(rawImageRef));
    if (data == NULL) {
        return nil;
    }
    const UInt8 *rawPixelData = CFDataGetBytePtr(data);
    
    NSUInteger imageHeight = CGImageGetHeight(rawImageRef);
    NSUInteger imageWidth  = CGImageGetWidth(rawImageRef);
    NSUInteger bytesPerRow = CGImageGetBytesPerRow(rawImageRef);
    NSUInteger bitsPerComp = CGImageGetBitsPerComponent(rawImageRef);
    NSUInteger stride = CGImageGetBitsPerPixel(rawImageRef) / bitsPerComp;
    
    UInt64 red   = 0;
    UInt64 green = 0;
    UInt64 blue  = 0;
    UInt64 alpha = 0;
    CGFloat f = 1.0;
    BOOL formatError = NO;
    
    int alphaInfo = CGImageGetBitmapInfo(rawImageRef) & kCGBitmapAlphaInfoMask;
    if (alphaInfo == kCGImageAlphaNoneSkipLast) {
        // RGB (kCGImageAlphaNoneSkipLast)
        for (int row = 0; row < imageHeight; row++) {
            const UInt8 *rowPtr = rawPixelData + bytesPerRow * row;
            for (int column = 0; column < imageWidth; column++) {
                red    += rowPtr[0];
                green  += rowPtr[1];
                blue   += rowPtr[2];
                rowPtr += stride;
            }
        }
        f = 1.0 / (255.0 * imageWidth * imageHeight);
    }
    else if (alphaInfo == kCGImageAlphaPremultipliedFirst) {
        // weight color with alpha to ignore transparent sections
        // ARGB (kCGImageAlphaPremultipliedFirst)
        for (int row = 0; row < imageHeight; row++) {
            const UInt8 *rowPtr = rawPixelData + bytesPerRow * row;
            for (int column = 0; column < imageWidth; column++) {
                alpha  += rowPtr[0];
                red    += rowPtr[1];
                green  += rowPtr[2];
                blue   += rowPtr[3];
                rowPtr += stride;
            }
        }
        f = 1.0 / alpha;
        formatError = alpha == 0;
    }
    else {
        formatError = YES;
    }
    CFRelease(data);
    
    // No alpha pixels were found or wrong image format was provided.
    if (formatError) {
        return nil;
    }
    
    // We worked in linear sRGB color space for calculating the average (kCGColorSpaceLinearSRGB).
    // Now we need to go back to non-linear sRGB as used in UIColor.
    CGFloat sRGB_red   = GAMMA_ENC(f * red);
    CGFloat sRGB_green = GAMMA_ENC(f * green);
    CGFloat sRGB_blue  = GAMMA_ENC(f * blue);
    return [UIColor colorWithRed:sRGB_red green:sRGB_green blue:sRGB_blue alpha:1];
}

+ (UIColor*)averageColor:(UIImage*)image {
    CGImageRef linearSrgbImageRef = [self createLinearSRGBFromImage:image size:IMAGE_SIZE_COLOR_AVERAGING];
    if (linearSrgbImageRef == NULL) {
        return nil;
    }
    
    UIColor *averageColor = [self averageColorForImageRef:linearSrgbImageRef];
    CGImageRelease(linearSrgbImageRef);
    
    return averageColor;
}

+ (UIColor*)getUIColorFromImage:(UIImage*)image {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    BOOL autocolor_preference = [userDefaults boolForKey:@"autocolor_ui_preference"];
    if (!autocolor_preference) {
        return UI_AVERAGE_DEFAULT_COLOR;
    }
    
    UIColor *uiColor = [Utilities averageColor:image];
    return uiColor ?: UI_AVERAGE_DEFAULT_COLOR;
}

+ (UIColor*)tailorColor:(UIColor*)color satscale:(CGFloat)satscale brightscale:(CGFloat)brightscale brightmin:(CGFloat)brightmin brightmax:(CGFloat)brightmax {
    CGFloat hue, sat, bright, alpha;
    BOOL success = [color getHue:&hue saturation:&sat brightness:&bright alpha:&alpha];
    if (!success) {
        return nil;
    }
    
    // Scale and limit saturation to range [0 ... 1]
    sat = MIN(MAX(sat * satscale, 0), 1);
    // Scale and limit brightness to range [brightmin ... brightmax]
    bright = MIN(MAX(bright * brightscale, brightmin), brightmax);
    return [UIColor colorWithHue:hue saturation:sat brightness:bright alpha:alpha];
}

+ (UIColor*)textTintColor:(UIColor*)color {
    return [Utilities tailorColor:color satscale:0.33 brightscale:1.5 brightmin:0.7 brightmax:0.9];
}

+ (UIColor*)contrastColor:(UIColor*)color lightColor:(UIColor*)lighter darkColor:(UIColor*)darker {
    CGFloat red, green, blue, alpha;
    BOOL success = [color getRed:&red green:&green blue:&blue alpha:&alpha];
    
    // Reference https://stackoverflow.com/questions/596216/formula-to-determine-perceived-brightness-of-rgb-color
    // Relative luminance for sRGB BT.709 using approximate linearization with gamma 2.2 and weighting
    // Middle contrast of relative luminance is around 0.36-0.37
    CGFloat luminance = GAMMA_DEC(red) * 0.2126 + GAMMA_DEC(green) * 0.7152 + GAMMA_DEC(blue) * 0.0722;
    return (!success || luminance < 0.36) ? lighter : darker;
}

+ (UIColor*)sectionGradientTopColor:(UIColor*)color {
    CGFloat hue, sat, bright, alpha;
    BOOL success = [color getHue:&hue saturation:&sat brightness:&bright alpha:&alpha];
    if (!success) {
        return color;
    }
    
    // Limit saturation
    sat = MIN(MAX(sat, 0), 0.33);
    // Limit brightness range
    bright = MIN(MAX(bright, 0.4), 0.8);
    return [UIColor colorWithHue:hue saturation:sat brightness:bright alpha:alpha];
}

+ (UIColor*)sectionGradientBottomColor:(UIColor*)color {
    color = [Utilities sectionGradientTopColor:color];
    
    CGFloat hue, sat, bright, alpha;
    BOOL success = [color getHue:&hue saturation:&sat brightness:&bright alpha:&alpha];
    if (!success) {
        return color;
    }
    
    // Desaturate bottom stronger than top
    sat = MIN(MAX(sat * 0.33, 0), 1);
    // Make bottom slightly brighter than top
    bright = MIN(MAX(bright + 0.1, 0.0), 1.0);
    return [UIColor colorWithHue:hue saturation:sat brightness:bright alpha:alpha];
}

+ (UIImage*)colorizeImage:(UIImage*)image withColor:(UIColor*)color {
    if (color == nil || image.size.width == 0 || image.size.height == 0) {
        return image;
    }
    CGRect contextRect = (CGRect) {.origin = CGPointZero, .size = image.size};
    UIImage *newImage = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    UIGraphicsBeginImageContextWithOptions(newImage.size, NO, newImage.scale);
    [color set];
    [newImage drawInRect:contextRect];
    newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

+ (UIImage*)setLightDarkModeImageAsset:(UIImage*)image lightColor:(UIColor*)lightColor darkColor:(UIColor*)darkColor {
    if (@available(iOS 13.0, *)) {
        UITraitCollection *scale = [UITraitCollection currentTraitCollection];
        UITraitCollection *lightUI = [UITraitCollection traitCollectionWithUserInterfaceStyle:UIUserInterfaceStyleLight];
        UITraitCollection *darkUI = [UITraitCollection traitCollectionWithUserInterfaceStyle:UIUserInterfaceStyleDark];
        UITraitCollection *lightScaledTC = [UITraitCollection traitCollectionWithTraitsFromCollections:@[scale, lightUI]];
        UITraitCollection *darkScaledTC = [UITraitCollection traitCollectionWithTraitsFromCollections:@[scale, darkUI]];
        UITraitCollection *lightTraitCollection = [UITraitCollection traitCollectionWithUserInterfaceStyle:UIUserInterfaceStyleLight];
        UITraitCollection *darkTraitCollection = [UITraitCollection traitCollectionWithUserInterfaceStyle:UIUserInterfaceStyleDark];
        
        __block UIImage *lightImage = image;
        [darkScaledTC performAsCurrentTraitCollection:^{
            lightImage = [Utilities colorizeImage:lightImage withColor:lightColor];
            lightImage = [lightImage imageWithConfiguration:[lightImage.configuration configurationWithTraitCollection:lightTraitCollection]];
        }];
        
        __block UIImage *darkImage = image;
        [lightScaledTC performAsCurrentTraitCollection:^{
            darkImage = [Utilities colorizeImage:darkImage withColor:darkColor];
            darkImage = [darkImage imageWithConfiguration:[darkImage.configuration configurationWithTraitCollection:darkTraitCollection]];
        }];
        
        [lightImage.imageAsset registerImage:darkImage withTraitCollection:darkTraitCollection];
        return lightImage;
    }
    else {
        image = [Utilities colorizeImage:image withColor:lightColor];
        return image;
    }
}

+ (void)setLogoBackgroundColor:(UIImageView*)imageview mode:(LogoBackgroundType)mode {
    UIColor *bgcolor = UIColor.clearColor;
    UIColor *imgcolor = nil;
    UIColor *bglight = SYSTEMGRAY6_LIGHTMODE;
    UIColor *bgdark = SYSTEMGRAY6_DARKMODE;
    switch (mode) {
        case LogoBackgroundAuto:
            // get background color and colorize the image background
            imgcolor = [Utilities averageColor:imageview.image];
            bgcolor = [Utilities contrastColor:imgcolor lightColor:bglight darkColor:bgdark];
            break;
        case LogoBackgroundLight:
            bgcolor = bglight;
            break;
        case LogoBackgroundDark:
            bgcolor = bgdark;
            break;
        case LogoBackgroundTransparent:
            // bgcolor already defined to clearColor as default
            break;
        default:
            NSLog(@"setLogoBackgroundColor: unknown mode %ld", mode);
            break;
    }
    imageview.backgroundColor = bgcolor;
}

+ (BOOL)getPreferTvPosterMode {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    BOOL result = [userDefaults boolForKey:@"prefer_TVposter_preference"];
    return result;
}

+ (LogoBackgroundType)getLogoBackgroundMode {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    LogoBackgroundType setting = LogoBackgroundAuto;
    NSString *mode = [userDefaults stringForKey:@"logo_background"];
    if (mode.length) {
        if ([mode isEqualToString:@"dark"]) {
            setting = LogoBackgroundDark;
        }
        else if ([mode isEqualToString:@"light"]) {
            setting = LogoBackgroundLight;
        }
        else if ([mode isEqualToString:@"trans"]) {
            setting = LogoBackgroundTransparent;
        }
    }
    return setting;
}

+ (NSDictionary*)buildPlayerSeekPercentageParams:(int)playerID percentage:(float)percentage {
    NSDictionary *params = nil;
    if (AppDelegate.instance.serverVersion < 15) {
        params = @{
            @"playerid": @(playerID),
            @"value": @(percentage),
        };
    }
    else {
        params = @{
            @"playerid": @(playerID),
            @"value": @{@"percentage": @(percentage)},
        };
    }
    return params;
}

+ (NSDictionary*)buildPlayerSeekStepParams:(NSString*)stepmode {
    NSDictionary *params = nil;
    if (AppDelegate.instance.serverVersion < 15) {
        params = @{@"value": stepmode};
    }
    else {
        params = @{@"value": @{@"step": stepmode}};
    }
    return params;
}

+ (CGFloat)getTransformX {
    // We scale for iPhone with their different device widths.
    if (IS_IPHONE) {
        return (GET_MAINSCREEN_WIDTH / IPHONE_SCREEN_DESIGN_WIDTH);
    }
    // For iPad a fixed frame width is used.
    else {
        return (STACKSCROLL_WIDTH / IPAD_SCREEN_DESIGN_WIDTH);
    }
}

+ (CGRect)createCoverInsideJewel:(UIImageView*)jewelView jewelType:(JewelType)type {
    CGFloat border_right, border_bottom, border_top, border_left;
    // Setup the border width on all 4 sides for each jewel case type
    switch (type) {
        case JewelTypeCD:
            border_right  = 14;
            border_bottom = 15;
            border_top    = 11;
            border_left   = 32;
            break;
        case JewelTypeDVD:
            border_right  = 10;
            border_bottom = 14;
            border_top    = 11;
            border_left   = 35;
            break;
        case JewelTypeTV:
            border_right  = 10;
            border_bottom = 26;
            border_top    = 10;
            border_left   = 15;
            break;
        default:
            return CGRectZero;
            break;
    }
    CGFloat factor = MIN(jewelView.frame.size.width / jewelView.image.size.width, jewelView.frame.size.height / jewelView.image.size.height);
    CGRect frame = jewelView.frame;
    frame.size.width = ceil((jewelView.image.size.width - border_left - border_right) * factor);
    frame.size.height = ceil((jewelView.image.size.height - border_top - border_bottom) * factor);
    frame.origin.y = floor(jewelView.center.y - frame.size.height / 2 + (border_top - border_bottom) / 2 * factor);
    frame.origin.x = floor(jewelView.center.x - frame.size.width / 2 + (border_left - border_right) / 2 * factor);
    return frame;
}

+ (UIAlertController*)createAlertOK:(NSString*)title message:(NSString*)msg {
    UIAlertController *alertCtrl = [UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okButton = [UIAlertAction actionWithTitle:LOCALIZED_STR(@"OK") style:UIAlertActionStyleDefault handler:nil];
    [alertCtrl addAction:okButton];
    return alertCtrl;
}

+ (UIAlertController*)createAlertCopyClipboard:(NSString*)title message:(NSString*)msg {
    UIAlertController *alertCtrl = [UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *copyButton = [UIAlertAction actionWithTitle:LOCALIZED_STR(@"Copy to clipboard") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
            pasteboard.string = msg;
    }];
    UIAlertAction *cancelButton = [UIAlertAction actionWithTitle:LOCALIZED_STR(@"Cancel") style:UIAlertActionStyleCancel handler:nil];
    [alertCtrl addAction:copyButton];
    [alertCtrl addAction:cancelButton];
    return alertCtrl;
}

+ (void)powerAction:(NSString*)command onSuccess:(void (^)(void))onSuccess {
    [[Utilities getJsonRPC] callMethod:command withParameters:@{} onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *error) {
        // User already confirmed, so we only show a short-lived message.
        if (methodError == nil && error == nil) {
            [Utilities showMessage:LOCALIZED_STR(@"Command executed") color:SUCCESS_MESSAGE_COLOR];
            if (onSuccess) {
                onSuccess();
            }
        }
        else {
            [Utilities showMessage:LOCALIZED_STR(@"Cannot do that") color:ERROR_MESSAGE_COLOR];
        }
    }];
}

+ (UIAlertController*)createPowerControl {
    NSString *title = [NSString stringWithFormat:@"%@\n%@", AppDelegate.instance.obj.serverDescription, AppDelegate.instance.obj.serverIP];
    UIAlertController *alertCtrl = [UIAlertController alertControllerWithTitle:title message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    if (!AppDelegate.instance.serverOnLine) {
        UIAlertAction *action_wake = [UIAlertAction actionWithTitle:LOCALIZED_STR(@"Send Wake-On-LAN") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            // In this case we want to have a user interaction popup instead of a short-lived message.
            if ([Utilities isValidMacAddress:AppDelegate.instance.obj.serverHWAddr]) {
                [Utilities wakeUp:AppDelegate.instance.obj.serverHWAddr];
                [Utilities showMessage:LOCALIZED_STR(@"Command executed") color:SUCCESS_MESSAGE_COLOR];
            }
            else {
                [Utilities showMessage:LOCALIZED_STR(@"No server MAC address defined") color:ERROR_MESSAGE_COLOR];
            }
        }];
        [alertCtrl addAction:action_wake];
    }
    else {
        UIAlertAction *action_pwr_off_system = [UIAlertAction actionWithTitle:LOCALIZED_STR(@"Power off System") style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
            [self powerAction:@"System.Shutdown" onSuccess:^{
                [Utilities stopPollingActiveServer];
            }];
        }];
        [alertCtrl addAction:action_pwr_off_system];
        
        UIAlertAction *action_quit_kodi = [UIAlertAction actionWithTitle:LOCALIZED_STR(@"Quit XBMC application") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [self powerAction:@"Application.Quit" onSuccess:^{
                [Utilities stopPollingActiveServer];
            }];
        }];
        [alertCtrl addAction:action_quit_kodi];
        
        UIAlertAction *action_hibernate = [UIAlertAction actionWithTitle:LOCALIZED_STR(@"Hibernate") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [self powerAction:@"System.Hibernate" onSuccess:^{
                [Utilities stopPollingActiveServer];
            }];
        }];
        [alertCtrl addAction:action_hibernate];
        
        UIAlertAction *action_suspend = [UIAlertAction actionWithTitle:LOCALIZED_STR(@"Suspend") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [self powerAction:@"System.Suspend" onSuccess:^{
                [Utilities stopPollingActiveServer];
            }];
        }];
        [alertCtrl addAction:action_suspend];
        
        UIAlertAction *action_reboot = [UIAlertAction actionWithTitle:LOCALIZED_STR(@"Reboot") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [self powerAction:@"System.Reboot" onSuccess:nil];
        }];
        [alertCtrl addAction:action_reboot];
        
        UIAlertAction *action_scan_audio_lib = [UIAlertAction actionWithTitle:LOCALIZED_STR(@"Update Audio Library") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [self powerAction:@"AudioLibrary.Scan" onSuccess:nil];
        }];
        [alertCtrl addAction:action_scan_audio_lib];
        
        UIAlertAction *action_clean_audio_lib = [UIAlertAction actionWithTitle:LOCALIZED_STR(@"Clean Audio Library") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [self powerAction:@"AudioLibrary.Clean" onSuccess:nil];
        }];
        [alertCtrl addAction:action_clean_audio_lib];
        
        UIAlertAction *action_scan_video_lib = [UIAlertAction actionWithTitle:LOCALIZED_STR(@"Update Video Library") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [self powerAction:@"VideoLibrary.Scan" onSuccess:nil];
        }];
        [alertCtrl addAction:action_scan_video_lib];
        
        UIAlertAction *action_clean_video_lib = [UIAlertAction actionWithTitle:LOCALIZED_STR(@"Clean Video Library") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [self powerAction:@"VideoLibrary.Clean" onSuccess:nil];
        }];
        [alertCtrl addAction:action_clean_video_lib];
    }
    
    UIAlertAction *cancelButton = [UIAlertAction actionWithTitle:LOCALIZED_STR(@"Cancel") style:UIAlertActionStyleCancel handler:nil];
    [alertCtrl addAction:cancelButton];
    alertCtrl.modalPresentationStyle = UIModalPresentationPopover;
    
    return alertCtrl;
}

+ (void)SFloadURL:(NSString*)url fromctrl:(UIViewController<SFSafariViewControllerDelegate>*)fromctrl {
    NSURL *nsurl = [NSURL URLWithString:url];
    SFSafariViewController *svc = nil;
    // Try to load the URL via SFSafariViewController. If this is not possible, check if this is loadable
    // with other system applications. If so, load it. If not, show an error popup.
    @try {
        svc = [[SFSafariViewController alloc] initWithURL:nsurl];
    } @catch (NSException *exception) {
        if ([UIApplication.sharedApplication canOpenURL:nsurl]) {
            [UIApplication.sharedApplication openURL:nsurl options:@{} completionHandler:nil];
        }
        else {
            UIAlertController *alertCtrl = [Utilities createAlertOK:LOCALIZED_STR(@"Error loading page") message:exception.reason];
            [fromctrl presentViewController:alertCtrl animated:YES completion:nil];
        }
        return;
    }
    UIViewController *ctrl = fromctrl;
    svc.delegate = fromctrl;
    if (IS_IPAD) {
        // On iPad presenting from the active ViewController results in blank screen
        ctrl = UIApplication.sharedApplication.keyWindow.rootViewController;
    }
    if (![svc isBeingPresented]) {
        if (ctrl.presentedViewController) {
            [ctrl dismissViewControllerAnimated:YES completion:nil];
        }
        [ctrl presentViewController:svc animated:YES completion:nil];
    }
}

+ (void)showLocalNetworkAccessError:(UIViewController*)viewCtrl {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    BOOL showLocalNetworkNotice = [userDefaults boolForKey:@"local_network_info_preference"];
    if (showLocalNetworkNotice) {
        NSString *message = LOCALIZED_STR(@"It seems local network access is not enabled for the Kodi Remote App. This is required for the app to find and connect to Kodi servers in your local network.");
        NSString *fix = LOCALIZED_STR(@"The local network access can be enabled in the iOS network or in the app settings. You might need to reset your network settings, restart your iOS device or even remove/re-install the app to let this take effect.");
        UIAlertController *alertCtrl = [UIAlertController alertControllerWithTitle:LOCALIZED_STR(@"Local network notice")
                                                                           message:[NSString stringWithFormat:@"%@\n\n%@", message, fix]
                                                                    preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okButton = [UIAlertAction actionWithTitle:LOCALIZED_STR(@"OK")
                                                           style:UIAlertActionStyleDefault
                                                         handler:nil];
        UIAlertAction *dontShowButton = [UIAlertAction
                                         actionWithTitle:LOCALIZED_STR(@"Don't show this message again")
                                         style:UIAlertActionStyleDestructive
                                         handler:^(UIAlertAction *action) {
            [Utilities disableLocalNetworkconnectionNotice];
        }];
        [alertCtrl addAction:dontShowButton];
        [alertCtrl addAction:okButton];
        
        [viewCtrl presentViewController:alertCtrl animated:YES completion:nil];
    }
}

+ (void)disableLocalNetworkconnectionNotice {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setBool:NO forKey:@"local_network_info_preference"];
}

+ (void)showMessage:(NSString*)messageText color:(UIColor*)messageColor {
    if (!messageText || ![messageColor isKindOfClass:[UIColor class]]) {
        return;
    }
    NSDictionary *params = @{
        @"message": messageText,
        @"color": messageColor,
    };
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UIShowMessage" object:nil userInfo:params];
}

+ (DSJSONRPC*)getJsonRPC {
    static DSJSONRPC *jsonRPC;
    static NSString *checkRPC;
    
    // Calculate checksum for requested JSONRPC configuration
    NSString *text = [NSString stringWithFormat:@"%@ %@", AppDelegate.instance.getServerJSONEndPoint, AppDelegate.instance.getServerHTTPHeaders];
    NSString *checksum = [text SHA256String];
    
    // Create JSONRPC object if not yet created or new configuration is required
    if (jsonRPC == nil || ![checkRPC isEqualToString:checksum]) {
        jsonRPC = [[DSJSONRPC alloc] initWithServiceEndpoint:AppDelegate.instance.getServerJSONEndPoint
                                              andHTTPHeaders:AppDelegate.instance.getServerHTTPHeaders];
        checkRPC = checksum;
    }
    return jsonRPC;
}

+ (void)setWebImageAuthorizationOnSuccessNotification:(NSNotification*)note {
    if ([note.name isEqualToString:@"XBMCServerConnectionSuccess"]) {
        SDWebImageDownloader *manager = [SDWebImageManager sharedManager].imageDownloader;
        NSDictionary *httpHeaders = AppDelegate.instance.getServerHTTPHeaders;
        if (httpHeaders[@"Authorization"] != nil) {
            [manager setValue:httpHeaders[@"Authorization"] forHTTPHeaderField:@"Authorization"];
        }
    }
}

+ (NSString*)convertTimeFromSeconds:(NSNumber*)seconds {
    NSString *result = @"";
    if (![seconds respondsToSelector:@selector(intValue)]) {
        return result;
    }
    int secs = [seconds intValue];
    int hour   = secs / 3600;
    int minute = secs / 60 - hour * 60;
    int second = secs - (hour * 3600 + minute * 60);
    result = [NSString stringWithFormat:@"%02d:%02d", minute, second];
    if (hour > 0) {
        result = [NSString stringWithFormat:@"%02d:%@", hour, result];
    }
    return result;
}

+ (NSString*)getItemIconFromDictionary:(NSDictionary*)dict {
    NSString *iconName = @"";
    if (dict[@"filetype"] != nil) {
        NSString *filetype = dict[@"filetype"];
        if ([filetype isEqualToString:@"directory"]) {
            iconName = @"nocover_filemode";
        }
        else if ([filetype isEqualToString:@"file"]) {
            iconName = @"icon_file";
        }
    }
    return iconName;
}

+ (NSString*)getStringFromItem:(id)item {
    NSString *text = @"";
    if (item == nil || [item isKindOfClass:[NSNull class]]) {
        text = @"";
    }
    else if ([item isKindOfClass:[NSArray class]]) {
        text = [item componentsJoinedByString:@" / "];
        text = text.length == 0 ? @"" : text;
    }
    else if ([item isKindOfClass:[NSNumber class]]) {
        text = [NSString stringWithFormat:@"%@", item];
    }
    else {
        text = [item length] == 0 ? @"" : item;
    }
    return text;
}

+ (NSNumber*)getNumberFromItem:(id)item {
    NSNumber *value = @(0);
    if (!item) {
        return value;
    }
    // Check for longLongValue as this is supported by both NSNumber and NSString.
    // If longLongValue value is not supported, convert via NSString.
    if ([item respondsToSelector:@selector(longLongValue)]) {
        value = @([item longLongValue]);
    }
    else {
        value = @([[Utilities getStringFromItem:item] longLongValue]);
    }
    return value;
}

+ (NSString*)getTimeFromItem:(id)item sec2min:(int)secondsToMinute {
    NSString *runtime = @"";
    if (item == nil || [item isKindOfClass:[NSNull class]]) {
        runtime = @"";
    }
    else if ([item isKindOfClass:[NSArray class]]) {
        runtime = [item componentsJoinedByString:@" / "];
    }
    else if ([item intValue] > 0) {
        int minutes = [item intValue] / secondsToMinute;
        runtime = minutes ? [NSString stringWithFormat:@"%d min", minutes] : [NSString stringWithFormat:@"<1 min"];
    }
    return runtime;
}

+ (NSString*)getYearFromItem:(id)item {
    NSString *year = @"";
    if (item == nil || [item isKindOfClass:[NSNull class]]) {
        year = @"";
    }
    else if ([item isKindOfClass:[NSNumber class]]) {
        if ([item integerValue] > 0) {
            year = [item stringValue];
        }
        else {
            year = @"";
        }
    }
    else if ([item isKindOfClass:[NSArray class]]) {
        year = [item componentsJoinedByString:@" / "];
    }
    else if ([item integerValue] > 0) {
        year = item;
    }
    return year;
}

+ (float)getFloatValueFromItem:(id)item {
    float floatval = 0.0f;
    if ([item respondsToSelector:@selector(floatValue)]) {
        floatval = [item floatValue];
    }
    return floatval;
}

+ (NSString*)getRatingFromItem:(id)item {
    NSString *rating = @"";
    float ratingValue = [Utilities getFloatValueFromItem:item];
    if (ratingValue > 0) {
        rating = [NSString stringWithFormat:@"%.1f", ratingValue];
    }
    return rating;
}

+ (NSString*)getClearArtFromDictionary:(NSDictionary*)dict type:(NSString*)type {
    // 1st preference: "albumartist.clearart" to prefer albumartist clearart.
    NSString *albumArtistClearArtPath = dict[[NSString stringWithFormat:@"albumartist.%@", type]];
    if (albumArtistClearArtPath) {
        return albumArtistClearArtPath;
    }
    
    // 2nd preference: "clearart" w/o any prefix to prefer movie over set clearart.
    NSString *pureClearArtPath = dict[type];
    if (pureClearArtPath) {
        return pureClearArtPath;
    }
    
    // Search for any "clearart"
    NSString *path = @"";
    for (NSString *key in dict) {
        if ([key rangeOfString:type].location != NSNotFound) {
            path = dict[key];
            break; // We want to leave the loop after we found what we were searching for
        }
    }
    return path;
}

+ (NSString*)getThumbnailFromDictionary:(NSDictionary*)dict useBanner:(BOOL)useBanner useIcon:(BOOL)useIcon {
    NSString *thumbnailPath = dict[@"thumbnail"];
    NSDictionary *art = dict[@"art"];
    if ([art[@"poster"] length] != 0) {
        thumbnailPath = art[@"poster"];
    }
    if (useBanner && [art[@"banner"] length] != 0) {
        thumbnailPath = art[@"banner"];
    }
    if (useIcon && [art[@"icon"] length] != 0) {
        thumbnailPath = art[@"icon"];
    }
    return thumbnailPath;
}

+ (NSString*)getDateFromItem:(id)item dateStyle:(NSDateFormatterStyle)dateStyle {
    NSString *dateString = @"";
    if ([item isKindOfClass:[NSString class]] && [item length] > 0) {
        NSDateFormatter *format = [NSDateFormatter new];
        format.locale = [NSLocale currentLocale];
        format.dateFormat = @"yyyy-MM-dd";
        NSDate *date = [format dateFromString:item];
        format.dateStyle = dateStyle;
        dateString = [format stringFromDate:date];
    }
    return dateString;
}

+ (int)getSec2Min:(BOOL)convert {
    return (AppDelegate.instance.serverVersion > 11 && convert) ? 60 : 1;
}

+ (NSString*)getImageServerURL {
    GlobalData *obj = [GlobalData getInstance];
    NSString *stringFormat = (AppDelegate.instance.serverVersion > 11) ? @"%@:%@/image/" : @"%@:%@/vfs/";
    return [NSString stringWithFormat:stringFormat, obj.serverIP, obj.serverPort];
}

+ (NSString*)formatStringURL:(NSString*)path serverURL:(NSString*)serverURL {
    NSString *urlString = @"";
    if (path.length > 0 && ![path isEqualToString:@"(null)"]) {
        if (![path hasPrefix:@"image://"]) {
            urlString = path;
        }
        else {
            urlString = [NSString stringWithFormat:@"http://%@%@", serverURL, [path stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLPathAllowedCharacterSet]]];
        }
    }
    return urlString;
}

+ (UIImage*)roundedCornerImage:(UIImage*)image {
    if (image.size.width == 0 || image.size.height == 0) {
        return image;
    }
    
    CGRect imageRect = CGRectMake(0, 0, image.size.width, image.size.height);
    UIGraphicsBeginImageContextWithOptions(image.size, NO, 0);

    // Set radius for corners
    CGFloat radius = GET_ROUNDED_EDGES_RADIUS(image.size);
    
    // Define our path, capitalizing on UIKit's corner rounding magic
    UIBezierPath *path = GET_ROUNDED_EDGES_PATH(imageRect, radius);
    [path addClip];

    // Draw the image into the implicit context
    [image drawInRect:imageRect];
     
    // Get image and cleanup
    UIImage *roundedCornerImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return roundedCornerImage;
}

+ (void)roundedCornerView:(UIView*)view {
    view.layer.cornerRadius = GET_ROUNDED_EDGES_RADIUS(view.layer.frame.size);
}

+ (UIImage*)applyRoundedEdgesImage:(UIImage*)image {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    BOOL corner_preference = [userDefaults boolForKey:@"rounded_corner_preference"];
    if (corner_preference) {
        image = [Utilities roundedCornerImage:image];
    }
    return image;
}

+ (void)applyRoundedEdgesView:(UIView*)view {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    BOOL corner_preference = [userDefaults boolForKey:@"rounded_corner_preference"];
    if (corner_preference) {
        [Utilities roundedCornerView:view];
    }
}

+ (CGFloat)getBottomPadding {
    CGFloat bottomPadding = UIApplication.sharedApplication.keyWindow.safeAreaInsets.bottom;
    return bottomPadding;
}

+ (CGFloat)getTopPadding {
    CGFloat topPadding = UIApplication.sharedApplication.keyWindow.safeAreaInsets.top;
    return topPadding;
}

+ (CGFloat)getTopPaddingWithNavBar:(UINavigationController*)navCtrl {
    CGFloat topPadding = UIApplication.sharedApplication.statusBarFrame.size.height + navCtrl.navigationBar.frame.size.height;
    return topPadding;
}

+ (void)sendXbmcHttp:(NSString*)command {
    GlobalData *obj = [GlobalData getInstance];
    NSString *userPassword = obj.serverPass.length ? [NSString stringWithFormat:@":%@", obj.serverPass] : @"";
    NSString *serverHTTP = [NSString stringWithFormat:@"http://%@%@@%@:%@/xbmcCmds/xbmcHttp?command=%@", obj.serverUser, userPassword, obj.serverIP, obj.serverPort, command];
    [[NSURLSession.sharedSession dataTaskWithURL:[NSURL URLWithString:serverHTTP]] resume];
}

+ (NSString*)getAppVersionString {
    NSDictionary *infoDict = NSBundle.mainBundle.infoDictionary;
    NSString *appVersion = [NSString stringWithFormat:@"v%@ (%@)", infoDict[@"CFBundleShortVersionString"], infoDict[(NSString*)kCFBundleVersionKey]];
    return appVersion;
}

+ (void)showReviewController {
    [SKStoreReviewController requestReview];
}

+ (void)checkForReviewRequest {
    NSString *currentVersion = [Utilities getAppVersionString];
    NSString *savedVersion = [[NSUserDefaults standardUserDefaults] stringForKey:PERSISTENCE_KEY_VERSION];
    // Compare current version with version under review
    if (![savedVersion isEqualToString:currentVersion]) {
        // Reset counter to 0 for new version
        [[NSUserDefaults standardUserDefaults] setObject:currentVersion forKey:PERSISTENCE_KEY_VERSION];
        [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:PERSISTENCE_KEY_PLAYBACK_ATTEMPTS];
    }
    else {
        // Read and increase count by 1
        NSInteger count = [[NSUserDefaults standardUserDefaults] integerForKey:PERSISTENCE_KEY_PLAYBACK_ATTEMPTS] + 1;
        [[NSUserDefaults standardUserDefaults] setInteger:count forKey:PERSISTENCE_KEY_PLAYBACK_ATTEMPTS];
        
        // Show review popup after 20th, 100th, 200th attempt, and each 200th from then on
        // From AppStore metrics it is evident that 50 equals 3+ months for majority of users
        if (count == 20 || count == 100 || count == 200 || count % 200 == 0) {
            [Utilities showReviewController];
        }
    }
}

+ (void)checkLocalNetworkAccess {
    LocalNetworkAccess *localNetworkAccess = [LocalNetworkAccess new];
    [localNetworkAccess checkAccessState:^(BOOL granted) {
        if (!granted) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"LocalNetworkAccessError" object:nil userInfo:nil];
        }
    }];
}

+ (NSString*)getConnectionStatusIconName {
    NSString *iconName = @"connection_off";
    if (AppDelegate.instance.serverOnLine) {
        if (AppDelegate.instance.serverTCPConnectionOpen) {
            iconName = @"connection_on";
        }
        else {
            iconName = @"connection_on_notcp";
        }
    }
    return iconName;
}

+ (NSString*)getConnectionStatusServerName {
    NSString *serverName = @"No connection";
    if (AppDelegate.instance.serverOnLine) {
        serverName = AppDelegate.instance.serverName;
    }
    return serverName;
}

+ (void)addShadowsToView:(UIView*)view viewFrame:(CGRect)frame {
    view.clipsToBounds = NO;
    
    // Shadow on left side of movable screen
    CGRect shadowRect = CGRectMake(-PANEL_SHADOW_SIZE,
                                   0,
                                   PANEL_SHADOW_SIZE,
                                   frame.size.height);
    UIImageView *shadowLeft = [[UIImageView alloc] initWithFrame:shadowRect];
    shadowLeft.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    shadowLeft.image = [UIImage imageNamed:@"tableLeft"];
    shadowLeft.opaque = YES;
    [view addSubview:shadowLeft];
    
    // Shadow on right side of movable screen
    shadowRect = CGRectMake(frame.size.width,
                            0,
                            PANEL_SHADOW_SIZE,
                            frame.size.height);
    UIImageView *shadowRight = [[UIImageView alloc] initWithFrame:shadowRect];
    shadowRight.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleLeftMargin;
    shadowRight.image = [UIImage imageNamed:@"tableRight"];
    shadowRight.opaque = YES;
    [view addSubview:shadowRight];
    
    if (IS_IPAD) {
        // Shadow on top of movable screen
        shadowRect = CGRectMake(-PANEL_SHADOW_SIZE,
                                -PANEL_SHADOW_SIZE,
                                frame.size.width + 2 * PANEL_SHADOW_SIZE,
                                PANEL_SHADOW_SIZE);
        UIImageView *shadowUp = [[UIImageView alloc] initWithFrame:shadowRect];
        shadowUp.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        shadowUp.image = [UIImage imageNamed:@"stackScrollUpShadow"];
        [view insertSubview:shadowUp atIndex:1];
    }
}

+ (void)setStyleOfMenuItemCell:(UITableViewCell*)cell active:(BOOL)active menuType:(MenuItemType)type {
    // Connection status and App settings are always visible. Those should not be faded/unfaded.
    active = active || type == TypeServer || type == TypeAppSettings;
    CGFloat alpha = active ? 1.0 : 0.3;
    UIImageView *icon = (UIImageView*)[cell viewWithTag:XIB_MAIN_MENU_CELL_ICON];
    UILabel *title = (UILabel*)[cell viewWithTag:XIB_MAIN_MENU_CELL_TITLE];
    icon.alpha = alpha;
    title.alpha = alpha;
}

+ (void)setStyleOfMenuItems:(UITableView*)tableView active:(BOOL)active menu:(NSArray*)menuList {
    for (NSIndexPath *indexPath in tableView.indexPathsForVisibleRows) {
        mainMenu *menuItem = menuList[indexPath.row];
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        [UIView animateWithDuration:0.3
                         animations:^{
                            [Utilities setStyleOfMenuItemCell:cell active:active menuType:menuItem.type];
                         }];
    }
}

+ (NSIndexPath*)getIndexPathForDefaultController:(NSArray*)menuItems {
    // Read the default controller from the app settings
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *startId = [userDefaults stringForKey:@"start_menu"];
    
    // Map startId to MenuItemType (default = TypeNone = 0)
    NSDictionary *defaultMenus = @{
        @"start_menu_main": @(TypeNone),
        @"start_menu_music": @(TypeMusic),
        @"start_menu_movies": @(TypeMovies),
        @"start_menu_videos": @(TypeVideos),
        @"start_menu_tvshows": @(TypeTvShows),
        @"start_menu_pictures": @(TypePictures),
        @"start_menu_livetv": @(TypeLiveTv),
        @"start_menu_radio": @(TypeRadio),
        @"start_menu_favourites": @(TypeFavourites),
        @"start_menu_nowplaying": @(TypeNowPlaying),
        @"start_menu_remote": @(TypeRemote),
        @"start_menu_search": @(TypeGlobalSearch),
        @"start_menu_files": @(TypeFiles),
        @"start_menu_addons": @(TypeAddons),
        @"start_menu_settings": @(TypeKodiSettings),
    };
    MenuItemType startMenuType = [defaultMenus[startId] intValue];
    
    // Search for the index path of the desired controller
    NSUInteger index = [menuItems indexOfObjectPassingTest:^BOOL(mainMenu *item, NSUInteger idx, BOOL *stop) {
      return item.type == startMenuType;
    }];
    return index != NSNotFound ? [NSIndexPath indexPathForRow:index inSection:0] : nil;
}

+ (void)enableDefaultController:(id<UITableViewDelegate>)viewController tableView:(UITableView*)tableView menuItems:(NSArray*)menuItems {
    NSIndexPath *indexPath = [self getIndexPathForDefaultController:menuItems];
    if (indexPath) {
        NSIndexPath *selectedPath = [tableView indexPathForSelectedRow];
        // Deselect any active view, except it is the desired view
        if (selectedPath && indexPath.row != selectedPath.row) {
            [tableView deselectRowAtIndexPath:selectedPath animated:YES];
        }
        // Select the desired view, except it is already up
        if (!selectedPath || indexPath.row != selectedPath.row) {
            [viewController tableView:tableView didSelectRowAtIndexPath:indexPath];
        }
    }
}

+ (id)unarchivePath:(NSString*)path file:(NSString*)filename {
    NSString *filePath = [path stringByAppendingPathComponent:filename];
    NSData *data = [[NSFileManager defaultManager] contentsAtPath:filePath];
    NSError *error;
    NSSet *objectClasses = [NSSet setWithArray:@[
        // Supported non-mutable classes
        [NSDictionary class],
        [NSString class],
        [NSArray class],
        [NSNumber class],
        [NSDate class],
        [NSData class],
        // Supported mutable classes
        [NSMutableDictionary class],
        [NSMutableString class],
        [NSMutableArray class],
    ]];
    id unarchived = [NSKeyedUnarchiver unarchivedObjectOfClasses:objectClasses
                                                     fromData:data
                                                        error:&error];
    return unarchived;
}

+ (void)archivePath:(NSString*)path file:(NSString*)filename data:(id)data {
    NSString *filePath = [path stringByAppendingPathComponent:filename];
    NSError *error;
    NSData *archiveData = [NSKeyedArchiver archivedDataWithRootObject:data requiringSecureCoding:NO error:&error];
    if (!error) {
        [archiveData writeToFile:filePath options:NSDataWritingAtomic error:&error];
    }
}

+ (float)getPercentElapsed:(NSDate*)startDate EndDate:(NSDate*)endDate {
    float total_seconds = [endDate timeIntervalSince1970] - [startDate timeIntervalSince1970];
    float elapsed_seconds = [[NSDate date] timeIntervalSince1970] - [startDate timeIntervalSince1970];
    float percent_elapsed = total_seconds > 0 ? (elapsed_seconds / total_seconds) * 100.0f : 0.0f;
    return percent_elapsed;
}

+ (void)createTransparentToolbar:(UIToolbar*)toolbar {
    [toolbar setBackgroundImage:[UIImage new]
             forToolbarPosition:UIBarPositionAny
                     barMetrics:UIBarMetricsDefault];
    [toolbar setShadowImage:[UIImage new]
         forToolbarPosition:UIBarPositionAny];
}

+ (NSString*)formatTVShowStringForSeasonLeading:(id)season episode:(id)episode title:(NSString*)title {
    NSString *seasonAndEpisode = [Utilities formatTVShowStringForSeason:season episode:episode];
    NSString *text = [NSString stringWithFormat:@"%@%@%@", seasonAndEpisode, seasonAndEpisode.length ? @" " : @"", title];
    return text;
}

+ (NSString*)formatTVShowStringForSeasonTrailing:(id)season episode:(id)episode title:(NSString*)title {
    NSString *seasonAndEpisode = [Utilities formatTVShowStringForSeason:season episode:episode];
    NSString *text = [NSString stringWithFormat:@"%@%@%@", title, seasonAndEpisode.length ? @" " : @"", seasonAndEpisode];
    return text;
}

+ (NSString*)formatTVShowStringForSeason:(id)season episode:(id)episode {
    NSString *text = @"";
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *format = [userDefaults stringForKey:@"episode_identifier"];
    if ([season respondsToSelector:@selector(intValue)] && [episode respondsToSelector:@selector(intValue)]) {
        if ([season intValue] && [episode intValue]) {
            text = [NSString stringWithFormat:format, [season intValue], [episode intValue]];
        }
    }
    return text;
}

+ (NSString*)formatClipboardMessage:(NSString*)method parameters:(NSDictionary*)parameters error:(NSError*)error methodError:(DSJSONRPCError*)methodError {
    // Convert dictionary to string and remove spaces and newlines
    NSString *parameterString = [NSString stringWithFormat:@"%@", parameters];
    parameterString = [parameterString stringByReplacingOccurrencesOfString:@" " withString:@""];
    parameterString = [parameterString stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    
    // Build and return message
    NSString *message = [NSString stringWithFormat:@"METHOD\n%@\n\nPARAMETERS\n%@\n", method, parameterString];
    if (methodError != nil) {
        message = [NSString stringWithFormat:@"%@\n\n%@\n", methodError, message];
    }
    if (error != nil) {
        message = [NSString stringWithFormat:@"%@\n\n%@\n", error.localizedDescription, message];
    }
    return message;
}

+ (NSString*)stripRegEx:(NSString*)regExp text:(NSString*)textIn {
    // Returns unchanged string, if regExp is nil. Returns nil, if string is nil.
    if (!textIn || !regExp) {
        return textIn;
    }
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regExp options:NSRegularExpressionCaseInsensitive error:NULL];
    NSString *textOut = [regex stringByReplacingMatchesInString:textIn options:0 range:NSMakeRange(0, [textIn length]) withTemplate:@""];
    return textOut;
}

+ (NSString*)stripBBandHTML:(NSString*)text {
    NSString *textOut = text;
    
    // Strip html, <x>, whereas x is not ""
    textOut = [Utilities stripRegEx:@"<[^>]+>" text:textOut];
    
    // Strip BB code, [x] [/x], whereas x = b,u,i,s,center,left,right,url,img and spaces
    textOut = [Utilities stripRegEx:@"\\[/?(b|u|i|s|center|left|right|url|img)\\]" text:textOut];
    
    // Strip BB code, [x=anything] [/x], whereas x = font,size,color,url and spaces
    textOut = [Utilities stripRegEx:@"\\[/?(font|size|color|url)(=[^]]+)?\\]" text:textOut];
    
    return textOut;
}

+ (BOOL)isValidMacAddress:(NSString*)macAddress {
    return macAddress && macAddress.length && ![macAddress isEqualToString:@":::::"];
}

+ (void)wakeUp:(NSString*)macAddress {
    [AppDelegate.instance sendWOL:macAddress withPort:WOL_PORT];
}

+ (BOOL)isValidIP6Address:(NSString*)ip {
    const char *utf8 = [ip UTF8String];
    
    if (utf8 == NULL) {
        return NO;
    }

    // Check valid IPv6.
    struct in6_addr dst6;
    int success = inet_pton(AF_INET6, utf8, &dst6);
    
    return (success == 1);
}

+ (NSString*)getUrlStyleAddress:(NSString*)address {
    NSString *URLaddress = address;
    if ([Utilities isValidIP6Address:address]) {
        URLaddress = [NSString stringWithFormat:@"[%@]", address];
    }
    return URLaddress;
}

+ (NSString*)getServerPort:(NSString*)serverPort {
    return serverPort.length ? serverPort : [NSString stringWithFormat:@"%d", DEFAULT_SERVER_PORT];
}

+ (int)getTcpPort:(NSNumber*)tcpPort {
    return [tcpPort intValue] ?: DEFAULT_TCP_PORT;
}

+ (int)getActivePlayerID:(NSArray*)activePlayerList {
    if (!activePlayerList.count) {
        return PLAYERID_UNKNOWN;
    }
    if (![activePlayerList[0] isKindOfClass:[NSDictionary class]]) {
        return PLAYERID_UNKNOWN;
    }
    // Active player is the first listed one
    int activePlayerID = [activePlayerList[0][@"playerid"] intValue];
    return activePlayerID;
}

+ (UIViewController*)topMostController {
    return [self topMostControllerIgnoringClass:nil];
}

+ (UIViewController*)topMostControllerIgnoringClass:(Class)ignoredClass {
    UIViewController *topController = UIApplication.sharedApplication.keyWindow.rootViewController;
    while (topController.presentedViewController) {
        if ([topController.presentedViewController isKindOfClass:ignoredClass]) {
            // We want to ignore any ignoredClass being the top most controller.
            break;
        }
        topController = topController.presentedViewController;
    }
    return topController;
}

+ (uint64_t)memoryFootprint {
    task_vm_info_data_t vmInfo;
    mach_msg_type_number_t count = TASK_VM_INFO_COUNT;
    kern_return_t result = task_info(mach_task_self(), TASK_VM_INFO, (task_info_t) &vmInfo, &count);
    if (result != KERN_SUCCESS) {
        return 0;
    }
    return vmInfo.phys_footprint;
}

+ (NSIndexPath*)readLastServerIndex {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if ([userDefaults objectForKey:@"lastServer"] != nil) {
        NSInteger lastServer = [userDefaults integerForKey:@"lastServer"];
        if (lastServer > -1 && lastServer < AppDelegate.instance.arrayServerList.count) {
            return [NSIndexPath indexPathForRow:lastServer inSection:0];
        }
    }
    return nil;
}

+ (void)saveLastServerIndex:(NSIndexPath*)indexPath {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSNumber *lastServerIndex = indexPath ? @(indexPath.row) : @(-1);
    [userDefaults setObject:lastServerIndex forKey:@"lastServer"];
}

+ (void)readKodiServerParameters {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if ([userDefaults objectForKey:@"lastServer"] != nil) {
        NSInteger lastServer = [userDefaults integerForKey:@"lastServer"];
        if (lastServer > -1 && lastServer < AppDelegate.instance.arrayServerList.count) {
            NSIndexPath *lastServerIndexPath = [NSIndexPath indexPathForRow:lastServer inSection:0];
            NSDictionary *item = AppDelegate.instance.arrayServerList[lastServerIndexPath.row];
            AppDelegate.instance.obj.serverDescription = item[@"serverDescription"];
            AppDelegate.instance.obj.serverUser = item[@"serverUser"];
            AppDelegate.instance.obj.serverPass = item[@"serverPass"];
            AppDelegate.instance.obj.serverRawIP = item[@"serverIP"];
            AppDelegate.instance.obj.serverIP = [Utilities getUrlStyleAddress:item[@"serverIP"]];
            AppDelegate.instance.obj.serverPort = [Utilities getServerPort:item[@"serverPort"]];
            AppDelegate.instance.obj.serverHWAddr = item[@"serverMacAddress"];
            AppDelegate.instance.obj.tcpPort = [Utilities getTcpPort:item[@"tcpPort"]];
        }
    }
}

+ (void)resetKodiServerParameters {
    AppDelegate.instance.obj.serverDescription = @"";
    AppDelegate.instance.obj.serverUser = @"";
    AppDelegate.instance.obj.serverPass = @"";
    AppDelegate.instance.obj.serverRawIP = @"";
    AppDelegate.instance.obj.serverIP = @"";
    AppDelegate.instance.obj.serverPort = @"";
    AppDelegate.instance.obj.serverHWAddr = @"";
    AppDelegate.instance.obj.tcpPort = 0;
}

+ (void)stopPollingActiveServer {
    // Temporarily disconnect the server by resetting the server parameters. This will keep the server
    // selected in the server list, but will stop polling and supports reconnecting after wakeup or restart.
    [Utilities resetKodiServerParameters];
    
    // Send XBMCServerHasChanged notification to let main menu deactivate the menu items
    [[NSNotificationCenter defaultCenter] postNotificationName:@"XBMCServerHasChanged" object:nil];
}

@end

#pragma mark - UILabel extensions

@implementation UILabel (Extensions)

- (CGSize)getSize {
    return [self sizeThatFits:CGSizeMake(self.frame.size.width, CGFLOAT_MAX)];
}

@end

#pragma mark - UIView extensions

@implementation UIView (Extensions)

- (void)setX:(CGFloat)x {
    CGRect frame = self.frame;
    frame.origin.x = x;
    self.frame = frame;
}

- (void)setY:(CGFloat)y {
    CGRect frame = self.frame;
    frame.origin.y = y;
    self.frame = frame;
}

- (void)setOrigin:(CGPoint)origin {
    CGRect frame = self.frame;
    frame.origin = origin;
    self.frame = frame;
}

- (void)setHeight:(CGFloat)height {
    CGRect frame = self.frame;
    frame.size.height = height;
    self.frame = frame;
}

- (void)setWidth:(CGFloat)width {
    CGRect frame = self.frame;
    frame.size.width = width;
    self.frame = frame;
}

- (void)offsetY:(CGFloat)offset {
    CGRect frame = self.frame;
    frame.origin.y += offset;
    self.frame = frame;
}

- (void)setX:(CGFloat)x alpha:(CGFloat)alpha {
    CGRect frame = self.frame;
    frame.origin.x = x;
    self.frame = frame;
    self.alpha = alpha;
}

- (void)animateX:(CGFloat)x alpha:(CGFloat)alpha duration:(NSTimeInterval)seconds {
    [UIView animateWithDuration:seconds
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
        [self setX:x alpha:alpha];
    }
                     completion:nil];
}

- (void)animateOrigin:(CGPoint)origin duration:(NSTimeInterval)seconds {
    [UIView animateWithDuration:seconds
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
        [self setOrigin:origin];
    }
                     completion:nil];
}

- (void)animateAlpha:(CGFloat)alpha duration:(NSTimeInterval)seconds {
    [UIView animateWithDuration:seconds
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
        self.alpha = alpha;
    }
                     completion:nil];
}

@end

#pragma mark - UIImageView extensions

@implementation UIImageView (Extensions)

- (void)animateImage:(UIImage*)image duration:(NSTimeInterval)seconds {
    [UIView transitionWithView:self
                      duration:seconds
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{
        self.image = image;
    }
                    completion:nil];
}

@end

#pragma mark - UIColor extensions

@implementation UIColor (Extensions)

+ (UIColor*)getSystemRed:(CGFloat)alpha {
    return [UIColor.systemRedColor colorWithAlphaComponent:alpha];
}

+ (UIColor*)getSystemGreen:(CGFloat)alpha {
    return [UIColor.systemGreenColor colorWithAlphaComponent:alpha];
}

+ (UIColor*)getKodiBlue {
    return RGBA(20, 178, 231, 1.0);
}

+ (UIColor*)getSystemBlue {
    return UIColor.systemBlueColor;
}

+ (UIColor*)getSystemGray1 {
    return UIColor.systemGrayColor;
}

+ (UIColor*)getSystemGray2 {
    if (@available(iOS 13.0, *)) {
        return UIColor.systemGray2Color;
    }
    else {
        return RGBA(174, 174, 178, 1.0);
    }
}

+ (UIColor*)getSystemGray3 {
    if (@available(iOS 13.0, *)) {
        return UIColor.systemGray3Color;
    }
    else {
        return RGBA(199, 199, 204, 1.0);
    }
}

+ (UIColor*)getSystemGray4 {
    if (@available(iOS 13.0, *)) {
        return UIColor.systemGray4Color;
    }
    else {
        return RGBA(209, 209, 214, 1.0);
    }
}

+ (UIColor*)getSystemGray5 {
    if (@available(iOS 13.0, *)) {
        return UIColor.systemGray5Color;
    }
    else {
        return RGBA(229, 229, 234, 1.0);
    }
}

+ (UIColor*)getSystemGray6 {
    if (@available(iOS 13.0, *)) {
        return UIColor.systemGray6Color;
    }
    else {
        return RGBA(242, 242, 247, 1.0);
    }
}

+ (UIColor*)get1stLabelColor {
    if (@available(iOS 13.0, *)) {
        return UIColor.labelColor;
    }
    else {
        return RGBA(0, 0, 0, 1.0);
    }
}

+ (UIColor*)get2ndLabelColor {
    if (@available(iOS 13.0, *)) {
        return UIColor.secondaryLabelColor;
    }
    else {
        return RGBA(60, 60, 67, 0.6);
    }
}

+ (UIColor*)get3rdLabelColor {
    if (@available(iOS 13.0, *)) {
        return UIColor.tertiaryLabelColor;
    }
    else {
        return RGBA(60, 60, 67, 0.3);
    }
}

+ (UIColor*)get4thLabelColor {
    if (@available(iOS 13.0, *)) {
        return UIColor.quaternaryLabelColor;
    }
    else {
        return RGBA(60, 60, 67, 0.18);
    }
}

+ (UIColor*)getGrayColor:(int)tone alpha:(CGFloat)alpha {
    return RGBA(tone, tone, tone, alpha);
}

@end

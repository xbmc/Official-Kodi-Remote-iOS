//
//  Utilities.m
//  XBMC Remote
//
//  Created by Giovanni Messina on 4/3/13.
//  Copyright (c) 2013 joethefox inc. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <StoreKit/StoreKit.h>
#import <arpa/inet.h>
#import "Utilities.h"
#import "AppDelegate.h"
#import "NSString+MD5.h"
#import "SDWebImageManager.h"

#define GET_ROUNDED_EDGES_RADIUS(size) MAX(MIN(size.width, size.height) * 0.03, 6.0)
#define GET_ROUNDED_EDGES_PATH(rect, radius) [UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:radius];
#define RGBA(r, g, b, a) [UIColor colorWithRed:(r) / 255.0 green:(g) / 255.0 blue:(b) / 255.0 alpha:(a)]
#define XBMC_LOGO_PADDING 10
#define PERSISTENCE_KEY_VERSION @"VersionUnderReview"
#define PERSISTENCE_KEY_PLAYBACK_ATTEMPTS @"PlaybackAttempts"

@implementation Utilities

+ (CGContextRef)createBitmapContextFromImage:(CGImageRef)inImage format:(uint32_t)format {
    size_t width = CGImageGetWidth(inImage);
    size_t height = CGImageGetHeight(inImage);
    unsigned long bytesPerRow = width * 4; // 4 bytes for alpha, red, green and blue
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    if (colorSpace == NULL) {
        return NULL;
    }

    CGContextRef context = CGBitmapContextCreate(NULL, width, height, 8 /* 8 bits */, bytesPerRow, colorSpace, (CGBitmapInfo)format);
    
    // Make sure and release colorspace before returning
    CGColorSpaceRelease(colorSpace);
    return context;
}

+ (CGImageRef)create32bppImage:(CGImageRef)imageRef format:(uint32_t)format {
    CGContextRef ctx = [Utilities createBitmapContextFromImage:imageRef format:format];
    if (ctx == NULL) {
        return NULL;
    }
    CGRect rect = CGRectMake(0, 0, CGImageGetWidth(imageRef), CGImageGetHeight(imageRef));
    CGContextDrawImage(ctx, rect, imageRef);
    imageRef = CGBitmapContextCreateImage(ctx);
    CGContextRelease(ctx);
    return imageRef;
}

+ (UIColor*)averageColor:(UIImage*)image inverse:(BOOL)inverse autoColorCheck:(BOOL)autoColorCheck {
    CGImageRef rawImageRef = [image CGImage];
    if (rawImageRef == nil) {
        return UIColor.clearColor;
    }
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    BOOL autocolor_preference = [userDefaults boolForKey:@"autocolor_ui_preference"];
    if (autoColorCheck && !autocolor_preference) {
        return [Utilities getSystemGray2];
    }
    
    CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(rawImageRef);
    int infoMask = (bitmapInfo & kCGBitmapAlphaInfoMask);
    BOOL anyNonAlpha = (infoMask == kCGImageAlphaNone ||
                        infoMask == kCGImageAlphaNoneSkipFirst ||
                        infoMask == kCGImageAlphaNoneSkipLast);
//    if (!anyNonAlpha) {
//        return UIColor.clearColor;
//    }
    
    // Enforce images are converted to default (ARGB or RGB, 32bpp, ByteOrderDefault) before analyzing them
    if (anyNonAlpha && (bitmapInfo != kCGImageAlphaNoneSkipLast || CGImageGetBitsPerPixel(rawImageRef) != 32)) {
        rawImageRef = [Utilities create32bppImage:rawImageRef format:kCGImageAlphaNoneSkipLast];
    }
    else if (!anyNonAlpha && (bitmapInfo != kCGImageAlphaPremultipliedFirst || CGImageGetBitsPerPixel(rawImageRef) != 32)) {
        rawImageRef = [Utilities create32bppImage:rawImageRef format:kCGImageAlphaPremultipliedFirst];
    }
    if (rawImageRef == NULL) {
        return UIColor.clearColor;
    }
    
	CFDataRef data = CGDataProviderCopyData(CGImageGetDataProvider(rawImageRef));
    const UInt8 *rawPixelData = CFDataGetBytePtr(data);
    
    NSUInteger imageHeight = CGImageGetHeight(rawImageRef);
    NSUInteger imageWidth  = CGImageGetWidth(rawImageRef);
    NSUInteger bytesPerRow = CGImageGetBytesPerRow(rawImageRef);
	NSUInteger stride = CGImageGetBitsPerPixel(rawImageRef) / 8;
    
    // DEBUG
    /*
    bitmapInfo = CGImageGetBitmapInfo(rawImageRef);
    infoMask = (bitmapInfo & kCGBitmapAlphaInfoMask);
    BOOL isARGB = infoMask == kCGImageAlphaPremultipliedFirst;
    BOOL isRGBA = infoMask == kCGImageAlphaPremultipliedLast;
    BOOL isRGBa = infoMask == kCGImageAlphaLast;
    BOOL isaRGB = infoMask == kCGImageAlphaFirst;
    BOOL isxRGB = infoMask == kCGImageAlphaNoneSkipFirst;
    BOOL isRGBx = infoMask == kCGImageAlphaNoneSkipLast;
    BOOL isRGB = infoMask == kCGImageAlphaNone;
    */
    
    UInt64 red   = 0;
    UInt64 green = 0;
    UInt64 blue  = 0;
    UInt64 alpha = 0;
    CGFloat f = 1.0;
    
    if (anyNonAlpha) {
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
    else {
        // weight color with alpha to ignore transparent sections
        // ARGB (kCGImageAlphaPremultipliedFirst)
        for (int row = 0; row < imageHeight; row++) {
            const UInt8 *rowPtr = rawPixelData + bytesPerRow * row;
            for (int column = 0; column < imageWidth; column++) {
                alpha  += rowPtr[0];
                red    += rowPtr[1] * rowPtr[0];
                green  += rowPtr[2] * rowPtr[0];
                blue   += rowPtr[3] * rowPtr[0];
                rowPtr += stride;
            }
        }
        f = 1.0 / (255.0 * alpha);
    }
    if (inverse) {
        UInt64 tmp = red;
        red = blue;
        blue = tmp;
    }
	CFRelease(data);
    
	return [UIColor colorWithRed:f * red green:f * green blue:f * blue alpha:1];
}

+ (UIColor*)limitSaturation:(UIColor*)color_in satmax:(CGFloat)satmax {
    CGFloat hue, sat, bright, alpha;
    UIColor *color_out = nil;
    if ([color_in getHue:&hue saturation:&sat brightness:&bright alpha:&alpha]) {
        // limit saturation
        sat = MIN(MAX(sat, 0), satmax);
        color_out = [UIColor colorWithHue:hue saturation:sat brightness:bright alpha:alpha];
    }
    return color_out;
}

+ (UIColor*)tailorColor:(UIColor*)color_in satscale:(CGFloat)satscale brightscale:(CGFloat)brightscale brightmin:(CGFloat)brightmin brightmax:(CGFloat)brightmax {
    CGFloat hue, sat, bright, alpha;
    UIColor *color_out = nil;
    if ([color_in getHue:&hue saturation:&sat brightness:&bright alpha:&alpha]) {
        // de-saturate, but do not remove saturation fully
        sat = MIN(MAX(sat * satscale, 0), 1);
        // scale and limit brightness to range [brightmin ... brightmax]
        bright = MIN(MAX(bright * brightscale, brightmin), brightmax);
        color_out = [UIColor colorWithHue:hue saturation:sat brightness:bright alpha:alpha];
    }
    return color_out;
}

+ (UIColor*)slightLighterColorForColor:(UIColor*)color_in {
    return [Utilities tailorColor:color_in satscale:0.33 brightscale:1.2 brightmin:0.5 brightmax:0.6];
}

+ (UIColor*)lighterColorForColor:(UIColor*)color_in {
    return [Utilities tailorColor:color_in satscale:0.33 brightscale:1.5 brightmin:0.7 brightmax:0.9];
}

+ (UIColor*)darkerColorForColor:(UIColor*)color_in {
    return [Utilities tailorColor:color_in satscale:0.33 brightscale:0.7 brightmin:0.2 brightmax:0.4];
}

+ (UIColor*)updateColor:(UIColor*)newColor lightColor:(UIColor*)lighter darkColor:(UIColor*)darker {
    CGFloat trigger = 0.4;
    return [Utilities updateColor:newColor lightColor:lighter darkColor:darker trigger:trigger];
}

+ (UIColor*)updateColor:(UIColor*)newColor lightColor:(UIColor*)lighter darkColor:(UIColor*)darker trigger:(CGFloat)trigger {
    if ([newColor isEqual:UIColor.clearColor] || newColor == nil) {
        return lighter;
    }
    const CGFloat *componentColors = CGColorGetComponents(newColor.CGColor);
    CGFloat colorBrightness = (componentColors[0] * 299 + componentColors[1] * 587 + componentColors[2] * 114) / 1000;
    if (colorBrightness < trigger) {
        return lighter;
    }
    else {
        return darker;
    }
}

+ (UIImage*)colorizeImage:(UIImage*)image withColor:(UIColor*)color {
    if (color == nil) {
        return image;
    }
    UIGraphicsBeginImageContextWithOptions(image.size, YES, 0);
    
    CGRect contextRect = (CGRect) {.origin = CGPointZero, .size = image.size};
    
    CGSize itemImageSize = image.size;
    CGPoint itemImagePosition;
    itemImagePosition.x = ceilf((contextRect.size.width - itemImageSize.width) / 2);
    itemImagePosition.y = ceilf(contextRect.size.height - itemImageSize.height);
    
    UIGraphicsBeginImageContextWithOptions(contextRect.size, NO, 0);
    
    CGContextRef c = UIGraphicsGetCurrentContext();
    
    CGContextBeginTransparencyLayer(c, NULL);
    CGContextScaleCTM(c, 1.0, -1.0);
    CGContextClipToMask(c, CGRectMake(itemImagePosition.x, -itemImagePosition.y, itemImageSize.width, -itemImageSize.height), [image CGImage]);

    CGColorSpaceRef colorSpace = CGColorGetColorSpace(color.CGColor);
    CGColorSpaceModel model = CGColorSpaceGetModel(colorSpace);
    const CGFloat *colors = CGColorGetComponents(color.CGColor);
    
    if (model == kCGColorSpaceModelMonochrome) {
        CGContextSetRGBFillColor(c, colors[0], colors[0], colors[0], colors[1]);
    }
    else {
        CGContextSetRGBFillColor(c, colors[0], colors[1], colors[2], colors[3]);
    }
    
    contextRect.size.height = -contextRect.size.height;
    contextRect.size.height -= 15;
    CGContextFillRect(c, contextRect);
    CGContextEndTransparencyLayer(c);
    
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return img;
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
    UIColor *bglight = [Utilities getGrayColor:242 alpha:1.0];
    UIColor *bgdark = [Utilities getGrayColor:28 alpha:1.0];
    switch (mode) {
        case bgAuto:
            // get background color and colorize the image background
            imgcolor = [Utilities averageColor:imageview.image inverse:NO autoColorCheck:NO];
            bgcolor = [Utilities updateColor:imgcolor lightColor:bglight darkColor:bgdark trigger:0.4];
            break;
        case bgLight:
            bgcolor = bglight;
            break;
        case bgDark:
            bgcolor = bgdark;
            break;
        case bgTrans:
            // bgcolor already defined to clearColor as default
            break;
        default:
            NSLog(@"setLogoBackgroundColor: unknown mode %d", mode);
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
    LogoBackgroundType setting = bgAuto;
    NSString *mode = [userDefaults stringForKey:@"logo_background"];
    if (mode.length) {
        if ([mode isEqualToString:@"dark"]) {
            setting = bgDark;
        }
        else if ([mode isEqualToString:@"light"]) {
            setting = bgLight;
        }
        else if ([mode isEqualToString:@"trans"]) {
            setting = bgTrans;
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

+ (UIColor*)getSystemRed:(CGFloat)alpha {
    return [UIColor.systemRedColor colorWithAlphaComponent:alpha];
}

+ (UIColor*)getSystemGreen:(CGFloat)alpha {
    return [UIColor.systemGreenColor colorWithAlphaComponent:alpha];
}

+ (UIColor*)getKodiBlue {
    return RGBA(50, 174, 225, 1.0);
}

+ (UIColor*)getSystemBlue {
    return UIColor.systemBlueColor;
}

+ (UIColor*)getSystemTeal {
    return UIColor.systemTealColor;
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

+ (CGRect)createXBMCInfoframe:(UIImage*)logo height:(CGFloat)height width:(CGFloat)width {
    if (IS_IPHONE) {
        return CGRectMake(width - ANCHOR_RIGHT_PEEK - logo.size.width - XBMC_LOGO_PADDING, (height - logo.size.height) / 2, logo.size.width, logo.size.height);
    }
    else {
        return CGRectMake(width - logo.size.width / 2 - XBMC_LOGO_PADDING, (height - logo.size.height / 2) / 2, logo.size.width / 2, logo.size.height / 2);
    }
}

+ (CGRect)createCoverInsideJewel:(UIImageView*)jewelView jewelType:(eJewelType)type {
    CGFloat border_right, border_bottom, border_top, border_left;
    // Setup the border width on all 4 sides for each jewel case type
    switch (type) {
        case jewelTypeCD:
            border_right  = 14;
            border_bottom = 15;
            border_top    = 11;
            border_left   = 32;
            break;
        case jewelTypeDVD:
            border_right  = 10;
            border_bottom = 14;
            border_top    = 11;
            border_left   = 35;
            break;
        case jewelTypeTV:
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
    UIAlertController *alertView = [UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okButton = [UIAlertAction actionWithTitle:LOCALIZED_STR(@"OK") style:UIAlertActionStyleDefault handler:nil];
    [alertView addAction:okButton];
    return alertView;
}

+ (UIAlertController*)createAlertCopyClipboard:(NSString*)title message:(NSString*)msg {
    UIAlertController *alertView = [UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *copyButton = [UIAlertAction actionWithTitle:LOCALIZED_STR(@"Copy to clipboard") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
            pasteboard.string = msg;
    }];
    UIAlertAction *cancelButton = [UIAlertAction actionWithTitle:LOCALIZED_STR(@"Cancel") style:UIAlertActionStyleCancel handler:nil];
    [alertView addAction:copyButton];
    [alertView addAction:cancelButton];
    return alertView;
}

+ (void)powerAction:(NSString*)command ctrl:(UIViewController*)ctrl message:(NSString*)alertMessage ok:(NSString*)okMessage messageView:(MessagesView*)messageView {
    alertMessage = alertMessage ?: @"";
    okMessage = okMessage ?: LOCALIZED_STR(@"Yes");
    UIAlertController *alertView = [UIAlertController alertControllerWithTitle:alertMessage message:nil preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancelButton = [UIAlertAction actionWithTitle:LOCALIZED_STR(@"Cancel") style:UIAlertActionStyleCancel handler:nil];
    UIAlertAction *okButton = [UIAlertAction actionWithTitle:okMessage style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        if (!command) {
            return;
        }
        [[Utilities getJsonRPC] callMethod:command withParameters:@{} onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *error) {
            if (messageView) {
                if (methodError == nil && error == nil) {
                    [messageView showMessage:LOCALIZED_STR(@"Command executed") timeout:2.0 color:[Utilities getSystemGreen:0.95]];
                }
                else {
                    [messageView showMessage:LOCALIZED_STR(@"Cannot do that") timeout:2.0 color:[Utilities getSystemRed:0.95]];
                }
            }
            else {
                NSString *alertTitle = nil;
                if (methodError == nil && error == nil) {
                    alertTitle = LOCALIZED_STR(@"Command executed");
                }
                else {
                    alertTitle = LOCALIZED_STR(@"Cannot do that");
                }
                UIAlertController *alertViewResult = [Utilities createAlertOK:alertTitle message:nil];
                [ctrl presentViewController:alertViewResult animated:YES completion:nil];
            }
        }];
    }];
    [alertView addAction:cancelButton];
    [alertView addAction:okButton];
    [ctrl presentViewController:alertView animated:YES completion:nil];
}

+ (UIAlertController*)createPowerControl:(UIViewController*)ctrl messageView:(MessagesView*)messageView {
    NSString *title = [NSString stringWithFormat:@"%@\n%@", AppDelegate.instance.obj.serverDescription, AppDelegate.instance.obj.serverIP];
    UIAlertController *actionView = [UIAlertController alertControllerWithTitle:title message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    if (!AppDelegate.instance.serverOnLine) {
        UIAlertAction *action_wake = [UIAlertAction actionWithTitle:LOCALIZED_STR(@"Send Wake-On-LAN") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            if (messageView) {
                if ([Utilities isValidMacAddress:AppDelegate.instance.obj.serverHWAddr]) {
                    [Utilities wakeUp:AppDelegate.instance.obj.serverHWAddr];
                    [messageView showMessage:LOCALIZED_STR(@"Command executed") timeout:2.0 color:[Utilities getSystemGreen:0.95]];
                }
                else {
                    [messageView showMessage:LOCALIZED_STR(@"Cannot do that") timeout:2.0 color:[Utilities getSystemRed:0.95]];
                }
            }
            else {
                if ([Utilities isValidMacAddress:AppDelegate.instance.obj.serverHWAddr]) {
                    [Utilities wakeUp:AppDelegate.instance.obj.serverHWAddr];
                    UIAlertController *alertView = [Utilities createAlertOK:LOCALIZED_STR(@"Command executed") message:nil];
                    [ctrl presentViewController:alertView animated:YES completion:nil];
                }
                else {
                    UIAlertController *alertView = [Utilities createAlertOK:LOCALIZED_STR(@"Warning") message:LOCALIZED_STR(@"No server MAC address defined")];
                    [ctrl presentViewController:alertView animated:YES completion:nil];
                }
            }
        }];
        [actionView addAction:action_wake];
    }
    else {
        UIAlertAction *action_pwr_off_system = [UIAlertAction actionWithTitle:LOCALIZED_STR(@"Power off System") style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
            [self powerAction:@"System.Shutdown" 
                         ctrl:ctrl
                      message:LOCALIZED_STR(@"Are you sure you want to power off your XBMC system now?")
                           ok:LOCALIZED_STR(@"Power off")
                  messageView:messageView];
        }];
        [actionView addAction:action_pwr_off_system];
        
        UIAlertAction *action_quit_kodi = [UIAlertAction actionWithTitle:LOCALIZED_STR(@"Quit XBMC application") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [self powerAction:@"Application.Quit" 
                         ctrl:ctrl
                      message:LOCALIZED_STR(@"Are you sure you want to quit XBMC application now?")
                           ok:LOCALIZED_STR(@"Quit")
                  messageView:messageView];
        }];
        [actionView addAction:action_quit_kodi];
        
        UIAlertAction *action_hibernate = [UIAlertAction actionWithTitle:LOCALIZED_STR(@"Hibernate") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [self powerAction:@"System.Hibernate" 
                         ctrl:ctrl
                      message:LOCALIZED_STR(@"Are you sure you want to hibernate your XBMC system now?")
                           ok:LOCALIZED_STR(@"Hibernate")
                  messageView:messageView];
        }];
        [actionView addAction:action_hibernate];
        
        UIAlertAction *action_suspend = [UIAlertAction actionWithTitle:LOCALIZED_STR(@"Suspend") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [self powerAction:@"System.Suspend"
                         ctrl:ctrl
                      message:LOCALIZED_STR(@"Are you sure you want to suspend your XBMC system now?")
                           ok:LOCALIZED_STR(@"Suspend")
                  messageView:messageView];
        }];
        [actionView addAction:action_suspend];
        
        UIAlertAction *action_reboot = [UIAlertAction actionWithTitle:LOCALIZED_STR(@"Reboot") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [self powerAction:@"System.Reboot" 
                         ctrl:ctrl
                      message:LOCALIZED_STR(@"Are you sure you want to reboot your XBMC system now?")
                           ok:LOCALIZED_STR(@"Reboot")
                  messageView:messageView];
        }];
        [actionView addAction:action_reboot];
        
        UIAlertAction *action_scan_audio_lib = [UIAlertAction actionWithTitle:LOCALIZED_STR(@"Update Audio Library") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [self powerAction:@"AudioLibrary.Scan" 
                         ctrl:ctrl
                      message:LOCALIZED_STR(@"Are you sure you want to update your audio library now?")
                           ok:LOCALIZED_STR(@"Update Audio")
                  messageView:messageView];
        }];
        [actionView addAction:action_scan_audio_lib];
        
        UIAlertAction *action_clean_audio_lib = [UIAlertAction actionWithTitle:LOCALIZED_STR(@"Clean Audio Library") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [self powerAction:@"AudioLibrary.Clean"
                         ctrl:ctrl
                      message:LOCALIZED_STR(@"Are you sure you want to clean your audio library now?")
                           ok:LOCALIZED_STR(@"Clean Audio")
                  messageView:messageView];
        }];
        [actionView addAction:action_clean_audio_lib];
        
        UIAlertAction *action_scan_video_lib = [UIAlertAction actionWithTitle:LOCALIZED_STR(@"Update Video Library") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [self powerAction:@"VideoLibrary.Scan" 
                         ctrl:ctrl
                      message:LOCALIZED_STR(@"Are you sure you want to update your video library now?")
                           ok:LOCALIZED_STR(@"Update Video")
                  messageView:messageView];
        }];
        [actionView addAction:action_scan_video_lib];
        
        UIAlertAction *action_clean_video_lib = [UIAlertAction actionWithTitle:LOCALIZED_STR(@"Clean Video Library") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [self powerAction:@"VideoLibrary.Clean" 
                         ctrl:ctrl 
                      message:LOCALIZED_STR(@"Are you sure you want to clean your video library now?")
                           ok:LOCALIZED_STR(@"Clean Video")
                  messageView:messageView];
        }];
        [actionView addAction:action_clean_video_lib];
    }
    
    UIAlertAction *cancelButton = [UIAlertAction actionWithTitle:LOCALIZED_STR(@"Cancel") style:UIAlertActionStyleCancel handler:nil];
    [actionView addAction:cancelButton];
    actionView.modalPresentationStyle = UIModalPresentationPopover;
    
    return actionView;
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
            UIAlertController *alertView = [Utilities createAlertOK:LOCALIZED_STR(@"Error loading page") message:exception.reason];
            [fromctrl presentViewController:alertView animated:YES completion:nil];
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

+ (NSDictionary*)indexKeyedDictionaryFromArray:(NSArray*)array {
    NSMutableDictionary *mutableDictionary = [NSMutableDictionary new];
    NSInteger numelement = array.count;
    for (int i = 0; i < numelement - 1; i += 2) {
        mutableDictionary[array[i + 1]] = array[i];
    }
    return (NSDictionary*)mutableDictionary;
}

+ (NSMutableDictionary*)indexKeyedMutableDictionaryFromArray:(NSArray*)array {
    NSMutableDictionary *mutableDictionary = [NSMutableDictionary new];
    NSInteger numelement = array.count;
    for (int i = 0; i < numelement - 1; i += 2) {
        mutableDictionary[array[i + 1]] = array[i];
    }
    return (NSMutableDictionary*)mutableDictionary;
}

+ (NSString*)convertTimeFromSeconds:(NSNumber*)seconds {
    NSString *result = @"";
    if (seconds == nil) {
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
    // Begin special treatment
    // Adding custom button mis-uses the key "year" to transport the type of button which
    // is added. Allowed are "list", "integer" and "boolean".
    else if ([item isKindOfClass:[NSString class]] &&
             ([item isEqualToString:@"boolean"] || [item isEqualToString:@"integer"] || [item isEqualToString:@"list"])) {
        year = item;
    }
    // End special treatment
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

+ (CGSize)getSizeOfLabel:(UILabel*)label {
    return [label sizeThatFits:CGSizeMake(label.frame.size.width, CGFLOAT_MAX)];
}

+ (UIImage*)roundedCornerImage:(UIImage*)image drawBorder:(BOOL)drawBorder {
    CGRect imageRect = CGRectMake(0, 0, image.size.width, image.size.height);
    UIGraphicsBeginImageContextWithOptions(image.size, NO, 0);

    // Set radius for corners
    CGFloat radius = GET_ROUNDED_EDGES_RADIUS(image.size);
    
    // Define our path, capitalizing on UIKit's corner rounding magic
    UIBezierPath *path = GET_ROUNDED_EDGES_PATH(imageRect, radius);
    [path addClip];

    // Draw the image into the implicit context
    [image drawInRect:imageRect];
    
    if (drawBorder) {
        // Draw border with shape of path
        path.lineWidth = 1.0 / UIScreen.mainScreen.scale;
        [UIColor.blackColor setStroke];
        [path stroke];
    }
     
    // Get image and cleanup
    UIImage *roundedCornerImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return roundedCornerImage;
}

+ (void)roundedCornerView:(UIView*)view drawBorder:(BOOL)drawBorder {
    CALayer *imageLayer = view.layer;
    
    // Set radius for corners
    CGFloat radius = GET_ROUNDED_EDGES_RADIUS(imageLayer.frame.size);
    // Create a mask layer
    CAShapeLayer *maskLayer = [CAShapeLayer new];
    CGFloat freeAreaWidth = 1.0 / UIScreen.mainScreen.scale;
    CGRect maskFrame = CGRectInset(imageLayer.bounds, freeAreaWidth, freeAreaWidth);
    maskFrame.origin.x /= 2;
    maskFrame.origin.y /= 2;
    maskLayer.frame = maskFrame;
    // Define our path, capitalizing on UIKit's corner rounding magic
    UIBezierPath *newPath = GET_ROUNDED_EDGES_PATH(maskLayer.frame, radius);
    maskLayer.path = newPath.CGPath;
    // Apply the mask
    imageLayer.mask = maskLayer;
    
    // Apply border
    if (drawBorder) {
        imageLayer.borderWidth = 1.0 / UIScreen.mainScreen.scale;
        imageLayer.borderColor = UIColor.blackColor.CGColor;
    }
    else {
        imageLayer.borderWidth = 0;
    }
}

+ (UIImage*)applyRoundedEdgesImage:(UIImage*)image drawBorder:(BOOL)drawBorder {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    BOOL corner_preference = [userDefaults boolForKey:@"rounded_corner_preference"];
    if (corner_preference) {
        image = [Utilities roundedCornerImage:image drawBorder:drawBorder];
    }
    return image;
}

+ (void)applyRoundedEdgesView:(UIView*)view drawBorder:(BOOL)drawBorder {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    BOOL corner_preference = [userDefaults boolForKey:@"rounded_corner_preference"];
    if (corner_preference) {
        [Utilities roundedCornerView:view drawBorder:drawBorder];
    }
}

+ (void)turnTorchOn:(id)sender on:(BOOL)torchOn {
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if (!(device.hasTorch && device.hasFlash)) {
        return;
    }
    
    AVCapturePhotoSettings *settings = [AVCapturePhotoSettings photoSettings];
    UIImage *img;
    [device lockForConfiguration:nil];
    // Set torch and select button image
    if (torchOn) {
        device.torchMode = AVCaptureTorchModeOn;
        settings.flashMode = AVCaptureFlashModeOn;
        img = [UIImage imageNamed:@"torch_on"];
    }
    else {
        device.torchMode = AVCaptureTorchModeOff;
        settings.flashMode = AVCaptureFlashModeOff;
        img = [UIImage imageNamed:@"torch"];
    }
    // Check for class of sender and use matching function to set button image
    if ([sender isKindOfClass:[UIImageView class]]) {
        [sender setImage:img];
    }
    else if ([sender isKindOfClass:[UIButton class]]) {
        [sender setImage:img forState:UIControlStateNormal];
    }
    else {
        NSAssert(NO, @"Unexpected class. Cannot set image for torch icon.");
    }
        
    [device unlockForConfiguration];
}

+ (BOOL)hasTorch {
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    return device.hasTorch && device.hasFlash;
}

+ (BOOL)isTorchOn {
    BOOL torchIsOn = NO;
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if (device.hasTorch && device.hasFlash) {
        torchIsOn = device.torchActive;
    }
    return torchIsOn;
}

+ (BOOL)hasRemoteToolBar {
    return UIScreen.mainScreen.bounds.size.height >= 568;
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

+ (void)setStyleOfMenuItemCell:(UITableViewCell*)cell active:(BOOL)active {
    CGFloat alpha = active ? 1.0 : 0.3;
    UIImageView *icon = (UIImageView*)[cell viewWithTag:XIB_MAIN_MENU_CELL_ICON];
    UILabel *title = (UILabel*)[cell viewWithTag:XIB_MAIN_MENU_CELL_TITLE];
    icon.alpha = alpha;
    title.alpha = alpha;
}

+ (void)setStyleOfMenuItems:(UITableView*)tableView active:(BOOL)active {
    for (NSIndexPath *indexPath in tableView.indexPathsForVisibleRows) {
        // The iPhone uses the top most cell as connection status. This should not be faded/unfaded.
        if (IS_IPHONE && indexPath.row == 0 && indexPath.section == 0) {
            continue;
        }
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        [UIView animateWithDuration:0.3
                         animations:^{
                            [Utilities setStyleOfMenuItemCell:cell active:active];
                         }];
    }
}

+ (NSIndexPath*)getIndexPathForDefaultController:(NSArray*)menuItems {
    // Read the default controller from the app settings
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *label = [userDefaults stringForKey:@"start_menu"];
    
    // Search for the index path of the desired controller
    for (int row = 0; row < menuItems.count; ++row) {
        mainMenu *item = menuItems[row];
        if ([item.rootLabel isEqualToString:LOCALIZED_STR(label)]) {
            return [NSIndexPath indexPathForRow:row inSection:0];
        }
    }
    return nil;
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

+ (void)AnimView:(UIView*)view AnimDuration:(NSTimeInterval)seconds Alpha:(CGFloat)alphavalue XPos:(int)X {
    [UIView animateWithDuration:seconds
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
        view.alpha = alphavalue;
        CGRect frame = view.frame;
        frame.origin.x = X;
        view.frame = frame;
                     }
                     completion:^(BOOL finished) {}];
}

+ (void)AnimView:(UIView*)view AnimDuration:(NSTimeInterval)seconds Alpha:(CGFloat)alphavalue XPos:(int)X YPos:(int)Y {
    [UIView animateWithDuration:seconds
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
        CGRect frame = view.frame;
        frame.origin.x = X;
        frame.origin.y = Y;
        view.frame = frame;
                     }
                     completion:^(BOOL finished) {}];
}

+ (void)alphaView:(UIView*)view AnimDuration:(NSTimeInterval)seconds Alpha:(CGFloat)alphavalue {
    [UIView animateWithDuration:seconds
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
        view.alpha = alphavalue;
                     }
                     completion:^(BOOL finished) {}];
}

+ (void)imageView:(UIImageView*)view AnimDuration:(NSTimeInterval)seconds Image:(UIImage*)image {
    [UIView transitionWithView:view
                      duration:seconds
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{
        view.image = image;
                    }
                    completion:^(BOOL finished) {}];
}

+ (void)colorLabel:(UILabel*)view AnimDuration:(NSTimeInterval)seconds Color:(UIColor*)color {
    [UIView transitionWithView:view
                      duration:seconds
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{
        view.textColor = color;
                    }
                    completion:^(BOOL finished) {}];
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

+ (BOOL)isValidIP6Address:(NSString *)ip {
    const char *utf8 = [ip UTF8String];

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

@end

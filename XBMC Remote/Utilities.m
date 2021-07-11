//
//  Utilities.m
//  XBMC Remote
//
//  Created by Giovanni Messina on 4/3/13.
//  Copyright (c) 2013 joethefox inc. All rights reserved.
//

#import "Utilities.h"
#import "AppDelegate.h"

#define RGBA(r, g, b, a) [UIColor colorWithRed:(r)/255.0 green:(g)/255.0 blue:(b)/255.0 alpha:(a)]
#define XBMC_LOGO_PADDING 10

@implementation Utilities

+ (CGContextRef)createBitmapContextFromImage:(CGImageRef)inImage format:(uint32_t)format {
    size_t width = CGImageGetWidth(inImage);
    size_t height = CGImageGetHeight(inImage);
    unsigned long bytesPerRow = (width * 4); // 4 bytes for alpha, red, green and blue
    
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

+ (UIColor*)averageColor:(UIImage*)image inverse:(BOOL)inverse {
    CGImageRef rawImageRef = [image CGImage];
    if (rawImageRef == nil) return [UIColor clearColor];
    
    CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(rawImageRef);
    int infoMask = (bitmapInfo & kCGBitmapAlphaInfoMask);
    BOOL anyNonAlpha = (infoMask == kCGImageAlphaNone ||
                        infoMask == kCGImageAlphaNoneSkipFirst ||
                        infoMask == kCGImageAlphaNoneSkipLast);
//    if (!anyNonAlpha) return [UIColor clearColor];
    
    // Enforce images are converted to ARGB or RGB 32bpp before analyzing them
    if (anyNonAlpha && (infoMask != kCGImageAlphaNoneSkipLast || CGImageGetBitsPerPixel(rawImageRef) != 32)) {
        rawImageRef = [Utilities create32bppImage:rawImageRef format:kCGImageAlphaNoneSkipLast];
    }
    else if (!anyNonAlpha && (infoMask != kCGImageAlphaPremultipliedFirst || CGImageGetBitsPerPixel(rawImageRef) != 32)) {
        rawImageRef = [Utilities create32bppImage:rawImageRef format:kCGImageAlphaPremultipliedFirst];
    }
    if (rawImageRef == NULL) {
        return [UIColor clearColor];
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
        bright = MIN((MAX(bright * brightscale, brightmin)), brightmax);
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
    if ([newColor isEqual:[UIColor clearColor]] || newColor == nil) {
        return lighter;
    }
    const CGFloat *componentColors = CGColorGetComponents(newColor.CGColor);
    CGFloat colorBrightness = ((componentColors[0] * 299) + (componentColors[1] * 587) + (componentColors[2] * 114)) / 1000;
    if (colorBrightness < trigger) {
        return lighter;
    }
    else {
        return darker;
    }
}

+ (UIImage*)colorizeImage:(UIImage*)image withColor:(UIColor*)color {
    if (color == nil) return image;
    UIGraphicsBeginImageContextWithOptions(image.size, YES, [[UIScreen mainScreen] scale]);
    
    CGRect contextRect = (CGRect) {.origin = CGPointZero, .size = [image size]};
    
    CGSize itemImageSize = [image size];
    CGPoint itemImagePosition;
    itemImagePosition.x = ceilf((contextRect.size.width - itemImageSize.width) / 2);
    itemImagePosition.y = ceilf((contextRect.size.height - itemImageSize.height));
    
    UIGraphicsBeginImageContextWithOptions(contextRect.size, NO, [[UIScreen mainScreen] scale]);
    
    CGContextRef c = UIGraphicsGetCurrentContext();
    
    CGContextBeginTransparencyLayer(c, NULL);
    CGContextScaleCTM(c, 1.0, -1.0);
    CGContextClipToMask(c, CGRectMake(itemImagePosition.x, -itemImagePosition.y, itemImageSize.width, -itemImageSize.height), [image CGImage]);

    CGColorSpaceRef colorSpace = CGColorGetColorSpace(color.CGColor);
    CGColorSpaceModel model = CGColorSpaceGetModel(colorSpace);
    const CGFloat* colors = CGColorGetComponents(color.CGColor);
    
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

+ (void)setLogoBackgroundColor:(UIImageView*)imageview mode:(LogoBackgroundType)mode {
    UIColor *bgcolor = [UIColor clearColor];
    UIColor *imgcolor = nil;
    UIColor *bglight = [Utilities getGrayColor:242 alpha:1.0];
    UIColor *bgdark = [Utilities getGrayColor:28 alpha:1.0];
    switch (mode) {
        case bgAuto:
            // get background color and colorize the image background
            imgcolor = [Utilities averageColor:imageview.image inverse:NO];
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
    [imageview setBackgroundColor:bgcolor];
}

+ (LogoBackgroundType)getLogoBackgroundMode {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    LogoBackgroundType setting = bgAuto;
    NSString *mode = [userDefaults stringForKey:@"logo_background"];
    if ([mode length]) {
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
    if ([AppDelegate instance].serverVersion < 15) {
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

+ (NSArray*)buildPlayerSeekStepParams:(NSString*)stepmode {
    NSArray *params = nil;
    if ([AppDelegate instance].serverVersion < 15) {
        params = @[stepmode, @"value"];
    }
    else {
        params = @[@{@"step": stepmode}, @"value"];
    }
    return params;
}

+ (CGFloat)getTransformX {
    // We scale for iPhone with their different device widths.
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (CGRectGetWidth(UIScreen.mainScreen.fixedCoordinateSpace.bounds) / IPHONE_SCREEN_DESIGN_WIDTH);
    }
    // For iPad a fixed frame width is used.
    else {
        return (STACKSCROLL_WIDTH / IPAD_SCREEN_DESIGN_WIDTH);
    }
}

+ (UIColor*)getSystemRed:(CGFloat)alpha {
    return [[UIColor systemRedColor] colorWithAlphaComponent:alpha];
}

+ (UIColor*)getSystemGreen:(CGFloat)alpha {
    return [[UIColor systemGreenColor] colorWithAlphaComponent:alpha];
}

+ (UIColor*)getSystemBlue {
    return [UIColor systemBlueColor];
}

+ (UIColor*)getSystemTeal {
    return [UIColor systemTealColor];
}

+ (UIColor*)getSystemGray1 {
    return [UIColor systemGrayColor];
}

+ (UIColor*)getSystemGray2 {
    if (@available(iOS 13.0, *)) {
        return [UIColor systemGray2Color];
    }
    else {
        return RGBA(174, 174, 178, 1.0);
    }
}

+ (UIColor*)getSystemGray3 {
    if (@available(iOS 13.0, *)) {
        return [UIColor systemGray3Color];
    }
    else {
        return RGBA(199, 199, 204, 1.0);
    }
}

+ (UIColor*)getSystemGray4 {
    if (@available(iOS 13.0, *)) {
        return [UIColor systemGray4Color];
    }
    else {
        return RGBA(209, 209, 214, 1.0);
    }
}

+ (UIColor*)getSystemGray5 {
    if (@available(iOS 13.0, *)) {
        return [UIColor systemGray5Color];
    }
    else {
        return RGBA(229, 229, 234, 1.0);
    }
}

+ (UIColor*)getSystemGray6 {
    if (@available(iOS 13.0, *)) {
        return [UIColor systemGray6Color];
    }
    else {
        return RGBA(242, 242, 247, 1.0);
    }
}

+ (UIColor*)get1stLabelColor {
    if (@available(iOS 13.0, *)) {
        return [UIColor labelColor];
    }
    else {
        return RGBA(0, 0, 0, 1.0);
    }
}

+ (UIColor*)get2ndLabelColor {
    if (@available(iOS 13.0, *)) {
        return [UIColor secondaryLabelColor];
    }
    else {
        return RGBA(60, 60, 67, 0.6);
    }
}

+ (UIColor*)get3rdLabelColor {
    if (@available(iOS 13.0, *)) {
        return [UIColor tertiaryLabelColor];
    }
    else {
        return RGBA(60, 60, 67, 0.3);
    }
}

+ (UIColor*)get4thLabelColor {
    if (@available(iOS 13.0, *)) {
        return [UIColor quaternaryLabelColor];
    }
    else {
        return RGBA(60, 60, 67, 0.18);
    }
}

+ (UIColor*)getGrayColor:(int)tone alpha:(CGFloat)alpha {
    return RGBA(tone, tone, tone, alpha);
}

+ (CGRect)createXBMCInfoframe:(UIImage*)logo height:(CGFloat)height width:(CGFloat)width {
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return CGRectMake(width - ANCHOR_RIGHT_PEEK - logo.size.width - XBMC_LOGO_PADDING, (height - logo.size.height)/2, logo.size.width, logo.size.height);
    }
    else {
        return CGRectMake(width - logo.size.width/2 - XBMC_LOGO_PADDING, (height - logo.size.height/2)/2, logo.size.width/2, logo.size.height/2);
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
    frame.origin.y = floor(jewelView.center.y - frame.size.height/2 + (border_top - border_bottom)/2 * factor);
    frame.origin.x = floor(jewelView.center.x - frame.size.width/2 + (border_left - border_right)/2 * factor);
    return frame;
}

+ (UIAlertController*)createAlertOK:(NSString*)title message:(NSString*)msg {
    UIAlertController *alertView = [UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* okButton = [UIAlertAction actionWithTitle:LOCALIZED_STR(@"OK") style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
    [alertView addAction:okButton];
    return alertView;
}

+ (UIAlertController*)createAlertCopyClipboard:(NSString*)title message:(NSString*)msg {
    UIAlertController *alertView = [UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* copyButton = [UIAlertAction actionWithTitle:LOCALIZED_STR(@"Copy to clipboard") style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
            UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
            pasteboard.string = msg;
    }];
    UIAlertAction* cancelButton = [UIAlertAction actionWithTitle:LOCALIZED_STR(@"Cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction * action) {}];
    [alertView addAction:copyButton];
    [alertView addAction:cancelButton];
    return alertView;
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
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        // On iPad presenting from the active ViewController results in blank screen
        ctrl = UIApplication.sharedApplication.keyWindow.rootViewController;
    }
    if (![svc isBeingPresented]) {
        [ctrl presentViewController:svc animated:YES completion:nil];
    }
}

+ (DSJSONRPC*)getJsonRPC {
    return [[DSJSONRPC alloc] initWithServiceEndpoint:[AppDelegate instance].getServerJSONEndPoint andHTTPHeaders:[AppDelegate instance].getServerHTTPHeaders];
}

+ (NSDictionary*)indexKeyedDictionaryFromArray:(NSArray*)array {
    NSMutableDictionary *mutableDictionary = [NSMutableDictionary new];
    NSInteger numelement = [array count];
    for (int i = 0; i < numelement-1; i += 2) {
        mutableDictionary[array[i+1]] = array[i];
    }
    return (NSDictionary*)mutableDictionary;
}

+ (NSMutableDictionary*)indexKeyedMutableDictionaryFromArray:(NSArray*)array {
    NSMutableDictionary *mutableDictionary = [NSMutableDictionary new];
    NSInteger numelement = [array count];
    for (int i = 0; i < numelement-1; i += 2) {
        mutableDictionary[array[i+1]] = array[i];
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

+ (NSString*)getItemIconFromDictionary:(NSDictionary*)dict mainFields:(NSDictionary*)mainFields {
    NSString *filetype = @"";
    NSString *iconName = @"";
    if (dict[@"filetype"] != nil) {
        filetype = dict[@"filetype"];
        if ([filetype isEqualToString:@"directory"]) {
            iconName = @"nocover_filemode";
        }
        else if ([filetype isEqualToString:@"file"]) {
            if ([mainFields[@"playlistid"] intValue] == 0) {
                iconName = @"icon_song";
            }
            else if ([mainFields[@"playlistid"] intValue] == 1) {
                iconName = @"icon_video";
            }
            else if ([mainFields[@"playlistid"] intValue] == 2) {
                iconName = @"icon_picture";
            }
        }
    }
    return iconName;
}

+ (NSString*)getStringFromDictionary:(NSDictionary*)dict key:(NSString*)key emptyString:(NSString*)empty {
    NSString *text = @"";
    id value = dict[key];
    if (value == nil) {
        text = empty;
    }
    else if ([value isKindOfClass:[NSArray class]]) {
        text = [value componentsJoinedByString:@" / "];
        text = [text length] == 0 ? empty : text;
    }
    else if ([value isKindOfClass:[NSNumber class]]) {
        text = [NSString stringWithFormat:@"%@", value];
    }
    else {
        text = [value length] == 0 ? empty : value;
    }
    return text;
}

+ (NSString*)getTimeFromDictionary:(NSDictionary*)dict key:(NSString*)key sec2min:(int)secondsToMinute {
    NSString *runtime = @"";
    id value = dict[key];
    if (value == nil) {
        runtime = @"";
    }
    else if ([value isKindOfClass:[NSArray class]]) {
        runtime = [NSString stringWithFormat:@"%@", [value componentsJoinedByString:@" / "]];
    }
    else if ([value intValue]) {
        runtime = [NSString stringWithFormat:@"%d min", [value intValue]/secondsToMinute];
    }
    else {
        runtime = [NSString stringWithFormat:@"%@", value];
    }
    return runtime;
}

+ (NSString*)getYearFromDictionary:(NSDictionary*)dict key:(NSString*)key {
    NSString *year = @"";
    id value = dict[key];
    if (value == nil) {
        year = @"";
    }
    else if ([value isKindOfClass:[NSNumber class]]) {
        year = [(NSNumber*)value stringValue];
    }
    else {
        if ([key isEqualToString:@"blank"]) {
            year = @"";
        }
        else {
            year = value;
        }
    }
    return year;
}

+ (NSString*)getRatingFromDictionary:(NSDictionary*)dict key:(NSString*)key {
    NSString *rating = [NSString stringWithFormat:@"%.1f", [(NSNumber*)dict[key] floatValue]];
    if ([rating isEqualToString:@"0.0"]) {
        rating = @"";
    }
    return rating;
}

+ (NSString*)getClearArtFromDictionary:(NSDictionary*)dict type:(NSString*)type {
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

+ (UIImage*)imageWithShadow:(UIImage*)source radius:(CGFloat)radius {
    CGColorSpaceRef colourSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef shadowContext = CGBitmapContextCreate(NULL, source.size.width + radius * 2, source.size.height + radius * 2, CGImageGetBitsPerComponent(source.CGImage), 0, colourSpace, kCGBitmapAlphaInfoMask & kCGImageAlphaPremultipliedLast);
    CGColorSpaceRelease(colourSpace);

    CGContextSetShadowWithColor(shadowContext, CGSizeZero, radius, [UIColor blackColor].CGColor);
    CGContextDrawImage(shadowContext, CGRectMake(radius, radius, source.size.width, source.size.height), source.CGImage);

    CGImageRef shadowedCGImage = CGBitmapContextCreateImage(shadowContext);
    CGContextRelease(shadowContext);

    UIImage * shadowedImage = [UIImage imageWithCGImage:shadowedCGImage];
    CGImageRelease(shadowedCGImage);

    return shadowedImage;
}

@end

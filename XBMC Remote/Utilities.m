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

- (UIColor *)averageColor:(UIImage *)image inverse:(BOOL)inverse{
    CGImageRef rawImageRef = [image CGImage];
    if (rawImageRef == nil) return [UIColor clearColor];
    
    CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(rawImageRef);
    int infoMask = (bitmapInfo & kCGBitmapAlphaInfoMask);
    BOOL anyNonAlpha = (infoMask == kCGImageAlphaNone ||
                        infoMask == kCGImageAlphaNoneSkipFirst ||
                        infoMask == kCGImageAlphaNoneSkipLast);
//    if (!anyNonAlpha) return [UIColor clearColor];
	CFDataRef data = CGDataProviderCopyData(CGImageGetDataProvider(rawImageRef));
    const UInt8 *rawPixelData = CFDataGetBytePtr(data);
    
    NSUInteger imageHeight = CGImageGetHeight(rawImageRef);
    NSUInteger imageWidth  = CGImageGetWidth(rawImageRef);
    NSUInteger bytesPerRow = CGImageGetBytesPerRow(rawImageRef);
	NSUInteger stride = CGImageGetBitsPerPixel(rawImageRef) / 8;
    
    unsigned int red   = 0;
    unsigned int green = 0;
    unsigned int blue  = 0;
    unsigned int alpha = 0;
    CGFloat f = 1.0;
    
    if (anyNonAlpha) {
        // no alpha channel present
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
        for (int row = 0; row < imageHeight; row++) {
            const UInt8 *rowPtr = rawPixelData + bytesPerRow * row;
            for (int column = 0; column < imageWidth; column++) {
                red    += rowPtr[0] * rowPtr[3];
                green  += rowPtr[1] * rowPtr[3];
                blue   += rowPtr[2] * rowPtr[3];
                alpha  += rowPtr[3];
                rowPtr += stride;
            }
        }
        f = 1.0 / (255.0 * alpha);
    }
    if (inverse) {
        unsigned int tmp = red;
        red = blue;
        blue = tmp;
    }
	CFRelease(data);
    
	return [UIColor colorWithRed:f * red  green:f * green blue:f * blue alpha:1];
}

+ (UIColor *)tailorColor:(UIColor *)color_in satscale:(CGFloat)satscale brightscale:(CGFloat)brightscale brightmin:(CGFloat)brightmin brightmax:(CGFloat)brightmax{
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

- (UIColor *)slightLighterColorForColor:(UIColor *)color_in{
    return [Utilities tailorColor:color_in satscale:0.33 brightscale:1.2 brightmin:0.5 brightmax:0.6];
}

- (UIColor *)lighterColorForColor:(UIColor *)color_in{
    return [Utilities tailorColor:color_in satscale:0.33 brightscale:1.5 brightmin:0.7 brightmax:0.9];
}

- (UIColor *)darkerColorForColor:(UIColor *)color_in{
    return [Utilities tailorColor:color_in satscale:0.33 brightscale:0.7 brightmin:0.2 brightmax:0.4];
}

- (UIColor *)updateColor:(UIColor *) newColor lightColor:(UIColor *)lighter darkColor:(UIColor *)darker{
    CGFloat trigger = 0.4;
    return [self updateColor:newColor lightColor:lighter darkColor:darker trigger:trigger];
}

- (UIColor *)updateColor:(UIColor *) newColor lightColor:(UIColor *)lighter darkColor:(UIColor *)darker trigger:(CGFloat)trigger{
    if ([newColor isEqual:[UIColor clearColor]] || newColor == nil) return lighter;
    const CGFloat *componentColors = CGColorGetComponents(newColor.CGColor);
    CGFloat colorBrightness = ((componentColors[0] * 299) + (componentColors[1] * 587) + (componentColors[2] * 114)) / 1000;
    if (colorBrightness < trigger){
        return lighter;
    }
    else{
        return darker;
    }
}

- (UIImage*)colorizeImage:(UIImage *)image withColor:(UIColor*)color{
    if (color == nil) return image;
    UIGraphicsBeginImageContextWithOptions(image.size, YES, [[UIScreen mainScreen] scale]);
    
    CGRect contextRect = (CGRect){.origin = CGPointZero, .size = [image size]};
    
    CGSize itemImageSize = [image size];
    CGPoint itemImagePosition;
    itemImagePosition.x = ceilf((contextRect.size.width - itemImageSize.width) / 2);
    itemImagePosition.y = ceilf((contextRect.size.height - itemImageSize.height) );
    
    UIGraphicsBeginImageContextWithOptions(contextRect.size, NO, [[UIScreen mainScreen] scale]);
    
    CGContextRef c = UIGraphicsGetCurrentContext();
    
    CGContextBeginTransparencyLayer(c, NULL);
    CGContextScaleCTM(c, 1.0, -1.0);
    CGContextClipToMask(c, CGRectMake(itemImagePosition.x, -itemImagePosition.y, itemImageSize.width, -itemImageSize.height), [image CGImage]);

    CGColorSpaceRef colorSpace = CGColorGetColorSpace(color.CGColor);
    CGColorSpaceModel model = CGColorSpaceGetModel(colorSpace);
    const CGFloat* colors = CGColorGetComponents(color.CGColor);
    
    if(model == kCGColorSpaceModelMonochrome){
        CGContextSetRGBFillColor(c, colors[0], colors[0], colors[0], colors[1]);
    }
    else{
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

+ (NSDictionary*)buildPlayerSeekPercentageParams:(int)playerID percentage:(float)percentage{
    NSDictionary *params = nil;
    if ([AppDelegate instance].serverVersion < 15){
        params = @{
            @"playerid": @(playerID),
            @"value": @(percentage),
        };
    } else
    {
        params = @{
            @"playerid": @(playerID),
            @"value": @{@"percentage": @(percentage)},
        };
    }
    return params;
}

+ (NSArray*)buildPlayerSeekStepParams:(NSString*)stepmode{
    NSArray *params = nil;
    if ([AppDelegate instance].serverVersion < 15){
        params = @[stepmode, @"value"];
    } else
    {
        params = @[ @{@"step": stepmode}, @"value"];
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

+ (UIColor*)getSystemRed:(CGFloat)alpha{
    return [[UIColor systemRedColor] colorWithAlphaComponent:alpha];
}

+ (UIColor*)getSystemGreen:(CGFloat)alpha{
    return [[UIColor systemGreenColor] colorWithAlphaComponent:alpha];
}

+ (UIColor*)getSystemBlue{
    return [UIColor systemBlueColor];
}

+ (UIColor*)getSystemTeal{
    return [UIColor systemTealColor];
}

+ (UIColor*)getSystemGray1{
    return [UIColor systemGrayColor];
}

+ (UIColor*)getSystemGray2{
    if (@available(iOS 13.0, *)) {
        return [UIColor systemGray2Color];
    } else {
        return RGBA(174, 174, 178, 1.0);
    }
}

+ (UIColor*)getSystemGray3{
    if (@available(iOS 13.0, *)) {
        return [UIColor systemGray3Color];
    } else {
        return RGBA(199, 199, 204, 1.0);
    }
}

+ (UIColor*)getSystemGray4{
    if (@available(iOS 13.0, *)) {
        return [UIColor systemGray4Color];
    } else {
        return RGBA(209, 209, 214, 1.0);
    }
}

+ (UIColor*)getSystemGray5{
    if (@available(iOS 13.0, *)) {
        return [UIColor systemGray5Color];
    } else {
        return RGBA(229, 229, 234, 1.0);
    }
}

+ (UIColor*)getSystemGray6{
    if (@available(iOS 13.0, *)) {
        return [UIColor systemGray6Color];
    } else {
        return RGBA(242, 242, 247, 1.0);
    }
}

+ (UIColor*)get1stLabelColor{
    if (@available(iOS 13.0, *)) {
        return [UIColor labelColor];
    } else {
        return RGBA(0, 0, 0, 1.0);
    }
}

+ (UIColor*)get2ndLabelColor{
    if (@available(iOS 13.0, *)) {
        return [UIColor secondaryLabelColor];
    } else {
        return RGBA(60, 60, 67, 0.6);
    }
}

+ (UIColor*)get3rdLabelColor{
    if (@available(iOS 13.0, *)) {
        return [UIColor tertiaryLabelColor];
    } else {
        return RGBA(60, 60, 67, 0.3);
    }
}

+ (UIColor*)get4thLabelColor{
    if (@available(iOS 13.0, *)) {
        return [UIColor quaternaryLabelColor];
    } else {
        return RGBA(60, 60, 67, 0.18);
    }
}

+ (UIColor*)getGrayColor:(int)tone alpha:(CGFloat)alpha{
    return RGBA(tone, tone, tone, alpha);
}

+ (CGRect)createXBMCInfoframe:(UIImage *)logo height:(CGFloat)height width:(CGFloat)width {
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return CGRectMake(width - ANCHORRIGHTPEEK - logo.size.width - XBMC_LOGO_PADDING, (height - logo.size.height)/2, logo.size.width, logo.size.height);
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
    UIAlertAction* okButton = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
    [alertView addAction:okButton];
    return alertView;
}

+ (UIAlertController*)createAlertCopyClipboard:(NSString*)title message:(NSString*)msg {
    UIAlertController *alertView = [UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* copyButton = [UIAlertAction actionWithTitle:NSLocalizedString(@"Copy to clipboard", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
            UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
            pasteboard.string = msg;
    }];
    UIAlertAction* cancelButton = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
    [alertView addAction:copyButton];
    [alertView addAction:cancelButton];
    return alertView;
}

+ (void)SFloadURL:(NSString*)url fromctrl:(UIViewController<SFSafariViewControllerDelegate> *)fromctrl {
    NSURL *nsurl = [NSURL URLWithString:url];
    SFSafariViewController *svc = [[SFSafariViewController alloc] initWithURL:nsurl];
    UIViewController *ctrl = fromctrl;
    svc.delegate = fromctrl;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        // On iPad presenting from the active ViewController results in blank screen
        ctrl = UIApplication.sharedApplication.keyWindow.rootViewController;
    }
    [ctrl presentViewController:svc animated:YES completion:nil];
}

@end

//
//  Utilities.m
//  XBMC Remote
//
//  Created by Giovanni Messina on 4/3/13.
//  Copyright (c) 2013 joethefox inc. All rights reserved.
//

#import "Utilities.h"
#import "AppDelegate.h"

@implementation Utilities

- (UIColor *)averageColor:(UIImage *)image inverse:(BOOL)inverse{
    CGImageRef rawImageRef = [image CGImage];
    if (rawImageRef == nil) return [UIColor clearColor];
    
    CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(rawImageRef);

    int infoMask = (bitmapInfo & kCGBitmapAlphaInfoMask);
    BOOL anyNonAlpha = (infoMask == kCGImageAlphaNone ||
                        infoMask == kCGImageAlphaNoneSkipFirst ||
                        infoMask == kCGImageAlphaNoneSkipLast);
    if (!anyNonAlpha) return [UIColor clearColor];
	CFDataRef data = CGDataProviderCopyData(CGImageGetDataProvider(rawImageRef));
    const UInt8 *rawPixelData = CFDataGetBytePtr(data);
    
    NSUInteger imageHeight = CGImageGetHeight(rawImageRef);
    NSUInteger imageWidth  = CGImageGetWidth(rawImageRef);
    NSUInteger bytesPerRow = CGImageGetBytesPerRow(rawImageRef);
	NSUInteger stride = CGImageGetBitsPerPixel(rawImageRef) / 8;
    
    unsigned int red   = 0;
    unsigned int green = 0;
    unsigned int blue  = 0;
    
	for (int row = 0; row < imageHeight; row++) {
		const UInt8 *rowPtr = rawPixelData + bytesPerRow * row;
		for (int column = 0; column < imageWidth; column++) {
            if (inverse == YES){
                blue    += rowPtr[0];
                red   += rowPtr[2];
            }
            else{
                red    += rowPtr[0];
                blue   += rowPtr[2];
            }
            green  += rowPtr[1];
			rowPtr += stride;
        }
    }
	CFRelease(data);
    
	CGFloat f = 1.0f / (255.0f * imageWidth * imageHeight);
	return [UIColor colorWithRed:f * red  green:f * green blue:f * blue alpha:1];
}

- (UIColor *)slightLighterColorForColor:(UIColor *)c{
    CGFloat r, g, b, a;
    if ([c getRed:&r green:&g blue:&b alpha:&a])
        return [UIColor colorWithRed:MIN(r + 0.2, 1.0)
                               green:MIN(g + 0.2, 1.0)
                                blue:MIN(b + 0.2, 1.0)
                               alpha:a];
    return nil;
}

- (UIColor *)lighterColorForColor:(UIColor *)c{
    CGFloat r, g, b, a;
    if ([c getRed:&r green:&g blue:&b alpha:&a])
        return [UIColor colorWithRed:MIN(r + 0.4, 1.0)
                               green:MIN(g + 0.4, 1.0)
                                blue:MIN(b + 0.4, 1.0)
                               alpha:a];
    return nil;
}

- (UIColor *)darkerColorForColor:(UIColor *)c{
    CGFloat r, g, b, a;
    if ([c getRed:&r green:&g blue:&b alpha:&a])
        return [UIColor colorWithRed:MAX(r - 0.1, 0.0)
                               green:MAX(g - 0.1, 0.0)
                                blue:MAX(b - 0.1, 0.0)
                               alpha:a];
    return nil;
}

- (UIColor *)updateColor:(UIColor *) newColor lightColor:(UIColor *)lighter darkColor:(UIColor *)darker{
    CGFloat trigger = 0.4f;
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
    
    CGRect contextRect;
    contextRect.origin.x = 0.0f;
    contextRect.origin.y = 0.0f;
    contextRect.size = [image size];
    
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

@end
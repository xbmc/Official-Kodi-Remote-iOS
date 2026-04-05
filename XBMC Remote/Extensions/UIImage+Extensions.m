//
//  NSString+Extensions.m
//  Kodi Remote
//
//  Created by Buschmann on 05.04.26.
//  Copyright © 2026 Team Kodi. All rights reserved.
//

#import "UIImage+Extensions.h"
#import "Utilities.h"

#define IMAGE_SIZE_COLOR_AVERAGING CGSizeMake(64, 64) // Scale (down) to this size before averaging an image color

@implementation UIImage (Extensions)

- (UIImage*)setCornerRadiusForRoundedEdges {
    if (self.size.width == 0 || self.size.height == 0) {
        return self;
    }
    
    CGRect imageRect = CGRectMake(0, 0, self.size.width, self.size.height);
    UIGraphicsBeginImageContextWithOptions(self.size, NO, 0);

    // Set radius for corners
    CGFloat radius = GET_ROUNDED_EDGES_RADIUS(self.size);
    
    // Define our path, capitalizing on UIKit's corner rounding magic
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:imageRect cornerRadius:radius];
    [path addClip];

    // Draw the image into the implicit context
    [self drawInRect:imageRect];
     
    // Get image and cleanup
    UIImage *roundedCornerImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return roundedCornerImage;
}

- (UIImage*)applyRoundedEdges {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    BOOL corner_preference = [userDefaults boolForKey:@"rounded_corner_preference"];
    if (corner_preference) {
        return [self setCornerRadiusForRoundedEdges];
    }
    return self;
}

- (UIColor*)averageColor {
    CGImageRef linearSrgbImageRef = [Utilities createLinearSRGBFromImage:self size:IMAGE_SIZE_COLOR_AVERAGING];
    if (linearSrgbImageRef == NULL) {
        return nil;
    }
    
    UIColor *averageColor = [Utilities averageColorForImageRef:linearSrgbImageRef];
    CGImageRelease(linearSrgbImageRef);
    
    return averageColor;
}

- (UIImage*)colorizeWithColor:(UIColor*)color {
    if (color == nil || self.size.width == 0 || self.size.height == 0) {
        return self;
    }
    CGRect contextRect = (CGRect) {.origin = CGPointZero, .size = self.size};
    UIImage *newImage = [self imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    UIGraphicsBeginImageContextWithOptions(newImage.size, NO, newImage.scale);
    [color set];
    [newImage drawInRect:contextRect];
    newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

- (UIImage*)resizedImageSize:(CGSize)newSize aspectMode:(UIViewContentMode)contentMode {
    CGImageRef imageRef = self.CGImage;
    
    // Calculate new dimension for the three scale modes, default is ScaleAspectFill.
    CGFloat horizontalRatio = newSize.width / self.size.width;
    CGFloat verticalRatio = newSize.height / self.size.height;
    CGFloat ratio, width, height;
    switch (contentMode) {
        case UIViewContentModeScaleToFill:
            width = newSize.width;
            height = newSize.height;
            break;
            
        case UIViewContentModeScaleAspectFit:
            ratio = MIN(horizontalRatio, verticalRatio);
            width = floor(self.size.width * ratio);
            height = floor(self.size.height * ratio);
            break;
            
        case UIViewContentModeScaleAspectFill:
        default:
            ratio = MAX(horizontalRatio, verticalRatio);
            width = floor(self.size.width * ratio);
            height = floor(self.size.height * ratio);
            break;
    }
    
    // The new image will have the target dimension given by newSize. We need to render
    // the scaled image into this and will place it centralized.
    CGRect newImageRect = CGRectMake(floor((newSize.width - width) / 2),
                                     floor((newSize.height - height) / 2),
                                     width,
                                     height);
    
    // Read color space. Only create new color space (memory intense), if it is not already RGB.
    CGColorSpaceModel imageColorSpaceModel = CGColorSpaceGetModel(CGImageGetColorSpace(imageRef));
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(imageRef);
    BOOL isRGB = imageColorSpaceModel == kCGColorSpaceModelRGB;
    if (!isRGB) {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    
    CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(imageRef);
    
    CGImageAlphaInfo infoMask = (bitmapInfo & kCGBitmapAlphaInfoMask);
    BOOL anyNonAlpha = (infoMask == kCGImageAlphaNone ||
                        infoMask == kCGImageAlphaNoneSkipFirst ||
                        infoMask == kCGImageAlphaNoneSkipLast);
    
    // CGBitmapContextCreate doesn't support kCGImageAlphaNone with RGB.
    // https://developer.apple.com/library/mac/#qa/qa1037/_index.html
    if (infoMask == kCGImageAlphaNone && CGColorSpaceGetNumberOfComponents(colorSpace) > 1) {
        // Unset the old alpha info.
        bitmapInfo &= ~kCGBitmapAlphaInfoMask;
        
        // Set noneSkipFirst.
        bitmapInfo |= kCGImageAlphaNoneSkipFirst;
    }
    // Some PNGs tell us they have alpha but only 3 components. Odd.
    else if (!anyNonAlpha && CGColorSpaceGetNumberOfComponents(colorSpace) == 3) {
        // Unset the old alpha info.
        bitmapInfo &= ~kCGBitmapAlphaInfoMask;
        bitmapInfo |= kCGImageAlphaPremultipliedFirst;
    }
    
    CGContextRef bitmap = CGBitmapContextCreate(NULL,
                                                newSize.width,
                                                newSize.height,
                                                CGImageGetBitsPerComponent(imageRef),
                                                0,
                                                colorSpace,
                                                bitmapInfo);
    
    CGContextSetShouldAntialias(bitmap, YES);
    CGContextSetAllowsAntialiasing(bitmap, YES);
    CGContextSetInterpolationQuality(bitmap, kCGInterpolationHigh);
    CGContextDrawImage(bitmap, newImageRect, imageRef);
    CGImageRef newImageRef = CGBitmapContextCreateImage(bitmap);
    UIImage *newImage = [UIImage imageWithCGImage:newImageRef];
    
    // Release memory
    if (!isRGB) {
        CGColorSpaceRelease(colorSpace);
    }
    CGContextRelease(bitmap);
    CGImageRelease(newImageRef);
    
    return newImage;
}

@end

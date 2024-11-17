//
//  UIImage+Resize.m
//  XBMC Remote
//
//  Created by Giovanni Messina on 31/3/13.
//  Copyright (c) 2013 joethefox inc. All rights reserved.
//

#import "UIImage+Resize.h"

@implementation UIImage (Resize)

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

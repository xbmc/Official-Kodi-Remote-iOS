//
//  UIImage+Resize.m
//  XBMC Remote
//
//  Created by Giovanni Messina on 31/3/13.
//  Copyright (c) 2013 joethefox inc. All rights reserved.
//

#import "UIImage+Resize.h"

@implementation UIImage (Resize)

- (UIImage *)resizedImage:(CGImageRef)imageRef size:(CGSize)newSize interpolationQuality:(CGInterpolationQuality)quality {
    CGRect newRect;
    CGFloat horizontalRatio = newSize.width / self.size.width;
    CGFloat verticalRatio = newSize.height / self.size.height;
    CGFloat ratio;
    ratio = MAX(horizontalRatio, verticalRatio); //UIViewContentModeScaleAspectFill
    newSize = CGSizeMake(self.size.width * ratio, self.size.height * ratio);
    newRect = CGRectIntegral(CGRectMake(0, 0, newSize.width, newSize.height));
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(imageRef);
    
    int infoMask = (bitmapInfo & kCGBitmapAlphaInfoMask);
    BOOL anyNonAlpha = (infoMask == kCGImageAlphaNone ||
                        infoMask == kCGImageAlphaNoneSkipFirst ||
                        infoMask == kCGImageAlphaNoneSkipLast);
    
    // CGBitmapContextCreate doesn't support kCGImageAlphaNone with RGB.
    // https://developer.apple.com/library/mac/#qa/qa1037/_index.html
    if (infoMask == kCGImageAlphaNone && CGColorSpaceGetNumberOfComponents(colorSpace) > 1)
    {
        // Unset the old alpha info.
        bitmapInfo &= ~kCGBitmapAlphaInfoMask;
        
        // Set noneSkipFirst.
        bitmapInfo |= kCGImageAlphaNoneSkipFirst;
    }
    // Some PNGs tell us they have alpha but only 3 components. Odd.
    else if (!anyNonAlpha && CGColorSpaceGetNumberOfComponents(colorSpace) == 3)
    {
        // Unset the old alpha info.
        bitmapInfo &= ~kCGBitmapAlphaInfoMask;
        bitmapInfo |= kCGImageAlphaPremultipliedFirst;
    }
    
    CGContextRef bitmap = CGBitmapContextCreate(NULL,
                                                newRect.size.width,
                                                newRect.size.height,
                                                CGImageGetBitsPerComponent(imageRef),
                                                0,
                                                colorSpace,
                                                bitmapInfo);
    CGColorSpaceRelease(colorSpace);
    CGContextSetInterpolationQuality(bitmap, quality);
    CGContextDrawImage(bitmap, newRect, imageRef);
    CGImageRef newImageRef = CGBitmapContextCreateImage(bitmap);
    UIImage *newImage = [UIImage imageWithCGImage:newImageRef];
    CGContextRelease(bitmap);
    CGImageRelease(newImageRef);
    return newImage;
}

@end
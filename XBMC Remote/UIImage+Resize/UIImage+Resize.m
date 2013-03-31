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
    CGContextRef bitmap = CGBitmapContextCreate(NULL,
                                                newRect.size.width,
                                                newRect.size.height,
                                                CGImageGetBitsPerComponent(imageRef),
                                                0,
                                                CGImageGetColorSpace(imageRef),
                                                CGImageGetBitmapInfo(imageRef));
    CGContextSetInterpolationQuality(bitmap, quality);
    CGContextDrawImage(bitmap, newRect, imageRef);
    CGImageRef newImageRef = CGBitmapContextCreateImage(bitmap);
    UIImage *newImage = [UIImage imageWithCGImage:newImageRef];
    CGContextRelease(bitmap);
    CGImageRelease(newImageRef);
    return newImage;
}

@end
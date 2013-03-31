//
//  UIImage+Resize.h
//  XBMC Remote
//
//  Created by Giovanni Messina on 31/3/13.
//  Copyright (c) 2013 joethefox inc. All rights reserved.
//
// Extends the UIImage class to support resizing

@interface UIImage (Resize)

- (UIImage *)resizedImage:(CGImageRef)imageRef size:(CGSize)newSize interpolationQuality:(CGInterpolationQuality)quality;

@end
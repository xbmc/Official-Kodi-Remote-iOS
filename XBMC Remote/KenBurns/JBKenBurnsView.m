//
//  KenBurnsView.m
//  KenBurns
//
//  Created by Javier Berlana on 9/23/11.
//  Copyright (c) 2011, Javier Berlana
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this 
//  software and associated documentation files (the "Software"), to deal in the Software 
//  without restriction, including without limitation the rights to use, copy, modify, merge, 
//  publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons 
//  to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies 
//  or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
//  INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR 
//  PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE 
//  FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, 
//  ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS 
//  IN THE SOFTWARE.
//

#import "JBKenBurnsView.h"
#import "AppDelegate.h"
#include <stdlib.h>

#define enlargeRatio 1.1
#define imageBufer 3

// Private interface
@interface KenBurnsView ()

@property (nonatomic) int currentImage;
@property (nonatomic) BOOL animationInCurse;

- (void)_animate:(NSNumber*)num;
- (void)_startAnimations:(NSArray*)images;
- (void)_startInternetAnimations:(NSArray*)urls;
- (UIImage*)_downloadImageFrom:(NSString*)url;
- (void)_notifyDelegate:(NSNumber*)imageIndex;

@end

@implementation KenBurnsView

@synthesize imagesArray, timeTransition, isLoop, isLandscape;
@synthesize animationInCurse, currentImage, delegate;

- (id)init {
    self = [super init];
    if (self) {
        self.layer.masksToBounds = YES;
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.layer.masksToBounds = YES;
    }
    return self;
}

- (void)stopAnimation {
    self.isLoop = NO;
}

- (void)animateWithImages:(NSMutableArray*)images transitionDuration:(NSTimeInterval)duration loop:(BOOL)shouldLoop isLandscape:(BOOL)inLandscape;{
    self.imagesArray      = images;
    self.timeTransition   = duration;
    self.isLoop           = shouldLoop;
    self.isLandscape      = inLandscape;
    self.animationInCurse = NO;
    
    self.layer.masksToBounds = YES;
    
    newEnlargeRatio = 1.0;
//    if (IS_IPAD) {
//        newEnlargeRatio = 1.0;
//    }
    
    [NSThread detachNewThreadSelector:@selector(_startAnimations:) toTarget:self withObject:images];
    
}

- (void)animateWithURLs:(NSArray*)urls transitionDuration:(NSTimeInterval)duration loop:(BOOL)shouldLoop isLandscape:(BOOL)inLandscape;{
    self.imagesArray      = [NSMutableArray new];
    self.timeTransition   = duration;
    self.isLoop           = shouldLoop;
    self.isLandscape      = inLandscape;
    self.animationInCurse = NO;
    
    NSInteger bufferSize = (imageBufer < urls.count) ? imageBufer : urls.count;
    
    // Fill the buffer.
    for (uint i = 0; i < bufferSize; i++) {
        NSString *url = [[NSString alloc] initWithString:urls[i]];
        [self.imagesArray addObject:[self _downloadImageFrom:url]];
    }
    
    self.layer.masksToBounds = YES;
    
    newEnlargeRatio = 1.2;
    if (IS_IPAD) {
        newEnlargeRatio = 2.2;
    }
    
    [NSThread detachNewThreadSelector:@selector(_startInternetAnimations:) toTarget:self withObject:urls];
    
}

- (void)_startAnimations:(NSArray*)images {
    for (uint i = 0; i < [images count]; i++) {
        
        [self performSelectorOnMainThread:@selector(_animate:)
                               withObject:@(i)
                            waitUntilDone:YES];
        
        sleep(self.timeTransition);
        
        i = (i == [images count] - 1) && isLoop ? -1 : i;
        
    }
}

- (UIImage*)_downloadImageFrom:(NSString*)url {
    UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:url]]];
    return image;
}

- (void)_startInternetAnimations:(NSArray*)urls {
    int bufferIndex = 0;
    
    for (NSInteger urlIndex = self.imagesArray.count; urlIndex < [urls count]; urlIndex++) {
        
        [self performSelectorOnMainThread:@selector(_animate:)
                               withObject:@(0)
                            waitUntilDone:YES];
        
        [self.imagesArray removeObjectAtIndex:0];
        [self.imagesArray addObject:[self _downloadImageFrom:urls[urlIndex]]];
        
        if (bufferIndex == self.imagesArray.count -1) {
            bufferIndex = -1;
        }
        
        bufferIndex++;
        urlIndex = (urlIndex == [urls count]-1) && isLoop ? -1 : urlIndex; 
        
        sleep(self.timeTransition);
    }
}

- (void)_animate:(NSNumber*)num {
    UIImage* image = self.imagesArray[[num intValue]];
    UIImageView *imageView;
    
    CGFloat resizeRatio   = -1;
    CGFloat widthDiff     = -1;
    CGFloat heightDiff    = -1;
    CGFloat originX       = -1;
    CGFloat originY       = -1;
    CGFloat zoomInX       = -1;
    CGFloat zoomInY       = -1;
    CGFloat moveX         = -1;
    CGFloat moveY         = -1;
    CGFloat frameWidth    = isLandscape ? self.frame.size.width : self.frame.size.height;
    CGFloat frameHeight   = isLandscape ? self.frame.size.height : self.frame.size.width;
    
    // Widder than screen 
    if (image.size.width > frameWidth) {
        widthDiff = image.size.width - frameWidth;
        
        // Higher than screen
//        if (image.size.height > frameHeight)
//        {
            heightDiff = image.size.height - frameHeight;
            
            if (widthDiff > heightDiff) {
                resizeRatio = frameHeight / image.size.height;
            }
            else {
                resizeRatio = frameWidth / image.size.width;
            }
            
            // No higher than screen
//        }
//        else
//        {
//
//            heightDiff = frameHeight - image.size.height;
//            
//            if (widthDiff > heightDiff) 
//                resizeRatio = frameWidth / image.size.width;
//            else
//                resizeRatio = self.bounds.size.height / image.size.height;
//        }
        
        // No widder than screen
    }
//    else
//    {
//        widthDiff = frameWidth - image.size.width;
//        
//        // Higher than screen
//        if (image.size.height > frameHeight)
//        {
//
//            heightDiff = image.size.height - frameHeight;
//            
//            if (widthDiff > heightDiff) 
//                resizeRatio = image.size.height / frameHeight;
//            else
//                resizeRatio = frameWidth / image.size.width;
//            
//            // No higher than screen
//        }
//        else
//        {
//
//            heightDiff = frameHeight - image.size.height;
//            
//            if (widthDiff > heightDiff) 
//                resizeRatio = frameWidth / image.size.width;
//            else
//                resizeRatio = frameHeight / image.size.height;
//        }
//    }
    
    // Resize the image.
    CGFloat optimusWidth  = (image.size.width * resizeRatio) * newEnlargeRatio;
    CGFloat optimusHeight = (image.size.height * resizeRatio) * newEnlargeRatio;
    imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, optimusWidth, optimusHeight)];
    
    // Calcule the maximum move allowed.
    CGFloat maxMoveX = optimusWidth - frameWidth;
    CGFloat maxMoveY = optimusHeight - frameHeight;
    
    CGFloat rotation = arc4random_uniform(9) / 100;
    
    switch (arc4random_uniform(4)) {
        case 0:
            originX = 0;
            originY = 0;
            zoomInX = 1.25;
            zoomInY = 1.25;
            moveX   = -maxMoveX;
            moveY   = -maxMoveY;
            break;
            
        case 1:
            originX = 0;
            originY = frameHeight - optimusHeight;
            zoomInX = 1.30;
            zoomInY = 1.30;
            moveX   = -maxMoveX;
            moveY   = maxMoveY;
            break;
            
            
        case 2:
            originX = frameWidth - optimusWidth;
            originY = 0;
            zoomInX = 1.50;
            zoomInY = 1.50;
            moveX   = maxMoveX;
            moveY   = -maxMoveY;
            break;
            
        case 3:
            originX = frameWidth - optimusWidth;
            originY = frameHeight - optimusHeight;
            zoomInX = 1.40;
            zoomInY = 1.40;
            moveX   = maxMoveX;
            moveY   = maxMoveY;
            break;
            
        default:
            break;
    }
    
    CALayer *picLayer    = [CALayer layer];
    picLayer.contents    = (id)image.CGImage;
    picLayer.anchorPoint = CGPointMake(0, 0); 
    picLayer.bounds      = CGRectMake(0, 0, optimusWidth, optimusHeight);
    picLayer.position    = CGPointMake(originX, originY);
    
    [imageView.layer addSublayer:picLayer];
    
    CATransition *animation = [CATransition animation];
    [animation setDuration:1];
    [animation setType:kCATransitionFade];
    [[self layer] addAnimation:animation forKey:nil];
    
    // Remove the previous view
    if ([[self subviews] count] > 0) {
        [[self subviews][0] removeFromSuperview];
    }
    
    [self addSubview:imageView];
    
    // Generates the animation
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:self.timeTransition+2];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
    CGAffineTransform rotate    = CGAffineTransformMakeRotation(rotation);
    CGAffineTransform moveRight = CGAffineTransformMakeTranslation(moveX, moveY);
    CGAffineTransform combo1    = CGAffineTransformConcat(rotate, moveRight);
    CGAffineTransform zoomIn    = CGAffineTransformMakeScale(zoomInX, zoomInY);
    CGAffineTransform transform = CGAffineTransformConcat(zoomIn, combo1);
    imageView.transform = transform;
    [UIView commitAnimations];
    
    [self performSelector:@selector(_notifyDelegate:) withObject:num afterDelay:self.timeTransition];
}

- (void)_notifyDelegate:(NSNumber*)imageIndex {
    if (delegate) {
        if ([self.delegate respondsToSelector:@selector(didShowImageAtIndex:)]) {
            [self.delegate didShowImageAtIndex:[imageIndex intValue]];
        }
        
        if ([imageIndex intValue] == ([self.imagesArray count]-1) && !isLoop && [self.delegate respondsToSelector:@selector(didFinishAllAnimations)]) {
            [self.delegate didFinishAllAnimations];
        } 
    }
}

@end

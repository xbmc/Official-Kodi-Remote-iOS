/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDWebImageDownloaderOperation.h"
#import "SDWebImageDecoder.h"
#import <ImageIO/ImageIO.h>
#import "UIImage+Resize.h"

@interface SDWebImageDownloaderOperation ()

@property (copy, nonatomic) SDWebImageDownloaderProgressBlock progressBlock;
@property (copy, nonatomic) SDWebImageDownloaderCompletedBlock completedBlock;
@property (copy, nonatomic) void (^cancelBlock)(void);

@property (assign, nonatomic, getter = isExecuting) BOOL _executing;
@property (assign, nonatomic, getter = isFinished) BOOL _finished;
@property (assign, nonatomic) long long expectedSize;
@property (strong, nonatomic) NSMutableData *imageData;
@property (strong, nonatomic) NSURLSessionDataTask *dataTask;
@property (strong, nonatomic) NSDictionary *userInfo;

@property (SDDispatchQueueSetterSementics, nonatomic) dispatch_queue_t queue;

@end

@implementation SDWebImageDownloaderOperation
{
    size_t width, height;
    BOOL responseFromCached;
}

- (id)initWithRequest:(NSURLRequest*)request queue:(dispatch_queue_t)queue options:(SDWebImageDownloaderOptions)options userInfo:(NSDictionary*)userInfo progress:(void (^)(NSUInteger, long long))progressBlock completed:(void (^)(UIImage *, NSData *, NSError *, BOOL))completedBlock cancelled:(void (^)(void))cancelBlock {
    if ((self = [super init])) {
        _queue = queue;
        _request = request;
        _options = options;
        _userInfo = userInfo;
        _progressBlock = [progressBlock copy];
        _completedBlock = [completedBlock copy];
        _cancelBlock = [cancelBlock copy];
        __executing = NO;
        __finished = NO;
        _expectedSize = 0;
        responseFromCached = YES; // Initially wrong until `connection:willCacheResponse:` is called or not called
    }
    return self;
}

- (void)start {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.isCancelled) {
            self.finished = YES;
            [self reset];
            return;
        }

        self.executing = YES;
        NSURLSession *session = [NSURLSession sharedSession];
        self.dataTask = [session dataTaskWithRequest:self.request
                completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                    if (response) {
                        [self didReceiveResponse:response];
                    }
                    if (data) {
                        [self didReceiveData:data];
                        [self connectionDidFinishLoading];
                    }
                    if (error) {
                        [self didFailWithError:error];
                    }
                }];
        [self.dataTask resume];

        if (self.dataTask) {
            if (self.progressBlock) {
                self.progressBlock(0, -1);
            }
            [[NSNotificationCenter defaultCenter] postNotificationName:SDWebImageDownloadStartNotification object:self];
        }
        else {
            if (self.completedBlock) {
                self.completedBlock(nil, nil, [NSError errorWithDomain:NSURLErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey: @"Connection can't be initialized"}], YES);
            }
        }
    });
}

- (void)cancel {
    if (self.isFinished) {
        return;
    }
    [super cancel];
    if (self.cancelBlock) {
        self.cancelBlock();
    }

    if (self.dataTask) {
        [self.dataTask cancel];
        [[NSNotificationCenter defaultCenter] postNotificationName:SDWebImageDownloadStopNotification object:self];

        // As we cancelled the connection, its callback won't be called and thus won't
        // maintain the isFinished and isExecuting flags.
        if (self.isExecuting) {
            self.executing = NO;
        }
        if (!self.isFinished) {
            self.finished = YES;
        }
    }

    [self reset];
}

- (void)done {
    self.finished = YES;
    self.executing = NO;
    [self reset];
}

- (void)reset {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.cancelBlock = nil;
        self.completedBlock = nil;
        self.progressBlock = nil;
        self.dataTask = nil;
        self.imageData = nil;
    });
}

- (void)setFinished:(BOOL)finished {
    [self willChangeValueForKey:@"isFinished"];
    __finished = finished;
    [self didChangeValueForKey:@"isFinished"];
}

- (void)setExecuting:(BOOL)executing {
    [self willChangeValueForKey:@"isExecuting"];
    __executing = executing;
    [self didChangeValueForKey:@"isExecuting"];
}

- (BOOL)isConcurrent {
    return YES;
}

#pragma mark - Response/Data handlers

- (void)didReceiveResponse:(NSURLResponse*)response {
    if (![response respondsToSelector:@selector(statusCode)] || [((NSHTTPURLResponse*)response) statusCode] < 400) {
        NSUInteger expected = response.expectedContentLength > 0 ? (NSUInteger)response.expectedContentLength : 0;
        self.expectedSize = expected;
        if (self.progressBlock) {
            self.progressBlock(0, expected);
        }

        dispatch_async(self.queue, ^{
            self.imageData = [NSMutableData.alloc initWithCapacity:expected];
        });
    }
    else {
        [self.dataTask cancel];

        [[NSNotificationCenter defaultCenter] postNotificationName:SDWebImageDownloadStopNotification object:nil];

        if (self.completedBlock) {
            self.completedBlock(nil, nil, [NSError errorWithDomain:NSURLErrorDomain code:[((NSHTTPURLResponse*)response) statusCode] userInfo:nil], YES);
        }

        [self done];
    }
}

- (void)didReceiveData:(NSData*)data {
    dispatch_async(self.queue, ^{
        [self.imageData appendData:data];
        
        if ((self.options & SDWebImageDownloaderProgressiveDownload) && self.expectedSize > 0 && self.completedBlock) {
            // The following code is from http://www.cocoaintheshell.com/2011/05/progressive-images-download-imageio/
            // Thanks to the author @Nyx0uf

            // Get the total bytes downloaded
            const NSUInteger totalSize = self.imageData.length;

            // Update the data source, we must pass ALL the data, not just the new bytes
            CGImageSourceRef imageSource = CGImageSourceCreateIncremental(NULL);
            CGImageSourceUpdateData(imageSource, (__bridge CFDataRef)self.imageData, totalSize == self.expectedSize);

            if (self->width + self->height == 0) {
                CFDictionaryRef properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, NULL);
                if (properties) {
                    CFTypeRef val = CFDictionaryGetValue(properties, kCGImagePropertyPixelHeight);
                    if (val) {
                        CFNumberGetValue(val, kCFNumberLongType, &self->height);
                    }
                    val = CFDictionaryGetValue(properties, kCGImagePropertyPixelWidth);
                    if (val) {
                        CFNumberGetValue(val, kCFNumberLongType, &self->width);
                    }
                    CFRelease(properties);
                }
            }

            if (self->width + self->height > 0 && totalSize < self.expectedSize) {
                // Create the image
                CGImageRef partialImageRef = CGImageSourceCreateImageAtIndex(imageSource, 0, NULL);

#ifdef TARGET_OS_IPHONE
                // Workaround for iOS anamorphic image
                if (partialImageRef) {
                    const size_t partialHeight = CGImageGetHeight(partialImageRef);
                    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
                    CGContextRef bmContext = CGBitmapContextCreate(NULL, self->width, self->height, 8, self->width * 4, colorSpace, kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedFirst);
                    CGColorSpaceRelease(colorSpace);
                    if (bmContext) {
                        CGContextDrawImage(bmContext, CGRectMake(0, 0, self->width, partialHeight), partialImageRef);
                        CGImageRelease(partialImageRef);
                        partialImageRef = CGBitmapContextCreateImage(bmContext);
                        CGContextRelease(bmContext);
                    }
                    else {
                        CGImageRelease(partialImageRef);
                        partialImageRef = nil;
                    }
                }
#endif

                if (partialImageRef) {
                    UIImage *image = [UIImage decodedImageWithImage:SDScaledImageForPath(self.request.URL.absoluteString, [UIImage imageWithCGImage:partialImageRef])];
                    CGImageRelease(partialImageRef);
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (self.completedBlock) {
                            self.completedBlock(image, nil, nil, NO);
                        }
                    });
                }
            }

            CFRelease(imageSource);
        }
        NSUInteger received = self.imageData.length;
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.progressBlock) {
                self.progressBlock(received, self.expectedSize);
            }
        });
    });
}

- (void)connectionDidFinishLoading {
    self.dataTask = nil;

    [[NSNotificationCenter defaultCenter] postNotificationName:SDWebImageDownloadStopNotification object:nil];

    SDWebImageDownloaderCompletedBlock completionBlock = self.completedBlock;

    if (completionBlock) {
        if (self.options & SDWebImageDownloaderIgnoreCachedResponse && responseFromCached) {
            completionBlock(nil, nil, nil, YES);
            self.completionBlock = nil;
            [self done];
        }
        else {
            dispatch_async(self.queue, ^{
//                CGSize size = CGSizeFromString([self.userInfo objectForKey:@"size"]);
                if ([[self.userInfo objectForKey:@"transformation"] isEqualToString:@"resize"]) {
                    CGSize size = CGSizeFromString([self.userInfo objectForKey:@"size"]);
                    UIImage *elab = [UIImage imageWithData:self.imageData];
                    NSData *elabData = UIImagePNGRepresentation([elab resizedImage:elab.CGImage size:size interpolationQuality:kCGInterpolationHigh]);
                    self.imageData = [NSMutableData dataWithData:elabData];
                }
                UIImage *image = [UIImage decodedImageWithImage:SDScaledImageForPath(self.request.URL.absoluteString, self.imageData) size:CGSizeZero interpolationQuality:kCGInterpolationHigh];
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (CGSizeEqualToSize(image.size, CGSizeZero)) {
                        completionBlock(nil, nil, [NSError errorWithDomain:@"SDWebImageErrorDomain" code:0 userInfo:@{NSLocalizedDescriptionKey: @"Downloaded image has 0 pixels"}], YES);
                    }
                    else {
                        completionBlock(image, self.imageData, nil, YES);
                    }
                    self.completionBlock = nil;
                    [self done];
                });
            });
        }
    }
    else {
        [self done];
    }
}

- (void)didFailWithError:(NSError*)error {
    [[NSNotificationCenter defaultCenter] postNotificationName:SDWebImageDownloadStopNotification object:nil];

    if (self.completedBlock) {
        self.completedBlock(nil, nil, error, YES);
    }

    [self done];
}

- (NSCachedURLResponse*)connection:(NSURLConnection*)connection willCacheResponse:(NSCachedURLResponse*)cachedResponse {
    responseFromCached = NO; // If this method is called, it means the response wasn't read from cache
    if (self.request.cachePolicy == NSURLRequestReloadIgnoringLocalCacheData) {
        // Prevents caching of responses
        return nil;
    }
    else {
        return cachedResponse;
    }
}


@end

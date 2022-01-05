/*
 * DSJSONRPC.m
 *
 * Demiurgic JSON-RPC
 * Created by Derek Bowen on 10/20/2011.
 * 
 * Copyright (c) 2011 Demiurgic Software, LLC
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 
 * Redistributions of source code must retain the above copyright notice,
 * this list of conditions and the following disclaimer.
 * 
 * Redistributions in binary form must reproduce the above copyright
 * notice, this list of conditions and the following disclaimer in the
 * documentation and/or other materials provided with the distribution.
 * 
 * Neither the name of the project's author nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 * NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 */

#import "DSJSONRPC.h"

#ifdef __OBJC_GC__
#error Demiurgic JSON-RPC does not support Objective-C Garbage Collection
#endif


@interface DSJSONRPC () // Private
@property (nonatomic, DS_STRONG) NSURL               *_serviceEndpoint;
@property (nonatomic, DS_STRONG) NSDictionary        *_httpHeaders;
@property (nonatomic, DS_STRONG) NSNumber            *request_id;
@property (nonatomic, DS_STRONG) NSString            *method;
@property (nonatomic, DS_STRONG) NSMutableData       *data;
@property (nonatomic, DS_STRONG) NSNumber            *expected;
@property (nonatomic, copy) DSJSONRPCCompletionHandler completionHandler;

@end

@implementation DSJSONRPC

@synthesize _serviceEndpoint, _httpHeaders;

- (id)initWithServiceEndpoint:(NSURL*)serviceEndpoint; {
    return [self initWithServiceEndpoint:serviceEndpoint andHTTPHeaders:nil];
}

- (id)initWithServiceEndpoint:(NSURL*)serviceEndpoint andHTTPHeaders:(NSDictionary*)httpHeaders {
    if (!(self = [super init])) {
        return self;
    }
    
    self._serviceEndpoint = serviceEndpoint;
    self._httpHeaders     = httpHeaders;
    
    return self;
}

- (void)dealloc {
    DS_RELEASE(_serviceEndpoint)
    DS_RELEASE(_httpHeaders)
    
    DS_SUPERDEALLOC()
}

#pragma mark - Web Service Invocation Methods

- (NSInteger)callMethod:(NSString*)methodName {
    return [self callMethod:methodName withParameters:nil];
}

- (NSInteger)callMethod:(NSString*)methodName withParameters:(id)methodParams {
    return [self callMethod:methodName withParameters:methodParams onCompletion:nil];
}


#pragma mark - Web Service Invocation Methods (Completion Handler Based)
- (NSInteger)callMethod:(NSString*)methodName onCompletion:(DSJSONRPCCompletionHandler)completionHandler {
    return [self callMethod:methodName withParameters:nil onCompletion:completionHandler];
}

- (NSInteger)callMethod:(NSString*)methodName withParameters:(id)methodParams onCompletion:(DSJSONRPCCompletionHandler)completionHandler {
    return [self callMethod:methodName withParameters:methodParams withTimeout:0 onCompletion:completionHandler];
}

// (int)timeout PARAMETER ADDED BY JOE

- (NSInteger)callMethod:(NSString*)methodName withParameters:(id)methodParams withTimeout:(NSTimeInterval)timeout onCompletion:(DSJSONRPCCompletionHandler)completionHandler {
    
    // Generate a random Id for the call
    NSInteger aId = arc4random();
    
    // Setup the JSON-RPC call payload
    NSArray *methodKeys = nil;
    NSArray *methodObjs = nil;
    if (methodParams) {
        methodKeys = @[@"jsonrpc", @"method", @"params", @"id"];
        methodObjs = @[@"2.0", methodName, methodParams, @(aId)];
    }
    else {
        methodKeys = @[@"jsonrpc", @"method", @"id"];
        methodObjs = @[@"2.0", methodName, @(aId)];
    }
    // Create call payload
    NSDictionary *methodCall = [NSDictionary dictionaryWithObjects:methodObjs forKeys:methodKeys];
    
    // Attempt to serialize the call payload to a JSON string
    NSError *error = nil;
    NSData *postData = [NSJSONSerialization dataWithJSONObject:methodCall options:kNilOptions error:&error];
//    NSLog(@"PARAMS: %@", methodParams);
    // TODO: Make this a parameter??
    if (error != nil) {
        if (completionHandler) {
            NSError *aError = [NSError errorWithDomain:@"it.joethefox.json-rpc" code:DSJSONRPCParseError userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[error localizedDescription], NSLocalizedDescriptionKey, nil]];
            
            // Pass the error to completion handler
            dispatch_async(dispatch_get_main_queue(), ^{
                completionHandler(methodName, aId, nil, nil, aError);
            });
        }
    }
    
    // Create the JSON-RPC request
    NSMutableURLRequest *serviceRequest = [NSMutableURLRequest requestWithURL:self._serviceEndpoint];
    [serviceRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [serviceRequest setValue:@"DSJSONRPC/1.0" forHTTPHeaderField:@"User-Agent"];
    // Add custom HTTP headers
    for (id key in self._httpHeaders) {
        [serviceRequest setValue:self._httpHeaders[key] forHTTPHeaderField:key];
    }
    
    // Finish creating request, we set content-length after user headers to prevent user error
    [serviceRequest setValue:[NSString stringWithFormat:@"%i", (int)postData.length] forHTTPHeaderField:@"Content-Length"];
    serviceRequest.HTTPMethod = @"POST";
    serviceRequest.HTTPBody = postData;
    serviceRequest.timeoutInterval = 3600;
    
    // Create dictionary to store information about the request so we can recall it later
    self.method = methodName;
    self.request_id = @(aId);
    if (completionHandler != nil) {
        DSJSONRPCCompletionHandler completionHandlerCopy = [completionHandler copy];
        self.completionHandler = completionHandlerCopy;
    }
    
    // Perform the JSON-RPC method call
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:serviceRequest
            completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                if (response) {
                    [self didReceiveResponse:response];
                }
                if (data) {
                    [self didReceiveData:data];
                }
                if (error) {
                    [self didFailWithError:error];
                }
            }];
    [dataTask resume];

    if (timeout) {
        timer = [NSTimer scheduledTimerWithTimeInterval:timeout 
                                                 target:self 
                                               selector:@selector(cancelRequest:) 
                                               userInfo:dataTask repeats:NO];
    }
    
    return aId;
}

- (void)cancelRequest:(NSTimer*)theTimer {
    NSURLSessionDataTask *dataTask = (NSURLSessionDataTask*)theTimer.userInfo;
    DSJSONRPCCompletionHandler completionHandler = self.completionHandler;
    NSError *aError = [NSError errorWithDomain:@"it.joethefox.json-rpc" code:DSJSONRPCNetworkError userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Connection Timeout", NSLocalizedDescriptionKey, nil]];
    // Pass the error to completion handler
    dispatch_async(dispatch_get_main_queue(), ^{
        if (completionHandler) {
            completionHandler(self.method, [self.request_id intValue], nil, nil, aError);
        }
    });
    [dataTask cancel];
    timer = nil;
}

#pragma mark - Runtime Method Invocation Handling

- (NSMethodSignature*)methodSignatureForSelector:(SEL)aSelector {
    // Determine if we handle the method signature
    // If not, create one so it goes to forwardInvocation
    NSMethodSignature *aMethodSignature;
    if (!(aMethodSignature = [super methodSignatureForSelector:aSelector])) {
        aMethodSignature = [NSMethodSignature signatureWithObjCTypes:"@:@@@"];
    }
    
    return aMethodSignature;
}

- (void)forwardInvocation:(NSInvocation*)anInvocation {
    // Get method name from invocation
    NSString *selectorName = NSStringFromSelector(anInvocation.selector);
    NSString *methodName = [selectorName componentsSeparatedByString:@":"][0];
    
    // Get reference to the first argument passed in
    id methodParams;
    [anInvocation getArgument:&methodParams atIndex:2];
    
    // If no parameters were given or its not a valid primative type, then pass in nil
    if (methodParams == nil || !([methodParams isKindOfClass:[NSArray class]] || [methodParams isKindOfClass:[NSDictionary class]] || [methodParams isKindOfClass:[NSString class]] || [methodParams isKindOfClass:[NSNumber class]])) {
        methodParams = nil;
    }
        
    // Rebuild the invocation request and invoke it
    [anInvocation setSelector:@selector(callMethod:withParameters:)];
    [anInvocation setArgument:&methodName atIndex:2];
    [anInvocation setArgument:&methodParams atIndex:3];
    [anInvocation invokeWithTarget:self];
}


#pragma mark - Response/Data handlers

- (void)willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge*)challenge {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"XBMCServerAuthenticationFailed" object:nil userInfo:nil];
}

- (void)didReceiveResponse:(NSURLResponse*)response {
    self.data = [NSMutableData data];
    self.expected = [[NSNumber alloc] initWithLongLong:response.expectedContentLength];
}

- (void)didReceiveData:(NSData*)data {
    NSMutableData *connectionData = self.data;
    [connectionData appendData:data];
    
    if (connectionData.length >= [self.expected longLongValue]) {
        [self connectionDidFinishLoading];
    }
}

- (void)didFailWithError:(NSError*)error {
    DSJSONRPCCompletionHandler completionHandler = self.completionHandler;
    
    if (completionHandler) {
        NSError *aError = [NSError errorWithDomain:@"it.joethefox.json-rpc" code:DSJSONRPCNetworkError userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[error localizedDescription], NSLocalizedDescriptionKey, nil]];
        
        // Pass the error to completion handler
        dispatch_async(dispatch_get_main_queue(), ^{
            completionHandler(self.method, [self.request_id intValue], nil, nil, aError);
        });
    }
    
    // Failed with error, kill timer.
    [timer invalidate];
    timer = nil;
}

- (void)connectionDidFinishLoading {
    // Get information about the connection
    NSMutableData *connectionData = self.data;
    DSJSONRPCCompletionHandler completionHandler = self.completionHandler;
    
    // Attempt to deserialize result
    NSError *error = nil;
    NSDictionary *jsonResult = [NSJSONSerialization JSONObjectWithData:connectionData options:kNilOptions error:&error];
    
    if (error && completionHandler) {
        NSError *aError = [NSError errorWithDomain:@"it.joethefox.json-rpc" code:DSJSONRPCParseError userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[error localizedDescription], NSLocalizedDescriptionKey, nil]];
        
        // Pass the error to completion handler
        dispatch_async(dispatch_get_main_queue(), ^{
            completionHandler(self.method, [self.request_id intValue], nil, nil, aError);
        });
    }
    
    // The JSON server passed back and error for the response
    if (!error && jsonResult[@"error"] != nil && [jsonResult[@"error"] isKindOfClass:[NSDictionary class]]) {
        if (completionHandler) {
            DSJSONRPCError *jsonRPCError = [DSJSONRPCError errorWithData:jsonResult[@"error"]];
            
            // Pass the error to completion handler
            dispatch_async(dispatch_get_main_queue(), ^{
                completionHandler(self.method, [self.request_id intValue], nil, jsonRPCError, nil);
            });
        }
    }
    // Not error, give delegate the method result
    else if (!error && completionHandler) {
        // Pass the result to completion handler
        dispatch_async(dispatch_get_main_queue(), ^{
            completionHandler(self.method, [self.request_id intValue], jsonResult[@"result"], nil, nil);
        });
    }
    
    // Did finish loading, kill timer.
    [timer invalidate];
    timer = nil;
}

@end

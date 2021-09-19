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
@property (nonatomic, DS_STRONG) NSMutableDictionary *_activeConnections;
@end

@implementation DSJSONRPC

@synthesize delegate;
@synthesize _serviceEndpoint, _httpHeaders, _activeConnections;

- (id)initWithServiceEndpoint:(NSURL*)serviceEndpoint; {
    return [self initWithServiceEndpoint:serviceEndpoint andHTTPHeaders:nil];
}

- (id)initWithServiceEndpoint:(NSURL*)serviceEndpoint andHTTPHeaders:(NSDictionary*)httpHeaders {
    if (!(self = [super init])) {
        return self;
    }
    
    self._serviceEndpoint = serviceEndpoint;
    self._httpHeaders     = httpHeaders;
    
    // Create dictionary to hold active conenctions
    self._activeConnections = [NSMutableDictionary dictionary];
    
    return self;
}

- (void)dealloc {
    DS_RELEASE(_serviceEndpoint)
    DS_RELEASE(_httpHeaders)
    DS_RELEASE(_activeConnections)
    
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
        if (completionHandler || delegate) {
            NSError *aError = [NSError errorWithDomain:@"it.joethefox.json-rpc" code:DSJSONRPCParseError userInfo:@{NSLocalizedDescriptionKey: [error localizedDescription]}];
            
            if (completionHandler) {
                completionHandler(methodName, aId, nil, nil, aError);
                DS_RELEASE(completionHandler);
            }
            else if ([delegate respondsToSelector:@selector(jsonRPC:didFailMethod:forId:withError:)]) {
                [delegate jsonRPC:self didFailMethod:methodName forId:aId withError:aError];
            }
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
    [serviceRequest setHTTPMethod:@"POST"];
    [serviceRequest setHTTPBody:postData];
    [serviceRequest setTimeoutInterval:3600];
    
    // Create dictionary to store information about the request so we can recall it later
    NSMutableDictionary *connectionInfo = [NSMutableDictionary dictionaryWithCapacity:3];
    connectionInfo[@"method"] = methodName;
    connectionInfo[@"id"] = @(aId);
    if (completionHandler != nil) {
        DSJSONRPCCompletionHandler completionHandlerCopy = [completionHandler copy];
        connectionInfo[@"completionHandler"] = completionHandlerCopy;
    }
    
    // Perform the JSON-RPC method call
    NSURLConnection *aConnection = [[NSURLConnection alloc] initWithRequest:serviceRequest delegate:self];
    self._activeConnections[[NSValue valueWithNonretainedObject:aConnection]] = connectionInfo;
    
    if (timeout) {
        timer = [NSTimer scheduledTimerWithTimeInterval:timeout 
                                                 target:self 
                                               selector:@selector(cancelRequest:) 
                                               userInfo:aConnection repeats:NO];
    }
    return aId;
}

- (void)cancelRequest:(NSTimer*)theTimer {
    NSURLConnection *connection = (NSURLConnection*)[theTimer userInfo];
    __auto_type connectionKey = [NSValue valueWithNonretainedObject:connection];
    NSMutableDictionary *connectionInfo = self._activeConnections[connectionKey];
    DSJSONRPCCompletionHandler completionHandler = connectionInfo[@"completionHandler"];
    NSError *aError = [NSError errorWithDomain:@"it.joethefox.json-rpc" code:DSJSONRPCNetworkError userInfo:@{NSLocalizedDescriptionKey: @"Connection Timeout"}];
    if (completionHandler) {
        completionHandler(connectionInfo[@"method"], [connectionInfo[@"id"] intValue], nil, nil, aError);
        DS_RELEASE(completionHandler)
    }
    if (delegate && [delegate respondsToSelector:@selector(jsonRPC:didFailMethod:forId:withError:)]) {
        [delegate jsonRPC:self didFailMethod:connectionInfo[@"method"] forId:[connectionInfo[@"id"] intValue] withError:aError];
    }
    [(NSURLConnection*)[theTimer userInfo] cancel];
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


#pragma mark - NSURLConnection Delegate Methods

- (void)connection:(NSURLConnection*)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge*)challenge {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"XBMCServerAuthenticationFailed" object:nil userInfo:nil];
}

- (void)connection:(NSURLConnection*)connection didReceiveResponse:(NSURLResponse*)response {
    NSMutableDictionary *connectionInfo = self._activeConnections[[NSValue valueWithNonretainedObject:connection]];
    connectionInfo[@"data"] = [NSMutableData data];
}

- (void)connection:(NSURLConnection*)connection didReceiveData:(NSData*)data {
    NSMutableDictionary *connectionInfo = self._activeConnections[[NSValue valueWithNonretainedObject:connection]];
    NSMutableData *connectionData = connectionInfo[@"data"];
    [connectionData appendData:data];
}

- (void)connection:(NSURLConnection*)connection didFailWithError:(NSError*)error {
    __auto_type connectionKey = [NSValue valueWithNonretainedObject:connection];
    NSMutableDictionary *connectionInfo = self._activeConnections[connectionKey];
    DSJSONRPCCompletionHandler completionHandler = connectionInfo[@"completionHandler"];
    
    if (completionHandler || delegate) {
        NSError *aError = [NSError errorWithDomain:@"it.joethefox.json-rpc" code:DSJSONRPCNetworkError userInfo:@{NSLocalizedDescriptionKey: [error localizedDescription]}];
        
        if (completionHandler) {
            completionHandler(connectionInfo[@"method"], [connectionInfo[@"id"] intValue], nil, nil, aError);
            DS_RELEASE(completionHandler)
        }
        else if ([delegate respondsToSelector:@selector(jsonRPC:didFailMethod:forId:withError:)]) {
            [delegate jsonRPC:self didFailMethod:connectionInfo[@"method"] forId:[connectionInfo[@"id"] intValue] withError:aError];
        }
    }
    
    [self._activeConnections removeObjectForKey:connectionKey];
    DS_RELEASE(connection)
}

- (void)connectionDidFinishLoading:(NSURLConnection*)connection {
    // Get information about the connection
    __auto_type connectionKey = [NSValue valueWithNonretainedObject:connection];
    NSMutableDictionary *connectionInfo = self._activeConnections[connectionKey];
    NSMutableData *connectionData = connectionInfo[@"data"];
    DSJSONRPCCompletionHandler completionHandler = connectionInfo[@"completionHandler"];
    
    // Attempt to deserialize result
    NSError *error = nil;
    NSDictionary *jsonResult = [NSJSONSerialization JSONObjectWithData:connectionData options:kNilOptions error:&error];
    
    if (error) {
        NSError *aError = [NSError errorWithDomain:@"it.joethefox.json-rpc" code:DSJSONRPCParseError userInfo:@{NSLocalizedDescriptionKey: [error localizedDescription]}];
        
        if (completionHandler || delegate) {
            // Pass the error to the delegate if they care, completion handler takes presidence
            if (completionHandler) {
                completionHandler(connectionInfo[@"method"], [connectionInfo[@"id"] intValue], nil, nil, aError);
                DS_RELEASE(completionHandler)
            }
            if (delegate && [delegate respondsToSelector:@selector(jsonRPC:didFailMethod:forId:withError:)]) {
                [delegate jsonRPC:self didFailMethod:connectionInfo[@"method"] forId:[connectionInfo[@"id"] intValue] withError:aError];
            }
        }
    }
    
    // The JSON server passed back and error for the response
    if (!error && jsonResult[@"error"] != nil && [jsonResult[@"error"] isKindOfClass:[NSDictionary class]]) {
        if (completionHandler || delegate) {
            DSJSONRPCError *jsonRPCError = [DSJSONRPCError errorWithData:jsonResult[@"error"]];
            
            // Give the error to the delegate if they care, completion handler takes presidence
            if (completionHandler) {
                completionHandler(connectionInfo[@"method"], [connectionInfo [@"id"] intValue], nil, jsonRPCError, nil);
                DS_RELEASE(completionHandler)
            }
            else if (delegate && [delegate respondsToSelector:@selector(jsonRPC:didFinishMethod:forId:withError:)]) {
                [delegate jsonRPC:self didFinishMethod:connectionInfo[@"method"] forId:[connectionInfo[@"id"] intValue] withError:jsonRPCError];
            }
        }
    }
    // Not error, give delegate the method result
    else if (!error && (completionHandler || delegate)) {
        if (completionHandler) {
            completionHandler(connectionInfo[@"method"], [connectionInfo[@"id"] intValue], jsonResult[@"result"], nil, nil);
            DS_RELEASE(completionHandler)
        }
        else if ([delegate respondsToSelector:@selector(jsonRPC:didFinishMethod:forId:withResult:)]) {
            [delegate jsonRPC:self didFinishMethod:connectionInfo [@"method"] forId:[connectionInfo[@"id"] intValue] withResult:jsonResult[@"result"]];
        }
    }
    
    // Remove the connection from active connections
    [self._activeConnections removeObjectForKey:connectionKey];
    DS_RELEASE(connection)
}

@end

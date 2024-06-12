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
#import "AppDelegate.h"

#define RPC_DOMAIN @"it.joethefox.json-rpc"

@interface DSJSONRPC () // Private
@property (nonatomic, copy) NSURL *serviceEndpoint;
@property (nonatomic, copy) NSDictionary *httpHeaders;
@property (nonatomic, strong) NSURLSession *rpcSession;
@property (nonatomic, strong) NSMutableDictionary *activeDataTasks;
@end

@implementation DSJSONRPC

- (id)initWithServiceEndpoint:(NSURL*)serviceEndpoint; {
    return [self initWithServiceEndpoint:serviceEndpoint andHTTPHeaders:nil];
}

- (id)initWithServiceEndpoint:(NSURL*)serviceEndpoint andHTTPHeaders:(NSDictionary*)httpHeaders {
    if (!(self = [super init])) {
        return self;
    }
    
    self.serviceEndpoint = serviceEndpoint;
    self.httpHeaders     = httpHeaders;
    self.activeDataTasks = [NSMutableDictionary new];
    self.rpcSession      = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]
                                                         delegate:self
                                                    delegateQueue:[NSOperationQueue mainQueue]];
    
    return self;
}

- (void)dealloc {
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

- (NSInteger)callMethod:(NSString*)methodName withParameters:(id)methodParams withTimeout:(NSTimeInterval)timeout onCompletion:(DSJSONRPCCompletionHandler)completionHandler {
    
    // Generate a random Id for the call
    NSInteger aID = arc4random();
    
    // For actions without timeout we expect server to be connected already. Only the server heartbeat check uses timeout.
    if (!timeout && !AppDelegate.instance.serverOnLine) {
        if (completionHandler) {
            NSError *aError = [NSError errorWithDomain:RPC_DOMAIN code:DSJSONRPCParseError userInfo:@{NSLocalizedDescriptionKey: LOCALIZED_STR(@"No connection")}];
            NSDictionary *jsonErrorDict = @{
                @"code": @(JSONRPCNoConnection),
                @"message": LOCALIZED_STR(@"No connection"),
            };
            DSJSONRPCError *jsonRPCError = [DSJSONRPCError errorWithData:jsonErrorDict];
            completionHandler(methodName, aID, nil, jsonRPCError, aError);
        }
        return aID;
    }
    
    // Setup the JSON-RPC call payload
    NSArray *methodKeys = nil;
    NSArray *methodObjs = nil;
    if (methodParams) {
        methodKeys = @[@"jsonrpc", @"method", @"params", @"id"];
        methodObjs = @[@"2.0", methodName, methodParams, @(aID)];
    }
    else {
        methodKeys = @[@"jsonrpc", @"method", @"id"];
        methodObjs = @[@"2.0", methodName, @(aID)];
    }
    // Create call payload
    NSDictionary *methodCall = [NSDictionary dictionaryWithObjects:methodObjs forKeys:methodKeys];
    
    // Attempt to serialize the call payload to a JSON string
    NSError *error = nil;
    NSData *postData = [NSJSONSerialization dataWithJSONObject:methodCall options:kNilOptions error:&error];
    // TODO: Make this a parameter??
    if (error != nil) {
        if (completionHandler) {
            NSError *aError = [NSError errorWithDomain:RPC_DOMAIN code:DSJSONRPCParseError userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[error localizedDescription], NSLocalizedDescriptionKey, nil]];
            completionHandler(methodName, aID, nil, nil, aError);
        }
        return aID;
    }
    
    // Create the JSON-RPC request
    if (!self.serviceEndpoint) {
        if (completionHandler) {
            NSError *aError = [NSError errorWithDomain:RPC_DOMAIN code:DSJSONRPCNetworkError userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[error localizedDescription], NSLocalizedDescriptionKey, nil]];
            completionHandler(methodName, aID, nil, nil, aError);
        }
        return aID;
    }
    NSMutableURLRequest *serviceRequest = [NSMutableURLRequest requestWithURL:self.serviceEndpoint];
    [serviceRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [serviceRequest setValue:@"DSJSONRPC/1.0" forHTTPHeaderField:@"User-Agent"];
    // Add custom HTTP headers
    for (id key in self.httpHeaders) {
        [serviceRequest setValue:self.httpHeaders[key] forHTTPHeaderField:key];
    }
    
    // Finish creating request, we set content-length after user headers to prevent user error
    [serviceRequest setValue:[NSString stringWithFormat:@"%i", (int)postData.length] forHTTPHeaderField:@"Content-Length"];
    serviceRequest.HTTPMethod = @"POST";
    serviceRequest.HTTPBody = postData;
    serviceRequest.timeoutInterval = (timeout > 0) ? timeout : 3600;
    
    // Perform the JSON-RPC method call
    NSURLSessionDataTask *rpcDataTask = [self.rpcSession dataTaskWithRequest:serviceRequest];
    [rpcDataTask resume];
    
    // Set properties for current data task
    NSMutableDictionary *dataTaskProp = [NSMutableDictionary new];
    dataTaskProp[@"requestID"] = @(aID);
    dataTaskProp[@"methodName"] = methodName;
    if (completionHandler) {
        dataTaskProp[@"callback"] = [completionHandler copy];
    }
    self.activeDataTasks[rpcDataTask] = dataTaskProp;
    
    return aID;
}

#pragma mark NSURLSession (delegate)

- (void)URLSession:(NSURLSession*)session task:(NSURLSessionTask*)task didCompleteWithError:(NSError*)error {
    // Restore variables from activeConnection
    NSDictionary *dataTaskProp = self.activeDataTasks[task];
    DSJSONRPCCompletionHandler completionHandler = dataTaskProp[@"callback"];
    NSString *methodName = dataTaskProp[@"methodName"];
    NSData *data = dataTaskProp[@"dataBuffer"];
    long aID = [dataTaskProp[@"requestID"] longValue];
    
    // No error, process the received data
    if (error == nil) {
        // Attempt to deserialize result
        NSError *jsonError = nil;
        NSDictionary *jsonResult = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&jsonError];
        
        // JSON parsing error
        if (jsonError) {
            // Pass the error to completion handler
            if (completionHandler) {
                NSError *aError = [NSError errorWithDomain:RPC_DOMAIN code:DSJSONRPCParseError userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[jsonError localizedDescription], NSLocalizedDescriptionKey, nil]];
                completionHandler(methodName, aID, nil, nil, aError);
            }
        }
        // Deserialized object is not a dictionary
        else if (![jsonResult isKindOfClass:[NSDictionary class]]) {
            // Pass the error to completion handler
            if (completionHandler) {
                NSError *aError = [NSError errorWithDomain:RPC_DOMAIN code:DSJSONRPCParseError userInfo:@{NSLocalizedDescriptionKey: LOCALIZED_STR(@"Received unexpected JSON object.")}];
                NSDictionary *jsonErrorDict = @{
                    @"code": @(JSONRPCInvalidObject),
                    @"message": LOCALIZED_STR(@"Received unexpected JSON object."),
                    @"data": [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding],
                };
                DSJSONRPCError *jsonRPCError = [DSJSONRPCError errorWithData:jsonErrorDict];
                completionHandler(methodName, aID, nil, jsonRPCError, aError);
            }
        }
        // The JSON server passed back an error for the response
        else if (!jsonError && jsonResult[@"error"] != nil && [jsonResult[@"error"] isKindOfClass:[NSDictionary class]]) {
            // Pass the error to completion handler
            if (completionHandler) {
                DSJSONRPCError *jsonRPCError = [DSJSONRPCError errorWithData:jsonResult[@"error"]];
                completionHandler(methodName, aID, nil, jsonRPCError, nil);
            }
        }
        // No error
        else if (!jsonError) {
            // Pass the method result to completion handler
            if (completionHandler) {
                completionHandler(methodName, aID, jsonResult[@"result"], nil, nil);
            }
        }
    }
    // Connection error
    else {
        // Pass the error to completion handler
        if (completionHandler) {
            NSError *aError = [NSError errorWithDomain:RPC_DOMAIN code:DSJSONRPCNetworkError userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[error localizedDescription], NSLocalizedDescriptionKey, nil]];
            completionHandler(methodName, aID, nil, nil, aError);
        }
    }
    // Clean up finished request
    [self.activeDataTasks removeObjectForKey:task];
}

- (void)URLSession:(NSURLSession*)session dataTask:(NSURLSessionDataTask*)dataTask didReceiveData:(NSData*)data {
    // Append data to existing buffer
    [self.activeDataTasks[dataTask][@"dataBuffer"] appendData:data];
}

- (void)URLSession:(NSURLSession*)session dataTask:(NSURLSessionDataTask*)dataTask didReceiveResponse:(NSURLResponse*)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
    // Connections established, create buffer
    self.activeDataTasks[dataTask][@"dataBuffer"] = [NSMutableData new];
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession*)session task:(NSURLSessionTask*)task didReceiveChallenge:(NSURLAuthenticationChallenge*)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential*))completionHandler {
    // Notify user that authentication failed
    [[NSNotificationCenter defaultCenter] postNotificationName:@"XBMCServerAuthenticationFailed" object:nil userInfo:nil];
    completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
}

@end

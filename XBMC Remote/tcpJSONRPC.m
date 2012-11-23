//
//  tcpJSONRPC.m
//  XBMC Remote
//
//  Created by Giovanni Messina on 22/11/12.
//  Copyright (c) 2012 joethefox inc. All rights reserved.
//

#import "tcpJSONRPC.h"

NSInputStream	*inStream;
NSOutputStream	*outStream;
CFReadStreamRef readStream;
//	CFWriteStreamRef writeStream;

@implementation tcpJSONRPC

- (void) startNetworkCommunicationWithServer:(NSString *)server serverPort:(int)port{
    if (port == 0){
        port = 9090;
    }
	CFStreamCreatePairWithSocketToHost(NULL, (__bridge CFStringRef)server, port, &readStream, NULL);
	inStream = (__bridge NSInputStream *)readStream;
//	outStream = (__bridge NSOutputStream *)writeStream;
	[inStream setDelegate:self];
//	[outStream setDelegate:self];
	[inStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
//	[outStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[inStream open];
//	[outStream open];
}

-(void) stopNetworkCommunication{
    if (inStream != nil){
        [inStream close];
        [inStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [inStream setDelegate:nil];
        inStream = nil;
    }
    if (readStream != nil){
        CFReadStreamUnscheduleFromRunLoop(readStream, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
        CFReadStreamClose(readStream);
        CFRelease(readStream);
    }
//    if (outStream != nil){
//        [outStream close];
//        [outStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
////        outStream = nil;
//    }
}

- (void)stream:(NSStream *)theStream handleEvent:(NSStreamEvent)streamEvent {
    NSLog(@"stream event %i", streamEvent);
	switch (streamEvent) {
			
		case NSStreamEventOpenCompleted:
			break;
            
		case NSStreamEventHasBytesAvailable:
			if (theStream == inStream) {
				uint8_t buffer[1024];
				int len;
				while ([inStream hasBytesAvailable]) {
					len = [inStream read:buffer maxLength:sizeof(buffer)];
					if (len > 0) {
						NSData *output = [[NSData alloc] initWithBytes:buffer length:len];
						if (nil != output) {
                            NSError *parseError = nil;
                            NSDictionary *notification = [NSJSONSerialization JSONObjectWithData:output options:kNilOptions error:&parseError];
                            if (parseError == nil){
                                NSString *method = @"";
                                NSString *params = @"";
                                NSDictionary *paramsDict;
                                if (((NSNull *)[notification objectForKey:@"method"] != [NSNull null])){
                                        method = [notification objectForKey:@"method"];
                                    if (((NSNull *)[notification objectForKey:@"params"] != [NSNull null])){
                                        params = [notification objectForKey:@"params"];
                                        paramsDict = [NSDictionary dictionaryWithObject:[notification objectForKey:@"params"] forKey:@"params"];
                                    }
                                    [[NSNotificationCenter defaultCenter] postNotificationName:method object:nil userInfo:paramsDict];
                                }
                            }
                            else{
                                NSLog(@"ERROR %@", parseError);
                            }
						}
					}
				}
			}
			break;
            
		case NSStreamEventErrorOccurred:
            //			NSLog(@"Can not connect to the host!");
			break;
			
		case NSStreamEventEndEncountered:
            [theStream close];
            [theStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
            [theStream setDelegate:nil];
            theStream = nil;
            break;
		default:
            //			NSLog(@"Unknown event");
            break;
	}    
}

//- (void)dealloc{
//    inStream = nil;
////    outStream = nil;
//}

@end

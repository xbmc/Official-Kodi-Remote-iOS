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
//	CFWriteStreamRef writeStream;

@implementation tcpJSONRPC

- (void)startNetworkCommunicationWithServer:(NSString *)server serverPort:(int)port{
    if (port == 0){
        port = 9090;
    }
    CFReadStreamRef readStream;
	CFStreamCreatePairWithSocketToHost(NULL, (CFStringRef)CFBridgingRetain(server), port, &readStream, NULL);
	inStream = (NSInputStream *)CFBridgingRelease(readStream);
//	outStream = (__bridge NSOutputStream *)writeStream;
	[inStream setDelegate:self];
//	[outStream setDelegate:self];
	[inStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
//	[outStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[inStream open];
//	[outStream open];
}

-(NSStreamStatus)currentSocketInStatus{
    return [inStream streamStatus];
}

-(void)stopNetworkCommunication{
    NSStreamStatus current_status =[inStream streamStatus];
    if (current_status == NSStreamStatusOpen){
        [inStream close];
        [inStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [inStream setDelegate:nil];
        inStream = nil;
    }
}

- (void)stream:(NSStream *)theStream handleEvent:(NSStreamEvent)streamEvent {
//    NSLog(@"event %i", streamEvent);
	switch (streamEvent) {
			
		case NSStreamEventOpenCompleted:
            [[NSNotificationCenter defaultCenter] postNotificationName:@"tcpJSONRPCConnectionOpened" object:nil userInfo:nil];
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
//                            else{
//                                NSLog(@"ERROR %@", parseError);
//                            }
						}
					}
				}
			}
			break;
            
		case NSStreamEventErrorOccurred:
            [[NSNotificationCenter defaultCenter] postNotificationName:@"tcpJSONRPCConnectionError" object:nil userInfo:nil];
//             NSLog(@"Can't connect"); // 8
			break;
			
		case NSStreamEventEndEncountered:
            [theStream close];
            [theStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
            [theStream setDelegate:nil];
            theStream = nil;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"tcpJSONRPCConnectionClosed" object:nil userInfo:nil];

            break;
		default:
            break;
	}    
}

//- (void)dealloc{
//    inStream = nil;
////    outStream = nil;
//}

@end

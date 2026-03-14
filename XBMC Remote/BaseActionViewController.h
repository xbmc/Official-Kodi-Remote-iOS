//
//  BaseActionViewController.h
//  Kodi Remote
//
//  Created by Buschmann on 25.12.24.
//  Copyright © 2024 Team Kodi. All rights reserved.
//

#import "DSJSONRPC.h"

@import UIKit;
@import SafariServices;

@interface BaseActionViewController : UIViewController <SFSafariViewControllerDelegate> {
    NSDateFormatter *xbmcDateFormatter;
}

- (void)showRemote;
- (void)showNowPlaying;
- (void)simpleAction:(NSString*)action params:(NSDictionary*)params success:(NSString*)successMessage failure:(NSString*)failureMessage;
- (void)simpleAction:(NSString*)action params:(NSDictionary*)params completion:(DSJSONRPCCompletionHandler)handler;
- (void)simpleAction:(NSString*)action params:(NSDictionary*)params;
- (void)playerAction:(NSString*)action params:(NSDictionary*)params playerid:(int)playerid;
- (void)playerAction:(NSString*)action params:(NSDictionary*)params;
- (void)playerOpen:(NSDictionary*)params indicator:(UIActivityIndicatorView*)cellActivityIndicator;
- (void)playlistAdd:(NSDictionary*)params indicator:(UIActivityIndicatorView*)cellActivityIndicator;
- (void)playlistInsert:(NSDictionary*)params indicator:(UIActivityIndicatorView*)cellActivityIndicator;
- (void)playlistQueue:(int)playlistid items:(NSDictionary*)playlistItems afterCurrent:(BOOL)afterCurrent indicator:(UIActivityIndicatorView*)cellActivityIndicator;
- (void)startPlaybackItems:(NSDictionary*)playlistItems using:(NSString*)playername shuffle:(BOOL)shuffled resume:(BOOL)resume indicator:(UIActivityIndicatorView*)cellActivityIndicator;
- (void)SFloadURL:(NSString*)url;
- (void)recordChannel:(NSDictionary*)item indicator:(UIActivityIndicatorView*)cellActivityIndicator onSuccess:(void (^)(void))onSuccess;

@property (strong, nonatomic) id detailItem;

@end

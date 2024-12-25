//
//  BaseActionViewController.m
//  Kodi Remote
//
//  Created by Buschmann on 25.12.24.
//  Copyright © 2024 Team Kodi. All rights reserved.
//

#import "BaseActionViewController.h"
#import "AppDelegate.h"
#import "Utilities.h"
#import "RemoteController.h"
#import "NowPlaying.h"

@implementation BaseActionViewController

- (void)showRemote {
    RemoteController *remote = [[RemoteController alloc] initWithNibName:@"RemoteController" bundle:nil];
    [self.navigationController pushViewController:remote animated:YES];
}

- (void)showNowPlaying {
    NowPlaying *nowPlaying = [[NowPlaying alloc] initWithNibName:@"NowPlaying" bundle:nil];
    nowPlaying.detailItem = self.detailItem;
    [self.navigationController pushViewController:nowPlaying animated:YES];
}

- (void)simpleAction:(NSString*)action params:(NSDictionary*)params success:(NSString*)successMessage failure:(NSString*)failureMessage {
    [[Utilities getJsonRPC] callMethod:action withParameters:params onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *error) {
        if (error == nil && methodError == nil) {
            [Utilities showMessage:successMessage color:SUCCESS_MESSAGE_COLOR];
        }
        else {
            [Utilities showMessage:failureMessage color:ERROR_MESSAGE_COLOR];
        }
    }];
}

- (void)simpleAction:(NSString*)action params:(NSDictionary*)params completion:(DSJSONRPCCompletionHandler)handler {
    [[Utilities getJsonRPC] callMethod:action withParameters:params onCompletion:handler];
}

- (void)simpleAction:(NSString*)action params:(NSDictionary*)params {
    [[Utilities getJsonRPC] callMethod:action withParameters:params];
}

- (void)playerAction:(NSString*)action params:(NSDictionary*)params playerid:(int)playerid {
    NSMutableDictionary *mutableParams = [NSMutableDictionary dictionaryWithDictionary:params];
    mutableParams[@"playerid"] = @(playerid);
    [[Utilities getJsonRPC] callMethod:action withParameters:mutableParams onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *error) {
    }];
}

- (void)playerAction:(NSString*)action params:(NSDictionary*)params {
    [[Utilities getJsonRPC] callMethod:@"Player.GetActivePlayers" withParameters:@{} onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *error) {
        if (error == nil && methodError == nil && [methodResult isKindOfClass:[NSArray class]]) {
            if ([methodResult count] > 0) {
                int playerID = [Utilities getActivePlayerID:methodResult];
                [self playerAction:action params:params playerid:playerID];
            }
        }
    }];
}

- (void)playerOpen:(NSDictionary*)params indicator:(UIActivityIndicatorView*)cellActivityIndicator {
    [cellActivityIndicator startAnimating];
    [[Utilities getJsonRPC] callMethod:@"Player.Open" withParameters:params onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *error) {
        [cellActivityIndicator stopAnimating];
        if (error == nil && methodError == nil) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"XBMCPlaylistHasChanged" object:nil];
            [self showNowPlaying];
            [Utilities checkForReviewRequest];
        }
    }];
}

- (void)playlistAdd:(NSDictionary*)params indicator:(UIActivityIndicatorView*)cellActivityIndicator {
    [[Utilities getJsonRPC] callMethod:@"Playlist.Add" withParameters:params onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *error) {
        [cellActivityIndicator stopAnimating];
        if (error == nil && methodError == nil) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"XBMCPlaylistHasChanged" object:nil];
        }
    }];
}

- (void)playlistInsert:(NSDictionary*)params indicator:(UIActivityIndicatorView*)cellActivityIndicator {
    [[Utilities getJsonRPC] callMethod:@"Playlist.Insert" withParameters:params onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *error) {
        [cellActivityIndicator stopAnimating];
        if (error == nil && methodError == nil) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"XBMCPlaylistHasChanged" object:nil];
        }
    }];
}

- (void)playlistQueue:(int)playlistid items:(NSDictionary*)playlistItems afterCurrent:(BOOL)afterCurrent indicator:(UIActivityIndicatorView*)cellActivityIndicator {
    [cellActivityIndicator startAnimating];
    NSDictionary *playlistParams = @{
        @"playlistid": @(playlistid),
        @"item": playlistItems,
    };
    if (afterCurrent) {
        NSDictionary *params = @{
            @"playerid": @(playlistid),
            @"properties": @[@"percentage", @"time", @"totaltime", @"partymode", @"position"],
        };
        [[Utilities getJsonRPC]
         callMethod:@"Player.GetProperties"
         withParameters:params
         onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *error) {
            if (error == nil && methodError == nil) {
                if ([methodResult isKindOfClass:[NSDictionary class]]) {
                    if ([methodResult count]) {
                        int newPos = [methodResult[@"position"] intValue] + 1;
                        NSDictionary *params2 = @{
                            @"playlistid": @(playlistid),
                            @"item": playlistItems,
                            @"position": @(newPos),
                        };
                        [self playlistInsert:params2 indicator:cellActivityIndicator];
                    }
                    else {
                        [self playlistAdd:playlistParams indicator:cellActivityIndicator];
                    }
                }
                else {
                    [self playlistAdd:playlistParams indicator:cellActivityIndicator];
                }
            }
            else {
                [self playlistAdd:playlistParams indicator:cellActivityIndicator];
            }
        }];
    }
    else {
        [self playlistAdd:playlistParams indicator:cellActivityIndicator];
    }
}

- (void)startPlaybackItems:(NSDictionary*)playbackItems using:(NSString*)playername shuffle:(BOOL)shuffled resume:(BOOL)resume indicator:(UIActivityIndicatorView*)cellActivityIndicator {
    [cellActivityIndicator startAnimating];
    id optionsKey;
    id optionsValue;
    if (AppDelegate.instance.serverVersion > 11) {
        optionsKey = @"options";
        optionsValue = [NSDictionary dictionaryWithObjectsAndKeys:
                        @(resume), @"resume",
                        @(shuffled), @"shuffled",
                        playername, @"playername",
                        nil];
    }
    NSDictionary *playbackParams = [NSDictionary dictionaryWithObjectsAndKeys:
                                    playbackItems, @"item",
                                    optionsValue, optionsKey,
                                    nil];
    if (shuffled && AppDelegate.instance.serverVersion > 11) {
        [[Utilities getJsonRPC]
         callMethod:@"Player.SetPartymode"
         withParameters:@{@"playerid": @(0), @"partymode": @NO}
         onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *internalError) {
            [self playerOpen:playbackParams indicator:cellActivityIndicator];
        }];
    }
    else {
        [self playerOpen:playbackParams indicator:cellActivityIndicator];
    }
}

- (void)SFloadURL:(NSString*)url {
    NSURL *nsurl = [NSURL URLWithString:url];
    SFSafariViewController *svc = nil;
    // Try to load the URL via SFSafariViewController. If this is not possible, check if this is loadable
    // with other system applications. If so, load it. If not, show an error popup.
    @try {
        svc = [[SFSafariViewController alloc] initWithURL:nsurl];
    } @catch (NSException *exception) {
        if ([UIApplication.sharedApplication canOpenURL:nsurl]) {
            [UIApplication.sharedApplication openURL:nsurl options:@{} completionHandler:nil];
        }
        else {
            UIAlertController *alertView = [Utilities createAlertOK:LOCALIZED_STR(@"Error loading page") message:exception.reason];
            [self presentViewController:alertView animated:YES completion:nil];
        }
        return;
    }
    UIViewController *ctrl = self;
    svc.delegate = self;
    if (IS_IPAD) {
        // On iPad presenting from the active ViewController results in blank screen
        ctrl = UIApplication.sharedApplication.keyWindow.rootViewController;
    }
    if (![svc isBeingPresented]) {
        if (ctrl.presentedViewController) {
            [ctrl dismissViewControllerAnimated:YES completion:nil];
        }
        [ctrl presentViewController:svc animated:YES completion:nil];
    }
}

@end

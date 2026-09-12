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

@implementation NSMutableDictionary (Extensions)

- (void)key:(id)key value:(id)value {
    // Do not attempt to write empty keys/objects. Do not overwrite any existing key.
    if (key && value && !self[key]) {
        self[key] = value;
    }
}

@end

@implementation BaseActionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    xbmcDateFormatter = [NSDateFormatter new];
    xbmcDateFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    xbmcDateFormatter.timeZone = [NSTimeZone timeZoneWithName:@"UTC"]; // all times in Kodi PVR are UTC
    xbmcDateFormatter.locale = [NSLocale systemLocale]; // Needed to work with 12h system setting in combination with "UTC"
}

- (void)disableScrollsToTopPropertyOnAllSubviewsOf:(UIView*)view {
    for (UIView *subview in view.subviews) {
        if ([subview isKindOfClass:[UIScrollView class]]) {
            ((UIScrollView*)subview).scrollsToTop = NO;
        }
        [self disableScrollsToTopPropertyOnAllSubviewsOf:subview];
    }
}

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

- (void)playerAction:(NSString*)action params:(NSDictionary*)params playerid:(int)playerid {
    NSMutableDictionary *mutableParams = [NSMutableDictionary dictionaryWithDictionary:params];
    mutableParams[@"playerid"] = @(playerid);
    [[Utilities getJsonRPC] callMethod:action withParameters:mutableParams];
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
    [cellActivityIndicator startAnimating];
    [[Utilities getJsonRPC] callMethod:@"Playlist.Add" withParameters:params onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *error) {
        [cellActivityIndicator stopAnimating];
        if (error == nil && methodError == nil) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"XBMCPlaylistHasChanged" object:nil];
        }
    }];
}

- (void)playlistInsert:(NSDictionary*)params indicator:(UIActivityIndicatorView*)cellActivityIndicator {
    [cellActivityIndicator startAnimating];
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
    NSString *optionsKey = @"options";
    NSDictionary *optionsValue = [NSDictionary dictionaryWithObjectsAndKeys:
                                  @(resume), @"resume",
                                  @(shuffled), @"shuffled",
                                  playername, @"playername",
                                  nil];
    NSDictionary *playbackParams = [NSDictionary dictionaryWithObjectsAndKeys:
                                    playbackItems, @"item",
                                    optionsValue, optionsKey,
                                    nil];
    if (shuffled) {
        [[Utilities getJsonRPC]
         callMethod:@"Player.SetPartymode"
         withParameters:@{@"playerid": @0, @"partymode": @NO}
         onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *internalError) {
            [self playerOpen:playbackParams indicator:cellActivityIndicator];
        }];
    }
    else {
        [self playerOpen:playbackParams indicator:cellActivityIndicator];
    }
}

- (void)openURL:(NSString*)url {
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

- (void)recordChannel:(NSDictionary*)item indicator:(UIActivityIndicatorView*)cellActivityIndicator onSuccess:(void (^)(void))onSuccess {
    NSString *methodToCall = @"PVR.Record";
    NSString *parameterName = @"channel";
    NSNumber *itemid = [Utilities getNumberFromItem:item[@"channelid"]];
    NSNumber *storeChannelid = itemid;
    NSNumber *storeBroadcastid = [Utilities getNumberFromItem:item[@"broadcastid"]];
    if ([itemid longValue] == 0) {
        itemid = [Utilities getNumberFromItem:item[@"pvrExtraInfo"][@"channelid"]];
        if ([itemid longValue] == 0) {
            return;
        }
        storeChannelid = itemid;
        NSDate *starttime = [xbmcDateFormatter dateFromString:item[@"starttime"]];
        NSDate *endtime = [xbmcDateFormatter dateFromString:item[@"endtime"]];
        float percent_elapsed = [Utilities getPercentElapsed:starttime EndDate:endtime];
        if (percent_elapsed < 0) {
            itemid = [Utilities getNumberFromItem:item[@"broadcastid"]];
            storeBroadcastid = itemid;
            storeChannelid = @(0);
            methodToCall = @"PVR.ToggleTimer";
            parameterName = @"broadcastid";
        }
    }
    
    [cellActivityIndicator startAnimating];
    NSDictionary *parameters = @{parameterName: itemid};
    [[Utilities getJsonRPC] callMethod:methodToCall
                        withParameters:parameters
                          onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *error) {
        [cellActivityIndicator stopAnimating];
        if (error == nil && methodError == nil) {
            NSNumber *status = @(![item[@"isrecording"] boolValue]);
            if ([item[@"broadcastid"] longLongValue] > 0) {
                status = @(![item[@"hastimer"] boolValue]);
            }
            NSDictionary *params = @{
                @"channelid": storeChannelid,
                @"broadcastid": storeBroadcastid,
                @"status": status,
            };
            [[NSNotificationCenter defaultCenter] postNotificationName:@"KodiServerRecordTimerStatusChange" object:nil userInfo:params];
            
            if (onSuccess) {
                onSuccess();
            }
        }
        else {
            NSString *message = [Utilities formatClipboardMessage:methodToCall
                                                       parameters:parameters
                                                            error:error
                                                      methodError:methodError];
            UIAlertController *alertCtrl = [Utilities createAlertCopyClipboard:LOCALIZED_STR(@"ERROR") message:message];
            [self presentViewController:alertCtrl animated:YES completion:nil];
        }
    }];
}

- (NSMutableDictionary*)getNewDictionaryFromItem:(NSDictionary*)item mainFields:(NSDictionary*)mainFields serverURL:(NSString*)serverURL sec2min:(int)sec2min useIcon:(BOOL)useIcon {
    NSString *label = [Utilities getStringFromItem:item[mainFields[@"row1"]]];
    NSString *genre = [Utilities getStringFromItem:item[mainFields[@"row2"]]];
    NSString *year = [Utilities getYearFromItem:item[mainFields[@"row3"]]];
    NSString *runtime = [Utilities getTimeFromItem:item[mainFields[@"row4"]] sec2min:sec2min];
    NSString *rating = [Utilities getRatingFromItem:item[mainFields[@"row5"]]];
    NSString *family = [Utilities getStringFromItem:mainFields[@"row8"]];
    NSString *seasonNumber = [Utilities getStringFromItem:item[mainFields[@"row10"]]];
    NSString *clearlogo = [Utilities getClearArtFromDictionary:item[@"art"] type:@"clearlogo"];
    NSString *clearart = [Utilities getClearArtFromDictionary:item[@"art"] type:@"clearart"];
    NSString *thumbnailPath = [Utilities getThumbnailFromDictionary:item useBanner:NO useIcon:useIcon];
    NSString *bannerPath = [Utilities getThumbnailFromDictionary:item useBanner:YES useIcon:useIcon];
    NSString *stringURL = [Utilities formatStringURL:thumbnailPath serverURL:serverURL];
    NSString *bannerURL = [Utilities formatStringURL:bannerPath serverURL:serverURL];
    NSString *fanartURL = [Utilities formatStringURL:item[@"fanart"] serverURL:serverURL];
    if (!stringURL.length) {
        stringURL = [Utilities getItemIconFromDictionary:item];
    }
    // row7 and row19 objects are used for sorting and must use NSString
    NSString *row7object = [Utilities getStringFromItem:item[mainFields[@"row7"]]];
    NSString *row19itemKey = [mainFields[@"row19"] isEqualToString:@"tag"] ? @"label" : mainFields[@"row19"];
    NSString *row19object = [Utilities getStringFromItem:item[row19itemKey]];
    
    NSMutableDictionary *newDict = [NSMutableDictionary new];
    newDict[@"label"] = label;
    newDict[@"genre"] = genre;
    newDict[@"thumbnail"] = stringURL;
    newDict[@"fanart"] = fanartURL;
    newDict[@"banner"] = bannerURL;
    newDict[@"clearlogo"] = clearlogo;
    newDict[@"clearart"] = clearart;
    newDict[@"runtime"] = runtime;
    newDict[@"season"] = seasonNumber;
    newDict[@"family"] = family;
    newDict[@"year"] = year;
    newDict[@"rating"] = rating;
    newDict[@"playlistid"] = mainFields[@"playlistid"];
    [newDict key:mainFields[@"row6"] value:item[mainFields[@"row6"]]];
    [newDict key:mainFields[@"row7"] value:row7object];
    [newDict key:mainFields[@"row8"] value:item[mainFields[@"row8"]]];
    [newDict key:mainFields[@"row9"] value:item[mainFields[@"row9"]]];
    [newDict key:mainFields[@"row10"] value:item[mainFields[@"row10"]]];
    [newDict key:mainFields[@"row11"] value:item[mainFields[@"row11"]]];
    [newDict key:mainFields[@"row12"] value:item[mainFields[@"row12"]]];
    [newDict key:mainFields[@"row13"] value:item[mainFields[@"row13"]]];
    [newDict key:mainFields[@"row14"] value:item[mainFields[@"row14"]]];
    [newDict key:mainFields[@"row15"] value:item[mainFields[@"row15"]]];
    [newDict key:mainFields[@"row16"] value:item[mainFields[@"row16"]]];
    [newDict key:mainFields[@"row17"] value:item[mainFields[@"row17"]]];
    [newDict key:mainFields[@"row18"] value:item[mainFields[@"row18"]]];
    [newDict key:mainFields[@"row19"] value:row19object];
    [newDict key:mainFields[@"row20"] value:item[mainFields[@"row20"]]];
    
    return newDict;
}


@end

//
//  WebViewController.m
//  XBMC Remote
//
//  Created by Giovanni Messina on 26/2/12.
//  Copyright (c) 2012 joethefox inc. All rights reserved.
//

#import "WebViewController.h"
#import "mainMenu.h"
#import "AppDelegate.h"
#import "DetailViewController.h"
#import "ViewControllerIPad.h"
#import "StackScrollViewController.h"
#import "DetailViewController.h"

@interface WebViewController ()

@end

@implementation WebViewController

@synthesize detailItem = _detailItem;
@synthesize urlRequest;
@synthesize detailViewController;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(void)fade:(UIView*)view AnimDuration:(float)seconds startAlpha:(float)start endAlpha:(float)end {
    view.alpha = start;
    CGContextRef contextView = UIGraphicsGetCurrentContext();
	[UIView beginAnimations:nil context:contextView];
    [UIView setAnimationDuration:seconds];
    view.alpha = end;
    [UIView commitAnimations];
}

#pragma mark -	
#pragma mark actionSheet delegate methods;

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
	switch (actionSheet.tag) {
        case 30:
            if (buttonIndex == 0){
                [[UIApplication sharedApplication] openURL:[Twitterweb.request URL]];
            }
            break;
        default: break;
    }
}


#pragma mark -	
#pragma mark webView delegate methods;

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    return YES;
}

- (void)webViewDidStartLoad: (UIWebView *)webView{
    [TwitterwebLoadIndicator startAnimating];
    [self fade:topNavigationLabel AnimDuration:0.2 startAlpha:1 endAlpha:0];
}

- (void)webViewDidFinishLoad: (UIWebView *)webView {
    [TwitterwebLoadIndicator stopAnimating];
    BOOL blank_page=[[[Twitterweb.request URL] absoluteString] isEqualToString:@"about:blank"];
    [webBackButton setEnabled:[Twitterweb canGoBack] && !blank_page]; // Enable or disable back
    [webForwardButton setEnabled:[Twitterweb canGoForward]];
    tweetURL.text=[[Twitterweb.request URL] absoluteString];
    topNavigationLabel.text=[Twitterweb stringByEvaluatingJavaScriptFromString:@"document.title"];
    [self fade:topNavigationLabel AnimDuration:0.2 startAlpha:0 endAlpha:1];
    UIEdgeInsets tableViewInsets = UIEdgeInsetsZero;
    tableViewInsets = Twitterweb.scrollView.contentInset;
    tableViewInsets.bottom = 44;
    Twitterweb.scrollView.contentInset = tableViewInsets;
    Twitterweb.scrollView.scrollIndicatorInsets = tableViewInsets;

}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
     [TwitterwebLoadIndicator stopAnimating];
    if (error != NULL && ([error code] != NSURLErrorCancelled)) {
		if ([error code] != NSURLErrorCancelled) {
			//show error alert, etc.
		}
        UIAlertView *errorAlert = [[UIAlertView alloc]
								   initWithTitle:NSLocalizedString(@"Error loading page", nil)
								   message: [error localizedFailureReason]
								   delegate:nil
								   cancelButtonTitle:NSLocalizedString(@"OK", nil)
								   otherButtonTitles:nil];
        [errorAlert show];
//        [errorAlert release];
    }
}

-(IBAction)TwitterWebBackButton:(id)sender{
    [Twitterweb goBack];
}

-(IBAction)TwitterWebForwardButton:(id)sender{
    [Twitterweb goForward];
}

-(IBAction)TwitterWebActionButton:(id)sender{
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                             delegate:self
                                                    cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:NSLocalizedString(@"Open in Safari", nil), nil];
    actionSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
    [actionSheet showInView:self.view];
    actionSheet.tag = 30;
//    [actionSheet release];
}

#pragma mark - JSON calls

- (NSDictionary *) indexKeyedDictionaryFromArray:(NSArray *)array {
    NSMutableDictionary *mutableDictionary = [[NSMutableDictionary alloc] init];
    NSInteger numelement=[array count];
    for (int i=0;i<numelement-1;i+=2){
        [mutableDictionary setObject:[array objectAtIndex:i] forKey:[array objectAtIndex:i+1]];
    }
    return (NSDictionary *)mutableDictionary;
}

- (NSMutableDictionary *) indexKeyedMutableDictionaryFromArray:(NSArray *)array {
    NSMutableDictionary *mutableDictionary = [[NSMutableDictionary alloc] init];
    NSInteger numelement=[array count];
    for (int i=0;i<numelement-1;i+=2){
        [mutableDictionary setObject:[array objectAtIndex:i] forKey:[array objectAtIndex:i+1]];
    }
    return (NSMutableDictionary *)mutableDictionary;
}

-(void)showContent:(id)sender{
    NSDictionary *item=self.detailItem;
    mainMenu *MenuItem = nil;
    int choosedTab = 0;
    NSString *notificationName = nil;
    if ([[item objectForKey:@"family"] isEqualToString:@"albumid"]){
        notificationName = @"UIApplicationEnableMusicSection";
        MenuItem = [[AppDelegate instance].playlistArtistAlbums copy];
    }
    else if ([[item objectForKey:@"family"] isEqualToString:@"artistid"]){
        notificationName = @"UIApplicationEnableMusicSection";
        choosedTab = 1;
        MenuItem = [[AppDelegate instance].playlistArtistAlbums copy];
    }
    MenuItem.subItem.mainLabel=[NSString stringWithFormat:@"%@", [item objectForKey:@"label"]];
    NSDictionary *methods=[self indexKeyedDictionaryFromArray:[[MenuItem.subItem mainMethod] objectAtIndex:choosedTab]];
    if ([methods objectForKey:@"method"]!=nil){ // THERE IS A CHILD
        NSDictionary *mainFields=[[MenuItem mainFields] objectAtIndex:choosedTab];
        NSMutableDictionary *parameters=[self indexKeyedMutableDictionaryFromArray:[[MenuItem.subItem mainParameters] objectAtIndex:choosedTab]];
        id obj = [NSNumber numberWithInt:[[item objectForKey:[mainFields objectForKey:@"row6"]] intValue]];
        id objKey = [mainFields objectForKey:@"row6"];
        if ([AppDelegate instance].serverVersion>11 && [[parameters objectForKey:@"disableFilterParameter"] boolValue] == FALSE){
            obj = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:[[item objectForKey:[mainFields objectForKey:@"row6"]] intValue]],[mainFields objectForKey:@"row6"], nil];
            objKey = @"filter";
        }
        NSMutableArray *newParameters=[NSMutableArray arrayWithObjects:
                                       [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                        obj,objKey,
                                        [[parameters objectForKey:@"parameters"] objectForKey:@"properties"], @"properties",
                                        [[parameters objectForKey:@"parameters"] objectForKey:@"sort"],@"sort",
                                        nil], @"parameters", [parameters objectForKey:@"label"], @"label",
                                       [NSNumber numberWithBool:YES], @"fromWikipedia",
                                       [parameters objectForKey:@"extra_info_parameters"], @"extra_info_parameters",
                                       nil];
        [[MenuItem.subItem mainParameters] replaceObjectAtIndex:choosedTab withObject:newParameters];
        MenuItem.subItem.chooseTab=choosedTab;
        if (![[item objectForKey:@"disableNowPlaying"] boolValue]){
            MenuItem.subItem.disableNowPlaying = NO;
        }
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone){
            self.detailViewController = [[DetailViewController alloc] initWithNibName:@"DetailViewController" bundle:nil];
            self.detailViewController.detailItem = MenuItem.subItem;
            [self.navigationController pushViewController:self.detailViewController animated:YES];
        }
        else{
            DetailViewController *iPadDetailViewController = [[DetailViewController alloc] initWithNibName:@"DetailViewController" withItem:MenuItem.subItem withFrame:CGRectMake(0, 0, STACKSCROLL_WIDTH, self.view.frame.size.height) bundle:nil];
            [[AppDelegate instance].windowController.stackScrollViewController addViewInSlider:iPadDetailViewController invokeByController:self isStackStartView:FALSE];
            [[AppDelegate instance].windowController.stackScrollViewController enablePanGestureRecognizer];
            [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object: nil];
        }
    }
}
#pragma mark - Utility

-(void)goBack:(id)sender{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone){
        [self.navigationController popViewControllerAnimated:YES];
    }
    else{
        [[NSNotificationCenter defaultCenter] postNotificationName:@"UIApplicationEnableStackPan" object: nil];
    }
}

#pragma mark - View lifecycle

- (void)viewDidLoad{
    [super viewDidLoad];
    [bottomToolbar setTintColor:TINT_COLOR];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone){
        UIEdgeInsets tableViewInsets = UIEdgeInsetsZero;
        float iOSYDelta = - [[UIApplication sharedApplication] statusBarFrame].size.height;
        tableViewInsets.top = 44 + fabs(iOSYDelta);
        Twitterweb.scrollView.contentInset = tableViewInsets;
        Twitterweb.scrollView.scrollIndicatorInsets = tableViewInsets;
    }
    NSDictionary *item = self.detailItem;
    UIBarButtonItem *extraButton = nil;
    int titleWidth = 310;
    if ([[item objectForKey:@"family"] isEqualToString:@"albumid"]){
        UIImage* extraButtonImg = [UIImage imageNamed:@"st_song_icon"];
        BOOL fromAlbumView = NO;
        if (((NSNull *)[item objectForKey:@"fromAlbumView"] != [NSNull null])){
            fromAlbumView = [[item objectForKey:@"fromAlbumView"] boolValue];
        }
        if (fromAlbumView){
            extraButton =[[UIBarButtonItem alloc] initWithImage:extraButtonImg style:UIBarButtonItemStylePlain target:self action:@selector(goBack:)];
        }
        else{
            extraButton =[[UIBarButtonItem alloc] initWithImage:extraButtonImg style:UIBarButtonItemStylePlain target:self action:@selector(showContent:)];
        }        
        titleWidth = 254;
    }
    else if ([[item objectForKey:@"family"] isEqualToString:@"artistid"]){
        UIImage* extraButtonImg = [UIImage imageNamed:@"st_album_icon"];
        extraButton =[[UIBarButtonItem alloc] initWithImage:extraButtonImg style:UIBarButtonItemStylePlain target:self action:@selector(showContent:)];
        titleWidth = 254;
    }
    UIView *titleView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 244, 44)];
    titleView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    topNavigationLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 2, 244, 40)];
    topNavigationLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    topNavigationLabel.tag = 1;
    topNavigationLabel.backgroundColor = [UIColor clearColor];
    topNavigationLabel.font = [UIFont boldSystemFontOfSize:12];
    topNavigationLabel.minimumScaleFactor=10.0f/12.0f;
    topNavigationLabel.numberOfLines=0;
    topNavigationLabel.adjustsFontSizeToFitWidth = YES;
    topNavigationLabel.textAlignment = NSTextAlignmentLeft;
    topNavigationLabel.textColor = [UIColor whiteColor];
    topNavigationLabel.shadowOffset    = CGSizeMake (0.0, -1.0);
    topNavigationLabel.highlightedTextColor = [UIColor blackColor];
    topNavigationLabel.opaque=YES;
    CGRect frame = CGRectMake(0.0, 12.0, 25.0, 44.0);  	
	TwitterwebLoadIndicator = [[UIActivityIndicatorView alloc] initWithFrame:frame];	
	TwitterwebLoadIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhite;	
	[TwitterwebLoadIndicator sizeToFit];  	
    [titleView addSubview:TwitterwebLoadIndicator];
    [titleView addSubview:topNavigationLabel];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad){
        UIToolbar *toolbar = [UIToolbar new];
        [toolbar setTintColor:TINT_COLOR];
        toolbar.barStyle = UIBarStyleBlackTranslucent;
        toolbar.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth;
        toolbar.contentMode = UIViewContentModeScaleAspectFill;            
        [toolbar sizeToFit];
        CGFloat toolbarHeight = [toolbar frame].size.height;
        CGRect mainViewBounds = self.view.bounds;
        [toolbar setFrame:CGRectMake(CGRectGetMinX(mainViewBounds),
                                     CGRectGetMinY(mainViewBounds),
                                     CGRectGetWidth(mainViewBounds),
                                     toolbarHeight)];
        CGRect toolbarShadowFrame = CGRectMake(0.0f, 43, 320, 8);
        UIImageView *toolbarShadow = [[UIImageView alloc] initWithFrame:toolbarShadowFrame];
        [toolbarShadow setImage:[UIImage imageNamed:@"tableUp.png"]];
        toolbarShadow.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        toolbarShadow.opaque = YES;
        toolbarShadow.alpha = 0.5;
        [toolbar addSubview:toolbarShadow];
        topNavigationLabel.font = [UIFont systemFontOfSize:16];
        [titleView setFrame:CGRectMake(10, 0, titleWidth, 44)];
        [toolbar addSubview:titleView];
        [self.view addSubview:toolbar];
        UIBarButtonItem *spacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        NSArray *items = [NSArray arrayWithObjects:
                          spacer,
                          extraButton,
                          nil];
        toolbar.items = items;
        Twitterweb.autoresizingMask = UIViewAutoresizingNone;
        [Twitterweb setFrame:CGRectMake(Twitterweb.frame.origin.x, Twitterweb.frame.origin.y + 44, Twitterweb.frame.size.width, Twitterweb.frame.size.height-44)];
        Twitterweb.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
    else {
        self.navigationItem.titleView = titleView;
        self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:
                                                   extraButton,
                                                   nil];
    }
    [Twitterweb loadRequest:self.urlRequest];
}

- (void)viewDidUnload{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation{
//    return (interfaceOrientation == UIInterfaceOrientationPortrait);
    return YES;
}

-(BOOL)shouldAutorotate{
    return YES;
}

#if __IPHONE_OS_VERSION_MAX_ALLOWED < 90000
- (NSUInteger)supportedInterfaceOrientations
#else
- (UIInterfaceOrientationMask)supportedInterfaceOrientations
#endif
{
    return UIInterfaceOrientationMaskAllButUpsideDown;
}

@end

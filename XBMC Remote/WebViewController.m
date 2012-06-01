//
//  WebViewController.m
//  XBMC Remote
//
//  Created by Giovanni Messina on 26/2/12.
//  Copyright (c) 2012 joethefox inc. All rights reserved.
//

#import "WebViewController.h"

@interface WebViewController ()

@end

@implementation WebViewController

@synthesize urlRequest;

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
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
     [TwitterwebLoadIndicator stopAnimating];
    if (error != NULL && ([error code] != NSURLErrorCancelled)) {
		if ([error code] != NSURLErrorCancelled) {
			//show error alert, etc.
		}
        UIAlertView *errorAlert = [[UIAlertView alloc]
								   initWithTitle:@"Error loading page"
								   message: [error localizedFailureReason]
								   delegate:nil
								   cancelButtonTitle:@"OK"
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
                                                    cancelButtonTitle:@"Cancel"
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:@"Open in Safari", nil];
    actionSheet.actionSheetStyle = UIActionSheetStyleDefault; 
    [actionSheet showInView:self.view];
    actionSheet.tag = 30;
//    [actionSheet release];
}

#pragma mark - View lifecycle

- (void)viewDidLoad{
    [super viewDidLoad];
    UIView *titleView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 244, 44)];
    titleView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    topNavigationLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 2, 244, 40)];
    topNavigationLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    topNavigationLabel.tag = 1;
    topNavigationLabel.backgroundColor = [UIColor clearColor];
    topNavigationLabel.font = [UIFont boldSystemFontOfSize:12];
    topNavigationLabel.minimumFontSize=10.0;
    topNavigationLabel.numberOfLines=0;
    topNavigationLabel.adjustsFontSizeToFitWidth = YES;
    topNavigationLabel.textAlignment = UITextAlignmentLeft;
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
        [titleView setFrame:CGRectMake(10, 0, 310, 44)];
        [toolbar addSubview:titleView];
        [self.view addSubview:toolbar];
        Twitterweb.autoresizingMask = UIViewAutoresizingNone;
        [Twitterweb setFrame:CGRectMake(Twitterweb.frame.origin.x, Twitterweb.frame.origin.y + 44, Twitterweb.frame.size.width, Twitterweb.frame.size.height-44)];
        Twitterweb.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
    else {
        self.navigationItem.titleView = titleView;
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

@end

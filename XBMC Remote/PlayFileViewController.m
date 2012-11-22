//
//  PlayFileViewController.m
//  XBMC Remote
//
//  Created by Giovanni Messina on 4/4/12.
//  Copyright (c) 2012 joethefox inc. All rights reserved.
//

#import "PlayFileViewController.h"
#import "GlobalData.h"

@interface PlayFileViewController ()

@end

@implementation PlayFileViewController

@synthesize detailItem = _detailItem;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

#pragma mark - PlayBack

-(void) createPlayback{
    NSDictionary *item=self.detailItem;
    NSLog(@"%@", item);
 
    [jsonRPC callMethod:@"Files.PrepareDownload" withParameters:[NSDictionary dictionaryWithObjectsAndKeys:[item objectForKey:@"file"], @"path", nil] onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
        if (error==nil && methodError==nil){
            if( [methodResult count] > 0){
                GlobalData *obj=[GlobalData getInstance];     
                //NSDictionary *itemid = [methodResult objectForKey:@"details"]; 

                NSString *serverURL=[NSString stringWithFormat:@"%@:%@", obj.serverIP, obj.serverPort];
                NSString *stringURL = [NSString stringWithFormat:@"%@://%@/%@",(NSArray*)[methodResult objectForKey:@"protocol"], serverURL, [(NSDictionary*)[methodResult objectForKey:@"details"] objectForKey:@"path"]];                
                NSLog(@"RESULT %@", stringURL);
                NSURLRequest *request = [[NSURLRequest alloc] initWithURL: [NSURL URLWithString: stringURL] cachePolicy: NSURLRequestUseProtocolCachePolicy timeoutInterval: 10];  
                [webPlayView loadRequest: request];  
            }
        }
        else {
            NSLog(@"ci deve essere un primo problema %@", methodError);
        }
    }];
    
}

#pragma mark - Life Cycle

- (void)viewDidLoad{
    
    
    GlobalData *obj=[GlobalData getInstance];     
    NSString *userPassword=[obj.serverPass isEqualToString:@""] ? @"" : [NSString stringWithFormat:@":%@", obj.serverPass];
    NSString *serverJSON=[NSString stringWithFormat:@"http://%@%@@%@:%@/jsonrpc", obj.serverUser, userPassword, obj.serverIP, obj.serverPort];
    jsonRPC = [[DSJSONRPC alloc] initWithServiceEndpoint:[NSURL URLWithString:serverJSON]];
    [self createPlayback];
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

-(void)dealloc{
    jsonRPC=nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end

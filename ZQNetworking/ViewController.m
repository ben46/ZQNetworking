//
//  ViewController.m
//  ZQNetworking
//
//  Created by nobby heell on 2019/2/14.
//  Copyright © 2019年 nobby heell. All rights reserved.
//

#import "ViewController.h"
#import "ZQRequest.h"
#import "ZQRequestManager.h"
#import "ZQRequestCache.h"

@interface ViewController ()
@property (strong, nonatomic) UILabel *lbl;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
//    for (int i = 0; i < 100; i++){
//        [[ZQRequestCache sharedInstance] deleteRequestFromDatabaseWithRequestId:i];
//    }
//    return;
    
    NSArray *arr =  [[ZQRequestCache sharedInstance] allRequestsFromDatabase];
    NSLog(@"%@", arr);
    return;
    
    ZQRequestManager *mgr = [ZQRequestManager sharedInstance];
    for (int i = 0; i < 10; i++)
    {
        ZQRequest *request = [ZQRequest requestWithURLString:@"http://47.98.52.6:9999/getblatt.htm" params:@{@"page": @(i)}];
        request.cacheKey = [NSString stringWithFormat:@"cache%d", i];
        request.reliability = ZQRequestReliabilityStoreToDB;
        [mgr sendRequest:request
            successBlock:^(id obj) {
                NSLog(@"~~~~~~~~~~~~~[%d]", request.requestId);
            }
            failureBlock:nil];
    }

//    self.lbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 500, 500)];
//    [_lbl setText:@"sfsdf"];
//    [self.view addSubview:_lbl];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkChanged:) name:@"ZQNetworkChanged" object:nil];
    
}

//- (void)networkChanged:(NSNotification *)notif{
//    [_lbl setText:[[notif userInfo] objectForKey:@"df"]];
//}


@end

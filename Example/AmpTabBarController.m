//
//  AmpTabBarController.m
//  amplfy
//
//  Created by DKarsh on 8/31/15.
//  Copyright (c) 2015 Kickflip. All rights reserved.
//

#import "AmpTabBarController.h"

@interface AmpTabBarController ()

@end

@implementation AmpTabBarController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.tabBar setHidden:YES];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(gotoVC:) name:@"kGotoViewController" object:nil];
    NSNotification *note = [NSNotification notificationWithName:@"kGotoViewController" object:@"Scan"];
    [self gotoVC:note];
    // Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    NSArray *allVCs = self.viewControllers;
    [allVCs enumerateObjectsUsingBlock:^(UIViewController *obj, NSUInteger idx, BOOL *stop) {
        NSLog(@"restorationIdentifier = %@",obj.restorationIdentifier);
    }];
}

- (void)gotoVC:(NSNotification*)note
{
    
    
//    NSString *NaviStr = [NSString stringWithFormat:@"Navi%@",note.object];
//    if ([note.object isEqualToString:@"Scan"]) {
//        [[NSNotificationCenter defaultCenter]postNotificationName:@"RestartScan" object:nil];
//        
//    }
//    RACSequence *results = [self.viewControllers.rac_sequence
//                            filter:^ BOOL (UIViewController *vc) {
//                                return [vc.restorationIdentifier isEqualToString:NaviStr];
//                            }];
//    
//    UINavigationController *nav = results.head;
//    
//    nav?[nav popToRootViewControllerAnimated:NO]:nil;
//    nav?[self setSelectedViewController:nav]:nil;
//    if (note.userInfo) {
//        self.product = [note.userInfo objectForKey:@"productKey"];
//        [self.mm_drawerController closeDrawerAnimated:YES completion:nil];
//    }
//    
//    //    if ([NaviStr isEqualToString:@"NaviScan"]) {
//    //        [[NSNotificationCenter defaultCenter]postNotificationName:@"handleRefresh" object:nil];
//    //    }

}




- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end

//
//  AmpStartVC.m
//  amplfy
//
//  Created by DKarsh on 8/31/15.
//  Copyright (c) 2015 Blnrd llc. All rights reserved.
//

#import "AmpStartVC.h"

@interface AmpStartVC ()

@end

@implementation AmpStartVC

- (void)viewDidLoad {
    [super viewDidLoad];
    UIViewController    *menuVC     = [self.storyboard instantiateViewControllerWithIdentifier:@"MenuVC"];
    UIViewController    *actiVC     = [self.storyboard instantiateViewControllerWithIdentifier:@"ActiVC"];
    UITabBarController  *naviC      = [self.storyboard instantiateViewControllerWithIdentifier:@"TabBarVC"];
    
    self.centerViewController       = naviC;
    self.leftDrawerViewController   = menuVC;
    self.rightDrawerViewController  = actiVC;
    
    CGRect fr = self.view.frame;
    
    [self setMaximumLeftDrawerWidth:fr.size.width-60];
    [self setShowsShadow:YES];
    [self setShouldStretchDrawer:YES];
    
    [self setOpenDrawerGestureModeMask:MMOpenDrawerGestureModeNone];
    [self setCloseDrawerGestureModeMask:MMCloseDrawerGestureModeAll];
    [self setCenterHiddenInteractionMode:MMDrawerOpenCenterInteractionModeNavigationBarOnly];
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

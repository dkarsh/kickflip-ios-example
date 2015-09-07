//
//  KFDemoViewController.m
//  Kickflip
//
//  Created by Christopher Ballinger on 1/28/14.
//  Copyright (c) 2014 Kickflip. All rights reserved.
//

#import "KFDemoViewController.h"

#import "KFLog.h"
//#import "KFUser.h"
#import "AmpKeys.h"
//#import "YapDatabase.h"
//#import "YapDatabaseView.h"
#import "PureLayout.h"
#import "KFDateUtils.h"
#import "KFStreamTableViewCell.h"
#import <MediaPlayer/MediaPlayer.h>
#import "UIActionSheet+Blocks.h"
#import "VTAcknowledgementsViewController.h"
#import "KFConstants.h"

static NSString * const kKFStreamView = @"kKFStreamView";
static NSString * const kKFStreamsGroup = @"kKFStreamsGroup";
static NSString * const kKFStreamsCollection = @"kKFStreamsCollection";

@interface KFDemoViewController ()
@property (nonatomic, strong, readwrite) UIButton *broadcastButton;
@property (nonatomic) NSUInteger currentPage;
@end

@implementation KFDemoViewController




- (void) broadcastButtonPressed:(id)sender {
    [AmpKeys presentBroadcasterFromViewController:self ready:^(KFStream *stream) {
        if (stream.streamURL) {
            DDLogInfo(@"Stream is ready at URL: %@", stream.streamURL);
        }
    } completion:^(BOOL success, NSError* error){
        if (!success) {
            DDLogError(@"Error setting up stream: %@", error);
        } else {
            DDLogInfo(@"Done broadcasting");
        }
    }];
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    [self broadcastButtonPressed:nil];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



@end

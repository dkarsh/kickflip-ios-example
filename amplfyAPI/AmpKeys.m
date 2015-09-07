//
//  Kickflip.m
//  FFmpegEncoder
//
//  Created by Christopher Ballinger on 1/16/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import "AmpKeys.h"
#import "KFLog.h"
#import "KFBroadcastViewController.h"

@interface AmpKeys()
@property (nonatomic, copy) NSString *vidID;
@property (nonatomic, copy) NSString *apiKey;
@property (nonatomic, copy) NSString *apiSecret;
@property (nonatomic) NSUInteger maxBitrate;
@property (nonatomic) BOOL useAdaptiveBitrate;
@end

static AmpKeys *_kickflip = nil;

@implementation AmpKeys

+ (void) presentBroadcasterFromViewController:(UIViewController *)viewController ready:(KFBroadcastReadyBlock)readyBlock completion:(KFBroadcastCompletionBlock)completionBlock {
    KFBroadcastViewController *broadcastViewController = [[KFBroadcastViewController alloc] init];
    broadcastViewController.readyBlock = readyBlock;
    broadcastViewController.completionBlock = completionBlock;
    [viewController presentViewController:broadcastViewController animated:YES completion:nil];
}

+ (AmpKeys*) sharedInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _kickflip = [[AmpKeys alloc] init];
    });
    return _kickflip;
}

- (id) init {
    if (self = [super init]) {
        _maxBitrate = 2000 * 1000; // 2 Mbps
        _useAdaptiveBitrate = YES;
    }
    return self;
}


//+ (void) setupWithAPIKey:(NSString *)key secret:(NSString *)secret {
//    Kickflip *kickflip = [Kickflip sharedInstance];
//    kickflip.apiKey = key;
//    kickflip.apiSecret = secret;
//    KFUser *activeUser = [KFUser activeUser];
//    if (!activeUser) {
//        [[KFAPIClient sharedClient] requestNewActiveUserWithUsername:nil callbackBlock:^(KFUser *newUser, NSError *error) {
//            if (error) {
//                DDLogError(@"Error pre-fetching new user: %@", error);
//            } else {
//                DDLogVerbose(@"New user fetched pre-emptively: %@", newUser);
//            }
//        }];
//    }
//}

+ (void)setVid:(NSString*)vid{
    [[AmpKeys sharedInstance]setVidID:vid];
}

+ (NSString*) vidID {
    return [AmpKeys sharedInstance].vidID;
}

+ (NSString*) apiKey {
    return [AmpKeys sharedInstance].apiKey;
}

+ (NSString*) apiSecret {
    return [AmpKeys sharedInstance].apiSecret;
}

+ (void) setMaxBitrate:(double)maxBitrate {
    [AmpKeys sharedInstance].maxBitrate = maxBitrate;
}

+ (double) maxBitrate {
    return [AmpKeys sharedInstance].maxBitrate;
}

+ (BOOL) useAdaptiveBitrate {
    return [AmpKeys sharedInstance].useAdaptiveBitrate;
}

+ (void) setUseAdaptiveBitrate:(BOOL)enabled {
    [AmpKeys sharedInstance].useAdaptiveBitrate = enabled;
}

@end

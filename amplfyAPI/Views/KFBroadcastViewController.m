//
//  KFBroadcastViewController.m
//  Encoder Demo
//
//  Created by Geraint Davies on 11/01/2013.
//  Copyright (c) 2013 GDCL http://www.gdcl.co.uk/license.htm
//

#import "KFBroadcastViewController.h"
#import "KFRecorder.h"
//#import "KFAPIClient.h"
#import "KFUser.h"
#import "KFLog.h"
#import "PureLayout.h"

@implementation KFBroadcastViewController

- (id) init {
    if (self = [super init]) {
        self.recorder = [[KFRecorder alloc] init];
        self.recorder.delegate = self;
    }
    return self;
}

- (void) setupCameraView {
    _cameraView = [[UIView alloc] init];
    _cameraView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
    [self.view addSubview:_cameraView];
}

- (void) setupShareButton {
    _shareButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [_shareButton addTarget:self action:@selector(shareButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [_shareButton setTitle:@"Share" forState:UIControlStateNormal];
    [_shareButton setTitle:@"Buffering..." forState:UIControlStateDisabled];
    self.shareButton.enabled = NO;
    self.shareButton.alpha = 0.0f;
    self.shareButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.shareButton];
    NSLayoutConstraint *constraint = [self.shareButton autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:10.0f];
    [self.view addConstraint:constraint];
    constraint = [self.shareButton autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:10.0f];
    [self.view addConstraint:constraint];
}

- (void) setupRecordButton {
    self.recordButton = [[KFRecordButton alloc] initWithFrame:CGRectZero];
    [self.view addSubview:self.recordButton];
    [self.recordButton addTarget:self action:@selector(recordButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    NSLayoutConstraint *constraint =
    [self.recordButton autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:10.0f];
    [self.view addConstraint:constraint];
    constraint = [self.recordButton autoAlignAxisToSuperviewAxis:ALAxisVertical];
    [self.view addConstraint:constraint];
}


- (void) recordButtonPressed:(id)sender {
    self.recordButton.enabled = NO;
    if (!self.recorder.isRecording) {
        [self.recorder startRecording];
    } else {
        [self.recorder stopRecording];
    }
}

- (void) shareButtonPressed:(id)sender {
    
    NSString *str = [NSString stringWithFormat:@"https://www.amplfy.me/video/%@",self.amppid];
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[str] applicationActivities:nil];
    UIActivityViewControllerCompletionWithItemsHandler completionHandler = ^(NSString *activityType, BOOL completed, NSArray *returnedItems, NSError *activityError) {
        NSLog(@"share activity: %@", activityType);
    };
    activityViewController.completionWithItemsHandler = completionHandler;
    
    [self presentViewController:activityViewController animated:YES completion:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    [self setupCameraView];
    [self setupShareButton];
    [self setupRecordButton];
//    [self setupCancelButton];
//    [self setupRotationImageView];
//    [self setupRotationLabel];
}

- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
    
    CGRect frame =  self.view.bounds;
    frame.origin.x = 5;
    frame.size.width-=10;
    frame.origin.y = 5;
    frame.size.height = frame.size.width;
    _cameraView.frame = frame;
    
    self.recordButton.enabled = YES;
    self.shareButton.alpha = 1.0f;
    self.recordButton.alpha = 1.0f;
    self.rotationLabel.alpha = 0.0f;
    self.rotationImageView.alpha = 0.0f;
    
    [self startPreview];
}




- (void) startPreview
{
    AVCaptureVideoPreviewLayer* preview = self.recorder.previewLayer;
    [preview removeFromSuperlayer];
    preview.frame = self.cameraView.bounds;
    [[preview connection] setVideoOrientation:AVCaptureVideoOrientationPortrait];//[self avOrientationForInterfaceOrientation:orientation]];
    
    [self.cameraView.layer addSublayer:preview];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) recorderDidStartRecording:(KFRecorder *)recorder error:(NSError *)error {
    self.recordButton.enabled = YES;
    if (error) {
        DDLogError(@"Error starting stream: %@", error.userInfo);
        NSDictionary *response = [error.userInfo objectForKey:@"response"];
        NSString *reason = nil;
        if (response) {
            reason = [response objectForKey:@"reason"];
        }
        NSMutableString *errorMsg = [NSMutableString stringWithFormat:@"Error starting stream: %@.", error.localizedDescription];
        if (reason) {
            [errorMsg appendFormat:@" %@", reason];
        }
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Stream Start Error" message:errorMsg delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alertView show];
        self.recordButton.isRecording = NO;
    } else {
        self.recordButton.isRecording = YES;
        self.shareButton.alpha = 1.0f;
    }
}

- (void) recorder:(KFRecorder *)recorder streamReadyAtURL:(NSString *)url {
    self.shareButton.enabled = YES;
    self.amppid = url;
//    [_shareButton setTitle:url forState:UIControlStateNormal];
}

- (void) recorderDidFinishRecording:(KFRecorder *)recorder error:(NSError *)error {
    if (_completionBlock) {
        
        self.recordButton.isRecording = NO;
        self.recordButton.enabled = YES;
        [self.recorder endVideoID];
        if (error) {
            _completionBlock(NO, error);
        } else {
            _completionBlock(YES, nil);
        }
    }
//    [self dismissViewControllerAnimated:YES completion:nil];
}

@end

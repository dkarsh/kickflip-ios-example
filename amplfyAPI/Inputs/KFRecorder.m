//
//  KFRecorder.m
//  FFmpegEncoder
//
//  Created by Christopher Ballinger on 1/16/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//
#import "AmpKeys.h"
#import "KFStream.h"
#import "AFNetworking.h"
#import "KFPaginationInfo.h"
#import "KFRecorder.h"
#import "KFAACEncoder.h"
#import "KFH264Encoder.h"
#import "KFHLSMonitor.h"
#import "KFH264Encoder.h"
#import "KFHLSWriter.h"
#import "KFS3Stream.h"
#import "KFVideoFrame.h"
#import "NSString+MD5.h"

#import "KFFrame.h"
#import "Endian.h"
#import "KFLog.h"

@interface KFRecorder()

@property (nonatomic) NSString *productionID;
@property (nonatomic) NSString *videoID;

@property (nonatomic) double minBitrate;
@property (nonatomic) BOOL hasScreenshot;

@property (nonatomic, strong) CLLocationManager *locationManager;
@end

@implementation KFRecorder

- (id) init {
    if (self = [super init]) {
        _minBitrate = 1000 * 1000;
        [self setupSession];
        [self setupEncoders];
    }
    return self;
}

- (void) setupSession {
    _session = [[AVCaptureSession alloc] init];
    [self setupVideoCapture];
    [self setupAudioCapture];
    
    // start capture and a preview layer
    [_session startRunning];
    
    _previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:_session];
    _previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
}

- (AVCaptureDevice *)audioDevice {
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio];
    if ([devices count] > 0)
        return [devices objectAtIndex:0];
    return nil;
}

- (void) setupHLSWriterWithEndpoint:(NSString*)endpoint {
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    NSString *folderName = [NSString stringWithFormat:@"%@.hls", endpoint];
    NSString *hlsDirectoryPath = [basePath stringByAppendingPathComponent:folderName];
    [[NSFileManager defaultManager] createDirectoryAtPath:hlsDirectoryPath withIntermediateDirectories:YES attributes:nil error:nil];
    self.hlsWriter = [[KFHLSWriter alloc] initWithDirectoryPath:hlsDirectoryPath];
    [_hlsWriter addVideoStreamWithWidth:self.videoWidth height:self.videoHeight];
    [_hlsWriter addAudioStreamWithSampleRate:self.audioSampleRate];

}

- (void) setupEncoders {
    
    self.audioSampleRate = 44100;
    self.videoHeight    = 360;
    self.videoWidth     = 360;
    
    int audioBitrate = 64 * 1000; // 32 Kbps
    
    int maxBitrate = [AmpKeys maxBitrate];
    int videoBitrate = maxBitrate - audioBitrate;
    
    _h264Encoder = [[KFH264Encoder alloc] initWithBitrate:videoBitrate width:self.videoWidth height:self.videoHeight];
    _h264Encoder.delegate = self;
    
    _aacEncoder = [[KFAACEncoder alloc] initWithBitrate:audioBitrate sampleRate:self.audioSampleRate channels:1];
    _aacEncoder.delegate = self;
    _aacEncoder.addADTSHeader = YES;
}

- (void) setupAudioCapture {

    // create capture device with video input
    
    /*
     * Create audio connection
     */
    AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    NSError *error = nil;
    AVCaptureDeviceInput *audioInput = [[AVCaptureDeviceInput alloc] initWithDevice:audioDevice error:&error];
    if (error) {
        NSLog(@"Error getting audio input device: %@", error.description);
    }
    if ([_session canAddInput:audioInput]) {
        [_session addInput:audioInput];
    }
    
    _audioQueue = dispatch_queue_create("Audio Capture Queue", DISPATCH_QUEUE_SERIAL);
    _audioOutput = [[AVCaptureAudioDataOutput alloc] init];
    [_audioOutput setSampleBufferDelegate:self queue:_audioQueue];
    if ([_session canAddOutput:_audioOutput]) {
        [_session addOutput:_audioOutput];
    }
    _audioConnection = [_audioOutput connectionWithMediaType:AVMediaTypeAudio];
}

- (void) setupVideoCapture {
    NSError *error = nil;
    AVCaptureDevice* videoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    AVCaptureDeviceInput* videoInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
    if (error) {
        NSLog(@"Error getting video input device: %@", error.description);
    }
    if ([_session canAddInput:videoInput]) {
        [_session addInput:videoInput];
    }
    
    // create an output for YUV output with self as delegate
    _videoQueue = dispatch_queue_create("Video Capture Queue", DISPATCH_QUEUE_SERIAL);
    _videoOutput = [[AVCaptureVideoDataOutput alloc] init];
    [_videoOutput setSampleBufferDelegate:self queue:_videoQueue];
    NSDictionary *captureSettings = @{(NSString*)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA)};
    _videoOutput.videoSettings = captureSettings;
    _videoOutput.alwaysDiscardsLateVideoFrames = YES;
    if ([_session canAddOutput:_videoOutput]) {
        [_session addOutput:_videoOutput];
    }
    
    _videoConnection = [_videoOutput connectionWithMediaType:AVMediaTypeVideo];
    if ([_videoConnection isVideoOrientationSupported])
    {
        [_videoConnection setVideoOrientation: AVCaptureVideoOrientationPortrait];
    }
}

#pragma mark KFEncoderDelegate method
- (void) encoder:(KFEncoder*)encoder encodedFrame:(KFFrame *)frame {
    if (encoder == _h264Encoder) {
        KFVideoFrame *videoFrame = (KFVideoFrame*)frame;
        [_hlsWriter processEncodedData:videoFrame.data presentationTimestamp:videoFrame.pts streamIndex:0 isKeyFrame:videoFrame.isKeyFrame];
    } else if (encoder == _aacEncoder) {
        [_hlsWriter processEncodedData:frame.data presentationTimestamp:frame.pts streamIndex:1 isKeyFrame:NO];
    }
}

#pragma mark AVCaptureOutputDelegate method
- (void) captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    if (!_isRecording) {
        return;
    }
    // pass frame to encoders
    if (connection == _videoConnection) {
        if (!_hasScreenshot) {
            UIImage *image = [self imageFromSampleBuffer:sampleBuffer];
            NSString *path = [self.hlsWriter.directoryPath stringByAppendingPathComponent:@"thumb.jpg"];
            NSData *imageData = UIImageJPEGRepresentation(image, 0.7);
            [imageData writeToFile:path atomically:NO];
            _hasScreenshot = YES;
        }
        [_h264Encoder encodeSampleBuffer:sampleBuffer];
    } else if (connection == _audioConnection) {
        [_aacEncoder encodeSampleBuffer:sampleBuffer];
    }
}
// Create a UIImage from sample buffer data
- (UIImage *) imageFromSampleBuffer:(CMSampleBufferRef) sampleBuffer {
    // Get a CMSampleBuffer's Core Video image buffer for the media data
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    // Lock the base address of the pixel buffer
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    
    // Get the number of bytes per row for the pixel buffer
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    
    // Get the number of bytes per row for the pixel buffer
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    // Get the pixel buffer width and height
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    
    // Create a device-dependent RGB color space
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    // Create a bitmap graphics context with the sample buffer data
    CGContextRef context = CGBitmapContextCreate(baseAddress, width, height, 8,
                                                 bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    // Create a Quartz image from the pixel data in the bitmap graphics context
    CGImageRef quartzImage = CGBitmapContextCreateImage(context);
    // Unlock the pixel buffer
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    
    // Free up the context and color space
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    
    // Create an image object from the Quartz image
    UIImage *image = [UIImage imageWithCGImage:quartzImage];
    
    // Release the Quartz image
    CGImageRelease(quartzImage);
    
    return (image);
}

- (void) startRecordingReal {
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    [self.locationManager startUpdatingLocation];
    
    NSString *strEndpoint = [NSString randomStringWithLength:8];
    NSLog(@"%@", strEndpoint);
    

    [self setStreamStartLocation];
    [self setupHLSWriterWithEndpoint:strEndpoint];
    [[KFHLSMonitor sharedMonitor] startMonitoringFolderPath:_hlsWriter.directoryPath
                                                   delegate:self];
    
    NSError *error = nil;
    [_hlsWriter prepareForWriting:&error];
    if (error) {
        DDLogError(@"Error preparing for writing: %@", error);
    }
    self.isRecording = YES;
    if (self.delegate && [self.delegate respondsToSelector:@selector(recorderDidStartRecording:error:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate recorderDidStartRecording:self error:nil];
        });
    }
    
}

- (void) startRecording{
    
    NSString *finalyToken = @"Bearer moqAbp7wY.7RdgIb8bm8xxJ8ytwETfwc";
    AFHTTPRequestOperationManager *manager =
    [[AFHTTPRequestOperationManager alloc] initWithBaseURL:[NSURL URLWithString:@"https://amplfy-me.appspot.com"]];
    [manager.requestSerializer setValue:finalyToken forHTTPHeaderField:@"Authorization"];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    [manager POST:@"/api/produce"
       parameters:nil
          success:^(AFHTTPRequestOperation *operation, id responseObject) {
              NSError *error = nil;
              NSMutableDictionary *jsonArray = [NSJSONSerialization JSONObjectWithData:responseObject options:kNilOptions error:&error];
              
              if (error != nil) {
                  NSLog(@"Error parsing JSON.");
              }
              else {
                  NSLog(@"pid: %@", [jsonArray objectForKey:@"pid"]);
                  
                  NSNumber *latitude = [NSNumber numberWithDouble:self.locationManager.location.coordinate.latitude];
                  NSNumber *longitude = [NSNumber numberWithDouble:self.locationManager.location.coordinate.longitude];
                  
                  NSDictionary* params = @{@"pid":[jsonArray objectForKey:@"pid"],
                                           @"long":longitude,
                                           @"lat":latitude};
                  
                  self.productionID = [jsonArray objectForKey:@"pid"];
                  
                  dispatch_async(dispatch_get_main_queue(), ^{
                      [self.delegate recorder:self streamReadyAtURL:self.productionID];
                  });
                  
                  [self updateProductionID:params];
              }
          }
          failure:^(AFHTTPRequestOperation *operation, NSError *error) {
              NSLog(@"Error: %@", error);
          }];
}

- (void) updateProductionID:(NSDictionary *)dictionary{
    NSString *finalyToken = @"Bearer moqAbp7wY.7RdgIb8bm8xxJ8ytwETfwc";
    AFHTTPRequestOperationManager *manager =
    [[AFHTTPRequestOperationManager alloc] initWithBaseURL:[NSURL URLWithString:@"https://amplfy-me.appspot.com"]];
    [manager.requestSerializer setValue:finalyToken forHTTPHeaderField:@"Authorization"];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    [manager  PUT:@"/api/produce"
       parameters:dictionary
          success:^(AFHTTPRequestOperation *operation, id responseObject) {
              [self getVideoID];
          }
          failure:^(AFHTTPRequestOperation *operation, NSError *error) {
              NSLog(@"Error: %@", error);
          }];
}

- (void) getVideoID{
    NSString *finalyToken = @"Bearer moqAbp7wY.7RdgIb8bm8xxJ8ytwETfwc";
    AFHTTPRequestOperationManager *manager =
    [[AFHTTPRequestOperationManager alloc] initWithBaseURL:[NSURL URLWithString:@"https://amplfy-me.appspot.com"]];
    [manager.requestSerializer setValue:finalyToken forHTTPHeaderField:@"Authorization"];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    [manager  POST:@"/api/video"
        parameters:nil
           success:^(AFHTTPRequestOperation *operation, id responseObject) {
               NSError *error = nil;
               NSMutableDictionary *jsonArray = [NSJSONSerialization JSONObjectWithData:responseObject options:kNilOptions error:&error];
               
               if (error != nil) {
                   NSLog(@"Error parsing JSON.");
               }
               else {
                   NSLog(@"vid: %@", [jsonArray objectForKey:@"vid"]);
                   self.videoID = [jsonArray objectForKey:@"vid"];
                   NSDictionary *params  = @{@"pid":self.productionID,
                                             @"vid":self.videoID,
                                             @"startseq":@"0"};
                   
                   [AmpKeys setVid:self.videoID];
                   [self addVideoToProduction:params];
               }
           }
           failure:^(AFHTTPRequestOperation *operation, NSError *error) {
               NSLog(@"Error: %@", error);
           }];
}

- (void) endVideoID{
    dispatch_group_t group = dispatch_group_create();
    
    NSString *finalyToken = @"Bearer moqAbp7wY.7RdgIb8bm8xxJ8ytwETfwc";
    AFHTTPRequestOperationManager *manager =
    [[AFHTTPRequestOperationManager alloc] initWithBaseURL:[NSURL URLWithString:@"https://amplfy-me.appspot.com"]];
    [manager.requestSerializer setValue:finalyToken forHTTPHeaderField:@"Authorization"];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];

    NSDictionary *paramsVid  = @{@"vid":self.videoID,@"status":@"done"};
    NSDictionary *paramsPid  = @{@"pid":self.productionID,@"status":@"done"};
    
    
    dispatch_group_enter(group);
    [manager  PUT:@"/api/video"
        parameters:paramsVid
           success:^(AFHTTPRequestOperation *operation, id responseObject) {
               dispatch_group_leave(group);
           }
           failure:^(AFHTTPRequestOperation *operation, NSError *error) {
               NSLog(@"Error: %@", error);
               dispatch_group_leave(group);
           }];
    
    dispatch_group_enter(group);
    [manager  PUT:@"/api/produce"
       parameters:paramsPid
          success:^(AFHTTPRequestOperation *operation, id responseObject) {
              dispatch_group_leave(group);
          }
          failure:^(AFHTTPRequestOperation *operation, NSError *error) {
              NSLog(@"Error: %@", error);
              dispatch_group_leave(group);
          }];
    
    
    
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        // Do whatever you need to do when all requests are finished
    });
}

- (void) addVideoToProduction:(NSDictionary*)dictionary{
    NSString *finalyToken = @"Bearer moqAbp7wY.7RdgIb8bm8xxJ8ytwETfwc";
    AFHTTPRequestOperationManager *manager =
    [[AFHTTPRequestOperationManager alloc]initWithBaseURL:[NSURL URLWithString:@"https://amplfy-me.appspot.com"]];
    [manager.requestSerializer setValue:finalyToken forHTTPHeaderField:@"Authorization"];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    [manager  POST:@"/api/produce/ref/video"
        parameters:dictionary
           success:^(AFHTTPRequestOperation *operation, id responseObject) {
               
               NSLog(@"start>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>");
               [self startRecordingReal];
           }
           failure:^(AFHTTPRequestOperation *operation, NSError *error) {
               NSLog(@"Error: %@", error);
           }];
    
}

- (void) reverseGeocodeStream:(KFStream*)stream {
    CLLocation *location = nil;
    CLLocation *endLocation = stream.endLocation;
    CLLocation *startLocation = stream.startLocation;
    if (startLocation) {
        location = startLocation;
    }
    if (endLocation) {
        location = endLocation;
    }
    if (!location) {
        return;
    }
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    [geocoder reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, NSError *error) {
        if (error) {
            DDLogError(@"Error geocoding stream: %@", error);
            return;
        }
        if (placemarks.count == 0) {
            return;
        }
        CLPlacemark *placemark = [placemarks firstObject];
        stream.city = placemark.locality;
        stream.state = placemark.administrativeArea;
        stream.country = placemark.country;
      
    }];
}

- (void) stopRecording {
    [self.locationManager stopUpdatingLocation];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (self.lastLocation) {

        }
//        [_session stopRunning];
        self.isRecording = NO;
        NSError *error = nil;
        [_hlsWriter finishWriting:&error];
        if (error) {
            DDLogError(@"Error stop recording: %@", error);
        }
        
       
        [[KFHLSMonitor sharedMonitor] finishUploadingContentsAtFolderPath:_hlsWriter.directoryPath];
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(recorderDidFinishRecording:error:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate recorderDidFinishRecording:self error:error];
            });
        }
    });
}

- (void) uploader:(KFHLSUploader *)uploader uploadSpeed:(double)uploadSpeed numberOfQueuedSegments:(NSUInteger)numberOfQueuedSegments {
    DDLogInfo(@"Uploaded segment  @ %f KB/s, numberOfQueuedSegments %lu", uploadSpeed, (unsigned long)numberOfQueuedSegments);
    if ([AmpKeys useAdaptiveBitrate]) {
        double currentUploadBitrate = uploadSpeed * 8 * 1024; // bps
        double maxBitrate = [AmpKeys maxBitrate];

        double newBitrate = currentUploadBitrate * 0.5;
        if (newBitrate > maxBitrate) {
            newBitrate = maxBitrate;
        }
        if (newBitrate < _minBitrate) {
            newBitrate = _minBitrate;
        }
        double newVideoBitrate = newBitrate - self.aacEncoder.bitrate;
        self.h264Encoder.bitrate = newVideoBitrate;
    }
}

- (void) uploader:(KFHLSUploader *)uploader liveManifestReadyAtURL:(NSURL *)manifestURL {
    if (self.delegate && [self.delegate respondsToSelector:@selector(recorder:streamReadyAtURL:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate recorder:self streamReadyAtURL:self.productionID];
        });
    }
    DDLogVerbose(@"Manifest ready at URL: %@", manifestURL);
}

- (void) locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    self.lastLocation = [locations lastObject];
    [self setStreamStartLocation];
}

- (void) setStreamStartLocation {
    if (!self.lastLocation) {
        return;
    }
}

@end

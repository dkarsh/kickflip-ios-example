//
//  VideoEncoder.m
//  Encoder Demo
//
//  Created by Geraint Davies on 14/01/2013.
//  Copyright (c) 2013 GDCL http://www.gdcl.co.uk/license.htm
//

#import "VideoEncoder.h"

@implementation VideoEncoder

@synthesize path = _path;

+ (VideoEncoder*) encoderForPath:(NSString*) path Height:(int) height andWidth:(int) width bitrate:(int)bitrate
{
    VideoEncoder* enc = [VideoEncoder alloc];
    [enc initPath:path Height:height andWidth:width bitrate:bitrate];
    return enc;
}


- (void) initPath:(NSString*)path Height:(int) height andWidth:(int) width bitrate:(int)bitrate
{
    self.path = path;
    _bitrate = bitrate;
    
    [[NSFileManager defaultManager] removeItemAtPath:self.path error:nil];
    NSURL* url = [NSURL fileURLWithPath:self.path];
    
    _writer = [AVAssetWriter assetWriterWithURL:url fileType:AVFileTypeQuickTimeMovie error:nil];
    NSDictionary* settings = @{
        AVVideoCodecKey: AVVideoCodecH264,
        AVVideoWidthKey: @(width),
        AVVideoHeightKey: @(height),
        AVVideoScalingModeKey: AVVideoScalingModeResizeAspectFill,
        AVVideoCompressionPropertiesKey: @{
             AVVideoAverageBitRateKey: @(self.bitrate),
             AVVideoMaxKeyFrameIntervalKey: @(150),
             AVVideoProfileLevelKey: AVVideoProfileLevelH264BaselineAutoLevel,
             AVVideoAllowFrameReorderingKey: @NO,
            
             //AVVideoH264EntropyModeKey: AVVideoH264EntropyModeCAVLC,
             //AVVideoExpectedSourceFrameRateKey: @(30),
             //AVVideoAverageNonDroppableFrameRateKey: @(30)
        }
        
    };
    
    
    
//    NSDictionary *videoCleanApertureSettings = [NSDictionary dictionaryWithObjectsAndKeys:
//                                                @720, AVVideoCleanApertureWidthKey,
//                                                @720, AVVideoCleanApertureHeightKey,
//                                                @10, AVVideoCleanApertureHorizontalOffsetKey,
//                                                @10, AVVideoCleanApertureVerticalOffsetKey,
//                                                nil];
//    
//    
//    NSDictionary *videoAspectRatioSettings = [NSDictionary dictionaryWithObjectsAndKeys:
//                                              @3, AVVideoPixelAspectRatioHorizontalSpacingKey,
//                                              @3,AVVideoPixelAspectRatioVerticalSpacingKey,
//                                              nil];
//    
//    
//    
//    NSDictionary *codecSettings = [NSDictionary dictionaryWithObjectsAndKeys:
//                                   [NSNumber numberWithInteger:self.bitrate], AVVideoAverageBitRateKey,
//                                   @1,AVVideoMaxKeyFrameIntervalKey,
//                                   videoCleanApertureSettings, AVVideoCleanApertureKey,
//                                   //AVVideoScalingModeFit,AVVideoScalingModeKey,
//                                   videoAspectRatioSettings, AVVideoPixelAspectRatioKey,
//                                   AVVideoProfileLevelH264BaselineAutoLevel,AVVideoProfileLevelKey,
//                                   @NO, AVVideoAllowFrameReorderingKey,
//                                   nil];
//    
//    NSDictionary *videoCompressionSettings = [NSDictionary dictionaryWithObjectsAndKeys:
//                                              AVVideoCodecH264, AVVideoCodecKey,
//                                              codecSettings,AVVideoCompressionPropertiesKey,
//                                              @720, AVVideoWidthKey,
//                                              @720, AVVideoHeightKey,
//                                              nil];
    
    
    _writerInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:settings];

    _writerInput.expectsMediaDataInRealTime = YES;
    [_writer addInput:_writerInput];
}

- (void) finishWithCompletionHandler:(void (^)(void))handler
{
    if (_writer.status == AVAssetWriterStatusWriting) {
        [_writer finishWritingWithCompletionHandler: handler];
    }
}

- (BOOL) encodeFrame:(CMSampleBufferRef) sampleBuffer
{
    if (CMSampleBufferDataIsReady(sampleBuffer))
    {
        if (_writer.status == AVAssetWriterStatusUnknown)
        {
            CMTime startTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
            [_writer startWriting];
            [_writer startSessionAtSourceTime:startTime];
        }
        if (_writer.status == AVAssetWriterStatusFailed)
        {
            NSLog(@"writer error %@", _writer.error.localizedDescription);
            return NO;
        }
        if (_writerInput.readyForMoreMediaData == YES)
        {
            [_writerInput appendSampleBuffer:sampleBuffer];
            return YES;
        }
    }
    return NO;
}

@end

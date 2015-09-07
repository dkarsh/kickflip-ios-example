//
//  KFHLSMonitor.h
//  FFmpegEncoder
//
//  Created by Christopher Ballinger on 1/16/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KFHLSUploader.h"


@interface KFHLSMonitor : NSObject <KFHLSUploaderDelegate>

+ (KFHLSMonitor*) sharedMonitor;

- (void) startMonitoringFolderPath:(NSString*)path delegate:(id<KFHLSUploaderDelegate>)delegate;
- (void) finishUploadingContentsAtFolderPath:(NSString*)path; //reclaims delegate of uploader

@end

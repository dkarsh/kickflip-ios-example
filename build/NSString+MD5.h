//
//  NSString+MD5.h
//  amplfy
//
//  Created by DKarsh on 8/28/15.
//  Copyright (c) 2015 Kickflip. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (MD5)
- (NSString*)MD5;
+(NSString*)randomStringWithLength: (int) len;
@end

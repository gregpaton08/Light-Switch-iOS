//
//  LSSwitchInfo.h
//  Light Switch
//
//  Created by Greg Paton on 12/6/15.
//  Copyright © 2015 Greg Paton. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LSSwitchInfo : NSObject <NSCoding>

@property NSString *title;
@property NSInteger tag;
@property BOOL status;
@property NSString *url;
@property NSInteger switchId;

@end

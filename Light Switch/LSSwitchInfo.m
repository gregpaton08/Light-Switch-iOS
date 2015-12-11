//
//  LSSwitchInfo.m
//  Light Switch
//
//  Created by Greg Paton on 12/6/15.
//  Copyright © 2015 Greg Paton. All rights reserved.
//

#import "LSSwitchInfo.h"

@implementation LSSwitchInfo

- (LSSwitchInfo*)init {
    self = [super init];
    if (self) {
        [self setTitle:[NSString alloc]];
        [self setTag:-1];
        [self setStatus:false];
        [self setUrl:[NSString alloc]];
        [self setSwitchId:-1];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:[self title] forKey:@"title"];
    [aCoder encodeInteger:[self tag] forKey:@"tag"];
    [aCoder encodeBool:[self status] forKey:@"status"];
    [aCoder encodeObject:[self url] forKey:@"url"];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        self.title = [aDecoder decodeObjectForKey:@"title"];
        self.tag = [aDecoder decodeIntegerForKey:@"tag"];
        self.status = [aDecoder decodeBoolForKey:@"status"];
        self.url = [aDecoder decodeObjectForKey:@"url"];
    }
    
    return self;
}

@end

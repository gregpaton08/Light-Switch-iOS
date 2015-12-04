//
//  LSSwitchTableViewCell.h
//  Light Switch
//
//  Created by Greg Paton on 11/30/15.
//  Copyright © 2015 Greg Paton. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LSSwitchTableViewCell : UITableViewCell <NSCoding>

@property UISwitch *cellSwitch;
@property SEL selector;


- (BOOL)getSwithState;
- (void)addAction:(SEL)action;
- (void)setTarget:(id)target action:(SEL)action;
+ (NSString*)getIdentifier;

@end

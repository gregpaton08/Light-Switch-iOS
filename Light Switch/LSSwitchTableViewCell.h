//
//  LSSwitchTableViewCell.h
//  Light Switch
//
//  Created by Greg Paton on 11/30/15.
//  Copyright © 2015 Greg Paton. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LSSwitchTableViewCell : UITableViewCell

@property NSString *label;

- (void)setCellLabel:(NSString*)label;
- (BOOL)getSwithState;
+ (NSString*)getIdentifier;

@end

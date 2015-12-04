//
//  LSSwitchTableViewCell.m
//  Light Switch
//
//  Created by Greg Paton on 11/30/15.
//  Copyright © 2015 Greg Paton. All rights reserved.
//

#import "LSSwitchTableViewCell.h"

@import UIKit;

@implementation LSSwitchTableViewCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

-(id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self) {
        [self setCellSwitch:[[UISwitch alloc] initWithFrame:CGRectZero]];
        [self setAccessoryView:[self cellSwitch]];
        
        [self setSelectionStyle:UITableViewCellSelectionStyleNone];
    }
    
    return self;
}

- (void)setTarget:(id)target action:(SEL)action {
    [[self cellSwitch] addTarget:target action:action forControlEvents:UIControlEventValueChanged];
}

- (void)setTag:(NSInteger)tag {
    [super setTag:tag];
    
    if ([self cellSwitch]) {
        [[self cellSwitch] setTag:tag];
    }
}

+ (NSString*)getIdentifier {
    return @"LSSwitchTableViewCellIdentifier";
}

@end

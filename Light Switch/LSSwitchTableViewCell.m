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
        UISwitch *cellSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
        [self setAccessoryView:cellSwitch];
        
        [self setSelectionStyle:UITableViewCellSelectionStyleNone];
    }
    
    return self;
}

- (void)setCellLabel:(NSString*)label {
    [self setLabel:label];
}

+ (NSString*)getIdentifier {
    return @"LSSwitchTableViewCellIdentifier";
}

@end

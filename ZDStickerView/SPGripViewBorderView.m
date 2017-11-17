//
//  SPGripViewBorderView.m
//
//  Created by Seonghyun Kim on 6/3/13.
//  Copyright (c) 2013 scipi. All rights reserved.
//
//  This file was modified from SPUserResizableView.

#import "SPGripViewBorderView.h"

@implementation SPGripViewBorderView


- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        // Clear background to ensure the content view shows through.
        self.backgroundColor = [UIColor clearColor];
        self.clipsToBounds = NO;
    }
    return self;
}

- (void)setBorderColor:(UIColor *)borderColor {
    _borderColor = borderColor;
    
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    
    CGContextSetLineWidth(context, 2.0);
    CGContextSetStrokeColorWithColor(context, self.borderColor.CGColor);
    CGContextAddRect(context, self.bounds);
    CGContextStrokePath(context);
    
    CGContextRestoreGState(context);
}

@end

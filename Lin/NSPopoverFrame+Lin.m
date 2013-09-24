//
//  NSPopoverFrame+Lin.m
//  Lin
//
//  Created by Tanaka Katsuma on 2013/09/21.
//  Copyright (c) 2013年 Tanaka Katsuma. All rights reserved.
//

#import "NSPopoverFrame+Lin.h"

#import "MethodSwizzle.h"

@implementation NSPopoverFrame (Lin)

+ (void)load
{
    MethodSwizzle(self, @selector(_drawMinimalPopoverAppearanceInRect:anchorEdge:anchorPoint:), @selector(_jp_questbeat_lin_drawMinimalPopoverAppearanceInRect:anchorEdge:anchorPoint:));
}

- (void)_jp_questbeat_lin_drawMinimalPopoverAppearanceInRect:(struct CGRect)arg1 anchorEdge:(unsigned long long)arg2 anchorPoint:(struct CGPoint)arg3
{
    [self _jp_questbeat_lin_drawMinimalPopoverAppearanceInRect:arg1 anchorEdge:arg2 anchorPoint:arg3];
    
    [[NSColor whiteColor] setFill];
    NSRectFill(arg1);
}

@end

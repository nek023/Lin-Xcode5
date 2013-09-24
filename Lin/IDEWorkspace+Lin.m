//
//  IDEWorkspace+Lin.m
//  Lin
//
//  Created by Tanaka Katsuma on 2013/08/24.
//  Copyright (c) 2013年 Tanaka Katsuma. All rights reserved.
//

#import "IDEWorkspace+Lin.h"

#import "MethodSwizzle.h"
#import "Lin.h"

@implementation IDEWorkspace (Lin)

+ (void)load
{
    MethodSwizzle(self, @selector(_updateIndexableFiles:), @selector(jp_questbeat_lin_updateIndexableFiles:));
}

- (void)jp_questbeat_lin_updateIndexableFiles:(id)arg1
{
    [self jp_questbeat_lin_updateIndexableFiles:arg1];
    
    [[Lin sharedPlugIn] indexNeedsUpdate:self.index];
}

@end

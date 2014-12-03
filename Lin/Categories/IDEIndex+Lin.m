//
//  IDEIndex+Lin.m
//  Lin
//
//  Created by Tanaka Katsuma on 2013/08/24.
//  Copyright (c) 2013年 Tanaka Katsuma. All rights reserved.
//

#import "IDEIndex+Lin.h"
#import "Lin.h"
#import <objc/objc-class.h>

static IMP __original_Method_Imp;

void _evo_lin_close_Method(id self, SEL _cmd) {
    [[Lin sharedPlugIn] removeLocalizationsForIndex:self];
    ((void(*)(id,SEL))__original_Method_Imp)(self, _cmd);
}

@implementation IDEIndex (Lin)

+ (void)load {
    Method m = class_getInstanceMethod(self, @selector(close));
    __original_Method_Imp = method_setImplementation(m, (IMP)_evo_lin_close_Method);
}

@end

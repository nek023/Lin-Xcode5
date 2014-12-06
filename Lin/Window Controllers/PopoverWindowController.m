//
//  LNPopoverWindowController.m
//  Lin
//
//  Created by Sascha Schwabbauer on 03/12/14.
//  Copyright (c) 2014 evolved.io. All rights reserved.
//

#import "PopoverWindowController.h"
#import "PopoverWindow.h"

@implementation PopoverWindowController

- (instancetype)initWithWindow:(NSWindow *)window {
    return [self initWithContentViewController:nil];
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    return [self initWithContentViewController:nil];
}

- (instancetype)initWithContentViewController:(NSViewController *)contentViewController {
    if ((self = [super initWithWindow:[PopoverWindow popoverWindow]])) {
        self.contentViewController = contentViewController;
    }
    
    return self;
}

@end

//
//  LNPopoverWindowController.m
//  Lin
//
//  Created by Tanaka Katsuma on 2013/09/20.
//  Copyright (c) 2013年 Tanaka Katsuma. All rights reserved.
//

#import "LNPopoverWindowController.h"

// Views
#import "LNPopoverWindow.h"

NSString * const LNPopoverWindowControllerWindowWillCloseNotification = @"LNPopoverWindowControllerWindowWillCloseNotification";

@implementation LNPopoverWindowController

- (instancetype)initWithPopoverContentViewController:(NSViewController *)popoverContentViewController
{
    LNPopoverWindow *popoverWindow = [LNPopoverWindow popoverWindow];
    popoverWindow.delegate = self;
    
    self = [super initWithWindow:popoverWindow];
    
    if (self) {
        self.popoverContentViewController = popoverContentViewController;
    }
    
    return self;
}


#pragma mark - Accessors

- (void)setPopoverContentViewController:(NSViewController *)popoverContentViewController
{
    // Remove previous content view
    if (self.popoverContentViewController) {
        [self.popoverContentViewController.view removeFromSuperview];
    }
    
    _popoverContentViewController = popoverContentViewController;
    
    // Set content view of the window
    self.popoverContentViewController.view.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    [self.window.contentView setFrame:self.popoverContentViewController.view.bounds];
    [self.window.contentView addSubview:self.popoverContentViewController.view];
}


#pragma mark - NSWindowDelegate

- (void)windowWillClose:(NSNotification *)notification
{
    // Post notification
    [[NSNotificationCenter defaultCenter] postNotificationName:LNPopoverWindowControllerWindowWillCloseNotification
                                                        object:self
                                                      userInfo:nil];
}

@end

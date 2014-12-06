//
//  PopoverWindowController.h
//  Lin
//
//  Created by Sascha Schwabbauer on 03/12/14.
//  Copyright (c) 2014 evolved.io. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface PopoverWindowController : NSWindowController

- (instancetype)initWithContentViewController:(NSViewController *)contentViewController NS_DESIGNATED_INITIALIZER;

@end

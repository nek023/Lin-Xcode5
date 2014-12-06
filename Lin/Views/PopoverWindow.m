//
//  PopoverWindow.m
//  Lin
//
//  Created by Sascha Schwabbauer on 03/12/14.
//  Copyright (c) 2014 evolved.io. All rights reserved.
//

#import "PopoverWindow.h"
#import "PopoverWindowController.h"
#import "MainViewController.h"

static NSString * const kEVOPopoverWindowToolbarSearchFieldIdentifier = @"Search";

@interface PopoverWindow () <NSToolbarDelegate, NSTextFieldDelegate>

@property (nonatomic, strong) NSSearchField *searchField;

@end

@implementation PopoverWindow

#pragma mark - Public API

+ (instancetype)popoverWindow {
    PopoverWindow *popoverWindow = [[PopoverWindow alloc] initWithContentRect:NSZeroRect styleMask:(NSTitledWindowMask | NSClosableWindowMask | NSResizableWindowMask) backing:NSBackingStoreBuffered defer:NO];
    popoverWindow.title = @"Lin";
    popoverWindow.level = NSFloatingWindowLevel;
    popoverWindow.backgroundColor = [NSColor whiteColor];
    [popoverWindow.contentView setAutoresizesSubviews:YES];
    
    return popoverWindow;
}

#pragma mark - Initializers

- (instancetype)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag {
    if ((self = [super initWithContentRect:contentRect styleMask:aStyle backing:bufferingType defer:flag])) {
        // Create toolbar
        NSToolbar *toolbar = [[NSToolbar alloc] initWithIdentifier:@"Toolbar"];
        toolbar.delegate = self;
        toolbar.displayMode = NSToolbarDisplayModeIconOnly;
        
        self.toolbar = toolbar;
    }
    
    return self;
}

#pragma mark - Actions

- (void)searchTextDidChange:(NSNotification *)note {
    if (![self.searchField.stringValue isEqual:note.object]) {
        self.searchField.stringValue = note.object;
    }
}

- (void)textFieldDidReturn:(id)sender {
    [self controlTextDidChange:nil];
}

#pragma mark - NSToolbarDelegate

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar {
    return @[NSToolbarFlexibleSpaceItemIdentifier, kEVOPopoverWindowToolbarSearchFieldIdentifier];
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar {
    return @[NSToolbarFlexibleSpaceItemIdentifier, kEVOPopoverWindowToolbarSearchFieldIdentifier];
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag {
    NSToolbarItem *toolbarItem = nil;
    
    if ([itemIdentifier isEqualToString:kEVOPopoverWindowToolbarSearchFieldIdentifier]) {
        toolbarItem = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
        
        NSSearchField *searchField = [[NSSearchField alloc] init];
        searchField.delegate = self;
        searchField.target = self;
        searchField.action = @selector(textFieldDidReturn:);
        
        toolbarItem.view = searchField;
        self.searchField = searchField;
    }
    
    return toolbarItem;
}


#pragma mark - NSTextFieldDelegate

- (void)controlTextDidChange:(NSNotification *)obj {
    PopoverWindowController *popoverWindowController = (PopoverWindowController *)self.windowController;
    MainViewController *mainViewController = (MainViewController *)popoverWindowController.contentViewController;
    
    mainViewController.searchString = self.searchField.stringValue;
}

@end

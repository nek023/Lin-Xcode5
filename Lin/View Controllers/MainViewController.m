//
//  MainViewController.m
//  Lin
//
//  Created by Sascha Schwabbauer on 03/12/14.
//  Copyright (c) 2014 evolved.io. All rights reserved.
//

#import "MainViewController.h"
#import "LNLocalizationCollection.h"
#import "LNLocalization.h"
#import "AddViewController.h"

NSString * const LNPopoverContentViewLocalizationKey = @"LNPopoverContentViewLocalizationKey";

NSString * const LNPopoverContentViewLocalizationDidSelectNotification = @"LNPopoverContentViewRowDidDoubleClickNotification";
NSString * const LNPopoverContentViewDetachButtonDidClickNotification = @"LNPopoverContentViewDetachButtonDidClickNotification";

static NSString * const EVOPopoverContentViewCellReuseIdentifier = @"EVOPopoverContentViewCellReuseIdentifier";

@interface MainViewController () <NSTableViewDataSource, NSTableViewDelegate, AddViewControllerDelegate>

@property (nonatomic, weak) IBOutlet NSTableView *tableView;
@property (nonatomic, weak) IBOutlet NSButton *detachButton;

@property (nonatomic, strong) NSMutableArray *localizations;
@property (nonatomic, strong) NSMutableArray *sortedLocalizations;

@end

@implementation MainViewController

#pragma mark - NSViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Set default sort order
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"key" ascending:YES selector:@selector(compare:)];
    [self.tableView setSortDescriptors:@[sortDescriptor]];
    
    self.tableView.target = self;
    self.tableView.doubleAction = @selector(doubleClickedTableView:);
    
    [self configureForPresentationInPopover:self.isInPopover];
    [self configureView];
}

- (void)dealloc {
    // Remove from notification center
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Helper methods

- (void)configureForPresentationInPopover:(BOOL)inPopover {
    if (inPopover) {
        self.tableView.selectionHighlightStyle = NSTableViewSelectionHighlightStyleSourceList;
    } else {
        self.detachButton.hidden = YES;
    }
}

#pragma mark - Accessors

- (void)setInPopover:(BOOL)inPopover {
    if (_inPopover != inPopover) {
        _inPopover = inPopover;
        
        if (self.isViewLoaded) {
            [self configureForPresentationInPopover:_inPopover];
        }
    }
}

- (void)setCollections:(NSArray *)collections {
    if (![_collections isEqual:collections]) {
        _collections = collections;
        
        if (self.isViewLoaded) {
            [self configureView];
        }
    }
}

- (void)setSearchString:(NSString *)searchString {
    if (![_searchString isEqualToString:searchString]) {
        _searchString = searchString;
        
        if (self.isViewLoaded) {
            [self configureView];
        }
    }
}

#pragma mark - Actions

- (IBAction)textChanged:(id)sender {
    NSInteger editedRowIndex = [self.tableView rowForView:sender];
    NSInteger editedColumnIndex = [self.tableView columnForView:sender];
    
    if (editedRowIndex >= 0 && editedColumnIndex >= 0) {
        NSTextField *textField = (NSTextField *)sender;
        
        // Create a new localization
        LNLocalization *localization = self.sortedLocalizations[editedRowIndex];
        
        NSString *key = localization.key;
        NSString *value = localization.value;
        
        NSTableColumn *editedColumn = self.tableView.tableColumns[editedColumnIndex];
        
        if ([editedColumn.identifier isEqualToString:@"key"]) {
            key = textField.stringValue;
        } else if ([editedColumn.identifier isEqualToString:@"value"]) {
            value = textField.stringValue;
        }
        
        LNLocalization *newLocalization = [LNLocalization localizationWithKey:key value:value entityRange:localization.entityRange keyRange:localization.keyRange valueRange:localization.valueRange collection:localization.collection];
        
        // Replace in file
        [localization.collection replaceLocalization:localization withLocalization:newLocalization];
        
        // Update
        [self configureView];
    }
}

- (void)doubleClickedTableView:(id)sender {
    NSInteger clickedRow = self.tableView.clickedRow;
    
    if (clickedRow >= 0) {
        LNLocalization *localization = self.sortedLocalizations[clickedRow];
        
        // Post notification
        [[NSNotificationCenter defaultCenter] postNotificationName:LNPopoverContentViewLocalizationDidSelectNotification object:self userInfo:@{LNPopoverContentViewLocalizationKey: localization}];
    }
}

- (IBAction)addLocalization:(id)sender {
    // Create alert
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    AddViewController *addViewController = [[AddViewController alloc] initWithNibName:@"AddViewController" bundle:bundle];
    addViewController.delegate = self;
    addViewController.collections = self.collections;
    
    [self presentViewController:addViewController asPopoverRelativeToRect:((NSView *)sender).bounds ofView:sender preferredEdge:NSMinYEdge behavior:NSPopoverBehaviorTransient];
}

- (IBAction)deleteLocalization:(id)sender {
    NSInteger selectedRow = self.tableView.selectedRow;
    
    if (selectedRow >= 0) {
        [self.tableView beginUpdates];
        
        // Delete localization from array
        LNLocalization *localization = self.sortedLocalizations[selectedRow];
        NSInteger index = [self.localizations indexOfObject:localization];
        [self.localizations removeObjectAtIndex:index];
        
        // Filter localizations
        [self filterLocalizations];
        
        // Delete localization from file
        LNLocalizationCollection *collection = localization.collection;
        [collection deleteLocalization:localization];
        
        // Delete localization from table view
        [self.tableView removeRowsAtIndexes:[NSIndexSet indexSetWithIndex:selectedRow] withAnimation:NSTableViewAnimationEffectFade];
        
        [self.tableView endUpdates];
    }
}

- (IBAction)detachPopover:(id)sender {
    // Post notification
    [[NSNotificationCenter defaultCenter] postNotificationName:LNPopoverContentViewDetachButtonDidClickNotification object:self userInfo:nil];
}

#pragma mark - Updating and Drawing the View

- (void)reloadLocalizations {
    NSMutableArray *localizations = [NSMutableArray array];
    
    for (LNLocalizationCollection *collection in self.collections) {
        [localizations addObjectsFromArray:[collection.localizations allObjects]];
    }
    
    self.localizations = localizations;
}

- (void)filterLocalizations {
    // Filter localizations
    NSArray *filteredLocalizations = self.localizations;
    
    if (self.searchString.length > 0) {
        filteredLocalizations = [filteredLocalizations filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"key contains[c] %@", self.searchString]];
    }
    
    // Sort localizations
    self.sortedLocalizations = [[filteredLocalizations sortedArrayUsingDescriptors:self.tableView.sortDescriptors] mutableCopy];
}

- (void)configureView {
    // Reload localizations
    [self reloadLocalizations];
    
    // Filter localizations
    [self filterLocalizations];
    
    // Update table view
    [self.tableView reloadData];
}


#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return self.sortedLocalizations.count;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    NSTableCellView *cell = [tableView makeViewWithIdentifier:EVOPopoverContentViewCellReuseIdentifier owner:self];
    
    NSString *identifier = tableColumn.identifier;
    
    LNLocalization *localization = self.sortedLocalizations[row];
    
    if([identifier isEqualToString:@"table"]) {
        cell.textField.stringValue = localization.collection.filePath.lastPathComponent;
        cell.textField.editable = NO;
    }
    else if ([identifier isEqualToString:@"language"]) {
        cell.textField.stringValue = localization.collection.languageDesignation;
        cell.textField.editable = NO;
    }
    else if ([identifier isEqualToString:@"key"]) {
        cell.textField.stringValue = localization.key;
        cell.textField.editable = YES;
    }
    else if ([identifier isEqualToString:@"value"]) {
        cell.textField.stringValue = localization.value;
        cell.textField.editable = YES;
    }
    
    return cell;
}

- (void)tableView:(NSTableView *)tableView sortDescriptorsDidChange:(NSArray *)oldDescriptors {
    // Update
    [self configureView];
}

#pragma mark - AddViewControllerDelegate

- (void)addViewControllerDidCancel:(AddViewController *)addViewController {
    [self dismissViewController:addViewController];
}

- (void)addViewController:(AddViewController *)addViewController didFinishWithLocalization:(LNLocalization *)localization forCollection:(LNLocalizationCollection *)collection {
    // Add localization to file
    [collection addLocalization:localization];
    
    // Update views
    [self configureView];
    
    [self dismissViewController:addViewController];
}

@end

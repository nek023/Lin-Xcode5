//
//  MainViewController.m
//  Lin
//
//  Created by Sascha Schwabbauer on 03/12/14.
//  Copyright (c) 2014 evolved.io. All rights reserved.
//

#import "MainViewController.h"

// Models
#import "LNLocalizationCollection.h"
#import "LNLocalization.h"

// Views
#import "LNAlertAccessoryView.h"

NSString * const LNPopoverContentViewLocalizationKey = @"LNPopoverContentViewLocalizationKey";

NSString * const LNPopoverContentViewLocalizationDidSelectNotification = @"LNPopoverContentViewRowDidDoubleClickNotification";
NSString * const LNPopoverContentViewAlertDidDismissNotification = @"LNPopoverContentViewAlertDidDismissNotification";
NSString * const LNPopoverContentViewDetachButtonDidClickNotification = @"LNPopoverContentViewDetachButtonDidClickNotification";

static NSString * const EVOPopoverContentViewCellReuseIdentifier = @"EVOPopoverContentViewCellReuseIdentifier";

@interface MainViewController () <NSTableViewDataSource, NSTableViewDelegate>

@property (nonatomic, weak, readwrite) IBOutlet NSTableView *tableView;
@property (nonatomic, weak, readwrite) IBOutlet NSButton *detachButton;

@property (nonatomic, strong) NSMutableArray *localizations;
@property (nonatomic, strong) NSMutableArray *sortedLocalizations;

- (IBAction)addLocalization:(id)sender;
- (IBAction)deleteLocalization:(id)sender;
- (IBAction)detachPopover:(id)sender;

@end

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Set default sort order
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"key" ascending:YES selector:@selector(compare:)];
    [self.tableView setSortDescriptors:@[sortDescriptor]];
    
    self.tableView.target = self;
    self.tableView.doubleAction = @selector(doubleClickedTableView:);
}

- (void)dealloc {
    // Remove from notification center
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - Accessors

- (void)setCollections:(NSArray *)collections {
    if (![_collections isEqual:collections]) {
        _collections = collections;
        
        [self configureView];
    }
}

- (void)setSearchString:(NSString *)searchString {
    if (![_searchString isEqualToString:searchString]) {
        _searchString = searchString;
        
        [self configureView];
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
    NSViewController *viewController = [[NSViewController alloc] initWithNibName:@"LNAlertAccessoryView" bundle:bundle];
    LNAlertAccessoryView *accessoryView = (LNAlertAccessoryView *)viewController.view;
    accessoryView.collections = self.collections;
    
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"Lin";
    [alert addButtonWithTitle:@"OK"];
    [alert addButtonWithTitle:@"Cancel"];
    alert.informativeText = @"Input a key/value for a new localization.";
    alert.accessoryView = accessoryView;
    
    NSButton *button = [alert buttons][0];
    accessoryView.button = button;
    
    // Set icon
    NSString *filePath = [bundle pathForResource:@"icon120" ofType:@"tiff"];
    NSImage *icon = [[NSImage alloc] initWithContentsOfFile:filePath];
    [alert setIcon:icon];
    
    // Show alert
    switch ([alert runModal]) {
        case NSAlertFirstButtonReturn:
        {
            // Create a new localization
            LNAlertAccessoryView *accessoryView = (LNAlertAccessoryView *)alert.accessoryView;
            
            LNLocalizationCollection *collection = accessoryView.selectedCollection;
            NSString *key = accessoryView.inputtedKey;
            NSString *value = accessoryView.inputtedValue;
            
            LNLocalization *localization = [LNLocalization localizationWithKey:key
                                                                         value:value
                                                                   entityRange:NSMakeRange(NSNotFound, 0)
                                                                      keyRange:NSMakeRange(NSNotFound, 0)
                                                                    valueRange:NSMakeRange(NSNotFound, 0)
                                                                    collection:collection];
            
            // Add localization to file
            [collection addLocalization:localization];
            
            // Update
            [self configureView];
        }
            
        default:
        {
            // Post notification
            [[NSNotificationCenter defaultCenter] postNotificationName:LNPopoverContentViewAlertDidDismissNotification
                                                                object:self
                                                              userInfo:nil];
        }
            break;
    }
}

- (IBAction)deleteLocalization:(id)sender {
    NSInteger selectedRow = [self.tableView selectedRow];
    
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

@end

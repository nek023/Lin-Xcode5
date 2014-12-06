//
//  AddViewController.m
//  Lin
//
//  Created by Sascha Schwabbauer on 06/12/14.
//  Copyright (c) 2014 evolved.io. All rights reserved.
//

#import "AddViewController.h"
#import "LNLocalization.h"
#import "LNLocalizationCollection.h"

@interface AddViewController () <NSTextFieldDelegate>

@property (nonatomic, weak) IBOutlet NSPopUpButton *tableButton;
@property (nonatomic, weak) IBOutlet NSPopUpButton *languageButton;
@property (nonatomic, weak) IBOutlet NSTextField *keyTextField;
@property (nonatomic, weak) IBOutlet NSTextField *valueTextField;
@property (nonatomic, weak) IBOutlet NSButton *okButton;

@end

@implementation AddViewController

#pragma mark - Accessors

- (void)setCollections:(NSArray *)collections {
    if (![_collections isEqual:collections]) {
        _collections = collections;
        
        if (self.isViewLoaded) {
            [self configureView];
        }
    }
}

#pragma mark - NSViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self configureView];
}

#pragma mark - Helpers

- (LNLocalizationCollection *)collectionForCurrentSelection {
    NSString *selectedFileName = [self.tableButton titleOfSelectedItem];
    NSString *selectedLanguageDesignations = [self.languageButton titleOfSelectedItem];
    
    for (LNLocalizationCollection *collection in self.collections) {
        if ([collection.fileName isEqualToString:selectedFileName] && [collection.languageDesignation isEqualToString:selectedLanguageDesignations]) {
            return collection;
        }
    }
    
    return nil;
}

#pragma mark - Actions

- (IBAction)tableDidChange:(id)sender {
    [self updateLanguages];
}

- (IBAction)okPressed:(id)sender {
    LNLocalizationCollection *collection = [self collectionForCurrentSelection];
    NSString *key = self.keyTextField.stringValue;
    NSString *value = self.valueTextField.stringValue;
    
    LNLocalization *localization = [LNLocalization localizationWithKey:key value:value entityRange:NSMakeRange(NSNotFound, 0) keyRange:NSMakeRange(NSNotFound, 0) valueRange:NSMakeRange(NSNotFound, 0) collection:collection];
    
    if (self.delegate) {
        [self.delegate addViewController:self didFinishWithLocalization:localization forCollection:collection];
    }
}

- (IBAction)cancelPressed:(id)sender {
    if (self.delegate) {
        [self.delegate addViewControllerDidCancel:self];
    }
}

#pragma mark - Updating the Views

- (void)updateTables {
    [self.tableButton removeAllItems];
    
    NSMutableSet *tableFileNames = [NSMutableSet set];
    for (LNLocalizationCollection *collection in self.collections) {
        [tableFileNames addObject:collection.fileName];
    }
    
    [self.tableButton addItemsWithTitles:[tableFileNames allObjects]];
}

- (void)updateLanguages {
    [self.languageButton removeAllItems];
    
    NSString *titleOfSelectedItem = [self.tableButton titleOfSelectedItem];
    
    NSMutableSet *languageDesignations = [NSMutableSet set];
    for (LNLocalizationCollection *collection in self.collections) {
        if ([titleOfSelectedItem isEqualToString:collection.fileName]) {
            [languageDesignations addObject:collection.languageDesignation];
        }
    }
    
    [self.languageButton addItemsWithTitles:[languageDesignations allObjects]];
}

- (void)configureView {
    [self updateTables];
    [self updateLanguages];
    
    [self configureButton];
}

- (void)configureButton {
    NSString *key = self.keyTextField.stringValue;
    NSString *value = self.valueTextField.stringValue;
    
    [self.okButton setEnabled:(self.collections.count > 0 && key.length > 0 && value.length > 0)];
}


#pragma mark - NSTextFieldDelegate

- (void)controlTextDidChange:(NSNotification *)obj {
    [self configureButton];
}

@end

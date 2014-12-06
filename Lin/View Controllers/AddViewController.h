//
//  AddViewController.h
//  Lin
//
//  Created by Sascha Schwabbauer on 06/12/14.
//  Copyright (c) 2014 evolved.io. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class LNLocalizationCollection;
@class LNLocalization;
@class AddViewController;

@protocol AddViewControllerDelegate <NSObject>

- (void)addViewControllerDidCancel:(AddViewController *)addViewController;
- (void)addViewController:(AddViewController *)addViewController didFinishWithLocalization:(LNLocalization *)localization forCollection:(LNLocalizationCollection *)collection;

@end

@interface AddViewController : NSViewController

@property (nonatomic, weak) id<AddViewControllerDelegate> delegate;
@property (nonatomic, copy) NSArray *collections;

@end

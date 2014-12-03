//
//  NSTableView+EditedColumnIdentifier.m
//  Lin
//
//  Created by Tanaka Katsuma on 2013/09/22.
//  Copyright (c) 2013年 Tanaka Katsuma. All rights reserved.
//

#import "NSTableView+EditedColumnIdentifier.h"

@implementation NSTableView (EditedColumnIdentifier)

- (NSString *)evo_editedColumnIdentifier {
    NSInteger editedColumnIndex = [self editedColumn];
    
    NSArray *tableColumns = [self tableColumns];
    for (NSInteger i = 0; i < tableColumns.count; i++) {
        NSTableColumn *column = tableColumns[i];
        
        if (i == editedColumnIndex) {
            return column.identifier;
        }
    }
    
    return nil;
}

@end

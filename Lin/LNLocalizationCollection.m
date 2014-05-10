//
//  LNLocalizationCollection.m
//  Lin
//
//  Created by Tanaka Katsuma on 2013/08/23.
//  Copyright (c) 2013年 Tanaka Katsuma. All rights reserved.
//

#import "LNLocalizationCollection.h"

// Models
#import "LNLocalization.h"

@interface LNLocalizationCollection ()

@property (nonatomic, copy, readwrite) NSString *filePath;
@property (nonatomic, copy, readwrite) NSString *languageDesignation;

@property (nonatomic, strong, readwrite) NSMutableSet *localizations;

@end

@implementation LNLocalizationCollection

+ (instancetype)localizationCollectionWithContentsOfFile:(NSString *)filePath
{
    return [[self alloc] initWithContentsOfFile:filePath];
}

- (instancetype)initWithContentsOfFile:(NSString *)filePath
{
    self = [super init];
    
    if (self) {
        self.filePath = filePath;
        
        // Extract language designation
        NSArray *pathComponents = [filePath pathComponents];
        self.languageDesignation = [[pathComponents objectAtIndex:pathComponents.count - 2] stringByDeletingPathExtension];
        
        // Update
        [self reloadLocalizations];
    }
    
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:
            @"<%@: %p; filePath = %@; languageDesignation = %@; localizations = %@>",
            NSStringFromClass([self class]),
            self,
            self.filePath,
            self.languageDesignation,
            self.localizations
            ];
}


#pragma mark - Accessors

- (NSString *)fileName
{
    return [self.filePath lastPathComponent];
}


#pragma mark - Managing Localizations

- (NSString *)loadContentsOfFile:(NSString *)filePath
{
	NSError *error = nil;
    NSStringEncoding encoding = NSUTF8StringEncoding;
    NSString *contents = [NSString stringWithContentsOfURL:[NSURL fileURLWithPath:self.filePath]
                                              usedEncoding:&encoding
                                                     error:&error];
    
    if (error) {
        NSLog(@"Error: %@", [error localizedDescription]);
        
        return nil;
    }
    
    return contents;
}

- (void)reloadLocalizations
{
    // Load contents
    NSString *contents = [self loadContentsOfFile:self.filePath];
    
    if (contents) {
        NSMutableSet *localizations = [NSMutableSet set];
        
        NSRegularExpression *regularExpression = [NSRegularExpression regularExpressionWithPattern:
                                                  @"(?#key   )(?:\"(.*)\"|(\\S+))"
                                                  @"(?#equals)\\s*=\\s*"
                                                  @"(?#value )\"(.*)\";"
                                                                                           options:0
                                                                                             error:nil];
        
        [regularExpression enumerateMatchesInString:contents options:0 range:NSMakeRange(0, [contents length]) usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
            NSRange entityRange = [result rangeAtIndex:0];
            NSRange keyRange    = [result rangeAtIndex:1].location != NSNotFound ? [result rangeAtIndex:1] : [result rangeAtIndex:2];
            NSRange valueRange  = [result rangeAtIndex:3];
            
            [localizations addObject:[LNLocalization localizationWithKey:[contents substringWithRange:keyRange]
                                                                   value:[contents substringWithRange:valueRange]
                                                             entityRange:entityRange
                                                                keyRange:keyRange
                                                              valueRange:valueRange
                                                              collection:self]];
        }];
        
        self.localizations = localizations;
    } else {
        self.localizations = nil;
    }
}

- (void)addLocalization:(LNLocalization *)localization
{
    // Load contents
    NSString *contents = [self loadContentsOfFile:self.filePath];
    
    // Add
    if (![contents hasSuffix:@"\n"]) {
        contents = [contents stringByAppendingString:@"\n"];
    }
    
    contents = [contents stringByAppendingFormat:@"\"%@\" = \"%@\";\n", localization.key, localization.value];
    
    // Override
    NSError *error = nil;
    [contents writeToFile:self.filePath atomically:NO encoding:NSUTF8StringEncoding error:&error];
    
    if (error) {
        NSLog(@"Error: %@", [error localizedDescription]);
    }
    
    // Reload
    [self reloadLocalizations];
}

- (void)deleteLocalization:(LNLocalization *)localization
{
    // Load contents
    NSString *contents = [self loadContentsOfFile:self.filePath];
    
    // Delete line
    NSRange lineRange = [contents lineRangeForRange:localization.entityRange];
    contents = [contents stringByReplacingCharactersInRange:lineRange withString:@""];
    
    // Override
    NSError *error = nil;
    [contents writeToFile:self.filePath atomically:NO encoding:NSUTF8StringEncoding error:&error];
    
    if (error) {
        NSLog(@"Error: %@", [error localizedDescription]);
    }
    
    // Reload
    [self reloadLocalizations];
}

- (void)replaceLocalization:(LNLocalization *)localization withLocalization:(LNLocalization *)newLocalization
{
    // Load contents
    NSString *contents = [self loadContentsOfFile:self.filePath];
    
    // Replace
    NSString *newEntity = [NSString stringWithFormat:@"\"%@\" = \"%@\";", newLocalization.key, newLocalization.value];
    contents = [contents stringByReplacingCharactersInRange:localization.entityRange withString:newEntity];
    
    // Override
    NSError *error = nil;
    [contents writeToFile:self.filePath atomically:NO encoding:NSUTF8StringEncoding error:&error];
    
    if (error) {
        NSLog(@"Error: %@", [error localizedDescription]);
    }
    
    // Reload
    [self reloadLocalizations];
}

@end

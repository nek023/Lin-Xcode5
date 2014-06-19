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
        // The superdir is shown in parentheses to distinguish possible duplicate name-language combos
        self.languageDesignation = [NSString stringWithFormat:@"%@ (%@)",
                                    [[pathComponents objectAtIndex:pathComponents.count - 2] stringByDeletingPathExtension],
                                    [pathComponents objectAtIndex:pathComponents.count - 3]];
        
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
        
        // to keep it simple for now comments are only accepted if
        //   * the comment is C-style
        //   * the comment is on the line above the key-value
        //   * the comment is followed by no whitespace except one new line
        //   * the key-value line is not prefixed with any whitespace
        // this can be changed later on when time allows :)
        // example found below:        
        //               v - no whitespace here except newline
        // /* Comment */
        // @"key" = @"value";
        // ^ - no whitespace here
        
        NSRegularExpression *regularExpression = [NSRegularExpression regularExpressionWithPattern:
                                                  @"(?#comment)(?:/\\*(.*)\\*/\n)?"
                                                  @"(?#key    )(?:\"(.*)\"|(\\S+))"
                                                  @"(?#equals )\\s*=\\s*"
                                                  @"(?#value  )\"(.*)\";"
                                                                                           options:0
                                                                                             error:nil];
        
        [regularExpression enumerateMatchesInString:contents options:0 range:NSMakeRange(0, [contents length]) usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
            NSString *comment = nil;
            
            NSRange entityRange  = [result rangeAtIndex:0];
            NSRange commentRange = [result rangeAtIndex:1];
            NSRange keyRange     = [result rangeAtIndex:2].location != NSNotFound ? [result rangeAtIndex:2] : [result rangeAtIndex:3];
            NSRange valueRange   = [result rangeAtIndex:4];
            
            if (commentRange.location != NSNotFound)
                comment = [contents substringWithRange:commentRange];
            
            [localizations addObject:[LNLocalization localizationWithKey:[contents substringWithRange:keyRange]
                                                                   value:[contents substringWithRange:valueRange]
                                                                 comment:comment
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

- (NSString *)formatEntity:(LNLocalization *)localization
{
    NSString *comment = @"";
    
    if (localization.comment && [localization.comment length] > 0) {
        // Add spaces at the ends if needed
        NSString *prefix = [localization.comment hasPrefix:@" "] ? @"" : @" ";
        NSString *suffix = [localization.comment hasSuffix:@" "] ? @"" : @" ";
        
        comment = [NSString stringWithFormat:@"/*%@%@%@*/\n", prefix, localization.comment, suffix];
    }
    
    return [NSString stringWithFormat:@"%@\"%@\" = \"%@\";", comment, localization.key, localization.value];
}

- (void)writeContents:(NSString *)contents withRange:(NSRange)range replacedWithString:(NSString *)string
{
    // Override
    NSError *error = nil;
    [[contents stringByReplacingCharactersInRange:range withString:string] writeToFile:self.filePath atomically:NO encoding:NSUTF8StringEncoding error:&error];
    
    if (error) {
        NSLog(@"Error: %@", [error localizedDescription]);
    }

    // Reload
    [self reloadLocalizations];
}

- (void)addLocalization:(LNLocalization *)localization
{
    // Load contents
    NSString *contents = [self loadContentsOfFile:self.filePath];
    __block NSRange range = NSMakeRange([contents length], 0); // Starting point if no trailing white space found
    
    NSRegularExpression *regularExpression = [NSRegularExpression regularExpressionWithPattern:
                                              @"(?#capture trailing whitespace)(\\s+)$"
                                                                                       options:0
                                                                                         error:nil];
    
    [regularExpression enumerateMatchesInString:contents options:0 range:NSMakeRange(0, [contents length]) usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
        range = [result rangeAtIndex:1];
    }];
    
    [self writeContents:contents withRange:range replacedWithString:[NSString stringWithFormat:@"\n\n%@\n", [self formatEntity:localization]]];
}

- (void)deleteLocalization:(LNLocalization *)localization
{
    NSCharacterSet *whitespace = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    
    // Load contents
    NSString *contents = [self loadContentsOfFile:self.filePath];
    
    NSRange range = localization.entityRange; // Starting point
    
    // Expand range left if whitespace is present
    while (range.location > 0 && [whitespace characterIsMember:[contents characterAtIndex:range.location - 1]]) {
        range.location--;
        range.length++;
    }
    
    // Expand range right if whitespace is present
    while (NSMaxRange(range) < [contents length] && [whitespace characterIsMember:[contents characterAtIndex:NSMaxRange(range)]]) {
        range.length++;
    }
    
    [self writeContents:[self loadContentsOfFile:self.filePath] withRange:range replacedWithString:@"\n\n"];
}

- (void)replaceLocalization:(LNLocalization *)localization withLocalization:(LNLocalization *)newLocalization
{
    [self writeContents:[self loadContentsOfFile:self.filePath] withRange:localization.entityRange replacedWithString:[self formatEntity:newLocalization]];
}

@end

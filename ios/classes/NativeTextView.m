//
//  NativeTextView.m
//  flutter_native_text_view
//
//  Created by Henry Leung on 30/11/2021.
//

#import "NativeTextView.h"
#import "NativeTextViewDelegate.h"

@implementation NativeTextView {
    UITextView* _textView;
    
    int64_t _viewId;
    FlutterMethodChannel* _channel;
    NativeTextViewDelegate* _delegate;
    
    float _containerWidth;
}

- (instancetype)initWithFrame:(CGRect)frame
               viewIdentifier:(int64_t)viewId
                    arguments:(id _Nullable)args
              binaryMessenger:(NSObject<FlutterBinaryMessenger>*)messenger {
    
    if ([super init]) {
        NSString* channelName = [NSString stringWithFormat:@"flutter_native_text_view%lld", viewId];
        _channel = [FlutterMethodChannel methodChannelWithName:channelName binaryMessenger:messenger];
        
        _viewId = viewId;
        
        _textView = [[UITextView alloc] initWithFrame:frame];
        _textView.backgroundColor = UIColor.clearColor;
        _textView.textAlignment = [self textAlignmentFromString:args[@"textAlign"]];
        _textView.textContainer.maximumNumberOfLines = [args[@"maxLines"] intValue];
        _textView.textContainer.lineBreakMode = NSLineBreakByCharWrapping;
        // Enable text selection
        // Set isSelectable from params
        // Check if 'isSelectable' is provided, default to true if not
        BOOL isSelectable = args[@"isSelectable"] ? [args[@"isSelectable"] boolValue] : YES;
        _textView.selectable = isSelectable;

        // Adjust scrolling based on text content and available space
        CGFloat contentHeight = [_textView sizeThatFits:CGSizeMake(frame.size.width, MAXFLOAT)].height;
        _textView.scrollEnabled = contentHeight > frame.size.height;

        // Optional: Set editable to false if you don't want users to edit the text
        [_textView setEditable:FALSE];

        // Remove padding
        _textView.textContainerInset = UIEdgeInsetsZero;
        _textView.textContainer.lineFragmentPadding = 0;

        if (args[@"fontSize"]) {
            CGFloat fontSize = [args[@"fontSize"] floatValue];
            _textView.font = [UIFont systemFontOfSize:fontSize];
        }
        
        _delegate = [[NativeTextViewDelegate alloc] initWithChannel:_channel arguments:args ];
        _textView.delegate = _delegate;
        
        if (![args[@"text"] isEqualToString:@""]) {
            _textView.text = args[@"text"];
            _textView.textColor = _delegate.fontColor;
            _textView.font = _delegate.font;
        }
        
        _containerWidth = [args[@"width"] floatValue];
        
        __weak __typeof__(self) weakSelf = self;
        [_channel setMethodCallHandler:^(FlutterMethodCall* call, FlutterResult result) {
            [weakSelf onMethodCall:call result:result];
        }];
    }
    return self;
}

- (void)onMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if ([[call method] isEqualToString:@"getContentHeight"]) {
        CGSize boundSize = CGSizeMake(_containerWidth, MAXFLOAT);
        CGSize size = [_textView sizeThatFits: boundSize];
        
        result([NSNumber numberWithFloat: size.height]);
    }
    if ([[call method] isEqualToString:@"getLineHeight"]) {
        result([NSNumber numberWithFloat: _textView.font.lineHeight]);
    } else if ([[call method] isEqualToString:@"setText"]) {
        [self onSetText:call result:result];
    } if ([[call method] isEqualToString:@"currentLineCount"]) {
          NSInteger lineCount = [self currentLineCount]; // Call the line count method
          result(@(lineCount)); // Return the line count as an NSNumber
    } else {
        result(FlutterMethodNotImplemented);
    }
}

- (void)onSetText:(FlutterMethodCall*)call result:(FlutterResult)result {
    _textView.text = call.arguments[@"text"];
    result(nil);
}

- (UIView*)view {
    return _textView;
}

/// Calculate current lines count
- (NSInteger)currentLineCount {
    if (_textView.font == nil) {
        return 0; // Ensure the font is set; otherwise, we can't calculate line height
    }
    // Calculate line height based on font
    CGFloat lineHeight = _textView.font.lineHeight;
    // Get the content size height
    CGFloat contentHeight = _textView.contentSize.height;
    // Calculate the number of lines
    NSInteger lineCount = contentHeight / lineHeight;
    return lineCount;
}

- (NSTextAlignment)textAlignmentFromString:(NSString*)textAlignment {
    if (!textAlignment || [textAlignment isKindOfClass:[NSNull class]]) {
        return NSTextAlignmentNatural;
    }
    
    if ([textAlignment isEqualToString:@"TextAlign.left"]) {
        return NSTextAlignmentLeft;
    } else if ([textAlignment isEqualToString:@"TextAlign.right"]) {
        return NSTextAlignmentRight;
    } else if ([textAlignment isEqualToString:@"TextAlign.center"]) {
        return NSTextAlignmentCenter;
    } else if ([textAlignment isEqualToString:@"TextAlign.justify"]) {
        return NSTextAlignmentJustified;
    } else if ([textAlignment isEqualToString:@"TextAlign.end"]) {
        return ([self layoutDirection] == UIUserInterfaceLayoutDirectionLeftToRight)
            ? NSTextAlignmentRight
            : NSTextAlignmentLeft;
    }
    
    // TextAlign.start
    return NSTextAlignmentNatural;
}

- (UIUserInterfaceLayoutDirection)layoutDirection {
    if (@available(iOS 9.0, *)) {
        return [UIView userInterfaceLayoutDirectionForSemanticContentAttribute:_textView.semanticContentAttribute];
    }
    
    return UIApplication.sharedApplication.userInterfaceLayoutDirection;
}

@end

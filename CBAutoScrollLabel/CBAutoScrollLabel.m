//
//  CBAutoScrollLabel.m
//  CBAutoScrollLabel
//
//  Created by Brian Stormont on 10/21/09.
//  Updated by Christopher Bess on 2/5/12
//
//  Copyright 2009 Stormy Productions. 
//
//  Permission is granted to use this code free of charge for any project.
//

#import "CBAutoScrollLabel.h"
#import <QuartzCore/QuartzCore.h>

#define kLabelCount 1
#define kDefaultFadeLength 7.f
// pixel buffer space between scrolling label
#define kDefaultLabelBufferSpace 20
#define kDefaultPixelsPerSecond 30
#define kDefaultPauseTime 0.0f

#define kMaxFieldHeight 9999

// shortcut method for NSArray iterations
static void each_object(NSArray *objects, void (^block)(id object))
{
    for (id obj in objects)
        block(obj);
}

// shortcut to change each label attribute value
#define EACH_LABEL(ATTR, VALUE) each_object(self.labels, ^(UILabel *label) { label.ATTR = VALUE; });

@interface CBAutoScrollLabel ()

@property (nonatomic, strong) NSArray *labels;
@property (strong, nonatomic, readonly) UITextView *mainLabel;
@property (nonatomic, strong) UIScrollView *scrollView;

@end

@implementation CBAutoScrollLabel

@synthesize scrollDirection = _scrollDirection;
@synthesize pauseInterval = _pauseInterval;
@synthesize labelSpacing;
@synthesize scrollSpeed = _scrollSpeed;
@synthesize scrollDuration = _scrollDuration;
@synthesize text;
@synthesize labels;
@synthesize mainLabel;
@synthesize animationOptions;
@synthesize shadowColor;
@synthesize shadowOffset;
@synthesize textAlignment;
@synthesize scrolling = _scrolling;
@synthesize scrollingPaused = _scrollingPaused;

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super initWithCoder:aDecoder]))
    {
     	[self commonInit];
    }
    return self;	
}

- (id)initWithFrame:(CGRect)frame 
{
    if ((self = [super initWithFrame:frame]))
    {
		[self commonInit];
    }
    return self;
}

- (void)commonInit
{
    // create the labels
    NSMutableSet *labelSet = [[NSMutableSet alloc] initWithCapacity:kLabelCount];
    
    UITextView *tview = [[UITextView alloc] init];
    tview.backgroundColor = [UIColor clearColor];
    tview.autoresizingMask = self.autoresizingMask;
    tview.textAlignment = NSTextAlignmentCenter;
    [self.scrollView addSubview:tview];
     [labelSet addObject:tview];
    
    self.labels = [labelSet.allObjects copy];
    
    #if ! __has_feature(objc_arc)
    [labelSet release];
    #endif
    
    // default values
	_scrollDirection = CBAutoScrollDirectionLeft;
	_scrollSpeed = kDefaultPixelsPerSecond;
//    _scrollDuration = 30.0;
    _scrollingPaused = TRUE;
	self.pauseInterval = kDefaultPauseTime;
	self.labelSpacing = kDefaultLabelBufferSpace;
    self.textAlignment = NSTextAlignmentCenter;
    self.animationOptions = UIViewAnimationOptionCurveEaseIn;
	self.scrollView.showsVerticalScrollIndicator = NO;
	self.scrollView.showsHorizontalScrollIndicator = NO;
    self.scrollView.scrollEnabled = NO;
    self.userInteractionEnabled = NO;
    self.backgroundColor = [UIColor clearColor];
    self.clipsToBounds = YES;
//    self.fadeLength = kDefaultFadeLength;
    self.fadeLength = 0.0;
    [self setAnimationOptions:UIViewAnimationOptionCurveLinear];
}

- (void)dealloc 
{
    self.labels = nil;
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    #if ! __has_feature(objc_arc)
    [super dealloc];
    #endif
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
//    [self applyGradientMaskForFadeLength:self.fadeLength enableFade:self.scrolling];
    [self applyGradientMaskForFadeLength:self.fadeLength enableFade:NO];
}

#pragma mark - Properties

- (UIScrollView *)scrollView
{
    if (_scrollView == nil)
    {
        _scrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
        _scrollView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
        _scrollView.backgroundColor = [UIColor clearColor];
        
        [self addSubview:_scrollView];
        
#if ! __has_feature(objc_arc)
        [_scrollView release];
#endif
    }
    return _scrollView;
}

- (void)setFadeLength:(CGFloat)fadeLength
{
//    if (_fadeLength != fadeLength)
//    {
//        _fadeLength = fadeLength;
//        
//        [self refreshLabels];
//        [self applyGradientMaskForFadeLength:fadeLength enableFade:NO];
//    }
}

- (UITextView *)mainLabel
{
    return self.labels[0];
}

- (void)setText:(NSString *)theText
{
    [self setText:theText refreshLabels:YES];
}

- (void)setText:(NSString *)theText refreshLabels:(BOOL)refresh
{
    // ignore identical text changes
	if ([theText isEqualToString:self.text])
		return;
	
    EACH_LABEL(text, theText)
    
    if (refresh)
        [self refreshLabels];
}

- (NSString *)text
{
	return self.mainLabel.text;
}

- (void)setAttributedText:(NSAttributedString *)theText
{
    [self setAttributedText:theText refreshLabels:YES];
}

- (void)setAttributedText:(NSAttributedString *)theText refreshLabels:(BOOL)refresh
{
    // ignore identical text changes
	if ([theText.string isEqualToString:self.attributedText.string])
		return;
	
    EACH_LABEL(attributedText, theText)
    
    if (refresh)
        [self refreshLabels];
}

- (NSAttributedString *)attributedText
{
	return self.mainLabel.attributedText;
}

- (void)setTextColor:(UIColor *)color
{
    EACH_LABEL(textColor, color)
}

- (UIColor *)textColor
{
	return self.mainLabel.textColor;
}


- (void)setFont:(UIFont *)font
{
    if (self.mainLabel.font == font)
        return;
    
    EACH_LABEL(font, font)
    
//    CGFloat measuredWidth = [self measuredWidthForString:@"Looked down where He lay" forBoundingRect:CGSizeMake(CGRectGetWidth(self.bounds),MAXFLOAT) forFont:self.mainLabel.font];
//    CGFloat smallestWidth = [self measuredWidthForString:@"Looked down where He lay" forBoundingRect:CGSizeMake(CGRectGetWidth(self.bounds),MAXFLOAT) forFont:[self.mainLabel.font fontWithSize:self.mainLabel.font.pointSize - 10]];
//    CGFloat measuredHeight = [self measuredHeightForString:@"Looked down where He lay" forBoundingRect:CGSizeMake(CGRectGetWidth(self.bounds),MAXFLOAT) forFont:self.mainLabel.font];
//    CGFloat smallestHeight = [self measuredHeightForString:@"L" forBoundingRect:CGSizeMake(CGRectGetWidth(self.bounds),MAXFLOAT) forFont:self.mainLabel.font];
//    
//    UIFont *newFont = self.mainLabel.font;
//    while (measuredHeight > smallestHeight)
//    {
//        newFont = [newFont fontWithSize:newFont.pointSize - 1];
//        measuredHeight = [self measuredHeightForString:@"Looked down where He lay" forBoundingRect:CGSizeMake(CGRectGetWidth(self.bounds),MAXFLOAT) forFont:newFont];
//        smallestHeight = [self measuredHeightForString:@"L" forBoundingRect:CGSizeMake(CGRectGetWidth(self.bounds),MAXFLOAT) forFont:newFont];
//
//    }
//    self.mainLabel.font = newFont;
    
	[self refreshLabels];
}

- (UIFont *)font
{
	return self.mainLabel.font;
}

- (void)setScrollSpeed:(float)speed
{
	_scrollSpeed = speed;
    
    [self scrollLabelIfNeeded];
}

- (void)setScrollDuration:(float)scrollDuration
{
	_scrollDuration  = scrollDuration;
    
    [self scrollLabelIfNeeded];
}

- (void)setScrollDirection:(CBAutoScrollDirection)direction
{
	_scrollDirection = direction;
    
    [self scrollLabelIfNeeded];
}

- (void)setShadowColor:(UIColor *)color
{
    return;
    EACH_LABEL(shadowColor, color)
}

- (UIColor *)shadowColor
{
    return [UIColor clearColor];
//    return self.mainLabel.shadowColor;
}

- (void)setShadowOffset:(CGSize)offset
{
    return;
    EACH_LABEL(shadowOffset, offset)
}

- (CGSize)shadowOffset
{
    return CGSizeZero;
//    return self.mainLabel.shadowOffset;
}

#pragma mark - Misc

- (void)observeApplicationNotifications
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    // restart scrolling when the app has been activated
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(scrollLabelIfNeeded)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(scrollLabelIfNeeded)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    
    // refresh labels when interface orientation is changed
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onUIApplicationDidChangeStatusBarOrientationNotification:)
                                                 name:UIApplicationDidChangeStatusBarOrientationNotification
                                               object:nil];
}

- (void)enableShadow
{
    _scrolling = YES;
//    [self applyGradientMaskForFadeLength:self.fadeLength enableFade:YES];
    [self applyGradientMaskForFadeLength:self.fadeLength enableFade:NO];
}

- (void)scrollLabelIfNeeded
{
    if (!self.text.length)
        return;
    
    if (self.scrollTextAnimation)
        return;
    
    CGFloat labelHeight =   [self measureHeightOfUITextView:self.mainLabel]; // CGRectGetHeight(self.mainLabel.bounds);
	if (labelHeight <= CGRectGetHeight(self.bounds))
        return;
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(scrollLabelIfNeeded) object:nil];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(enableShadow) object:nil];
    
//    BOOL doScrollLeft = (self.scrollDirection == CBAutoScrollDirectionLeft);
//    self.scrollView.contentOffset = (doScrollLeft ? CGPointZero : CGPointMake(labelWidth + self.labelSpacing, 0));
    self.scrollView.contentOffset = CGPointMake(labelHeight + self.labelSpacing, 0);


    origBounds = CGRectMake(self.scrollView.bounds.origin.x, self.scrollView.bounds.origin.y, self.scrollView.bounds.size.width, self.scrollView.bounds.size.height);
    
    // Add the left shadow after delay
    //    [self performSelector:@selector(enableShadow) withObject:nil afterDelay:self.pauseInterval];
    
//    pulseAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
//    pulseAnimation.autoreverses = YES;
//    pulseAnimation.repeatCount = FLT_MAX;
//    
//    [layer addAnimation:pulseAnimation forKey:animationKeyId];
//    
//    [UIView animateWithDuration:duration delay:self.pauseInterval options:self.animationOptions | UIViewAnimationOptionAllowUserInteraction animations:^{
//        // adjust offset
//        self.scrollView.contentOffset = (doScrollLeft ? CGPointMake(labelWidth + self.labelSpacing, 0) : CGPointZero);
//    } completion:^(BOOL finished) {
//        _scrolling = NO;
//        
//        // remove the left shadow
//        [self applyGradientMaskForFadeLength:self.fadeLength enableFade:NO];
//        
//        // setup pause delay/loop
//        if (finished)
//        {
//            // DONT REPEAT THE ANIMATION
////            [self performSelector:@selector(scrollLabelIfNeeded) withObject:nil];
//        }
//    }];
}

-(void)startAnimating
{
    NSLog(@"Starting to animate - slf:%@\ntextview:%@  scrollview: %@ scrollDuration: %f", self, self.mainLabel, self.scrollView, self.scrollDuration);

    self.alpha = 0.0f;
    self.hidden = NO;
    [self.scrollView.layer removeAnimationForKey:@"bounds"];
    self.scrollView.bounds = self.bounds;
    self.scrollView.hidden = NO;
    _scrolling = YES;
    [UIView animateWithDuration:5.0 animations:^{
        self.alpha = 1.0;
    }];
    
//    NSMutableAttributedString *txt = [[NSMutableAttributedString alloc] initWithString:self.mainLabel.text];
    
    
    
    
    if (!self.scrollTextAnimation) {
        float tviewHeight = CGRectGetHeight(self.mainLabel.bounds);

        // animate the scrolling
        NSTimeInterval duration = self.scrollDuration;
        if (! duration)
            duration  = tviewHeight / self.scrollSpeed;

        CGRect bounds = self.scrollView.bounds;
        _scrollTextAnimation = [CABasicAnimation animationWithKeyPath:@"bounds"];
        _scrollTextAnimation.duration = duration;
        _scrollTextAnimation.fromValue = [NSValue valueWithCGRect:self.scrollView.bounds];
        bounds.origin.y += tviewHeight + self.labelSpacing;
        _scrollTextAnimation.toValue = [NSValue valueWithCGRect:bounds];
        _scrollTextAnimation.autoreverses = NO;
        NSLog(@"created scroll animation\nfromValue:%@\ntoValue:%@\nscrollView:%@\ntextView%@\nduration:%f\nlableHeight: %f", self.scrollTextAnimation.fromValue, self.scrollTextAnimation.toValue, self.scrollView, self.mainLabel, duration, tviewHeight);
    }
    
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.initialDelay * NSEC_PER_SEC));
    NSLog(@"startAnimating %llu\nscrollview:%@\ntextview:%@ ", popTime, self.scrollView, self.mainLabel);
    
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self.scrollView.layer addAnimation:self.scrollTextAnimation forKey:@"bounds"];
    });
}

-(void)stopAnimating
{
    NSLog(@"Just before stopping animate - self:%@\ntextview:%@\nscrollview:%@\nscrollDuration: %f", self.mainLabel, self.scrollView, self.scrollDuration);

    _scrolling = NO;
    [UIView animateWithDuration:1.0 animations:^{
        self.alpha = 0.0f;
    } completion:^(BOOL f){
//        self.hidden = YES;
        [self.scrollView.layer removeAnimationForKey:@"bounds"];
        self.scrollTextAnimation = nil;
    }];
}

- (CGFloat)measureHeightOfUITextView:(UITextView *)textView
{
//    if ([textView respondsToSelector:@selector(snapshotViewAfterScreenUpdates:)])
//    {
        // This is the code for iOS 7. contentSize no longer returns the correct value, so
        // we have to calculate it.
        //
        // This is partly borrowed from HPGrowingTextView, but I've replaced the
        // magic fudge factors with the calculated values (having worked out where
        // they came from)
        
        CGRect frame = self.bounds;
        
        // Take account of the padding added around the text.
        
        UIEdgeInsets textContainerInsets = textView.textContainerInset;
        UIEdgeInsets contentInsets = textView.contentInset;
        
        CGFloat leftRightPadding = textContainerInsets.left + textContainerInsets.right + textView.textContainer.lineFragmentPadding * 2 + contentInsets.left + contentInsets.right;
        CGFloat topBottomPadding = textContainerInsets.top + textContainerInsets.bottom + contentInsets.top + contentInsets.bottom;
        
        frame.size.width -= leftRightPadding;
        frame.size.height -= topBottomPadding;
        
        NSString *textToMeasure = textView.text;
        if ([textToMeasure hasSuffix:@"\n"])
        {
            textToMeasure = [NSString stringWithFormat:@"%@-", textView.text];
        }
        
        // NSString class method: boundingRectWithSize:options:attributes:context is
        // available only on ios7.0 sdk.
        
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        [paragraphStyle setLineBreakMode:NSLineBreakByWordWrapping];
        
        NSDictionary *attributes = @{ NSFontAttributeName: self.mainLabel.font, NSParagraphStyleAttributeName : paragraphStyle };
        
        CGRect size = [textToMeasure boundingRectWithSize:CGSizeMake(CGRectGetWidth(frame), MAXFLOAT)
                                                  options:NSStringDrawingUsesLineFragmentOrigin
                                               attributes:attributes
                                                  context:nil];
        
        CGFloat measuredHeight = ceilf(CGRectGetHeight(size) + topBottomPadding);
        return measuredHeight;
//    }
//    else
//    {
//        return textView.contentSize.height;
//    }
}

- (CGFloat)measuredWidthForString:(NSString *)str forBoundingRect:(CGSize)maxSize forFont:(UIFont *)font
{
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle setLineBreakMode:NSLineBreakByWordWrapping];
    
    NSDictionary *attributes = @{ NSFontAttributeName: font, NSParagraphStyleAttributeName : paragraphStyle };
    
    CGRect size = [str boundingRectWithSize:maxSize
                                              options:NSStringDrawingUsesLineFragmentOrigin
                                           attributes:attributes
                                              context:nil];
    
    CGFloat measuredWidth = ceilf(CGRectGetWidth(size));
    return measuredWidth;
}

- (CGFloat)measuredHeightForString:(NSString *)str forBoundingRect:(CGSize)maxSize forFont:(UIFont *)font
{
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle setLineBreakMode:NSLineBreakByWordWrapping];
    
    NSDictionary *attributes = @{ NSFontAttributeName: font, NSParagraphStyleAttributeName : paragraphStyle };
    
    CGRect size = [str boundingRectWithSize:maxSize
                                    options:NSStringDrawingUsesLineFragmentOrigin
                                 attributes:attributes
                                    context:nil];
    
    CGFloat measuredHeight = ceilf(CGRectGetHeight(size));
    return measuredHeight;
}

-(void) refreshTextView
{
    if (!self.mainLabel.text.length)
        return;
//    
//    NSDictionary *attributes = @{NSFontAttributeName: self.mainLabel.font};
//    CGRect rect = [self.mainLabel.text boundingRectWithSize:CGSizeMake(CGRectGetWidth(self.bounds), MAXFLOAT)
//                                              options:NSStringDrawingUsesLineFragmentOrigin
//                                           attributes:attributes
//                                              context:nil];
    
    [self.mainLabel sizeToFit];
    [self.mainLabel layoutIfNeeded];
    
    CGFloat measuredHeight = [self measureHeightOfUITextView:self.mainLabel];
    CGFloat otherHeight = [self measuredHeightForString:self.mainLabel.text forBoundingRect:CGSizeMake(CGRectGetWidth(self.bounds),MAXFLOAT) forFont:self.mainLabel.font];
   
    CGSize tviewSize = CGSizeMake(origBounds.size.width, measuredHeight);

    self.scrollView.contentSize = tviewSize;
    self.mainLabel.frame = CGRectMake(self.scrollView.bounds.origin.x,self.scrollView.bounds.origin.y, tviewSize.width, tviewSize.height);
    
    EACH_LABEL(hidden, NO)
    
    [self applyGradientMaskForFadeLength:self.fadeLength enableFade:NO];
    
    [self scrollLabelIfNeeded];

    NSLog(@"Measured Height of textview %f  String height is %f", measuredHeight, otherHeight );

    
}

- (void)refreshLabels
{
    
    [self refreshTextView];
    return;
    
	__block float offset = 0;
	
    // calculate the label size
    CGSize labelSize = [self.mainLabel.text sizeWithFont:self.mainLabel.font
                                       constrainedToSize:CGSizeMake(CGFLOAT_MAX, CGRectGetHeight(self.bounds))];

    each_object(self.labels, ^(UILabel *label) {
        CGRect frame = label.frame;
        frame.origin.x = offset;
        frame.size.height = CGRectGetHeight(self.bounds);
        frame.size.width = labelSize.width + 2.f /*Magic number*/;
        label.frame = frame;
        
        // Recenter label vertically within the scroll view
        label.center = CGPointMake(label.center.x, roundf(self.center.y - CGRectGetMinY(self.frame)));
        
        offset += CGRectGetWidth(label.bounds) + self.labelSpacing;
    });
    
	self.scrollView.contentOffset = CGPointZero;

	// if the label is bigger than the space allocated, then it should scroll
	if (CGRectGetWidth(self.mainLabel.bounds) > CGRectGetWidth(self.bounds) )
    {
        CGSize size;
        size.width = CGRectGetWidth(self.mainLabel.bounds) + CGRectGetWidth(self.bounds) + self.labelSpacing;
        size.height = CGRectGetHeight(self.bounds);
        self.scrollView.contentSize = size;

        EACH_LABEL(hidden, NO)
        
        [self applyGradientMaskForFadeLength:self.fadeLength enableFade:self.scrolling];

		[self scrollLabelIfNeeded];
	}
    else
    {
		// Hide the other labels
        EACH_LABEL(hidden, (self.mainLabel != label))
        
        // adjust the scroll view and main label
        self.scrollView.contentSize = self.bounds.size;
        self.mainLabel.frame = self.bounds;
        self.mainLabel.hidden = NO;
        self.mainLabel.textAlignment = self.textAlignment;
        
        [self applyGradientMaskForFadeLength:0 enableFade:NO];
	}
}

#pragma mark - Gradient

// ref: https://github.com/cbpowell/MarqueeLabel
- (void)applyGradientMaskForFadeLength:(CGFloat)fadeLength enableFade:(BOOL)fade
{
    CGFloat labelWidth = CGRectGetWidth(self.mainLabel.bounds);
	if (labelWidth <= CGRectGetWidth(self.bounds))
        fadeLength = 0;

    if (fadeLength)
    {
        // Recreate gradient mask with new fade length
        CAGradientLayer *gradientMask = [CAGradientLayer layer];
        
        gradientMask.bounds = self.layer.bounds;
        gradientMask.position = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
        
        gradientMask.shouldRasterize = YES;
        gradientMask.rasterizationScale = [UIScreen mainScreen].scale;
        
        gradientMask.startPoint = CGPointMake(0, CGRectGetMidY(self.frame));
        gradientMask.endPoint = CGPointMake(1, CGRectGetMidY(self.frame));

        // setup fade mask colors and location
        id transparent = (id)[UIColor clearColor].CGColor;
        id opaque = (id)[UIColor blackColor].CGColor;
        gradientMask.colors = @[transparent, opaque, opaque, transparent];
        
        // calcluate fade
        CGFloat fadePoint = fadeLength / CGRectGetWidth(self.bounds);
        NSNumber *leftFadePoint = @(fadePoint);
        NSNumber *rightFadePoint = @(1 - fadePoint);
        if (!fade) switch (self.scrollDirection)
        {
            case CBAutoScrollDirectionLeft:
                leftFadePoint = @0;
                break;
                
            case CBAutoScrollDirectionRight:
                leftFadePoint = @0;
                rightFadePoint = @1;
                break;
        }
        
        // apply calculations to mask
        gradientMask.locations = @[@0, leftFadePoint, rightFadePoint, @1];
        
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        self.layer.mask = gradientMask;
        [CATransaction commit];
    }
    else
    {
        // Remove gradient mask for 0.0f lenth fade length
        self.layer.mask = nil;
    }
}

#pragma mark - Notifications

- (void)onUIApplicationDidChangeStatusBarOrientationNotification:(NSNotification *)notification
{
    // delay to have it re-calculate on next runloop
    [self performSelector:@selector(refreshLabels) withObject:nil afterDelay:.1f];
    [self performSelector:@selector(scrollLabelIfNeeded) withObject:nil afterDelay:.1f];
}

@end

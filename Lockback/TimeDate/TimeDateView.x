// This restores the time and date on the lock screen.

#import <UIKit/UIKit.h>
#import <math.h>
#import "TimeDateShared.h"

@interface NSObject (LBTimeDatePrivateMethods)
- (CGFloat)_baselineOffsetFromBottom;
@end

// Stores the font sizes and baseline positions used to recreate the lock screen time and date.
typedef struct {
    CGFloat timeFontSizeCase;
    CGFloat dateFontSizeCase;
    CGFloat timeBaselineCase;
    CGFloat dateBaselineOffsetCase;
} LBTimeDateMetrics;

static NSString *const lbTimeLabelAccessibilityIdentifierCase = @"LockScreenTimeLabel";
static NSString *const lbDateLabelAccessibilityIdentifierCase = @"LockScreenDateLabel";

// Maps the current Dynamic Type size to the corresponding date metrics.
static NSUInteger LBDateMetricsIndex(void) {
    NSString *contentSizeCategoryCase = [UIApplication sharedApplication].preferredContentSizeCategory;

    if ([contentSizeCategoryCase isEqualToString:UIContentSizeCategoryExtraLarge]) { return 1; }
    if ([contentSizeCategoryCase isEqualToString:UIContentSizeCategoryExtraExtraLarge]) { return 2; }

    if ([contentSizeCategoryCase isEqualToString:UIContentSizeCategoryExtraSmall] ||
        [contentSizeCategoryCase isEqualToString:UIContentSizeCategorySmall] ||
        [contentSizeCategoryCase isEqualToString:UIContentSizeCategoryMedium] ||
        [contentSizeCategoryCase isEqualToString:UIContentSizeCategoryLarge]) {
        return 0;
    }

    return 3;
}

// Returns the time and date metrics for the current device size and text size.
static LBTimeDateMetrics LBMetricsForCurrentScreen(void) {
    CGSize screenSizeCase = [UIScreen mainScreen].bounds.size;
    CGFloat portraitScreenHeightCase = MAX(screenSizeCase.width, screenSizeCase.height);

    NSUInteger dateMetricsIndexCase = LBDateMetricsIndex();

    // iPad uses a larger clock and separate date metrics from iPhone.
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        static const CGFloat dateFontSizesCase[] = { 22.0, 23.0, 24.0, 24.5 };
        static const CGFloat dateBaselineOffsetsCase[] = { 40.0, 40.0, 45.5, 45.5 };

        return (LBTimeDateMetrics) {
            .timeFontSizeCase = 117.0,
            .dateFontSizeCase = dateFontSizesCase[dateMetricsIndexCase],
            .timeBaselineCase = portraitScreenHeightCase > 1024.0 ? 208.0 : 168.0,
            .dateBaselineOffsetCase = dateBaselineOffsetsCase[dateMetricsIndexCase],
        };
    }

    static const CGFloat regularDateFontSizesCase[] = { 18.0, 19.0, 20.0, 21.0 };
    static const CGFloat regularDateBaselineOffsetsCase[] = { 32.0, 33.5, 36.0, 39.0 };

    // Like iPads, plus-sized iPhones use slightly larger date text and lower date baselines.
    static const CGFloat plusDateFontSizesCase[] = {
        20.0,
        20.666666666666668,
        21.333333333333332,
        22.0,
    };
    static const CGFloat plusDateBaselineOffsetsCase[] = {
        41.333333333333336,
        42.666666666666664,
        43.666666666666664,
        45.0,
    };

    BOOL isPlusDisplayCase = portraitScreenHeightCase > 667.0;
    return (LBTimeDateMetrics) {
        // Return all of the metrics used for the time and date.
        .timeFontSizeCase = 87.5,
        .dateFontSizeCase = isPlusDisplayCase ? plusDateFontSizesCase[dateMetricsIndexCase] : regularDateFontSizesCase[dateMetricsIndexCase],
        .timeBaselineCase = isPlusDisplayCase ? 146.0 : portraitScreenHeightCase > 568.0 ? 140.0 : 112.0,
        .dateBaselineOffsetCase = isPlusDisplayCase ? plusDateBaselineOffsetsCase[dateMetricsIndexCase] : regularDateBaselineOffsetsCase[dateMetricsIndexCase],
    };
}

static UIFont *LBFontByAddingFeatures(UIFont *fontCase, NSArray *featureSettingsCase, CGFloat fontSizeCase) {
    UIFontDescriptor *fontDescriptorCase = [fontCase.fontDescriptor fontDescriptorByAddingAttributes:@{ UIFontDescriptorFeatureSettingsAttribute: featureSettingsCase, }];
    return [UIFont fontWithDescriptor:fontDescriptorCase size:fontSizeCase];
}

// Creates the San Francisco font used by the lock screen clock.
static UIFont *LBTimeFont(CGFloat fontSizeCase) {
    UIFont *fontCase = [UIFont fontWithName:@".SFUIDisplay-Ultralight" size:fontSizeCase];

    if (!fontCase && [UIFont respondsToSelector:@selector(systemFontOfSize:weight:)]) { fontCase = [UIFont systemFontOfSize:fontSizeCase weight:UIFontWeightUltraLight]; }
    if (!fontCase) { fontCase = [UIFont systemFontOfSize:fontSizeCase]; }

    return LBFontByAddingFeatures(
        fontCase,
        @[
            @{
                UIFontFeatureTypeIdentifierKey: @6,
                UIFontFeatureSelectorIdentifierKey: @1,
            },
            @{
                UIFontFeatureTypeIdentifierKey: @17,
                UIFontFeatureSelectorIdentifierKey: @1,
            },
        ],
        fontSizeCase
    );
}

// Creates the system font used for the lock screen date.
static UIFont *LBDateFont(CGFloat fontSizeCase) {
    return LBFontByAddingFeatures(
        [UIFont systemFontOfSize:fontSizeCase],
        @[
            @{
                UIFontFeatureTypeIdentifierKey: @6,
                UIFontFeatureSelectorIdentifierKey: @1,
            },
        ],
        fontSizeCase
    );
}

// Builds the localized clock format for the lock screen clock.
static NSString *LBTimeFormatForLocale(NSLocale *localeCase) {
    NSString *localizedTimeFormatCase = [NSDateFormatter dateFormatFromTemplate:@"jmm" options:0 locale:localeCase];
    if (!localizedTimeFormatCase.length) { return @"HH:mm"; }

    NSMutableString *timeFormatCase = [localizedTimeFormatCase mutableCopy];

    NSRange dayPeriodRangeCase = [timeFormatCase rangeOfString:@"a"];
    if (dayPeriodRangeCase.location == NSNotFound) { return timeFormatCase; }

    NSCharacterSet *whitespaceCharacterSetCase = [NSCharacterSet whitespaceCharacterSet];
    NSUInteger dayPeriodStartIndexCase = dayPeriodRangeCase.location;
    NSUInteger dayPeriodEndIndexCase = NSMaxRange(dayPeriodRangeCase);

    while (dayPeriodStartIndexCase > 0 && [whitespaceCharacterSetCase characterIsMember: [timeFormatCase characterAtIndex:dayPeriodStartIndexCase - 1]]) { dayPeriodStartIndexCase--; }
    while (dayPeriodEndIndexCase < timeFormatCase.length && [whitespaceCharacterSetCase characterIsMember: [timeFormatCase characterAtIndex:dayPeriodEndIndexCase]]) { dayPeriodEndIndexCase++; }

    [timeFormatCase deleteCharactersInRange:NSMakeRange(dayPeriodStartIndexCase, dayPeriodEndIndexCase - dayPeriodStartIndexCase )];
    return timeFormatCase.length ? timeFormatCase : @"HH:mm";
}

// Creates a localized date formatter using the current locale and time zone.
static NSDateFormatter *LBFormatterWithTemplate(NSLocale *localeCase, NSTimeZone *timeZoneCase, NSString *formatTemplateCase
) {
    NSDateFormatter *formatterCase = [NSDateFormatter new];
    formatterCase.locale = localeCase;
    formatterCase.timeZone = timeZoneCase;

    [formatterCase setLocalizedDateFormatFromTemplate:formatTemplateCase];
    return formatterCase;
}

// Aligns positions to physical screen pixels to avoid blurry text.
static CGFloat LBPixelFloorForValue(CGFloat valueCase) {
    CGFloat screenScaleCase = [UIScreen mainScreen].scale;
    return floor(valueCase * screenScaleCase) / screenScaleCase;
}

static CGFloat LBBaselineOffsetFromTopForLabel(UILabel *labelCase) { return [labelCase respondsToSelector:@selector(_baselineOffsetFromBottom)] ? CGRectGetHeight(labelCase.bounds) - [(id)labelCase _baselineOffsetFromBottom] : labelCase.font.ascender; }

// Centers a label horizontally and positions it using an exact text baseline.
static void LBPositionLabelAtBaseline(UILabel *labelCase, CGFloat containerWidthCase, CGFloat baselineCase) {
    [labelCase sizeToFit];

    CGRect frameCase = labelCase.bounds;
    frameCase.origin.x = LBPixelFloorForValue((containerWidthCase - CGRectGetWidth(frameCase)) / 2.0);
    frameCase.origin.y = LBPixelFloorForValue(baselineCase - LBBaselineOffsetFromTopForLabel(labelCase));

    labelCase.frame = frameCase;
}

// Creates a label with the shared appearance and accessibility settings used by the clock and date.
static UILabel *LBNewTimeDateLabel(NSString *accessibilityIdentifierCase) {
    UILabel *labelCase = [[UILabel alloc] initWithFrame:CGRectZero];
    labelCase.backgroundColor = [UIColor clearColor];

    labelCase.textAlignment = NSTextAlignmentCenter;
    labelCase.textColor = [UIColor whiteColor];

    labelCase.numberOfLines = 1;

    labelCase.userInteractionEnabled = NO;

    labelCase.isAccessibilityElement = YES;
    labelCase.accessibilityIdentifier = accessibilityIdentifierCase;

    labelCase.shadowColor = [UIColor colorWithWhite:0.0 alpha:0.35];
    labelCase.shadowOffset = CGSizeMake(0.0, 1.0 / [UIScreen mainScreen].scale);

    return labelCase;
}

@implementation LBTimeDateView

- (instancetype)initWithFrame:(CGRect)frameCase {
    self = [super initWithFrame:frameCase];
    if (!self) { return nil; }

    self.backgroundColor = [UIColor clearColor];

    self.userInteractionEnabled = NO;
    self.isAccessibilityElement = NO;

    self.timeLabelCase = LBNewTimeDateLabel(lbTimeLabelAccessibilityIdentifierCase);
    self.dateLabelCase = LBNewTimeDateLabel(lbDateLabelAccessibilityIdentifierCase);
    [self addSubview:self.timeLabelCase];
    [self addSubview:self.dateLabelCase];

    [self updateLabelFonts];
    [self refreshFormatters];

    return self;
}

- (void)updateLabelFonts {
    LBTimeDateMetrics metricsCase = LBMetricsForCurrentScreen();

    self.timeLabelCase.font = LBTimeFont(metricsCase.timeFontSizeCase);
    self.dateLabelCase.font = LBDateFont(metricsCase.dateFontSizeCase);
}

- (void)refreshFormatters {
    NSLocale *localeCase = [NSLocale autoupdatingCurrentLocale];
    NSTimeZone *timeZoneCase = [NSTimeZone localTimeZone];

    self.timeFormatterCase = LBFormatterWithTemplate(localeCase, timeZoneCase, @"jmm");
    self.timeFormatterCase.dateFormat = LBTimeFormatForLocale(localeCase);

    self.dateFormatterCase = LBFormatterWithTemplate(localeCase, timeZoneCase, @"EEEE MMMM d");
}

- (void)setDate:(NSDate *)dateCase {
    if (!dateCase) { return; }

    NSString *timeTextCase = [self.timeFormatterCase stringFromDate:dateCase];
    NSString *dateTextCase = [self.dateFormatterCase stringFromDate:dateCase];

    self.timeLabelCase.text = timeTextCase;
    self.timeLabelCase.accessibilityLabel = timeTextCase;

    self.dateLabelCase.text = dateTextCase;
    self.dateLabelCase.accessibilityLabel = dateTextCase;

    [self setNeedsLayout];
}

// Positions both labels using baseline metrics.
- (void)layoutSubviews {
    [super layoutSubviews];
    [self updateLabelFonts];

    LBTimeDateMetrics metricsCase = LBMetricsForCurrentScreen();
    CGFloat containerWidthCase = CGRectGetWidth(self.bounds);

    LBPositionLabelAtBaseline(self.timeLabelCase, containerWidthCase, metricsCase.timeBaselineCase);
    LBPositionLabelAtBaseline(self.dateLabelCase, containerWidthCase, metricsCase.timeBaselineCase + metricsCase.dateBaselineOffsetCase);
}

@end
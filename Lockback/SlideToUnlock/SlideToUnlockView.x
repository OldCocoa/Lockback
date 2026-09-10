// This recreates the old iOS Slide to Unlock view and its visual behavior.

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "../LockbackUtils.h"
#import "SlideToUnlockShared.h"

@interface NSObject (LBSlideToUnlockViewPrivateMethods)
+ (UIEdgeInsets)slideToUnlockInsets;
+ (CGFloat)slideToUnlockOverlayMargin;
- (instancetype)initWithText:(NSString *)displayTextCase andFont:(UIFont *)displayFontCase;
- (void)setDelegate:(id)delegateCase;
- (void)setAdjustsFontSizeToFitWidth:(BOOL)adjustsFontSizeToFitWidthCase;
- (void)setChevronStyle:(NSInteger)chevronStyleCase;
- (void)setChevronBackgroundColor:(UIColor *)chevronBackgroundColorCase;
- (void)setBackgroundView:(UIView *)backgroundViewCase;
- (void)setVibrantSettings:(id)vibrantSettingsCase;
- (void)setBlurHidden:(BOOL)blurHiddenCase forRequester:(id)requesterCase;
- (void)setHighlight:(BOOL)highlightCase;
- (void)setText:(NSString *)textCase;
- (NSString *)text;
- (void)updateText;
- (void)startAnimating;
- (void)stopAnimating;
- (void)show;
- (void)fadeOut;
- (void)fadeIn;
- (CGFloat)_baselineOffsetFromBottom;
- (CGFloat)baselineOffsetFromBottomWithSize:(CGSize)viewSizeCase;
- (CGRect)labelFrame;
- (CGRect)chevronFrame;
- (id)contentColor;
- (id)legibilitySettings;
- (UIColor *)averageColorInRect:(CGRect)rectCase forVariant:(NSInteger)wallpaperVariantCase;
- (CGFloat)contrastInRect:(CGRect)rectCase forVariant:(NSInteger)wallpaperVariantCase;
- (BOOL)_hasLockContentUnderlayRequesterOtherThanRequester:(id)requesterCase;
@end

static const void *lbSlideToUnlockViewAssociationKeyCase = &lbSlideToUnlockViewAssociationKeyCase;

static NSString *LBLocalizedSpringBoardText(NSString *textKeyCase, NSString *fallbackTextCase) {
    NSString *localizedTextCase = [[NSBundle mainBundle] localizedStringForKey:textKeyCase value:fallbackTextCase table:@"SpringBoard"];
    return localizedTextCase.length ? localizedTextCase : fallbackTextCase;
}

// Loads SpringBoard's localized Slide to Unlock and Try Again text.
static NSString *LBLocalizedSlideToUnlockText(void) { return LBLocalizedSpringBoardText(@"AWAY_LOCK_LABEL", @"slide to unlock"); }
static NSString *LBLocalizedTryAgainText(void) { return LBLocalizedSpringBoardText(@"AWAY_LOCK_TRY_AGAIN", @"Try Again"); }

static UIEdgeInsets LBSlideToUnlockInsets(void) {
    Class lockScreenMetricsClassCase = NSClassFromString(@"SBFLockScreenMetrics");
    return lockScreenMetricsClassCase && [lockScreenMetricsClassCase respondsToSelector:@selector(slideToUnlockInsets)] ? [(id)lockScreenMetricsClassCase slideToUnlockInsets] : UIEdgeInsetsMake(0.0, 10.0, 20.0, 10.0);
}

static CGFloat LBSlideToUnlockOverlayMargin(void) {
    Class lockScreenMetricsClassCase = NSClassFromString(@"SBFLockScreenMetrics");
    if (lockScreenMetricsClassCase && [lockScreenMetricsClassCase respondsToSelector:@selector(slideToUnlockOverlayMargin)]) { return [(id)lockScreenMetricsClassCase slideToUnlockOverlayMargin]; }

    return UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? 22.0 : 0.0;
}

static BOOL LBShouldApplySlideToUnlockOverlayMargin(UIView *dashboardViewCase) {
    return ![dashboardViewCase respondsToSelector:@selector(_hasLockContentUnderlayRequesterOtherThanRequester:)] || ![(id)dashboardViewCase _hasLockContentUnderlayRequesterOtherThanRequester:nil];
}

// Owns the recreated glinty Slide to Unlock label and its wallpaper-aware appearance.
@interface LBSlideToUnlockView : UIView <CAAnimationDelegate>
@property (nonatomic, weak) UIView *dashboardViewCase;
@property (nonatomic, strong) UIView *parentSpringViewCase;
@property (nonatomic, strong) UIView *springViewCase;
@property (nonatomic, strong) UIView *glintyStringViewCase;
@property (nonatomic, strong) UIView *slideToUnlockBackgroundViewCase;
@property (nonatomic, assign) BOOL shakingSlideTextCase;
- (instancetype)initWithFrame:(CGRect)viewFrameCase dashboardView:(UIView *)dashboardViewCase;
- (void)refreshSlideContent;
- (void)updateSlideAppearance;
- (void)setCustomSlideToUnlockText:(NSString *)customTextCase;
@end

@interface LBSlideToUnlockView (Animation)
- (void)startSlideAnimation;
- (void)stopSlideAnimation;
- (void)shakeSlideToUnlockTextWithCustomText:(NSString *)customTextCase;
@end

@implementation LBSlideToUnlockView

- (instancetype)initWithFrame:(CGRect)viewFrameCase dashboardView:(UIView *)dashboardViewCase {
    self = [super initWithFrame:viewFrameCase];
    if (!self) { return nil; }

    self.dashboardViewCase = dashboardViewCase;
    self.backgroundColor = [UIColor clearColor];
    self.userInteractionEnabled = NO;
    self.isAccessibilityElement = NO;

    self.parentSpringViewCase = [[UIView alloc] initWithFrame:self.bounds];
    self.parentSpringViewCase.backgroundColor = [UIColor clearColor];
    self.parentSpringViewCase.userInteractionEnabled = NO;
    self.parentSpringViewCase.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addSubview:self.parentSpringViewCase];

    self.springViewCase = [[UIView alloc] initWithFrame:CGRectZero];
    self.springViewCase.backgroundColor = [UIColor clearColor];
    self.springViewCase.userInteractionEnabled = NO;
    [self.parentSpringViewCase addSubview:self.springViewCase];

    self.slideToUnlockBackgroundViewCase = LBNewWallpaperEffectView(6);

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(localeDidChange:) name:NSCurrentLocaleDidChangeNotification object:nil];

    [self refreshSlideContent];
    return self;
}

- (void)dealloc {
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

// Rebuilds the localized glinty label when its content needs to change.
- (void)refreshSlideContent {
    [self stopSlideAnimation];
    self.shakingSlideTextCase = NO;
    [self.glintyStringViewCase removeFromSuperview];

    UIFont *slideTextFontCase = [UIFont systemFontOfSize:24.0];
    NSString *slideTextCase = LBLocalizedSlideToUnlockText();
    Class glintyStringViewClassCase = NSClassFromString(@"_UIGlintyStringView");
    UIView *newGlintyStringViewCase = nil;

    if (glintyStringViewClassCase) {
        newGlintyStringViewCase = [(id)[glintyStringViewClassCase alloc] initWithText:slideTextCase andFont:slideTextFontCase];
        [(id)newGlintyStringViewCase setDelegate:self];
        [(id)newGlintyStringViewCase setAdjustsFontSizeToFitWidth:YES];
        [(id)newGlintyStringViewCase setChevronStyle:1];
        [(id)newGlintyStringViewCase updateText];
    }

    if (!newGlintyStringViewCase) {
        UILabel *fallbackTextLabelCase = [[UILabel alloc] initWithFrame:CGRectZero];
        fallbackTextLabelCase.font = slideTextFontCase;
        fallbackTextLabelCase.text = [NSString stringWithFormat:@">  %@", slideTextCase];
        fallbackTextLabelCase.textColor = [UIColor colorWithWhite:1.0 alpha:0.8];
        fallbackTextLabelCase.textAlignment = NSTextAlignmentCenter;
        fallbackTextLabelCase.adjustsFontSizeToFitWidth = YES;
        fallbackTextLabelCase.minimumScaleFactor = 0.5;
        newGlintyStringViewCase = fallbackTextLabelCase;
    }

    newGlintyStringViewCase.userInteractionEnabled = NO;
    newGlintyStringViewCase.isAccessibilityElement = YES;
    newGlintyStringViewCase.accessibilityIdentifier = @"SlideToUnlockLabel";
    newGlintyStringViewCase.accessibilityLabel = slideTextCase;

    self.glintyStringViewCase = newGlintyStringViewCase;
    [self.springViewCase addSubview:newGlintyStringViewCase];
    [self setNeedsLayout];

    if (self.window) {
        [self layoutIfNeeded];
        [self startSlideAnimation];
    }
}

- (void)localeDidChange:(NSNotification *)localeChangeNotificationCase { [self refreshSlideContent]; }

- (void)didMoveToWindow {
    [super didMoveToWindow];

    if (self.window) {
        [self setNeedsLayout];
        [self layoutIfNeeded];
        if (!self.shakingSlideTextCase) { [self startSlideAnimation]; }
        return;
    }

    [self stopSlideAnimation];
}

- (void)setCustomSlideToUnlockText:(NSString *)customTextCase {
    UIView *glintyStringViewCase = self.glintyStringViewCase;
    NSString *slideTextCase = customTextCase.length ? customTextCase : LBLocalizedSlideToUnlockText();
    NSString *currentTextCase = [glintyStringViewCase respondsToSelector:@selector(text)] ? [(id)glintyStringViewCase text] : nil;

    if (![currentTextCase isEqualToString:slideTextCase]) {
        if ([glintyStringViewCase respondsToSelector:@selector(setText:)]) {
            [(id)glintyStringViewCase setText:slideTextCase];
            if ([glintyStringViewCase respondsToSelector:@selector(updateText)]) { [(id)glintyStringViewCase updateText]; }
        } else if ([glintyStringViewCase isKindOfClass:[UILabel class]]) { [(UILabel *)glintyStringViewCase setText:[NSString stringWithFormat:@">  %@", slideTextCase]]; }

        [self setNeedsLayout];
        [self layoutIfNeeded];
    }

    glintyStringViewCase.accessibilityLabel = slideTextCase;
}

// Updates the label vibrancy, background, and chevron using the current wallpaper.
- (void)updateSlideAppearance {
    UIView *dashboardViewCase = self.dashboardViewCase;
    UIView *glintyStringViewCase = self.glintyStringViewCase;
    if (!dashboardViewCase || !glintyStringViewCase) { return; }

    id wallpaperControllerCase = LBSharedInstance(@"SBWallpaperController");
    id legibilitySettingsCase = [(id)dashboardViewCase legibilitySettings];

    UIColor *referenceColorCase = nil;
    CGFloat referenceContrastCase = 0.0;

    if (wallpaperControllerCase && [legibilitySettingsCase contentColor] && [glintyStringViewCase respondsToSelector:@selector(labelFrame)]) {
        CGRect labelFrameCase = [(id)glintyStringViewCase labelFrame];
        CGRect screenLabelFrameCase = [glintyStringViewCase convertRect:labelFrameCase toView:nil];

        referenceColorCase = [wallpaperControllerCase averageColorInRect:screenLabelFrameCase forVariant:0];
        referenceContrastCase = [wallpaperControllerCase contrastInRect:screenLabelFrameCase forVariant:0];
    }

    glintyStringViewCase.backgroundColor = referenceColorCase ?: [UIColor clearColor];

    if ([glintyStringViewCase respondsToSelector:@selector(setBackgroundView:)]) { [(id)glintyStringViewCase setBackgroundView:referenceColorCase ? self.slideToUnlockBackgroundViewCase : nil]; }
    if ([glintyStringViewCase respondsToSelector:@selector(setVibrantSettings:)]) { [(id)glintyStringViewCase setVibrantSettings:LBCreateVibrantSettings(referenceColorCase, referenceContrastCase, legibilitySettingsCase)]; }

    if (wallpaperControllerCase && [glintyStringViewCase respondsToSelector:@selector(chevronFrame)] && [glintyStringViewCase respondsToSelector:@selector(setChevronBackgroundColor:)]) {
        CGRect chevronFrameCase = [(id)glintyStringViewCase chevronFrame];
        CGRect screenChevronFrameCase = [glintyStringViewCase convertRect:chevronFrameCase toView:nil];
        [(id)glintyStringViewCase setChevronBackgroundColor:[wallpaperControllerCase averageColorInRect:screenChevronFrameCase forVariant:0]];
    }

    if ([glintyStringViewCase respondsToSelector:@selector(setBlurHidden:forRequester:)]) {
        [(id)glintyStringViewCase setBlurHidden:!LBShouldApplySlideToUnlockOverlayMargin(dashboardViewCase) forRequester:@"SBLockScreenViewContentUnderlayOverride"];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];

    self.parentSpringViewCase.frame = self.bounds;

    UIEdgeInsets slideInsetsCase = LBSlideToUnlockInsets();
    CGFloat availableWidthCase = MAX(0.0, CGRectGetWidth(self.bounds) - slideInsetsCase.left - slideInsetsCase.right);
    CGSize contentSizeCase = [self.glintyStringViewCase sizeThatFits:CGSizeMake(availableWidthCase, CGFLOAT_MAX)];
    CGFloat baselineOffsetFromBottomCase = 0.0;

    if ([(id)self.glintyStringViewCase respondsToSelector:@selector(baselineOffsetFromBottomWithSize:)]) { baselineOffsetFromBottomCase = [(id)self.glintyStringViewCase baselineOffsetFromBottomWithSize:contentSizeCase]; }
    else if ([(id)self.glintyStringViewCase respondsToSelector:@selector(_baselineOffsetFromBottom)]) { baselineOffsetFromBottomCase = [(id)self.glintyStringViewCase _baselineOffsetFromBottom]; }

    CGFloat contentOriginXCase = LBPixelRound((CGRectGetWidth(self.bounds) - availableWidthCase) / 2.0);
    CGFloat contentOriginYCase = CGRectGetHeight(self.bounds) - contentSizeCase.height - slideInsetsCase.bottom + baselineOffsetFromBottomCase;

    if (LBShouldApplySlideToUnlockOverlayMargin(self.dashboardViewCase)) { contentOriginYCase -= LBSlideToUnlockOverlayMargin(); }

    CGRect contentFrameCase = CGRectMake(contentOriginXCase, contentOriginYCase, availableWidthCase, contentSizeCase.height);
    BOOL springFrameChangedCase = !CGRectEqualToRect(self.springViewCase.frame, contentFrameCase);
    if (springFrameChangedCase) { self.springViewCase.frame = contentFrameCase; }

    CGRect glintyFrameCase = self.springViewCase.bounds;
    BOOL glintyFrameChangedCase = !CGRectEqualToRect(self.glintyStringViewCase.frame, glintyFrameCase);
    if (glintyFrameChangedCase) { self.glintyStringViewCase.frame = glintyFrameCase; }

    if (springFrameChangedCase || glintyFrameChangedCase) { [self updateSlideAppearance]; }
}

@end

static LBSlideToUnlockView *LBSlideToUnlockViewForDashboard(UIView *dashboardViewCase) {
    return (LBSlideToUnlockView *)LBLockScreenViewForDashboard(dashboardViewCase, lbSlideToUnlockViewAssociationKeyCase, [LBSlideToUnlockView class]);
}

void LBShowSlideToUnlockAuthenticationFailure(UIView *dashboardViewCase) {
    if (!dashboardViewCase) { return; }

    LBSlideToUnlockView *slideToUnlockViewCase = LBSlideToUnlockViewForDashboard(dashboardViewCase);
    [slideToUnlockViewCase shakeSlideToUnlockTextWithCustomText:LBLocalizedTryAgainText()];
}

// Creates and attaches the Slide to Unlock view to the active dashboard.
void LBInstallSlideToUnlockView(UIView *dashboardViewCase) {
    if (!dashboardViewCase.window) { return; }

    LBSlideToUnlockView *slideToUnlockViewCase = LBSlideToUnlockViewForDashboard(dashboardViewCase);
    if (!slideToUnlockViewCase) {
        slideToUnlockViewCase = [[LBSlideToUnlockView alloc] initWithFrame:dashboardViewCase.bounds dashboardView:dashboardViewCase];
        slideToUnlockViewCase.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }

    slideToUnlockViewCase.dashboardViewCase = dashboardViewCase;
    LBAttachLockScreenView(slideToUnlockViewCase, dashboardViewCase, lbSlideToUnlockViewAssociationKeyCase);
}

void LBRemoveSlideToUnlockView(UIView *dashboardViewCase) { LBRemoveLockScreenViewForDashboard(dashboardViewCase, lbSlideToUnlockViewAssociationKeyCase); }
void LBUpdateSlideToUnlockView(UIView *dashboardViewCase) { LBUpdateLockScreenFeature(dashboardViewCase, lbSlideToUnlockViewAssociationKeyCase, NO, LBInstallSlideToUnlockView); }
void LBUpdateSlideToUnlockAppearance(UIView *dashboardViewCase) { [LBSlideToUnlockViewForDashboard(dashboardViewCase) updateSlideAppearance]; }
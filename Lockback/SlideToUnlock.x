// This restores the Slide to Unlock interface and unlock behavior.

#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "LockbackUtils.h"

@interface NSObject (LBSlideToUnlockPrivateMethods)
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
- (void)updateText;
- (void)startAnimating;
- (void)stopAnimating;
- (CGFloat)_baselineOffsetFromBottom;
- (CGFloat)baselineOffsetFromBottomWithSize:(CGSize)viewSizeCase;
- (CGRect)labelFrame;
- (CGRect)chevronFrame;
- (id)contentColor;
- (id)legibilitySettings;
- (UIColor *)averageColorInRect:(CGRect)rectCase forVariant:(NSInteger)wallpaperVariantCase;
- (CGFloat)contrastInRect:(CGRect)rectCase forVariant:(NSInteger)wallpaperVariantCase;
- (id)pageViewController;
- (NSArray *)pageViews;
- (NSUInteger)currentPageIndex;
- (void)resetScrollViewToMainPageAnimated:(BOOL)animatedCase withCompletion:(id)completionCase;
- (BOOL)_hasLockContentUnderlayRequesterOtherThanRequester:(id)requesterCase;
- (void)setSource:(int)sourceCase;
- (void)setIntent:(int)intentCase;
- (void)setName:(NSString *)nameCase;
- (BOOL)unlockWithRequest:(id)requestCase completion:(void (^)(BOOL successCase))completionCase;
@end

static const void *lbSlideToUnlockViewAssociationKeyCase = &lbSlideToUnlockViewAssociationKeyCase;
static const void *lbUnlockRequestedAssociationKeyCase = &lbUnlockRequestedAssociationKeyCase;

// Creates the same SpringBoard unlock request used when the user completes Slide to Unlock.
static BOOL LBRequestUnlock(void (^completionCase)(BOOL successCase)) {
    Class unlockRequestClassCase = NSClassFromString(@"SBLockScreenUnlockRequest");
    id unlockRequestCase = unlockRequestClassCase ? [[unlockRequestClassCase alloc] init] : nil;

    if (!unlockRequestCase ||
        ![unlockRequestCase respondsToSelector:@selector(setSource:)] ||
        ![unlockRequestCase respondsToSelector:@selector(setIntent:)] ||
        ![unlockRequestCase respondsToSelector:@selector(setName:)]) {
        return NO;
    }

    [unlockRequestCase setSource:23];
    [unlockRequestCase setIntent:3];
    [unlockRequestCase setName:@"-[UIApplication requestDeviceUnlock]"];

    id lockScreenManagerCase = LBSharedInstance(@"SBLockScreenManager");
    if (![lockScreenManagerCase respondsToSelector:@selector(unlockWithRequest:completion:)]) { return NO; }

    [lockScreenManagerCase unlockWithRequest:unlockRequestCase completion:completionCase];
    return YES;
}

// Creates a lightweight dashboard page controller used as the Slide to Unlock destination.
static Class LBUnlockPageViewControllerClass(void) {
    Class unlockPageViewControllerClassCase = NSClassFromString(@"LBUnlockPageViewController");
    if (unlockPageViewControllerClassCase) { return unlockPageViewControllerClassCase; }

    Class pageViewControllerClassCase = NSClassFromString(@"SBDashBoardPageViewController");
    if (!pageViewControllerClassCase) { return Nil; }

    unlockPageViewControllerClassCase = objc_allocateClassPair(pageViewControllerClassCase, "LBUnlockPageViewController", 0);
    if (unlockPageViewControllerClassCase) { objc_registerClassPair(unlockPageViewControllerClassCase); }

    return unlockPageViewControllerClassCase ?: NSClassFromString(@"LBUnlockPageViewController");
}

// Removes the Today View and Camera pages and inserts the custom unlock page beside the main page.
static NSArray *LBSlidePageViewControllers(NSArray *pageViewControllersCase, id mainPageViewControllerCase) {
    Class todayPageClassCase = NSClassFromString(@"SBDashBoardTodayPageViewController");
    Class cameraPageClassCase = NSClassFromString(@"SBDashBoardCameraPageViewController");
    Class unlockPageClassCase = LBUnlockPageViewControllerClass();

    NSMutableArray *slidePageViewControllersCase = [NSMutableArray arrayWithCapacity:pageViewControllersCase.count + 1];

    for (NSUInteger pageViewControllerIndexCase = 0; pageViewControllerIndexCase < pageViewControllersCase.count; pageViewControllerIndexCase++) {
        id pageViewControllerCase = pageViewControllersCase[pageViewControllerIndexCase];

        if ((todayPageClassCase && [pageViewControllerCase isKindOfClass:todayPageClassCase]) ||
            (cameraPageClassCase && [pageViewControllerCase isKindOfClass:cameraPageClassCase]) ||
            (unlockPageClassCase && [pageViewControllerCase isKindOfClass:unlockPageClassCase])) {
            continue;
        }

        [slidePageViewControllersCase addObject:pageViewControllerCase];
    }

    NSUInteger mainPageIndexCase = [slidePageViewControllersCase indexOfObjectIdenticalTo:mainPageViewControllerCase];

    if (mainPageIndexCase == NSNotFound) {
        [slidePageViewControllersCase addObject:mainPageViewControllerCase];
        mainPageIndexCase = slidePageViewControllersCase.count - 1;
    }

    id unlockPageViewControllerCase = unlockPageClassCase ? [[unlockPageClassCase alloc] initWithNibName:nil bundle:nil] : nil;
    if (!unlockPageViewControllerCase) { return slidePageViewControllersCase; }

    BOOL rightToLeftCase = [UIApplication sharedApplication].userInterfaceLayoutDirection == UIUserInterfaceLayoutDirectionRightToLeft;
    NSUInteger unlockPageIndexCase = rightToLeftCase ? mainPageIndexCase + 1 : mainPageIndexCase;

    [slidePageViewControllersCase insertObject:unlockPageViewControllerCase atIndex:unlockPageIndexCase];
    return slidePageViewControllersCase;
}

// Checks whether a dashboard page view belongs to Lockback's unlock page controller.
static BOOL LBIsUnlockPageView(id pageViewCase) {
    if (![pageViewCase respondsToSelector:@selector(pageViewController)]) { return NO; }

    Class unlockPageViewControllerClassCase = NSClassFromString(@"LBUnlockPageViewController");
    return unlockPageViewControllerClassCase && [[pageViewCase pageViewController] isKindOfClass:unlockPageViewControllerClassCase];
}

// Checks whether the dashboard finished scrolling onto the custom unlock page.
static BOOL LBScrollViewIsOnUnlockPage(id scrollViewCase) {
    if (![scrollViewCase respondsToSelector:@selector(pageViews)] || ![scrollViewCase respondsToSelector:@selector(currentPageIndex)]) { return NO; }

    NSArray *pageViewsCase = [scrollViewCase pageViews];
    NSUInteger currentPageIndexCase = [scrollViewCase currentPageIndex];

    return currentPageIndexCase < pageViewsCase.count && LBIsUnlockPageView(pageViewsCase[currentPageIndexCase]);
}

// Returns the dashboard to the main lock screen page after a failed unlock.
static void LBResetDashboardToMainPage(id dashboardViewCase, BOOL animatedCase) {
    if ([dashboardViewCase respondsToSelector:@selector(resetScrollViewToMainPageAnimated:withCompletion:)]) { [dashboardViewCase resetScrollViewToMainPageAnimated:animatedCase withCompletion:nil]; }
}

static void LBClearUnlockRequest(id dashboardViewCase) { LBSetAssociatedObject(dashboardViewCase, lbUnlockRequestedAssociationKeyCase, nil); }

// Requests an unlock once the Slide to Unlock page has been reached.
static void LBRequestSlideUnlock(id dashboardViewCase) {
    if ([objc_getAssociatedObject(dashboardViewCase, lbUnlockRequestedAssociationKeyCase) boolValue]) { return; }

    LBSetAssociatedObject(dashboardViewCase, lbUnlockRequestedAssociationKeyCase, @YES);

    if (LBRequestUnlock(^(BOOL successCase) {
        if (!successCase) {
            LBClearUnlockRequest(dashboardViewCase);
            LBResetDashboardToMainPage(dashboardViewCase, YES);
        }
    })) {
        return;
    }

    LBClearUnlockRequest(dashboardViewCase);
    LBResetDashboardToMainPage(dashboardViewCase, YES);
}

// Loads SpringBoard's localized Slide to Unlock text.
static NSString *LBLocalizedSlideToUnlockText(void) {
    NSString *localizedSlideTextCase = [[NSBundle mainBundle] localizedStringForKey:@"AWAY_LOCK_LABEL" value:@"slide to unlock" table:@"SpringBoard"];
    return localizedSlideTextCase.length ? localizedSlideTextCase : @"slide to unlock";
}

static UIEdgeInsets LBSlideToUnlockInsets(void) {
    Class lockScreenMetricsClassCase = NSClassFromString(@"SBFLockScreenMetrics");
    return lockScreenMetricsClassCase && [lockScreenMetricsClassCase respondsToSelector:@selector(slideToUnlockInsets)] ? [(id)lockScreenMetricsClassCase slideToUnlockInsets] : UIEdgeInsetsMake(0.0, 10.0, 20.0, 10.0);
}

static CGFloat LBSlideToUnlockOverlayMargin(void) {
    Class lockScreenMetricsClassCase = NSClassFromString(@"SBFLockScreenMetrics");
    return lockScreenMetricsClassCase &&
        [lockScreenMetricsClassCase respondsToSelector:@selector(slideToUnlockOverlayMargin)]
        ? [(id)lockScreenMetricsClassCase slideToUnlockOverlayMargin] : UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? 22.0 : 0.0;
}

static BOOL LBShouldApplySlideToUnlockOverlayMargin(UIView *dashboardViewCase) {
    return ![dashboardViewCase respondsToSelector:@selector(_hasLockContentUnderlayRequesterOtherThanRequester:)] || ![(id)dashboardViewCase _hasLockContentUnderlayRequesterOtherThanRequester:nil];
}

// Owns the recreated glinty Slide to Unlock label and its wallpaper-aware appearance.
@interface LBSlideToUnlockView : UIView
@property (nonatomic, weak) UIView *dashboardViewCase;
@property (nonatomic, strong) UIView *parentSpringViewCase;
@property (nonatomic, strong) UIView *springViewCase;
@property (nonatomic, strong) UIView *glintyStringViewCase;
@property (nonatomic, strong) UIView *slideToUnlockBackgroundViewCase;
- (instancetype)initWithFrame:(CGRect)viewFrameCase dashboardView:(UIView *)dashboardViewCase;
- (void)refreshSlideContent;
- (void)updateSlideAppearance;
- (void)startSlideAnimation;
- (void)stopSlideAnimation;
@end

@implementation LBSlideToUnlockView

- (instancetype)initWithFrame:(CGRect)viewFrameCase dashboardView:(UIView *)dashboardViewCase {
    self = [super initWithFrame:viewFrameCase];
    if (!self) {
        return nil;
    }

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

- (void)dealloc { [[NSNotificationCenter defaultCenter] removeObserver:self]; }

// Rebuilds the localized glinty label when its content needs to change.
- (void)refreshSlideContent {
    [self stopSlideAnimation];
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
        [self startSlideAnimation];

        return;
    }

    [self stopSlideAnimation];
}

// Starts the original glint animation when the lock screen is visible.
- (void)startSlideAnimation { if ([(id)self.glintyStringViewCase respondsToSelector:@selector(startAnimating)]) { [(id)self.glintyStringViewCase startAnimating]; } }

// Stops the glint and spring animations when the lock screen leaves the screen.
- (void)stopSlideAnimation {
    [self.springViewCase.layer removeAllAnimations];
    [self.parentSpringViewCase.layer removeAllAnimations];

    if ([(id)self.glintyStringViewCase respondsToSelector:@selector(stopAnimating)]) { [(id)self.glintyStringViewCase stopAnimating]; }
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

    if ([glintyStringViewCase respondsToSelector:@selector(setBackgroundView:)]) {
        [(id)glintyStringViewCase setBackgroundView:referenceColorCase ? self.slideToUnlockBackgroundViewCase : nil];
    }

    if ([glintyStringViewCase respondsToSelector:@selector(setVibrantSettings:)]) {
        [(id)glintyStringViewCase setVibrantSettings:LBCreateVibrantSettings(referenceColorCase, referenceContrastCase, legibilitySettingsCase)];
    }

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

    CGSize fittingSizeCase = CGSizeMake(availableWidthCase, CGFLOAT_MAX);
    CGSize contentSizeCase = [self.glintyStringViewCase sizeThatFits:fittingSizeCase];

    CGFloat baselineOffsetFromBottomCase = 0.0;

    if ([(id)self.glintyStringViewCase respondsToSelector:@selector(baselineOffsetFromBottomWithSize:)]) {
        baselineOffsetFromBottomCase = [(id)self.glintyStringViewCase baselineOffsetFromBottomWithSize:contentSizeCase];
    } else if ([(id)self.glintyStringViewCase
        respondsToSelector:@selector(_baselineOffsetFromBottom)]) {
        baselineOffsetFromBottomCase = [(id)self.glintyStringViewCase _baselineOffsetFromBottom];
    }

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

// These empty callbacks satisfy the private glinty view delegate used by SpringBoard.
- (void)glintyFadeOutAnimationDidStop {}
- (void)glintyFadeInAnimationDidStop {}
- (void)glintyAnimationDidStart {}
- (void)glintyAnimationDidStop {}

@end

static LBSlideToUnlockView *LBSlideToUnlockViewForDashboard(UIView *dashboardViewCase) {
    return (LBSlideToUnlockView *)LBLockScreenViewForDashboard(dashboardViewCase, lbSlideToUnlockViewAssociationKeyCase, [LBSlideToUnlockView class]);
}

// Creates and attaches the Slide to Unlock view to the active dashboard.
static void LBInstallSlideToUnlockView(UIView *dashboardViewCase) {
    if (!dashboardViewCase.window) { return; }

    LBSlideToUnlockView *slideToUnlockViewCase = LBSlideToUnlockViewForDashboard(dashboardViewCase);

    if (!slideToUnlockViewCase) {
        slideToUnlockViewCase = [[LBSlideToUnlockView alloc] initWithFrame:dashboardViewCase.bounds dashboardView:dashboardViewCase];
        slideToUnlockViewCase.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }

    slideToUnlockViewCase.dashboardViewCase = dashboardViewCase;
    LBAttachLockScreenView(slideToUnlockViewCase, dashboardViewCase, lbSlideToUnlockViewAssociationKeyCase);
}

%group LBSlideToUnlock

%hook SBDashBoardViewController

- (void)_setPageViewControllers:(NSArray *)pageViewControllersCase {
    if (!LBLockbackEnabled()) {
        %orig;
        return;
    }

    Class mainPageViewControllerClassCase = NSClassFromString(@"SBDashBoardMainPageViewController");
    id mainPageViewControllerCase = nil;

    for (NSUInteger pageViewControllerIndexCase = 0; pageViewControllerIndexCase < pageViewControllersCase.count; pageViewControllerIndexCase++) {
        id pageViewControllerCase = pageViewControllersCase[pageViewControllerIndexCase];

        if (mainPageViewControllerClassCase && [pageViewControllerCase isKindOfClass:mainPageViewControllerClassCase]) {
            mainPageViewControllerCase = pageViewControllerCase;
            break;
        }
    }

    if (mainPageViewControllerCase) { pageViewControllersCase = LBSlidePageViewControllers(pageViewControllersCase, mainPageViewControllerCase); }
    %orig;
}

- (void)activateTodayViewWithCompletion:(void (^)(void))completionHandlerCase {
    if (!LBLockbackEnabled()) {
        %orig;
        return;
    }

    if (completionHandlerCase) { completionHandlerCase(); }
}

- (void)activateCameraAnimated:(BOOL)isAnimatedCase withActions:(id)cameraActionsCase {
    if (!LBLockbackEnabled()) {
        %orig;
    }
}

%end

%hook SBDashBoardView

- (void)didMoveToWindow {
    %orig;

    UIView *dashboardViewCase = (UIView *)self;
    if (!dashboardViewCase.window || !LBLockbackEnabled()) {
        LBRemoveLockScreenViewForDashboard(dashboardViewCase, lbSlideToUnlockViewAssociationKeyCase);
        LBClearUnlockRequest(dashboardViewCase);

        return;
    }

    LBInstallSlideToUnlockView(dashboardViewCase);
}

- (void)layoutSubviews {
    %orig;
    LBUpdateLockScreenFeature((UIView *)self, lbSlideToUnlockViewAssociationKeyCase, NO, LBInstallSlideToUnlockView);
}

- (void)scrollViewDidEndScrolling:(id)scrollViewCase {
    %orig;

    if (!LBLockbackEnabled()) { return; }

    UIView *dashboardViewCase = (UIView *)self;
    if (LBScrollViewIsOnUnlockPage(scrollViewCase)) {
        LBRequestSlideUnlock(dashboardViewCase);
        return;
    }

    LBClearUnlockRequest(dashboardViewCase);
}

- (void)setLegibilitySettings:(id)legibilitySettingsCase {
    %orig;
    if (LBLockbackEnabled()) { [LBSlideToUnlockViewForDashboard((UIView *)self) updateSlideAppearance]; }
}

- (void)setLegibilitySettingsOverrideVibrancy:(BOOL)overrideVibrancyCase {
    %orig;
    if (LBLockbackEnabled()) { [LBSlideToUnlockViewForDashboard((UIView *)self) updateSlideAppearance]; }
}

%end

%end

void LBInitializeSlideToUnlock(void) { %init(LBSlideToUnlock); }
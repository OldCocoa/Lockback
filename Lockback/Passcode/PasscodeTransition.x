// This recreates the old iOS passcode blur, tint, and overscroll transition.

#import <UIKit/UIKit.h>
#import "../LockbackUtils.h"
#import "PasscodeShared.h"
#import "../Notifications/NotificationsShared.h"

typedef struct {
    NSInteger baseStyleCase;
    NSInteger blurStyleCase;
    CGFloat progressCase;
} LBWallpaperStyleTransitionStateCase;

@interface NSObject (LBPasscodeTransitionPrivateMethods)
- (id)dashBoardViewController;
- (id)scrollView;
- (NSArray *)pageViews;
- (id)pageViewController;
- (void)setDisallowsRasterization:(BOOL)disallowsRasterizationCase forVariant:(NSInteger)variantCase withReason:(NSString *)reasonCase;
- (BOOL)setWallpaperStyleTransitionState:(LBWallpaperStyleTransitionStateCase)transitionStateCase forPriority:(NSInteger)priorityCase forVariant:(NSInteger)variantCase withAnimationFactory:(id)animationFactoryCase;
- (void)setBackgroundAlpha:(CGFloat)backgroundAlphaCase;
+ (id)overlayPropertiesFactoryWithStyle:(NSInteger)styleCase;
- (id)propertiesWithGraphicsQuality:(NSInteger)graphicsQualityCase;
- (CGFloat)tintAlpha;
- (UIColor *)tintColor;
@end

static const void *lbLegacyPasscodeMainTintViewAssociationKeyCase = &lbLegacyPasscodeMainTintViewAssociationKeyCase;
static const void *lbLegacyPasscodeOverscrollTintViewAssociationKeyCase = &lbLegacyPasscodeOverscrollTintViewAssociationKeyCase;

// Keeps passcode transition progress within the valid page range.
static CGFloat LBClampPasscodeProgress(CGFloat progressCase) { return MAX(0.0, MIN(1.0, progressCase)); }

// Loads the iOS overlay style that matches the legacy passcode appearance.
static id LBPasscodeOverlayProperties(void) {
    Class overlayPropertiesFactoryClassCase = NSClassFromString(@"SBLockOverlayStylePropertiesFactory");
    if (!overlayPropertiesFactoryClassCase || ![overlayPropertiesFactoryClassCase respondsToSelector:@selector(overlayPropertiesFactoryWithStyle:)]) { return nil; }

    id overlayPropertiesFactoryCase = [(id)overlayPropertiesFactoryClassCase overlayPropertiesFactoryWithStyle:1];
    if (!overlayPropertiesFactoryCase || ![overlayPropertiesFactoryCase respondsToSelector:@selector(propertiesWithGraphicsQuality:)]) { return nil; }

    return [overlayPropertiesFactoryCase propertiesWithGraphicsQuality:100];
}

// Returns the final dark tint strength used by the passcode transition.
static CGFloat LBPasscodeBackgroundTintAlpha(void) {
    static CGFloat backgroundTintAlphaCase = -1.0;
    if (backgroundTintAlphaCase >= 0.0) { return backgroundTintAlphaCase; }

    id overlayPropertiesCase = LBPasscodeOverlayProperties();
    backgroundTintAlphaCase = overlayPropertiesCase && [overlayPropertiesCase respondsToSelector:@selector(tintAlpha)] ? LBClampPasscodeProgress([overlayPropertiesCase tintAlpha]) : 0.0;

    return backgroundTintAlphaCase;
}

// Returns the dark overlay color used by the passcode transition.
static UIColor *LBPasscodeBackgroundTintColor(void) {
    id overlayPropertiesCase = LBPasscodeOverlayProperties();
    UIColor *tintColorCase = overlayPropertiesCase && [overlayPropertiesCase respondsToSelector:@selector(tintColor)] ? [overlayPropertiesCase tintColor] : nil;

    return tintColorCase ?: [UIColor blackColor];
}

// Finds the dashboard main page that remains visible during the slide.
static UIView *LBMainPageView(void) {
    id lockScreenManagerCase = LBSharedInstance(@"SBLockScreenManager");

    id dashboardViewControllerCase = [lockScreenManagerCase respondsToSelector:@selector(dashBoardViewController)] ? [lockScreenManagerCase dashBoardViewController] : nil;
    UIView *dashboardViewCase = [dashboardViewControllerCase isKindOfClass:[UIViewController class]] ? [(UIViewController *)dashboardViewControllerCase view] : nil;

    id scrollViewCase = [dashboardViewCase respondsToSelector:@selector(scrollView)] ? [(id)dashboardViewCase scrollView] : nil;
    NSArray *pageViewsCase = [scrollViewCase respondsToSelector:@selector(pageViews)] ? [scrollViewCase pageViews] : nil;
    Class mainPageViewControllerClassCase = NSClassFromString(@"SBDashBoardMainPageViewController");

    for (NSUInteger pageViewIndexCase = 0; pageViewIndexCase < pageViewsCase.count; pageViewIndexCase++) {
        UIView *pageViewCase = [pageViewsCase[pageViewIndexCase] isKindOfClass:[UIView class]] ? pageViewsCase[pageViewIndexCase] : nil;
        id pageViewControllerCase = [pageViewCase respondsToSelector:@selector(pageViewController)] ? [(id)pageViewCase pageViewController] : nil;

        if (pageViewCase && mainPageViewControllerClassCase && [pageViewControllerCase isKindOfClass:mainPageViewControllerClassCase]) { return pageViewCase; }
    }

    return nil;
}

// Creates the underlay that progressively darkens the main lock screen page.
static UIView *LBPrepareMainPageTintView(UIViewController *passcodeViewControllerCase) {
    UIView *tintViewCase = objc_getAssociatedObject(passcodeViewControllerCase, lbLegacyPasscodeMainTintViewAssociationKeyCase);
    if ([tintViewCase isKindOfClass:[UIView class]]) {
        tintViewCase.frame = tintViewCase.superview.bounds;
        return tintViewCase;
    }

    UIView *mainPageViewCase = LBMainPageView();
    if (!mainPageViewCase) { return nil; }

    tintViewCase = [[UIView alloc] initWithFrame:mainPageViewCase.bounds];
    tintViewCase.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    tintViewCase.userInteractionEnabled = NO;
    tintViewCase.backgroundColor = LBPasscodeBackgroundTintColor();
    tintViewCase.alpha = 0.0;

    id mainPageViewControllerCase = [mainPageViewCase respondsToSelector:@selector(pageViewController)] ? [(id)mainPageViewCase pageViewController] : nil;
    UIView *mainPageContentViewCase = [mainPageViewControllerCase isKindOfClass:[UIViewController class]] ? [(UIViewController *)mainPageViewControllerCase view] : nil;

    if (mainPageContentViewCase.superview == mainPageViewCase) { [mainPageViewCase insertSubview:tintViewCase belowSubview:mainPageContentViewCase]; }
    else { [mainPageViewCase insertSubview:tintViewCase atIndex:0]; }

    LBSetAssociatedObject(passcodeViewControllerCase, lbLegacyPasscodeMainTintViewAssociationKeyCase, tintViewCase);
    return tintViewCase;
}

// Extends the passcode tint past the page edge so overscroll never exposes raw wallpaper.
static UIView *LBPreparePasscodeOverscrollTintView(UIViewController *passcodeViewControllerCase, UIView *passcodeViewCase) {
    UIView *pageContentViewCase = passcodeViewCase.superview;
    if (!pageContentViewCase) { return nil; }

    CGFloat pageWidthCase = CGRectGetWidth(pageContentViewCase.bounds);
    CGFloat pageHeightCase = CGRectGetHeight(pageContentViewCase.bounds);
    if (pageWidthCase <= 0.0 || pageHeightCase <= 0.0) { return nil; }

    BOOL rightToLeftCase = [UIApplication sharedApplication].userInterfaceLayoutDirection == UIUserInterfaceLayoutDirectionRightToLeft;
    CGFloat overscrollXCase = rightToLeftCase ? CGRectGetMaxX(pageContentViewCase.bounds) : CGRectGetMinX(pageContentViewCase.bounds) - pageWidthCase;
    CGRect overscrollFrameCase = CGRectMake(overscrollXCase, CGRectGetMinY(pageContentViewCase.bounds), pageWidthCase, pageHeightCase);

    UIView *tintViewCase = objc_getAssociatedObject(passcodeViewControllerCase, lbLegacyPasscodeOverscrollTintViewAssociationKeyCase);
    if (![tintViewCase isKindOfClass:[UIView class]]) {
        tintViewCase = [[UIView alloc] initWithFrame:overscrollFrameCase];
        tintViewCase.userInteractionEnabled = NO;
        tintViewCase.backgroundColor = LBPasscodeBackgroundTintColor();
        tintViewCase.alpha = 0.0;
        LBSetAssociatedObject(passcodeViewControllerCase, lbLegacyPasscodeOverscrollTintViewAssociationKeyCase, tintViewCase);
    }

    tintViewCase.frame = overscrollFrameCase;
    pageContentViewCase.clipsToBounds = NO;

    UIView *pageContainerViewCase = pageContentViewCase.superview;
    if ([pageContainerViewCase isKindOfClass:[UIView class]]) { pageContainerViewCase.clipsToBounds = NO; }

    if (tintViewCase.superview != pageContentViewCase) {
        [tintViewCase removeFromSuperview];

        if (passcodeViewCase.superview == pageContentViewCase) { [pageContentViewCase insertSubview:tintViewCase belowSubview:passcodeViewCase]; }
        else { [pageContentViewCase insertSubview:tintViewCase atIndex:0]; }
    }

    return tintViewCase;
}

// Drives SpringBoard's legacy wallpaper blur from page progress.
static void LBSetPasscodeWallpaperBlurProgress(CGFloat progressCase) {
    progressCase = LBNotificationBackgroundOwnsPasscodeBlur() ? 0.0 : LBClampPasscodeProgress(progressCase);

    id wallpaperControllerCase = LBSharedInstance(@"SBWallpaperController");
    if (!wallpaperControllerCase || ![wallpaperControllerCase respondsToSelector:@selector(setWallpaperStyleTransitionState:forPriority:forVariant:withAnimationFactory:)]) { return; }

    if ([wallpaperControllerCase respondsToSelector:@selector(setDisallowsRasterization:forVariant:withReason:)]) {
        BOOL transitioningCase = progressCase > 0.001 && progressCase < 0.999;
        [wallpaperControllerCase setDisallowsRasterization:transitioningCase forVariant:0 withReason:@"LockScreenScroll"];
    }

    LBWallpaperStyleTransitionStateCase transitionStateCase = { 0, 8, progressCase };
    [wallpaperControllerCase setWallpaperStyleTransitionState:transitionStateCase forPriority:0 forVariant:0 withAnimationFactory:nil];
}

// Updates the complete passcode tint and blur composition for the current scroll position.
void LBUpdatePasscodeTransition(UIViewController *passcodeViewControllerCase, UIView *passcodeViewCase, CGFloat progressCase) {
    progressCase = LBClampPasscodeProgress(progressCase);

    if (!passcodeViewControllerCase || !passcodeViewCase) {
        if (progressCase <= 0.0) { LBSetPasscodeWallpaperBlurProgress(0.0); }
        return;
    }

    CGFloat backgroundAlphaCase = LBPasscodeBackgroundTintAlpha() * progressCase;
    UIView *mainPageTintViewCase = LBPrepareMainPageTintView(passcodeViewControllerCase);
    UIView *overscrollTintViewCase = LBPreparePasscodeOverscrollTintView(passcodeViewControllerCase, passcodeViewCase);

    if ([passcodeViewCase respondsToSelector:@selector(setBackgroundAlpha:)]) { [(id)passcodeViewCase setBackgroundAlpha:backgroundAlphaCase]; }

    if (mainPageTintViewCase) { mainPageTintViewCase.alpha = backgroundAlphaCase; }
    if (overscrollTintViewCase) { overscrollTintViewCase.alpha = backgroundAlphaCase; }
    LBSetPasscodeWallpaperBlurProgress(progressCase);
}
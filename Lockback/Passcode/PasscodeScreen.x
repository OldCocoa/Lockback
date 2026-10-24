// This restores the old passcode screen while using modern authentication.

#import <UIKit/UIKit.h>
#import "../LockbackUtils.h"
#import "PasscodeShared.h"

@interface NSObject (LBPasscodeScreenPrivateMethods)
- (id)authenticationController;
- (BOOL)hasPasscodeSet;
- (id)dashBoardViewController;
- (id)scrollView;
- (NSArray *)pageViews;
- (id)pageViewController;
- (BOOL)_attemptUnlockWithPasscode:(id)passcodeCase finishUIUnlock:(BOOL)finishUIUnlockCase;
- (void)attemptUnlockWithMesa;
- (void)setCompletionBlock:(void (^)(BOOL successCase))completionBlockCase;
- (id)passcode;
- (id)passcodeView;
- (void)setBackgroundAlpha:(CGFloat)backgroundAlphaCase;
- (id)rootSettings;
- (id)lockScreenSettings;
- (id)passcodeSettings;
- (NSInteger)scrollBehavior;
- (CGFloat)fixedHysteresis;
- (CGFloat)percentOfNextButtonIncluded;
- (id)panGestureRecognizer;
- (void)_setHysteresis:(CGFloat)hysteresisCase;
- (void)setScrollingDisabled:(BOOL)disabledCase forRequester:(id)requesterCase;
+ (CGFloat)_inputButtonCircleSize;
+ (UIEdgeInsets)_inputButtonCircleSpacing;
@end

static const void *lbLegacyPasscodeOwnedAssociationKeyCase = &lbLegacyPasscodeOwnedAssociationKeyCase;
static const void *lbLegacyPasscodeControllerAssociationKeyCase = &lbLegacyPasscodeControllerAssociationKeyCase;
static const void *lbLegacyPasscodeActiveAssociationKeyCase = &lbLegacyPasscodeActiveAssociationKeyCase;
static const void *lbLegacyPasscodeValueAssociationKeyCase = &lbLegacyPasscodeValueAssociationKeyCase;
static const void *lbLegacyPasscodeViewAssociationKeyCase = &lbLegacyPasscodeViewAssociationKeyCase;

// Checks whether a passcode controller belongs to Lockback.
static BOOL LBIsOwnedLegacyPasscodeController(id passcodeViewControllerCase) { return [objc_getAssociatedObject(passcodeViewControllerCase, lbLegacyPasscodeOwnedAssociationKeyCase) boolValue]; }

// Returns the prepared legacy passcode controller for a dashboard page.
static UIViewController *LBPreparedPasscodeController(UIViewController *pageViewControllerCase) {
    id passcodeViewControllerCase = objc_getAssociatedObject(pageViewControllerCase, lbLegacyPasscodeControllerAssociationKeyCase);
    if (![passcodeViewControllerCase isKindOfClass:[UIViewController class]]) { return nil; }
    return LBIsOwnedLegacyPasscodeController(passcodeViewControllerCase) ? passcodeViewControllerCase : nil;
}

// Returns the passcode lock view embedded into the Slide to Unlock page.
static UIView *LBPreparedPasscodeView(UIViewController *passcodeViewControllerCase) {
    id passcodeViewCase = objc_getAssociatedObject(passcodeViewControllerCase, lbLegacyPasscodeViewAssociationKeyCase);
    return [passcodeViewCase isKindOfClass:[UIView class]] ? passcodeViewCase : nil;
}

static id LBPasscodeDashboardScrollView(void) {
    id lockScreenManagerCase = LBSharedInstance(@"SBLockScreenManager");
    id dashboardViewControllerCase = [lockScreenManagerCase respondsToSelector:@selector(dashBoardViewController)] ? [lockScreenManagerCase dashBoardViewController] : nil;
    UIView *dashboardViewCase = [dashboardViewControllerCase isKindOfClass:[UIViewController class]] ? [(UIViewController *)dashboardViewControllerCase view] : nil;
    return [dashboardViewCase respondsToSelector:@selector(scrollView)] ? [(id)dashboardViewCase scrollView] : nil;
}

// Returns SpringBoard's current passcode scrolling settings.
static id LBPasscodeSettings(void) {
    id prototypeControllerCase = LBSharedInstance(@"SBPrototypeController");
    id rootSettingsCase = [prototypeControllerCase respondsToSelector:@selector(rootSettings)] ? [prototypeControllerCase rootSettings] : nil;
    id lockScreenSettingsCase = [rootSettingsCase respondsToSelector:@selector(lockScreenSettings)] ? [rootSettingsCase lockScreenSettings] : nil;
    return [lockScreenSettingsCase respondsToSelector:@selector(passcodeSettings)] ? [lockScreenSettingsCase passcodeSettings] : nil;
}

static CGFloat LBPasscodeButtonHysteresis(id passcodeSettingsCase) {
    NSInteger scrollBehaviorCase = [passcodeSettingsCase respondsToSelector:@selector(scrollBehavior)] ? [passcodeSettingsCase scrollBehavior] : 2;

    if (scrollBehaviorCase == 0) { return 10.0; }
    if (scrollBehaviorCase == 1) { return [passcodeSettingsCase respondsToSelector:@selector(fixedHysteresis)] ? [passcodeSettingsCase fixedHysteresis] : 60.0; }

    Class numberPadClassCase = NSClassFromString(@"SBUIPasscodeLockNumberPad");
    if (!numberPadClassCase || ![numberPadClassCase respondsToSelector:@selector(_inputButtonCircleSize)] || ![numberPadClassCase respondsToSelector:@selector(_inputButtonCircleSpacing)]) { return 60.0; }

    CGFloat circleSizeCase = [(id)numberPadClassCase _inputButtonCircleSize];
    UIEdgeInsets circleSpacingCase = [(id)numberPadClassCase _inputButtonCircleSpacing];
    CGFloat includedButtonPercentageCase = [passcodeSettingsCase respondsToSelector:@selector(percentOfNextButtonIncluded)] ? [passcodeSettingsCase percentOfNextButtonIncluded] : 0.1;

    return circleSizeCase + circleSpacingCase.left + circleSpacingCase.right + (circleSizeCase * includedButtonPercentageCase);
}

// Applies or removes the temporary keypad scrolling hysteresis.
static void LBSetPasscodeButtonHysteresis(BOOL enabledCase) {
    id scrollViewCase = LBPasscodeDashboardScrollView();
    id panGestureRecognizerCase = [scrollViewCase respondsToSelector:@selector(panGestureRecognizer)] ? [scrollViewCase panGestureRecognizer] : nil;

    if (!enabledCase) {
        if ([scrollViewCase respondsToSelector:@selector(setScrollingDisabled:forRequester:)]) { [scrollViewCase setScrollingDisabled:NO forRequester:@"TemporaryPasscodeButtonHysteresis"]; }
        if ([panGestureRecognizerCase respondsToSelector:@selector(_setHysteresis:)]) { [panGestureRecognizerCase _setHysteresis:10.0]; }
        return;
    }

    id passcodeSettingsCase = LBPasscodeSettings();
    NSInteger scrollBehaviorCase = [passcodeSettingsCase respondsToSelector:@selector(scrollBehavior)] ? [passcodeSettingsCase scrollBehavior] : 2;

    if (scrollBehaviorCase == 3) {
        if ([scrollViewCase respondsToSelector:@selector(setScrollingDisabled:forRequester:)]) { [scrollViewCase setScrollingDisabled:YES forRequester:@"TemporaryPasscodeButtonHysteresis"]; }
        return;
    }

    if ([panGestureRecognizerCase respondsToSelector:@selector(_setHysteresis:)]) { [panGestureRecognizerCase _setHysteresis:LBPasscodeButtonHysteresis(passcodeSettingsCase)]; }
}

// Checks whether the device currently requires passcode authentication.
BOOL LBPasscodeScreenRequired(void) {
    UIApplication *springBoardCase = [UIApplication sharedApplication];
    if (![springBoardCase respondsToSelector:@selector(authenticationController)]) { return NO; }

    id authenticationControllerCase = [(id)springBoardCase authenticationController];
    return [authenticationControllerCase respondsToSelector:@selector(hasPasscodeSet)] && [authenticationControllerCase hasPasscodeSet];
}

// Creates and embeds the legacy passcode lock view into the unlock page.
BOOL LBPreparePasscodeScreenForPageController(UIViewController *pageViewControllerCase) {
    if (!pageViewControllerCase) { return NO; }
    if (LBPreparedPasscodeController(pageViewControllerCase)) { return YES; }
    if (!LBPasscodeScreenRequired()) { return NO; }

    Class passcodeViewControllerClassCase = NSClassFromString(@"SBLockScreenPasscodeOverlayViewController");
    UIViewController *passcodeViewControllerCase = passcodeViewControllerClassCase ? [[passcodeViewControllerClassCase alloc] init] : nil;
    if (!passcodeViewControllerCase) { return NO; }

    UIView *pageViewCase = pageViewControllerCase.view;
    if (!pageViewCase || !passcodeViewControllerCase.view) { return NO; }

    Ivar passcodeContainerViewIvarCase = class_getInstanceVariable(passcodeViewControllerClassCase, "_passcodeView");
    id passcodeContainerViewCase = passcodeContainerViewIvarCase ? object_getIvar(passcodeViewControllerCase, passcodeContainerViewIvarCase) : nil;

    UIView *passcodeViewCase = [passcodeContainerViewCase respondsToSelector:@selector(passcodeView)] ? [passcodeContainerViewCase passcodeView] : nil;
    if (![passcodeViewCase isKindOfClass:[UIView class]]) { return NO; }

    LBSetAssociatedObject(passcodeViewControllerCase, lbLegacyPasscodeOwnedAssociationKeyCase, @YES);
    LBSetAssociatedObject(passcodeViewControllerCase, lbLegacyPasscodeViewAssociationKeyCase, passcodeViewCase);
    LBSetAssociatedObject(pageViewControllerCase, lbLegacyPasscodeControllerAssociationKeyCase, passcodeViewControllerCase);

    [passcodeViewCase removeFromSuperview];
    passcodeViewCase.frame = pageViewCase.bounds;
    passcodeViewCase.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    passcodeViewCase.alpha = 1.0;

    if ([passcodeViewCase respondsToSelector:@selector(setBackgroundAlpha:)]) { [passcodeViewCase setBackgroundAlpha:0.0]; }

    [pageViewCase addSubview:passcodeViewCase];
    return YES;
}

// Updates the passcode appearance as the dashboard moves between pages.
void LBUpdatePasscodeScreenScrollProgress(UIViewController *pageViewControllerCase, CGFloat progressCase) {
    UIViewController *passcodeViewControllerCase = LBPreparedPasscodeController(pageViewControllerCase);
    if (!passcodeViewControllerCase && progressCase > 0.0 && LBPreparePasscodeScreenForPageController(pageViewControllerCase)) { passcodeViewControllerCase = LBPreparedPasscodeController(pageViewControllerCase); }

    UIView *passcodeViewCase = passcodeViewControllerCase ? LBPreparedPasscodeView(passcodeViewControllerCase) : nil;
    LBUpdatePasscodeTransition(passcodeViewControllerCase, passcodeViewCase, progressCase);
}

// Deactivates the passcode controller when leaving its dashboard page.
void LBDeactivatePasscodeScreenForPageController(UIViewController *pageViewControllerCase) {
    UIViewController *passcodeViewControllerCase = LBPreparedPasscodeController(pageViewControllerCase);
    if (!passcodeViewControllerCase) { return; }

    LBSetPasscodeButtonHysteresis(NO);

    if (![objc_getAssociatedObject(passcodeViewControllerCase, lbLegacyPasscodeActiveAssociationKeyCase) boolValue]) { return; }

    [passcodeViewControllerCase beginAppearanceTransition:NO animated:YES];
    [passcodeViewControllerCase endAppearanceTransition];
    [LBPreparedPasscodeView(passcodeViewControllerCase) endEditing:YES];

    LBSetAssociatedObject(passcodeViewControllerCase, lbLegacyPasscodeActiveAssociationKeyCase, nil);
}

// Cancels passcode entry and returns the dashboard to Slide to Unlock.
static void LBCancelPasscodeScreen(UIViewController *pageViewControllerCase, UIViewController *passcodeViewControllerCase) {
    LBSetAssociatedObject(passcodeViewControllerCase, lbLegacyPasscodeValueAssociationKeyCase, nil);
    LBDeactivatePasscodeScreenForPageController(pageViewControllerCase);
    LBResetSlideToUnlockAfterPasscodeCancellation();
}

// Submits the authenticated passcode through the iOS lock screen manager.
static BOOL LBAttemptPasscodeUnlock(UIViewController *passcodeViewControllerCase) {
    id lockScreenManagerCase = LBSharedInstance(@"SBLockScreenManager");
    id passcodeCase = objc_getAssociatedObject(passcodeViewControllerCase, lbLegacyPasscodeValueAssociationKeyCase);

    LBSetAssociatedObject(passcodeViewControllerCase, lbLegacyPasscodeValueAssociationKeyCase, nil);

    if (passcodeCase && [lockScreenManagerCase respondsToSelector:@selector(_attemptUnlockWithPasscode:finishUIUnlock:)]) { return [lockScreenManagerCase _attemptUnlockWithPasscode:passcodeCase finishUIUnlock:YES]; }

    if ([lockScreenManagerCase respondsToSelector:@selector(attemptUnlockWithMesa)]) {
        [lockScreenManagerCase attemptUnlockWithMesa];
        return YES;
    }

    return NO;
}

// Activates the prepared passcode controller when the unlock page is reached.
BOOL LBActivatePasscodeScreenForPageController(UIViewController *pageViewControllerCase) {
    if (!pageViewControllerCase) { return NO; }
    if (!LBPreparedPasscodeController(pageViewControllerCase) && !LBPreparePasscodeScreenForPageController(pageViewControllerCase)) { return NO; }

    UIViewController *passcodeViewControllerCase = LBPreparedPasscodeController(pageViewControllerCase);
    if (!passcodeViewControllerCase) { return NO; }
    if ([objc_getAssociatedObject(passcodeViewControllerCase, lbLegacyPasscodeActiveAssociationKeyCase) boolValue]) { return YES; }

    __unsafe_unretained UIViewController *unsafePasscodeViewControllerCase = passcodeViewControllerCase;
    __unsafe_unretained UIViewController *unsafePageViewControllerCase = pageViewControllerCase;

    if ([passcodeViewControllerCase respondsToSelector:@selector(setCompletionBlock:)]) {
        [(id)passcodeViewControllerCase setCompletionBlock:^(BOOL successCase) {
            UIViewController *strongPasscodeViewControllerCase = unsafePasscodeViewControllerCase;
            UIViewController *strongPageViewControllerCase = unsafePageViewControllerCase;

            if (!strongPasscodeViewControllerCase || !strongPageViewControllerCase || !LBIsOwnedLegacyPasscodeController(strongPasscodeViewControllerCase)) { return; }

            if (!successCase) {
                LBCancelPasscodeScreen(strongPageViewControllerCase, strongPasscodeViewControllerCase);
                return;
            }

            if (!LBAttemptPasscodeUnlock(strongPasscodeViewControllerCase)) { LBCancelPasscodeScreen(strongPageViewControllerCase, strongPasscodeViewControllerCase); }
        }];
    }

    LBSetAssociatedObject(passcodeViewControllerCase, lbLegacyPasscodeActiveAssociationKeyCase, @YES);
    LBUpdatePasscodeScreenScrollProgress(pageViewControllerCase, 1.0);

    [passcodeViewControllerCase beginAppearanceTransition:YES animated:NO];
    [passcodeViewControllerCase endAppearanceTransition];
    return YES;
}

// Finds the unlock page and activates its prepared passcode controller.
BOOL LBPresentPasscodeScreen(void) {
    id lockScreenManagerCase = LBSharedInstance(@"SBLockScreenManager");

    id dashboardViewControllerCase = [lockScreenManagerCase respondsToSelector:@selector(dashBoardViewController)] ? [lockScreenManagerCase dashBoardViewController] : nil;
    UIView *dashboardViewCase = [dashboardViewControllerCase isKindOfClass:[UIViewController class]] ? [(UIViewController *)dashboardViewControllerCase view] : nil;

    id scrollViewCase = [dashboardViewCase respondsToSelector:@selector(scrollView)] ? [(id)dashboardViewCase scrollView] : nil;
    NSArray *pageViewsCase = [scrollViewCase respondsToSelector:@selector(pageViews)] ? [scrollViewCase pageViews] : nil;
    Class unlockPageViewControllerClassCase = NSClassFromString(@"LBUnlockPageViewController");

    for (NSUInteger pageViewIndexCase = 0; pageViewIndexCase < pageViewsCase.count; pageViewIndexCase++) {
        id pageViewCase = pageViewsCase[pageViewIndexCase];
        id pageViewControllerCase = [pageViewCase respondsToSelector:@selector(pageViewController)] ? [pageViewCase pageViewController] : nil;

        if (unlockPageViewControllerClassCase && [pageViewControllerCase isKindOfClass:unlockPageViewControllerClassCase]) { return LBActivatePasscodeScreenForPageController(pageViewControllerCase); }
    }

    return NO;
}

%group LBPasscodeScreen

%hook SBLockScreenPasscodeOverlayViewController

- (void)passcodeLockViewPasscodeEntered:(id)passcodeLockViewCase {
    if (LBIsOwnedLegacyPasscodeController(self)) {
        id passcodeCase = [passcodeLockViewCase respondsToSelector:@selector(passcode)] ? [passcodeLockViewCase passcode] : nil;
        LBSetAssociatedObject(self, lbLegacyPasscodeValueAssociationKeyCase, passcodeCase);
    }

    %orig;
}

- (void)passcodeLockViewPasscodeEnteredViaMesa:(id)passcodeLockViewCase {
    if (LBIsOwnedLegacyPasscodeController(self)) { LBSetAssociatedObject(self, lbLegacyPasscodeValueAssociationKeyCase, nil); }
    %orig;
}

%new
- (void)passcodeLockViewKeypadKeyDown:(id)passcodeLockViewCase { if (LBIsOwnedLegacyPasscodeController(self)) { LBSetPasscodeButtonHysteresis(YES); } }

%new
- (void)passcodeLockViewKeypadKeyUp:(id)passcodeLockViewCase { if (LBIsOwnedLegacyPasscodeController(self)) { LBSetPasscodeButtonHysteresis(NO); } }

%end

%end

void LBInitializePasscodeScreen(void) { %init(LBPasscodeScreen); }
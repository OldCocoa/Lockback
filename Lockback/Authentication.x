// This handles Slide to Unlock authentication and passcode activation.

#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "LockbackUtils.h"
#import "Authentication.h"
#import "Passcode/PasscodeShared.h"
#import "SlideToUnlock/SlideToUnlockShared.h"
#import "DashboardPaging.h"

@interface NSObject (LBAuthenticationPrivateMethods)
- (id)scrollView;
- (void)resetScrollViewToMainPageAnimated:(BOOL)animatedCase withCompletion:(id)completionCase;
- (void)setSource:(int)sourceCase;
- (void)setIntent:(int)intentCase;
- (void)setName:(NSString *)nameCase;
- (BOOL)unlockWithRequest:(id)requestCase completion:(void (^)(BOOL successCase))completionCase;
- (id)dashBoardViewController;
- (id)_feedbackForFailureSettings:(id)failureSettingsCase;
- (BOOL)showPasscode;
- (void)setShowPasscode:(BOOL)showPasscodeCase;
- (NSArray *)pageViews;
- (id)pageViewController;
- (BOOL)scrollToPageAtIndex:(NSUInteger)pageIndexCase animated:(BOOL)animatedCase withCompletion:(id)completionCase;
@end

static const void *lbUnlockRequestedAssociationKeyCase = &lbUnlockRequestedAssociationKeyCase;
static const void *lbMesaFailurePasscodeAssociationKeyCase = &lbMesaFailurePasscodeAssociationKeyCase;

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

static UIView *LBActiveDashboardView(void) {
    id lockScreenManagerCase = LBSharedInstance(@"SBLockScreenManager");
    id dashboardViewControllerCase = [lockScreenManagerCase respondsToSelector:@selector(dashBoardViewController)] ? [lockScreenManagerCase dashBoardViewController] : nil;
    return [dashboardViewControllerCase isKindOfClass:[UIViewController class]] ? [(UIViewController *)dashboardViewControllerCase view] : nil;
}

static BOOL LBScrollDashboardToUnlockPage(UIView *dashboardViewCase) {
    if (![dashboardViewCase respondsToSelector:@selector(scrollView)] || ![dashboardViewCase respondsToSelector:@selector(scrollToPageAtIndex:animated:withCompletion:)]) { return NO; }

    id scrollViewCase = [(id)dashboardViewCase scrollView];
    NSArray *pageViewsCase = [scrollViewCase respondsToSelector:@selector(pageViews)] ? [scrollViewCase pageViews] : nil;
    Class unlockPageViewControllerClassCase = NSClassFromString(@"LBUnlockPageViewController");

    for (NSUInteger pageViewIndexCase = 0; pageViewIndexCase < pageViewsCase.count; pageViewIndexCase++) {
        id pageViewCase = pageViewsCase[pageViewIndexCase];
        id pageViewControllerCase = [pageViewCase respondsToSelector:@selector(pageViewController)] ? [pageViewCase pageViewController] : nil;

        if (unlockPageViewControllerClassCase && [pageViewControllerCase isKindOfClass:unlockPageViewControllerClassCase]) {
            return [(id)dashboardViewCase scrollToPageAtIndex:pageViewIndexCase animated:YES withCompletion:nil];
        }
    }

    return NO;
}

// Returns the dashboard to the main lock screen page after a failed unlock.
static void LBResetDashboardToMainPage(id dashboardViewCase, BOOL animatedCase) {
    if ([dashboardViewCase respondsToSelector:@selector(resetScrollViewToMainPageAnimated:withCompletion:)]) {
        [dashboardViewCase resetScrollViewToMainPageAnimated:animatedCase withCompletion:nil];
    }
}

void LBResetAuthenticationStateForDashboard(UIView *dashboardViewCase) {
    if (!dashboardViewCase) { return; }
    LBSetAssociatedObject(dashboardViewCase, lbUnlockRequestedAssociationKeyCase, nil);
}

// Restores Lockback's main dashboard after the native passcode screen is cancelled.
void LBResetSlideToUnlockAfterPasscodeCancellation(void) {
    UIView *dashboardViewCase = LBActiveDashboardView();
    if (!dashboardViewCase) { return; }

    LBResetAuthenticationStateForDashboard(dashboardViewCase);
    LBResetDashboardToMainPage(dashboardViewCase, YES);
    [dashboardViewCase setNeedsLayout];
    [dashboardViewCase layoutIfNeeded];
}

// Requests an unlock once the Slide to Unlock page has been reached.
static void LBRequestSlideUnlock(UIView *dashboardViewCase) {
    if ([objc_getAssociatedObject(dashboardViewCase, lbUnlockRequestedAssociationKeyCase) boolValue]) { return; }

    LBSetAssociatedObject(dashboardViewCase, lbUnlockRequestedAssociationKeyCase, @YES);

    if (LBPasscodeScreenRequired()) {
        id scrollViewCase = [dashboardViewCase respondsToSelector:@selector(scrollView)] ? [(id)dashboardViewCase scrollView] : nil;
        UIViewController *unlockPageViewControllerCase = LBUnlockPageViewControllerForScrollView(scrollViewCase);

        if (unlockPageViewControllerCase && LBActivatePasscodeScreenForPageController(unlockPageViewControllerCase)) { return; }

        LBResetAuthenticationStateForDashboard(dashboardViewCase);
        LBResetDashboardToMainPage(dashboardViewCase, YES);
        return;
    }

    if (LBRequestUnlock(^(BOOL successCase) {
        if (!successCase) {
            LBResetAuthenticationStateForDashboard(dashboardViewCase);
            LBResetDashboardToMainPage(dashboardViewCase, YES);
        }
    })) {
        return;
    }

    LBResetAuthenticationStateForDashboard(dashboardViewCase);
    LBResetDashboardToMainPage(dashboardViewCase, YES);
}

%group LBAuthentication

%hook SBDashBoardMesaUnlockBehavior

- (id)_feedbackForFailureSettings:(id)failureSettingsCase {
    if (!LBLockbackEnabled() || ![failureSettingsCase respondsToSelector:@selector(showPasscode)] || ![failureSettingsCase respondsToSelector:@selector(setShowPasscode:)]) {
        return %orig;
    }

    BOOL showPasscodeCase = [failureSettingsCase showPasscode];
    if (!showPasscodeCase) {
        return %orig;
    }

    LBSetAssociatedObject(self, lbMesaFailurePasscodeAssociationKeyCase, @YES);
    [failureSettingsCase setShowPasscode:NO];
    id feedbackCase = %orig(failureSettingsCase);
    [failureSettingsCase setShowPasscode:YES];
    return feedbackCase;
}

- (void)_handleMesaFailure {
    LBSetAssociatedObject(self, lbMesaFailurePasscodeAssociationKeyCase, nil);
    %orig;

    if (!LBLockbackEnabled()) { return; }

    UIView *dashboardViewCase = LBActiveDashboardView();
    if (!dashboardViewCase) { return; }

    id scrollViewCase = [dashboardViewCase respondsToSelector:@selector(scrollView)] ? [(id)dashboardViewCase scrollView] : nil;
    if (LBScrollViewIsOnUnlockPage(scrollViewCase)) { return; }

    if ([objc_getAssociatedObject(self, lbMesaFailurePasscodeAssociationKeyCase) boolValue]) {
        LBResetAuthenticationStateForDashboard(dashboardViewCase);
        if (LBScrollDashboardToUnlockPage(dashboardViewCase)) { return; }
    }

    LBShowSlideToUnlockAuthenticationFailure(dashboardViewCase);
}

%end

%hook SBDashBoardView

- (void)scrollViewDidEndScrolling:(id)scrollViewCase {
    %orig;

    if (!LBLockbackEnabled()) { return; }

    UIView *dashboardViewCase = (UIView *)self;
    if (LBScrollViewIsOnUnlockPage(scrollViewCase)) {
        LBRequestSlideUnlock(dashboardViewCase);
        return;
    }

    LBResetAuthenticationStateForDashboard(dashboardViewCase);
}

%end

%end

void LBInitializeAuthentication(void) { %init(LBAuthentication); }
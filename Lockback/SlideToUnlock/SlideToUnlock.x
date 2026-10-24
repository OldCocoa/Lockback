// This connects the recreated Slide to Unlock view to the active dashboard lifecycle.

#import <UIKit/UIKit.h>
#import "../LockbackUtils.h"
#import "../Authentication.h"
#import "../Passcode/PasscodeShared.h"
#import "SlideToUnlockShared.h"
#import "../DashboardPaging.h"

@interface NSObject (LBSlideToUnlockLifecyclePrivateMethods)
- (id)scrollView;
@end

%group LBSlideToUnlock

%hook SBDashBoardView

- (void)didMoveToWindow {
    %orig;

    UIView *dashboardViewCase = (UIView *)self;
    if (!dashboardViewCase.window || !LBLockbackEnabled()) {
        id scrollViewCase = [dashboardViewCase respondsToSelector:@selector(scrollView)] ? [(id)dashboardViewCase scrollView] : nil;
        UIViewController *unlockPageViewControllerCase = LBUnlockPageViewControllerForScrollView(scrollViewCase);

        LBDeactivatePasscodeScreenForPageController(unlockPageViewControllerCase);
        LBUpdatePasscodeScreenScrollProgress(unlockPageViewControllerCase, 0.0);
        LBRemoveSlideToUnlockView(dashboardViewCase);
        LBResetAuthenticationStateForDashboard(dashboardViewCase);
        return;
    }

    LBInstallSlideToUnlockView(dashboardViewCase);
}

- (void)layoutSubviews {
    %orig;
    LBUpdateSlideToUnlockView((UIView *)self);
}

- (void)setLegibilitySettings:(id)legibilitySettingsCase {
    %orig;
    if (LBLockbackEnabled()) { LBUpdateSlideToUnlockAppearance((UIView *)self); }
}

- (void)setLegibilitySettingsOverrideVibrancy:(BOOL)overrideVibrancyCase {
    %orig;
    if (LBLockbackEnabled()) { LBUpdateSlideToUnlockAppearance((UIView *)self); }
}

%end

%end

void LBInitializeSlideToUnlock(void) { %init(LBSlideToUnlock); }
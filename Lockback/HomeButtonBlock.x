#import <UIKit/UIKit.h>
#import "Lockback.h"
#import "DashboardPaging.h"

@interface SBDashBoardViewController : UIViewController
- (UIView *)dashBoardView;
@end

@interface NSObject (LBHomeButtonBlockPrivateMethods)
- (UIScrollView *)scrollView;
@end

@interface SBLockScreenManager : NSObject
- (void)homeButtonShowPasscodeRecognizerRequestsPasscodeUIToBeShown:(id)recognizerCase;
- (BOOL)_attemptUnlockWithPasscode:(id)passcodeCase mesa:(BOOL)mesaCase finishUIUnlock:(BOOL)finishUIUnlockCase;
@end

%group LBHomeButtonBlockHooks

%hook SBLockScreenManager

- (void)homeButtonShowPasscodeRecognizerRequestsPasscodeUIToBeShown:(id)recognizerCase {
    if (LBLockbackEnabled() && LBDisableHomeButtonUnlockEnabled()) { return; }
    %orig;
}

- (BOOL)_attemptUnlockWithPasscode:(id)passcodeCase mesa:(BOOL)mesaCase finishUIUnlock:(BOOL)finishUIUnlockCase {
    if (LBLockbackEnabled() && LBDisableHomeButtonUnlockEnabled() && mesaCase) {
        return %orig(passcodeCase, mesaCase, YES); 
    }
    return %orig;
}

%end

%hook SBDashBoardViewController

- (BOOL)handleMenuButtonTap {
    if (LBLockbackEnabled() && LBDisableHomeButtonUnlockEnabled()) {
        UIView *dashBoardViewCase = [(SBDashBoardViewController *)self dashBoardView];
        UIScrollView *scrollViewCase = [dashBoardViewCase respondsToSelector:@selector(scrollView)] ? [(id)dashBoardViewCase scrollView] : nil;
        if (!LBScrollViewIsOnUnlockPage(scrollViewCase)) { return YES; }
    }

    return %orig;
}

%end

%end

void LBInitializeHomeButtonBlock(void) { %init(LBHomeButtonBlockHooks); }
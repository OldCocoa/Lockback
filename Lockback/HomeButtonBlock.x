#import <UIKit/UIKit.h>
#import "Lockback.h"

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

%end

void LBInitializeHomeButtonBlock(void) { %init(LBHomeButtonBlockHooks); }
// This part of the tweak initializes all separated hooks to make the tweak function.

#import <UIKit/UIKit.h>
#import "Lockback.h"

@interface NSObject (LBStatePrivateMethods)
- (id)authenticationController;
- (BOOL)hasPasscodeSet;
@end

BOOL LBLockbackEnabled(void) {
    UIApplication *springBoardCase = [UIApplication sharedApplication];
    // If the lock screen exposes the authentication controller, Lockback should stay enabled.
    // TODO: Implement authentication support (i.e. PIN code support, Touch ID support).
    if (![springBoardCase respondsToSelector:@selector(authenticationController)]) {
        return YES;
    }

    id authenticationControllerCase = [(id)springBoardCase authenticationController];
    return !authenticationControllerCase ||
        ![authenticationControllerCase respondsToSelector:@selector(hasPasscodeSet)] ||
        ![authenticationControllerCase hasPasscodeSet];
}

%ctor {
    LBInitializeElementHiding();     // Hides lock screen elements
    LBInitializeNotificationsView(); // Restores iOS notification list
    LBInitializeTimeDate();          // Restores iOS time and date
    LBInitializeSlideToUnlock();     // Restores iOS Slide to Unlock
    LBInitializeGrabbers();          // Restores status bar, control center and camera grabbers
}
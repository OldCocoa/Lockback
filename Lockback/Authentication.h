// This exposes the shared authentication state and initialization functions.

#ifndef Authentication_h
#define Authentication_h

#import <UIKit/UIKit.h>

// Authentication state shared with the passcode and Slide to Unlock code.
void LBResetAuthenticationStateForDashboard(UIView *dashboardViewCase);
void LBResetSlideToUnlockAfterPasscodeCancellation(void);
void LBInitializeAuthentication(void);

#endif
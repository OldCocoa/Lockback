// This exposes the shared Slide to Unlock view helpers.

#ifndef SlideToUnlockShared_h
#define SlideToUnlockShared_h

#import <UIKit/UIKit.h>

// Installs or updates the recreated Slide to Unlock view.
void LBInstallSlideToUnlockView(UIView *dashboardViewCase);
void LBUpdateSlideToUnlockView(UIView *dashboardViewCase);
// Removes the recreated Slide to Unlock view from the dashboard.
void LBRemoveSlideToUnlockView(UIView *dashboardViewCase);
// Refreshes the Slide to Unlock appearance after SpringBoard legibility changes.
void LBUpdateSlideToUnlockAppearance(UIView *dashboardViewCase);
// Displays the original Touch ID failure response on the Slide to Unlock label.
void LBShowSlideToUnlockAuthenticationFailure(UIView *dashboardViewCase);

#endif
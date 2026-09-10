// This exposes Lockback's shared state and feature initializers.

#ifndef Lockback_h
#define Lockback_h

#import <UIKit/UIKit.h>

BOOL LBLockbackEnabled(void);
BOOL LBNotificationCenterMirroringEnabled(void);
BOOL LBDisableHomeButtonUnlockEnabled(void);
BOOL LBPasscodeScreenRequired(void);
BOOL LBPresentPasscodeScreen(void);
void LBResetSlideToUnlockAfterPasscodeCancellation(void);
void LBInitializePasscodeScreen(void);
void LBInitializeElementHiding(void);
void LBInitializeTimeDate(void);
void LBInitializeNotificationsView(void);
void LBInitializeAuthentication(void);
void LBInitializeHomeButtonBlock(void);
void LBInitializeDashboardPaging(void);
void LBInitializeSlideToUnlock(void);
void LBInitializeGrabbers(void);

#endif
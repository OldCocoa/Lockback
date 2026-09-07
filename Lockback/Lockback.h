// This exposes Lockback's shared state and feature initializers.

#ifndef Lockback_h
#define Lockback_h

#import <UIKit/UIKit.h>

BOOL LBLockbackEnabled(void);
void LBInitializeElementHiding(void);
void LBInitializeTimeDate(void);
void LBInitializeNotificationsView(void);
void LBInitializeSlideToUnlock(void);
void LBInitializeGrabbers(void);

#endif
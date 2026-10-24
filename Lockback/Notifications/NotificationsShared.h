// This exposes notification background transition helpers used by dashboard paging.

#ifndef NotificationsShared_h
#define NotificationsShared_h

#import <UIKit/UIKit.h>

void LBUpdateNotificationBackgroundForPasscodeProgress(UIView *dashboardViewCase, CGFloat progressCase);
BOOL LBNotificationBackgroundOwnsPasscodeBlur(void);

#endif
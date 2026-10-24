// This exposes the dashboard paging helpers shared with authentication and Slide to Unlock.

#ifndef DashboardPaging_h
#define DashboardPaging_h

#import <UIKit/UIKit.h>

// Returns Lockback's custom unlock page for the current dashboard scroll view.
UIViewController *LBUnlockPageViewControllerForScrollView(id scrollViewCase);
// Checks whether the dashboard is currently resting on Lockback's unlock page.
BOOL LBScrollViewIsOnUnlockPage(id scrollViewCase);
// Initializes the dashboard page hooks used by Slide to Unlock.
void LBInitializeDashboardPaging(void);

#endif
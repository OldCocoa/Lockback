// This keeps the lock screen grabbers synchronized with the dashboard.

#import <UIKit/UIKit.h>
#import "Grabbers/GrabberShared.h"

BOOL lbMediaControlsVisibleCase = NO;

// Converts the dashboard page offset into the amount the iOS grabbers should move.
static CGFloat LBGrabberScrollProgress(UIScrollView *scrollViewCase) {
    CGFloat scrollViewWidthCase = CGRectGetWidth(scrollViewCase.bounds);
    if (scrollViewWidthCase <= 0.0) {
        return 0.0;
    }

    CGFloat scrollProgressCase = scrollViewCase.contentOffset.x / scrollViewWidthCase;
    BOOL isRightToLeftCase = [UIApplication sharedApplication].userInterfaceLayoutDirection == UIUserInterfaceLayoutDirectionRightToLeft;
    if (!isRightToLeftCase) { scrollProgressCase = 1.0 - scrollProgressCase; }

    return MAX(scrollProgressCase, 0.0);
}

static UIView *LBDashboardViewForContentView(UIView *contentViewCase) {
    Class dashboardViewClassCase = NSClassFromString(@"SBDashBoardView");
    UIView *viewCase = contentViewCase;

    while (viewCase) {
        if (dashboardViewClassCase && [viewCase isKindOfClass:dashboardViewClassCase]) { return viewCase; }
        viewCase = viewCase.superview;
    }

    return nil;
}

// Mirrors SpringBoard's media-controls visibility into the replacement grabber overlay.
static void LBUpdateMediaControlsGrabberState(id contentViewControllerCase) {
    if (![contentViewControllerCase respondsToSelector:@selector(isShowingMediaControls)]) { return; }

    lbMediaControlsVisibleCase = [contentViewControllerCase isShowingMediaControls];

    UIView *contentViewCase = [(UIViewController *)contentViewControllerCase view];
    UIView *dashboardViewCase = LBDashboardViewForContentView(contentViewCase);
    if (!dashboardViewCase) { return; }

    LBGrabberOverlayView *grabberOverlayViewCase = LBGrabberOverlayForDashboard(dashboardViewCase);
    [grabberOverlayViewCase updateMediaControlsVisibility:lbMediaControlsVisibleCase];
}

%group LBGrabbers

%hook SBDashBoardMainPageContentViewController

- (void)_updateMediaControlsVisibility {
    %orig;
    if (LBLockbackEnabled()) { LBUpdateMediaControlsGrabberState(self); }
}

%end

%hook SBDashBoardView

- (void)didMoveToWindow {
    %orig;
    LBUpdateLockScreenFeature((UIView *)self, lbGrabberOverlayAssociationKeyCase, YES, LBInstallGrabberOverlay);
}

- (void)layoutSubviews {
    %orig;
    LBUpdateLockScreenFeature((UIView *)self, lbGrabberOverlayAssociationKeyCase, NO, LBInstallGrabberOverlay);
}

- (void)scrollViewDidScroll:(id)scrollViewCase withContext:(void *)scrollContextCase {
    %orig;

    if (!LBLockbackEnabled() || ![scrollViewCase isKindOfClass:[UIScrollView class]]) { return; }
    [LBGrabberOverlayForDashboard((UIView *)self) updateGrabberScrollProgress:LBGrabberScrollProgress((UIScrollView *)scrollViewCase)];
}

- (void)setLegibilitySettings:(id)legibilitySettingsCase {
    %orig;
    if (LBLockbackEnabled()) { [LBGrabberOverlayForDashboard((UIView *)self) updateGrabberAppearance]; }
}

- (void)setLegibilitySettingsOverrideVibrancy:(BOOL)overrideVibrancyCase {
    %orig;
    if (LBLockbackEnabled()) { [LBGrabberOverlayForDashboard((UIView *)self) updateGrabberAppearance]; }
}

%end

%end

void LBInitializeGrabbers(void) {
    LBInitializeGrabberView();
    LBInitializeCameraGrabber();
    %init(LBGrabbers);
}
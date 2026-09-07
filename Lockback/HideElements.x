// This hides the iOS lock screen elements that Lockback replaces.

#import <UIKit/UIKit.h>
#import "Lockback.h"

@interface SBLockScreenDateViewController : UIViewController
- (UIView *)dateViewIfExists;
@end

@interface SBDashBoardMainPageView : UIView
- (UIView *)callToActionLabel;
- (UIView *)statusTextView;
- (UIView *)logoutButtonView;
- (UIView *)slideUpAppGrabberView;
- (UIView *)wallpaperEffectView;
@end

@interface SBDashBoardNowPlayingViewController : UIViewController
@end

@interface SBDashBoardMediaControlsViewController : UIViewController
@end

@interface SBDashBoardMediaArtworkViewController : UIViewController
@end

@interface NSObject (LBHideElementsPrivateMethods)
- (BOOL)_setItem:(int)itemCase enabled:(BOOL)enabledCase;
- (id)mainPageViewController;
- (id)contentViewController;
- (void)updateSlideUpAppGrabberViewForApplicationWithBundleIdentifier:(NSString *)bundleIdentifierCase;
@end

// Hides a native lock screen view and disables its interaction and accessibility.
static void LBHideView(UIView *viewCase) {
    if (!viewCase) { return; }

    viewCase.hidden = YES;
    viewCase.userInteractionEnabled = NO;
    viewCase.accessibilityElementsHidden = YES;
}

// Hides the main page elements that do not exist on the iOS lock screen.
static void LBHideMainPageElements(SBDashBoardMainPageView *mainPageViewCase) {
    LBHideView([mainPageViewCase callToActionLabel]);
    LBHideView([mainPageViewCase statusTextView]);
    LBHideView([mainPageViewCase logoutButtonView]);
    LBHideView([mainPageViewCase slideUpAppGrabberView]);
    LBHideView([mainPageViewCase wallpaperEffectView]);
}


// Prevents the suggested-app grabber from appearing over the replacement camera grabber.
static void LBHideDashboardSlideUpGrabber(id dashboardViewControllerCase) {
    if (![dashboardViewControllerCase respondsToSelector:@selector(mainPageViewController)]) {
        return;
    }

    id mainPageViewControllerCase = [dashboardViewControllerCase mainPageViewController];
    id contentViewControllerCase = [mainPageViewControllerCase respondsToSelector:@selector(contentViewController)] ? [mainPageViewControllerCase contentViewController] : nil;

    if ([contentViewControllerCase respondsToSelector:@selector(updateSlideUpAppGrabberViewForApplicationWithBundleIdentifier:)]) {
        [contentViewControllerCase updateSlideUpAppGrabberViewForApplicationWithBundleIdentifier:nil];
    }
}

// Keeps the iOS replacements hidden whenever SpringBoard recreates or lays them out.
%group LBHideElements

%hook SBDashBoardMainPageView

- (void)didMoveToWindow {
    %orig;
    if (LBLockbackEnabled()) { LBHideMainPageElements((SBDashBoardMainPageView *)self); }
}

- (void)layoutSubviews {
    %orig;
    if (LBLockbackEnabled()) { LBHideMainPageElements((SBDashBoardMainPageView *)self); }
}

- (void)setCallToActionLabel:(UIView *)callToActionLabelCase {
    %orig;
    if (LBLockbackEnabled()) { LBHideView(callToActionLabelCase); }
}

- (void)setStatusTextView:(UIView *)statusTextViewCase {
    %orig;
    if (LBLockbackEnabled()) { LBHideView(statusTextViewCase); }
}

- (void)setLogoutButtonView:(UIView *)logoutButtonViewCase {
    %orig;
    if (LBLockbackEnabled()) { LBHideView(logoutButtonViewCase); }
}

- (void)setSlideUpAppGrabberView:(UIView *)slideUpAppGrabberViewCase {
    %orig;
    if (LBLockbackEnabled()) { LBHideView(slideUpAppGrabberViewCase); }
}

- (void)setWallpaperEffectView:(UIView *)wallpaperEffectViewCase {
    %orig;
    if (LBLockbackEnabled()) { LBHideView(wallpaperEffectViewCase); }
}

%end

// Hides the native iOS lock screen date because TimeDate.x provides the iOS version.
%hook SBFLockScreenDateView

- (void)didMoveToWindow {
    %orig;
    if (LBLockbackEnabled()) { LBHideView((UIView *)self); }
}

- (void)setHidden:(BOOL)hiddenCase {
    if (LBLockbackEnabled()) {
        %orig(YES);
        return;
    }

    %orig(hiddenCase);
}

%end

// Keeps the controller-owned date view hidden after SpringBoard updates it.
%hook SBLockScreenDateViewController

- (void)loadView {
    %orig;
    if (LBLockbackEnabled()) { LBHideView([(SBLockScreenDateViewController *)self dateViewIfExists]); }
}

- (void)_updateView {
    %orig;
    if (LBLockbackEnabled()) { LBHideView([(SBLockScreenDateViewController *)self dateViewIfExists]); }
}

%end


// Disables the native iOS music player.
%hook SBDashBoardNowPlayingViewController

- (void)aggregateAppearance:(id)appearanceCase {
    if (LBLockbackEnabled()) { return; }
    %orig(appearanceCase);
}

%end

%hook SBDashBoardMediaControlsViewController

- (void)viewDidLoad {
    %orig;
    if (LBLockbackEnabled()) { LBHideView(self.view); }
}

- (void)viewWillLayoutSubviews {
    %orig;
    if (LBLockbackEnabled()) { LBHideView(self.view); }
}

%end

%hook SBDashBoardMediaArtworkViewController

- (void)viewDidLoad {
    %orig;
    if (LBLockbackEnabled()) { LBHideView(self.view); }
}

- (void)updateForPresentation:(id)presentationCase {
    %orig;
    if (LBLockbackEnabled()) { LBHideView(self.view); }
}

%end


// Hides the native lock item from the status bar.
%hook SBStatusBarStateAggregator

- (void)_updateLockItem {
    if (!LBLockbackEnabled()) {
        %orig;
        return;
    }

    [(id)self _setItem:31 enabled:NO];
}

%end

// Keeps the native suggested-app grabber disabled while the replacement camera grabber is active.
%hook SBDashBoardViewController

- (void)slideController:(id)slideControllerCase
    didUpdateWithApplicationWithBundleIdentifier:(NSString *)bundleIdentifierCase {
    if (!LBLockbackEnabled()) {
        %orig;
        return;
    }

    Class slideControllerClassCase = NSClassFromString(@"SBDashBoardSlideUpToAppController");
    if (slideControllerClassCase && [slideControllerCase isKindOfClass:slideControllerClassCase]) {
        LBHideDashboardSlideUpGrabber(self);
        return;
    }

    %orig;
}

%end

// Hides the iOS dashboard status bar.
%hook SBDashBoardStatusBar

- (void)didMoveToWindow {
    %orig;
    if (LBLockbackEnabled()) { LBHideView((UIView *)self); }
}

%end

// Hides the iOS dashboard page dots.
%hook SBDashBoardPageControl

- (void)didMoveToWindow {
    %orig;
    if (LBLockbackEnabled()) { LBHideView((UIView *)self); }
}

%end

%end

void LBInitializeElementHiding(void) { %init(LBHideElements); }
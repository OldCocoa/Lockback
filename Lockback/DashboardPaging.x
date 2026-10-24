// This manages the dashboard pages used by Slide to Unlock and the passcode transition.

#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "LockbackUtils.h"
#import "Passcode/PasscodeShared.h"
#import "Notifications/NotificationsShared.h"
#import "DashboardPaging.h"

typedef struct {
    NSInteger pageIndexCase;
    CGPoint contentOffsetCase;
    CGPoint translationCase;
} LBDashBoardScrollContextCase;

@interface NSObject (LBDashboardPagingPrivateMethods)
- (id)pageViewController;
- (NSArray *)pageViews;
- (NSUInteger)currentPageIndex;
@end

// Creates a lightweight dashboard page controller used as the Slide to Unlock destination.
static Class LBUnlockPageViewControllerClass(void) {
    Class unlockPageViewControllerClassCase = NSClassFromString(@"LBUnlockPageViewController");
    if (unlockPageViewControllerClassCase) { return unlockPageViewControllerClassCase; }

    Class pageViewControllerClassCase = NSClassFromString(@"SBDashBoardPageViewController");
    if (!pageViewControllerClassCase) { return Nil; }

    unlockPageViewControllerClassCase = objc_allocateClassPair(pageViewControllerClassCase, "LBUnlockPageViewController", 0);
    if (unlockPageViewControllerClassCase) { objc_registerClassPair(unlockPageViewControllerClassCase); }

    return unlockPageViewControllerClassCase ?: NSClassFromString(@"LBUnlockPageViewController");
}

// Removes the Today View and Camera pages and inserts the custom unlock page beside the main page.
static NSArray *LBDashboardPageViewControllers(NSArray *pageViewControllersCase, id mainPageViewControllerCase) {
    Class todayPageClassCase = NSClassFromString(@"SBDashBoardTodayPageViewController");
    Class cameraPageClassCase = NSClassFromString(@"SBDashBoardCameraPageViewController");
    Class unlockPageClassCase = LBUnlockPageViewControllerClass();

    NSMutableArray *slidePageViewControllersCase = [NSMutableArray arrayWithCapacity:pageViewControllersCase.count + 1];

    for (id pageViewControllerCase in pageViewControllersCase) {
        if ((todayPageClassCase && [pageViewControllerCase isKindOfClass:todayPageClassCase]) ||
            (cameraPageClassCase && [pageViewControllerCase isKindOfClass:cameraPageClassCase]) ||
            (unlockPageClassCase && [pageViewControllerCase isKindOfClass:unlockPageClassCase])) {
            continue;
        }

        [slidePageViewControllersCase addObject:pageViewControllerCase];
    }

    NSUInteger mainPageIndexCase = [slidePageViewControllersCase indexOfObjectIdenticalTo:mainPageViewControllerCase];
    if (mainPageIndexCase == NSNotFound) {
        [slidePageViewControllersCase addObject:mainPageViewControllerCase];
        mainPageIndexCase = slidePageViewControllersCase.count - 1;
    }

    UIViewController *unlockPageViewControllerCase = unlockPageClassCase ? [[unlockPageClassCase alloc] initWithNibName:nil bundle:nil] : nil;
    if (!unlockPageViewControllerCase) { return slidePageViewControllersCase; }

    LBPreparePasscodeScreenForPageController(unlockPageViewControllerCase);

    BOOL rightToLeftCase = [UIApplication sharedApplication].userInterfaceLayoutDirection == UIUserInterfaceLayoutDirectionRightToLeft;
    NSUInteger unlockPageIndexCase = rightToLeftCase ? mainPageIndexCase + 1 : mainPageIndexCase;
    [slidePageViewControllersCase insertObject:unlockPageViewControllerCase atIndex:unlockPageIndexCase];

    return slidePageViewControllersCase;
}

// Checks whether a dashboard page view belongs to Lockback's unlock page controller.
static BOOL LBIsUnlockPageView(id pageViewCase) {
    if (![pageViewCase respondsToSelector:@selector(pageViewController)]) { return NO; }

    Class unlockPageViewControllerClassCase = NSClassFromString(@"LBUnlockPageViewController");
    return unlockPageViewControllerClassCase && [[pageViewCase pageViewController] isKindOfClass:unlockPageViewControllerClassCase];
}

UIViewController *LBUnlockPageViewControllerForScrollView(id scrollViewCase) {
    if (![scrollViewCase respondsToSelector:@selector(pageViews)]) { return nil; }

    for (id pageViewCase in [scrollViewCase pageViews]) {
        if (!LBIsUnlockPageView(pageViewCase)) { continue; }

        id pageViewControllerCase = [pageViewCase pageViewController];
        return [pageViewControllerCase isKindOfClass:[UIViewController class]] ? pageViewControllerCase : nil;
    }

    return nil;
}

static CGFloat LBPasscodeScrollProgress(id scrollViewCase) {
    if (![scrollViewCase isKindOfClass:[UIScrollView class]] || ![scrollViewCase respondsToSelector:@selector(pageViews)]) { return 0.0; }

    NSArray *pageViewsCase = [scrollViewCase pageViews];
    Class mainPageViewControllerClassCase = NSClassFromString(@"SBDashBoardMainPageViewController");
    NSUInteger mainPageIndexCase = NSNotFound;
    NSUInteger unlockPageIndexCase = NSNotFound;
    UIView *mainPageViewCase = nil;
    UIView *unlockPageViewCase = nil;

    for (NSUInteger pageViewIndexCase = 0; pageViewIndexCase < pageViewsCase.count; pageViewIndexCase++) {
        id pageViewCase = pageViewsCase[pageViewIndexCase];
        id pageViewControllerCase = [pageViewCase respondsToSelector:@selector(pageViewController)] ? [pageViewCase pageViewController] : nil;

        if (LBIsUnlockPageView(pageViewCase)) {
            unlockPageIndexCase = pageViewIndexCase;
            unlockPageViewCase = [pageViewCase isKindOfClass:[UIView class]] ? pageViewCase : nil;
        } else if (mainPageViewControllerClassCase && [pageViewControllerCase isKindOfClass:mainPageViewControllerClassCase]) {
            mainPageIndexCase = pageViewIndexCase;
            mainPageViewCase = [pageViewCase isKindOfClass:[UIView class]] ? pageViewCase : nil;
        }
    }

    if (mainPageIndexCase == NSNotFound || unlockPageIndexCase == NSNotFound) { return 0.0; }

    CGFloat mainPageOffsetCase = mainPageViewCase ? CGRectGetMinX(mainPageViewCase.frame) : 0.0;
    CGFloat unlockPageOffsetCase = unlockPageViewCase ? CGRectGetMinX(unlockPageViewCase.frame) : 0.0;
    CGFloat pageDistanceCase = unlockPageOffsetCase - mainPageOffsetCase;

    if (fabs(pageDistanceCase) < 1.0) {
        CGFloat pageWidthCase = CGRectGetWidth([(UIScrollView *)scrollViewCase bounds]);
        if (pageWidthCase <= 0.0) { return 0.0; }

        mainPageOffsetCase = ((CGFloat)mainPageIndexCase) * pageWidthCase;
        unlockPageOffsetCase = ((CGFloat)unlockPageIndexCase) * pageWidthCase;
        pageDistanceCase = unlockPageOffsetCase - mainPageOffsetCase;
    }

    if (fabs(pageDistanceCase) < 1.0) { return 0.0; }

    CGFloat contentOffsetCase = [(UIScrollView *)scrollViewCase contentOffset].x;
    CGFloat progressCase = (contentOffsetCase - mainPageOffsetCase) / pageDistanceCase;
    return MAX(0.0, MIN(1.0, progressCase));
}

// Checks whether the dashboard finished scrolling onto the custom unlock page.
BOOL LBScrollViewIsOnUnlockPage(id scrollViewCase) {
    if (![scrollViewCase respondsToSelector:@selector(pageViews)] || ![scrollViewCase respondsToSelector:@selector(currentPageIndex)]) { return NO; }

    NSArray *pageViewsCase = [scrollViewCase pageViews];
    NSUInteger currentPageIndexCase = [scrollViewCase currentPageIndex];
    return currentPageIndexCase < pageViewsCase.count && LBIsUnlockPageView(pageViewsCase[currentPageIndexCase]);
}

%group LBDashboardPaging

%hook SBDashBoardViewController

- (void)_setPageViewControllers:(NSArray *)pageViewControllersCase {
    if (!LBLockbackEnabled()) {
        %orig;
        return;
    }

    Class mainPageViewControllerClassCase = NSClassFromString(@"SBDashBoardMainPageViewController");
    id mainPageViewControllerCase = nil;

    for (id pageViewControllerCase in pageViewControllersCase) {
        if (mainPageViewControllerClassCase && [pageViewControllerCase isKindOfClass:mainPageViewControllerClassCase]) {
            mainPageViewControllerCase = pageViewControllerCase;
            break;
        }
    }

    if (mainPageViewControllerCase) { pageViewControllersCase = LBDashboardPageViewControllers(pageViewControllersCase, mainPageViewControllerCase); }

    %orig;
}

- (void)activateTodayViewWithCompletion:(void (^)(void))completionHandlerCase {
    if (!LBLockbackEnabled()) {
        %orig;
        return;
    }

    if (completionHandlerCase) { completionHandlerCase(); }
}

- (void)activateCameraAnimated:(BOOL)isAnimatedCase withActions:(id)cameraActionsCase {
    if (!LBLockbackEnabled()) {
        %orig;
    }
}

%end

%hook SBDashBoardView

- (void)scrollViewDidScroll:(id)scrollViewCase withContext:(LBDashBoardScrollContextCase)contextCase {
    %orig;

    if (!LBLockbackEnabled()) { return; }

    CGFloat passcodeProgressCase = LBPasscodeScrollProgress(scrollViewCase);
    UIViewController *unlockPageViewControllerCase = LBUnlockPageViewControllerForScrollView(scrollViewCase);

    LBUpdateNotificationBackgroundForPasscodeProgress((UIView *)self, passcodeProgressCase);
    LBUpdatePasscodeScreenScrollProgress(unlockPageViewControllerCase, passcodeProgressCase);
}

%end

%end

void LBInitializeDashboardPaging(void) { %init(LBDashboardPaging); }
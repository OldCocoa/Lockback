#import <UIKit/UIKit.h>
#import <dlfcn.h>
#import "../LockbackUtils.h"
#import "MediaControlsShared.h"

static const NSInteger lbLockScreenControlsStyleCase = 2;
static const NSInteger lbLockScreenArtworkStyleCase = 3;

static const void *lbMediaControlsViewAssociationKeyCase = &lbMediaControlsViewAssociationKeyCase;
static BOOL lbRestoredMediaControlsVisibleCase = NO;
static __weak id lbMainPageContentViewControllerCase = nil;

static NSHashTable *LBAllMediaControlsViews(void) {
    static NSHashTable *viewsCase;
    static dispatch_once_t onceTokenCase;
    dispatch_once(&onceTokenCase, ^{ viewsCase = [NSHashTable weakObjectsHashTable]; });
    return viewsCase;
}

static int LBCommandForCommandInfo(id commandInfoCase) {
    static int (*getCommandCase)(id);
    static dispatch_once_t onceTokenCase;
    dispatch_once(&onceTokenCase, ^{
        void *mediaRemoteCase = dlopen("/System/Library/PrivateFrameworks/MediaRemote.framework/MediaRemote", RTLD_LAZY);
        getCommandCase = mediaRemoteCase ? (int (*)(id))dlsym(mediaRemoteCase, "MRMediaRemoteCommandInfoGetCommand") : NULL;
    });
    return getCommandCase && commandInfoCase ? getCommandCase(commandInfoCase) : -1;
}

static const void *lbOriginalSupportedCommandsKeyCase = &lbOriginalSupportedCommandsKeyCase;
static const void *lbLockScreenRemoteControllerKeyCase = &lbLockScreenRemoteControllerKeyCase;

@interface NSObject (LBMediaControlsPrivateMethods)
- (instancetype)initWithStyle:(NSInteger)styleCase;
- (UIView *)artworkView;
- (void)setPersistentUpdatesEnabled:(BOOL)enabledCase;
- (UIScrollView *)scrollView;
- (BOOL)isShowingMediaControls;
- (id)dashBoardViewController;
- (void)_updateStatusBar;
- (void)updateTimeEnabled;
- (NSArray *)supportedCommands;
- (void)setSupportedCommands:(NSArray *)commandsCase;
- (UIView *)trackInformationView;
- (UIView *)transportControlsView;
- (UIView *)volumeView;
@end

static id LBRemoteControllerForControlsViewController(UIViewController *viewControllerCase) {
    Class remoteControllerClassCase = NSClassFromString(@"MPUTransportControlMediaRemoteController");
    if (!viewControllerCase || !remoteControllerClassCase) { return nil; }

    unsigned int ivarCountCase = 0;
    Ivar *ivarsCase = class_copyIvarList([viewControllerCase class], &ivarCountCase);
    id remoteControllerCase = nil;

    for (unsigned int ivarIndexCase = 0; ivarIndexCase < ivarCountCase && !remoteControllerCase; ivarIndexCase++) {
        const char *typeCase = ivar_getTypeEncoding(ivarsCase[ivarIndexCase]);
        if (!typeCase || typeCase[0] != '@') { continue; }

        id valueCase = object_getIvar(viewControllerCase, ivarsCase[ivarIndexCase]);
        if ([valueCase isKindOfClass:remoteControllerClassCase]) { remoteControllerCase = valueCase; }
    }

    free(ivarsCase);
    return remoteControllerCase;
}

static NSArray *LBFilteredSupportedCommands(NSArray *commandsCase) {
    if (!LBMediaControlsShowsPreviousTrack()) { return commandsCase; }

    NSMutableArray *filteredCommandsCase = [NSMutableArray array];
    for (id commandInfoCase in commandsCase) {
        int commandCase = LBCommandForCommandInfo(commandInfoCase);
        if (commandCase == 21 || commandCase == 22) { continue; }
        [filteredCommandsCase addObject:commandInfoCase];
    }

    return filteredCommandsCase;
}

static void LBApplyLeftButtonPreference(UIViewController *controlsViewControllerCase) {
    id remoteControllerCase = LBRemoteControllerForControlsViewController(controlsViewControllerCase);
    if (!remoteControllerCase) { return; }

    objc_setAssociatedObject(remoteControllerCase, lbLockScreenRemoteControllerKeyCase, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    NSArray *originalCommandsCase = objc_getAssociatedObject(remoteControllerCase, lbOriginalSupportedCommandsKeyCase);
    if (!originalCommandsCase && [remoteControllerCase respondsToSelector:@selector(supportedCommands)]) { originalCommandsCase = [remoteControllerCase supportedCommands]; }
    if (originalCommandsCase) { [remoteControllerCase setSupportedCommands:originalCommandsCase]; }
}

BOOL LBMediaControlsVisible(void) { return LBLockbackEnabled() && lbRestoredMediaControlsVisibleCase; }

static BOOL LBIsPad(void) { return UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad; }

static BOOL LBIsLandscapeBounds(CGRect boundsCase) { return CGRectGetWidth(boundsCase) > CGRectGetHeight(boundsCase); }

static const CGFloat lbPadControlsWidthCase = 460.0;

static CGFloat LBMediaControlsY(CGRect boundsCase) {
    if (LBIsPad()) { return LBIsLandscapeBounds(boundsCase) ? 36.0 : 50.0; }
    return 30.0;
}

static CGFloat LBMediaControlsHeight(CGRect boundsCase) {
    if (LBIsPad()) { return LBIsLandscapeBounds(boundsCase) ? 180.0 : 200.0; }
    return 165.0;
}

static CGRect LBArtworkFrame(CGRect boundsCase) {
    CGRect screenBoundsCase = [UIScreen mainScreen].bounds;
    BOOL isTallScreenCase = fabs(CGRectGetHeight(screenBoundsCase) - 480.0) > FLT_EPSILON;

    CGFloat artworkSizeCase;
    CGFloat artworkYCase;

    if (LBIsPad()) {
        BOOL isLandscapeCase = LBIsLandscapeBounds(boundsCase);
        artworkSizeCase = isLandscapeCase ? 421.0 : 522.0;
        artworkYCase = isLandscapeCase ? 230.0 : 280.0;
    } else if (isTallScreenCase) {
        artworkSizeCase = round(CGRectGetWidth(screenBoundsCase) * 0.9);
        artworkYCase = round(CGRectGetHeight(boundsCase) * 0.3) + 12.0;
    } else {
        artworkSizeCase = 226.0;
        artworkYCase = 170.0;
    }

    CGFloat artworkXCase = floor((CGRectGetWidth(boundsCase) - artworkSizeCase) * 0.5);
    return CGRectMake(artworkXCase, artworkYCase, artworkSizeCase, artworkSizeCase);
}

static UIViewController *LBNewSystemMediaControlsViewController(NSInteger styleCase) {
    Class controllerClassCase = NSClassFromString(@"MPUSystemMediaControlsViewController");
    if (!controllerClassCase || ![controllerClassCase instancesRespondToSelector:@selector(initWithStyle:)]) { return nil; }

    return [(id)[controllerClassCase alloc] initWithStyle:styleCase];
}

static void LBSetAppearance(UIViewController *viewControllerCase, BOOL appearingCase) {
    if (!viewControllerCase) { return; }

    [viewControllerCase beginAppearanceTransition:appearingCase animated:NO];
    [viewControllerCase endAppearanceTransition];

    if ([viewControllerCase respondsToSelector:@selector(setPersistentUpdatesEnabled:)]) { [(id)viewControllerCase setPersistentUpdatesEnabled:appearingCase]; }
}

static void LBUpdateLockStatusBarTime(void) {
    id lockScreenManagerCase = LBSharedInstance(@"SBLockScreenManager");
    id dashBoardViewControllerCase = [lockScreenManagerCase respondsToSelector:@selector(dashBoardViewController)] ? [lockScreenManagerCase dashBoardViewController] : nil;
    if ([dashBoardViewControllerCase respondsToSelector:@selector(_updateStatusBar)]) { [dashBoardViewControllerCase _updateStatusBar]; }

    id statusBarStateProviderCase = LBSharedInstance(@"SBMainStatusBarStateProvider");
    if ([statusBarStateProviderCase respondsToSelector:@selector(updateTimeEnabled)]) { [statusBarStateProviderCase updateTimeEnabled]; }
}

@implementation LBMediaControlsView

- (instancetype)initWithFrame:(CGRect)frameCase {
    self = [super initWithFrame:frameCase];
    if (!self) { return nil; }

    self.backgroundColor = [UIColor clearColor];
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.hidden = YES;
    self.alpha = 0.0;

    self.controlsViewControllerCase = LBNewSystemMediaControlsViewController(lbLockScreenControlsStyleCase);
    if (self.controlsViewControllerCase) { [self addSubview:self.controlsViewControllerCase.view]; }

    {
        self.artworkViewControllerCase = LBNewSystemMediaControlsViewController(lbLockScreenArtworkStyleCase);
        [self.artworkViewControllerCase loadViewIfNeeded];

        UIView *artworkViewCase = [self.artworkViewControllerCase respondsToSelector:@selector(artworkView)] ? [(id)self.artworkViewControllerCase artworkView] : nil;
        if (artworkViewCase) {
            self.artworkContainerViewCase = [[UIView alloc] initWithFrame:CGRectZero];
            self.artworkContainerViewCase.userInteractionEnabled = NO;
            self.artworkContainerViewCase.backgroundColor = [UIColor clearColor];

            [artworkViewCase removeFromSuperview];
            artworkViewCase.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            [self.artworkContainerViewCase addSubview:artworkViewCase];
            [self insertSubview:self.artworkContainerViewCase atIndex:0];
        }
    }

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notificationListVisibilityDidChange:) name:LBNotificationListVisibilityDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(preferencesDidChange:) name:LBPreferencesDidChangeNotification object:nil];
    LBApplyLeftButtonPreference(self.controlsViewControllerCase);
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (self.appearedCase) {
        LBSetAppearance(self.controlsViewControllerCase, NO);
        LBSetAppearance(self.artworkViewControllerCase, NO);
    }
}

- (UIView *)hitTest:(CGPoint)pointCase withEvent:(UIEvent *)eventCase {
    UIView *hitViewCase = [super hitTest:pointCase withEvent:eventCase];
    return hitViewCase == self ? nil : hitViewCase;
}

- (void)attachSliderTargets {
    NSMutableArray *viewsCase = [NSMutableArray arrayWithObject:self];

    while (viewsCase.count) {
        UIView *viewCase = viewsCase.lastObject;
        [viewsCase removeLastObject];
        [viewsCase addObjectsFromArray:viewCase.subviews];

        if (![viewCase isKindOfClass:[UISlider class]]) { continue; }

        UISlider *sliderCase = (UISlider *)viewCase;
        if ([sliderCase.allTargets containsObject:self]) { continue; }

        [sliderCase addTarget:self action:@selector(sliderTrackingBegan:) forControlEvents:UIControlEventTouchDown];
        [sliderCase addTarget:self action:@selector(sliderTrackingEnded:) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside | UIControlEventTouchCancel];
    }
}

- (UIGestureRecognizer *)dashboardPanGestureRecognizer {
    UIView *dashboardViewCase = self.dashboardViewCase;
    UIScrollView *scrollViewCase = [dashboardViewCase respondsToSelector:@selector(scrollView)] ? [(id)dashboardViewCase scrollView] : nil;
    return [scrollViewCase isKindOfClass:[UIScrollView class]] ? scrollViewCase.panGestureRecognizer : nil;
}

- (void)sliderTrackingBegan:(UISlider *)sliderCase { [self dashboardPanGestureRecognizer].enabled = NO; }

- (void)sliderTrackingEnded:(UISlider *)sliderCase { [self dashboardPanGestureRecognizer].enabled = YES; }

- (void)layoutSubviews {
    [super layoutSubviews];
    [self attachSliderTargets];

    CGRect boundsCase = self.bounds;
    self.controlsViewControllerCase.view.frame = CGRectMake(0.0, LBMediaControlsY(boundsCase), CGRectGetWidth(boundsCase), LBMediaControlsHeight(boundsCase));
    if (LBIsPad()) {
        UIView *controlsViewCase = self.controlsViewControllerCase.view.subviews.firstObject;
        controlsViewCase.frame = CGRectMake(floor((CGRectGetWidth(boundsCase) - lbPadControlsWidthCase) * 0.5), 0.0, lbPadControlsWidthCase, LBMediaControlsHeight(boundsCase));
    }

    if (self.artworkContainerViewCase) {
        self.artworkContainerViewCase.frame = LBArtworkFrame(boundsCase);
        UIView *artworkViewCase = self.artworkContainerViewCase.subviews.firstObject;
        artworkViewCase.frame = self.artworkContainerViewCase.bounds;
    }
}

- (void)didMoveToWindow {
    [super didMoveToWindow];
    if (!self.window) { [self dashboardPanGestureRecognizer].enabled = YES; }
    [self updateAppearance];
}

- (void)updateAppearance {
    BOOL shouldAppearCase = self.controlsVisibleCase && self.window != nil;
    if (shouldAppearCase == self.appearedCase) { return; }

    self.appearedCase = shouldAppearCase;
    LBSetAppearance(self.controlsViewControllerCase, shouldAppearCase);
    LBSetAppearance(self.artworkViewControllerCase, shouldAppearCase);
}

- (void)setControlsVisible:(BOOL)visibleCase animated:(BOOL)animatedCase {
    BOOL changedCase = visibleCase != self.controlsVisibleCase;
    self.controlsVisibleCase = visibleCase;

    [self updateAppearance];
    [self updateArtworkVisibilityAnimated:NO];

    if (!changedCase && self.hidden == !visibleCase) { return; }

    if (visibleCase) { self.hidden = NO; }

    void (^animationsCase)(void) = ^{ self.alpha = visibleCase ? 1.0 : 0.0; };
    void (^completionCase)(BOOL) = ^(BOOL finishedCase) {
        if (!self.controlsVisibleCase) { self.hidden = YES; }
    };

    if (animatedCase && self.window) {
        [UIView animateWithDuration:0.25 animations:animationsCase completion:completionCase];
    } else {
        animationsCase();
        completionCase(YES);
    }
}

- (void)updateArtworkVisibilityAnimated:(BOOL)animatedCase {
    if (!self.artworkContainerViewCase) { return; }

    CGFloat alphaCase = LBNotificationListVisible() ? 0.0 : 1.0;
    if (self.artworkContainerViewCase.alpha == alphaCase) { return; }

    if (animatedCase && self.window) {
        [UIView animateWithDuration:0.25 animations:^{ self.artworkContainerViewCase.alpha = alphaCase; }];
    } else {
        self.artworkContainerViewCase.alpha = alphaCase;
    }
}

- (void)notificationListVisibilityDidChange:(NSNotification *)notificationCase { [self updateArtworkVisibilityAnimated:YES]; }

- (void)preferencesDidChange:(NSNotification *)notificationCase { LBApplyLeftButtonPreference(self.controlsViewControllerCase); }

@end

static LBMediaControlsView *LBMediaControlsViewForDashboard(UIView *dashboardViewCase) {
    return (LBMediaControlsView *)LBLockScreenViewForDashboard(dashboardViewCase, lbMediaControlsViewAssociationKeyCase, [LBMediaControlsView class]);
}

static void LBApplyMediaControlsState(UIView *dashboardViewCase, BOOL animatedCase) {
    LBMediaControlsView *mediaControlsViewCase = LBMediaControlsViewForDashboard(dashboardViewCase);
    BOOL visibleCase = LBMediaControlsVisible();

    [mediaControlsViewCase setControlsVisible:visibleCase animated:animatedCase];
    LBSetTimeDateHiddenForMediaControls(dashboardViewCase, visibleCase, animatedCase);
    LBSetNotificationBackgroundForMediaControls(dashboardViewCase, visibleCase, animatedCase);
}

static void LBInstallMediaControlsView(UIView *dashboardViewCase) {
    if (!dashboardViewCase.window) { return; }

    LBMediaControlsView *mediaControlsViewCase = LBMediaControlsViewForDashboard(dashboardViewCase);
    if (!mediaControlsViewCase) {
        mediaControlsViewCase = [[LBMediaControlsView alloc] initWithFrame:dashboardViewCase.bounds];
        [LBAllMediaControlsViews() addObject:mediaControlsViewCase];
    }

    mediaControlsViewCase.dashboardViewCase = dashboardViewCase;

    LBAttachLockScreenView(mediaControlsViewCase, dashboardViewCase, lbMediaControlsViewAssociationKeyCase);

    id contentViewControllerCase = lbMainPageContentViewControllerCase;
    if ([contentViewControllerCase respondsToSelector:@selector(isShowingMediaControls)]) { lbRestoredMediaControlsVisibleCase = [contentViewControllerCase isShowingMediaControls]; }

    LBApplyMediaControlsState(dashboardViewCase, NO);
}

static void LBMediaControlsVisibilityDidChange(id contentViewControllerCase) {
    if (![contentViewControllerCase respondsToSelector:@selector(isShowingMediaControls)]) { return; }

    lbMainPageContentViewControllerCase = contentViewControllerCase;

    BOOL visibleCase = [contentViewControllerCase isShowingMediaControls];
    BOOL changedCase = visibleCase != lbRestoredMediaControlsVisibleCase;
    lbRestoredMediaControlsVisibleCase = visibleCase;

    for (LBMediaControlsView *mediaControlsViewCase in LBAllMediaControlsViews().allObjects) {
        UIView *dashboardViewCase = mediaControlsViewCase.dashboardViewCase;
        if (dashboardViewCase) { LBApplyMediaControlsState(dashboardViewCase, YES); }
    }

    if (changedCase) { LBUpdateLockStatusBarTime(); }
}

%group LBMediaControls

%hook MPUTransportControlMediaRemoteController

- (void)setSupportedCommands:(NSArray *)commandsCase {
    if (!objc_getAssociatedObject(self, lbLockScreenRemoteControllerKeyCase)) {
        %orig;
        return;
    }

    objc_setAssociatedObject(self, lbOriginalSupportedCommandsKeyCase, commandsCase, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    %orig(LBFilteredSupportedCommands(commandsCase));
}

%end

%hook MPUSystemMediaControlsView

- (void)layoutSubviews {
    %orig;
    if (LBIsPad() || ![((UIView *)self).superview.superview isKindOfClass:[LBMediaControlsView class]]) { return; }

    static const CGFloat lbTitleGapCase = 6.0;
    UIView *viewsCase[] = { [(id)self trackInformationView], [(id)self transportControlsView], [(id)self volumeView] };
    for (NSUInteger viewIndexCase = 0; viewIndexCase < 3; viewIndexCase++) {
        UIView *viewCase = viewsCase[viewIndexCase];
        if (viewCase) { viewCase.frame = CGRectOffset(viewCase.frame, 0.0, lbTitleGapCase); }
    }
}

%end

%hook SBDashBoardMainPageContentViewController

- (void)_updateMediaControlsVisibility {
    %orig;
    if (LBLockbackEnabled()) { LBMediaControlsVisibilityDidChange(self); }
}

%end

%hook SBDashBoardViewController

- (BOOL)shouldShowLockStatusBarTime {
    if (LBMediaControlsVisible()) { return YES; }
    return %orig;
}

%end

%hook SBDashBoardView

- (void)didMoveToWindow {
    %orig;
    LBUpdateLockScreenFeature((UIView *)self, lbMediaControlsViewAssociationKeyCase, YES, LBInstallMediaControlsView);
}

- (void)layoutSubviews {
    %orig;
    LBUpdateLockScreenFeature((UIView *)self, lbMediaControlsViewAssociationKeyCase, NO, LBInstallMediaControlsView);
}

%end

%end

void LBInitializeMediaControls(void) {
    dlopen("/System/Library/PrivateFrameworks/MediaPlayerUI.framework/MediaPlayerUI", RTLD_LAZY);
    %init(LBMediaControls);
}

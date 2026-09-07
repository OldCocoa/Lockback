// This restores the iOS notification list and its lock screen background.

#import <UIKit/UIKit.h>
#import "../LockbackUtils.h"

@class LBNotificationsView;

@interface SBLockScreenNotificationListController : UIViewController
- (void)setDelegate:(id)delegateCase;
- (void)setIsOnscreen:(BOOL)isOnscreenCase;
- (void)prepareForTeardown;
@end

void lbAttachNotificationConversionControllerCase(id notificationControllerCase);
void lbDetachNotificationConversionControllerCase(id notificationControllerCase);
void lbInitializeNotificationsConversionCase(void);

@interface NSObject (LBNotificationsViewPrivateMethods)
+ (id)underlayPropertiesFactory;
+ (id)settingsForPrivateStyle:(NSInteger)styleCase;
- (id)scrollView;
- (id)propertiesWithDeviceDefaultGraphicsQuality;
- (id)propertiesWithGraphicsQuality:(NSInteger)qualityCase;
- (CGFloat)blurRadius;
- (UIColor *)tintColor;
- (CGFloat)tintAlpha;
- (void)setBackdropVisible:(BOOL)visibleCase;
- (void)setSaturationDeltaFactor:(CGFloat)saturationCase;
- (instancetype)initWithSettings:(id)settingsCase;
- (void)setComputesColorSettings:(BOOL)computesColorSettingsCase;
- (id)inputSettings;
- (void)setBlurRadius:(CGFloat)blurRadiusCase;
@end

// Bridges the callbacks expected by the iOS notification list controller into the iOS dashboard.
@interface LBNotificationsListDelegate : NSObject
@property (nonatomic, weak) UIView *dashboardViewCase;
@property (nonatomic, weak) LBNotificationsView *notificationsViewCase;
@end

// Owns the restored notification list, blur background, and its SpringBoard controller.
@interface LBNotificationsView : UIView
@property (nonatomic, weak) UIView *dashboardViewCase;
@property (nonatomic, strong) UIView *backdropViewCase;
@property (nonatomic, strong) UIView *tintViewCase;
@property (nonatomic, strong) SBLockScreenNotificationListController *notificationControllerCase;
@property (nonatomic, strong) LBNotificationsListDelegate *notificationDelegateCase;
@property (nonatomic) CGFloat blurRadiusCase;
@property (nonatomic) CGFloat tintAlphaCase;
- (instancetype)initWithFrame:(CGRect)viewFrameCase dashboardView:(UIView *)dashboardViewCase;
- (void)installNotificationBackground;
- (void)attachNotificationBackground;
- (void)applyNotificationBackgroundVisible:(BOOL)visibleCase;
- (void)setNotificationBackgroundVisible:(BOOL)visibleCase animated:(BOOL)animatedCase;
@end

// Updates the private backdrop blur radius used behind the notification list.
static void LBSetNotificationBlurRadiusCase(LBNotificationsView *notificationsViewCase, CGFloat blurRadiusCase) {
    id inputSettingsCase = [notificationsViewCase.backdropViewCase respondsToSelector:@selector(inputSettings)] ? [(id)notificationsViewCase.backdropViewCase inputSettings] : nil;

    if ([inputSettingsCase respondsToSelector:@selector(setBlurRadius:)]) { [inputSettingsCase setBlurRadius:blurRadiusCase]; }
}

@implementation LBNotificationsListDelegate

// These callbacks are required by the iOS list controller but do not need additional handling.
- (void)bannerEnablementChanged {}
- (void)attemptToUnlockUIFromNotification {}

// Shows or hides the notification underlay as the restored list becomes visible.
- (void)notificationListBecomingVisible:(BOOL)visibleCase {
    LBNotificationsView *notificationsViewCase = self.notificationsViewCase;
    [notificationsViewCase setNotificationBackgroundVisible:visibleCase animated:notificationsViewCase.window != nil];
}

// Gives the iOS list controller the active iOS dashboard scroll view.
- (id)lockScreenScrollView {
    UIView *dashboardViewCase = self.dashboardViewCase;
    return [dashboardViewCase respondsToSelector:@selector(scrollView)] ? [(id)dashboardViewCase scrollView] : nil;
}

- (void)presentFullscreenBulletinAlertWithItem:(id)itemCase {}
- (void)modifyFullscreenBulletinAlertWithItem:(id)itemCase {}
- (void)dismissFullscreenBulletinAlertWithItem:(id)itemCase reason:(id)reasonCase {}
- (void)removeCoordinatedPresentingController:(id)presentingControllerCase {}
- (void)addCoordinatedPresentingController:(id)presentingControllerCase {}
- (void)authenticateForNotificationActionWithCompletion:(void (^)(BOOL successCase))completionCase { if (completionCase) { completionCase(YES); } }

@end

@implementation LBNotificationsView

// Creates the iOS notification controller and attaches it to the Lockback notification view.
- (instancetype)initWithFrame:(CGRect)viewFrameCase dashboardView:(UIView *)dashboardViewCase {
    self = [super initWithFrame:viewFrameCase];
    if (!self) { return nil; }

    self.dashboardViewCase = dashboardViewCase;
    self.backgroundColor = [UIColor clearColor];
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    self.notificationDelegateCase = [[LBNotificationsListDelegate alloc] init];
    self.notificationDelegateCase.dashboardViewCase = dashboardViewCase;
    self.notificationDelegateCase.notificationsViewCase = self;

    [self installNotificationBackground];

    Class notificationControllerClassCase = NSClassFromString(@"SBLockScreenNotificationListController");
    self.notificationControllerCase = notificationControllerClassCase ? [[notificationControllerClassCase alloc] initWithNibName:nil bundle:nil] : nil;

    if (!self.notificationControllerCase) { return self; }

    [self.notificationControllerCase setDelegate:self.notificationDelegateCase];
    lbAttachNotificationConversionControllerCase(self.notificationControllerCase);

    UIView *notificationViewCase = self.notificationControllerCase.view;
    notificationViewCase.frame = self.bounds;
    notificationViewCase.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addSubview:notificationViewCase];
    [self.notificationControllerCase setIsOnscreen:YES];

    return self;
}

// Recreates the blur and tint values used by the iOS notification underlay.
- (void)installNotificationBackground {
    Class notificationControllerClassCase = NSClassFromString(@"SBLockScreenNotificationListController");
    id underlayFactoryCase = [notificationControllerClassCase respondsToSelector:@selector(underlayPropertiesFactory)] ? [(id)notificationControllerClassCase underlayPropertiesFactory] : nil;
    id underlayPropertiesCase = nil;

    if ([underlayFactoryCase respondsToSelector:@selector(propertiesWithDeviceDefaultGraphicsQuality)]) { underlayPropertiesCase = [underlayFactoryCase propertiesWithDeviceDefaultGraphicsQuality]; } 
    else if ([underlayFactoryCase respondsToSelector:@selector(propertiesWithGraphicsQuality:)]) { underlayPropertiesCase = [underlayFactoryCase propertiesWithGraphicsQuality:100]; }

    self.blurRadiusCase = [underlayPropertiesCase respondsToSelector:@selector(blurRadius)] ? [underlayPropertiesCase blurRadius] : 0.0;
    self.tintAlphaCase = [underlayPropertiesCase respondsToSelector:@selector(tintAlpha)] ? [underlayPropertiesCase tintAlpha] : 0.0;

    UIColor *tintColorCase = [underlayPropertiesCase respondsToSelector:@selector(tintColor)] ? [underlayPropertiesCase tintColor] : [UIColor clearColor];

    Class backdropSettingsClassCase = NSClassFromString(@"_UIBackdropViewSettings");
    Class backdropViewClassCase = NSClassFromString(@"_UIBackdropView");
    if (!backdropSettingsClassCase || !backdropViewClassCase) { return; }

    id backdropSettingsCase = [backdropSettingsClassCase respondsToSelector:@selector(settingsForPrivateStyle:)] ? [(id)backdropSettingsClassCase settingsForPrivateStyle:-2] : nil;
    if (!backdropSettingsCase) { return; }

    if ([backdropSettingsCase respondsToSelector:@selector(setBackdropVisible:)]) { [backdropSettingsCase setBackdropVisible:YES]; }
    if ([backdropSettingsCase respondsToSelector:@selector(setSaturationDeltaFactor:)]) { [backdropSettingsCase setSaturationDeltaFactor:1.8]; }

    self.backdropViewCase = [(id)[backdropViewClassCase alloc] initWithSettings:backdropSettingsCase];
    self.backdropViewCase.frame = self.bounds;
    self.backdropViewCase.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.backdropViewCase.userInteractionEnabled = NO;
    self.backdropViewCase.alpha = 0.0;

    if ([self.backdropViewCase respondsToSelector:@selector(setComputesColorSettings:)]) { [(id)self.backdropViewCase setComputesColorSettings:NO]; }

    LBSetNotificationBlurRadiusCase(self, 0.0);

    [self attachNotificationBackground];

    self.tintViewCase = [[UIView alloc] initWithFrame:self.backdropViewCase.bounds];
    self.tintViewCase.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tintViewCase.userInteractionEnabled = NO;
    self.tintViewCase.backgroundColor = tintColorCase;
    self.tintViewCase.alpha = 0.0;
    [self.backdropViewCase addSubview:self.tintViewCase];
}

- (void)attachNotificationBackground {
    UIView *dashboardViewCase = self.dashboardViewCase;
    if (!dashboardViewCase || !self.backdropViewCase) {
        return;
    }

    UIView *backgroundContainerCase = [dashboardViewCase respondsToSelector:@selector(slideableContentView)] ? [(id)dashboardViewCase slideableContentView] : nil;
    backgroundContainerCase = backgroundContainerCase ?: dashboardViewCase;

    if (self.backdropViewCase.superview != backgroundContainerCase) {
        [self.backdropViewCase removeFromSuperview];
        [backgroundContainerCase insertSubview:self.backdropViewCase atIndex:0];
    }

    self.backdropViewCase.frame = backgroundContainerCase.bounds;
}

// Applies the visible or hidden notification background state immediately.
- (void)applyNotificationBackgroundVisible:(BOOL)visibleCase {
    if (visibleCase) {
        LBSetNotificationBlurRadiusCase(self, self.blurRadiusCase);

        self.backdropViewCase.alpha = 1.0;
        self.tintViewCase.alpha = self.tintAlphaCase;
        return;
    }

    LBSetNotificationBlurRadiusCase(self, 0.0);

    self.backdropViewCase.alpha = 0.0;
    self.tintViewCase.alpha = 0.0;
}

- (void)setNotificationBackgroundVisible:(BOOL)visibleCase animated:(BOOL)animatedCase {
    if (!self.backdropViewCase) { return; }

    if (!animatedCase) {
        [self applyNotificationBackgroundVisible:visibleCase];
        return;
    }

    [UIView animateWithDuration:0.15 animations:^{ [self applyNotificationBackgroundVisible:visibleCase]; }];
}

- (void)didMoveToWindow {
    [super didMoveToWindow];

    self.notificationDelegateCase.dashboardViewCase = self.dashboardViewCase;
    [self attachNotificationBackground];
    [self.notificationControllerCase setIsOnscreen:self.window != nil];
}

- (void)layoutSubviews {
    [super layoutSubviews];

    [self attachNotificationBackground];
    self.notificationControllerCase.view.frame = self.bounds;
}

- (void)dealloc {
    [self.backdropViewCase removeFromSuperview];
    lbDetachNotificationConversionControllerCase(self.notificationControllerCase);
    [self.notificationControllerCase setIsOnscreen:NO];
    [self.notificationControllerCase prepareForTeardown];
}

@end

static const void *lbNotificationsViewAssociationKeyCase = &lbNotificationsViewAssociationKeyCase;

static LBNotificationsView *LBNotificationsViewForDashboard(UIView *dashboardViewCase) {
    return (LBNotificationsView *)LBLockScreenViewForDashboard(dashboardViewCase, lbNotificationsViewAssociationKeyCase, [LBNotificationsView class]);
}

// Creates and attaches the restored notification list to the active dashboard.
static void LBInstallNotificationsView(UIView *dashboardViewCase) {
    if (!dashboardViewCase.window) {
        return;
    }

    LBNotificationsView *notificationsViewCase = LBNotificationsViewForDashboard(dashboardViewCase);

    if (!notificationsViewCase) {
        notificationsViewCase = [[LBNotificationsView alloc] initWithFrame:dashboardViewCase.bounds dashboardView:dashboardViewCase];
    }

    notificationsViewCase.dashboardViewCase = dashboardViewCase;
    notificationsViewCase.notificationDelegateCase.dashboardViewCase = dashboardViewCase;
    LBAttachLockScreenView(notificationsViewCase, dashboardViewCase, lbNotificationsViewAssociationKeyCase);
}

// Hides the native iOS notification list while Lockback is enabled.
static void LBSetDashboardNotificationsHidden(UIViewController *viewControllerCase) {
    BOOL hiddenCase = LBLockbackEnabled();
    UIView *notificationViewCase = viewControllerCase.view;

    notificationViewCase.hidden = hiddenCase;
    notificationViewCase.userInteractionEnabled = !hiddenCase;
    notificationViewCase.accessibilityElementsHidden = hiddenCase;
}

// Keeps the native list hidden and the restored iOS list attached through dashboard lifecycle changes.
%group LBNotificationsView

%hook SBDashBoardNotificationListViewController

- (void)viewDidLoad {
    %orig;
    LBSetDashboardNotificationsHidden((UIViewController *)self);
}

- (void)viewWillAppear:(BOOL)animatedCase {
    %orig;
    LBSetDashboardNotificationsHidden((UIViewController *)self);
}

- (void)viewWillLayoutSubviews {
    %orig;
    LBSetDashboardNotificationsHidden((UIViewController *)self);
}

%end

%hook SBDashBoardView

- (void)didMoveToWindow {
    %orig;
    LBUpdateLockScreenFeature((UIView *)self, lbNotificationsViewAssociationKeyCase, YES, LBInstallNotificationsView);
}

- (void)layoutSubviews {
    %orig;
    LBUpdateLockScreenFeature((UIView *)self, lbNotificationsViewAssociationKeyCase, NO, LBInstallNotificationsView);
}

%end

%end

void LBInitializeNotificationsView(void) {
    lbInitializeNotificationsConversionCase();
    %init(LBNotificationsView);
}
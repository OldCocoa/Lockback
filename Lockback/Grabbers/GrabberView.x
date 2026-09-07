// This creates and maintains the lock screen grabber views.

#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <dlfcn.h>
#import "GrabberShared.h"

const void *lbGrabberOverlayAssociationKeyCase = &lbGrabberOverlayAssociationKeyCase;
static const void *lbIos9GrabberAssociationKeyCase = &lbIos9GrabberAssociationKeyCase;

// Gets one of the private chevron segment views used to build the iOS grabber shape.
static UIView *LBGrabberSubviewForIvar(UIView *grabberViewCase, const char *ivarNameCase) {
    Ivar grabberIvarCase = class_getInstanceVariable([grabberViewCase class], ivarNameCase);
    return grabberIvarCase ? object_getIvar(grabberViewCase, grabberIvarCase) : nil;
}

static void LBConfigureGrabberSegment(UIView *segmentViewCase, BOOL hiddenCase, CGRect frameCase) {
    segmentViewCase.hidden = hiddenCase;
    segmentViewCase.transform = CGAffineTransformIdentity;
    segmentViewCase.frame = frameCase;
    segmentViewCase.layer.cornerRadius = 3.5;
    segmentViewCase.layer.allowsEdgeAntialiasing = YES;
}

static void LBApplyIOSNineGrabberContentGeometry(UIView *grabberViewCase) {
    UIView *leftGrabberViewCase = LBGrabberSubviewForIvar(grabberViewCase, "_leftGrabberView");
    UIView *rightGrabberViewCase = LBGrabberSubviewForIvar(grabberViewCase, "_rightGrabberView");

    if (!leftGrabberViewCase || !rightGrabberViewCase) { return; }

    LBConfigureGrabberSegment(leftGrabberViewCase, NO, CGRectMake(0.0, 3.5, 36.0, 7.0));
    LBConfigureGrabberSegment(rightGrabberViewCase, YES, CGRectMake(14.0, 3.5, 22.0, 7.0));
}

// Applies the original overall size and internal geometry to a grabber view.
static void LBApplyIOSNineGrabberGeometry(UIView *grabberViewCase) {
    if (!grabberViewCase) { return; }

    CGRect grabberFrameCase = grabberViewCase.frame;
    
    grabberFrameCase.size = CGSizeMake(36.0, 14.0);
    grabberViewCase.frame = grabberFrameCase;

    LBApplyIOSNineGrabberContentGeometry(grabberViewCase);
}

// Uses the original vibrant grabber appearance when the current graphics quality supports it.
static BOOL LBShouldUseGrabberVibrancy(UIView *dashboardViewCase) {
    NSInteger (*graphicsQualityFunctionCase)(void) = (NSInteger (*)(void))dlsym(RTLD_DEFAULT, "SBUIGraphicsQuality");
    if (!graphicsQualityFunctionCase || graphicsQualityFunctionCase() != 100) { return NO; }

    return !([dashboardViewCase respondsToSelector:@selector(legibilitySettingsOverrideVibrancy)] && [(id)dashboardViewCase legibilitySettingsOverrideVibrancy]);
}

static UIView *LBNewGrabberView(BOOL useVibrancyCase) {
    Class chevronViewClassCase = NSClassFromString(@"SBUIChevronView");
    if (!chevronViewClassCase) { return nil; }

    UIColor *grabberColorCase = useVibrancyCase ? [UIColor blackColor] : [UIColor whiteColor];
    UIView *grabberViewCase = [(id)[chevronViewClassCase alloc] initWithColor:grabberColorCase];

    if ([grabberViewCase respondsToSelector:@selector(setState:)]) { [(id)grabberViewCase setState:0]; }

    [grabberViewCase sizeToFit];
    LBSetAssociatedObject(grabberViewCase, lbIos9GrabberAssociationKeyCase, @YES);
    LBApplyIOSNineGrabberGeometry(grabberViewCase);

    grabberViewCase.userInteractionEnabled = NO;

    grabberViewCase.isAccessibilityElement = NO;
    grabberViewCase.accessibilityElementsHidden = YES;

    return grabberViewCase;
}

// Samples the wallpaper behind a grabber and applies matching SpringBoard vibrancy.
static id LBApplyGrabberVibrancy(UIView *grabberViewCase, UIView *backgroundViewCase, id wallpaperControllerCase, id legibilitySettingsCase) {
    if (!grabberViewCase) { return nil; }

    UIColor *referenceColorCase = nil;
    CGFloat referenceContrastCase = 0.0;

    if (wallpaperControllerCase && [legibilitySettingsCase contentColor] && grabberViewCase.superview) {
        CGRect screenGrabberFrameCase = [grabberViewCase.superview convertRect:grabberViewCase.frame toView:nil];

        referenceColorCase = [wallpaperControllerCase averageColorInRect:screenGrabberFrameCase forVariant:0];
        referenceContrastCase = [wallpaperControllerCase contrastInRect:screenGrabberFrameCase forVariant:0];
    }

    grabberViewCase.backgroundColor = referenceColorCase;

    if ([grabberViewCase respondsToSelector:@selector(setBackgroundView:)]) { [(id)grabberViewCase setBackgroundView:backgroundViewCase]; }

    id vibrantSettingsCase = LBCreateVibrantSettings(referenceColorCase, referenceContrastCase, legibilitySettingsCase);
    if ([grabberViewCase respondsToSelector:@selector(setVibrantSettings:)]) { [(id)grabberViewCase setVibrantSettings:vibrantSettingsCase]; }

    return vibrantSettingsCase;
}

// Applies the non-vibrant fallback color used for lower graphics quality.
static void LBSetGrabberColor(UIView *grabberViewCase, UIColor *grabberColorCase) {
    if (!grabberViewCase) { return; }
    if ([grabberViewCase respondsToSelector:@selector(setVibrantSettings:)]) { [(id)grabberViewCase setVibrantSettings:nil]; }
    if ([grabberViewCase respondsToSelector:@selector(setBackgroundView:)]) { [(id)grabberViewCase setBackgroundView:nil]; }
    if ([grabberViewCase respondsToSelector:@selector(setColor:)]) { [(id)grabberViewCase setColor:grabberColorCase]; }

    grabberViewCase.backgroundColor = nil;
}

static void LBAddSubview(UIView *parentViewCase, UIView *subviewCase) { if (subviewCase) { [parentViewCase addSubview:subviewCase]; } }

// Positions the top or bottom grabber and moves it out of view while the lock screen is swiped.
static void LBPositionCenteredGrabber(UIView *grabberViewCase, CGFloat viewWidthCase, CGFloat viewHeightCase, CGFloat marginCase, CGFloat scrollProgressCase, BOOL bottomCase) {
    if (!grabberViewCase) { return; }

    CGFloat grabberOffsetCase = MAX(scrollProgressCase * 24.0, 0.0);
    CGRect grabberFrameCase = grabberViewCase.frame;

    grabberFrameCase.origin.x = LBPixelRound((viewWidthCase - CGRectGetWidth(grabberFrameCase)) / 2.0);
    grabberFrameCase.origin.y = bottomCase ? viewHeightCase - CGRectGetHeight(grabberFrameCase) - marginCase + grabberOffsetCase : marginCase - grabberOffsetCase;
    
    grabberViewCase.frame = grabberFrameCase;
}

@implementation LBGrabberOverlayView

// Creates all three replacement grabbers and their wallpaper effect backgrounds.
- (instancetype)initWithFrame:(CGRect)viewFrameCase dashboardView:(UIView *)dashboardViewCase {
    self = [super initWithFrame:viewFrameCase];
    if (!self) { return nil; }

    self.dashboardViewCase = dashboardViewCase;
    self.backgroundColor = [UIColor clearColor];

    self.userInteractionEnabled = NO;

    self.isAccessibilityElement = NO;
    self.accessibilityElementsHidden = YES;

    BOOL useVibrancyCase = LBShouldUseGrabberVibrancy(dashboardViewCase);

    self.topGrabberViewCase = LBNewGrabberView(useVibrancyCase);
    self.bottomGrabberViewCase = LBNewGrabberView(useVibrancyCase);
    self.cameraGrabberViewCase = LBNewCameraGrabberView(useVibrancyCase);

    self.topGrabberBackgroundViewCase = LBNewWallpaperEffectView(10);
    self.bottomGrabberBackgroundViewCase = LBNewWallpaperEffectView(10);
    self.cameraGrabberBackgroundViewCase = LBNewWallpaperEffectView(10);

    LBAddSubview(self, self.topGrabberViewCase);
    LBAddSubview(self, self.bottomGrabberViewCase);
    LBAddSubview(self, self.cameraGrabberViewCase);

    [self updateGrabberAppearance];
    [self updateMediaControlsVisibility:lbMediaControlsVisibleCase];
    return self;
}

// Positions the top, bottom, and camera grabbers using the current dashboard size and scroll state.
- (void)layoutSubviews {
    [super layoutSubviews];

    CGFloat grabberMarginCase = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? 7.0 : 6.0;
    CGFloat viewWidthCase = CGRectGetWidth(self.bounds);
    CGFloat viewHeightCase = CGRectGetHeight(self.bounds);
    CGFloat scrollProgressCase = self.scrollProgressCase;

    LBPositionCenteredGrabber(self.topGrabberViewCase, viewWidthCase, viewHeightCase, grabberMarginCase, scrollProgressCase, NO);
    LBPositionCenteredGrabber(self.bottomGrabberViewCase, viewWidthCase, viewHeightCase, grabberMarginCase, scrollProgressCase, YES);

    UIView *cameraGrabberViewCase = self.cameraGrabberViewCase;
    if (cameraGrabberViewCase) {
        cameraGrabberViewCase.hidden = !LBShouldShowCameraGrabber();

        CGFloat cameraGrabberInsetCase = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? 10.0 : 7.0;
        CGRect cameraGrabberFrameCase = cameraGrabberViewCase.frame;
        BOOL isRightToLeftCase = [UIApplication sharedApplication].userInterfaceLayoutDirection == UIUserInterfaceLayoutDirectionRightToLeft;

        cameraGrabberFrameCase.origin.x = isRightToLeftCase ? cameraGrabberInsetCase : viewWidthCase - CGRectGetWidth(cameraGrabberFrameCase) - cameraGrabberInsetCase;
        cameraGrabberFrameCase.origin.y = viewHeightCase - CGRectGetHeight(cameraGrabberFrameCase) - cameraGrabberInsetCase;
        cameraGrabberViewCase.frame = cameraGrabberFrameCase;
    }

    [self updateGrabberAppearance];
}

// Updates how far the top and bottom grabbers should move offscreen while paging.
- (void)updateGrabberScrollProgress:(CGFloat)scrollProgressCase {
    self.scrollProgressCase = scrollProgressCase;
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

// Hides the top grabber while SpringBoard reports that media controls are visible.
- (void)updateMediaControlsVisibility:(BOOL)visibleCase { self.topGrabberViewCase.alpha = visibleCase ? 0.0 : 1.0; }

// Keeps the grabber overlay attached to the lock screen content during the camera slide animation.
- (void)updateCameraOffset:(CGFloat)cameraOffsetCase {
    self.cameraOffsetCase = cameraOffsetCase;

    UIView *dashboardViewCase = self.dashboardViewCase;
    if (!dashboardViewCase) { return; }

    CGRect overlayFrameCase = dashboardViewCase.bounds;
    overlayFrameCase.origin.y += cameraOffsetCase;

    self.frame = overlayFrameCase;
}

// Refreshes grabber colors and vibrancy from the current wallpaper legibility settings.
- (void)updateGrabberAppearance {
    UIView *dashboardViewCase = self.dashboardViewCase;
    if (!dashboardViewCase) { return; }

    id legibilitySettingsCase = [(id)dashboardViewCase legibilitySettings];
    BOOL useVibrancyCase = LBShouldUseGrabberVibrancy(dashboardViewCase);

    if (useVibrancyCase) {
        if ([self.cameraGrabberViewCase respondsToSelector:@selector(setVibrancyAllowed:)]) { [(id)self.cameraGrabberViewCase setVibrancyAllowed:YES]; }

        id wallpaperControllerCase = LBSharedInstance(@"SBWallpaperController");
        LBApplyGrabberVibrancy(self.topGrabberViewCase, self.topGrabberBackgroundViewCase, wallpaperControllerCase, legibilitySettingsCase);
        LBApplyGrabberVibrancy(self.bottomGrabberViewCase, self.bottomGrabberBackgroundViewCase, wallpaperControllerCase, legibilitySettingsCase);

        id cameraVibrantSettingsCase = LBApplyGrabberVibrancy(self.cameraGrabberViewCase, self.cameraGrabberBackgroundViewCase, wallpaperControllerCase, legibilitySettingsCase);
        LBApplyIOSNineCameraGrabberVibrancy(self.cameraGrabberViewCase, cameraVibrantSettingsCase);
        return;
    }

    UIColor *grabberColorCase = [legibilitySettingsCase secondaryColor] ?: [UIColor whiteColor];
    LBSetGrabberColor(self.topGrabberViewCase, grabberColorCase);
    LBSetGrabberColor(self.bottomGrabberViewCase, grabberColorCase);

    UIView *cameraGrabberViewCase = self.cameraGrabberViewCase;
    if (!cameraGrabberViewCase) { return; }

    if ([cameraGrabberViewCase respondsToSelector:@selector(setVibrancyAllowed:)]) { [(id)cameraGrabberViewCase setVibrancyAllowed:NO]; }
    if ([cameraGrabberViewCase respondsToSelector:@selector(setVibrantSettings:)]) { [(id)cameraGrabberViewCase setVibrantSettings:nil]; }
    if ([cameraGrabberViewCase respondsToSelector:@selector(setBackgroundView:)]) { [(id)cameraGrabberViewCase setBackgroundView:nil]; }

    cameraGrabberViewCase.backgroundColor = nil;
    LBRemoveCameraGrabberVibrancy(cameraGrabberViewCase);

    if ([cameraGrabberViewCase respondsToSelector:@selector(setStrength:)]) {
        NSInteger legibilityStyleCase = 0;
        if ([legibilitySettingsCase respondsToSelector:@selector(style)]) { legibilityStyleCase = ((NSInteger (*)(id, SEL))objc_msgSend)(legibilitySettingsCase, @selector(style)); }

        [(id)cameraGrabberViewCase setStrength:LBCameraGrabberStrength(legibilityStyleCase)];
    }

    if ([cameraGrabberViewCase respondsToSelector:@selector(setLegibilitySettings:)]) { [(id)cameraGrabberViewCase setLegibilitySettings:legibilitySettingsCase]; }
}

@end

// Returns the grabber overlay associated with this dashboard.
LBGrabberOverlayView *LBGrabberOverlayForDashboard(UIView *dashboardViewCase) {
    id grabberOverlayViewCase = objc_getAssociatedObject(dashboardViewCase, lbGrabberOverlayAssociationKeyCase);
    return [grabberOverlayViewCase isKindOfClass:[LBGrabberOverlayView class]] ? grabberOverlayViewCase : nil;
}

// Creates and attaches the grabber overlay to the active dashboard.
void LBInstallGrabberOverlay(UIView *dashboardViewCase) {
    if (!dashboardViewCase.window) { return; }

    LBGrabberOverlayView *grabberOverlayViewCase = LBGrabberOverlayForDashboard(dashboardViewCase);
    if (!grabberOverlayViewCase) {
        grabberOverlayViewCase = [[LBGrabberOverlayView alloc] initWithFrame:dashboardViewCase.bounds dashboardView:dashboardViewCase];
        grabberOverlayViewCase.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        LBSetAssociatedObject(dashboardViewCase, lbGrabberOverlayAssociationKeyCase, grabberOverlayViewCase);
    }

    grabberOverlayViewCase.dashboardViewCase = dashboardViewCase;

    if (grabberOverlayViewCase.superview != dashboardViewCase) {
        [grabberOverlayViewCase removeFromSuperview];
        [dashboardViewCase addSubview:grabberOverlayViewCase];
    }

    [grabberOverlayViewCase updateCameraOffset:grabberOverlayViewCase.cameraOffsetCase];
    [grabberOverlayViewCase updateMediaControlsVisibility:lbMediaControlsVisibleCase];
    [dashboardViewCase bringSubviewToFront:grabberOverlayViewCase];
}


%group LBGrabberView

%hook SBUIChevronView

- (void)layoutSubviews {
    %orig;
    if (LBLockbackEnabled() && objc_getAssociatedObject(self, lbIos9GrabberAssociationKeyCase)) { LBApplyIOSNineGrabberContentGeometry((UIView *)self); }
}

%end

%end

void LBInitializeGrabberView(void) { %init(LBGrabberView); }
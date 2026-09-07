// This restores the lock screen camera grabber and camera slide behavior.

#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "GrabberShared.h"

static const void *lbCameraTintViewAssociationKeyCase = &lbCameraTintViewAssociationKeyCase;

// Maps SpringBoard legibility styles to the camera grabber strength used by iOS.
CGFloat LBCameraGrabberStrength(NSInteger legibilityStyleCase) {
    switch (legibilityStyleCase) {
        case 1:
            return 0.35;
        case 2:
            return 0.75;
        default:
            return 0.0;
    }
}

// Checks whether SpringBoard currently allows the lock screen camera grabber.
BOOL LBShouldShowCameraGrabber(void) {
    UIApplication *applicationCase = [UIApplication sharedApplication];
    return ![applicationCase respondsToSelector:@selector(canShowLockScreenCameraGrabber)] || [(id)applicationCase canShowLockScreenCameraGrabber];
}

static id LBCameraApplication(void) {
    id applicationControllerCase = LBSharedInstance(@"SBApplicationController");
    return [applicationControllerCase respondsToSelector:@selector(cameraApplication)] ? [applicationControllerCase cameraApplication] : nil;
}

// Loads the original lock screen camera grabber image.
static UIImage *LBCameraGrabberImage(void) {
    UIImage *cameraGrabberImageCase = [UIImage imageNamed:@"camera-lockscreen.png"];
    return cameraGrabberImageCase ?: [UIImage imageNamed:@"camera-lockscreen"];
}

static void LBSetIOSNineCameraGrabberImage(UIView *cameraGrabberViewCase, UIImage *cameraGrabberImageCase) {
    Ivar saturatedIconViewIvarCase = class_getInstanceVariable([cameraGrabberViewCase class], "_saturatedIconView");

    if (saturatedIconViewIvarCase) {
        UIView *saturatedIconViewCase = object_getIvar(cameraGrabberViewCase, saturatedIconViewIvarCase);
        [saturatedIconViewCase removeFromSuperview];

        object_setIvar(cameraGrabberViewCase, saturatedIconViewIvarCase, nil);
    }

    Ivar grabberImageIvarCase = class_getInstanceVariable([cameraGrabberViewCase class], "_grabberImage");
    if (grabberImageIvarCase) { object_setIvar(cameraGrabberViewCase, grabberImageIvarCase, cameraGrabberImageCase); }
}

// Removes the custom camera vibrancy mask and tint view.
void LBRemoveCameraGrabberVibrancy(UIView *cameraGrabberViewCase) {
    UIView *cameraTintViewCase = objc_getAssociatedObject(cameraGrabberViewCase, lbCameraTintViewAssociationKeyCase);
    [cameraTintViewCase removeFromSuperview];

    LBSetAssociatedObject(cameraGrabberViewCase, lbCameraTintViewAssociationKeyCase, nil);
    cameraGrabberViewCase.layer.mask = nil;
}

// Applies the iOS camera image as a mask over SpringBoard's vibrant tint view.
void LBApplyIOSNineCameraGrabberVibrancy(UIView *cameraGrabberViewCase, id vibrantSettingsCase) {
    UIImage *cameraGrabberImageCase = LBCameraGrabberImage();
    if (!cameraGrabberViewCase || !vibrantSettingsCase || !cameraGrabberImageCase) { return; }

    LBRemoveCameraGrabberVibrancy(cameraGrabberViewCase);

    CALayer *maskLayerCase = [CALayer layer];
    maskLayerCase.frame = cameraGrabberViewCase.bounds;
    maskLayerCase.contents = (__bridge id)cameraGrabberImageCase.CGImage;
    cameraGrabberViewCase.layer.mask = maskLayerCase;

    if (![vibrantSettingsCase respondsToSelector:@selector(tintViewWithFrame:)]) { return; }

    UIView *cameraTintViewCase = [vibrantSettingsCase tintViewWithFrame:cameraGrabberViewCase.bounds];
    if (!cameraTintViewCase) { return; }

    cameraTintViewCase.userInteractionEnabled = NO;
    cameraTintViewCase.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    [cameraGrabberViewCase addSubview:cameraTintViewCase];
    LBSetAssociatedObject(cameraGrabberViewCase, lbCameraTintViewAssociationKeyCase, cameraTintViewCase);
}

// Creates the replacement iOS camera grabber using SpringBoard's slide-up grabber view.
UIView *LBNewCameraGrabberView(BOOL useVibrancyCase) {
    Class cameraGrabberViewClassCase = NSClassFromString(@"SBSlideUpAppGrabberView");
    if (!cameraGrabberViewClassCase) { return nil; }

    UIView *cameraGrabberViewCase = [(id)[cameraGrabberViewClassCase alloc] initWithAdditionalTopPadding:YES invertVerticalInsets:NO];
    LBSetIOSNineCameraGrabberImage(cameraGrabberViewCase, LBCameraGrabberImage());
    if ([cameraGrabberViewCase respondsToSelector:@selector(setVibrancyAllowed:)]) { [(id)cameraGrabberViewCase setVibrancyAllowed:useVibrancyCase]; }

    [cameraGrabberViewCase sizeToFit];

    cameraGrabberViewCase.userInteractionEnabled = NO;

    cameraGrabberViewCase.isAccessibilityElement = NO;
    cameraGrabberViewCase.accessibilityElementsHidden = YES;

    return cameraGrabberViewCase;
}

// Finds the dashboard view controlled by the camera slide controller.
static UIView *LBDashboardViewForSlideController(id slideControllerCase) {
    SEL delegateSelectorCase = @selector(delegate);
    if (![slideControllerCase respondsToSelector:delegateSelectorCase]) { return nil; }

    id delegateCase = ((id (*)(id, SEL))objc_msgSend)(slideControllerCase, delegateSelectorCase);
    return [delegateCase isKindOfClass:[UIViewController class]] ? [(UIViewController *)delegateCase view] : nil;
}

static void LBUpdateCameraGrabberOffset(id slideControllerCase, CGFloat cameraOffsetCase) {
    UIView *dashboardViewCase = LBDashboardViewForSlideController(slideControllerCase);
    if (!dashboardViewCase) {
        return;
    }

    LBGrabberOverlayView *grabberOverlayViewCase = LBGrabberOverlayForDashboard(dashboardViewCase);
    if (!grabberOverlayViewCase) {
        LBInstallGrabberOverlay(dashboardViewCase);
        grabberOverlayViewCase = LBGrabberOverlayForDashboard(dashboardViewCase);
    }

    [grabberOverlayViewCase updateCameraOffset:cameraOffsetCase];
}

// Forces the slide-up controller target back to the Camera application.
static void LBSetCameraSlideTarget(id slideControllerCase) {
    id cameraApplicationCase = LBShouldShowCameraGrabber() ? LBCameraApplication() : nil;
    if ([slideControllerCase respondsToSelector:@selector(_setTargetApp:withAppSuggestion:)]) { [slideControllerCase _setTargetApp:cameraApplicationCase withAppSuggestion:nil]; }
}


%group LBCameraGrabber

%hook SBDashBoardSlideUpToAppController

- (void)_translateSlidingViewByY:(CGFloat)yTranslationCase {
    %orig;
    if (LBLockbackEnabled()) { LBUpdateCameraGrabberOffset(self, yTranslationCase); }
}

- (id)init {
    id slideControllerCase = %orig;
    if (LBLockbackEnabled()) { LBSetCameraSlideTarget(slideControllerCase); }

    return slideControllerCase;
}

- (void)_updateSlideUpToAppControllerWithCurrentSuggestedApp {
    if (!LBLockbackEnabled()) {
        %orig;
        return;
    }

    LBSetCameraSlideTarget(self);
}

- (void)_performTargetAppContinuity {
    if (!LBLockbackEnabled()) {
        %orig;
        return;
    }

    id cameraApplicationCase = LBCameraApplication();
    if (!cameraApplicationCase || !LBShouldShowCameraGrabber()) {
        %orig;
        return;
    }

    [(id)self _setState:4];
    [(id)self _activateTargetAppAnimated:YES];
}

- (void)_activateTargetAppAnimated:(BOOL)animatedCase {
    if (!LBLockbackEnabled()) {
        %orig;
        return;
    }

    id cameraApplicationCase = LBCameraApplication();
    if (!cameraApplicationCase || !LBShouldShowCameraGrabber()) {
        %orig;
        return;
    }

    NSURL *cameraUrlCase = [NSURL URLWithString:@"camera://?launchsource=lockscreen"];
    [(id)self _activateApp:cameraApplicationCase withAppInfo:nil andURL:cameraUrlCase animated:animatedCase];
}

%end

%hook SBDashBoardViewController

- (id)slideControllerRequestedGrabberView:(id)slideControllerCase {
    if (!LBLockbackEnabled()) {
        id grabberViewCase = %orig;
        return grabberViewCase;
    }

    Class slideControllerClassCase = NSClassFromString(@"SBDashBoardSlideUpToAppController");
    if (slideControllerClassCase && [slideControllerCase isKindOfClass:slideControllerClassCase]) {
        UIView *dashboardViewCase = (UIView *)[(UIViewController *)self view];
        LBInstallGrabberOverlay(dashboardViewCase);

        LBGrabberOverlayView *grabberOverlayViewCase = LBGrabberOverlayForDashboard(dashboardViewCase);
        if (grabberOverlayViewCase.cameraGrabberViewCase && !grabberOverlayViewCase.cameraGrabberViewCase.hidden) { return grabberOverlayViewCase.cameraGrabberViewCase; }
    }

    id grabberViewCase = %orig;
    return grabberViewCase;
}

%end

%end

void LBInitializeCameraGrabber(void) { %init(LBCameraGrabber); }
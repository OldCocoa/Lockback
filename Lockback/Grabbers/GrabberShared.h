#ifndef GrabberShared_h
#define GrabberShared_h

#import <UIKit/UIKit.h>
#import "../LockbackUtils.h"

@interface NSObject (LBGrabberPrivateMethods)
- (instancetype)initWithColor:(UIColor *)colorCase;
- (instancetype)initWithAdditionalTopPadding:(BOOL)additionalTopPaddingCase invertVerticalInsets:(BOOL)invertVerticalInsetsCase;
- (void)setState:(NSInteger)stateCase;
- (void)setColor:(UIColor *)colorCase;
- (void)setVibrantSettings:(id)vibrantSettingsCase;
- (void)setVibrancyAllowed:(BOOL)vibrancyAllowedCase;
- (void)setLegibilitySettings:(id)legibilitySettingsCase;
- (void)setBackgroundView:(UIView *)backgroundViewCase;
- (void)setStrength:(CGFloat)strengthCase;
- (id)legibilitySettings;
- (id)contentColor;
- (id)secondaryColor;
- (BOOL)legibilitySettingsOverrideVibrancy;
- (BOOL)canShowLockScreenCameraGrabber;
- (UIColor *)averageColorInRect:(CGRect)rectCase forVariant:(NSInteger)wallpaperVariantCase;
- (CGFloat)contrastInRect:(CGRect)rectCase forVariant:(NSInteger)wallpaperVariantCase;
- (UIView *)tintViewWithFrame:(CGRect)viewFrameCase;
- (id)cameraApplication;
- (BOOL)isShowingMediaControls;
- (void)_setTargetApp:(id)targetAppCase withAppSuggestion:(id)appSuggestionCase;
- (void)_setState:(NSUInteger)stateCase;
- (void)_activateTargetAppAnimated:(BOOL)animatedCase;
- (void)_activateApp:(id)applicationCase withAppInfo:(id)appInfoCase andURL:(NSURL *)urlCase animated:(BOOL)animatedCase;
@end

@interface LBGrabberOverlayView : UIView
@property (nonatomic, weak) UIView *dashboardViewCase;
@property (nonatomic, strong) UIView *topGrabberViewCase;
@property (nonatomic, strong) UIView *bottomGrabberViewCase;
@property (nonatomic, strong) UIView *cameraGrabberViewCase;
@property (nonatomic, strong) UIView *topGrabberBackgroundViewCase;
@property (nonatomic, strong) UIView *bottomGrabberBackgroundViewCase;
@property (nonatomic, strong) UIView *cameraGrabberBackgroundViewCase;
@property (nonatomic) CGFloat scrollProgressCase;
@property (nonatomic) CGFloat cameraOffsetCase;
- (instancetype)initWithFrame:(CGRect)viewFrameCase dashboardView:(UIView *)dashboardViewCase;
- (void)updateGrabberAppearance;
- (void)updateGrabberScrollProgress:(CGFloat)scrollProgressCase;
- (void)updateCameraOffset:(CGFloat)cameraOffsetCase;
- (void)updateMediaControlsVisibility:(BOOL)visibleCase;
@end

extern const void *lbGrabberOverlayAssociationKeyCase;
extern BOOL lbMediaControlsVisibleCase;

LBGrabberOverlayView *LBGrabberOverlayForDashboard(UIView *dashboardViewCase);
void LBInstallGrabberOverlay(UIView *dashboardViewCase);

CGFloat LBCameraGrabberStrength(NSInteger legibilityStyleCase);
BOOL LBShouldShowCameraGrabber(void);
UIView *LBNewCameraGrabberView(BOOL useVibrancyCase);
void LBRemoveCameraGrabberVibrancy(UIView *cameraGrabberViewCase);
void LBApplyIOSNineCameraGrabberVibrancy(UIView *cameraGrabberViewCase, id vibrantSettingsCase);

void LBInitializeGrabberView(void);
void LBInitializeCameraGrabber(void);

#endif
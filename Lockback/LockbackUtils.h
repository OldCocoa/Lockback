// This contains shared helpers used by the different Lockback lock screen features.

#ifndef LockbackUtils_h
#define LockbackUtils_h

#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <math.h>
#import "Lockback.h"

@interface NSObject (LBUtilsPrivateMethods)
+ (id)sharedInstance;
+ (id)vibrantSettingsWithReferenceColor:(UIColor *)referenceColorCase referenceContrast:(CGFloat)referenceContrastCase legibilitySettings:(id)legibilitySettingsCase;
- (instancetype)initWithWallpaperVariant:(NSInteger)wallpaperVariantCase;
- (UIView *)mainPageView;
- (UIView *)slideableContentView;
- (id)dashBoardViewController;
@end

typedef void (*LBLockScreenInstaller)(UIView *dashboardViewCase);

// Rounds a point value to the nearest physical screen pixel.
static inline CGFloat LBPixelRound(CGFloat pointValueCase) {
    CGFloat screenScaleCase = [UIScreen mainScreen].scale;
    return round(pointValueCase * screenScaleCase) / screenScaleCase;
}

// Returns the shared instance of a private SpringBoard class when it is available.
static inline id LBSharedInstance(NSString *classNameCase) {
    Class targetClassCase = NSClassFromString(classNameCase);
    return targetClassCase && [targetClassCase respondsToSelector:@selector(sharedInstance)] ? [(id)targetClassCase sharedInstance] : nil;
}

// Creates the same vibrant settings used by SpringBoard lock screen elements.
static inline id LBCreateVibrantSettings(UIColor *referenceColorCase, CGFloat referenceContrastCase, id legibilitySettingsCase) {
    Class vibrantSettingsClassCase = NSClassFromString(@"_SBFVibrantSettings");
    return vibrantSettingsClassCase && [vibrantSettingsClassCase respondsToSelector:@selector(vibrantSettingsWithReferenceColor:referenceContrast:legibilitySettings:)]
        ? [(id)vibrantSettingsClassCase vibrantSettingsWithReferenceColor:referenceColorCase referenceContrast:referenceContrastCase legibilitySettings:legibilitySettingsCase] : nil;
}

// Creates a wallpaper effect view using the requested private SpringBoard style.
static inline UIView *LBNewWallpaperEffectView(NSInteger styleCase) {
    Class wallpaperEffectViewClassCase = NSClassFromString(@"SBWallpaperEffectView");
    if (!wallpaperEffectViewClassCase) { return nil; }

    UIView *wallpaperEffectViewCase = [(id)[wallpaperEffectViewClassCase alloc] initWithWallpaperVariant:0];
    if ([wallpaperEffectViewCase respondsToSelector:@selector(setStyle:)]) { ((void (*)(id, SEL, NSInteger))objc_msgSend)(wallpaperEffectViewCase, @selector(setStyle:), styleCase); }

    return wallpaperEffectViewCase;
}

// Returns the dashboard view that should contain Lockback's replacement views.
static inline UIView *LBLockScreenContentView(UIView *dashboardViewCase) {
    UIView *contentViewCase = [dashboardViewCase respondsToSelector:@selector(mainPageView)] ? [(id)dashboardViewCase mainPageView] : nil;
    if (!contentViewCase && [dashboardViewCase respondsToSelector:@selector(slideableContentView)]) { contentViewCase = [(id)dashboardViewCase slideableContentView]; }

    return contentViewCase ?: dashboardViewCase;
}

// Stores a Lockback object on a SpringBoard object using a retained association.
static inline void LBSetAssociatedObject(id objectCase, const void *associationKeyCase, id valueCase) { objc_setAssociatedObject(objectCase, associationKeyCase, valueCase, OBJC_ASSOCIATION_RETAIN_NONATOMIC); }

// Stores the same replacement view on both the dashboard and its current content view.
static inline void LBStoreLockScreenView(UIView *lockScreenViewCase, UIView *dashboardViewCase, UIView *contentViewCase, const void *associationKeyCase) {
    LBSetAssociatedObject(dashboardViewCase, associationKeyCase, lockScreenViewCase);
    LBSetAssociatedObject(contentViewCase, associationKeyCase, lockScreenViewCase);
}

// Finds the existing replacement view, removes duplicates, and repairs stale associations.
static inline UIView *LBLockScreenViewForDashboard(UIView *dashboardViewCase, const void *associationKeyCase, Class viewClassCase) {
    if (!dashboardViewCase || !associationKeyCase || !viewClassCase) { return nil; }

    UIView *contentViewCase = LBLockScreenContentView(dashboardViewCase);
    UIView *dashboardViewObjectCase = objc_getAssociatedObject(dashboardViewCase, associationKeyCase);
    UIView *lockScreenViewCase = objc_getAssociatedObject(contentViewCase, associationKeyCase);

    NSArray *contentSubviewsCase = [contentViewCase.subviews copy];

    for (NSUInteger subviewIndexCase = 0; subviewIndexCase < contentSubviewsCase.count; subviewIndexCase++) {
        UIView *subviewCase = contentSubviewsCase[subviewIndexCase];
        if (![subviewCase isKindOfClass:viewClassCase]) { continue; }

        if (!lockScreenViewCase) { lockScreenViewCase = subviewCase; }
        else if (subviewCase != lockScreenViewCase) { [subviewCase removeFromSuperview]; }
    }

    if (!lockScreenViewCase) { lockScreenViewCase = dashboardViewObjectCase; }
    else if (dashboardViewObjectCase && dashboardViewObjectCase != lockScreenViewCase) { [dashboardViewObjectCase removeFromSuperview]; }

    if (!lockScreenViewCase) { return nil; }

    UIView *previousContentViewCase = lockScreenViewCase.superview;
    if (previousContentViewCase && previousContentViewCase != contentViewCase && objc_getAssociatedObject(previousContentViewCase, associationKeyCase) == lockScreenViewCase) { LBSetAssociatedObject(previousContentViewCase, associationKeyCase, nil); }

    LBStoreLockScreenView(lockScreenViewCase, dashboardViewCase, contentViewCase, associationKeyCase);
    return lockScreenViewCase;
}

// Attaches a replacement view to the current dashboard content view and keeps it in front.
static inline void LBAttachLockScreenView(UIView *lockScreenViewCase, UIView *dashboardViewCase, const void *associationKeyCase) {
    if (!lockScreenViewCase || !dashboardViewCase || !associationKeyCase) { return; }

    UIView *contentViewCase = LBLockScreenContentView(dashboardViewCase);
    if (lockScreenViewCase.superview != contentViewCase) {
        [lockScreenViewCase removeFromSuperview];
        [contentViewCase addSubview:lockScreenViewCase];
    }

    lockScreenViewCase.frame = contentViewCase.bounds;
    [contentViewCase bringSubviewToFront:lockScreenViewCase];

    LBStoreLockScreenView(lockScreenViewCase, dashboardViewCase, contentViewCase, associationKeyCase);
}

// Removes a replacement view and clears its dashboard associations.
static inline void LBRemoveLockScreenViewForDashboard(UIView *dashboardViewCase, const void *associationKeyCase) {
    if (!dashboardViewCase || !associationKeyCase) { return; }

    UIView *lockScreenViewCase = objc_getAssociatedObject(dashboardViewCase, associationKeyCase);
    if (!lockScreenViewCase) { return; }

    UIView *contentViewCase = lockScreenViewCase.superview ?: LBLockScreenContentView(dashboardViewCase);
    if (objc_getAssociatedObject(contentViewCase, associationKeyCase) == lockScreenViewCase) { LBSetAssociatedObject(contentViewCase, associationKeyCase, nil); }

    [lockScreenViewCase removeFromSuperview];
    LBSetAssociatedObject(dashboardViewCase, associationKeyCase, nil);
}

// Installs or removes a Lockback feature based on the current lock screen state.
static inline void LBUpdateLockScreenFeature(UIView *dashboardViewCase, const void *associationKeyCase, BOOL removeWhenDetachedCase, LBLockScreenInstaller installerCase) {
    if (!LBLockbackEnabled() || (removeWhenDetachedCase && !dashboardViewCase.window)) {
        LBRemoveLockScreenViewForDashboard(dashboardViewCase, associationKeyCase);
        return;
    }

    installerCase(dashboardViewCase);
}

#endif
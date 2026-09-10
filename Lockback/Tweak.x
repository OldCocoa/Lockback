// This part of the tweak initializes all separated hooks to make the tweak function.

#import <UIKit/UIKit.h>
#import "Lockback.h"

static BOOL lbLockbackEnabledCase = YES;
static BOOL lbNotificationCenterMirroringEnabledCase = NO;
static BOOL lbDisableHomeButtonUnlockEnabledCase = YES;
static CFStringRef const lbPreferencesDomainCase = CFSTR("com.patricktbp.lockback");

static void LBReloadPreferences(void) {
    CFPreferencesAppSynchronize(lbPreferencesDomainCase);

    CFPropertyListRef enabledValueCase = CFPreferencesCopyAppValue(CFSTR("Enabled"), lbPreferencesDomainCase);
    CFPropertyListRef notificationCenterMirroringValueCase = CFPreferencesCopyAppValue(CFSTR("NotificationCenterMirroring"), lbPreferencesDomainCase);
    CFPropertyListRef disableHomeButtonUnlockValueCase = CFPreferencesCopyAppValue(CFSTR("DisableHomeButtonUnlock"), lbPreferencesDomainCase);

    lbLockbackEnabledCase = enabledValueCase ? CFBooleanGetValue((CFBooleanRef)enabledValueCase) : YES;
    lbNotificationCenterMirroringEnabledCase = notificationCenterMirroringValueCase ? CFBooleanGetValue((CFBooleanRef)notificationCenterMirroringValueCase) : NO;
    lbDisableHomeButtonUnlockEnabledCase = disableHomeButtonUnlockValueCase ? CFBooleanGetValue((CFBooleanRef)disableHomeButtonUnlockValueCase) : YES;

    if (enabledValueCase) { CFRelease(enabledValueCase); }
    if (notificationCenterMirroringValueCase) { CFRelease(notificationCenterMirroringValueCase); }
    if (disableHomeButtonUnlockValueCase) { CFRelease(disableHomeButtonUnlockValueCase); }
}

static void LBPreferencesChanged(CFNotificationCenterRef __unused centerCase, void *__unused observerCase, CFStringRef __unused nameCase, const void *__unused objectCase, CFDictionaryRef __unused userInfoCase) {
    LBReloadPreferences();
}

BOOL LBLockbackEnabled(void) { return lbLockbackEnabledCase; }
BOOL LBNotificationCenterMirroringEnabled(void) { return lbNotificationCenterMirroringEnabledCase; }
BOOL LBDisableHomeButtonUnlockEnabled(void) { return lbDisableHomeButtonUnlockEnabledCase; }

%ctor {
    LBReloadPreferences();

    CFNotificationCenterAddObserver(
        CFNotificationCenterGetDarwinNotifyCenter(),
        NULL,
        LBPreferencesChanged,
        CFSTR("com.patricktbp.lockback/preferences.changed"),
        NULL,
        CFNotificationSuspensionBehaviorDeliverImmediately
    );

    LBInitializePasscodeScreen();    // Restores the iOS passcode screen
    LBInitializeElementHiding();     // Hides lock screen elements
    LBInitializeNotificationsView(); // Restores iOS notification list
    LBInitializeTimeDate();          // Restores iOS time and date
    LBInitializeDashboardPaging();   // Restores Slide to Unlock dashboard paging
    LBInitializeAuthentication();    // Restores Slide to Unlock authentication
    LBInitializeHomeButtonBlock();   // Blocks the home button from unlocking the device (If enabled)
    LBInitializeSlideToUnlock();     // Restores iOS Slide to Unlock
    LBInitializeGrabbers();          // Restores status bar, control center and camera grabbers
}
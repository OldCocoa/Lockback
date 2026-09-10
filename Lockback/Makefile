ARCHS = armv7 arm64

TARGET = iphone:clang:10.3:10.0 # iOS 10.3 SDK, iOS 10.0 build target
INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Lockback
Lockback_FILES = \
    Tweak.x \
    Passcode/PasscodeScreen.x \
    Passcode/PasscodeTransition.x \
    HideElements.x \
    TimeDate/TimeDateView.x \
    TimeDate/TimeDate.x \
    Notifications/NotificationsConversion.x \
    Notifications/NotificationsView.x \
    Authentication.x \
    HomeButtonBlock.x \
    DashboardPaging.x \
    SlideToUnlock/SlideToUnlockView.x \
    SlideToUnlock/SlideToUnlockAnimation.x \
    SlideToUnlock/SlideToUnlock.x \
    Grabbers/GrabberView.x \
    Grabbers/CameraGrabber.x \
    Grabbers.x
DEBUG.CFLAGS = -DDEBUG -O1
Lockback_CFLAGS = -fobjc-arc
Lockback_FRAMEWORKS = UIKit CoreGraphics QuartzCore

include $(THEOS_MAKE_PATH)/tweak.mk

SUBPROJECTS += Preferences
include $(THEOS_MAKE_PATH)/aggregate.mk
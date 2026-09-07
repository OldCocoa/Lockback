ARCHS = armv7 arm64
TARGET = iphone:clang:10.3:10.0
INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

DEBUG.CFLAGS = -DDEBUG -O1

TWEAK_NAME = Lockback
Lockback_FILES = \
    Tweak.x \
    HideElements.x \
    TimeDate.x \
    Notifications/NotificationsConversion.x \
    Notifications/NotificationsView.x \
    SlideToUnlock.x \
    Grabbers/GrabberView.x \
    Grabbers/CameraGrabber.x \
    Grabbers.x
Lockback_CFLAGS = -fobjc-arc
Lockback_FRAMEWORKS = UIKit CoreGraphics QuartzCore

include $(THEOS_MAKE_PATH)/tweak.mk

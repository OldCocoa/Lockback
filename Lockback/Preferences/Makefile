include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = LockbackPrefs
LockbackPrefs_FILES = LBRootListController.m
LockbackPrefs_CFLAGS = -fobjc-arc
LockbackPrefs_FRAMEWORKS = UIKit
LockbackPrefs_PRIVATE_FRAMEWORKS = Preferences
LockbackPrefs_RESOURCE_DIRS = Resources
LockbackPrefs_INSTALL_PATH = /Library/PreferenceBundles

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p "$(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences"$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist "$(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/Lockback.plist"$(ECHO_END)
TARGET := iphone:clang:latest:17.0
ifeq ($(THEOS_PACKAGE_SCHEME),roothide)
ARCHS := arm64e
else
ARCHS := arm64
endif
INSTALL_TARGET_PROCESSES = Facebook
THEOS_PACKAGE_SCHEME ?= rootless

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = ShopeeBlocker
ShopeeBlocker_FILES = Tweak.xm
ShopeeBlocker_FRAMEWORKS = Foundation UIKit QuartzCore
ShopeeBlocker_CFLAGS = -fobjc-arc -Wall -Wextra -Werror -Wno-deprecated-declarations

include $(THEOS_MAKE_PATH)/tweak.mk

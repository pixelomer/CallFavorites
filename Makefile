TARGET := iphone:clang:latest:13.0
INSTALL_TARGET_PROCESSES = SpringBoard
ARCHS = arm64 arm64e
export TARGET ARCHS

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = CallFavorites

CallFavorites_FILES = Tweak.x
CallFavorites_FRAMEWORKS = CoreTelephony
CallFavorites_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk

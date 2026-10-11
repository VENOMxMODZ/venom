#
#  Makefile for DefineAura iOS Dynamic Library (.dylib)
#  Hardened Anti-Tamper & Obfuscated Production Configuration
#

TARGET = DefineAura.dylib

# Force iPhoneOS SDK and Clang compiler
SYSROOT := $(shell xcrun --sdk iphoneos --show-sdk-path)
CC := $(shell xcrun --sdk iphoneos --find clang)
STRIP := $(shell xcrun --sdk iphoneos --find strip)

TARGET_FLAGS := -target arm64-apple-ios14.0 -isysroot $(SYSROOT)

# Aggressive optimization (-O3) for inlining security routines, hidden symbols, and dead code removal
CFLAGS := -fobjc-arc -O3 -Wall -Wextra -Wno-unused-parameter \
          -fvisibility=hidden -fvisibility-inlines-hidden \
          -I./include $(TARGET_FLAGS)

LDFLAGS := -dynamiclib -install_name @rpath/$(TARGET) \
           $(TARGET_FLAGS) \
           -Wl,-dead_strip \
           -framework UIKit \
           -framework Foundation \
           -framework Security \
           -framework CoreGraphics \
           -framework QuartzCore

SRCS := src/SecurityHardening.m \
        src/APIClient.m \
        src/SessionManager.m \
        src/ModuleInterface.m \
        src/LoginManager.m \
        src/LoginViewController.m \
        src/FloatingView.m \
        src/FloatingController.m \
        src/DylibEntry.m

OBJS := $(SRCS:.m=.o)

all: $(TARGET)

$(TARGET): $(OBJS)
	$(CC) $(LDFLAGS) -o $@ $^
	@if [ -n "$(STRIP)" ]; then \
		$(STRIP) -x $@ 2>/dev/null || true; \
		echo "===> Stripped non-global symbols from: $@"; \
	fi
	@echo "===> Hardened build completed successfully: $(TARGET)"

%.o: %.m
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -f $(OBJS) $(TARGET)
	@echo "===> Cleaned build artifacts."

.PHONY: all clean

#
#  Makefile for DefineAura iOS Dynamic Library (.dylib)
#

TARGET = DefineAura.dylib

# Compiler settings (macOS / Xcode Toolchain)
CC ?= xcrun -sdk iphoneos clang
ARCHS ?= -arch arm64
MIN_IOS ?= -miphoneos-version-min=14.0

CFLAGS = -fobjc-arc -O2 -Wall -Wextra -I./include $(ARCHS) $(MIN_IOS)
LDFLAGS = -dynamiclib -install_name @rpath/$(TARGET) \
          -framework UIKit \
          -framework Foundation \
          -framework Security \
          -framework CoreGraphics

SRCS = src/APIClient.m \
       src/SessionManager.m \
       src/ModuleInterface.m \
       src/LoginManager.m \
       src/LoginViewController.m \
       src/FloatingView.m \
       src/FloatingController.m \
       src/DylibEntry.m

OBJS = $(SRCS:.m=.o)

all: $(TARGET)

$(TARGET): $(OBJS)
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $^
	@echo "===> Build completed successfully: $(TARGET)"

%.o: %.m
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -f $(OBJS) $(TARGET)
	@echo "===> Cleaned build artifacts."

.PHONY: all clean

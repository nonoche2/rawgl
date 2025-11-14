# === UNIVERSAL MAKEFILE for rawgl.app ===
#
# This Makefile builds a distributable, universal macOS application bundle.
# It compiles both ARM64 (Apple Silicon) and x86_64 (Intel) binaries
# and bundles them, along with their dependencies, into a single .app.
#
# REQUIREMENTS:
# 1. Must be run on an ARM64 (Apple Silicon) Mac.
# 2. Homebrew must be installed in BOTH locations:
#    - /opt/homebrew (for ARM64)
#    - /usr/local (for x86_64, via Rosetta)
# 3. SDL2, SDL2_mixer, and libmt32emu must be installed via *both* Homebrew instances.
# 4. An `Info.plist` file must be present in this directory.
#
# USAGE:
#   make          - Builds the complete rawgl.app
#   make clean    - Removes all build artifacts
#
# === OS CHECK ===
UNAME_S := $(strip $(shell uname -s))
ifeq ($(UNAME_S),Darwin)

# === SHARED CONFIGURATION ===
SRCS = aifcplayer.cpp bitmap.cpp file.cpp engine.cpp graphics_gl.cpp graphics_soft.cpp \
       script.cpp mixer.cpp pak.cpp resource.cpp resource_nth.cpp \
       resource_win31.cpp resource_3do.cpp scaler.cpp screenshot.cpp \
       systemstub_sdl.cpp sfxplayer.cpp staticres.cpp unpack.cpp util.cpp video.cpp main.cpp \
       MacHelper.mm
       
DEFINES = -DBYPASS_PROTECTION -DUSE_GL

# Versioned dylibs to find, make universal, and bundle (match otool output)
DYLIBS_TO_BUNDLE = libSDL2-2.0.0.dylib libSDL2_mixer-2.0.0.dylib libmt32emu.2.dylib

# Exact "old" paths for patching (from otool -L on a non-patched build)
OLD_SDL2_ARM64 = /opt/homebrew/opt/sdl2/lib/libSDL2-2.0.0.dylib
OLD_MIXER_ARM64 = /opt/homebrew/opt/sdl2_mixer/lib/libSDL2_mixer-2.0.0.dylib
OLD_MT32_ARM64 = /opt/homebrew/opt/mt32emu/lib/libmt32emu.2.dylib

OLD_SDL2_X86_64 = /usr/local/opt/sdl2/lib/libSDL2-2.0.0.dylib
OLD_MIXER_X86_64 = /usr/local/opt/sdl2_mixer/lib/libSDL2_mixer-2.0.0.dylib
OLD_MT32_X86_64 = /usr/local/opt/mt32emu/lib/libmt32emu.2.dylib

# === APPLICATION BUNDLE PATHS ===
APP_NAME = rawgl.app
CONTENTS = $(APP_NAME)/Contents
RESOURCES = $(CONTENTS)/Resources
MACOS = $(CONTENTS)/MacOS
FRAMEWORKS = $(CONTENTS)/Frameworks

# Intermediate and final executable paths
EXEC_ARM64 = $(MACOS)/rawgl_arm64
EXEC_X86_64 = $(MACOS)/rawgl_x86_64
EXEC_UNIVERSAL = $(MACOS)/rawgl

# === ARM64 (NATIVE) BUILD CONFIG ===
CXX_ARM64 = g++
BREW_ARM64 = /opt/homebrew
SDL2_CONFIG_ARM64 = $(BREW_ARM64)/bin/sdl2-config
SDL_CFLAGS_ARM64 := $(shell $(SDL2_CONFIG_ARM64) --cflags)
SDL_LIBS_ARM64 := $(shell $(SDL2_CONFIG_ARM64) --libs)
CXXFLAGS_ARM64 = -g -O -MMD -Wall -Wpedantic $(SDL_CFLAGS_ARM64) $(DEFINES) -I$(BREW_ARM64)/include -Wno-deprecated-declarations
LDFLAGS_ARM64 = -L$(BREW_ARM64)/lib
LIBS_ARM64 = $(SDL_LIBS_ARM64) -lSDL2_mixer -framework OpenGL -framework Cocoa -lz -lmt32emu
OBJS_ARM64 = $(addsuffix _arm64.o, $(basename $(SRCS)))
DEPS_ARM64 = $(OBJS_ARM64:.o=.d)

# === X86_64 (ROSETTA) BUILD CONFIG ===
# We use `arch -x86_64` to force this part of the build to run under Rosetta
CXX_X86_64 = arch -x86_64 g++
BREW_X86_64 = /usr/local
SDL2_CONFIG_X86_64 = $(BREW_X86_64)/bin/sdl2-config
# We must also run sdl2-config under Rosetta to get the correct x86_64 paths
SDL_CFLAGS_X86_64 := $(shell arch -x86_64 $(SDL2_CONFIG_X86_64) --cflags)
SDL_LIBS_X86_64 := $(shell arch -x86_64 $(SDL2_CONFIG_X86_64) --libs)
CXXFLAGS_X86_64 = -g -O -MMD -Wall -Wpedantic $(SDL_CFLAGS_X86_64) $(DEFINES) -I$(BREW_X86_64)/include -Wno-deprecated-declarations
LDFLAGS_X86_64 = -L$(BREW_X86_64)/lib
LIBS_X86_64 = $(SDL_LIBS_X86_64) -lSDL2_mixer -framework OpenGL -framework Cocoa -lz -lmt32emu
OBJS_X86_64 = $(addsuffix _x86_64.o, $(basename $(SRCS)))
DEPS_X86_64 = $(OBJS_X86_64:.o=.d)


# === BUILD TARGETS ===

.PHONY: all rawgl clean
all: rawgl
rawgl: $(APP_NAME)

# --- STAGE 1: Compile Object Files ---

# Rule for ARM64 .o files
%_arm64.o: %.cpp
	@echo "Compiling [ARM64] $@"
	@$(CXX_ARM64) $(CXXFLAGS_ARM64) -c $< -o $@
%_arm64.o: %.mm
	@echo "Compiling [ARM64] $@"
	@$(CXX_ARM64) $(CXXFLAGS_ARM64) -ObjC++ -c $< -o $@

# Rule for x86_64 .o files (using Rosetta)
%_x86_64.o: %.cpp
	@echo "Compiling [x86_64] $@"
	@$(CXX_X86_64) $(CXXFLAGS_X86_64) -c $< -o $@
%_x86_64.o: %.mm
	@echo "Compiling [x86_64] $@"
	@$(CXX_X86_64) $(CXXFLAGS_X86_64) -ObjC++ -c $< -o $@

# --- STAGE 2: Link Architecture-Specific Executables ---
# After linking, we immediately patch the dylib paths to point *inside* the
# future app bundle. This is critical.

$(EXEC_ARM64): $(OBJS_ARM64)
	@mkdir -p $(MACOS)
	@echo "Linking [ARM64] executable..."
	@$(CXX_ARM64) $(LDFLAGS_ARM64) -o $@ $^ $(LIBS_ARM64)
	@echo "Patching [ARM64] executable dylib paths..."
	@install_name_tool -change $(OLD_SDL2_ARM64) @executable_path/../Frameworks/libSDL2-2.0.0.dylib $@
	@install_name_tool -change $(OLD_MIXER_ARM64) @executable_path/../Frameworks/libSDL2_mixer-2.0.0.dylib $@
	@install_name_tool -change $(OLD_MT32_ARM64) @executable_path/../Frameworks/libmt32emu.2.dylib $@

$(EXEC_X86_64): $(OBJS_X86_64)
	@mkdir -p $(MACOS)
	@echo "Linking [x86_64] executable (under Rosetta)..."
	@$(CXX_X86_64) $(LDFLAGS_X86_64) -o $@ $^ $(LIBS_X86_64)
	@echo "Patching [x86_64] executable dylib paths..."
	@install_name_tool -change $(OLD_SDL2_X86_64) @executable_path/../Frameworks/libSDL2-2.0.0.dylib $@
	@install_name_tool -change $(OLD_MIXER_X86_64) @executable_path/../Frameworks/libSDL2_mixer-2.0.0.dylib $@
	@install_name_tool -change $(OLD_MT32_X86_64) @executable_path/../Frameworks/libmt32emu.2.dylib $@

# --- STAGE 3: Create Universal Executable ---
# Combine the two binaries and remove the intermediate files

$(EXEC_UNIVERSAL): $(EXEC_ARM64) $(EXEC_X86_64)
	@echo "Creating universal executable with lipo..."
	@lipo -create -output $@ $^
	@echo "Cleaning up intermediate binaries..."
	@rm -f $(EXEC_ARM64) $(EXEC_X86_64)

# --- STAGE 4: Build Application Bundle ---
# This is the final step. It creates the .app structure,
# copies the universal executable and Info.plist, and
# creates the universal dylibs.

$(APP_NAME): $(EXEC_UNIVERSAL) Info.plist
	@echo "Creating macOS app bundle structure..."
	@mkdir -p $(RESOURCES)
	@mkdir -p $(FRAMEWORKS)
	@cp Info.plist $(CONTENTS)/

	@echo "Creating and bundling universal dylibs..."
	@for lib in $(DYLIBS_TO_BUNDLE); do \
		echo "  -> Processing $$lib"; \
		if [ "$$lib" = "libSDL2-2.0.0.dylib" ]; then \
			arm_path=$(OLD_SDL2_ARM64); \
			x86_path=$(OLD_SDL2_X86_64); \
		elif [ "$$lib" = "libSDL2_mixer-2.0.0.dylib" ]; then \
			arm_path=$(OLD_MIXER_ARM64); \
			x86_path=$(OLD_MIXER_X86_64); \
		elif [ "$$lib" = "libmt32emu.2.dylib" ]; then \
			arm_path=$(OLD_MT32_ARM64); \
			x86_path=$(OLD_MT32_X86_64); \
		fi; \
		lipo -create -output $(FRAMEWORKS)/$$lib $$arm_path $$x86_path; \
		install_name_tool -id @executable_path/../Frameworks/$$lib $(FRAMEWORKS)/$$lib; \
	done

	@echo "Fixing dylib cross-dependencies..."
	@# libSDL2_mixer-2.0.0.dylib depends on libSDL2-2.0.0.dylib. We must update its internal
	@# path to point to the *bundled* libSDL2-2.0.0.dylib.
	@# `install_name_tool` will patch both arch slices in the universal dylib.
	@install_name_tool -change $(OLD_SDL2_ARM64) @executable_path/../Frameworks/libSDL2-2.0.0.dylib $(FRAMEWORKS)/libSDL2_mixer-2.0.0.dylib
	@install_name_tool -change $(OLD_SDL2_X86_64) @executable_path/../Frameworks/libSDL2-2.0.0.dylib $(FRAMEWORKS)/libSDL2_mixer-2.0.0.dylib

	@echo "---"
	@echo "UNIVERSAL APP READY: $(APP_NAME)"
	@echo "---"

# --- CLEANUP ---

clean:
	@echo "Cleaning up build artifacts..."
	@rm -f *_arm64.o *_x86_64.o
	@rm -f $(DEPS_ARM64) $(DEPS_X86_64)
	@rm -f $(EXEC_ARM64) $(EXEC_X86_64) $(EXEC_UNIVERSAL)
	@rm -rf $(APP_NAME)

# --- Handle non-macOS ---
else
    $(error This Makefile is for macOS only)
endif

# --- Include auto-generated dependencies ---
-include $(DEPS_ARM64)
-include $(DEPS_X86_64)

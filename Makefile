# Detect the operating system
UNAME_S := $(shell uname -s)

# Base definitions (common to all OSes)
DEFINES = -DBYPASS_PROTECTION -DUSE_GL
SRCS = aifcplayer.cpp bitmap.cpp file.cpp engine.cpp graphics_gl.cpp graphics_soft.cpp \
    script.cpp mixer.cpp pak.cpp resource.cpp resource_nth.cpp \
    resource_win31.cpp resource_3do.cpp scaler.cpp screenshot.cpp systemstub_sdl.cpp sfxplayer.cpp \
    staticres.cpp unpack.cpp util.cpp video.cpp main.cpp
OBJS = $(SRCS:.cpp=.o)
DEPS = $(SRCS:.cpp=.d)

# --- OS-specific configuration ---

ifeq ($(UNAME_S),Darwin)
    # --- macOS Configuration ---
    # This assumes you have installed Homebrew, and SDL and MT32 dependencies with it like this:
    # brew install sdl2 sdl2_mixer mt32emu
    # Use brew --prefix for robust path finding on Intel and Apple Silicon Macs
    SDL2_PREFIX = $(shell brew --prefix sdl2)
    MT32EMU_PREFIX = $(shell brew --prefix mt32emu)

    # Compiler flags: find SDL2 and mt32emu headers
    SDL_CFLAGS = $(shell $(SDL2_PREFIX)/bin/sdl2-config --cflags)
    CXXFLAGS := -g -O -MMD -Wall -Wpedantic $(SDL_CFLAGS) $(DEFINES) -I$(MT32EMU_PREFIX)/include

    # Linker flags: find SDL2 and mt32emu libraries, and use the OpenGL framework
    SDL_LIBS = $(shell $(SDL2_PREFIX)/bin/sdl2-config --libs) -lSDL2_mixer -framework OpenGL
    LDFLAGS := -L$(MT32EMU_PREFIX)/lib

else
    # --- Linux/Other Configuration ---
    # Assume sdl2-config is in the system PATH
    SDL_CFLAGS = `sdl2-config --cflags`
    CXXFLAGS := -g -O -MMD -Wall -Wpedantic $(SDL_CFLAGS) $(DEFINES)

    # Linker flags: use standard Linux libraries
    SDL_LIBS = `sdl2-config --libs` -lSDL2_mixer -lGL
    LDFLAGS :=
endif

# --- Build rules (no changes needed here) ---

rawgl: $(OBJS)
    $(CXX) $(LDFLAGS) -o $@ $(OBJS) $(SDL_LIBS) -lz -lmt32emu

clean:
    rm -f $(OBJS) $(DEPS)

-include $(DEPS)

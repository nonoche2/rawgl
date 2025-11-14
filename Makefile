# Detect the operating system
UNAME_S := $(shell uname -s)

# --- Common settings for all platforms ---
SDL_CFLAGS = `sdl2-config --cflags`
DEFINES = -DBYPASS_PROTECTION -DUSE_GL

# Base compiler flags, will be extended by platform-specific flags
CXXFLAGS_BASE := -g -O -MMD -Wall -Wpedantic $(SDL_CFLAGS) $(DEFINES)

SRCS = aifcplayer.cpp bitmap.cpp file.cpp engine.cpp graphics_gl.cpp graphics_soft.cpp \
    script.cpp mixer.cpp pak.cpp resource.cpp resource_nth.cpp \
    resource_win31.cpp resource_3do.cpp scaler.cpp screenshot.cpp systemstub_sdl.cpp sfxplayer.cpp \
    staticres.cpp unpack.cpp util.cpp video.cpp main.cpp

OBJS = $(SRCS:.cpp=.o)
DEPS = $(SRCS:.cpp=.d)

# --- Platform-specific settings ---
ifeq ($(UNAME_S),Darwin)
    # --- macOS specific settings ---
    # Use -framework for system libraries like OpenGL
    SDL_LIBS = `sdl2-config --libs` -lSDL2_mixer -framework OpenGL
    
    # Find mt32emu installed via Homebrew
    MT32EMU_PREFIX = $(shell brew --prefix mt32emu)
    CXXFLAGS := $(CXXFLAGS_BASE) -I$(MT32EMU_PREFIX)/include
    LDFLAGS := -L$(MT32EMU_PREFIX)/lib
else
    # --- Linux / other OS settings ---
    # Use -l for standard libraries
    SDL_LIBS = `sdl2-config --libs` -lSDL2_mixer -lGL
    
    # Assume mt32emu is in a standard path
    CXXFLAGS := $(CXXFLAGS_BASE)
    LDFLAGS :=
endif


# --- Build targets ---

rawgl: $(OBJS)
    $(CXX) $(LDFLAGS) -o $@ $(OBJS) $(SDL_LIBS) -lz -lmt32emu

clean:
    rm -f $(OBJS) $(DEPS)

-include $(DEPS)

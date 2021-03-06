# Taken from https://spin.atomicobject.com/2016/08/26/makefile-c-projects/

BUILD_DIR ?= build
SRC_DIRS ?= $(shell find src -type d -not -path src) vendor/glad vendor/nanovg vendor/nanogui

UNAME := $(shell uname)
SRCS := $(shell find $(SRC_DIRS) -maxdepth 1 -name '*.cpp' -or -name '*.c')

INCFLAGS := $(addprefix -I, $(SRC_DIRS)) -Ivendor
CPPFLAGS ?= $(INCFLAGS) -MMD -MP -g -Wno-multichar -DNANOGUI_GLAD
CXXFLAGS ?= -std=c++1y

ifeq ($(UNAME), Darwin)
	SRCS += $(shell find $(SRC_DIRS) -maxdepth 1 -name '*.mm')
	LDFLAGS ?= -lstdc++ -lm -framework SDL2 -framework SDL2_net -framework OpenGL -framework AppKit
	POST_PROCESS ?= dsymutil
else ifeq ($(UNAME), MINGW64_NT-10.0)
	# Not a great conditional check for "Windows", but works for now.
	LDFLAGS ?= -lstdc++ -lm -lmingw32 -lSDL2main -lSDL2 -lSDL2_net -lglu32 -lopengl32 -lws2_32 -lcomdlg32
	POST_PROCESS ?= ls -lh
else
	LDFLAGS ?= -lstdc++ -lm -lSDL2 -lSDL2_net -lGL -lGLU -lpthread -ldl
	POST_PROCESS ?= ls -lh
endif

OBJS := $(SRCS:%=$(BUILD_DIR)/%.o)
DEPS := $(OBJS:.o=.d)


avara: $(BUILD_DIR)/Avara resources

bspviewer: $(BUILD_DIR)/BSPViewer resources

macapp: avara
	$(MKDIR_P) $(BUILD_DIR)/Avara.app/Contents/{Frameworks,MacOS,Resources}
	cp platform/macos/Info.plist $(BUILD_DIR)/Avara.app/Contents
	cp $(BUILD_DIR)/Avara $(BUILD_DIR)/Avara.app/Contents/MacOS
	cp -r $(BUILD_DIR)/{bsps,levels,rsrc,shaders} $(BUILD_DIR)/Avara.app/Contents/Resources
	cp -a /Library/Frameworks/SDL2.framework $(BUILD_DIR)/Avara.app/Contents/Frameworks
	cp -a /Library/Frameworks/SDL2_net.framework $(BUILD_DIR)/Avara.app/Contents/Frameworks
	install_name_tool -change @rpath/SDL2.framework/Versions/A/SDL2 @executable_path/../Frameworks/SDL2.framework/Versions/A/SDL2 $(BUILD_DIR)/Avara.app/Contents/MacOS/Avara
	install_name_tool -change @rpath/SDL2_net.framework/Versions/A/SDL2_net @executable_path/../Frameworks/SDL2_net.framework/Versions/A/SDL2_net $(BUILD_DIR)/Avara.app/Contents/MacOS/Avara

winapp: avara
	$(MKDIR_P) $(BUILD_DIR)/Avara
	cp -r $(BUILD_DIR)/{Avara.exe,bsps,levels,rsrc,shaders} $(BUILD_DIR)/Avara
	cp platform/windows/*.dll $(BUILD_DIR)/Avara
	cd $(BUILD_DIR) && zip -r Avara.zip Avara && cd ..

# Avara
$(BUILD_DIR)/Avara: $(OBJS) $(BUILD_DIR)/src/Avara.cpp.o
	$(CC) $(OBJS) $(BUILD_DIR)/src/Avara.cpp.o -o $@ $(LDFLAGS)
	$(POST_PROCESS) $@

# BSPViewer
$(BUILD_DIR)/BSPViewer: $(OBJS) $(BUILD_DIR)/src/BSPViewer.cpp.o
	$(CC) $(OBJS) $(BUILD_DIR)/src/BSPViewer.cpp.o -o $@ $(LDFLAGS)
	$(POST_PROCESS) $@

# c source
$(BUILD_DIR)/%.c.o: %.c
	$(MKDIR_P) $(dir $@)
	$(CC) $(CPPFLAGS) $(CFLAGS) -c $< -o $@

# c++ source
$(BUILD_DIR)/%.cpp.o: %.cpp
	$(MKDIR_P) $(dir $@)
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -c $< -o $@

# obj-c++ source
$(BUILD_DIR)/%.mm.o: %.mm
	$(MKDIR_P) $(dir $@)
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -c $< -o $@

.PHONY: clean

clean:
	$(RM) -r $(BUILD_DIR)

resources:
	cp -r bsps levels rsrc shaders $(BUILD_DIR)

-include $(DEPS)

MKDIR_P ?= mkdir -p

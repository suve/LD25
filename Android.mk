LOCAL_PATH := $(call my-dir)
include $(CLEAR_VARS)

$(call import-module,SDL2)
$(call import-module,SDL2_mixer)
$(call import-module,SDL2_image)

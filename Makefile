KVER        := $(shell uname -r)
KBASE       := /lib/modules/$(KVER)
KSRC        := $(KBASE)/source
KBUILD      := $(KBASE)/build
MOD_DIR     := $(KBASE)/kernel
PWD         := $(shell pwd)

I9_MODULES  := i915.o drm.o drm_kms_helper.o intel_ips.o drm_mipi_dsi.o

CPATH       := $(KBUILD_EXTMOD)/drivers/gpu/drm/i915

INC_INCPATH := $(KBUILD_EXTMOD)/include
DRMD        := drivers/gpu/drm/

I915_ITEMS  := i915_drv \
               i915_params \
               i915_suspend \
               i915_sysfs \
               intel_pm \
               i915_cmd_parser \
               i915_gem_context \
               i915_gem_render_state \
               i915_gem_debug \
               i915_gem_dmabuf \
               i915_gem_evict \
               i915_gem_execbuffer \
               i915_gem_gtt \
               i915_gem \
               i915_gem_stolen \
               i915_gem_tiling \
               i915_gem_userptr \
               i915_gpu_error \
               i915_irq \
               i915_trace_points \
               intel_ringbuffer \
               intel_uncore \
               intel_renderstate_gen6 \
               intel_renderstate_gen7 \
               intel_renderstate_gen8 \
               intel_bios \
               intel_display \
               intel_modes \
               intel_overlay \
               intel_sideband \
               intel_sprite \
               dvo_ch7017 \
               dvo_ch7xxx \
               dvo_ivch \
               dvo_ns2501 \
               dvo_sil164 \
               dvo_tfp410 \
               intel_crt \
               intel_ddi \
               intel_dp \
               intel_dsi_cmd \
               intel_dsi \
               intel_dsi_pll \
               intel_dsi_panel_vbt \
               intel_dvo \
               intel_hdmi \
               intel_i2c \
               intel_lvds \
               intel_panel \
               intel_sdvo \
               intel_tv \
               i915_dma \
               i915_ums

DRM_ITEMS   := drm_auth drm_buffer drm_bufs drm_cache \
               drm_context drm_dma \
               drm_drv drm_fops drm_gem drm_ioctl drm_irq \
               drm_lock drm_memory drm_stub drm_vm \
               drm_agpsupport drm_scatter drm_pci \
               drm_platform drm_sysfs drm_hashtab drm_mm \
               drm_crtc drm_modes drm_edid \
               drm_info drm_debugfs drm_encoder_slave \
               drm_trace_points drm_global drm_prime \
               drm_rect drm_vma_manager drm_flip_work \
               drm_modeset_lock

# this prioritises the DKMS package include directories over the kernel headers
# allowing us to override header files where the 3.12.x versions have extra
# structs and declarations and so forth that we need for the backport to build

export CPATH

.PHONY: default clean modules load unload install patch

# make sure our dkms includes override local ones:
LINUXINCLUDE := -I$(INC_INCPATH) -I$(INC_INCPATH)/drm -I$(INC_INCPATH)/uapi $(LINUXINCLUDE)
ccflags-y    := -Iinclude/drm

# construct the object file lists to match the in-tree Makefiles:
drm_kms_helper-y := \
    $(patsubst %,$(DRMD)%.o,drm_crtc_helper drm_dp_helper drm_probe_helper drm_plane_helper)
drm_kms_helper-$(CONFIG_DRM_LOAD_EDID_FIRMWARE) += \
    $(patsubst %,$(DRMD)%.o,drm_edid_load)
drm_kms_helper-$(CONFIG_DRM_KMS_FB_HELPER)     += \
    $(patsubst %,$(DRMD)%.o,drm_fb_helper)
drm_kms_helper-$(CONFIG_DRM_KMS_CMA_HELPER)     += \
    $(patsubst %,$(DRMD)%.o,drm_fb_cma_helper)

drm-y       := $(patsubst %,$(DRMD)%.o,      $(DRM_ITEMS))
i915-y      := $(patsubst %,$(DRMD)i915/%.o, $(I915_ITEMS))
intel_ips-y := $(patsubst %,drivers/platform/x86/%.o,intel_ips)
drm_mipi_dsi-y := $(patsubst %,drivers/gpu/drm/%.o,drm_mipi_dsi)

i915-$(CONFIG_COMPAT)            += $(patsubst %,$(DRMD)i915/%.o,i915_ioc32)
i915-$(CONFIG_DEBUG_FS)          += $(patsubst %,$(DRMD)i915/%.o,i915_debugfs)
i915-$(CONFIG_ACPI)              += $(patsubst %,$(DRMD)i915/%.o,intel_acpi intel_opregion)
i915-$(CONFIG_DRM_I915_FBDEV)    += $(patsubst %,$(DRMD)i915/%.o,intel_fbdev)

drm-usb-y                        := $(patsubst %,$(DRMD)%.o,drm_usb)
drm-$(CONFIG_COMPAT)             += $(patsubst %,$(DRMD)%.o,drm_ioc32)
drm-$(CONFIG_DRM_GEM_CMA_HELPER) += $(patsubst %,$(DRMD)%.o,drm_gem_cma_helper)
drm-$(CONFIG_PCI)                += $(patsubst %,$(DRMD)%.o,ati_pcigart)
drm-$(CONFIG_DRM_PANEL)          += $(patsubst %,$(DRMD)%.o,drm_panel)

obj-$(CONFIG_DRM_I915)           += i915.o
obj-$(CONFIG_INTEL_IPS)          += intel_ips.o
obj-$(CONFIG_DRM)                += drm.o
obj-$(CONFIG_DRM_KMS_HELPER)     += drm_kms_helper.o
obj-$(CONFIG_DRM_MIPI_DSI)       += drm_mipi_dsi.o

obj-m := $(I9_MODULES)

CFLAGS_i915_trace_points.o := -I$(CPATH)
CFLAGS_drm_trace_points.o  := -I$(KBUILD_EXTMOD)/drivers/gpu/drm

modules: $(KBUILD) $(patsubst %.o,%.c,$(I9_MODULES))
	$(MAKE) -C $(KBUILD) M=$(PWD) O=$(KBUILD) modules

clean:
	rm -rf *.o *.ko *.cmd .*.cmd .tmp_versions

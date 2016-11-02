KVER        := $(shell uname -r)
KBASE       := /lib/modules/$(KVER)
KSRC        := $(KBASE)/source
KBUILD      := $(KBASE)/build
MOD_DIR     := $(KBASE)/kernel
PWD         := $(shell pwd)

INC_INCPATH := $(KBUILD_EXTMOD)/include
DRMD        := drivers/gpu/drm/

# keep sorted like they are to allow easier comparison to drm/Makefile
DRM_ITEMS   := drm_auth drm_bufs drm_cache \
               drm_context drm_dma \
               drm_fops drm_gem drm_ioctl drm_irq \
               drm_lock drm_memory drm_drv drm_vm \
               drm_scatter drm_pci \
               drm_platform drm_sysfs drm_hashtab drm_mm \
               drm_crtc drm_fourcc drm_modes drm_edid \
               drm_info drm_debugfs drm_encoder_slave \
               drm_trace_points drm_global drm_prime \
               drm_rect drm_vma_manager drm_flip_work \
               drm_modeset_lock drm_atomic drm_bridge


DRM_KMS_HELPER_ITEMS := drm_crtc_helper drm_dp_helper drm_probe_helper \
                drm_plane_helper drm_dp_mst_topology drm_atomic_helper \
                drm_kms_helper_common drm_dp_dual_mode_helper \
                drm_simple_kms_helper drm_blend

.PHONY: default clean modules load unload install patch

# make sure our dkms includes override local ones:
LINUXINCLUDE := -I$(INC_INCPATH) -I$(INC_INCPATH)/drm -I$(INC_INCPATH)/uapi $(LINUXINCLUDE)
LINUXINCLUDE += -I$(KBUILD_EXTMOD)/drivers/gpu/drm/amd/include
ccflags-y    := -Iinclude/drm

# construct the object file lists to match the in-tree Makefiles:
drm_kms_helper-y := \
    $(patsubst %,$(DRMD)%.o, $(DRM_KMS_HELPER_ITEMS))
drm_kms_helper-$(CONFIG_DRM_LOAD_EDID_FIRMWARE) += \
    $(patsubst %,$(DRMD)%.o,drm_edid_load)
drm_kms_helper-$(CONFIG_DRM_KMS_FB_HELPER)      += \
    $(patsubst %,$(DRMD)%.o,drm_fb_helper)
drm_kms_helper-$(CONFIG_DRM_KMS_CMA_HELPER)     += \
    $(patsubst %,$(DRMD)%.o,drm_fb_cma_helper)
drm_kms_helper-y                                += \
    $(patsubst %,$(DRMD)%.o,drm_dp_aux_dev)

drm-y       := $(patsubst %,$(DRMD)%.o,      $(DRM_ITEMS))
intel_ips-y := $(patsubst %,drivers/platform/x86/%.o,intel_ips)

drm-$(CONFIG_COMPAT)             += $(patsubst %,$(DRMD)%.o,drm_ioc32)
drm-$(CONFIG_DRM_GEM_CMA_HELPER) += $(patsubst %,$(DRMD)%.o,drm_gem_cma_helper)
drm-$(CONFIG_PCI)                += $(patsubst %,$(DRMD)%.o,ati_pcigart)
drm-y                            += $(patsubst %,$(DRMD)%.o,drm_panel)
drm-$(CONFIG_OF)                 += $(patsubst %,$(DRMD)%.o,drm_of)
drm-$(CONFIG_AGP)                += $(patsubst %,$(DRMD)%.o,drm_agpsupport)

obj-$(CONFIG_INTEL_IPS)          += intel_ips.o
obj-$(CONFIG_DRM)                += drm.o
obj-$(CONFIG_DRM_KMS_HELPER)     += drm_kms_helper.o

BUILD_MODULES  := drm.o drm_kms_helper.o intel_ips.o

obj-m := $(BUILD_MODULES)
obj-m += drivers/gpu/drm/i915/
obj-m += drivers/gpu/drm/radeon/

CFLAGS_drm_trace_points.o  := -I$(KBUILD_EXTMOD)/drivers/gpu/drm

modules: $(KBUILD) $(patsubst %.o,%.c,$(BUILD_MODULES))
	$(MAKE) -C $(KBUILD) M=$(PWD) O=$(KBUILD) modules

clean:
	rm -rf *.o *.ko *.cmd .*.cmd .tmp_versions

KVER        := $(shell uname -r)
KBASE       := /lib/modules/$(KVER)
KSRC        := $(KBASE)/source
KBUILD      := $(KBASE)/build
MOD_DIR     := $(KBASE)/kernel
PWD         := $(shell pwd)

INC_INCPATH := $(KBUILD_EXTMOD)/include
DRMD        := drivers/gpu/drm/

.PHONY: default clean modules load unload install patch

# make sure our dkms includes override local ones:
LINUXINCLUDE := -I$(INC_INCPATH) -I$(INC_INCPATH)/drm -I$(INC_INCPATH)/uapi $(LINUXINCLUDE)
LINUXINCLUDE += -I$(KBUILD_EXTMOD)/drivers/gpu/drm/amd/include
ccflags-y    := -Iinclude/drm

intel_ips-y := $(patsubst %,drivers/platform/x86/%.o,intel_ips)

obj-$(CONFIG_INTEL_IPS)          += intel_ips.o

BUILD_MODULES  := intel_ips.o

obj-m := $(BUILD_MODULES)
obj-m += drivers/gpu/drm/

modules: $(KBUILD) $(patsubst %.o,%.c,$(BUILD_MODULES))
	$(MAKE) -C $(KBUILD) M=$(PWD) O=$(KBUILD) modules

clean:
	rm -rf *.o *.ko *.cmd .*.cmd .tmp_versions

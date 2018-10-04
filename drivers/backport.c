#include <linux/pci.h>
#include <linux/acpi.h>
#include <linux/delay.h>
#include <linux/pci_ids.h>
#include <linux/bcma/bcma.h>
#include <linux/bcma/bcma_regs.h>
#include <linux/platform_data/x86/apple.h>
#include <drm/i915_drm.h>
#include <asm/pci-direct.h>
#include <asm/dma.h>
#include <asm/io_apic.h>
#include <asm/apic.h>
#include <asm/hpet.h>
#include <asm/iommu.h>
#include <asm/gart.h>
#include <asm/irq_remapping.h>
#include <asm/early_ioremap.h>

struct intel_early_ops {
        resource_size_t (*stolen_size)(int num, int slot, int func);
        resource_size_t (*stolen_base)(int num, int slot, int func,
                                       resource_size_t size);
};

struct resource intel_graphics_stolen_res __ro_after_init = DEFINE_RES_MEM(0, 0);
EXPORT_SYMBOL(intel_graphics_stolen_res);

static void __init
intel_graphics_stolen(int num, int slot, int func,
                      const struct intel_early_ops *early_ops)
{
        resource_size_t base, size;
        resource_size_t end;

        size = early_ops->stolen_size(num, slot, func);
        base = early_ops->stolen_base(num, slot, func, size);

        if (!size || !base)
                return;

        end = base + size - 1;

        intel_graphics_stolen_res.start = base;
        intel_graphics_stolen_res.end = end;

        printk(KERN_INFO "Reserving Intel graphics memory at %pR\n",
               &intel_graphics_stolen_res);

        /* Mark this space as reserved */
        e820__range_add(base, size, E820_TYPE_RESERVED);
        e820__update_table(e820_table);
}

MODULE_DESCRIPTION("dkms backport module");
MODULE_LICENSE("GPL");


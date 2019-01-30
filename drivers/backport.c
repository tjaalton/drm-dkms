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

#include <linux/reservation.h>

int bpo_reservation_object_get_fences_rcu(struct reservation_object *obj,
                                      struct dma_fence **pfence_excl,
                                      unsigned *pshared_count,
                                      struct dma_fence ***pshared)
{
        struct dma_fence **shared = NULL;
        struct dma_fence *fence_excl;
        unsigned int shared_count;
        int ret = 1;

        do {
                struct reservation_object_list *fobj;
                unsigned int i, seq;
                size_t sz = 0;

                shared_count = i = 0;

                rcu_read_lock();
                seq = read_seqcount_begin(&obj->seq);

                fence_excl = rcu_dereference(obj->fence_excl);
                if (fence_excl && !dma_fence_get_rcu(fence_excl))
                        goto unlock;

                fobj = rcu_dereference(obj->fence);
                if (fobj)
                        sz += sizeof(*shared) * fobj->shared_max;

                if (!pfence_excl && fence_excl)
                        sz += sizeof(*shared);

                if (sz) {
                        struct dma_fence **nshared;

                        nshared = krealloc(shared, sz,
                                           GFP_NOWAIT | __GFP_NOWARN);
                        if (!nshared) {
                                rcu_read_unlock();
                                nshared = krealloc(shared, sz, GFP_KERNEL);
                                if (nshared) {
                                        shared = nshared;
                                        continue;
                                }

                                ret = -ENOMEM;
                                break;
                        }
                        shared = nshared;
                        shared_count = fobj ? fobj->shared_count : 0;
                        for (i = 0; i < shared_count; ++i) {
                                shared[i] = rcu_dereference(fobj->shared[i]);
                                if (!dma_fence_get_rcu(shared[i]))
                                        break;
                        }

                        if (!pfence_excl && fence_excl) {
                                shared[i] = fence_excl;
                                fence_excl = NULL;
                                ++i;
                                ++shared_count;
                        }
                }

                if (i != shared_count || read_seqcount_retry(&obj->seq, seq)) {
                        while (i--)
                                dma_fence_put(shared[i]);
                        dma_fence_put(fence_excl);
                        goto unlock;
                }

                ret = 0;
unlock:
                rcu_read_unlock();
        } while (ret);

        if (!shared_count) {
                kfree(shared);
                shared = NULL;
        }

        *pshared_count = shared_count;
        *pshared = shared;
        if (pfence_excl)
                *pfence_excl = fence_excl;

        return ret;
}
EXPORT_SYMBOL_GPL(bpo_reservation_object_get_fences_rcu);



MODULE_DESCRIPTION("dkms backport module");
MODULE_LICENSE("GPL");


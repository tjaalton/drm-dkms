 /* clflushopt falls back to clflush
  * if clflushopt is not available */
 #define clflushopt clflush

/* from asm-generic/barrier.h */
#ifndef smp_mb__before_atomic
#define smp_mb__before_atomic()        smp_mb()
#endif

#ifndef smp_mb__after_atomic
#define smp_mb__after_atomic() smp_mb()
#endif


/* from include/acpi/acpi_io.h */
/* We apparently don't want to include linux/acpi_io.h directly as that
 * can cause build problems in our kernel */
#include <linux/acpi.h>
#include <linux/io.h>

static inline void __iomem *acpi_os_ioremap(acpi_physical_address phys,
                                           acpi_size size)
{
       return ioremap_cache(phys, size);
}

#define cpu_relax_lowlatency() cpu_relax()

#define DIV_ROUND_CLOSEST_ULL(ll, d)	\
({ unsigned long long _tmp = (ll)+(d)/2; do_div(_tmp, d); _tmp; })

#include <linux/moduleparam.h>
#define module_param_unsafe(name, type, perm)                  \
	module_param_named_unsafe(name, name, type, perm)
#define module_param_named_unsafe(name, value, type, perm)             \
	param_check_##type(name, &(value));                            \
	module_param_cb_unsafe(name, &param_ops_##type, &value, perm); \
	__MODULE_PARM_TYPE(name, #type)
#define module_param_cb_unsafe(name, ops, arg, perm)                      \
	__module_param_call(MODULE_PARAM_PREFIX, name, ops, arg, perm, -1)

#undef dma_buf_export
#define dma_buf_export(priv, ops, size, flags, resv)   \
       dma_buf_export_named(priv, ops, size, flags, KBUILD_MODNAME)

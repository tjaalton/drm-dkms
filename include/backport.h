
static inline int
reservation_object_lock_interruptible(struct reservation_object *obj,
                                      struct ww_acquire_ctx *ctx)
{
        return ww_mutex_lock_interruptible(&obj->lock, ctx);
}

int bpo_reservation_object_get_fences_rcu(struct reservation_object *obj,
                                      struct dma_fence **pfence_excl,
                                      unsigned *pshared_count,
                                      struct dma_fence ***pshared);



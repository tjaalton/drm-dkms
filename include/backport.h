static inline gfp_t mapping_gfp_constraint(struct address_space *mapping,
		gfp_t gfp_mask)
{
	return mapping_gfp_mask(mapping) & gfp_mask;
}

#define __GFP_RECLAIM  __GFP_WAIT

static inline s64 ktime_ms_delta(const ktime_t later, const ktime_t earlier)
{
	return ktime_to_ms(ktime_sub(later, earlier));
}

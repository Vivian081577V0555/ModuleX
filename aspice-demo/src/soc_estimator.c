// GP-05 / SWU-SOC-001: clamp an AFE-derived SOC estimate to 0..100 percent.
float soc_estimate_percent(float accumulated_mah, float capacity_mah)
{
    if (capacity_mah <= 0.0F) return 0.0F;

    float estimate = (accumulated_mah / capacity_mah) * 100.0F;
    if (estimate < 0.0F) return 0.0F;
    if (estimate > 100.0F) return 100.0F;
    return estimate;
}


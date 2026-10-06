#include <stdint.h>

// GP-01 / SWU-LED-001: map relative state of charge to four LED segments.
uint8_t rsoc_led_segments(uint8_t rsoc_percent)
{
    if (rsoc_percent >= 75U) return 4U;
    if (rsoc_percent >= 50U) return 3U;
    if (rsoc_percent >= 25U) return 2U;
    return 1U;
}


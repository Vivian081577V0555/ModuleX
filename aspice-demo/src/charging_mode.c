#include <stdbool.h>

// GP-03 / SWU-CHG-001: enter charging mode at the configured current threshold.
bool charging_mode_active(float charge_current_ma)
{
    return charge_current_ma >= 25.0F;
}


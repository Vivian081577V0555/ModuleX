#include <stdbool.h>

// GP-02 / SWU-OVP-001: apply hysteresis to the charging over-voltage guard.
bool ovp_charge_allowed(float cell_voltage, bool alarm_active)
{
    const float trip_voltage = 4.25F;
    const float release_voltage = 4.05F;
    return alarm_active ? (cell_voltage <= release_voltage)
                        : (cell_voltage < trip_voltage);
}


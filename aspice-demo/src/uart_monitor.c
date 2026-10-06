#include <stdbool.h>
#include <stdint.h>

// GP-04 / SWU-UART-001: report a timeout after the supervision window expires.
bool uart_link_timed_out(uint32_t elapsed_ms, uint32_t timeout_ms)
{
    return elapsed_ms > timeout_ms;
}


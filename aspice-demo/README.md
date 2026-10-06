# ASPICE Golden Path Source Artifacts

These small C modules are traceable source artifacts for the five ModuleX
ASPICE demo paths. They are intentionally implementation-focused rather than
production firmware. Redmine SW Unit issues link to the exact Git commit and
file path used by verification evidence.

| Golden path | Source artifact |
| --- | --- |
| GP-01 RSOC LED indication | `src/rsoc_led.c` |
| GP-02 over-voltage protection | `src/ovp_monitor.c` |
| GP-03 charging mode threshold | `src/charging_mode.c` |
| GP-04 UART communication supervision | `src/uart_monitor.c` |
| GP-05 AFE/SOC estimation | `src/soc_estimator.c` |


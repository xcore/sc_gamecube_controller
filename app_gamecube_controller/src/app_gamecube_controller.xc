#include <xs1.h>
#include <stdio.h>
#include <xscope.h>
#include "gc_controller.h"

#define ARRAY_SIZE(x) (sizeof(x) / sizeof(x[0]))
#define POLL_INTERVAL (XS1_TIMER_MHZ * 12 * 1000)

port gc_controller_port = XS1_PORT_1C;

void xscope_user_init(void)
{
  xscope_register(0, 0, "", 0, "");
  xscope_config_io(XSCOPE_IO_BASIC);
}

int main()
{
  timer t;
  unsigned time;
  t :> time;
  while (1) {
    gc_controller_state_t state;
    gc_controller_poll(gc_controller_port, state);
    gc_controller_print(state);
    t when timerafter(time += POLL_INTERVAL) :> void;
  }
  return 0;
}

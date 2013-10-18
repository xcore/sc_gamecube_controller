#include <xs1.h>
#include <stdio.h>
#include <xscope.h>
#include "gc_controller.h"

#define POLL_INTERVAL (XS1_TIMER_MHZ * 12 * 1000)

port gc_controller_port = XS1_PORT_1C;

void xscope_user_init(void)
{
  xscope_register(0, 0, "", 0, "");
  xscope_config_io(XSCOPE_IO_BASIC);
}

[[distributable]]
void print_state(server interface gc_controller_tx controller)
{
  while (1) {
    select {
    case controller.push(gc_controller_state_t state):
      gc_controller_print(state);
      break;
    }
  }
}

int main()
{
  interface gc_controller_tx controller;
  par {
    gc_controller_poller(gc_controller_port, controller, POLL_INTERVAL);
    print_state(controller);
  }
  return 0;
}

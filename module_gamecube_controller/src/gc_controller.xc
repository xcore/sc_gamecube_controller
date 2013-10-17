#include "gc_controller.h"
#include <xs1.h>
#include <print.h>

#define SHORT_DELAY (XS1_TIMER_MHZ)
#define THRESHOLD_DELAY (SHORT_DELAY * 2)
#define LONG_DELAY (SHORT_DELAY * 3)

#define ARRAY_SIZE(x) (sizeof(x) / sizeof(x[0]))

// Force external definitions of inline functions in this file.
extern inline int
gc_controller_get_button(gc_controller_state_t &state,
                         enum gc_controller_button button);
extern inline uint8_t
gc_controller_get_axis(gc_controller_state_t &state,
                       enum gc_controller_axis axis);

static const uint8_t poll_cmd[] =
{
  0b01000000,
  0b00000011,
  0b00000000
};

static void send_byte(port p, uint8_t byte, unsigned short &time)
{
  for (unsigned i = 0; i < 8; i++) {
    if (byte & (1 << 7)) {
      p @ time <: 0;
      p @ time += SHORT_DELAY :> void; // Float high
      time += LONG_DELAY;
    } else {
      p @ time <: 0;
      p @ time += LONG_DELAY :> void; // Float high
      time += SHORT_DELAY;
    }
    byte <<= 1;
  }
}

static void send_end(port p, unsigned short &time)
{
  // Terminate with a single high stop bit.
  p @ time <: 0;
  p @ time += SHORT_DELAY :> void; // Float high.
  p when pinseq(1) :> void;
}

static int receive_byte(port p)
{
  unsigned short t1, t2;
  uint8_t byte = 0;
  for (unsigned i = 0; i < 8; i++) {
    p when pinseq(0) :> void @ t1;
    p when pinseq(1) :> void @ t2;
    int bit = (t2 - t1) < THRESHOLD_DELAY;
    byte = (byte << 1) | bit;
  }
  return byte;
}

static void receive_end(port p)
{
  p when pinseq(0) :> void;
  p when pinseq(1) :> void;
}

void gc_controller_poll(port p, gc_controller_state_t &state)
{
  unsigned short time;
  p :> void @ time;
  time += SHORT_DELAY;
  for (unsigned i = 0; i < ARRAY_SIZE(poll_cmd); i++) {
    send_byte(p, poll_cmd[i], time);
  }
  send_end(p, time);
  for (unsigned i = 0; i < ARRAY_SIZE(state.data); i++) {
    state.data[i] = receive_byte(p);
  }
  receive_end(p);
}

void gc_controller_print(gc_controller_state_t &state)
{
  printstr("JOYSTICK: ");
  printint(gc_controller_get_axis(state, GC_CONTROLLER_AXIS_X));
  printchar(',');
  printintln(gc_controller_get_axis(state, GC_CONTROLLER_AXIS_Y));

  printstr("CSTICK: ");
  printint(gc_controller_get_axis(state, GC_CONTROLLER_AXIS_CX));
  printchar(',');
  printintln(gc_controller_get_axis(state, GC_CONTROLLER_AXIS_CY));

  printstr("LPADDLE: ");
  printintln(gc_controller_get_axis(state, GC_CONTROLLER_AXIS_L));

  printstr("RPADDLE: ");
  printintln(gc_controller_get_axis(state, GC_CONTROLLER_AXIS_R));

#define PRINT_BUTTON(name) \
  printstr(#name ": "); \
  printintln(gc_controller_get_button(state, GC_CONTROLLER_ ## name));

  PRINT_BUTTON(X);
  PRINT_BUTTON(Y);
  PRINT_BUTTON(A);
  PRINT_BUTTON(B);
  PRINT_BUTTON(START);
  PRINT_BUTTON(D_LEFT);
  PRINT_BUTTON(D_RIGHT);
  PRINT_BUTTON(D_UP);
  PRINT_BUTTON(D_DOWN);
  PRINT_BUTTON(Z);
  PRINT_BUTTON(R);
  PRINT_BUTTON(L);
}

#include "gc_controller.h"
#include <xs1.h>
#include <print.h>

#define SHORT_DELAY (XS1_TIMER_MHZ)
#define THRESHOLD_DELAY (SHORT_DELAY * 2)
#define LONG_DELAY (SHORT_DELAY * 3)

#define ARRAY_SIZE(x) (sizeof(x) / sizeof(x[0]))

// Force external definitions of inline functions in this file.
extern inline int
gc_controller_get_button(const gc_controller_state_t &state,
                         enum gc_controller_button button);
extern inline uint8_t
gc_controller_get_axis(const gc_controller_state_t &state,
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
  uint8_t byte = 0;
  for (unsigned i = 0; i < 8; i++) {
    unsigned short t1, t2;
    timer t;
    unsigned timeout;
    t :> timeout;
    timeout += SHORT_DELAY + LONG_DELAY;
    select {
    case t when timerafter(timeout) :> void:
      return -1;
    case p when pinseq(0) :> void @ t1:
      break;
    }
    p when pinseq(1) :> void @ t2;
    int bit = (t2 - t1) < THRESHOLD_DELAY;
    byte = (byte << 1) | bit;
  }
  return byte;
}

static void receive_end(port p)
{
  timer t;
  unsigned timeout;
  t :> timeout;
  timeout += SHORT_DELAY + LONG_DELAY;
  select {
  case t when timerafter(timeout) :> void:
    return;
  case p when pinseq(0) :> void:
    break;
  }
  p when pinseq(1) :> void;
}

int gc_controller_poll(port p, gc_controller_state_t &state)
{
  unsigned short time;
  p :> void @ time;
  time += SHORT_DELAY;
  for (unsigned i = 0; i < ARRAY_SIZE(poll_cmd); i++) {
    send_byte(p, poll_cmd[i], time);
  }
  send_end(p, time);
  for (unsigned i = 0; i < ARRAY_SIZE(state.data); i++) {
    int byte = receive_byte(p);
    if (byte < 0)
      return 0;
    state.data[i] = byte;
  }
  receive_end(p);
  return 1;
}

[[combinable]]
void gc_controller_poller(port p, client interface gc_controller_tx tx,
                          unsigned period)
{
  timer t;
  unsigned time;
  t :> time;
  time += period;
  while (1) {
    select {
    case t when timerafter(time) :> void:
      gc_controller_state_t state;
      if (gc_controller_poll(p, state)) {
        tx.push(state);
      }
      time += period;
      break;
    }
  }
}

void gc_controller_print(const gc_controller_state_t &state)
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

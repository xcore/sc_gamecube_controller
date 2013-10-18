#ifndef GC_CONTROLLER_H_
#define GC_CONTROLLER_H_

#include <stdint.h>

enum gc_controller_button {
  GC_CONTROLLER_A = 0,
  GC_CONTROLLER_B = 1,
  GC_CONTROLLER_X = 2,
  GC_CONTROLLER_Y = 3,
  GC_CONTROLLER_START = 4,
  GC_CONTROLLER_D_LEFT = 8,
  GC_CONTROLLER_D_RIGHT = 9,
  GC_CONTROLLER_D_DOWN = 10,
  GC_CONTROLLER_D_UP = 11,
  GC_CONTROLLER_Z = 12,
  GC_CONTROLLER_R = 13,
  GC_CONTROLLER_L = 14,
};

enum gc_controller_axis {
  GC_CONTROLLER_AXIS_X = 2,
  GC_CONTROLLER_AXIS_Y = 3,
  GC_CONTROLLER_AXIS_CX = 4,
  GC_CONTROLLER_AXIS_CY = 5,
  GC_CONTROLLER_AXIS_L = 6,
  GC_CONTROLLER_AXIS_R = 7
};

typedef struct gc_controller_state_t {
  uint8_t data[8];
} gc_controller_state_t;

/// Read the current state of the controller, storing the result in state.
/// Port p should be a 1-bit port clocked of the reference clock.
/// Takes approximately 360us to complete.
void gc_controller_poll(port p, gc_controller_state_t &state);

interface gc_controller_tx {
  void push(gc_controller_state_t data);
};

[[combinable]]
void gc_controller_poller(port p, client interface gc_controller_tx tx,
                          unsigned period);

inline int
gc_controller_get_button(const gc_controller_state_t &state,
                         enum gc_controller_button button) {
  return (state.data[button / 8] >> (button % 8)) & 1;
}

inline uint8_t
gc_controller_get_axis(const gc_controller_state_t &state,
                       enum gc_controller_axis axis) {
  return state.data[axis];
}

void gc_controller_print(const gc_controller_state_t &state);

#endif /* GC_CONTROLLER_H_ */

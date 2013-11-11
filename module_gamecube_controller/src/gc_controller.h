#ifndef GC_CONTROLLER_H_
#define GC_CONTROLLER_H_

/**
 * \file
 * \brief Functions for interfacing with a gamecube controller.
 *
 * The Gamecube controller uses a proprietry 6-pin connector, of which only 1
 * pin is used to transfer data. The data pin should be connected to a 1-bit
 * port with an external pull-up resistor of approximately 1K.
 * See http://www.int03.co.uk/crema/hardware/gamecube/gc-control.html
 */

#include <stdint.h>

/**
 * Enum for the Gamecube controller buttons.
 */
enum gc_controller_button {
  GC_CONTROLLER_A = 0, /**< A button. */
  GC_CONTROLLER_B = 1, /**< B button. */
  GC_CONTROLLER_X = 2, /**< X button. */
  GC_CONTROLLER_Y = 3, /**< Y button. */
  GC_CONTROLLER_START = 4, /**< Start button. */
  GC_CONTROLLER_D_LEFT = 8, /**< Left on D-Pad. */
  GC_CONTROLLER_D_RIGHT = 9, /**< Right on D-Pad. */
  GC_CONTROLLER_D_DOWN = 10, /**< Down on D-Pad. */
  GC_CONTROLLER_D_UP = 11, /**< Up on D-Pad. */
  GC_CONTROLLER_Z = 12, /**< Z button. */
  GC_CONTROLLER_R = 13, /**< Right shoulder button. */
  GC_CONTROLLER_L = 14, /**< Left shoulder button. */
};

/**
 * Enum for the Gamecube controller axes.
 */
enum gc_controller_axis {
  GC_CONTROLLER_AXIS_X = 2, /**< Control stick horizontal axis. */
  GC_CONTROLLER_AXIS_Y = 3, /**< Control stick vertical axis. */
  GC_CONTROLLER_AXIS_CX = 4, /**< C-stick horizontal axis. */
  GC_CONTROLLER_AXIS_CY = 5, /**< C-stick vertical axis. */
  GC_CONTROLLER_AXIS_L = 6, /**< Left shoulder trigger. */
  GC_CONTROLLER_AXIS_R = 7 /**< Left shoulder trigger. */
};

/**
 * Gamecube controller state. Use gc_controller_get_button() to
 * gc_controller_get_axis() to retrieve button and axis values.
 */
typedef struct gc_controller_state_t {
  uint8_t data[8];
} gc_controller_state_t;

/**
 * Read the current state of the controller, storing the result in state.
 * Port p should be a 1-bit port clocked off the reference clock.
 * Takes approximately 360us to complete.
 * \param p Controller port
 * \param[out] state Reference to where to store controller state.
 * \return 1 on success, 0 on failure
 */
int gc_controller_poll(port p, gc_controller_state_t &state);

interface gc_controller_tx {
  void push(gc_controller_state_t data);
};

/**
 * Controller polling task. Periodically polls the controller with the
 * specified period, sending the current controller state to another task.
 */
[[combinable]]
void gc_controller_poller(port p, client interface gc_controller_tx tx,
                          unsigned period);

/**
 * Get the value of the specified button.
 * \return 1 if pressed, 0 otherwise.
 */
inline int
gc_controller_get_button(const gc_controller_state_t &state,
                         enum gc_controller_button button) {
  return (state.data[button / 8] >> (button % 8)) & 1;
}

/**
 * Get the value of the specified axis.
 * \return Axis value in the range 0 to 255.
 */
inline uint8_t
gc_controller_get_axis(const gc_controller_state_t &state,
                       enum gc_controller_axis axis) {
  return state.data[axis];
}

/**
 * Print the controller state to standard out (for debugging).
 */
void gc_controller_print(const gc_controller_state_t &state);

#endif /* GC_CONTROLLER_H_ */

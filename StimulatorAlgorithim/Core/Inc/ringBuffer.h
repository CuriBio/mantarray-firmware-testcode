/*
 * ringBuffer.h
 *
 *  Created on: Jul 2, 2021
 *      Author: alexv
 */

/**
 * @file
 * Prototypes and structures for the ring buffer module.
 */

#ifndef RINGBUFFER_H
#define RINGBUFFER_H

/**
 * The size of a ring buffer.
 * Due to the design only <tt> RING_BUFFER_SIZE-1 </tt> items
 * can be contained in the buffer.
 * The buffer size must be a power of two.
*/
#define RING_BUFFER_SIZE 32

#if (RING_BUFFER_SIZE & (RING_BUFFER_SIZE - 1)) != 0
#error "RING_BUFFER_SIZE must be a power of two"
#endif


/**
 * The type which is used to hold the size
 * and the indicies of the buffer.
 * Must be able to fit \c RING_BUFFER_SIZE .
 */
typedef unsigned char ring_buffer_size_t;

/**
 * Used as a modulo operator
 * as <tt> a % b = (a & (b - 1)) </tt>
 * where \c a is a positive index in the buffer and
 * \c b is the (power of two) size of the buffer.
 */
#define RING_BUFFER_MASK (RING_BUFFER_SIZE-1)

/**
 * Simplifies the use of <tt>struct ring_buffer_t</tt>.
 */
typedef enum {
	XFER_CPLT = 0x01,
	STIM_RUN_CMD,
	STIM_STOP_CMD,
	STIM_RUN_CAPTURE_CMD,
	STIM_STOP_CAPTURE_CMD
} event_t;



typedef struct ring_buffer_t ring_buffer_t;

/**
 * Structure which holds a ring buffer.
 * The buffer contains a buffer array
 * as well as metadata for the ring buffer.
 */
struct ring_buffer_t {
  /** Buffer memory. */
  event_t buffer[RING_BUFFER_SIZE];
  /** Index of tail. */
  ring_buffer_size_t tail_index;
  /** Index of head. */
  ring_buffer_size_t head_index;
};

/**
 * Initializes the ring buffer pointed to by <em>buffer</em>.
 * This function can also be used to empty/reset the buffer.
 * @param buffer The ring buffer to initialize.
 */
void ring_buffer_init(volatile ring_buffer_t *buffer);

/**
 * Adds a byte to a ring buffer.
 * @param buffer The buffer in which the data should be placed.
 * @param data The byte to place.
 */
void ring_buffer_queue(volatile ring_buffer_t *buffer, event_t data);

/**
 * Adds an array of bytes to a ring buffer.
 * @param buffer The buffer in which the data should be placed.
 * @param data A pointer to the array of bytes to place in the queue.
 * @param size The size of the array.
 */
void ring_buffer_queue_arr(volatile ring_buffer_t *buffer, event_t *data, ring_buffer_size_t size);

/**
 * Returns the oldest byte in a ring buffer.
 * @param buffer The buffer from which the data should be returned.
 * @param data A pointer to the location at which the data should be placed.
 * @return 1 if data was returned; 0 otherwise.
 */
ring_buffer_size_t ring_buffer_dequeue(volatile ring_buffer_t *buffer, event_t *data);

/**
 * Returns the <em>len</em> oldest bytes in a ring buffer.
 * @param buffer The buffer from which the data should be returned.
 * @param data A pointer to the array at which the data should be placed.
 * @param len The maximum number of bytes to return.
 * @return The number of bytes returned.
 */
ring_buffer_size_t ring_buffer_dequeue_arr(volatile ring_buffer_t *buffer, event_t *data, ring_buffer_size_t len);
/**
 * Peeks a ring buffer, i.e. returns an element without removing it.
 * @param buffer The buffer from which the data should be returned.
 * @param data A pointer to the location at which the data should be placed.
 * @param index The index to peek.
 * @return 1 if data was returned; 0 otherwise.
 */
ring_buffer_size_t ring_buffer_peek(volatile ring_buffer_t *buffer, event_t *data, ring_buffer_size_t index);


unsigned char ring_buffer_is_empty(volatile ring_buffer_t *buffer);
unsigned char ring_buffer_is_full(volatile ring_buffer_t *buffer);
void push_event(volatile ring_buffer_t *buffer, event_t data);
void pop_event(volatile ring_buffer_t *buffer, event_t *data);
ring_buffer_size_t ring_buffer_num_items(volatile ring_buffer_t *buffer);

#endif /* INC_RINGBUFFER_H_ */

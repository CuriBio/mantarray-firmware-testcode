/*
 * ringBuffer.c
 *
 *  Created on: Jul 2, 2021
 *      Author: alexv
 */


#include "ringBuffer.h"
/**
 * @file
 * Implementation of ring buffer functions.
 */

void ring_buffer_init(volatile ring_buffer_t *buffer) {
  buffer->tail_index = 0;
  buffer->head_index = 0;
}

void ring_buffer_queue(volatile ring_buffer_t *buffer, event_t event) {
  /* Is buffer full? */
  if(ring_buffer_is_full(buffer)) {
    /* Is going to overwrite the oldest byte */
    /* Increase tail index */
    buffer->tail_index = ((buffer->tail_index + 1) & RING_BUFFER_MASK);
  }

  /* Place data in buffer */
  buffer->buffer[buffer->head_index] = event;
  buffer->head_index = ((buffer->head_index + 1) & RING_BUFFER_MASK);
}

void push_event(volatile ring_buffer_t *buffer, event_t event)
{
	ring_buffer_queue(buffer, event);
}

void ring_buffer_queue_arr(volatile ring_buffer_t *buffer, event_t *pEvent, ring_buffer_size_t size) {
  /* Add bytes; one by one */
  ring_buffer_size_t i;
  for(i = 0; i < size; i++) {
    ring_buffer_queue(buffer, pEvent[i]);
  }
}

ring_buffer_size_t ring_buffer_dequeue(volatile ring_buffer_t *buffer, event_t *pEvent) {
  if(ring_buffer_is_empty(buffer)) {
    /* No items */
    return 0;
  }

  *pEvent = buffer->buffer[buffer->tail_index];
  buffer->tail_index = ((buffer->tail_index + 1) & RING_BUFFER_MASK);
  return 1;
}

void pop_event(volatile ring_buffer_t *buffer, event_t *pEvent)
{
	ring_buffer_dequeue(buffer, pEvent);
}

ring_buffer_size_t ring_buffer_dequeue_arr(volatile ring_buffer_t *buffer, event_t *pEvent, ring_buffer_size_t len) {
  if(ring_buffer_is_empty(buffer)) {
    /* No items */
    return 0;
  }

  event_t *event_ptr = pEvent;
  ring_buffer_size_t cnt = 0;
  while((cnt < len) && ring_buffer_dequeue(buffer, event_ptr)) {
    cnt++;
    event_ptr++;
  }
  return cnt;
}

ring_buffer_size_t ring_buffer_peek(volatile ring_buffer_t *buffer, event_t *pEvent, ring_buffer_size_t index) {
  if(index >= ring_buffer_num_items(buffer)) {
    /* No items at index */
    return 0;
  }

  /* Add index to pointer */
  ring_buffer_size_t data_index = ((buffer->tail_index + index) & RING_BUFFER_MASK);
  *pEvent = buffer->buffer[data_index];
  return 1;
}
/**
 * Returns whether a ring buffer is empty.
 * @param buffer The buffer for which it should be returned whether it is empty.
 * @return 1 if empty; 0 otherwise.
 */
unsigned char ring_buffer_is_empty(volatile ring_buffer_t *buffer) {
  return (buffer->head_index == buffer->tail_index);
}

/**
 * Returns whether a ring buffer is full.
 * @param buffer The buffer for which it should be returned whether it is full.
 * @return 1 if full; 0 otherwise.
 */
unsigned char ring_buffer_is_full(volatile ring_buffer_t *buffer) {
  return ((buffer->head_index - buffer->tail_index) & RING_BUFFER_MASK) == RING_BUFFER_MASK;
}

/**
 * Returns the number of items in a ring buffer.
 * @param buffer The buffer for which the number of items should be returned.
 * @return The number of items in the ring buffer.
 */
ring_buffer_size_t ring_buffer_num_items(volatile ring_buffer_t *buffer) {
  return ((buffer->head_index - buffer->tail_index) & RING_BUFFER_MASK);
}

void create_event(event_name_e name, void *data, size_t size, event_t *pEvent)
{
	pEvent -> name = name;
	pEvent -> data = (int16_t *) malloc(size);
	pEvent -> data_size = size;
	if (data != NULL) { memcpy(pEvent->data, data, size); }
}

void free_event_data(event_t *pEvent)
{
	free(pEvent->data);
}

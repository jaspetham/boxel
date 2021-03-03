/* eslint-disable @typescript-eslint/explicit-module-boundary-types */
/* eslint-disable @typescript-eslint/no-explicit-any */
import { schedule, cancel } from '@ember/runloop';
import { EmberRunTimer } from '@ember/runloop/types';

const cancellation: WeakMap<
  Promise<any>,
  (p: Promise<any>) => void
> = new WeakMap();

export function registerCancellation(
  promise: Promise<any>,
  handler: (p: Promise<any>) => void
) {
  cancellation.set(promise, handler);
}

export function afterRender() {
  let ticket: EmberRunTimer;
  let promise = new Promise((resolve) => {
    ticket = schedule('afterRender', resolve);
  });
  registerCancellation(promise, () => {
    cancel(ticket);
  });
  return promise;
}

export function microwait() {
  return new Promise<void>((resolve) => resolve());
}

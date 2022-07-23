import Service from '@ember/service';
import { task } from 'ember-concurrency';
import { taskFor } from 'ember-concurrency-ts';
import type {
  Box,
  Card,
  prepareToRender,
  serializeCard,
  serializedGet,
  serializedSet,
  contains,
  containsMany,
  field,
  Component,
  primitive,
} from 'https://cardstack.com/base/card-api';
import { baseRealm } from '@cardstack/runtime-common';
import config from 'runtime-spike/config/environment';

export interface API {
  Box: typeof Box;
  Card: typeof Card;
  prepareToRender: typeof prepareToRender;
  serializeCard: typeof serializeCard;
  serializedGet: typeof serializedGet;
  serializedSet: typeof serializedSet;
  contains: typeof contains;
  containsMany: typeof containsMany;
  field: typeof field;
  Component: typeof Component;
  primitive: typeof primitive;
}

const baseCardModule = `${baseRealm.url}card-api`;

export default class CardAPI extends Service {
  #api: API | undefined;

  constructor(properties: object) {
    super(properties);
    taskFor(this.load).perform();
  }

  get api() {
    if (!this.#api) {
      throw new Error(
        `bug: card API has not loaded yet--make sure to await this.loaded before using the api`
      );
    }
    return this.#api;
  }

  get loaded(): Promise<void> {
    return (this.load as any).last.isRunning;
  }

  @task private async load(): Promise<void> {
    if (config.environment === 'test') {
      // The tests don't have a way of overriding import URL's like we do in the
      // service worker for resolving https://cardstack.com/base/ imports to a locally
      // served base realm. so we cheat and use AMD style module loading for the tests
      this.#api = (window as any).RUNTIME_SPIKE_EXTERNALS.get(
        'runtime-spike/lib/card-api'
      );
    } else {
      this.#api = await import(/* webpackIgnore: true */ baseCardModule);
    }
  }
}

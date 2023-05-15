import Controller from '@ember/controller';
import ENV from '@cardstack/host/config/environment';
import { withPreventDefault } from '../helpers/with-prevent-default';
import { service } from '@ember/service';
import type RouterService from '@ember/routing/router-service';
import { action } from '@ember/object';

import { tracked } from '@glimmer/tracking';
const { isLocalRealm } = ENV;
import { ComponentLike } from '@glint/template';
import { Model } from '@cardstack/host/routes/card';

export default class CardController extends Controller {
  isLocalRealm = isLocalRealm;
  isolatedCardComponent: ComponentLike | undefined;
  withPreventDefault = withPreventDefault;
  @service declare router: RouterService;
  @tracked operatorModeEnabled = false;
  @tracked model: Model | undefined;

  get getIsolatedComponent() {
    if (this.model) {
      return this.model.constructor.getComponent(this.model, 'isolated');
    }

    return null;
  }

  @action
  toggleOperatorMode() {
    this.operatorModeEnabled = !this.operatorModeEnabled;
  }

  @action
  closeOperatorMode() {
    this.operatorModeEnabled = false;
  }
}
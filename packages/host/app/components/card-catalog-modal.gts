import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import { fn } from '@ember/helper';
import { action } from '@ember/object';
import { service } from '@ember/service';
import { registerDestructor } from '@ember/destroyable';
import { enqueueTask, restartableTask } from 'ember-concurrency';
import debounce from 'lodash/debounce';
import type { Card, CardContext } from 'https://cardstack.com/base/card-api';
import {
  createNewCard,
  isSingleCardDocument,
  type CardRef,
  type CreateNewCard,
  Deferred,
} from '@cardstack/runtime-common';
import type { Query, Filter } from '@cardstack/runtime-common/query';
import { Button, SearchInput } from '@cardstack/boxel-ui';
import { and, eq, not } from '@cardstack/boxel-ui/helpers/truth-helpers';
import { svgJar } from '@cardstack/boxel-ui/helpers/svg-jar';
import cn from '@cardstack/boxel-ui/helpers/cn';
import type CardService from '../services/card-service';
import type LoaderService from '../services/loader-service';
import { getSearchResults, Search } from '../resources/search';
import {
  suggestCardChooserTitle,
  getSuggestionWithLowestDepth,
} from '../utils/text-suggestion';
import ModalContainer from './modal-container';
import CardCatalog from './card-catalog';
import CardCatalogFilters from './card-catalog/filters';

interface Signature {
  Args: {
    context?: CardContext;
  };
}

const DEFAULT_CHOOOSE_CARD_TITLE = 'Choose a Card';

export default class CardCatalogModal extends Component<Signature> {
  <template>
    {{! @glint-ignore Argument of type boolean
          is not assignable to currentRequest's params. }}
    {{#if (and this.currentRequest (not this.dismissModal))}}
      <ModalContainer
        @title={{this.chooseCardTitle}}
        @onClose={{fn this.pick undefined}}
        @zIndex={{this.zIndex}}
        data-test-card-catalog-modal
      >
        <:header>
          <SearchInput
            class='card-catalog-modal__search-field'
            @value={{this.searchKey}}
            @onInput={{this.setSearchKey}}
            @onKeyPress={{this.onSearchFieldKeypress}}
            @state={{this.searchFieldState}}
            @errorMessage={{this.searchErrorMessage}}
            @placeholder='Search for a card type or enter card URL'
            data-test-search-field
          />
          <CardCatalogFilters />
        </:header>
        <:content>
          {{#if this.currentRequest.search.isLoading}}
            Loading...
          {{else}}
            <CardCatalog
              @results={{this.results}}
              @toggleSelect={{this.toggleSelect}}
              @selectedCard={{this.selectedCard}}
              @context={{@context}}
            />
          {{/if}}
        </:content>
        <:footer>
          <div
            class={{cn
              'footer'
              (if this.currentRequest.opts.offerToCreate 'with-create-button')
            }}
          >
            {{#if this.currentRequest.opts.offerToCreate}}
              <Button
                @kind='secondary-light'
                @size='tall'
                class='create-new-button'
                {{on
                  'click'
                  (fn this.createNew this.currentRequest.opts.offerToCreate)
                }}
                data-test-card-catalog-create-new-button
              >
                {{svgJar
                  'icon-plus'
                  width='20'
                  height='20'
                  role='presentation'
                }}
                Create New
                {{this.cardRefName}}
              </Button>
            {{/if}}
            <div>
              <Button
                @kind='secondary-light'
                @size='tall'
                class='footer-button'
                {{on 'click' this.cancel}}
                data-test-card-catalog-cancel-button
              >
                Cancel
              </Button>
              <Button
                @kind='primary'
                @size='tall'
                @disabled={{eq this.selectedCard undefined}}
                class='footer-button'
                {{on 'click' (fn this.pick this.selectedCard)}}
                data-test-card-catalog-go-button
              >
                Go
              </Button>
            </div>
          </div>
        </:footer>
      </ModalContainer>
    {{/if}}
    <style>
      .card-catalog-modal__search-field {
        /* This is neccesary to show card URL error messages */
        height: 5.625rem;
      }
      .footer {
        display: flex;
        justify-content: flex-end;
      }
      .footer.with-create-button {
        justify-content: space-between;
      }
      .footer-button + .footer-button {
        margin-left: var(--boxel-sp-xs);
      }
      .create-new-button {
        --icon-color: var(--boxel-highlight);
        display: flex;
        justify-content: center;
        align-items: center;
        gap: var(--boxel-sp-xxs);
      }
    </style>
  </template>

  @tracked currentRequest:
    | {
        search: Search;
        deferred: Deferred<Card | undefined>;
        opts?: {
          offerToCreate?: CardRef;
          createNewCard?: CreateNewCard;
        };
      }
    | undefined = undefined;
  @tracked zIndex = 20;
  @tracked selectedCard?: Card = undefined;
  @tracked searchKey = '';
  @tracked hasSearchError = false;
  @tracked urlSearchVisible = false;
  @tracked chooseCardTitle = DEFAULT_CHOOOSE_CARD_TITLE;
  @tracked dismissModal = false;
  @service declare cardService: CardService;
  @service declare loaderService: LoaderService;

  constructor(owner: unknown, args: {}) {
    super(owner, args);
    (globalThis as any)._CARDSTACK_CARD_CHOOSER = this;
    registerDestructor(this, () => {
      delete (globalThis as any)._CARDSTACK_CARD_CHOOSER;
    });
  }

  get results() {
    return this.currentRequest?.search.instancesWithRealmInfo ?? [];
  }

  get searchFieldState() {
    return this.hasSearchError ? 'invalid' : 'initial';
  }

  get searchErrorMessage() {
    return this.hasSearchError ? 'Not a valid search key' : undefined;
  }

  get cardRefName() {
    return (
      (
        this.currentRequest?.opts?.offerToCreate as {
          module: string;
          name: string;
        }
      ).name ?? 'Card'
    );
  }

  private resetState() {
    this.searchKey = '';
    this.hasSearchError = false;
    this.selectedCard = undefined;
    this.urlSearchVisible = false;
    this.dismissModal = false;
  }

  // This is part of our public API for runtime-common to invoke the card chooser
  async chooseCard<T extends Card>(
    query: Query,
    opts?: {
      offerToCreate?: CardRef;
      multiSelect?: boolean;
      createNewCard?: CreateNewCard;
    },
  ): Promise<undefined | T> {
    this.zIndex++;
    this.chooseCardTitle = chooseCardTitle(query.filter, opts?.multiSelect);
    return (await this._chooseCard.perform(query, opts)) as T | undefined;
  }

  private _chooseCard = enqueueTask(
    async <T extends Card>(
      query: Query,
      opts: { offerToCreate?: CardRef } = {},
    ) => {
      this.currentRequest = {
        search: getSearchResults(this, () => query),
        deferred: new Deferred(),
        opts,
      };
      let card = await this.currentRequest.deferred.promise;
      if (card) {
        return card as T;
      } else {
        return undefined;
      }
    },
  );

  private getCard = restartableTask(async (searchKey: string) => {
    //TODO: Handle fetching card using non-URL search key
    let response = await this.loaderService.loader.fetch(searchKey, {
      headers: {
        Accept: 'application/vnd.card+json',
      },
    });
    if (response.ok) {
      let maybeCardDoc = await response.json();
      if (isSingleCardDocument(maybeCardDoc)) {
        this.selectedCard = await this.cardService.createFromSerialized(
          maybeCardDoc.data,
          maybeCardDoc,
          new URL(maybeCardDoc.data.id),
        );
        return;
      }
    }
    this.selectedCard = undefined;
    this.hasSearchError = true;
  });

  debouncedSearchFieldUpdate = debounce(() => {
    if (!this.searchKey) {
      this.selectedCard = undefined;
      return;
    }
    //TODO: Remove this URL validation after implementing search feature with non-URL.
    try {
      new URL(this.searchKey);
    } catch (e: any) {
      if (e instanceof TypeError && e.message.includes('Invalid URL')) {
        return;
      }
      throw e;
    }
    this.onSearchFieldUpdated();
  }, 500);

  @action
  displayURLSearch() {
    this.urlSearchVisible = true;
  }

  @action
  hideURLSearchIfBlank() {
    if (!this.searchKey.trim()) {
      this.urlSearchVisible = false;
    }
  }

  @action
  setSearchKey(searchKey: string) {
    this.hasSearchError = false;
    this.selectedCard = undefined;
    this.searchKey = searchKey;
    this.debouncedSearchFieldUpdate();
  }

  @action
  onSearchFieldKeypress(e: KeyboardEvent) {
    if (e.key === 'Enter' && this.searchKey) {
      this.getCard.perform(this.searchKey);
    }
  }

  @action
  onSearchFieldUpdated() {
    if (this.searchKey) {
      this.selectedCard = undefined;
      this.getCard.perform(this.searchKey);
    }
  }

  @action toggleSelect(card?: Card): void {
    this.searchKey = '';
    if (this.selectedCard?.id === card?.id) {
      this.selectedCard = undefined;
      return;
    }
    this.selectedCard = card;
  }

  @action pick(card?: Card) {
    if (this.currentRequest) {
      this.currentRequest.deferred.fulfill(card);
      this.currentRequest = undefined;
    }
    this.resetState();
  }

  @action cancel(): void {
    this.resetState();
  }

  @action async createNew(ref: CardRef): Promise<void> {
    let newCard;
    this.dismissModal = true;
    if (this.currentRequest?.opts?.createNewCard) {
      newCard = await this.currentRequest?.opts?.createNewCard(ref, undefined, {
        isLinkedCard: true,
      });
    } else {
      newCard = await createNewCard(ref, undefined);
    }
    this.pick(newCard);
  }
}

function chooseCardTitle(
  filter: Filter | undefined,
  multiSelect?: boolean,
): string {
  if (!filter) {
    return DEFAULT_CHOOOSE_CARD_TITLE;
  }
  let suggestions = suggestCardChooserTitle(filter, 0, { multiSelect });
  return (
    getSuggestionWithLowestDepth(suggestions) ?? DEFAULT_CHOOOSE_CARD_TITLE
  );
}

declare module '@glint/environment-ember-loose/registry' {
  export default interface Registry {
    CardCatalogModal: typeof CardCatalogModal;
  }
}

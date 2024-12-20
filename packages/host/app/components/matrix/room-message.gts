import { fn } from '@ember/helper';
import { on } from '@ember/modifier';
import { action } from '@ember/object';
import { service } from '@ember/service';
import { htmlSafe } from '@ember/template';
import Component from '@glimmer/component';
import { tracked, cached } from '@glimmer/tracking';

import { task } from 'ember-concurrency';
import perform from 'ember-concurrency/helpers/perform';
import { modifier } from 'ember-modifier';

import { trackedFunction } from 'ember-resources/util/function';

import { Avatar, Button } from '@cardstack/boxel-ui/components';
import { Copy as CopyIcon } from '@cardstack/boxel-ui/icons';

import { isCardInstance, markdownToHtml } from '@cardstack/runtime-common';

import { Message } from '@cardstack/host/lib/matrix-classes/message';
import MessageCommand from '@cardstack/host/lib/matrix-classes/message-command';
import monacoModifier from '@cardstack/host/modifiers/monaco';
import type { MonacoEditorOptions } from '@cardstack/host/modifiers/monaco';
import CommandService from '@cardstack/host/services/command-service';
import type MatrixService from '@cardstack/host/services/matrix-service';
import type MonacoService from '@cardstack/host/services/monaco-service';
import { type MonacoSDK } from '@cardstack/host/services/monaco-service';
import type OperatorModeStateService from '@cardstack/host/services/operator-mode-state-service';

import { type CardDef } from 'https://cardstack.com/base/card-api';

import ApplyButton from '../ai-assistant/apply-button';
import { type ApplyButtonState } from '../ai-assistant/apply-button';
import AiAssistantMessage from '../ai-assistant/message';
import { aiBotUserId } from '../ai-assistant/panel';

interface Signature {
  Element: HTMLDivElement;
  Args: {
    roomId: string;
    message: Message;
    index: number;
    monacoSDK: MonacoSDK;
    isStreaming: boolean;
    currentEditor: number | undefined;
    setCurrentEditor: (editor: number | undefined) => void;
    retryAction?: () => void;
    isPending?: boolean;
    registerScroller: (args: {
      index: number;
      element: HTMLElement;
      scrollTo: Element['scrollIntoView'];
    }) => void;
  };
}

const STREAMING_TIMEOUT_MS = 60000;

export default class RoomMessage extends Component<Signature> {
  constructor(owner: unknown, args: Signature['Args']) {
    super(owner, args);

    this.checkStreamingTimeout.perform();
  }

  @tracked private streamingTimeout = false;

  private checkStreamingTimeout = task(async () => {
    if (!this.isFromAssistant || !this.args.isStreaming) {
      return;
    }

    // If message is streaming and hasn't been updated in the last minute, show a timeout message
    if (Date.now() - Number(this.args.message.updated) > STREAMING_TIMEOUT_MS) {
      this.streamingTimeout = true;
      return;
    }

    // Do this check every second
    await new Promise((resolve) => setTimeout(resolve, 1000));

    this.checkStreamingTimeout.perform();
  });

  private get isFromAssistant() {
    return this.args.message.author.userId === aiBotUserId;
  }

  private get getComponent() {
    let { commandResult } = this.args.message;
    if (!commandResult || !isCardInstance(commandResult)) {
      return undefined;
    }
    return commandResult.constructor.getComponent(commandResult);
  }

  <template>
    {{! We Intentionally wait until message resources are loaded (i.e. have a value) before rendering the message.
      This is because if the message resources render asynchronously after the message is already rendered (e.g. card pills),
      it is problematic to ensure the last message sticks to the bottom of the screen.
      In AiAssistantMessage, there is a ScrollIntoView modifier that will scroll the last message into view (i.e. scroll to the bottom) when it renders.
      If we let things in the message render asynchronously, the height of the message will change after that and the scroll position will move up a bit (i.e. not stick to the bottom).
    }}
    {{#if this.resources}}
      <AiAssistantMessage
        id='message-container-{{@index}}'
        class='room-message'
        @formattedMessage={{htmlSafe
          (markdownToHtml @message.formattedMessage)
        }}
        @datetime={{@message.created}}
        @index={{@index}}
        @registerScroller={{@registerScroller}}
        @isFromAssistant={{this.isFromAssistant}}
        @profileAvatar={{component
          Avatar
          isReady=true
          userId=@message.author.userId
          displayName=@message.author.displayName
        }}
        @resources={{this.resources}}
        @errorMessage={{this.errorMessage}}
        @isStreaming={{@isStreaming}}
        @retryAction={{if
          @message.command
          (fn (perform this.run) @message.command @roomId)
          @retryAction
        }}
        @isPending={{@isPending}}
        data-test-boxel-message-from={{@message.author.name}}
        ...attributes
      >
        {{#if @message.command}}
          <div
            class='command-button-bar'
            {{! In test, if we change this isIdle check to the task running locally on this component, it will fail because roomMessages get destroyed during re-indexing.
            Since services are long-lived so it we will not have this issue. I think this will go away when we convert our room field into a room component }}
            {{! TODO: Convert to non-EC async method after fixing CS-6987 }}
            data-test-command-card-idle={{this.commandService.run.isIdle}}
          >
            <Button
              class='view-code-button'
              {{on 'click' this.viewCodeToggle}}
              @kind={{if this.isDisplayingCode 'primary-dark' 'secondary-dark'}}
              @size='extra-small'
              data-test-view-code-button
            >
              {{if this.isDisplayingCode 'Hide Code' 'View Code'}}
            </Button>
            <ApplyButton
              @state={{this.applyButtonState}}
              {{on 'click' (fn (perform this.run) @message.command @roomId)}}
              data-test-command-apply={{this.applyButtonState}}
            />
          </div>
          {{#if this.isDisplayingCode}}
            <div class='preview-code'>
              <Button
                class='copy-to-clipboard-button'
                @kind='text-only'
                @size='extra-small'
                {{on 'click' (perform this.copyToClipboard)}}
                data-test-copy-code
              >
                <CopyIcon
                  width='16'
                  height='16'
                  role='presentation'
                  aria-hidden='true'
                />
                Copy to clipboard
              </Button>
              <div
                class='monaco-container'
                {{this.scrollBottomIntoView}}
                {{monacoModifier
                  content=this.previewCommandCode
                  contentChanged=undefined
                  monacoSDK=@monacoSDK
                  language='json'
                  readOnly=true
                  darkTheme=true
                  editorDisplayOptions=this.editorDisplayOptions
                }}
                data-test-editor
                data-test-percy-hide
              />
            </div>
          {{/if}}
          {{#let this.getComponent as |Component|}}
            {{#if Component}}
              <Component @format='embedded' />
            {{/if}}
          {{/let}}
        {{/if}}
      </AiAssistantMessage>
    {{/if}}

    <style scoped>
      .room-message {
        --ai-assistant-message-padding: var(--boxel-sp);
      }
      .is-pending .view-code-button,
      .is-error .view-code-button {
        background: var(--boxel-200);
        color: var(--boxel-500);
      }
      .command-button-bar {
        display: flex;
        justify-content: flex-end;
        gap: var(--boxel-sp-xs);
        margin-top: var(--boxel-sp);
      }
      .view-code-button {
        --boxel-button-font: 600 var(--boxel-font-xs);
        --boxel-button-min-height: 1.5rem;
        --boxel-button-padding: 0 var(--boxel-sp-xs);
        min-width: initial;
        width: auto;
        max-height: 1.5rem;
      }
      .view-code-button:hover:not(:disabled) {
        filter: brightness(1.1);
      }
      .preview-code {
        --spacing: var(--boxel-sp-sm);
        --fill-container-spacing: calc(
          -1 * var(--ai-assistant-message-padding)
        );
        margin: var(--boxel-sp) var(--fill-container-spacing) 0
          var(--fill-container-spacing);
        padding: var(--spacing) 0;
        background-color: var(--boxel-dark);
      }
      .copy-to-clipboard-button {
        --boxel-button-font: 600 var(--boxel-font-xs);
        --boxel-button-padding: 0 var(--boxel-sp-xs);
        --icon-color: var(--boxel-highlight);
        --icon-stroke-width: 2px;
        margin-left: var(--spacing);
        margin-bottom: var(--spacing);
        display: grid;
        grid-template-columns: auto 1fr;
        gap: var(--spacing);
      }
      .copy-to-clipboard-button:hover:not(:disabled) {
        --boxel-button-text-color: var(--boxel-highlight);
        filter: brightness(1.1);
      }
      .monaco-container {
        height: var(--monaco-container-height);
        min-height: 7rem;
        max-height: 30vh;
      }
    </style>
  </template>

  editorDisplayOptions: MonacoEditorOptions = {
    wordWrap: 'on',
    wrappingIndent: 'indent',
    fontWeight: 'bold',
    scrollbar: {
      alwaysConsumeMouseWheel: false,
    },
  };

  @service private declare operatorModeStateService: OperatorModeStateService;
  @service private declare matrixService: MatrixService;
  @service private declare monacoService: MonacoService;
  @service declare commandService: CommandService;

  @tracked private isDisplayingCode = false;

  private copyToClipboard = task(async () => {
    await navigator.clipboard.writeText(this.previewCommandCode);
  });

  private loadMessageResources = trackedFunction(this, async () => {
    let cards: CardDef[] = [];
    let errors: { id: string; error: Error }[] = [];

    let promises = this.args.message.attachedResources?.map(
      async (resource) => {
        await resource.loaded;
        if (resource.card) {
          cards.push(resource.card);
        } else if (resource.cardError) {
          let { id, error } = resource.cardError;
          errors.push({
            id,
            error,
          });
        }
      },
    );

    if (promises) {
      await Promise.all(promises);
    }

    return {
      cards: cards.length ? cards : undefined,
      errors: errors.length ? errors : undefined,
    };
  });

  private get resources() {
    return this.loadMessageResources.value;
  }

  private get errorMessage() {
    if (this.failedCommandState) {
      return `Failed to apply changes. ${this.failedCommandState.message}`;
    }
    if (this.args.message.errorMessage) {
      return this.args.message.errorMessage;
    }
    if (this.streamingTimeout) {
      return 'This message was processing for too long. Please try again.';
    }
    if (!this.resources?.errors) {
      return undefined;
    }

    let hasResourceErrors = this.resources.errors.length > 0;
    if (hasResourceErrors) {
      return 'Error rendering attached cards.';
    }

    return this.resources.errors
      .map((e: { id: string; error: Error }) => `${e.id}: ${e.error.message}`)
      .join(', ');
  }

  private get previewCommandCode() {
    if (!this.command) {
      return JSON.stringify({}, null, 2);
    }
    let { name, payload } = this.command;
    return JSON.stringify({ name, payload }, null, 2);
  }

  get command() {
    return this.args.message.command;
  }

  @cached
  private get failedCommandState() {
    if (!this.command?.eventId) {
      return undefined;
    }
    return this.matrixService.failedCommandState.get(this.command.eventId);
  }

  run = task(async (command: MessageCommand, roomId: string) => {
    return this.commandService.run.unlinked().perform(command, roomId);
  });

  @cached
  private get applyButtonState(): ApplyButtonState {
    if (this.failedCommandState) {
      return 'failed';
    }
    return this.command?.status ?? 'ready';
  }

  @action private viewCodeToggle() {
    this.isDisplayingCode = !this.isDisplayingCode;
    if (this.isDisplayingCode) {
      this.args.setCurrentEditor(this.args.message.index);
    }
  }

  // TODO need to reevalutate this modifier--do we want to hijack the scroll
  // when the user views the code?
  private scrollBottomIntoView = modifier((element: HTMLElement) => {
    if (this.args.currentEditor !== this.args.message.index) {
      return;
    }

    let height = this.monacoService.getContentHeight();
    if (!height || height < 0) {
      return;
    }
    element.style.height = `${height}px`;

    let outerContainer = document.getElementById(
      `message-container-${this.args.index}`,
    );
    if (!outerContainer) {
      return;
    }
    this.scrollIntoView(outerContainer);
  });

  private scrollIntoView(element: HTMLElement) {
    let { top, bottom } = element.getBoundingClientRect();
    let isVerticallyInView = top >= 0 && bottom <= window.innerHeight;

    if (!isVerticallyInView) {
      element.scrollIntoView({ block: 'end' });
    }
  }
}

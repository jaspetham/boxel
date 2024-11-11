import { fn } from '@ember/helper';
import { on } from '@ember/modifier';
import { getOwner, setOwner } from '@ember/owner';
import { service } from '@ember/service';
import { click, waitFor, findAll, waitUntil } from '@ember/test-helpers';

import { module, test } from 'qunit';

import { GridContainer } from '@cardstack/boxel-ui/components';

import { baseRealm, Command } from '@cardstack/runtime-common';

import type LoaderService from '@cardstack/host/services/loader-service';

import type OperatorModeStateService from '@cardstack/host/services/operator-mode-state-service';

import type {
  SwitchSubmodeInput,
  SaveCardInput,
  ShowCardInput,
  PatchCardInput,
} from 'https://cardstack.com/base/command';

import type * as BaseCommandModule from 'https://cardstack.com/base/command';

import {
  setupLocalIndexing,
  setupServerSentEvents,
  setupOnSave,
  testRealmURL,
  setupAcceptanceTestRealm,
  visitOperatorMode,
  delay,
} from '../helpers';

import {
  CardDef,
  Component,
  CardsGrid,
  contains,
  linksTo,
  linksToMany,
  field,
  setupBaseRealm,
  StringField,
} from '../helpers/base-realm';

import { setupMockMatrix } from '../helpers/mock-matrix';
import { setupApplicationTest } from '../helpers/setup';

module('Acceptance | Commands tests', function (hooks) {
  setupApplicationTest(hooks);
  setupLocalIndexing(hooks);
  setupServerSentEvents(hooks);
  setupOnSave(hooks);
  let { simulateRemoteMessage, getRoomIds, getRoomEvents } = setupMockMatrix(
    hooks,
    {
      loggedInAs: '@testuser:staging',
      activeRealms: [baseRealm.url, testRealmURL],
    },
  );
  setupBaseRealm(hooks);

  hooks.beforeEach(async function () {
    class Pet extends CardDef {
      static displayName = 'Pet';
      @field name = contains(StringField);
      @field favoriteTreat = contains(StringField);

      @field title = contains(StringField, {
        computeVia: function (this: Pet) {
          return this.name;
        },
      });
      static embedded = class Embedded extends Component<typeof this> {
        <template>
          <h3 data-test-pet={{@model.name}}>
            <@fields.name />
          </h3>
        </template>
      };
      static isolated = class Isolated extends Component<typeof this> {
        <template>
          <GridContainer class='container'>
            <h2><@fields.title /></h2>
            <div>
              <div>Favorite Treat: <@fields.favoriteTreat /></div>
              <div data-test-editable-meta>
                {{#if @canEdit}}
                  <@fields.title />
                  is editable.
                {{else}}
                  <@fields.title />
                  is NOT editable.
                {{/if}}
              </div>
            </div>
          </GridContainer>
        </template>
      };
    }

    class ScheduleMeetingInput extends CardDef {
      @field topic = contains(StringField);
      @field participants = linksToMany(() => Person);
    }

    class Meeting extends CardDef {
      static displayName = 'Meeting';
      @field participants = linksToMany(() => Person);
      @field topic = contains(StringField);
    }

    class ScheduleMeetingCommand extends Command<
      ScheduleMeetingInput,
      undefined
    > {
      @service private declare loaderService: LoaderService;
      @service
      private declare operatorModeStateService: OperatorModeStateService;
      static displayName = 'ScheduleMeetingCommand';

      async getInputType() {
        return ScheduleMeetingInput;
      }
      protected async run(input: ScheduleMeetingInput) {
        console.log('input', input);
        let meeting = new Meeting({
          topic: 'unset topic',
          participants: input.participants,
        });
        console.log('meeting', meeting);
        let saveCardCommand = this.commandContext.lookupCommand<
          SaveCardInput,
          undefined
        >('save-card');
        console.log('saveCardCommand', saveCardCommand);
        console.log('this.loaderService', this.loaderService);
        const { SaveCardInput } = await this.loaderService.loader.import<
          typeof BaseCommandModule
        >(`${baseRealm.url}command`);
        console.log('SaveCardInput', SaveCardInput);
        await saveCardCommand.execute(
          new SaveCardInput({
            card: meeting,
            realm: testRealmURL,
          }),
        );
        console.log('saved');

        // Mutate and save again
        let patchCardCommand = this.commandContext.lookupCommand<
          PatchCardInput,
          undefined,
          { cardType: typeof Meeting }
        >('patch-card', { cardType: Meeting });

        await this.commandContext.sendAiAssistantMessage({
          prompt: `Change the topic of the meeting to "${input.topic}"`,
          attachedCards: [meeting],
          commands: [{ command: patchCardCommand, autoExecute: true }],
        });

        await patchCardCommand.waitForNextCompletion();

        let showCardCommand = this.commandContext.lookupCommand<
          ShowCardInput,
          undefined
        >('show-card');
        console.log('showCardCommand', showCardCommand);
        const { ShowCardInput } = await this.loaderService.loader.import<
          typeof BaseCommandModule
        >(`${baseRealm.url}command`);
        await showCardCommand.execute(
          new ShowCardInput({
            cardToShow: meeting,
            placement: 'addToStack',
          }),
        );

        return undefined;
      }
    }

    class Person extends CardDef {
      static displayName = 'Person';
      @field firstName = contains(StringField);
      @field lastName = contains(StringField);
      @field pet = linksTo(Pet);
      @field friends = linksToMany(Pet);
      @field firstLetterOfTheName = contains(StringField, {
        computeVia: function (this: Person) {
          if (!this.firstName) {
            return;
          }
          return this.firstName[0];
        },
      });
      @field title = contains(StringField, {
        computeVia: function (this: Person) {
          return [this.firstName, this.lastName].filter(Boolean).join(' ');
        },
      });

      static isolated = class Isolated extends Component<typeof this> {
        runSwitchToCodeModeCommandViaAiAssistant = (autoExecute: boolean) => {
          let commandContext = this.args.context?.commandContext;
          if (!commandContext) {
            console.error('No command context found');
            return;
          }
          let switchSubmodeCommand = commandContext.lookupCommand<
            SwitchSubmodeInput,
            undefined
          >('switch-submode');
          commandContext.sendAiAssistantMessage({
            prompt: 'Switch to code mode',
            commands: [{ command: switchSubmodeCommand, autoExecute }],
          });
        };
        runScheduleMeetingCommand = async () => {
          let commandContext = this.args.context?.commandContext;
          if (!commandContext) {
            console.error('No command context found');
            return;
          }
          let scheduleMeeting = new ScheduleMeetingCommand(
            commandContext,
            undefined,
          );
          setOwner(scheduleMeeting, getOwner(this)!);
          await scheduleMeeting.execute(
            new ScheduleMeetingInput({
              topic: 'Meeting with Hassan',
              participants: [this.args.model],
            }),
          );
        };
        <template>
          <h2 data-test-person={{@model.firstName}}>
            <@fields.firstName />
          </h2>
          <p data-test-first-letter-of-the-name={{@model.firstLetterOfTheName}}>
            <@fields.firstLetterOfTheName />
          </p>
          Pet:
          <@fields.pet />
          Friends:
          <@fields.friends />
          <button
            {{on
              'click'
              (fn this.runSwitchToCodeModeCommandViaAiAssistant true)
            }}
            data-test-switch-to-code-mode-with-autoexecute-button
          >Switch to code-mode with autoExecute</button>
          <button
            {{on
              'click'
              (fn this.runSwitchToCodeModeCommandViaAiAssistant false)
            }}
            data-test-switch-to-code-mode-without-autoexecute-button
          >Switch to code-mode (no autoExecute)</button>
          <button
            {{on 'click' (fn this.runScheduleMeetingCommand)}}
            data-test-schedule-meeting-button
          >Schedule meeting</button>
        </template>
      };
    }
    let mangoPet = new Pet({ name: 'Mango' });

    await setupAcceptanceTestRealm({
      contents: {
        'person.gts': { Person, Meeting },
        'pet.gts': { Pet },
        'Pet/ringo.json': new Pet({ name: 'Ringo' }),
        'Person/hassan.json': new Person({
          firstName: 'Hassan',
          lastName: 'Abdel-Rahman',
          pet: mangoPet,
          friends: [mangoPet],
        }),
        'Pet/mango.json': mangoPet,
        'Pet/vangogh.json': new Pet({ name: 'Van Gogh' }),
        'Person/fadhlan.json': new Person({
          firstName: 'Fadhlan',
          pet: mangoPet,
          friends: [mangoPet],
        }),
        'index.json': new CardsGrid(),
        '.realm.json': {
          name: 'Test Workspace B',
          backgroundURL:
            'https://i.postimg.cc/VNvHH93M/pawel-czerwinski-Ly-ZLa-A5jti-Y-unsplash.jpg',
          iconURL: 'https://i.postimg.cc/L8yXRvws/icon.png',
        },
      },
    });
  });

  test('a command sent via sendAiAssistantMessage with autoExecute flag is automatically executed by the bot', async function (assert) {
    await visitOperatorMode({
      stacks: [
        [
          {
            id: `${testRealmURL}index`,
            format: 'isolated',
          },
        ],
      ],
    });
    const testCard = `${testRealmURL}Person/hassan`;

    await click('[data-test-boxel-filter-list-button="All Cards"]');
    await click(
      `[data-test-stack-card="${testRealmURL}index"] [data-test-cards-grid-item="${testCard}"]`,
    );
    await click('[data-test-switch-to-code-mode-with-autoexecute-button]');
    await waitUntil(() => getRoomIds().length > 0);
    let roomId = getRoomIds()[0];
    let message = getRoomEvents(roomId).pop()!;
    assert.strictEqual(message.content.msgtype, 'org.boxel.message');
    let boxelMessageData = message.content.data;
    assert.strictEqual(boxelMessageData.context.tools.length, 1);
    assert.strictEqual(boxelMessageData.context.tools[0].type, 'function');
    let toolName = boxelMessageData.context.tools[0].function.name;
    assert.ok(
      /^SwitchSubmodeCommand_/.test(toolName),
      'The function name start with SwitchSubmodeCommand_',
    );
    assert.strictEqual(
      boxelMessageData.context.tools[0].function.description,
      'Navigate the UI to another submode. Possible values for submode are "interact" and "code".',
    );
    // TODO: do we need to include `required: ['attributes'],` in the parameters object? If so, how?
    assert.deepEqual(boxelMessageData.context.tools[0].function.parameters, {
      type: 'object',
      properties: {
        attributes: {
          type: 'object',
          properties: {
            submode: {
              type: 'string',
            },
            title: {
              type: 'string',
            },
            description: {
              type: 'string',
            },
            thumbnailURL: {
              type: 'string',
            },
          },
        },
        relationships: {
          properties: {},
          required: [],
          type: 'object',
        },
      },
    });
    simulateRemoteMessage(roomId, '@aibot:localhost', {
      body: 'Switching to code submode',
      msgtype: 'org.boxel.command',
      formatted_body: 'Switching to code submode',
      format: 'org.matrix.custom.html',
      data: JSON.stringify({
        toolCall: {
          name: toolName,
          arguments: {
            submode: 'code',
          },
        },
        eventId: '__EVENT_ID__',
      }),
      'm.relates_to': {
        rel_type: 'm.replace',
        event_id: '__EVENT_ID__',
      },
    });
    await waitFor('[data-test-submode-switcher=code]');
    assert.dom('[data-test-submode-switcher=code]').exists();
    assert.dom('[data-test-card-url-bar-input]').hasValue(`${testCard}.json`);
    await click('[data-test-submode-switcher] button');
    await click('[data-test-boxel-menu-item-text="Interact"]');
    await click('[data-test-open-ai-assistant]');
    assert
      .dom(
        '[data-test-message-idx="0"][data-test-boxel-message-from="testuser"]',
      )
      .containsText('Switch to code mode');
    assert
      .dom('[data-test-message-idx="1"][data-test-boxel-message-from="aibot"]')
      .containsText('Switching to code submode');
    assert
      .dom('[data-test-message-idx="1"] [data-test-apply-state="applied"]')
      .exists();
  });

  test('a command sent via sendAiAssistantMessage without autoExecute flag is not automatically executed by the bot', async function (assert) {
    await visitOperatorMode({
      stacks: [
        [
          {
            id: `${testRealmURL}index`,
            format: 'isolated',
          },
        ],
      ],
    });
    const testCard = `${testRealmURL}Person/hassan`;

    await click('[data-test-boxel-filter-list-button="All Cards"]');
    await click(
      `[data-test-stack-card="${testRealmURL}index"] [data-test-cards-grid-item="${testCard}"]`,
    );
    await click('[data-test-switch-to-code-mode-without-autoexecute-button]');
    await waitUntil(() => getRoomIds().length > 0);
    let roomId = getRoomIds()[0];
    let message = getRoomEvents(roomId).pop()!;
    assert.strictEqual(message.content.msgtype, 'org.boxel.message');
    let boxelMessageData = message.content.data;
    assert.strictEqual(boxelMessageData.context.tools.length, 1);
    assert.strictEqual(boxelMessageData.context.tools[0].type, 'function');
    let toolName = boxelMessageData.context.tools[0].function.name;
    assert.ok(
      /^SwitchSubmodeCommand_/.test(toolName),
      'The function name start with SwitchSubmodeCommand_',
    );
    assert.strictEqual(
      boxelMessageData.context.tools[0].function.description,
      'Navigate the UI to another submode. Possible values for submode are "interact" and "code".',
    );
    // TODO: do we need to include `required: ['attributes'],` in the parameters object? If so, how?
    assert.deepEqual(boxelMessageData.context.tools[0].function.parameters, {
      type: 'object',
      properties: {
        attributes: {
          type: 'object',
          properties: {
            submode: {
              type: 'string',
            },
            title: {
              type: 'string',
            },
            description: {
              type: 'string',
            },
            thumbnailURL: {
              type: 'string',
            },
          },
        },
        relationships: {
          properties: {},
          required: [],
          type: 'object',
        },
      },
    });
    simulateRemoteMessage(roomId, '@aibot:localhost', {
      body: 'Switching to code submode',
      msgtype: 'org.boxel.command',
      formatted_body: 'Switching to code submode',
      format: 'org.matrix.custom.html',
      data: JSON.stringify({
        toolCall: {
          name: toolName,
          arguments: {
            submode: 'code',
          },
        },
        eventId: '__EVENT_ID__',
      }),
      'm.relates_to': {
        rel_type: 'm.replace',
        event_id: '__EVENT_ID__',
      },
    });
    await delay(500);
    assert.dom('[data-test-submode-switcher=interact]').exists();
    await click('[data-test-open-ai-assistant]');
    assert
      .dom(
        '[data-test-message-idx="0"][data-test-boxel-message-from="testuser"]',
      )
      .containsText('Switch to code mode');
    assert
      .dom('[data-test-message-idx="1"][data-test-boxel-message-from="aibot"]')
      .containsText('Switching to code submode');
    assert
      .dom('[data-test-message-idx="1"] [data-test-apply-state="ready"]')
      .exists();
    await click('[data-test-message-idx="1"] [data-test-command-apply]');
    await waitFor('[data-test-submode-switcher=code]');
    assert.dom('[data-test-submode-switcher=code]').exists();
    assert.dom('[data-test-card-url-bar-input]').hasValue(`${testCard}.json`);
    await click('[data-test-submode-switcher] button');
    await click('[data-test-boxel-menu-item-text="Interact"]');
    await click('[data-test-open-ai-assistant]');
    assert
      .dom(
        '[data-test-message-idx="0"][data-test-boxel-message-from="testuser"]',
      )
      .containsText('Switch to code mode');
    assert
      .dom('[data-test-message-idx="1"][data-test-boxel-message-from="aibot"]')
      .containsText('Switching to code submode');
    assert
      .dom('[data-test-message-idx="1"] [data-test-apply-state="applied"]')
      .exists();
  });

  test('a scripted command can create a card, update it and show it', async function (assert) {
    await visitOperatorMode({
      stacks: [
        [
          {
            id: `${testRealmURL}index`,
            format: 'isolated',
          },
        ],
      ],
    });
    const testCard = `${testRealmURL}Person/hassan`;

    await click('[data-test-boxel-filter-list-button="All Cards"]');
    await click(
      `[data-test-stack-card="${testRealmURL}index"] [data-test-cards-grid-item="${testCard}"]`,
    );
    await click('[data-test-schedule-meeting-button]');
    await waitUntil(() => getRoomIds().length > 0);
    let roomId = getRoomIds()[0];
    let message = getRoomEvents(roomId).pop()!;
    assert.strictEqual(message.content.msgtype, 'org.boxel.message');
    let boxelMessageData = message.content.data;
    assert.strictEqual(boxelMessageData.context.tools.length, 1);
    assert.strictEqual(boxelMessageData.context.tools[0].type, 'function');
    let toolName = boxelMessageData.context.tools[0].function.name;
    let meetingCardEventId = boxelMessageData.attachedCardsEventIds[0];
    console.log('meetingCardEventId', meetingCardEventId);
    console.log('getRoomEvents(roomId)', getRoomEvents(roomId));
    console.log(
      getRoomEvents(roomId).find(
        (event) => event.event_id === meetingCardEventId,
      ),
    );
    let cardFragment = getRoomEvents(roomId).find(
      (event) => event.event_id === meetingCardEventId,
    )!.content.data.cardFragment;

    let parsedCard = JSON.parse(cardFragment);
    let meetingCardId = parsedCard.data.id;
    console.log('meetingCardId', meetingCardId);

    simulateRemoteMessage(roomId, '@aibot:localhost', {
      body: 'Update card',
      msgtype: 'org.boxel.command',
      formatted_body: 'Update card',
      format: 'org.matrix.custom.html',
      data: JSON.stringify({
        toolCall: {
          name: toolName,
          arguments: {
            cardId: meetingCardId,
            patch: {
              attributes: {
                topic: 'Meeting with Hassan',
              },
            },
          },
        },
        eventId: '__EVENT_ID__',
      }),
      'm.relates_to': {
        rel_type: 'm.replace',
        event_id: '__EVENT_ID__',
      },
    });

    await waitUntil(
      () => findAll('[data-test-operator-mode-stack]').length === 2,
    );

    assert.dom('[data-test-operator-mode-stack]').exists({ count: 2 });

    assert
      .dom(
        '[data-test-operator-mode-stack="1"] [data-test-stack-card-index="0"]',
      )
      .includesText('Meeting with Hassan');
  });
});

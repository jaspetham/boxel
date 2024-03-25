import { module, test } from 'qunit';

import {
  IndexerDBClient,
  asExpressions,
  addExplicitParens,
  separatedByCommas,
  internalKeyFor,
  baseCardRef,
  type IndexedCardsTable,
  type RealmVersionsTable,
  type LooseCardResource,
} from '@cardstack/runtime-common';

import ENV from '@cardstack/host/config/environment';
import SQLiteAdapter from '@cardstack/host/lib/SQLiteAdapter';

import { testRealmURL } from '../helpers';
const testRealmURL2 = `http://test-realm/test2/`;

let { sqlSchema } = ENV;

// TODO move this into a helper
async function setupIndex(
  client: IndexerDBClient,
  versionRows: RealmVersionsTable[],
  // only assert that the non-null columns need to be present in rows objects
  indexRows: (Pick<
    IndexedCardsTable,
    'card_url' | 'realm_version' | 'realm_url'
  > &
    Partial<
      Omit<IndexedCardsTable, 'card_url' | 'realm_version' | 'realm_url'>
    >)[],
) {
  let indexedCardsExpressions = indexRows.map((r) =>
    asExpressions(r, {
      jsonFields: ['deps', 'types', 'pristine_doc', 'error_doc', 'search_doc'],
    }),
  );
  let versionExpressions = versionRows.map((r) => asExpressions(r));

  if (indexedCardsExpressions.length > 0) {
    await client.query([
      `INSERT INTO indexed_cards`,
      ...addExplicitParens(
        separatedByCommas(indexedCardsExpressions[0].nameExpressions),
      ),
      'VALUES',
      ...separatedByCommas(
        indexedCardsExpressions.map((row) =>
          addExplicitParens(separatedByCommas(row.valueExpressions)),
        ),
      ),
    ]);
  }

  if (versionExpressions.length > 0) {
    await client.query([
      `INSERT INTO realm_versions`,
      ...addExplicitParens(
        separatedByCommas(versionExpressions[0].nameExpressions),
      ),
      'VALUES',
      ...separatedByCommas(
        versionExpressions.map((row) =>
          addExplicitParens(separatedByCommas(row.valueExpressions)),
        ),
      ),
    ]);
  }
}

module('Unit | index-db', function (hooks) {
  let adapter: SQLiteAdapter;
  let client: IndexerDBClient;

  hooks.beforeEach(async function () {
    adapter = new SQLiteAdapter(sqlSchema);
    client = new IndexerDBClient(adapter);
    await client.ready();
  });

  hooks.afterEach(async function () {
    await client.teardown();
  });

  test('can perform invalidations for an index entry', async function (assert) {
    await setupIndex(
      client,
      [
        { realm_url: testRealmURL, current_version: 1 },
        { realm_url: testRealmURL2, current_version: 5 },
      ],
      [
        {
          card_url: `${testRealmURL}1.json`,
          realm_version: 1,
          realm_url: testRealmURL,
          deps: [`${testRealmURL}2.json`],
        },
        {
          card_url: `${testRealmURL}2.json`,
          realm_version: 1,
          realm_url: testRealmURL,
          deps: [`${testRealmURL}4.json`],
        },
        {
          card_url: `${testRealmURL}3.json`,
          realm_version: 1,
          realm_url: testRealmURL,
          deps: [`${testRealmURL}2.json`],
        },
        {
          card_url: `${testRealmURL}4.json`,
          realm_version: 1,
          realm_url: testRealmURL,
          deps: [],
        },
        {
          card_url: `${testRealmURL}5.json`,
          realm_version: 1,
          realm_url: testRealmURL,
          deps: [],
        },
        {
          card_url: `${testRealmURL2}A.json`,
          realm_version: 5,
          realm_url: testRealmURL2,
          deps: [],
        },
      ],
    );

    let batch = await client.createBatch(new URL(testRealmURL));
    let invalidations = await batch.invalidate(
      new URL(`${testRealmURL}4.json`),
    );

    assert.deepEqual(invalidations.sort(), [
      `${testRealmURL}1.json`,
      `${testRealmURL}2.json`,
      `${testRealmURL}3.json`,
      `${testRealmURL}4.json`,
    ]);

    let originalEntries = await adapter.execute(
      'SELECT card_url, realm_url, is_deleted FROM indexed_cards WHERE realm_version = 1 ORDER BY card_url',
      { coerceTypes: { is_deleted: 'BOOLEAN' } },
    );
    assert.deepEqual(
      originalEntries,
      [1, 2, 3, 4, 5].map((i) => ({
        card_url: `${testRealmURL}${i}.json`,
        realm_url: testRealmURL,
        is_deleted: null,
      })),
      'the "production" version of the index entries are unchanged',
    );
    let invalidatedEntries = await adapter.execute(
      'SELECT card_url, realm_url, is_deleted FROM indexed_cards WHERE realm_version = 2 ORDER BY card_url',
      { coerceTypes: { is_deleted: 'BOOLEAN' } },
    );
    assert.deepEqual(
      invalidatedEntries,
      [1, 2, 3, 4].map((i) => ({
        card_url: `${testRealmURL}${i}.json`,
        realm_url: testRealmURL,
        is_deleted: true,
      })),
      'the "work-in-progress" version of the index entries have been marked as deleted',
    );
    let otherRealms = await adapter.execute(
      `SELECT card_url, realm_url, realm_version, is_deleted FROM indexed_cards WHERE realm_url != '${testRealmURL}'`,
      { coerceTypes: { is_deleted: 'BOOLEAN' } },
    );
    assert.deepEqual(
      otherRealms,
      [
        {
          card_url: `${testRealmURL2}A.json`,
          realm_url: testRealmURL2,
          realm_version: 5,
          is_deleted: null,
        },
      ],
      'the index entries from other realms are unchanged',
    );
    let realmVersions = await adapter.execute(
      'select * from realm_versions ORDER BY realm_url',
    );
    assert.deepEqual(
      realmVersions,
      [
        {
          realm_url: `${testRealmURL}`,
          current_version: 1,
        },
        {
          realm_url: `${testRealmURL2}`,
          current_version: 5,
        },
      ],
      'the "production" realm versions are correct',
    );
  });

  test('does not create invalidation record for non-JSON invalidation', async function (assert) {
    await setupIndex(
      client,
      [{ realm_url: testRealmURL, current_version: 1 }],
      [],
    );
    let batch = await client.createBatch(new URL(testRealmURL));
    let invalidations = await batch.invalidate(
      new URL(`${testRealmURL}module`),
    );
    assert.deepEqual(invalidations.sort(), [`${testRealmURL}module`]);
    let entries = await adapter.execute('SELECT card_url FROM indexed_cards');
    assert.deepEqual(
      entries,
      [],
      'an index entry was not created for a non-JSON URL',
    );
  });

  test('can prevent concurrent batch invalidations from colliding', async function (assert) {
    await setupIndex(
      client,
      [{ realm_url: testRealmURL, current_version: 1 }],
      [
        {
          card_url: `${testRealmURL}1.json`,
          realm_version: 1,
          realm_url: testRealmURL,
          deps: [],
        },
        {
          card_url: `${testRealmURL}2.json`,
          realm_version: 1,
          realm_url: testRealmURL,
          deps: [`${testRealmURL}1.json`],
        },
        {
          card_url: `${testRealmURL}3.json`,
          realm_version: 1,
          realm_url: testRealmURL,
          deps: [`${testRealmURL}1.json`],
        },
      ],
    );

    // both batches have the same WIP version number
    let batch1 = await client.createBatch(new URL(testRealmURL));
    let batch2 = await client.createBatch(new URL(testRealmURL));
    await batch1.invalidate(new URL(`${testRealmURL}1.json`));

    try {
      await batch2.invalidate(new URL(`${testRealmURL}3.json`));
      throw new Error(`expected invalidation conflict error`);
    } catch (e: any) {
      assert.ok(
        e.message.includes(
          'Invalidation conflict error in realm http://test-realm/test/ version 2',
        ),
        'received invalidation conflict error',
      );
    }
  });

  test('can prevent concurrent batch invalidations from colliding when making new generation', async function (assert) {
    await setupIndex(
      client,
      [{ realm_url: testRealmURL, current_version: 1 }],
      [
        {
          card_url: `${testRealmURL}1.json`,
          realm_version: 1,
          realm_url: testRealmURL,
          deps: [],
        },
      ],
    );

    // both batches have the same WIP version number
    let batch1 = await client.createBatch(new URL(testRealmURL));
    let batch2 = await client.createBatch(new URL(testRealmURL));
    await batch1.invalidate(new URL(`${testRealmURL}1.json`));

    try {
      await batch2.makeNewGeneration();
      throw new Error(`expected invalidation conflict error`);
    } catch (e: any) {
      assert.ok(
        e.message.includes(
          'Invalidation conflict error in realm http://test-realm/test/ version 2',
        ),
        'received invalidation conflict error',
      );
    }
  });

  test('can update an index entry', async function (assert) {
    await setupIndex(
      client,
      [{ realm_url: testRealmURL, current_version: 1 }],
      [
        {
          card_url: `${testRealmURL}1.json`,
          realm_version: 1,
          realm_url: testRealmURL,
          pristine_doc: {
            id: `${testRealmURL}1.json`,
            type: 'card',
            attributes: {
              name: 'Mango',
            },
            meta: {
              adoptsFrom: {
                module: `./person`,
                name: 'Person',
              },
            },
          } as LooseCardResource,
          search_doc: { name: 'Mango' },
          deps: [`${testRealmURL}person`],
          types: [{ module: `./person`, name: 'Person' }, baseCardRef].map(
            (i) => internalKeyFor(i, new URL(testRealmURL)),
          ),
        },
      ],
    );

    let batch = await client.createBatch(new URL(testRealmURL));
    await batch.invalidate(new URL(`${testRealmURL}1.json`));
    await batch.updateEntry(new URL(`${testRealmURL}1.json`), {
      type: 'entry',
      entry: {
        resource: {
          id: `${testRealmURL}1.json`,
          type: 'card',
          attributes: {
            name: 'Van Gogh',
          },
          meta: {
            adoptsFrom: {
              module: `./fancy-person`,
              name: 'FancyPerson',
            },
          },
        },
        searchData: { name: 'Van Gogh' },
        deps: new Set([`${testRealmURL}fancy-person`]),
        types: [
          { module: `./fancy-person`, name: 'FancyPerson' },
          { module: `./person`, name: 'Person' },
          baseCardRef,
        ].map((i) => internalKeyFor(i, new URL(testRealmURL))),
      },
    });

    let versions = await adapter.execute(
      `SELECT realm_version, pristine_doc, search_doc, deps, types FROM indexed_cards WHERE card_url = $1 ORDER BY realm_version`,
      {
        bind: [`${testRealmURL}1.json`],
        coerceTypes: {
          pristine_doc: 'JSON',
          search_doc: 'JSON',
          deps: 'JSON',
          types: 'JSON',
        },
      },
    );
    assert.strictEqual(
      versions.length,
      2,
      'correct number of versions exist for the entry before finishing the batch',
    );

    let [liveVersion, wipVersion] = versions;
    assert.deepEqual(
      liveVersion,
      {
        realm_version: 1,
        pristine_doc: {
          id: `${testRealmURL}1.json`,
          type: 'card',
          attributes: {
            name: 'Mango',
          },
          meta: {
            adoptsFrom: {
              module: `./person`,
              name: 'Person',
            },
          },
        },
        search_doc: { name: 'Mango' },
        deps: [`${testRealmURL}person`],
        types: [{ module: `./person`, name: 'Person' }, baseCardRef].map((i) =>
          internalKeyFor(i, new URL(testRealmURL)),
        ),
      },
      'live version of the doc has not changed',
    );
    assert.deepEqual(
      wipVersion,
      {
        realm_version: 2,
        pristine_doc: {
          id: `${testRealmURL}1.json`,
          type: 'card',
          attributes: {
            name: 'Van Gogh',
          },
          meta: {
            adoptsFrom: {
              module: `./fancy-person`,
              name: 'FancyPerson',
            },
          },
        },
        search_doc: { name: 'Van Gogh' },
        deps: [`${testRealmURL}fancy-person`],
        types: [
          { module: `./fancy-person`, name: 'FancyPerson' },
          { module: `./person`, name: 'Person' },
          baseCardRef,
        ].map((i) => internalKeyFor(i, new URL(testRealmURL))),
      },
      'WIP version of the doc exists',
    );

    await batch.done();

    versions = await adapter.execute(
      `SELECT realm_version, pristine_doc, search_doc, deps, types FROM indexed_cards WHERE card_url = $1 ORDER BY realm_version`,
      {
        bind: [`${testRealmURL}1.json`],
        coerceTypes: {
          pristine_doc: 'JSON',
          search_doc: 'JSON',
          deps: 'JSON',
          types: 'JSON',
        },
      },
    );
    assert.strictEqual(
      versions.length,
      1,
      'correct number of versions exist for the entry after finishing the batch',
    );

    let [finalVersion] = versions;
    assert.deepEqual(
      finalVersion,
      {
        realm_version: 2,
        pristine_doc: {
          id: `${testRealmURL}1.json`,
          type: 'card',
          attributes: {
            name: 'Van Gogh',
          },
          meta: {
            adoptsFrom: {
              module: `./fancy-person`,
              name: 'FancyPerson',
            },
          },
        },
        search_doc: { name: 'Van Gogh' },
        deps: [`${testRealmURL}fancy-person`],
        types: [
          { module: `./fancy-person`, name: 'FancyPerson' },
          { module: `./person`, name: 'Person' },
          baseCardRef,
        ].map((i) => internalKeyFor(i, new URL(testRealmURL))),
      },
      'final version of the doc exists',
    );
  });

  test('can remove an index entry', async function (assert) {
    await setupIndex(
      client,
      [{ realm_url: testRealmURL, current_version: 1 }],
      [
        {
          card_url: `${testRealmURL}1.json`,
          realm_version: 1,
          realm_url: testRealmURL,
          deps: [],
        },
      ],
    );
    let batch = await client.createBatch(new URL(testRealmURL));
    await batch.invalidate(new URL(`${testRealmURL}1.json`));
    await batch.deleteEntry(new URL(`${testRealmURL}1.json`));

    let versions = await adapter.execute(
      `SELECT realm_version, is_deleted FROM indexed_cards WHERE card_url = $1 ORDER BY realm_version`,
      {
        bind: [`${testRealmURL}1.json`],
        coerceTypes: {
          is_deleted: 'BOOLEAN',
        },
      },
    );
    assert.strictEqual(
      versions.length,
      2,
      'correct number of versions exist for the entry before finishing the batch',
    );

    let [liveVersion, wipVersion] = versions;
    assert.deepEqual(
      liveVersion,
      {
        realm_version: 1,
        is_deleted: null,
      },
      'live version of the doc has not changed',
    );

    assert.deepEqual(
      wipVersion,
      {
        realm_version: 2,
        is_deleted: true,
      },
      'WIP version of the doc exists',
    );

    await batch.done();
    versions = await adapter.execute(
      `SELECT realm_version, is_deleted FROM indexed_cards WHERE card_url = $1 ORDER BY realm_version`,
      {
        bind: [`${testRealmURL}1.json`],
        coerceTypes: {
          is_deleted: 'BOOLEAN',
        },
      },
    );
    assert.strictEqual(
      versions.length,
      1,
      'correct number of versions exist for the entry after finishing the batch',
    );

    let [finalVersion] = versions;
    assert.deepEqual(
      finalVersion,
      { realm_version: 2, is_deleted: true },
      'final version of the doc exists',
    );
  });

  test('can create a new generation of index entries', async function (assert) {
    await setupIndex(
      client,
      [{ realm_url: testRealmURL, current_version: 1 }],
      [
        {
          card_url: `${testRealmURL}1.json`,
          realm_version: 1,
          realm_url: testRealmURL,
        },
        {
          card_url: `${testRealmURL}2.json`,
          realm_version: 1,
          realm_url: testRealmURL,
        },
        {
          card_url: `${testRealmURL}3.json`,
          realm_version: 1,
          realm_url: testRealmURL,
        },
        {
          card_url: `${testRealmURL2}A.json`,
          realm_version: 5,
          realm_url: testRealmURL2,
        },
      ],
    );

    let batch = await client.createBatch(new URL(testRealmURL));
    await batch.makeNewGeneration();

    let index = await adapter.execute(
      'SELECT card_url, realm_url, realm_version, is_deleted FROM indexed_cards ORDER BY card_url, realm_version',
      { coerceTypes: { is_deleted: 'BOOLEAN' } },
    );
    assert.deepEqual(
      index,
      [
        {
          card_url: `${testRealmURL}1.json`,
          realm_url: testRealmURL,
          realm_version: 1,
          is_deleted: null,
        },
        {
          card_url: `${testRealmURL}1.json`,
          realm_url: testRealmURL,
          realm_version: 2,
          is_deleted: true,
        },
        {
          card_url: `${testRealmURL}2.json`,
          realm_version: 1,
          realm_url: testRealmURL,
          is_deleted: null,
        },
        {
          card_url: `${testRealmURL}2.json`,
          realm_version: 2,
          realm_url: testRealmURL,
          is_deleted: true,
        },
        {
          card_url: `${testRealmURL}3.json`,
          realm_version: 1,
          realm_url: testRealmURL,
          is_deleted: null,
        },
        {
          card_url: `${testRealmURL}3.json`,
          realm_version: 2,
          realm_url: testRealmURL,
          is_deleted: true,
        },
        {
          card_url: `${testRealmURL2}A.json`,
          realm_version: 5,
          realm_url: testRealmURL2,
          is_deleted: null,
        },
      ],
      'the WIP next generation index entries have been added',
    );

    // in this next generation only 1 card happened to be visited
    await batch.updateEntry(new URL(`${testRealmURL}1.json`), {
      type: 'entry',
      entry: {
        resource: {
          id: `${testRealmURL}1.json`,
          type: 'card',
          attributes: {
            name: 'Van Gogh',
          },
          meta: {
            adoptsFrom: {
              module: `./person`,
              name: 'Person',
            },
          },
        },
        searchData: { name: 'Van Gogh' },
        deps: new Set(),
        types: [],
      },
    });

    await batch.done();
    index = await adapter.execute(
      'SELECT card_url, realm_url, realm_version, is_deleted FROM indexed_cards ORDER BY card_url, realm_version',
      { coerceTypes: { is_deleted: 'BOOLEAN' } },
    );
    assert.deepEqual(
      index,
      [
        {
          card_url: `${testRealmURL}1.json`,
          realm_url: testRealmURL,
          realm_version: 2,
          is_deleted: false,
        },
        {
          card_url: `${testRealmURL}2.json`,
          realm_version: 2,
          realm_url: testRealmURL,
          is_deleted: true,
        },
        {
          card_url: `${testRealmURL}3.json`,
          realm_version: 2,
          realm_url: testRealmURL,
          is_deleted: true,
        },
        {
          card_url: `${testRealmURL2}A.json`,
          realm_version: 5,
          realm_url: testRealmURL2,
          is_deleted: null,
        },
      ],
      'the old generation index entries have been pruned',
    );
  });

  test('can get "production" index entry', async function (assert) {
    await setupIndex(
      client,
      [{ realm_url: testRealmURL, current_version: 1 }],
      [
        {
          card_url: `${testRealmURL}1.json`,
          realm_version: 1,
          realm_url: testRealmURL,
          pristine_doc: {
            attributes: {
              name: 'Mango',
            },
            meta: {
              adoptsFrom: {
                module: `./person`,
                name: 'Person',
              },
            },
          } as LooseCardResource,
        },
      ],
    );

    let batch = await client.createBatch(new URL(testRealmURL));
    await batch.invalidate(new URL(`${testRealmURL}1.json`));
    await batch.updateEntry(new URL(`${testRealmURL}1.json`), {
      type: 'entry',
      entry: {
        resource: {
          id: `${testRealmURL}1.json`,
          type: 'card',
          attributes: {
            name: 'Van Gogh',
          },
          meta: {
            adoptsFrom: {
              module: `./person`,
              name: 'Person',
            },
          },
        },
        searchData: { name: 'Van Gogh' },
        deps: new Set(),
        types: [],
      },
    });

    let entry = await client.getIndexEntry(new URL(`${testRealmURL}1`));
    assert.deepEqual(entry, {
      card_url: `${testRealmURL}1.json`,
      realm_version: 1,
      realm_url: testRealmURL,
      pristine_doc: {
        attributes: {
          name: 'Mango',
        },
        meta: {
          adoptsFrom: {
            module: `./person`,
            name: 'Person',
          },
        },
      },
      is_deleted: null,
      error_doc: null,
      search_doc: null,
      deps: null,
      types: null,
      indexed_at: null,
      isolated_html: null,
      embedded_html: null,
    });
  });

  test('can get work in progress index entry', async function (assert) {
    await setupIndex(
      client,
      [{ realm_url: testRealmURL, current_version: 1 }],
      [
        {
          card_url: `${testRealmURL}1.json`,
          realm_version: 1,
          realm_url: testRealmURL,
          pristine_doc: {
            attributes: {
              name: 'Mango',
            },
            meta: {
              adoptsFrom: {
                module: `./person`,
                name: 'Person',
              },
            },
          } as LooseCardResource,
        },
      ],
    );

    let batch = await client.createBatch(new URL(testRealmURL));
    await batch.invalidate(new URL(`${testRealmURL}1.json`));
    await batch.updateEntry(new URL(`${testRealmURL}1.json`), {
      type: 'entry',
      entry: {
        resource: {
          id: `${testRealmURL}1.json`,
          type: 'card',
          attributes: {
            name: 'Van Gogh',
          },
          meta: {
            adoptsFrom: {
              module: `./person`,
              name: 'Person',
            },
          },
        },
        searchData: { name: 'Van Gogh' },
        deps: new Set(),
        types: [],
      },
    });

    let entry = await client.getIndexEntry(new URL(`${testRealmURL}1`), {
      useWorkInProgressIndex: true,
    });
    assert.ok(entry?.indexed_at, 'the indexed_at field was set');
    delete (entry as Partial<IndexedCardsTable>)?.indexed_at;
    assert.deepEqual(entry as Partial<IndexedCardsTable>, {
      card_url: `${testRealmURL}1.json`,
      realm_version: 2,
      realm_url: testRealmURL,
      pristine_doc: {
        id: `${testRealmURL}1.json`,
        type: 'card',
        attributes: {
          name: 'Van Gogh',
        },
        meta: {
          adoptsFrom: {
            module: `./person`,
            name: 'Person',
          },
        },
      },
      is_deleted: false,
      error_doc: null,
      search_doc: { name: 'Van Gogh' },
      deps: [],
      types: [],
      isolated_html: null,
      embedded_html: null,
    });
  });

  test('returns undefined when getting a deleted entry', async function (assert) {
    await setupIndex(
      client,
      [{ realm_url: testRealmURL, current_version: 1 }],
      [
        {
          card_url: `${testRealmURL}1.json`,
          realm_version: 1,
          realm_url: testRealmURL,
          is_deleted: true,
        },
      ],
    );

    let entry = await client.getIndexEntry(new URL(`${testRealmURL}1`));
    assert.strictEqual(entry, undefined, 'deleted entries return undefined');
  });
});

import { test, expect } from '@playwright/test';
import {
  synapseStart,
  synapseStop,
  registerUser,
  type SynapseInstance,
} from '../docker/synapse';
import { assertLoggedIn, assertLoggedOut } from '../helpers';

test.describe('Login', () => {
  let synapse: SynapseInstance;
  test.beforeEach(async () => {
    synapse = await synapseStart();
    await registerUser(synapse, 'user1', 'pass');
  });

  test.afterEach(async () => {
    await synapseStop(synapse.synapseId);
  });

  test('it can login', async ({ page }) => {
    await page.goto(`/chat`);

    await assertLoggedOut(page);
    await expect(page.locator('[data-test-login-btn]')).toBeDisabled();
    await page.locator('[data-test-username-field]').fill('user1');
    await expect(page.locator('[data-test-login-btn]')).toBeDisabled();
    await page.locator('[data-test-password-field]').fill('pass');
    await expect(page.locator('[data-test-login-btn]')).toBeEnabled();
    await page.locator('[data-test-login-btn]').click();

    await assertLoggedIn(page);

    // edit the display name to show that our access token works
    await page.locator('[data-test-profile-edit-btn]').click();
    await page.locator('[data-test-displayName-field]').fill('New Name');
    await page.locator('[data-test-profile-save-btn]').click();
    await expect(
      page.locator('[data-test-field-value="displayName"]')
    ).toContainText('New Name');

    // reload to page to show that the access token persists
    await page.reload();
    await assertLoggedIn(page, { displayName: 'New Name' });
  });

  test('it can logout', async ({ page }) => {
    await page.goto(`/chat`);
    await page.locator('[data-test-username-field]').fill('user1');
    await page.locator('[data-test-password-field]').fill('pass');
    await page.locator('[data-test-login-btn]').click();
    await assertLoggedIn(page);

    await page.locator('[data-test-logout-btn]').click();
    assertLoggedOut(page);

    // reload to page to show that the logout state persists
    await page.reload();
    await assertLoggedOut(page);
  });

  test('it shows an error when invalid credentials are provided', async ({
    page,
  }) => {
    await page.goto(`/chat`);
    await page.locator('[data-test-username-field]').fill('user1');
    await page.locator('[data-test-password-field]').fill('bad pass');

    await expect(
      page.locator('[data-test-login-error]'),
      'login error message is not displayed'
    ).toHaveCount(0);
    await page.locator('[data-test-login-btn]').click();
    await expect(page.locator('[data-test-login-error]')).toContainText(
      'Invalid username or password'
    );

    await page.locator('[data-test-password-field]').fill('pass');
    await expect(
      page.locator('[data-test-login-error]'),
      'login error message is not displayed'
    ).toHaveCount(0);
    await page.locator('[data-test-login-btn]').click();

    await assertLoggedIn(page);
  });
});

exports.up = (pgm) => {
  pgm.createTable('users', {
    id: {
      type: 'serial',
      primaryKey: true,
    },
    matrix_user_id: { type: 'varchar', notNull: true, unique: true },
    stripe_customer_id: { type: 'varchar' },
    created_at: {
      type: 'timestamp',
      notNull: true,
      default: pgm.func('current_timestamp'),
    },
  });

  pgm.createTable('plans', {
    id: {
      type: 'serial',
      primaryKey: true,
    },
    name: { type: 'varchar', notNull: true },
    monthly_price: { type: 'numeric(19,4)', notNull: true },
    credits_included: { type: 'integer', notNull: true },
    overage_fee_per_credit_in_usd: { type: 'numeric(19,4)' },
    created_at: {
      type: 'timestamp',
      notNull: true,
      default: pgm.func('current_timestamp'),
    },
  });

  pgm.createTable('subscription_cycles', {
    id: {
      type: 'serial',
      primaryKey: true,
    },
    subscription_id: { type: 'integer' },
    period_start: { type: 'timestamp', notNull: true },
    period_end: { type: 'timestamp', notNull: true },
  });

  pgm.createTable('subscriptions', {
    id: {
      type: 'serial',
      primaryKey: true,
    },
    user_id: { type: 'integer', references: 'users(id)' },
    plan_id: { type: 'integer', references: 'plans(id)' },
    started_at: { type: 'timestamp', notNull: true },
    ended_at: { type: 'timestamp', notNull: true },
    status: { type: 'varchar', notNull: true },
    stripe_subscription_id: { type: 'varchar', notNull: true },
    current_subscription_cycle_id: {
      type: 'integer',
      references: 'subscription_cycles(id)',
    },
  });

  pgm.addConstraint(
    'subscription_cycles',
    'subscription_cycles_subscription_id_fkey',
    {
      foreignKeys: {
        columns: 'subscription_id',
        references: 'subscriptions(id)',
      },
    },
  );

  pgm.createTable('ai_actions', {
    id: {
      type: 'serial',
      primaryKey: true,
    },
    action_type: { type: 'varchar', notNull: true },
    user_id: { type: 'integer', references: 'users(id)' },
    cost_in_usd: { type: 'numeric(19,4)', notNull: true },
    credits_used: { type: 'numeric(19,4)', notNull: true },
    is_overage: { type: 'boolean', notNull: true, default: false },
    overage_reported_to_stripe: {
      type: 'boolean',
      notNull: true,
      default: false,
    },
    created_at: {
      type: 'timestamp',
      notNull: true,
      default: pgm.func('current_timestamp'),
    },
  });

  pgm.sql(`
    CREATE OR REPLACE FUNCTION ensure_single_active_subscription()
    RETURNS TRIGGER AS $$
    BEGIN
      IF NEW.status = 'active' THEN
        IF EXISTS (
          SELECT 1 FROM subscriptions
          WHERE user_id = NEW.user_id
            AND status = 'active'
            AND id != NEW.id
        ) THEN
          RAISE EXCEPTION 'User already has an active subscription';
        END IF;
      END IF;
      RETURN NEW;
    END;
    $$ LANGUAGE plpgsql;
  `);

  pgm.createTrigger(
    'subscriptions',
    'ensure_single_active_subscription_trigger',
    {
      when: 'BEFORE',
      operation: ['INSERT', 'UPDATE'],
      function: 'ensure_single_active_subscription',
      level: 'ROW',
    },
  );

  pgm.createIndex('users', 'stripe_customer_id');
  pgm.createIndex('subscriptions', 'user_id');
  pgm.createIndex('subscriptions', 'plan_id');
  pgm.createIndex('subscriptions', 'status');
  pgm.createIndex('subscriptions', 'stripe_subscription_id');
  pgm.createIndex('subscriptions', 'current_subscription_cycle_id');
  pgm.createIndex('subscription_cycles', 'subscription_id');
  pgm.createIndex('subscription_cycles', ['period_start', 'period_end']);
  pgm.createIndex('ai_actions', 'user_id');
  pgm.createIndex('ai_actions', 'created_at');

  pgm.sql(`
    INSERT INTO plans (name, monthly_price, credits_included, overage_fee_per_credit_in_usd) VALUES
    ('Free', 0, 100, NULL),
    ('Creator', 12, 500, 0.02),
    ('Power User', 49, 2500, 0.0125);
  `);
};

exports.down = (pgm) => {
  pgm.dropIndex('users', 'stripe_customer_id');
  pgm.dropIndex('subscriptions', 'user_id');
  pgm.dropIndex('subscriptions', 'plan_id');
  pgm.dropIndex('subscriptions', 'status');
  pgm.dropIndex('subscriptions', 'stripe_subscription_id');
  pgm.dropIndex('subscriptions', 'current_subscription_cycle_id');
  pgm.dropIndex('subscription_cycles', 'subscription_id');
  pgm.dropIndex('subscription_cycles', ['period_start', 'period_end']);
  pgm.dropIndex('ai_actions', 'user_id');
  pgm.dropIndex('ai_actions', 'created_at');

  pgm.dropTrigger('subscriptions', 'ensure_single_active_subscription_trigger');

  pgm.dropFunction('ensure_single_active_subscription', []);

  pgm.dropTable('ai_actions', { ifExists: true, cascade: true });

  pgm.dropConstraint(
    'subscriptions',
    'subscriptions_current_subscription_cycle_id_fkey',
  );

  pgm.dropTable('subscriptions', { cascade: true });
  pgm.dropTable('subscription_cycles', { cascade: true });
  pgm.dropTable('plans', { cascade: true });
  pgm.dropTable('users', { cascade: true });
};

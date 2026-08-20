const { shouldSeedDemoData } = require('../src/database/init');

describe('production database initialization', () => {
  const originalValue = process.env.SEED_DEMO_DATA;

  afterEach(() => {
    if (originalValue === undefined) {
      delete process.env.SEED_DEMO_DATA;
    } else {
      process.env.SEED_DEMO_DATA = originalValue;
    }
  });

  test('does not seed demo accounts by default', () => {
    delete process.env.SEED_DEMO_DATA;
    expect(shouldSeedDemoData()).toBe(false);
  });

  test('requires an explicit opt-in for demo data', () => {
    process.env.SEED_DEMO_DATA = 'true';
    expect(shouldSeedDemoData()).toBe(true);
  });
});

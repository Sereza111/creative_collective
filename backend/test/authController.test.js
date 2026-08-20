jest.mock('../src/config/database', () => ({ query: jest.fn() }));
jest.mock('bcryptjs', () => ({ hash: jest.fn(async () => 'password-hash') }));
jest.mock('jsonwebtoken', () => ({ sign: jest.fn(() => 'signed-token') }));

const { query } = require('../src/config/database');
const authController = require('../src/controllers/authController');

function response() {
  const res = {};
  res.status = jest.fn(() => res);
  res.json = jest.fn(() => res);
  return res;
}

describe('public registration roles', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    query.mockResolvedValue([]);
    process.env.JWT_SECRET = 'test-access-secret';
    process.env.JWT_REFRESH_SECRET = 'test-refresh-secret';
    process.env.JWT_EXPIRES_IN = '1h';
    process.env.JWT_REFRESH_EXPIRES_IN = '1d';
  });

  test('ignores a requested system admin role', async () => {
    const req = {
      body: {
        email: 'client@example.test',
        password: 'strong-password',
        full_name: 'Test Client',
        role: 'admin',
        user_role: 'client',
      },
    };
    const res = response();

    await authController.register(req, res);

    const insertUser = query.mock.calls.find(([sql]) => sql.includes('INSERT INTO users'));
    expect(insertUser).toBeDefined();
    expect(insertUser[1][7]).toBe('member');
    expect(insertUser[1][8]).toBe('client');
    expect(res.status).toHaveBeenCalledWith(201);
  });

  test('rejects an administrative marketplace role', async () => {
    const req = {
      body: {
        email: 'attacker@example.test',
        password: 'strong-password',
        user_role: 'admin',
      },
    };
    const res = response();

    await authController.register(req, res);

    expect(query).not.toHaveBeenCalled();
    expect(res.status).toHaveBeenCalledWith(400);
    expect(res.json).toHaveBeenCalledWith(expect.objectContaining({ success: false }));
  });
});

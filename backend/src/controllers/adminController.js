const { query } = require('../config/database');
const { successResponse, errorResponse } = require('../utils/responseHandler');

// Верифицировать пользователя (только админ)
exports.verifyUser = async (req, res) => {
  try {
    // Проверка прав администратора
    if (req.user.user_role !== 'admin') {
      return errorResponse(res, 'Недостаточно прав', 403);
    }

    const { userId } = req.params;
    const { verification_note } = req.body;

    console.log(`✅ Верификация пользователя ${userId} администратором ${req.user.id}`);

    await query(
      'UPDATE users SET is_verified = TRUE, verified_at = NOW(), verification_note = ? WHERE id = ?',
      [verification_note || 'Верифицирован администратором', userId]
    );

    successResponse(res, null, 'Пользователь верифицирован');
  } catch (error) {
    console.error('Verify user error:', error);
    errorResponse(res, 'Ошибка верификации пользователя');
  }
};

// Отменить верификацию пользователя (только админ)
exports.unverifyUser = async (req, res) => {
  try {
    if (req.user.user_role !== 'admin') {
      return errorResponse(res, 'Недостаточно прав', 403);
    }

    const { userId } = req.params;

    console.log(`❌ Отмена верификации пользователя ${userId} администратором ${req.user.id}`);

    await query(
      'UPDATE users SET is_verified = FALSE, verified_at = NULL, verification_note = NULL WHERE id = ?',
      [userId]
    );

    successResponse(res, null, 'Верификация отменена');
  } catch (error) {
    console.error('Unverify user error:', error);
    errorResponse(res, 'Ошибка отмены верификации');
  }
};

module.exports = exports;


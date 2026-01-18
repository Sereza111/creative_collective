const express = require('express');
const router = express.Router();
const legalController = require('../controllers/legalController');
const { authenticate, adminOnly } = require('../middleware/auth');

// Публичные роуты (доступны без авторизации)
router.get('/documents/:type', legalController.getActiveDocument);
router.get('/documents', legalController.getAllActiveDocuments);

// Роуты для авторизованных пользователей
router.use(authenticate);

router.post('/sign', legalController.signDocument);
router.get('/check', legalController.checkUserAgreement);
router.get('/my-agreements', legalController.getUserAgreements);
router.post('/applications/:applicationId/view', legalController.markApplicationViewed);

// Админ роуты
router.post('/process-ignored', adminOnly, legalController.processIgnoredApplications);

module.exports = router;


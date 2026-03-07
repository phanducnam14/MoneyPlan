const express = require('express');
const { forgotPassword, login, register, changePassword, changeEmail, getProfile, updateProfile, getUserStats, resetUserData } = require('../controllers/authController');
const auth = require('../middleware/auth');

const router = express.Router();

router.post('/register', register);
router.post('/login', login);
router.post('/forgot-password', forgotPassword);
router.get('/profile', auth(['user', 'admin']), getProfile);
router.post('/profile', auth(['user', 'admin']), updateProfile);
router.post('/change-password', auth(['user', 'admin']), changePassword);
router.post('/change-email', auth(['user', 'admin']), changeEmail);
router.get('/stats', auth(['user', 'admin']), getUserStats);
router.post('/reset-data', auth(['user', 'admin']), resetUserData);

module.exports = router;

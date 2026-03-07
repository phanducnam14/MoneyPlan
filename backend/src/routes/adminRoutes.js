const express = require('express');
const { blockUser, getUsers, systemStats, getUserStats } = require('../controllers/adminController');
const auth = require('../middleware/auth');

const router = express.Router();

router.get('/users', auth(['admin']), getUsers);
router.put('/users/:id/block', auth(['admin']), blockUser);
router.get('/stats', auth(['admin']), systemStats);
router.get('/users/:id/stats', auth(['admin']), getUserStats);

module.exports = router;

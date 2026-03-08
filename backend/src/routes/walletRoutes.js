const express = require('express');
const { getWallets, createWallet, updateWallet, deleteWallet, getWalletById } = require('../controllers/walletController');
const auth = require('../middleware/auth');

const router = express.Router();

router.get('/', auth(['user', 'admin']), getWallets);
router.get('/:id', auth(['user', 'admin']), getWalletById);
router.post('/', auth(['user', 'admin']), createWallet);
router.put('/:id', auth(['user', 'admin']), updateWallet);
router.delete('/:id', auth(['user', 'admin']), deleteWallet);

module.exports = router;


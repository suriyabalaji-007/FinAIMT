const bcrypt = require('bcrypt');
const { User } = require('../models');

/**
 * Middleware to verify 4-digit Transaction PIN
 */
/**
 * Middleware to verify 4-digit Transaction PIN.
 * Assumes either 'protect' middleware has run (setting req.user)
 * or userId is provided in req.body.
 */
const verifyTransactionPin = async (req, res, next) => {
    const { transactionPin } = req.body;
    let { userId } = req.body;

    if (!transactionPin) {
        return res.status(400).json({ error: 'Transaction PIN is required' });
    }

    try {
        let user = req.user;

        // If 'protect' middleware wasn't used, fetch user by ID
        if (!user && userId) {
            user = await User.findByPk(userId);
        }

        if (!user) {
            return res.status(404).json({ error: 'User context not found' });
        }

        // We need the full user for comparison because req.user from 'protect' might exclude secrets
        const fullUser = await User.findByPk(user.id);
        if (!fullUser) {
            return res.status(404).json({ error: 'User not found in storage' });
        }

        const isMatch = await bcrypt.compare(transactionPin.toString(), fullUser.transactionPin);
        if (!isMatch) {
            return res.status(401).json({ error: 'Invalid Transaction PIN' });
        }

        // Re-attach absolute user if necessary
        req.user = fullUser;
        next();
    } catch (error) {
        console.error('[PIN_AUTH_ERROR]', error);
        res.status(500).json({ error: 'Internal server error during PIN verification' });
    }
};

module.exports = verifyTransactionPin;

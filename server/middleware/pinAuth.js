const bcrypt = require('bcrypt');
const { User } = require('../models');

/**
 * Middleware to verify 4-digit Transaction PIN
 */
const verifyTransactionPin = async (req, res, next) => {
    const { userId, transactionPin } = req.body;

    if (!userId || !transactionPin) {
        return res.status(400).json({ error: 'User ID and PIN are required' });
    }

    try {
        const user = await User.findByPk(userId);
        if (!user) {
            return res.status(404).json({ error: 'User not found' });
        }

        const isMatch = await bcrypt.compare(transactionPin.toString(), user.transactionPin);
        if (!isMatch) {
            return res.status(401).json({ error: 'Invalid Transaction PIN' });
        }

        // Attach user to request for further use
        req.user = user;
        next();
    } catch (error) {
        res.status(500).json({ error: 'Internal server error' });
    }
};

module.exports = verifyTransactionPin;

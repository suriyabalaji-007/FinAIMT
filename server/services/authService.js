const jwt = require('jsonwebtoken');
const bcrypt = require('bcrypt');
const crypto = require('crypto');
const { User } = require('../models');

/**
 * Generate a JWT token for session management
 * @param {string} id - User UUID
 * @returns {string} Signed JWT token
 */
const generateToken = (id) => {
    return jwt.sign({ id }, process.env.JWT_SECRET, {
        expiresIn: '30d', // Session expires in 30 days
    });
};

/**
 * Generate a random token for email verification or password reset
 * @returns {string} Random hex string
 */
const generateRandomToken = () => {
    return crypto.randomBytes(20).toString('hex');
};

/**
 * Hash a token for secure database storage
 * @param {string} token - Raw token
 * @returns {string} Hashed token
 */
const hashToken = (token) => {
    return crypto.createHash('sha256').update(token).digest('hex');
};

/**
 * Check if the user is locked out due to too many failed login attempts
 * @param {User} user - User instance
 * @returns {boolean} True if locked
 */
const isLocked = (user) => {
    return !!(user.lockUntil && user.lockUntil > Date.now());
};

module.exports = {
    generateToken,
    generateRandomToken,
    hashToken,
    isLocked,
};

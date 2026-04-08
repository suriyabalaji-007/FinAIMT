const express = require('express');
const router = express.Router();
const rateLimit = require('express-rate-limit');
const bcrypt = require('bcrypt');
const { User } = require('../models');
const { protect } = require('../middleware/authMiddleware');
const { generateToken, generateRandomToken, hashToken, isLocked } = require('../services/authService');

// Rate limiting for login and sensitive auth endpoints
const authLimiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 5, // 5 login attempts
    message: { error: 'Too many login attempts, please try again after 15 minutes' }
});

/**
 * @route   POST /api/auth/register
 * @desc    Register a new user
 */
router.post('/register', async (req, res) => {
    const { name, email, phone, password, transactionPin } = req.body;

    try {
        const userExists = await User.findOne({ where: { email } });
        if (userExists) return res.status(400).json({ error: 'User already exists' });

        const saltRounds = parseInt(process.env.BCRYPT_SALT_ROUNDS) || 10;
        const hashedPassword = await bcrypt.hash(password, saltRounds);
        const hashedPin = await bcrypt.hash(transactionPin.toString(), saltRounds);

        // Verification token
        const rawToken = generateRandomToken();
        const verificationToken = hashToken(rawToken);
        const verificationExpires = Date.now() + 24 * 60 * 60 * 1000; // 24 hours

        const user = await User.create({
            name,
            email,
            phone,
            password: hashedPassword,
            transactionPin: hashedPin,
            emailVerificationToken: verificationToken,
            emailVerificationExpires: verificationExpires
        });

        // In a real app, send email with rawToken here
        console.log(`[AUTH] Verification token for ${email}: ${rawToken}`);

        res.status(201).json({
            id: user.id,
            name: user.name,
            email: user.email,
            token: generateToken(user.id),
            message: 'Verification email sent'
        });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

/**
 * @route   POST /api/auth/login
 * @desc    Authenticate user & get token
 */
router.post('/login', authLimiter, async (req, res) => {
    const { email, password } = req.body;

    try {
        const user = await User.findOne({ where: { email } });
        if (!user) return res.status(401).json({ error: 'Invalid credentials' });

        // Check if locked
        if (isLocked(user)) {
            return res.status(403).json({ error: 'Account locked. Try again later.' });
        }

        const isMatch = await bcrypt.compare(password, user.password);

        if (isMatch) {
            // Reset failed attempts
            user.loginAttempts = 0;
            user.lockUntil = null;
            await user.save();

            res.json({
                id: user.id,
                name: user.name,
                email: user.email,
                balance: user.balance,
                token: generateToken(user.id)
            });
        } else {
            // Increment failed attempts
            user.loginAttempts += 1;
            if (user.loginAttempts >= 5) {
                user.lockUntil = Date.now() + (30 * 60 * 1000); // Lock for 30 min
            }
            await user.save();

            res.status(401).json({ error: 'Invalid credentials' });
        }
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

/**
 * @route   POST /api/auth/verify-email
 * @desc    Verify email address
 */
router.post('/verify-email', async (req, res) => {
    const { token } = req.body;
    const hashed = hashToken(token);

    try {
        const user = await User.findOne({
            where: {
                emailVerificationToken: hashed,
                emailVerificationExpires: { [require('sequelize').Op.gt]: Date.now() }
            }
        });

        if (!user) return res.status(400).json({ error: 'Invalid or expired token' });

        user.isEmailVerified = true;
        user.emailVerificationToken = null;
        user.emailVerificationExpires = null;
        await user.save();

        res.json({ message: 'Email verified successfully' });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

/**
 * @route   POST /api/auth/forgot-password
 * @desc    Generate password reset token
 */
router.post('/forgot-password', authLimiter, async (req, res) => {
    const { email } = req.body;

    try {
        const user = await User.findOne({ where: { email } });
        if (!user) return res.json({ message: 'If that email exists, a reset link was sent' });

        const rawToken = generateRandomToken();
        user.passwordResetToken = hashToken(rawToken);
        user.passwordResetExpires = Date.now() + 30 * 60 * 1000; // 30 minutes
        await user.save();

        console.log(`[AUTH] Password reset token for ${email}: ${rawToken}`);

        res.json({ message: 'Reset token generated (check console logs)' });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

/**
 * @route   POST /api/auth/reset-password
 * @desc    Reset password using token
 */
router.post('/reset-password', async (req, res) => {
    const { token, newPassword } = req.body;
    const hashed = hashToken(token);

    try {
        const user = await User.findOne({
            where: {
                passwordResetToken: hashed,
                passwordResetExpires: { [require('sequelize').Op.gt]: Date.now() }
            }
        });

        if (!user) return res.status(400).json({ error: 'Invalid or expired reset token' });

        const saltRounds = parseInt(process.env.BCRYPT_SALT_ROUNDS) || 10;
        user.password = await bcrypt.hash(newPassword, saltRounds);
        user.passwordResetToken = null;
        user.passwordResetExpires = null;
        await user.save();

        res.json({ message: 'Password reset successful' });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

/**
 * @route   GET /api/auth/me
 * @desc    Get current user profile
 */
router.get('/me', protect, async (req, res) => {
    res.json(req.user);
});

module.exports = router;

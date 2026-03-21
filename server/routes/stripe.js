const express = require('express');
const router = express.Router();
const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);
const { User, Transaction, sequelize } = require('../models');

/**
 * Handle Add Money: Create Payment Intent
 */
router.post('/create-payment-intent', async (req, res) => {
    const { userId, amount } = req.body; // Amount in cents/paise

    try {
        const user = await User.findByPk(userId);
        if (!user) return res.status(404).json({ error: 'User not found' });

        const paymentIntent = await stripe.paymentIntents.create({
            amount: amount,
            currency: 'inr', // Using INR for India context
            metadata: { userId: user.id }
        });

        res.json({ clientSecret: paymentIntent.client_secret });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

/**
 * Stripe Webhook Listener: Update balance on payment success
 */
router.post('/webhook', express.raw({ type: 'application/json' }), async (req, res) => {
    const sig = req.headers['stripe-signature'];
    let event;

    try {
        event = stripe.webhooks.constructEvent(req.body, sig, process.env.STRIPE_WEBHOOK_SECRET);
    } catch (err) {
        return res.status(400).send(`Webhook Error: ${err.message}`);
    }

    if (event.type === 'payment_intent.succeeded') {
        const paymentIntent = event.data.object;
        const userId = paymentIntent.metadata.userId;
        const amount = paymentIntent.amount;

        const t = await sequelize.transaction();
        try {
            const user = await User.findByPk(userId, { transaction: t, lock: true });
            if (user) {
                await user.update({
                    balance: BigInt(user.balance) + BigInt(amount)
                }, { transaction: t });

                await Transaction.create({
                    receiverId: userId,
                    amount: amount,
                    type: 'topup',
                    status: 'success',
                    referenceId: paymentIntent.id
                }, { transaction: t });

                await t.commit();
                console.log(`Payment confirmed for user ${userId}: ${amount}`);
            }
        } catch (error) {
            await t.rollback();
            console.error('Webhook processing failed:', error);
        }
    }

    res.json({ received: true });
});

module.exports = router;

const { sequelize, User, Transaction } = require('../models');
const { v4: uuidv4 } = require('uuid');

/**
 * Robust fund transfer with SQL Transactions and Row Locking
 */
async function transferFunds(senderId, receiverId, amount) {
    if (amount <= 0) throw new Error('Invalid amount');
    if (senderId === receiverId) throw new Error('Cannot send to self');

    const t = await sequelize.transaction();

    try {
        // 1. Lock the sender record to prevent concurrent updates (FOR UPDATE)
        const sender = await User.findByPk(senderId, {
            transaction: t,
            lock: true
        });

        if (!sender) throw new Error('Sender not found');
        if (BigInt(sender.balance) < BigInt(amount)) {
            throw new Error('Insufficient balance');
        }

        // 2. Lock the receiver record
        const receiver = await User.findByPk(receiverId, {
            transaction: t,
            lock: true
        });

        if (!receiver) throw new Error('Receiver not found');

        // 3. Deduct from sender
        await sender.update({
            balance: BigInt(sender.balance) - BigInt(amount)
        }, { transaction: t });

        // 4. Add to receiver
        await receiver.update({
            balance: BigInt(receiver.balance) + BigInt(amount)
        }, { transaction: t });

        // 5. Log the transaction
        const transactionRecord = await Transaction.create({
            senderId,
            receiverId,
            amount,
            type: 'transfer',
            status: 'success',
            referenceId: `txn_${Date.now()}_${uuidv4().split('-')[0]}`
        }, { transaction: t });

        // 6. Commit the transaction
        await t.commit();
        return transactionRecord;

    } catch (error) {
        // Rollback if anything fails
        await t.rollback();
        throw error;
    }
}

module.exports = { transferFunds };

const { User, Investment, Transaction, sequelize } = require('../models');

async function tradeAsset(userId, assetId, assetName, category, quantity, price, side) {
  const t = await sequelize.transaction();
  try {
    const user = await User.findByPk(userId, { transaction: t });
    if (!user) throw new Error('User not found');

    const amount = Math.round(quantity * price);

    if (side === 'buy') {
      if (user.balance < amount) throw new Error('Insufficient balance');
      
      user.balance -= amount;
      await user.save({ transaction: t });

      let investment = await Investment.findOne({
        where: { userId, assetId },
        transaction: t
      });

      if (investment) {
        const totalCost = (investment.quantity * investment.averagePrice) + amount;
        investment.quantity += quantity;
        investment.averagePrice = Math.round(totalCost / investment.quantity);
        await investment.save({ transaction: t });
      } else {
        await Investment.create({
          userId,
          assetId,
          assetName,
          category,
          quantity,
          averagePrice: price
        }, { transaction: t });
      }

      await Transaction.create({
        receiverId: userId,
        amount,
        type: 'withdrawal', // Representing money leaving balance for investment
        status: 'success',
        referenceId: `BUY_${assetId}_${Date.now()}`
      }, { transaction: t });

    } else if (side === 'sell') {
      let investment = await Investment.findOne({
        where: { userId, assetId },
        transaction: t
      });

      if (!investment || investment.quantity < quantity) {
        throw new Error('Insufficient quantities to sell');
      }

      user.balance += amount;
      await user.save({ transaction: t });

      investment.quantity -= quantity;
      if (investment.quantity === 0) {
        await investment.destroy({ transaction: t });
      } else {
        await investment.save({ transaction: t });
      }

      await Transaction.create({
        receiverId: userId,
        amount,
        type: 'topup', // Representing money entering balance from sale
        status: 'success',
        referenceId: `SELL_${assetId}_${Date.now()}`
      }, { transaction: t });
    }

    await t.commit();
    return { success: true };
  } catch (error) {
    await t.rollback();
    throw error;
  }
}

module.exports = { tradeAsset };

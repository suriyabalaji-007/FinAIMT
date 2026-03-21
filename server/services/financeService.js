const { User, Loan, Transaction, FinancialMetric, sequelize } = require('../models');

async function payEMI(userId, loanId) {
  const t = await sequelize.transaction();
  try {
    const loan = await Loan.findByPk(loanId, { transaction: t });
    if (!loan) throw new Error('Loan not found');
    if (loan.userId !== userId) throw new Error('Unauthorized');

    const amount = loan.emi;
    const user = await User.findByPk(userId, { transaction: t });
    if (user.balance < amount) throw new Error('Insufficient balance');

    user.balance -= amount;
    await user.save({ transaction: t });

    loan.remainingAmount -= amount;
    if (loan.remainingAmount < 0) loan.remainingAmount = 0;
    await loan.save({ transaction: t });

    await Transaction.create({
      receiverId: userId,
      amount,
      type: 'withdrawal',
      status: 'success',
      referenceId: `EMI_${loanId}_${Date.now()}`
    }, { transaction: t });

    // Record as expense for metrics
    await FinancialMetric.create({
      userId,
      metricType: 'expense',
      value: amount,
      category: 'Loans',
      year: '2024-25'
    }, { transaction: t });

    await t.commit();
    return { success: true, remainingAmount: loan.remainingAmount };
  } catch (error) {
    await t.rollback();
    throw error;
  }
}

async function updateTaxAnalytics(userId) {
  // Simple simulator: Est Tax = 10% of (Income - 80C)
  const incomeMetric = await FinancialMetric.findOne({ where: { userId, metricType: 'income' } });
  const deductionMetric = await FinancialMetric.findOne({ where: { userId, metricType: 'tax_80c' } });
  
  const income = incomeMetric ? incomeMetric.value : 0;
  const deductions = deductionMetric ? deductionMetric.value : 0;
  
  const taxable = Math.max(0, income - deductions);
  const estimatedTax = Math.round(taxable * 0.1);

  await FinancialMetric.upsert({
    userId,
    metricType: 'tax_estimated',
    value: estimatedTax,
    year: '2024-25'
  });

  return estimatedTax;
}

module.exports = { payEMI, updateTaxAnalytics };

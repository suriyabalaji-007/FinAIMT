import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fin_aimt/data/providers/finance_provider.dart';
import 'package:fin_aimt/data/models/finance_models.dart';
import 'package:fin_aimt/screens/upi/qr_scanner_view.dart';
import 'package:fin_aimt/screens/upi/contact_sync_view.dart';
import 'package:fin_aimt/screens/upi/payment_screen.dart';
import 'package:fin_aimt/screens/upi/mobile_recharge_view.dart';
import 'package:fin_aimt/screens/upi/bill_payment_view.dart';
import 'package:fin_aimt/widgets/obscured_balance_widget.dart';
import 'package:fin_aimt/widgets/upi_pin_dialog.dart';
import 'package:fin_aimt/widgets/global_header.dart';
import 'package:fin_aimt/screens/investments/transaction_history_view.dart';
import 'package:fin_aimt/data/providers/transaction_provider.dart';
import 'package:intl/intl.dart';

class UPIHomeView extends ConsumerWidget {
  const UPIHomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balance = ref.watch(financeDataProvider).totalBalance;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(
            child: GlobalHeader(
              title: 'Banking',
              subtitle: 'UPI & Bank Accounts',
              showLogo: false,
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              height: 140,
              margin: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark 
                    ? [Colors.blue.shade900, Colors.black] 
                    : [primaryColor, primaryColor.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: isDark ? [] : [
                  BoxShadow(color: primaryColor.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))
                ],
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Total Balance',
                      style: TextStyle(color: isDark ? Colors.white70 : Colors.white.withOpacity(0.9), fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    ObscuredBalanceWidget(
                      balance: balance,
                      textStyle: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                      isHeader: true,
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTransferMoney(context),
                  const SizedBox(height: 16),
                  _buildBillsAndRecharges(context),
                  const SizedBox(height: 16),
                  _buildOtherServices(context, ref),
                  const SizedBox(height: 24),

                  // Linked Accounts
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text('Linked Accounts', 
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87, 
                        fontSize: 18, 
                        fontWeight: FontWeight.bold
                      )
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildLinkedAccounts(context, ref),
                  const SizedBox(height: 24),

                  // Manage Cards
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text('Manage Cards', 
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87, 
                        fontSize: 18, 
                        fontWeight: FontWeight.bold
                      )
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildManageCards(context, ref),
                  const SizedBox(height: 24),

                  // Recent Transactions
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'Recent Transactions',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87, 
                        fontSize: 18, 
                        fontWeight: FontWeight.bold
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildTransactionFilterBar(context),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: _buildTransactionList(context, ref),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransferMoney(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    void navigateToPayment(String name) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => PaymentScreen(receiverId: 'mock-$name', receiverName: name)));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text('Transfer Money', 
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87, 
              fontSize: 16, 
              fontWeight: FontWeight.bold
            )
          ),
        ),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 4,
          childAspectRatio: 0.85,
          children: [
            _actionButton(context, Icons.qr_code_scanner, 'Scan QR', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QRScannerView()))),
            _actionButton(context, Icons.contact_phone_outlined, 'Pay\nContacts', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ContactSyncView()))),
            _actionButton(context, Icons.phone_android, 'Pay Phone\nNumber', () => navigateToPayment('Phone Number')),
            _actionButton(context, Icons.account_balance, 'Bank\nTransfer', () => navigateToPayment('Bank Transfer')),
            _actionButton(context, Icons.alternate_email, 'Pay to\nUPI ID', () => navigateToPayment('UPI ID')),
            _actionButton(context, Icons.person_outline, 'Self\nTransfer', () => navigateToPayment('Self Transfer')),
            _actionButton(context, Icons.receipt_long, 'Pay Bills', () => navigateToPayment('Bill Payment')),
            _actionButton(context, Icons.history, 'Mobile\nRecharge', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MobileRechargeView()))),
          ],
        ),
      ],
    );
  }

  Widget _buildBillsAndRecharges(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    void navigateToPayment(String name) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => PaymentScreen(receiverId: 'mock-$name', receiverName: name)));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text('Bills, Recharges and More', 
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87, 
              fontSize: 16, 
              fontWeight: FontWeight.bold
            )
          ),
        ),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 4,
          childAspectRatio: 0.85,
          children: [
            _actionButton(context, Icons.phone_android, 'Mobile\nRecharge', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MobileRechargeView()))),
            _actionButton(context, Icons.satellite_alt_outlined, 'DTH /\nCable', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BillPaymentView(category: BillCategory.dth)))),
            _actionButton(context, Icons.lightbulb_outline, 'Electricity', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BillPaymentView(category: BillCategory.electricity)))),
            _actionButton(context, Icons.time_to_leave, 'FASTag\nRecharge', () => navigateToPayment('FASTag Recharge')),
            _actionButton(context, Icons.payment, 'Credit Card\nPayment', () => navigateToPayment('Credit Card Bill')),
            _actionButton(context, Icons.water_drop_outlined, 'Water\nBill', () => navigateToPayment('Water Bill')),
            _actionButton(context, Icons.gas_meter_outlined, 'Piped Gas', () => navigateToPayment('Piped Gas Bill')),
            _actionButton(context, Icons.add_circle_outline, 'See All', () {}),
          ],
        ),
      ],
    );
  }

  Widget _buildOtherServices(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TransactionHistoryView())),
              icon: Icon(Icons.history, color: primaryColor),
              label: Text('Transaction history', 
                style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 12)
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: BorderSide(color: (isDark ? Colors.white : Colors.black).withOpacity(0.1)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (ctx) => UpiPinDialog(
                    onPinEntered: (pin) async {
                      if (pin == '0000') throw Exception('Incorrect PIN');
                      if (context.mounted) {
                        final balance = ref.read(financeDataProvider).totalBalance;
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: Theme.of(context).cardTheme.color,
                            title: Text('Bank Balance', 
                              style: TextStyle(color: isDark ? Colors.white : Colors.black87)
                            ),
                            content: Text(
                              'Available Balance:\n\n₹${balance.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black, 
                                fontSize: 24, 
                                fontWeight: FontWeight.bold
                              ),
                              textAlign: TextAlign.center,
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text('OK', style: TextStyle(color: primaryColor)),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                  ),
                );
              },
              icon: Icon(Icons.account_balance_wallet, color: primaryColor),
              label: Text('Check balance', 
                style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 12)
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: BorderSide(color: (isDark ? Colors.white : Colors.black).withOpacity(0.1)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : primaryColor.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: primaryColor, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label, 
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87, 
              fontSize: 11, 
              height: 1.2
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final transactions = ref.watch(transactionHistoryProvider);
    
    if (transactions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              Icon(Icons.receipt_long_outlined, color: isDark ? Colors.white10 : Colors.black12, size: 48),
              const SizedBox(height: 10),
              Text('No recent transactions', style: TextStyle(color: isDark ? Colors.white30 : Colors.black38)),
            ],
          ),
        ),
      );
    }

    final displayCount = transactions.length > 5 ? 5 : transactions.length;

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: displayCount,
      itemBuilder: (context, index) {
        final tx = transactions[index];
        final isDebit = tx.side == 'buy' || tx.side == 'repayment'; // Simplified for banking view
        
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              tx.category == 'Stocks' ? Icons.show_chart : tx.category == 'Loans' ? Icons.account_balance_wallet : Icons.shopping_bag,
              color: isDark ? Colors.white70 : Colors.black54,
              size: 20,
            ),
          ),
          title: Text(tx.assetName, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 14)),
          subtitle: Text(tx.formattedDate, style: TextStyle(color: isDark ? Colors.white30 : Colors.black45, fontSize: 11)),
          trailing: Text(
            '${isDebit ? "-" : "+"}₹${tx.totalAmount.toStringAsFixed(0)}',
            style: TextStyle(
              color: !isDebit ? Colors.green : (isDark ? Colors.white : Colors.black87),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        );
      },
    );
  }

  Widget _buildLinkedAccounts(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accounts = ref.watch(financeDataProvider).accounts;

    return SizedBox(
      height: 100,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: accounts.length,
        itemBuilder: (context, index) {
          final acc = accounts[index];
          return Container(
            width: 200,
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05)),
              boxShadow: isDark ? [] : [
                BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Icon(Icons.account_balance, color: isDark ? Colors.white70 : Colors.black45, size: 18),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(acc.bankName, 
                        style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 13),
                        overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('₹${acc.balance.toStringAsFixed(0)}', 
                  style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 16, fontWeight: FontWeight.bold)
                ),
                Text(acc.accountNumber, 
                  style: TextStyle(color: isDark ? Colors.white30 : Colors.black26, fontSize: 10)
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildManageCards(BuildContext context, WidgetRef ref) {
    final cards = ref.watch(financeDataProvider).creditCards;
    return SizedBox(
      height: 130,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: cards.length,
        itemBuilder: (context, index) {
          final card = cards[index];
          return Container(
            width: 240,
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: card.type == 'Visa'
                ? LinearGradient(colors: [Colors.indigo.shade900, Colors.indigo.shade700])
                : LinearGradient(colors: [Colors.teal.shade900, Colors.teal.shade700]),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(card.cardName, 
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        overflow: TextOverflow.ellipsis),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(card.type, style: const TextStyle(color: Colors.white70, fontSize: 10)),
                    ),
                  ],
                ),
                const Spacer(),
                Text('•••• ${card.cardNumber.substring(card.cardNumber.length - 4)}', 
                  style: const TextStyle(color: Colors.white54, fontSize: 14, letterSpacing: 2)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Due: ₹${card.balance.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                    const Row(
                      children: [
                        Icon(Icons.ac_unit, color: Colors.lightBlueAccent, size: 18),
                        SizedBox(width: 12),
                        Icon(Icons.tune, color: Colors.white54, size: 18),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTransactionFilterBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final filters = ['All', 'Sent', 'Received', 'Bills'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        height: 36,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: filters.length,
          itemBuilder: (context, index) {
            final isFirst = index == 0;
            return Container(
              margin: const EdgeInsets.only(right: 10),
              child: FilterChip(
                label: Text(filters[index], 
                  style: TextStyle(
                    color: isFirst ? Colors.white : (isDark ? Colors.white70 : Colors.black54), 
                    fontSize: 12
                  )
                ),
                selected: isFirst,
                selectedColor: primaryColor,
                backgroundColor: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
                checkmarkColor: Colors.white,
                onSelected: (_) {},
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                side: BorderSide.none,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            );
          },
        ),
      ),
    );
  }
}

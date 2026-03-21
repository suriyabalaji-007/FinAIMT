import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fin_aimt/core/theme.dart';
import 'package:fin_aimt/data/providers/finance_provider.dart';
import 'package:fin_aimt/data/models/finance_models.dart';
import 'package:fin_aimt/widgets/upi_pin_dialog.dart';
import 'package:fin_aimt/screens/upi/payment_success_view.dart';

enum BillCategory { dth, electricity }

class BillPaymentView extends ConsumerStatefulWidget {
  final BillCategory category;
  
  const BillPaymentView({super.key, required this.category});

  @override
  ConsumerState<BillPaymentView> createState() => _BillPaymentViewState();
}

class _BillPaymentViewState extends ConsumerState<BillPaymentView> {
  final _idController = TextEditingController();
  final _amountController = TextEditingController();
  String? _selectedBiller;

  final Map<BillCategory, List<String>> _billers = {
    BillCategory.dth: ['Airtel Digital TV', 'Tata Play', 'Dish TV', 'Sun Direct'],
    BillCategory.electricity: ['TNEB', 'BESCOM', 'Adani Electricity', 'Tata Power'],
  };

  @override
  void dispose() {
    _idController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.category == BillCategory.dth ? 'DTH Recharge' : 'Electricity Bill';
    final label = widget.category == BillCategory.dth ? 'Subscriber ID' : 'Consumer Number';
    final icon = widget.category == BillCategory.dth ? Icons.satellite_alt_outlined : Icons.lightbulb_outline;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(title, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select Biller', style: TextStyle(color: Colors.white, fontSize: 16)),
            const SizedBox(height: 12),
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _billers[widget.category]!.length,
                itemBuilder: (context, index) {
                  final biller = _billers[widget.category]![index];
                  final isSelected = _selectedBiller == biller;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedBiller = biller),
                    child: Container(
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary.withOpacity(0.2) : Colors.transparent,
                        border: Border.all(color: isSelected ? AppColors.primary : Colors.grey.shade800),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(
                          biller,
                          style: TextStyle(
                            color: isSelected ? AppColors.primary : Colors.white70,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _idController,
              style: const TextStyle(color: Colors.white, fontSize: 18),
              decoration: InputDecoration(
                labelText: label,
                labelStyle: const TextStyle(color: Colors.white70),
                prefixIcon: Icon(icon, color: AppColors.primary),
                filled: true,
                fillColor: Colors.grey.shade900,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primary)),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white, fontSize: 18),
              decoration: InputDecoration(
                labelText: 'Amount',
                prefixText: '₹ ',
                prefixStyle: const TextStyle(color: AppColors.primary, fontSize: 18),
                labelStyle: const TextStyle(color: Colors.white70),
                prefixIcon: const Icon(Icons.currency_rupee, color: AppColors.primary),
                filled: true,
                fillColor: Colors.grey.shade900,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primary)),
              ),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _handlePayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Proceed to Pay', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handlePayment() {
    if (_selectedBiller == null || _idController.text.isEmpty || _amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all details')));
      return;
    }

    final double? amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid amount')));
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => UpiPinDialog(
        bankName: 'HDFC Bank - •••• 1234',
        onPinEntered: (pin) async {
          if (pin == '0000') throw Exception('Incorrect PIN');
          
          if (mounted) {
            final txnId = 'TXN${DateTime.now().millisecondsSinceEpoch}';
            ref.read(financeDataProvider.notifier).addTransaction(
              Transaction(
                id: txnId,
                title: _selectedBiller!,
                subtitle: '${widget.category == BillCategory.dth ? "Sub ID" : "Cons ID"}: ${_idController.text}',
                amount: amount,
                date: DateTime.now(),
                type: TransactionType.debit,
                category: 'Bills & Utilities',
                icon: widget.category == BillCategory.dth ? Icons.satellite_alt_outlined : Icons.lightbulb_outline,
              ),
            );

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => PaymentSuccessView(
                  amount: amount,
                  receiverName: _selectedBiller!,
                  transactionId: txnId,
                ),
              ),
            );
          }
        },
      ),
    );
  }
}

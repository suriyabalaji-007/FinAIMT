import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:fin_aimt/screens/upi/payment_success_view.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fin_aimt/data/providers/finance_provider.dart';
import 'package:fin_aimt/data/models/finance_models.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  final String receiverId;
  final String receiverName;

  const PaymentScreen({
    super.key,
    required this.receiverId,
    required this.receiverName,
  });

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  final LocalAuthentication _auth = LocalAuthentication();
  final TextEditingController _amountController = TextEditingController();
  bool _isProcessing = false;

  Future<void> _handlePayment() async {
    if (_amountController.text.isEmpty) return;

    try {
      // 1. Biometric Authentication
      final bool canCheck = await _auth.canCheckBiometrics;

      bool didAuthenticate = false;
      if (canCheck) {
        didAuthenticate = await _auth.authenticate(
          localizedReason: 'Authenticate to complete the payment',
        );
      } else {
        // Fallback: skip biometric for emulators / no biometric enrolled
        didAuthenticate = true;
      }

      if (!didAuthenticate) return;

      setState(() => _isProcessing = true);

      // 2. Call backend API
      await Future.delayed(const Duration(seconds: 2)); // Simulate network

      if (!mounted) return;

      final amount = double.parse(_amountController.text);
      final txnId = 'TXN${DateTime.now().millisecondsSinceEpoch}';

      ref.read(financeDataProvider.notifier).addTransaction(
        Transaction(
          id: txnId,
          title: 'Paid to ${widget.receiverName}',
          subtitle: 'UPI Payment',
          amount: amount,
          date: DateTime.now(),
          type: TransactionType.debit,
          icon: Icons.send,
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentSuccessView(
            amount: amount,
            receiverName: widget.receiverName,
            transactionId: txnId,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white)),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.blue.shade900,
              child: Text(
                widget.receiverName[0].toUpperCase(),
                style: const TextStyle(fontSize: 32, color: Colors.white),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Paying ${widget.receiverName}',
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 48),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                hintText: '₹0',
                hintStyle: TextStyle(color: Colors.white30),
                border: InputBorder.none,
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _handlePayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28)),
                ),
                child: _isProcessing
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Confirm Payment',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

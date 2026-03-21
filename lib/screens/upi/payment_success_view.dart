import 'package:flutter/material.dart';

class PaymentSuccessView extends StatelessWidget {
  final double amount;
  final String receiverName;
  final String transactionId;

  const PaymentSuccessView({
    super.key,
    required this.amount,
    required this.receiverName,
    required this.transactionId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade700,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white, size: 100),
            const SizedBox(height: 24),
            const Text(
              'Payment Successful',
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '₹$amount sent to $receiverName',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 48),
            Container(
              padding: const EdgeInsets.all(24),
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  _row('Transaction ID', transactionId),
                  const Divider(),
                  _row('Date', DateTime.now().toString().split('.')[0]),
                  const Divider(),
                  _row('Paid to', receiverName),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: const Text('View Receipt'),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

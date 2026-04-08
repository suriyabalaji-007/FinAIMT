import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fin_aimt/core/theme.dart';
import 'package:fin_aimt/data/providers/transaction_provider.dart';
import 'package:fin_aimt/data/providers/investment_provider.dart';
import 'package:fin_aimt/data/providers/loans_provider.dart';
import 'package:fin_aimt/widgets/upi_pin_dialog.dart';

/// A unified payment flow widget used across ALL investment sections.
/// Handles: Payment Method Selection → UPI App / Card Details → PIN → Success Receipt
class UnifiedPaymentFlow {
  static Future<bool> show({
    required BuildContext context,
    required WidgetRef ref,
    required String assetName,
    required String category,
    required double quantity,
    required double pricePerUnit,
    required String side,
    String? itemId,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PaymentFlowSheet(
        assetName: assetName,
        category: category,
        quantity: quantity,
        pricePerUnit: pricePerUnit,
        side: side,
        itemId: itemId,
      ),
    );
    return result ?? false;
  }
}

class _PaymentFlowSheet extends ConsumerStatefulWidget {
  final String assetName;
  final String category;
  final double quantity;
  final double pricePerUnit;
  final String side;
  final String? itemId;

  const _PaymentFlowSheet({
    required this.assetName,
    required this.category,
    required this.quantity,
    required this.pricePerUnit,
    required this.side,
    this.itemId,
  });

  @override
  ConsumerState<_PaymentFlowSheet> createState() => _PaymentFlowSheetState();
}

class _PaymentFlowSheetState extends ConsumerState<_PaymentFlowSheet> {
  // Step: 0 = Select Method, 1 = UPI Apps / Card Details, 2 = Processing, 3 = Success
  int _step = 0;
  String _paymentMethod = 'UPI'; // 'UPI' or 'Card'
  String _selectedUpiApp = '';
  String _cardType = 'Credit Card'; // 'Credit Card' or 'Debit Card'
  final _cardNumberCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  final _cvvCtrl = TextEditingController();
  final _cardPinCtrl = TextEditingController();
  String? _txnId;
  bool _isProcessing = false;

  double get _totalAmount => widget.quantity * widget.pricePerUnit;
  NumberFormat get _fmt => NumberFormat.currency(locale: 'en_IN', symbol: '₹');

  @override
  void dispose() {
    _cardNumberCtrl.dispose();
    _expiryCtrl.dispose();
    _cvvCtrl.dispose();
    _cardPinCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1D1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(25, 20, 25, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2)),
                ),
              ),

              // Amount header
              _buildAmountHeader(isDark, primaryColor),
              const SizedBox(height: 25),

              // Step content
              if (_step == 0) _buildStep0SelectMethod(isDark, primaryColor),
              if (_step == 1 && _paymentMethod == 'UPI') _buildStep1UpiApps(isDark, primaryColor),
              if (_step == 1 && _paymentMethod == 'Card') _buildStep1CardDetails(isDark, primaryColor),
              if (_step == 2) _buildStep2Processing(isDark, primaryColor),
              if (_step == 3) _buildStep3Success(isDark, primaryColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAmountHeader(bool isDark, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryColor.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(
              widget.side == 'buy' ? Icons.shopping_cart_rounded : Icons.sell_rounded,
              color: primaryColor, size: 22,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.side == 'buy' ? 'Buying' : 'Selling'} ${widget.assetName}',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : Colors.black87),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(widget.category, style: TextStyle(fontSize: 11, color: isDark ? Colors.white30 : Colors.black38)),
              ],
            ),
          ),
          Text(_fmt.format(_totalAmount), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: primaryColor)),
        ],
      ),
    );
  }

  // ===== STEP 0: Select Payment Method =====
  Widget _buildStep0SelectMethod(bool isDark, Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Select Payment Method', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : Colors.black87)),
        const SizedBox(height: 20),
        _buildMethodTile('UPI', 'Pay via UPI App instantly', Icons.account_balance, _paymentMethod == 'UPI', () => setState(() => _paymentMethod = 'UPI'), isDark, primaryColor),
        const SizedBox(height: 12),
        _buildMethodTile('Card', 'Credit or Debit Card', Icons.credit_card, _paymentMethod == 'Card', () => setState(() => _paymentMethod = 'Card'), isDark, primaryColor),
        const SizedBox(height: 30),
        _buildFullWidthButton('CONTINUE', primaryColor, () => setState(() => _step = 1)),
      ],
    );
  }

  // ===== STEP 1A: UPI App List =====
  Widget _buildStep1UpiApps(bool isDark, Color primaryColor) {
    final upiApps = [
      {'name': 'Google Pay', 'icon': Icons.account_balance_wallet, 'color': Colors.blue},
      {'name': 'PhonePe', 'icon': Icons.payment, 'color': Colors.purple},
      {'name': 'Paytm', 'icon': Icons.account_balance, 'color': Colors.cyan},
      {'name': 'CRED', 'icon': Icons.credit_score, 'color': Colors.white},
      {'name': 'Amazon Pay', 'icon': Icons.shopping_bag, 'color': Colors.orange},
      {'name': 'FinAIMT UPI', 'icon': Icons.security, 'color': primaryColor},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            GestureDetector(onTap: () => setState(() => _step = 0), child: Icon(Icons.arrow_back_ios, size: 18, color: isDark ? Colors.white54 : Colors.black45)),
            const SizedBox(width: 10),
            Text('Select UPI App', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : Colors.black87)),
          ],
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: upiApps.map((app) => _buildUpiAppItem(
            app['name'] as String,
            app['icon'] as IconData,
            app['color'] as Color,
            isDark,
          )).toList(),
        ),
        const SizedBox(height: 30),
        _buildFullWidthButton(
          'PAY ${_fmt.format(_totalAmount)}',
          _selectedUpiApp.isEmpty ? Colors.grey : primaryColor,
          _selectedUpiApp.isEmpty ? null : () => _processUpiPayment(),
        ),
      ],
    );
  }

  // ===== STEP 1B: Card Details =====
  Widget _buildStep1CardDetails(bool isDark, Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            GestureDetector(onTap: () => setState(() => _step = 0), child: Icon(Icons.arrow_back_ios, size: 18, color: isDark ? Colors.white54 : Colors.black45)),
            const SizedBox(width: 10),
            Text('Enter Card Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : Colors.black87)),
          ],
        ),
        const SizedBox(height: 20),

        // Card type toggle
        Row(
          children: [
            _buildCardTypeChip('Credit Card', isDark, primaryColor),
            const SizedBox(width: 12),
            _buildCardTypeChip('Debit Card', isDark, primaryColor),
          ],
        ),
        const SizedBox(height: 20),

        // Card number
        TextField(
          controller: _cardNumberCtrl,
          keyboardType: TextInputType.number,
          style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 16, letterSpacing: 2),
          decoration: InputDecoration(
            labelText: 'Card Number',
            labelStyle: TextStyle(color: isDark ? Colors.white30 : Colors.black38, fontSize: 13),
            prefixIcon: const Icon(Icons.credit_card, size: 20),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.black12)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryColor)),
          ),
        ),
        const SizedBox(height: 15),

        // Expiry + CVV
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _expiryCtrl,
                keyboardType: TextInputType.number,
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  labelText: 'MM/YY',
                  labelStyle: TextStyle(color: isDark ? Colors.white30 : Colors.black38, fontSize: 13),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.black12)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryColor)),
                ),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: TextField(
                controller: _cvvCtrl,
                keyboardType: TextInputType.number,
                obscureText: true,
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  labelText: 'CVV',
                  labelStyle: TextStyle(color: isDark ? Colors.white30 : Colors.black38, fontSize: 13),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.black12)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryColor)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),

        // Card PIN
        TextField(
          controller: _cardPinCtrl,
          keyboardType: TextInputType.number,
          obscureText: true,
          style: TextStyle(color: isDark ? Colors.white : Colors.black87, letterSpacing: 4),
          decoration: InputDecoration(
            labelText: 'Card PIN',
            labelStyle: TextStyle(color: isDark ? Colors.white30 : Colors.black38, fontSize: 13),
            prefixIcon: const Icon(Icons.lock_outline, size: 20),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.black12)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryColor)),
          ),
        ),
        const SizedBox(height: 12),

        // Security badge
        Row(
          children: [
            const Icon(Icons.verified_user, color: Colors.green, size: 14),
            const SizedBox(width: 6),
            Text('256-bit SSL Encrypted • PCI DSS Compliant', style: TextStyle(color: Colors.green.withOpacity(0.7), fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 25),

        _buildFullWidthButton(
          'PAY ${_fmt.format(_totalAmount)}',
          primaryColor,
          () => _processCardPayment(),
        ),
      ],
    );
  }

  // ===== STEP 2: Processing =====
  Widget _buildStep2Processing(bool isDark, Color primaryColor) {
    return SizedBox(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: 40, height: 40, child: CircularProgressIndicator(strokeWidth: 3, color: primaryColor)),
            const SizedBox(height: 25),
            Text('Processing Payment...', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : Colors.black87)),
            const SizedBox(height: 8),
            Text(
              _paymentMethod == 'UPI' ? 'Verifying with $_selectedUpiApp' : 'Authorizing $_cardType',
              style: TextStyle(color: isDark ? Colors.white30 : Colors.black38, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  // ===== STEP 3: Success Receipt =====
  Widget _buildStep3Success(bool isDark, Color primaryColor) {
    final txn = ref.read(transactionHistoryProvider).firstWhere((t) => t.txnId == _txnId);
    
    return Column(
      children: [
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(Icons.check_circle_rounded, color: primaryColor, size: 50),
        ),
        const SizedBox(height: 20),
        Text('Payment Successful!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
        const SizedBox(height: 6),
        Text(txn.formattedAmount, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: primaryColor)),
        const SizedBox(height: 25),

        // Receipt card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
          ),
          child: Column(
            children: [
              _receiptRow('Transaction ID', txn.txnId, isDark, isMono: true),
              _divider(isDark),
              _receiptRow('From', txn.fromAccount, isDark),
              _divider(isDark),
              _receiptRow('To', txn.toAccount, isDark),
              _divider(isDark),
              _receiptRow('Date & Time', txn.formattedDate, isDark),
              _divider(isDark),
              _receiptRow('Payment', _paymentMethod == 'UPI' ? _selectedUpiApp : '$_cardType ****${_cardNumberCtrl.text.length >= 4 ? _cardNumberCtrl.text.substring(_cardNumberCtrl.text.length - 4) : '0000'}', isDark),
              _divider(isDark),
              _receiptRow('Asset', '${txn.quantity.toStringAsFixed(2)} × ${txn.assetName}', isDark),
              _divider(isDark),
              _receiptRow('Status', txn.status, isDark, valueColor: Colors.green),
            ],
          ),
        ),
        const SizedBox(height: 25),
        _buildFullWidthButton('DONE', primaryColor, () => Navigator.pop(context, true)),
      ],
    );
  }

  // ===== Payment Processing Logic =====
  Future<void> _processUpiPayment() async {
    setState(() { _step = 2; _isProcessing = true; });
    await Future.delayed(const Duration(milliseconds: 1200));

    if (!mounted) return;
    setState(() => _step = 1); // Temporarily go back so PIN dialog shows on top

    bool pinSuccess = false;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => UpiPinDialog(
        bankName: _selectedUpiApp,
        onPinEntered: (pin) async {
          if (pin.length != 4) throw Exception('Invalid PIN');
          pinSuccess = true;
        },
      ),
    );

    if (!pinSuccess || !mounted) {
      setState(() { _step = 1; _isProcessing = false; });
      return;
    }

    setState(() => _step = 2);
    await Future.delayed(const Duration(milliseconds: 800));

    _finalizePayment(_selectedUpiApp);
  }

  Future<void> _processCardPayment() async {
    if (_cardNumberCtrl.text.length < 4 || _expiryCtrl.text.isEmpty || _cvvCtrl.text.isEmpty || _cardPinCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all card details'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    setState(() { _step = 2; _isProcessing = true; });
    await Future.delayed(const Duration(milliseconds: 2000));
    
    final lastFour = _cardNumberCtrl.text.length >= 4 ? _cardNumberCtrl.text.substring(_cardNumberCtrl.text.length - 4) : '0000';
    _finalizePayment('$_cardType ****$lastFour');
  }

  void _finalizePayment(String paymentApp) {
    // Record transaction
    final txnId = ref.read(transactionHistoryProvider.notifier).addTransaction(
      assetName: widget.assetName,
      category: widget.category,
      side: widget.side,
      quantity: widget.quantity,
      pricePerUnit: widget.pricePerUnit,
      paymentMethod: _paymentMethod,
      paymentApp: paymentApp,
    );

    // Update state based on category
    if (widget.category == 'Loans' && widget.itemId != null) {
      // Handle Loan Repayment
      ref.read(loansProvider.notifier).payEMI('USER_ID', widget.itemId!);
    } else if (widget.category != 'Loans') {
      // Default to Portfolio Investment trade
      ref.read(userPortfolioProvider.notifier).tradeInvestment(
        assetId: widget.itemId ?? widget.assetName.replaceAll(' ', '_').toUpperCase(),
        assetName: widget.assetName,
        category: widget.category,
        quantity: widget.quantity,
        price: widget.pricePerUnit,
        side: widget.side,
      );
    }

    setState(() {
      _txnId = txnId;
      _step = 3;
      _isProcessing = false;
    });
  }

  // ===== Shared UI Helpers =====
  Widget _buildMethodTile(String title, String sub, IconData icon, bool isSel, VoidCallback onTap, bool isDark, Color primaryColor) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isSel ? primaryColor.withOpacity(0.05) : (isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.02)),
          border: Border.all(color: isSel ? primaryColor : (isDark ? Colors.white10 : Colors.black12), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: isSel ? primaryColor.withOpacity(0.1) : Colors.grey.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: isSel ? primaryColor : Colors.grey, size: 22),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isSel ? primaryColor : (isDark ? Colors.white : Colors.black87))),
                  Text(sub, style: TextStyle(fontSize: 12, color: isDark ? Colors.white30 : Colors.black54)),
                ],
              ),
            ),
            if (isSel) Icon(Icons.check_circle, color: primaryColor, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildUpiAppItem(String name, IconData icon, Color color, bool isDark) {
    final isSelected = _selectedUpiApp == name;
    return GestureDetector(
      onTap: () => setState(() => _selectedUpiApp = name),
      child: Container(
        width: 90,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? color : color.withOpacity(0.15), width: isSelected ? 2 : 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 8),
            Text(
              name == 'Google Pay' ? 'GPay' : name == 'FinAIMT UPI' ? 'FinAIMT' : name,
              style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 10, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            if (isSelected) ...[
              const SizedBox(height: 4),
              Icon(Icons.check_circle, color: color, size: 14),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCardTypeChip(String label, bool isDark, Color primaryColor) {
    final isSel = _cardType == label;
    return GestureDetector(
      onTap: () => setState(() => _cardType = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSel ? primaryColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSel ? primaryColor : (isDark ? Colors.white10 : Colors.black12)),
        ),
        child: Text(label, style: TextStyle(color: isSel ? primaryColor : (isDark ? Colors.white54 : Colors.black54), fontWeight: FontWeight.bold, fontSize: 12)),
      ),
    );
  }

  Widget _buildFullWidthButton(String label, Color color, VoidCallback? onTap) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _isProcessing ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }

  Widget _receiptRow(String label, String value, bool isDark, {bool isMono = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: isDark ? Colors.white38 : Colors.black45, fontSize: 13)),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? (isDark ? Colors.white : Colors.black87),
                fontSize: isMono ? 12 : 13,
                fontWeight: FontWeight.w600,
                fontFamily: isMono ? 'monospace' : null,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider(bool isDark) {
    return Divider(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05), height: 1);
  }
}

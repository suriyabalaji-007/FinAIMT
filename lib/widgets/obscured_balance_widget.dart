import 'package:flutter/material.dart';
import 'package:fin_aimt/core/theme.dart';
import 'package:fin_aimt/widgets/upi_pin_dialog.dart';
import 'package:intl/intl.dart';

class ObscuredBalanceWidget extends StatefulWidget {
  final double balance;
  final TextStyle textStyle;
  final Alignment iconAlignment;
  final bool isHeader;

  const ObscuredBalanceWidget({
    super.key,
    required this.balance,
    required this.textStyle,
    this.iconAlignment = Alignment.center,
    this.isHeader = false,
  });

  @override
  State<ObscuredBalanceWidget> createState() => _ObscuredBalanceWidgetState();
}

class _ObscuredBalanceWidgetState extends State<ObscuredBalanceWidget> {
  bool _isVisible = false;
  final _format = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

  void _triggerPinFlow() {
    if (_isVisible) {
      setState(() => _isVisible = false);
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => UpiPinDialog(
        onPinEntered: (pin) async {
          // In a real app, validate PIN here. For now, any 4 digits work.
          if (pin == '0000') throw Exception('Incorrect PIN');
          setState(() => _isVisible = true);
          
          // Auto-hide after 15 seconds for security
          Future.delayed(const Duration(seconds: 15), () {
            if (mounted) setState(() => _isVisible = false);
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _triggerPinFlow,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            _isVisible ? _format.format(widget.balance) : '₹ •••••••',
            style: widget.textStyle,
          ),
          const SizedBox(width: 8),
          Icon(
            _isVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            color: widget.isHeader ? Colors.white70 : AppColors.primary,
            size: widget.textStyle.fontSize! * 0.7,
          ),
        ],
      ),
    );
  }
}

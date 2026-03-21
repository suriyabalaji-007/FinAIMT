import 'package:flutter/material.dart';
import 'package:fin_aimt/core/theme.dart';

class UpiPinDialog extends StatefulWidget {
  final Future<void> Function(String pin) onPinEntered;
  final String bankName;

  const UpiPinDialog({
    super.key, 
    required this.onPinEntered,
    this.bankName = 'HDFC Bank',
  });

  @override
  State<UpiPinDialog> createState() => _UpiPinDialogState();
}

class _UpiPinDialogState extends State<UpiPinDialog> {
  String _pin = '';
  bool _isLoading = false;
  String? _error;

  void _onKeyPress(String digit) {
    if (_pin.length < 4 && !_isLoading) {
      setState(() {
        _pin += digit;
        _error = null;
      });
    }
  }

  void _onBackspace() {
    if (_pin.isNotEmpty && !_isLoading) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
        _error = null;
      });
    }
  }

  Future<void> _submitPin() async {
    if (_pin.length == 4 && !_isLoading) {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      try {
        // Mock authentication delay
        await Future.delayed(const Duration(seconds: 1));
        await widget.onPinEntered(_pin);
        if (mounted) Navigator.pop(context);
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _error = e.toString().replaceAll('Exception: ', '');
            _pin = '';
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: const BoxDecoration(
                color: Color(0xFF1E3C72),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.account_balance, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.bankName, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        const Text('Enter 4-digit UPI PIN', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                  const Icon(Icons.security, color: Colors.white54, size: 20),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Error Message
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.bold)),
              ),

            // PIN Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                final isFilled = index < _pin.length;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: isFilled ? Colors.black87 : Colors.grey.shade300,
                    shape: BoxShape.circle,
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),
            
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                ),
              ),

            const SizedBox(height: 20),

            // Keypad
            Container(
              color: Colors.grey.shade50,
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 30),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildKey('1'),
                      _buildKey('2'),
                      _buildKey('3'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildKey('4'),
                      _buildKey('5'),
                      _buildKey('6'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildKey('7'),
                      _buildKey('8'),
                      _buildKey('9'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionKey(Icons.backspace_outlined, _onBackspace, color: Colors.orange),
                      _buildKey('0'),
                      _buildActionKey(Icons.check_circle, _submitPin, 
                        color: _pin.length == 4 ? Colors.green : Colors.grey.shade400,
                        isSolid: true
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKey(String digit) {
    return InkWell(
      onTap: () => _onKeyPress(digit),
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 65,
        height: 65,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Text(digit, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w500, color: Colors.black87)),
      ),
    );
  }

  Widget _buildActionKey(IconData icon, VoidCallback onTap, {required Color color, bool isSolid = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 65,
        height: 65,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSolid ? color : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 32, color: isSolid ? Colors.white : color),
      ),
    );
  }
}

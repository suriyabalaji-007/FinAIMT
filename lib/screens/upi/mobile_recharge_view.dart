import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fin_aimt/core/theme.dart';
import 'package:fin_aimt/data/providers/finance_provider.dart';
import 'package:fin_aimt/data/models/finance_models.dart';
import 'package:fin_aimt/widgets/upi_pin_dialog.dart';

class MobileRechargeView extends ConsumerStatefulWidget {
  const MobileRechargeView({super.key});

  @override
  ConsumerState<MobileRechargeView> createState() => _MobileRechargeViewState();
}

class _MobileRechargeViewState extends ConsumerState<MobileRechargeView> {
  final _phoneController = TextEditingController();
  String? _selectedOperator;
  
  final List<String> _operators = ['Jio', 'Airtel', 'Vi', 'BSNL'];
  
  final List<Map<String, dynamic>> _mockPlans = [
    {
      'operator': 'Jio', 'price': 299, 'data': '2GB/day', 
      'validity': '28 Days', 'desc': 'Truly Unlimited Calls + 100 SMS/day. Eligible for 5G.'
    },
    {
      'operator': 'Jio', 'price': 666, 'data': '1.5GB/day', 
      'validity': '84 Days', 'desc': 'Truly Unlimited Calls + 100 SMS/day.'
    },
    {
      'operator': 'Airtel', 'price': 349, 'data': '2.5GB/day', 
      'validity': '28 Days', 'desc': 'Unlimited Calls + Airtel Xstream Play.'
    },
    {
      'operator': 'Airtel', 'price': 479, 'data': '1.5GB/day', 
      'validity': '56 Days', 'desc': 'Unlimited Calls + Apollo 24|7 Circle.'
    },
    {
      'operator': 'Vi', 'price': 299, 'data': '1.5GB/day', 
      'validity': '28 Days', 'desc': 'Binge All Night + Weekend Data Rollover.'
    },
    {
      'operator': 'BSNL', 'price': 199, 'data': '2GB/day', 
      'validity': '30 Days', 'desc': 'Unlimited Voice + PRBT.'
    },
  ];

  @override
  Widget build(BuildContext context) {
    // Filter plans based on selected operator, or show all if none selected
    final displayPlans = _selectedOperator == null 
        ? _mockPlans 
        : _mockPlans.where((p) => p['operator'] == _selectedOperator).toList();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Mobile Recharge', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Enter amount or mobile number', style: TextStyle(color: Colors.white, fontSize: 16)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(color: Colors.white, fontSize: 20),
                    decoration: InputDecoration(
                      hintText: '10-digit mobile number',
                      hintStyle: const TextStyle(color: Colors.white30),
                      prefixIcon: const Icon(Icons.phone_android, color: AppColors.primary),
                      filled: true,
                      fillColor: Colors.grey.shade900,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primary)),
                    ),
                    onChanged: (val) {
                      if (val.length >= 2 && mounted) {
                        // Auto-detect mock operator based on prefix
                        setState(() {
                          if (val.startsWith('9')) _selectedOperator = 'Airtel';
                          else if (val.startsWith('8')) _selectedOperator = 'Jio';
                          else if (val.startsWith('7')) _selectedOperator = 'Vi';
                          else _selectedOperator = null;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                  
                  const Text('Select Operator', style: TextStyle(color: Colors.white, fontSize: 16)),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _operators.map((op) => _buildOperatorChip(op)).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  const Text('Recommended Plans', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildPlanCard(displayPlans[index]),
              childCount: displayPlans.length,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOperatorChip(String operator) {
    final isSelected = _selectedOperator == operator;
    return GestureDetector(
      onTap: () => setState(() => _selectedOperator = operator),
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.2) : Colors.transparent,
          border: Border.all(color: isSelected ? AppColors.primary : Colors.grey.shade800),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          operator,
          style: TextStyle(
            color: isSelected ? AppColors.primary : Colors.white70,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildPlanCard(Map<String, dynamic> plan) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.flash_on, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text('₹${plan['price']}', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              ),
              ElevatedButton(
                onPressed: () => _handleRecharge(plan),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text('Recharge'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildPlanDetail('DATA', plan['data']),
              _buildPlanDetail('VALIDITY', plan['validity']),
              _buildPlanDetail('OPERATOR', plan['operator']),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white10),
          const SizedBox(height: 8),
          Text(plan['desc'], style: const TextStyle(color: Colors.white60, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildPlanDetail(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white30, fontSize: 11, letterSpacing: 1)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
      ],
    );
  }

  void _handleRecharge(Map<String, dynamic> plan) {
    final phone = _phoneController.text.trim();
    if (phone.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid 10-digit mobile number')));
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => UpiPinDialog(
        bankName: 'HDFC Bank - •••• 1234',
        onPinEntered: (pin) async {
          if (pin == '0000') throw Exception('Incorrect PIN');
          
          if (context.mounted) {
            // Process Recharge
            final amount = (plan['price'] as int).toDouble();
            ref.read(financeDataProvider.notifier).addTransaction(
              Transaction(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                title: '${plan['operator']} Recharge',
                subtitle: 'Mobile: $phone',
                amount: amount,
                date: DateTime.now(),
                type: TransactionType.debit,
                category: 'Bills & Utilities',
                icon: Icons.phone_android,
              ),
            );

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ Recharge of ₹${plan['price']} successful for $phone'),
                backgroundColor: AppColors.primary,
              ),
            );
            Navigator.pop(context); // Go back to UPI Hub
          }
        },
      ),
    );
  }
}

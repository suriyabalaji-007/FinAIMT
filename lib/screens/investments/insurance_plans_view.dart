import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fin_aimt/core/theme.dart';
import 'package:fin_aimt/data/models/finance_models.dart';
import 'package:fin_aimt/data/repositories/mock_repository.dart';
import 'package:fin_aimt/data/providers/investment_provider.dart';
import 'package:fin_aimt/widgets/unified_payment_flow.dart';

class InsurancePlansView extends ConsumerStatefulWidget {
  const InsurancePlansView({super.key});

  @override
  ConsumerState<InsurancePlansView> createState() => _InsurancePlansViewState();
}

class _InsurancePlansViewState extends ConsumerState<InsurancePlansView> {
  final List<InsuranceProduct> products = MockRepository.getInsuranceProducts();
  late InsuranceProduct selectedPlan;
  
  double coverageAmount = 500000;
  int userAge = 30;
  String paymentMode = 'Annual'; // 'Monthly' or 'Annual'

  @override
  void initState() {
    super.initState();
    selectedPlan = products.first;
    coverageAmount = selectedPlan.sumInsured.toDouble();
  }

  double get calculatedPremium {
    double baseRate = selectedPlan.annualPremium / selectedPlan.sumInsured;
    double ageLoading = 1.0 + (userAge > 30 ? (userAge - 30) * 0.02 : 0.0);
    double annual = (baseRate * coverageAmount) * ageLoading;
    return paymentMode == 'Monthly' ? (annual / 12) * 1.05 : annual;
  }

  void _buyNow() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardTheme.color,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Confirm Insurance Purchase', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            _summaryRow('Plan', selectedPlan.planName),
            _summaryRow('Provider', selectedPlan.provider),
            _summaryRow('Cover', NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(coverageAmount)),
            _summaryRow('Premium', '${NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(calculatedPremium)} ($paymentMode)'),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await UnifiedPaymentFlow.show(
                    context: context,
                    ref: ref,
                    assetName: selectedPlan.planName,
                    category: 'Insurance',
                    quantity: 1,
                    pricePerUnit: calculatedPremium,
                    side: 'buy',
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: const Text('PROCEED TO PAYMENT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Insurance Marketplace', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Plan Selection Header
            Container(
              height: 180,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final p = products[index];
                  final isSelected = selectedPlan.id == p.id;
                  return GestureDetector(
                    onTap: () => setState(() {
                      selectedPlan = p;
                      coverageAmount = p.sumInsured.toDouble();
                    }),
                    child: Container(
                      width: 150,
                      margin: const EdgeInsets.only(right: 15),
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: isSelected ? Theme.of(context).colorScheme.primary : (isDark ? Colors.white.withOpacity(0.05) : Colors.white),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isSelected ? Colors.transparent : (isDark ? Colors.white10 : Colors.black12)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            p.type == 'Term Life' ? Icons.favorite : Icons.health_and_safety,
                            color: isSelected ? Colors.white : Theme.of(context).colorScheme.primary,
                          ),
                          const Spacer(),
                          Text(p.planName, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.white : null, fontSize: 13)),
                          Text(p.provider, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white70 : Colors.grey)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Coverage Details
            Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E2124) : Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Coverage Amount', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black54)),
                  const SizedBox(height: 10),
                  Text(fmt.format(coverageAmount), style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                  Slider(
                    value: coverageAmount,
                    min: selectedPlan.sumInsured.toDouble() / 2,
                    max: selectedPlan.sumInsured * 5.0,
                    divisions: 20,
                    onChanged: (val) => setState(() => coverageAmount = val),
                  ),
                  
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 20),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Payment Mode', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          const SizedBox(height: 8),
                          ToggleButtons(
                            borderRadius: BorderRadius.circular(10),
                            constraints: const BoxConstraints(minHeight: 35, minWidth: 80),
                            isSelected: [paymentMode == 'Monthly', paymentMode == 'Annual'],
                            onPressed: (index) => setState(() => paymentMode = index == 0 ? 'Monthly' : 'Annual'),
                            children: const [Text('Monthly'), Text('Annual')],
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Your Age', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          const SizedBox(height: 8),
                          DropdownButton<int>(
                            value: userAge,
                            onChanged: (val) => setState(() => userAge = val!),
                            items: List.generate(50, (i) => 18 + i).map((a) => DropdownMenuItem(value: a, child: Text('$a years'))).toList(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Benefits
            Text('Exclusive Benefits', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
            const SizedBox(height: 15),
            ...selectedPlan.benefits.map((f) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 18),
                  const SizedBox(width: 12),
                  Expanded(child: Text(f, style: const TextStyle(fontSize: 14))),
                ],
              ),
            )),

            
            const SizedBox(height: 40),
            
            // Premium Summary
            Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.primary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Premium', style: TextStyle(color: Colors.white70, fontSize: 14)),
                      Text(paymentMode, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(fmt.format(calculatedPremium), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                      ElevatedButton(
                        onPressed: _buyNow,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Theme.of(context).colorScheme.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        child: const Text('BUY NOW', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}

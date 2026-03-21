import 'package:flutter/material.dart';
import 'package:fin_aimt/core/theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fin_aimt/data/providers/finance_provider.dart';
import 'package:fin_aimt/screens/home/home_dashboard_view.dart';
import 'package:fin_aimt/screens/investments/investments_view.dart';
import 'package:fin_aimt/screens/ai_bot/ai_bot_view.dart';
import 'package:fin_aimt/screens/loans/loans_view.dart';
import 'package:fin_aimt/screens/expenses/expenses_view.dart';
import 'package:fin_aimt/screens/profile/profile_view.dart';
import 'package:fin_aimt/screens/upi/upi_home_view.dart';
import 'package:fin_aimt/core/services/notification_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
      ref.read(notificationProvider.notifier).connect('mock-user-id'));
  }

  @override
  void dispose() {
    ref.read(notificationProvider.notifier).disconnect();
    super.dispose();
  }

  static const List<Widget> _widgetOptions = <Widget>[
    HomeDashboardView(),   // 0 - Home
    UPIHomeView(),         // 1 - Banking
    InvestmentsView(),     // 2 - Investment
    LoansView(),           // 3 - Loans
    ExpensesView(),        // 4 - Tax
    ProfileView(),         // 5 - Profile (accessible from header)
    AIBotView(),           // 6 - AI Bot (accessible from header)
  ];

  @override
  Widget build(BuildContext context) {
    final selectedIndex = ref.watch(currentTabProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          _widgetOptions[selectedIndex],
          const PaymentNotificationOverlay(),

          // Custom Floating Bottom Navigation
          Positioned(
            left: 16,
            right: 16,
            bottom: 25,
            child: Container(
              height: 80,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1D1E).withOpacity(0.95),
                borderRadius: BorderRadius.circular(34),
                border: Border.all(color: Colors.white10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(0, Icons.home_rounded, 'Home', selectedIndex),
                  _buildNavItem(1, Icons.account_balance, 'Banking', selectedIndex),
                  _buildNavItem(2, Icons.show_chart_rounded, 'Invest', selectedIndex),
                  _buildNavItem(3, Icons.account_balance_wallet_outlined, 'Loans', selectedIndex),
                  _buildNavItem(4, Icons.receipt_long_outlined, 'Tax', selectedIndex),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int viewIndex, IconData icon, String label, int selectedIndex) {
    final isSelected = selectedIndex == viewIndex;

    return InkWell(
      onTap: () => ref.read(currentTabProvider.notifier).setTab(viewIndex),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: isSelected ? BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ) : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isSelected ? AppColors.primary : AppColors.textHint, size: 22),
            const SizedBox(height: 3),
            Text(label, 
              style: TextStyle(
                color: isSelected ? AppColors.primary : AppColors.textHint, 
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              )),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Primary Navigation Stack
          IndexedStack(
            index: selectedIndex > 4 ? 0 : selectedIndex,
            children: _widgetOptions.sublist(0, 5),
          ),
          
          // Full-screen Overlays for Header Actions
          if (selectedIndex == 5) 
            const Positioned.fill(child: ProfileView()),
          if (selectedIndex == 6) 
            const Positioned.fill(child: AIBotView()),
          
          const PaymentNotificationOverlay(),

          // Custom Floating Bottom Navigation (Monifi Style)
          Positioned(
            left: 16,
            right: 16,
            bottom: 25,
            child: Container(
              height: 80,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1D1E).withOpacity(0.95) : Colors.white.withOpacity(0.98),
                borderRadius: BorderRadius.circular(30), // Smaller, cleaner radius like image
                border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.4 : 0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(0, Icons.home_rounded, 'Home', selectedIndex, isDark, primaryColor),
                  _buildNavItem(1, Icons.account_balance, 'Banking', selectedIndex, isDark, primaryColor),
                  _buildNavItem(2, Icons.show_chart_rounded, 'Invest', selectedIndex, isDark, primaryColor),
                  _buildNavItem(3, Icons.account_balance_wallet_outlined, 'Loans', selectedIndex, isDark, primaryColor),
                  _buildNavItem(4, Icons.receipt_long_outlined, 'Tax', selectedIndex, isDark, primaryColor),
                  _buildNavItem(6, Icons.auto_awesome, 'AI Bot', selectedIndex, isDark, primaryColor),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int viewIndex, IconData icon, String label, int selectedIndex, bool isDark, Color primaryColor) {
    final isSelected = selectedIndex == viewIndex;
    final activeColor = primaryColor;
    final inactiveColor = isDark ? const Color(0xFF666666) : const Color(0xFFB0B0B0);

    return InkWell(
      onTap: () => ref.read(currentTabProvider.notifier).setTab(viewIndex),
      borderRadius: BorderRadius.circular(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isSelected ? activeColor : inactiveColor, size: 24),
          const SizedBox(height: 5),
          Text(label, 
            style: TextStyle(
              color: isSelected ? activeColor : inactiveColor, 
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            )),
          if (isSelected && !isDark) // Visual dot indicator like modern apps
            Container(
              margin: const EdgeInsets.only(top: 2),
              width: 4,
              height: 4,
              decoration: BoxDecoration(color: activeColor, shape: BoxShape.circle),
            ),
        ],
      ),
    );
  }
}

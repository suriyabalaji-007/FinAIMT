import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fin_aimt/core/theme.dart';
import 'package:fin_aimt/data/providers/finance_provider.dart';

class ProfileView extends ConsumerWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final financeData = ref.watch(financeDataProvider);
    final profile = financeData.userProfile;

    void showAction(String title) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Opening $title...'), behavior: SnackBarBehavior.floating),
      );
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          const SizedBox(height: 40),
          // Profile Header
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: AppColors.highlight.withOpacity(0.1),
                child: const Icon(Icons.person, size: 80, color: AppColors.highlight),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                child: const Icon(Icons.verified, color: Colors.white, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(profile.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text(profile.email, style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 30),

          // Verification Status
          _buildInfoTile(
            context,
            'KYC Status',
            profile.isKycVerified ? 'Verified' : 'Pending',
            profile.isKycVerified ? Icons.verified_user : Icons.warning,
            profile.isKycVerified ? AppColors.success : Colors.orange,
            () => showAction('KYC Details'),
          ),
          
          _buildInfoTile(context, 'PAN Number', profile.panNumber, Icons.badge_outlined, AppColors.highlight, () => showAction('PAN Info')),
          _buildInfoTile(context, 'Aadhaar', profile.aadhaarNumber, Icons.fingerprint, AppColors.highlight, () => showAction('Aadhaar Info')),
          _buildInfoTile(context, 'Risk Profile', profile.riskProfile, Icons.analytics_outlined, Colors.purple, () => showAction('Risk Analysis')),

          const Padding(
            padding: EdgeInsets.fromLTRB(20, 30, 20, 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),

          _buildSettingsTile(Icons.security, 'Security & Privacy', () => showAction('Security')),
          _buildSettingsTile(Icons.notifications_outlined, 'Notification Preferences', () => showAction('Notifications')),
          _buildSettingsTile(Icons.help_outline, 'Help & Support', () => showAction('Help')),
          _buildSettingsTile(Icons.logout, 'Logout', () => showAction('Logout'), color: Colors.redAccent),
          
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildInfoTile(BuildContext context, String label, String value, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: AppColors.textHint, fontSize: 12)),
                Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTile(IconData icon, String title, VoidCallback onTap, {Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppColors.textSecondary),
      title: Text(title, style: TextStyle(color: color ?? AppColors.textPrimary)),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textHint),
      onTap: onTap,
    );
  }
}

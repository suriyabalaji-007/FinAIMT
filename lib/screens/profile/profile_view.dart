import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fin_aimt/core/theme.dart';
import 'package:fin_aimt/data/providers/finance_provider.dart';
import 'package:fin_aimt/main.dart';

class ProfileView extends ConsumerWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final financeData = ref.watch(financeDataProvider);
    final profile = financeData.userProfile;
    final themeMode = ref.watch(themeModeProvider);
    final isDarkMode = themeMode == ThemeMode.dark;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final textPrimary = isLight ? LightColors.textPrimary : Colors.white;
    final textSecondary = isLight ? LightColors.textSecondary : AppColors.textSecondary;

    void showAction(String title) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Opening $title...'), behavior: SnackBarBehavior.floating),
      );
    }

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor, // Ensure solid background
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // Colored Profile Header section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 60, bottom: 40),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDarkMode 
                    ? [const Color(0xFF1A1D1E), const Color(0xFF0E1111)] 
                    : [primaryColor, primaryColor.withOpacity(0.8)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
                boxShadow: isDarkMode ? [] : [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 55,
                        backgroundColor: Colors.white,
                        child: CircleAvatar(
                          radius: 52,
                          backgroundColor: (isDarkMode ? AppColors.surface : Colors.white),
                          child: Icon(Icons.person, size: 70, color: isDarkMode ? AppColors.primary : primaryColor),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: Icon(Icons.verified, color: isDarkMode ? AppColors.primary : primaryColor, size: 18),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Text(profile.name, 
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)
                  ),
                  Text(profile.email, 
                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Verification Status & Info
            _buildInfoTile(
              context,
              'KYC Status',
              profile.isKycVerified ? 'Verified' : 'Pending',
              profile.isKycVerified ? Icons.verified_user : Icons.warning,
              profile.isKycVerified ? (isLight ? LightColors.primary : AppColors.success) : Colors.orange,
              () => showAction('KYC Details'),
            ),
            
            _buildInfoTile(context, 'PAN Number', profile.panNumber, Icons.badge_outlined, isLight ? LightColors.primary : AppColors.highlight, () => showAction('PAN Info')),
            _buildInfoTile(context, 'Aadhaar', profile.aadhaarNumber, Icons.fingerprint, isLight ? LightColors.primary : AppColors.highlight, () => showAction('Aadhaar Info')),
            _buildInfoTile(context, 'Risk Profile', profile.riskProfile, Icons.analytics_outlined, Colors.purple, () => showAction('Risk Analysis')),

            Padding(
              padding: const EdgeInsets.fromLTRB(25, 30, 25, 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Settings', 
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary)
                ),
              ),
            ),

            _buildSettingsTile(context, Icons.security, 'Security & Privacy', () => showAction('Security')),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 25),
              leading: Icon(Icons.dark_mode_outlined, color: textSecondary),
              title: Text('Dark Mode', style: TextStyle(color: textPrimary, fontWeight: FontWeight.w500)),
              trailing: Switch(
                value: isDarkMode,
                activeThumbColor: isLight ? LightColors.primary : AppColors.primary,
                onChanged: (val) {
                  ref.read(themeModeProvider.notifier).toggle(val);
                },
              ),
            ),
            _buildSettingsTile(context, Icons.notifications_outlined, 'Notification Preferences', () => showAction('Notifications')),
            _buildSettingsTile(context, Icons.help_outline, 'Help & Support', () => showAction('Help')),
            _buildSettingsTile(context, Icons.logout, 'Logout', () => showAction('Logout'), color: Colors.redAccent),
            
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(BuildContext context, String label, String value, IconData icon, Color color, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 25, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color, 
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05)),
          boxShadow: isDark ? [] : [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, 
                  style: TextStyle(
                    color: isDark ? AppColors.textHint : LightColors.textHint, 
                    fontSize: 11,
                    fontWeight: FontWeight.w500
                  )
                ),
                Text(value, 
                  style: TextStyle(
                    fontWeight: FontWeight.bold, 
                    fontSize: 15,
                    color: isDark ? Colors.white : LightColors.textPrimary
                  )
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTile(BuildContext context, IconData icon, String title, VoidCallback onTap, {Color? color}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 25),
      leading: Icon(icon, color: color ?? (isDark ? AppColors.textSecondary : LightColors.textSecondary)),
      title: Text(title, 
        style: TextStyle(
          color: color ?? (isDark ? Colors.white : LightColors.textPrimary),
          fontWeight: FontWeight.w500
        )
      ),
      trailing: Icon(Icons.chevron_right, color: isDark ? AppColors.textHint : LightColors.textHint, size: 20),
      onTap: onTap,
    );
  }
}

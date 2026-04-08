import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fin_aimt/core/theme.dart';
import 'package:fin_aimt/data/providers/finance_provider.dart';

class GlobalHeader extends ConsumerWidget {
  final String title;
  final String? subtitle;
  final bool showLogo;
  final List<Widget>? actions;

  const GlobalHeader({
    super.key,
    this.title = 'FinAIMT',
    this.subtitle,
    this.showLogo = false,
    this.actions,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final textPrimary = isDark ? Colors.white : LightColors.textPrimary;

    return Container(
      padding: const EdgeInsets.fromLTRB(25, 50, 20, 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              // Stylized Logo
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.auto_graph_rounded, color: primaryColor, size: 24),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'FinAIMT',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      color: primaryColor,
                      height: 1.0,
                    ),
                  ),
                  if (title != 'Fin AIMT' && title != 'FinAIMT')
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: textPrimary.withOpacity(0.6),
                        height: 1.2,
                      ),
                    ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              _headerIconButton(
                context: context,
                icon: Icons.notifications_none_rounded,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('No new notifications'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                color: isDark ? Colors.white70 : LightColors.textPrimary,
              ),
              _headerIconButton(
                context: context,
                icon: Icons.auto_awesome_rounded,
                onTap: () => ref.read(currentTabProvider.notifier).setTab(6),
                color: primaryColor,
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => ref.read(currentTabProvider.notifier).setTab(5),
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: isDark ? Colors.white10 : const Color(0xFFF2F4F7),
                  child: Icon(Icons.person, color: isDark ? Colors.white70 : LightColors.textPrimary, size: 24),
                ),
              ),
              if (actions != null) ...actions!,
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerIconButton({
    required BuildContext context,
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }
}

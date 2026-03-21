import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fin_aimt/core/theme.dart';
import 'package:fin_aimt/data/providers/finance_provider.dart';
import 'package:fin_aimt/screens/home/dashboard_screen.dart';

class GlobalHeader extends ConsumerWidget {
  final String title;
  final String? subtitle;
  final bool showLogo;
  final List<Widget>? actions;

  const GlobalHeader({
    super.key,
    this.title = 'FinAIMT',
    this.subtitle = 'Financial Super App',
    this.showLogo = true,
    this.actions,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.fromLTRB(25, 50, 20, 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (showLogo) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.auto_graph_rounded, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 15),
              ],
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                      color: Colors.white,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.4),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              _headerIconButton(
                icon: Icons.auto_awesome_outlined,
                onTap: () => ref.read(currentTabProvider.notifier).setTab(6),
                color: AppColors.primary,
              ),
              const SizedBox(width: 10),
              _headerIconButton(
                icon: Icons.notifications_none_rounded,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('No new notifications'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              const SizedBox(width: 10),
              _headerIconButton(
                icon: Icons.person_outline_rounded,
                onTap: () => ref.read(currentTabProvider.notifier).setTab(5),
              ),
              if (actions != null) ...actions!,
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerIconButton({
    required IconData icon,
    required VoidCallback onTap,
    Color color = Colors.white,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color.withOpacity(0.8), size: 22),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../features/auth/presentation/dashboard_screen.dart';
import '../../features/auth/presentation/profile_screen.dart';
import '../../features/auth/presentation/statistics_screen.dart';
import '../../features/transactions/presentation/transaction_screen.dart';
import '../../core/theme/app_theme.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  final _screens = const [
    DashboardScreen(),
    TransactionsScreen(),
    StatisticsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    // Removed unused local isDark to satisfy lint; inline brightness checks below

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: _screens[_index],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryGradientStart,
              AppTheme.primaryGradientEnd,
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  0,
                  Icons.dashboard_outlined,
                  Icons.dashboard,
                  'Dashboard',
                ),
                _buildNavItem(
                  1,
                  Icons.receipt_long_outlined,
                  Icons.receipt_long,
                  'Giao dich',
                ),
                _buildNavItem(
                  2,
                  Icons.query_stats_outlined,
                  Icons.query_stats,
                  'Thong ke',
                ),
                _buildNavItem(3, Icons.person_outline, Icons.person, 'Ho so'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    IconData activeIcon,
    String label,
  ) {
    final isSelected = _index == index;

    return InkWell(
      onTap: () => setState(() => _index = index),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 20 : 16,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryGradientStart.withValues(
                  alpha: (Theme.of(context).brightness == Brightness.dark)
                      ? 0.2
                      : 0.1,
                )
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected
                  ? AppTheme.primaryGradientStart
                  : (Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[500]
                        : Colors.grey[600]),
              size: 24,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryGradientStart,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

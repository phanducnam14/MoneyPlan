import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/modern_widgets.dart';
import '../../admin/presentation/admin_screen.dart';
import './auth_controller.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _showChangePasswordDialog(BuildContext context, WidgetRef ref) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Doi mat khau'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ModernTextField(controller: currentPasswordController, label: 'Mat khau hien tai', prefixIcon: Icons.lock, obscureText: true),
                const SizedBox(height: 16),
                ModernTextField(controller: newPasswordController, label: 'Mat khau moi', prefixIcon: Icons.lock, obscureText: true),
                const SizedBox(height: 16),
                ModernTextField(controller: confirmPasswordController, label: 'Xac nhan mat khau', prefixIcon: Icons.lock, obscureText: true),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Huy')),
            FilledButton(
              onPressed: isLoading ? null : () async {
                if (newPasswordController.text != confirmPasswordController.text) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mat khau xac nhan khong khop')));
                  return;
                }
                setState(() => isLoading = true);
                await ref.read(authControllerProvider.notifier).changePassword(currentPassword: currentPasswordController.text, newPassword: newPasswordController.text);
                setState(() => isLoading = false);
                if (context.mounted) {
                  final authState = ref.read(authControllerProvider);
                  if (authState.error != null) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(authState.error!)));
                  } else {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cap nhat mat khau thanh cong')));
                  }
                }
              },
              child: isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Cap nhat'),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangeEmailDialog(BuildContext context, WidgetRef ref) {
    final newEmailController = TextEditingController();
    final passwordController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Thay doi email'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ModernTextField(controller: newEmailController, label: 'Email moi', prefixIcon: Icons.email, keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 16),
                ModernTextField(controller: passwordController, label: 'Mat khau (xac nhan)', prefixIcon: Icons.lock, obscureText: true),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Huy')),
            FilledButton(
              onPressed: isLoading ? null : () async {
                if (!newEmailController.text.contains('@')) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui long nhap email hop le')));
                  return;
                }
                setState(() => isLoading = true);
                await ref.read(authControllerProvider.notifier).changeEmail(newEmail: newEmailController.text, password: passwordController.text);
                setState(() => isLoading = false);
                if (context.mounted) {
                  final authState = ref.read(authControllerProvider);
                  if (authState.error != null) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(authState.error!)));
                  } else {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cap nhat email thanh cong')));
                  }
                }
              },
              child: isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Cap nhat'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final user = auth.user;
    final isAdmin = user?.role == 'admin';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeMode = ref.watch(themeModeProvider);
    final isDarkMode = themeMode == ThemeMode.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark ? [const Color(0xFF0F172A), const Color(0xFF1E293B)] : [const Color(0xFFF8FAFC), Colors.white],
        ),
      ),
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text('Ho so ca nhan', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppTheme.primaryGradientStart.withValues(alpha: 0.1), AppTheme.primaryGradientEnd.withValues(alpha: 0.1)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.primaryGradientStart.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        children: [
                          UserAvatar(name: user?.name ?? 'User', size: 80, fontSize: 28),
                          const SizedBox(height: 16),
                          Text(user?.name ?? 'Nguoi dung', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text(user?.email ?? 'demo@finance.app', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isAdmin ? Colors.orange.withValues(alpha: 0.1) : Colors.blue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(isAdmin ? 'Admin' : 'Nguoi dung', style: TextStyle(fontSize: 13, color: isAdmin ? Colors.orange : Colors.blue, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Cai dat'),
                    const SizedBox(height: 12),
                    _buildSettingsCard(context, isDark, [
                      _SettingsTile(icon: isDarkMode ? Icons.dark_mode : Icons.light_mode, title: 'Che do toi', subtitle: 'Bao ve mat vao ban dem', trailing: Switch(value: isDarkMode, onChanged: (value) => ref.read(themeModeProvider.notifier).state = value ? ThemeMode.dark : ThemeMode.light, activeThumbColor: AppTheme.primaryGradientStart)),
                    ]),
                    const SizedBox(height: 20),
                    _buildSectionTitle('Tai khoan'),
                    const SizedBox(height: 12),
                    _buildSettingsCard(context, isDark, [
                      _SettingsTile(icon: Icons.lock_outline, title: 'Doi mat khau', subtitle: 'Cap nhap mat khau dang nhap', onTap: () => _showChangePasswordDialog(context, ref)),
                      _SettingsTile(icon: Icons.mail_outline, title: 'Thay doi email', subtitle: 'Cap nhat dia chi email', onTap: () => _showChangeEmailDialog(context, ref)),
                    ]),
                    if (isAdmin) ...[
                      const SizedBox(height: 20),
                      _buildSectionTitle('Quan tri'),
                      const SizedBox(height: 12),
                      _buildSettingsCard(context, isDark, [
                        _SettingsTile(icon: Icons.admin_panel_settings_outlined, title: 'Bang dieu khien admin', subtitle: 'Quan ly nguoi dung va he thong', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminScreen()))),
                      ]),
                    ],
                    const SizedBox(height: 20),
                    _buildSectionTitle('Khac'),
                    const SizedBox(height: 12),
                    _buildSettingsCard(context, isDark, [
                      _SettingsTile(icon: Icons.info_outline, title: 'Ve ung dung', subtitle: 'Phien ban 1.0.0', onTap: () => showAboutDialog(context: context, applicationName: 'Smart Finance', applicationVersion: '1.0.0', applicationLegalese: '© 2026 Smart Finance. All rights reserved.')),
                    ]),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ModernButton(text: 'Dang xuat', isOutlined: true, icon: Icons.logout, onPressed: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) => AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            title: const Text('Dang xuat'),
                            content: const Text('Ban chan chan muon dang xuat khoi ung dung?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Huy')),
                              FilledButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  ref.read(authControllerProvider.notifier).logout();
                                },
                                child: const Text('Dang xuat'),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1F2937))),
    );
  }

  Widget _buildSettingsCard(BuildContext context, bool isDark, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({required this.icon, required this.title, required this.subtitle, this.trailing, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppTheme.primaryGradientStart.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: AppTheme.primaryGradientStart, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF1F2937))),
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                  ],
                ),
              ),
              if (trailing != null) ...[trailing!],
              if (onTap != null && trailing == null) Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}


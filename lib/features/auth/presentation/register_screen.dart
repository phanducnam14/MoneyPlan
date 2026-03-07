import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/modern_widgets.dart';
import 'auth_controller.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  DateTime? _selectedDate;
  String _gender = 'other';
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                : [const Color(0xFFF8FAFC), Colors.white],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Tao tai khoan', style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -1)),
                  const SizedBox(height: 8),
                  Text('Dang ky de bat dau quan ly tai chinh', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey[600])),
                  const SizedBox(height: 32),

                  ModernTextField(controller: _nameController, label: 'Ho va ten', hint: 'nhap ho va ten', prefixIcon: Icons.badge_outlined,
                    validator: (value) => (value == null || value.isEmpty) ? 'Vui long nhap ho ten' : null),
                  const SizedBox(height: 16),

                  ModernTextField(controller: _emailController, label: 'Email', hint: 'nhap dia chi email', prefixIcon: Icons.email_outlined, keyboardType: TextInputType.emailAddress,
                    validator: (value) => (value == null || !value.contains('@')) ? 'Email khong hop le' : null),
                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2D3748) : const Color(0xFFF7FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: DropdownButton<String>(
                      value: _gender,
                      isExpanded: true,
                      underline: const SizedBox(),
                      items: ['male', 'female', 'other'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value == 'male' ? 'Nam' : value == 'female' ? 'Nu' : 'Khac', style: const TextStyle(fontSize: 15)),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) setState(() => _gender = newValue);
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  ModernTextField(controller: _passwordController, label: 'Mat khau', hint: 'nhap mat khau', prefixIcon: Icons.lock_outline, obscureText: _obscurePassword,
                    suffixIcon: IconButton(icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: Colors.grey[500]), onPressed: () => setState(() => _obscurePassword = !_obscurePassword)),
                    validator: (value) => (value == null || value.length < 6) ? 'Mat khau toi thieu 6 ky tu' : null),
                  const SizedBox(height: 16),

                  ModernTextField(controller: _confirmPasswordController, label: 'Xac nhan mat khau', hint: 'nhap lai mat khau', prefixIcon: Icons.lock_outline, obscureText: _obscureConfirmPassword,
                    suffixIcon: IconButton(icon: Icon(_obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: Colors.grey[500]), onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword)),
                    validator: (value) => (value != _passwordController.text) ? 'Mat khau khong khop' : null),
                  const SizedBox(height: 24),

                  InkWell(
                    onTap: () => _selectDate(context),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2D3748) : const Color(0xFFF7FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today_outlined, color: Colors.grey[500], size: 22),
                          const SizedBox(width: 14),
                          Text(_selectedDate != null ? dateFormat.format(_selectedDate!) : 'Chon ngay sinh', style: TextStyle(fontSize: 15, color: _selectedDate != null ? (isDark ? Colors.white : Colors.black87) : Colors.grey[500])),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (authState.error != null)
                    Container(
                      padding: const EdgeInsets.all(14),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(color: AppTheme.dangerColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.dangerColor.withValues(alpha: 0.3))),
                      child: Row(children: [const Icon(Icons.error_outline, color: AppTheme.dangerColor, size: 22), const SizedBox(width: 12), Expanded(child: Text(authState.error!, style: const TextStyle(color: AppTheme.dangerColor, fontWeight: FontWeight.w500)))]),
                    ),

                  ModernButton(text: 'Tao tai khoan', isLoading: authState.isLoading, icon: Icons.app_registration, onPressed: () async {
                    if (_selectedDate == null) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui long chon ngay sinh'), behavior: SnackBarBehavior.floating));
                      }
                      return;
                    }
                    if (_formKey.currentState!.validate()) {
                      // ignore: use_build_context_synchronously
                      final navigator = Navigator.of(context);
                      await ref.read(authControllerProvider.notifier).register(
                        name: _nameController.text,
                        email: _emailController.text,
                        password: _passwordController.text,
                        dob: _selectedDate != null ? DateFormat('yyyy-MM-dd').format(_selectedDate!) : '',
                        gender: _gender,
                      );
                      
                      // Check registration result
                      final authState = ref.read(authControllerProvider);
                      if (authState.isAuthenticated && mounted) {
                        navigator.popUntil((route) => route.isFirst);
                      }
                    }
                  }),
                  const SizedBox(height: 20),

                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text('Da co tai khoan?', style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500)),
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Dang nhap', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15))),
                  ]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


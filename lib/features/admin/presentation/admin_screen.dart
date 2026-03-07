import 'package:flutter/material.dart';
import '../../../shared/widgets/premium_page.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  late List<({String id, String name, String email, bool blocked, String role, DateTime joinDate})> users;

  @override
  void initState() {
    super.initState();
    users = [
      (id: '1', name: 'Nguyễn Văn A', email: 'nguyenvana@example.com', blocked: false, role: 'user', joinDate: DateTime(2025, 1, 15)),
      (id: '2', name: 'Trần Thị B', email: 'tranthib@example.com', blocked: false, role: 'user', joinDate: DateTime(2025, 2, 10)),
      (id: '3', name: 'Lê Văn C', email: 'levanc@example.com', blocked: true, role: 'user', joinDate: DateTime(2025, 1, 5)),
      (id: '4', name: 'Phạm Thị D', email: 'phamthid@example.com', blocked: false, role: 'admin', joinDate: DateTime(2024, 12, 1)),
    ];
  }

  void _toggleUserStatus(int index) {
    setState(() {
      final user = users[index];
      users[index] = (
        id: user.id,
        name: user.name,
        email: user.email,
        blocked: !user.blocked,
        role: user.role,
        joinDate: user.joinDate,
      );
    });
    _showStatusChangeSnackBar(users[index]);
  }

  void _showStatusChangeSnackBar(({String id, String name, String email, bool blocked, String role, DateTime joinDate}) user) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          user.blocked ? '${user.name} đã bị khóa' : '${user.name} đã được mở khóa',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        backgroundColor: user.blocked ? Colors.red : Colors.green,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showUserDetails(({String id, String name, String email, bool blocked, String role, DateTime joinDate}) user) {
    final initials = user.name.split(' ').map((e) => e[0]).join();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue, Colors.purple],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(user.name)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _DetailRow(label: 'Email', value: user.email, icon: Icons.email),
              _DetailRow(label: 'Vai trò', value: user.role == 'admin' ? '👨‍💼 Quản trị viên' : '👤 Người dùng thường', icon: Icons.badge),
              _DetailRow(label: 'Trạng thái', value: user.blocked ? 'Đã khóa' : 'Đang hoạt động', icon: Icons.security, valueColor: user.blocked ? Colors.red : Colors.green),
              _DetailRow(label: 'Ngày tham gia', value: '${user.joinDate.day}/${user.joinDate.month}/${user.joinDate.year}', icon: Icons.calendar_today),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PremiumPage(
      appBar: AppBar(
        title: const Text('Quản lý người dùng'),
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${users.length} người dùng',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      child: users.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa có người dùng',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Người dùng sẽ hiển thị ở đây',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _UserCard(
                    user: user,
                    onTap: () => _showUserDetails(user),
                    onStatusChanged: () => _toggleUserStatus(index),
                  ),
                );
              },
            ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final ({String id, String name, String email, bool blocked, String role, DateTime joinDate}) user;
  final VoidCallback onTap;
  final VoidCallback onStatusChanged;

  const _UserCard({
    required this.user,
    required this.onTap,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final initials = user.name.split(' ').map((e) => e[0]).join();
    final isAdmin = user.role == 'admin';

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.blue.withValues(alpha: 0.8),
                      Colors.purple.withValues(alpha: 0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // User Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            user.name,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isAdmin)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              '👨‍💼 Admin',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.orange,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: user.blocked
                            ? Colors.red.withValues(alpha: 0.1)
                            : Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        user.blocked ? '🔒 Đã khóa' : '✓ Đang hoạt động',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: user.blocked ? Colors.red : Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Toggle Switch
              Transform.scale(
                scale: 0.85,
                child: Switch(
                  value: user.blocked,
                  onChanged: (value) => onStatusChanged(),
                  activeThumbColor: Colors.white,
                  activeTrackColor: Colors.red,
                  inactiveThumbColor: Colors.white,
                  inactiveTrackColor: Colors.green.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: valueColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


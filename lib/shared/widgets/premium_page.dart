import 'package:flutter/material.dart';

class PremiumPage extends StatelessWidget {
  final Widget child;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final double maxWidth;

  const PremiumPage({
    super.key,
    required this.child,
    this.appBar,
    this.floatingActionButton,
    this.maxWidth = 1100,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

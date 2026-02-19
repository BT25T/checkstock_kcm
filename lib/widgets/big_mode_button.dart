import 'package:flutter/material.dart';

class BigModeButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const BigModeButton({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        icon: Icon(icon),
        label: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Text(title),
        ),
        onPressed: onTap,
      ),
    );
  }
}

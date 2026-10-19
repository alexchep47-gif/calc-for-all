import 'package:flutter/material.dart';

/// Bouton réutilisable pour le clavier de la calculatrice
class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isOperator;
  final bool isWide;

  const CustomButton({
    super.key,
    required this.label,
    required this.onTap,
    this.isOperator = false,
    this.isWide = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).primaryColor;

    Color bgColor;
    Color textColor;

    if (label == '=') {
      bgColor = primary;
      textColor = Colors.white;
    } else if (isOperator) {
      bgColor = isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE3F2FD);
      textColor = primary;
    } else {
      bgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
      textColor = isDark ? Colors.white : Colors.black87;
    }

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: label.length > 2 ? 16 : 22,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Bouton réutilisable avec animation de pression
class CustomButton extends StatefulWidget {
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
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).primaryColor;

    Color bgColor;
    Color textColor;

    if (widget.label == '=') {
      bgColor = primary;
      textColor = Colors.white;
    } else if (widget.isOperator) {
      bgColor = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE3F2FD);
      textColor = primary;
    } else {
      bgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
      textColor = isDark ? Colors.white : Colors.black87;
    }

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: Material(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          elevation: _pressed ? 0 : 2,
          child: Container(
            alignment: Alignment.center,
            child: Text(
              widget.label,
              style: TextStyle(
                fontSize: widget.label.length > 2 ? 15 : 21,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

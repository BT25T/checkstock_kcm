import 'package:flutter/material.dart';

class BigModeButton extends StatefulWidget {
  final Widget title;
  final VoidCallback onTap;

  const BigModeButton({
    super.key,
    required this.title,
    required this.onTap,
  });

  @override
  State<BigModeButton> createState() => _BigModeButtonState();
}

class _BigModeButtonState extends State<BigModeButton> {
  bool _pressed = false;
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final scale = _pressed ? 0.97 : 1.0;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 100),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _hovering
                    ? [
                        const Color(0xFF3A7BD5),
                        const Color(0xFF00D2FF),
                      ]
                    : [
                        const Color.fromARGB(255, 54, 88, 152),
                        const Color.fromARGB(255, 55, 87, 141),
                      ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                )
              ],
            ),
            child: DefaultTextStyle(
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
                height: 1.4,
              ),
              child: widget.title,
            ),
          ),
        ),
      ),
    );
  }
}

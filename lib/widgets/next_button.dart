import 'package:flutter/material.dart';

class NextButton extends StatelessWidget {
  final bool isActive;
  final VoidCallback onPressed;

  const NextButton({
    super.key,
    required this.isActive,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive
              ? Colors.white.withOpacity(0.5)
              : Colors.grey.withOpacity(0.3),
          width: 1,
        ),
        gradient: isActive
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.black.withOpacity(0.8),
                  Colors.white.withOpacity(0.4),
                  Colors.black.withOpacity(0.9),
                ],
                stops: const [
                  0.0, // Position for the first color (top left)
                  0.5, // Position for the second color (center)
                  1.0, // Position for the third color (bottom right)
                ],
              )
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.black.withOpacity(0.8),
                  Colors.grey.withOpacity(0.4),
                  Colors.black.withOpacity(0.9),
                ],
                stops: const [
                  0.0,
                  0.5,
                  1.0,
                ],
              ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: isActive ? onPressed : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Next',
                  style: TextStyle(
                    color: isActive ? Colors.white : Colors.grey,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward,
                  color: isActive ? Colors.white : Colors.grey,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

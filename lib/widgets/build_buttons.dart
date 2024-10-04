import 'package:flutter/material.dart';

Widget buildButton({
  required BuildContext context,
  required IconData icon,
  required bool isSelected,
  required VoidCallback onPressed,
}) {
  return Container(
    width: 50,
    height: 50,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(10),
      gradient: isSelected
          ? const RadialGradient(
              center: Alignment.topLeft,
              radius: 1.0,
              colors: [
                Colors.black,
                Colors.grey,
                Colors.black,
              ],
              stops: [0.0, 0.5, 1.0],
            )
          : null,
    ),
    child: IconButton(
      icon: Icon(icon, color: Colors.white),
      onPressed: onPressed,
    ),
  );
}

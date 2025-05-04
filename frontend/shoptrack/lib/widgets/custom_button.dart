import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget{
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final ButtonStyle? buttonStyle;
  final IconData? icon;
  final double? width;
  final Color? textColor;
  final Color? color;

  const CustomButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.buttonStyle,
    this.icon,
    this.width,
    this.textColor,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context){
    return SizedBox(
      width: width,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: buttonStyle ?? 
          ElevatedButton.styleFrom(
            backgroundColor: color ?? Colors.indigo,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: textColor ?? Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
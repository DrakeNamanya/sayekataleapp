import 'package:flutter/material.dart';

/// Verified badge widget to show PSA is verified
class VerifiedBadge extends StatelessWidget {
  final double? fontSize;
  final double? iconSize;
  
  const VerifiedBadge({
    super.key,
    this.fontSize,
    this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: fontSize != null ? fontSize! * 0.67 : 8,
        vertical: fontSize != null ? fontSize! * 0.33 : 4,
      ),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.verified,
            color: Colors.blue,
            size: iconSize ?? 16,
          ),
          SizedBox(width: fontSize != null ? fontSize! * 0.33 : 4),
          Text(
            'Verified',
            style: TextStyle(
              color: Colors.blue,
              fontSize: fontSize ?? 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

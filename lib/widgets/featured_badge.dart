import 'package:flutter/material.dart';

/// Badge displayed on featured products
class FeaturedBadge extends StatelessWidget {
  final bool isCompact;
  
  const FeaturedBadge({
    super.key,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 12,
        vertical: isCompact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFFB300)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star,
            color: Colors.white,
            size: isCompact ? 14 : 16,
          ),
          const SizedBox(width: 4),
          Text(
            'Featured',
            style: TextStyle(
              color: Colors.white,
              fontSize: isCompact ? 11 : 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Badge displayed on top-performing products (high sales + ratings)
class TopBadge extends StatelessWidget {
  final bool isCompact;
  
  const TopBadge({
    super.key,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 6 : 8,
        vertical: isCompact ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFB300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'Top',
        style: TextStyle(
          color: Colors.white,
          fontSize: isCompact ? 10 : 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

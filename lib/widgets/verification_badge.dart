import 'package:flutter/material.dart';
import '../models/user.dart';
import '../utils/app_theme.dart';

/// Verification Badge Widget
/// Displays user verification status with appropriate icon and color
class VerificationBadge extends StatelessWidget {
  final VerificationStatus status;
  final bool showLabel;
  final double size;

  const VerificationBadge({
    super.key,
    required this.status,
    this.showLabel = true,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: showLabel ? 8 : 4,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getBorderColor(),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getIcon(),
            color: _getIconColor(),
            size: size,
          ),
          if (showLabel) ...[
            SizedBox(width: 4),
            Text(
              status.displayName,
              style: TextStyle(
                color: _getTextColor(),
                fontSize: size * 0.7,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _getIcon() {
    switch (status) {
      case VerificationStatus.verified:
        return Icons.verified;
      case VerificationStatus.inReview:
        return Icons.pending;
      case VerificationStatus.pending:
        return Icons.schedule;
      case VerificationStatus.rejected:
        return Icons.cancel;
      case VerificationStatus.suspended:
        return Icons.block;
    }
  }

  Color _getIconColor() {
    switch (status) {
      case VerificationStatus.verified:
        return AppTheme.successColor;
      case VerificationStatus.inReview:
        return Colors.blue;
      case VerificationStatus.pending:
        return AppTheme.warningColor;
      case VerificationStatus.rejected:
        return AppTheme.errorColor;
      case VerificationStatus.suspended:
        return Colors.grey;
    }
  }

  Color _getBackgroundColor() {
    return _getIconColor().withValues(alpha: 0.1);
  }

  Color _getBorderColor() {
    return _getIconColor().withValues(alpha: 0.3);
  }

  Color _getTextColor() {
    return _getIconColor();
  }
}

/// Verification Status Card
/// Detailed verification status display with description and actions
class VerificationStatusCard extends StatelessWidget {
  final VerificationStatus status;
  final String? additionalInfo;
  final VoidCallback? onActionPressed;
  final String? actionLabel;

  const VerificationStatusCard({
    super.key,
    required this.status,
    this.additionalInfo,
    this.onActionPressed,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: _getBackgroundColor(),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _getBorderColor(),
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getIcon(),
                  color: _getIconColor(),
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        status.displayName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _getIconColor(),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        status.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (additionalInfo != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        additionalInfo!,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (onActionPressed != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onActionPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getIconColor(),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(actionLabel ?? 'Take Action'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getIcon() {
    switch (status) {
      case VerificationStatus.verified:
        return Icons.verified_user;
      case VerificationStatus.inReview:
        return Icons.pending_actions;
      case VerificationStatus.pending:
        return Icons.warning_amber;
      case VerificationStatus.rejected:
        return Icons.error;
      case VerificationStatus.suspended:
        return Icons.block;
    }
  }

  Color _getIconColor() {
    switch (status) {
      case VerificationStatus.verified:
        return AppTheme.successColor;
      case VerificationStatus.inReview:
        return Colors.blue;
      case VerificationStatus.pending:
        return AppTheme.warningColor;
      case VerificationStatus.rejected:
        return AppTheme.errorColor;
      case VerificationStatus.suspended:
        return Colors.grey.shade700;
    }
  }

  Color _getBackgroundColor() {
    return _getIconColor().withValues(alpha: 0.05);
  }

  Color _getBorderColor() {
    return _getIconColor().withValues(alpha: 0.3);
  }
}

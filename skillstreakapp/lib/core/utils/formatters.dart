// lib/core/utils/formatters.dart

import 'package:intl/intl.dart';

class Formatters {
  // Date formatting with null safety
  static String formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    try {
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return 'Invalid Date';
    }
  }

  // DateTime formatting with null safety
  static String formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';
    try {
      return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
    } catch (e) {
      return 'Invalid DateTime';
    }
  }

  // Time formatting with null safety
  static String formatTime(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';
    try {
      return DateFormat('HH:mm').format(dateTime);
    } catch (e) {
      return 'Invalid Time';
    }
  }

  // Number formatting with improved abbreviation
  static String formatNumber(int? number) {
    if (number == null) return '0';
    
    try {
      if (number >= 1000000000) {
        final value = number / 1000000000;
        return '${value.toStringAsFixed(value % 1 == 0 ? 0 : 1)}B';
      } else if (number >= 1000000) {
        final value = number / 1000000;
        return '${value.toStringAsFixed(value % 1 == 0 ? 0 : 1)}M';
      } else if (number >= 1000) {
        final value = number / 1000;
        return '${value.toStringAsFixed(value % 1 == 0 ? 0 : 1)}K';
      }
      return NumberFormat.decimalPattern().format(number);
    } catch (e) {
      return number.toString();
    }
  }

  // Duration formatting with more detailed output
  static String formatDuration(Duration? duration) {
    if (duration == null) return '--';
    
    try {
      if (duration.inDays > 365) {
        final years = (duration.inDays / 365).floor();
        return '${years}y';
      } else if (duration.inDays > 30) {
        final months = (duration.inDays / 30).floor();
        return '${months}mo';
      } else if (duration.inDays > 0) {
        return '${duration.inDays}d';
      } else if (duration.inHours > 0) {
        return '${duration.inHours}h';
      } else if (duration.inMinutes > 0) {
        return '${duration.inMinutes}m';
      } else if (duration.inSeconds > 0) {
        return '${duration.inSeconds}s';
      }
      return 'Just now';
    } catch (e) {
      return '--';
    }
  }

  // File size formatting with more units
  static String formatFileSize(int? bytes) {
    if (bytes == null || bytes < 0) return '0 B';
    
    try {
      if (bytes < 1024) {
        return '$bytes B';
      } else if (bytes < 1024 * 1024) {
        return '${(bytes / 1024).toStringAsFixed(1)} KB';
      } else if (bytes < 1024 * 1024 * 1024) {
        return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
      } else {
        return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
      }
    } catch (e) {
      return '0 B';
    }
  }

  // Format relative time (e.g., "2 days ago")
  static String formatRelativeTime(DateTime? dateTime) {
    if (dateTime == null) return 'Unknown';
    
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return '$minutes ${minutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days ${days == 1 ? 'day' : 'days'} ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    }
  }

  // Format currency
  static String formatCurrency(double? amount, {String symbol = '₹'}) {
    if (amount == null) return '$symbol 0.00';
    
    try {
      return '$symbol ${amount.toStringAsFixed(2)}';
    } catch (e) {
      return '$symbol 0.00';
    }
  }

  // Format percentage
  static String formatPercentage(double? value) {
    if (value == null) return '0%';
    
    try {
      return '${(value * 100).toStringAsFixed(1)}%';
    } catch (e) {
      return '0%';
    }
  }

  // Format phone number
  static String formatPhoneNumber(String? phoneNumber) {
    if (phoneNumber == null || phoneNumber.isEmpty) return '';
    
    final digits = phoneNumber.replaceAll(RegExp(r'\D'), '');
    
    if (digits.length == 10) {
      return '${digits.substring(0, 3)}-${digits.substring(3, 6)}-${digits.substring(6)}';
    } else if (digits.length > 10) {
      final countryCode = digits.substring(0, digits.length - 10);
      final remaining = digits.substring(digits.length - 10);
      return '+$countryCode ${remaining.substring(0, 3)}-${remaining.substring(3, 6)}-${remaining.substring(6)}';
    }
    
    return phoneNumber;
  }

  // Format name (capitalize first letters)
  static String formatName(String? name) {
    if (name == null || name.isEmpty) return '';
    
    try {
      return name.split(' ').map((word) {
        if (word.isEmpty) return '';
        return word[0].toUpperCase() + word.substring(1).toLowerCase();
      }).join(' ');
    } catch (e) {
      return name;
    }
  }
}
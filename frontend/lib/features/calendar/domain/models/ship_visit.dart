import 'package:flutter/material.dart';

/// Ship visit status for calendar events
enum VisitStatus {
  confirmed,
  tentative,
  delayed,
  cancelled,
}

extension VisitStatusExtension on VisitStatus {
  String get displayName {
    switch (this) {
      case VisitStatus.confirmed:
        return 'Onaylandı';
      case VisitStatus.tentative:
        return 'Geçici';
      case VisitStatus.delayed:
        return 'Gecikme';
      case VisitStatus.cancelled:
        return 'İptal';
    }
  }

  /// Colors based on Linear Aesthetic design
  Color get color {
    switch (this) {
      case VisitStatus.confirmed:
        return const Color(0xFF334155); // Slate 700
      case VisitStatus.tentative:
        return const Color(0xFF94A3B8); // Slate 400
      case VisitStatus.delayed:
        return const Color(0xFFE11D48); // Muted Rose
      case VisitStatus.cancelled:
        return const Color(0xFF6B7280); // Gray 500
    }
  }
}

/// Represents a ship visit event for the calendar
class ShipVisit {
  final String id;
  final String shipName;
  final String imoNumber;
  final String portName;
  final String portId;
  final DateTime arrivalDate;
  final DateTime departureDate;
  final VisitStatus status;
  final String? notes;
  final int? orderId;

  const ShipVisit({
    required this.id,
    required this.shipName,
    required this.imoNumber,
    required this.portName,
    required this.portId,
    required this.arrivalDate,
    required this.departureDate,
    required this.status,
    this.notes,
    this.orderId,
  });

  /// Duration of the visit in days
  int get durationDays => departureDate.difference(arrivalDate).inDays + 1;

  /// Check if visit is currently active
  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(arrivalDate) && now.isBefore(departureDate);
  }

  /// Check if visit is in the future
  bool get isUpcoming => arrivalDate.isAfter(DateTime.now());

  /// Check if visit is completed
  bool get isCompleted => departureDate.isBefore(DateTime.now());
}

/// Port resource for resource view grouping
class Port {
  final String id;
  final String name;
  final String country;
  final String? code;

  const Port({
    required this.id,
    required this.name,
    required this.country,
    this.code,
  });

  String get displayName => code != null ? '$name ($code)' : name;
}

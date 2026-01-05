import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/linear_components.dart';
import '../../../../src/rust/api.dart' as rust_api;
import '../../../../src/rust/models.dart' as rust_models;

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  CalendarView _currentView = CalendarView.timelineMonth;
  final CalendarController _calendarController = CalendarController();

  // Real data from Rust API
  List<rust_models.ShipVisit> _visits = [];
  List<rust_models.Port> _ports = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCalendarData();
  }

  Future<void> _loadCalendarData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Load all visits and ports for calendar
      final visits = await rust_api.getAllShipVisits();
      final ports = await rust_api.getActivePorts();

      if (mounted) {
        setState(() {
          _visits = visits;
          _ports = ports;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Veriler yüklenirken hata oluştu: $e';
          _isLoading = false;
        });
      }
    }
  }

  // Convert Rust ShipVisit to calendar-compatible format
  List<_CalendarVisit> get _calendarVisits {
    return _visits.map((v) {
      return _CalendarVisit(
        id: v.id.toString(),
        shipName: v.shipName ?? 'Bilinmeyen Gemi',
        portName: v.portName ?? 'Bilinmeyen Liman',
        portId: v.portId.toString(),
        arrivalDate: DateTime.parse(v.eta),
        departureDate: DateTime.parse(v.etd),
        status: _mapVisitStatus(v.status),
        notes: v.notes,
      );
    }).toList();
  }

  // Get upcoming visits (ETA >= today)
  List<_CalendarVisit> get _upcomingVisits {
    final now = DateTime.now();
    return _calendarVisits.where((v) => v.arrivalDate.isAfter(now)).toList()
      ..sort((a, b) => a.arrivalDate.compareTo(b.arrivalDate));
  }

  // Map Rust VisitStatus to local enum
  _VisitStatus _mapVisitStatus(rust_models.VisitStatus status) {
    switch (status) {
      case rust_models.VisitStatus.planned:
        return _VisitStatus.planned;
      case rust_models.VisitStatus.arrived:
        return _VisitStatus.arrived;
      case rust_models.VisitStatus.departed:
        return _VisitStatus.departed;
      case rust_models.VisitStatus.cancelled:
        return _VisitStatus.cancelled;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: AppTheme.accent),
              const SizedBox(height: 16),
              Text('Takvim verileri yükleniyor...', style: AppTheme.bodyMedium),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: AppTheme.error),
              const SizedBox(height: 16),
              Text(_errorMessage!, style: AppTheme.bodyMedium),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadCalendarData,
                icon: const Icon(Icons.refresh),
                label: const Text('Tekrar Dene'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (Platform.isWindows || Platform.isMacOS) {
      return _buildDesktopView(context);
    } else {
      return _buildMobileView(context);
    }
  }

  /// Desktop View - Timeline with resource grouping by Port
  Widget _buildDesktopView(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        title: Text(
          'Operasyon Takvimi',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryText,
          ),
        ),
        actions: [
          // View Mode Toggle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ViewToggleButton(
                  label: 'Timeline',
                  icon: Icons.view_timeline_outlined,
                  isSelected: _currentView == CalendarView.timelineMonth,
                  onTap: () => _changeView(CalendarView.timelineMonth),
                ),
                _ViewToggleButton(
                  label: 'Haftalık',
                  icon: Icons.calendar_view_week_outlined,
                  isSelected: _currentView == CalendarView.timelineWeek,
                  onTap: () => _changeView(CalendarView.timelineWeek),
                ),
                _ViewToggleButton(
                  label: 'Aylık',
                  icon: Icons.calendar_month_outlined,
                  isSelected: _currentView == CalendarView.month,
                  onTap: () => _changeView(CalendarView.month),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.today, color: AppTheme.secondaryText),
            onPressed: () {
              _calendarController.displayDate = DateTime.now();
            },
            tooltip: 'Bugün',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.secondaryText),
            onPressed: _loadCalendarData,
            tooltip: 'Yenile',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            // Main Calendar
            Expanded(
              flex: 3,
              child: LinearContainer(
                padding: EdgeInsets.zero,
                child: _buildCalendar(),
              ),
            ),
            const SizedBox(width: 24),
            // Side Panel - Legend & Upcoming
            SizedBox(
              width: 280,
              child: Column(
                children: [
                  // Legend
                  LinearContainer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Durum Açıklaması', style: AppTheme.headingSmall),
                        const SizedBox(height: 16),
                        ..._VisitStatus.values.map((status) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: status.color,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                status.displayName,
                                style: AppTheme.bodyMedium,
                              ),
                            ],
                          ),
                        )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Upcoming Visits
                  Expanded(
                    child: LinearContainer(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Yaklaşan Ziyaretler', style: AppTheme.headingSmall),
                              Text(
                                '${_upcomingVisits.length}',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.accent,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: _upcomingVisits.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.event_busy, size: 32, color: AppTheme.secondaryText),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Yaklaşan ziyaret yok',
                                        style: AppTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: _upcomingVisits.length,
                                  itemBuilder: (context, index) {
                                    final visit = _upcomingVisits[index];
                                    return _UpcomingVisitCard(visit: visit);
                                  },
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Mobile View - Schedule/Agenda style
  Widget _buildMobileView(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        title: Text(
          'Takvim',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryText,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.today, color: AppTheme.secondaryText),
            onPressed: () {
              _calendarController.displayDate = DateTime.now();
            },
          ),
        ],
      ),
      body: SfCalendar(
        controller: _calendarController,
        view: CalendarView.schedule,
        dataSource: _ShipVisitDataSource(_calendarVisits),
        scheduleViewSettings: ScheduleViewSettings(
          appointmentItemHeight: 70,
          monthHeaderSettings: MonthHeaderSettings(
            monthFormat: 'MMMM yyyy',
            height: 60,
            textAlign: TextAlign.center,
            backgroundColor: AppTheme.surface,
            monthTextStyle: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryText,
            ),
          ),
          weekHeaderSettings: WeekHeaderSettings(
            startDateFormat: 'd MMM',
            endDateFormat: 'd MMM',
            height: 40,
            textAlign: TextAlign.center,
            backgroundColor: AppTheme.background,
            weekTextStyle: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.secondaryText,
            ),
          ),
          dayHeaderSettings: DayHeaderSettings(
            dayFormat: 'EEE',
            dateTextStyle: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryText,
            ),
            dayTextStyle: GoogleFonts.inter(
              fontSize: 12,
              color: AppTheme.secondaryText,
            ),
          ),
        ),
        appointmentBuilder: (context, details) {
          final visit = details.appointments.first as _CalendarVisit;
          return _MobileAppointmentCard(visit: visit);
        },
        onTap: (details) {
          if (details.appointments != null && details.appointments!.isNotEmpty) {
            final visit = details.appointments!.first as _CalendarVisit;
            _showVisitDetails(context, visit);
          }
        },
      ),
    );
  }

  Widget _buildCalendar() {
    if (_currentView == CalendarView.month) {
      return SfCalendar(
        controller: _calendarController,
        view: CalendarView.month,
        dataSource: _ShipVisitDataSource(_calendarVisits),
        monthViewSettings: MonthViewSettings(
          appointmentDisplayMode: MonthAppointmentDisplayMode.appointment,
          showAgenda: true,
          agendaViewHeight: 200,
          agendaStyle: AgendaStyle(
            backgroundColor: AppTheme.surface,
            dateTextStyle: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryText,
            ),
            dayTextStyle: GoogleFonts.inter(
              fontSize: 12,
              color: AppTheme.secondaryText,
            ),
            appointmentTextStyle: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.white,
            ),
          ),
        ),
        headerStyle: _calendarHeaderStyle,
        todayHighlightColor: AppTheme.accent,
        selectionDecoration: BoxDecoration(
          border: Border.all(color: AppTheme.accent, width: 2),
          borderRadius: BorderRadius.circular(4),
        ),
        onTap: (details) {
          if (details.appointments != null && details.appointments!.isNotEmpty) {
            final visit = details.appointments!.first as _CalendarVisit;
            _showVisitDetails(context, visit);
          }
        },
      );
    }

    // Timeline views with resource grouping
    return SfCalendar(
      controller: _calendarController,
      view: _currentView,
      dataSource: _ShipVisitDataSource(_calendarVisits),
      resourceViewSettings: ResourceViewSettings(
        size: 120,
        displayNameTextStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppTheme.primaryText,
        ),
      ),
      timeSlotViewSettings: TimeSlotViewSettings(
        timeIntervalHeight: 60,
        timelineAppointmentHeight: 50,
        dateFormat: 'd',
        dayFormat: 'EEE',
        timeTextStyle: GoogleFonts.inter(
          fontSize: 12,
          color: AppTheme.secondaryText,
        ),
      ),
      headerStyle: _calendarHeaderStyle,
      todayHighlightColor: AppTheme.accent,
      appointmentBuilder: (context, details) {
        final visit = details.appointments.first as _CalendarVisit;
        return _DesktopAppointmentCard(visit: visit);
      },
      onTap: (details) {
        if (details.appointments != null && details.appointments!.isNotEmpty) {
          final visit = details.appointments!.first as _CalendarVisit;
          _showVisitDetails(context, visit);
        }
      },
    );
  }

  CalendarHeaderStyle get _calendarHeaderStyle => CalendarHeaderStyle(
    textAlign: TextAlign.center,
    backgroundColor: AppTheme.surface,
    textStyle: GoogleFonts.inter(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: AppTheme.primaryText,
    ),
  );

  void _changeView(CalendarView view) {
    setState(() {
      _currentView = view;
      _calendarController.view = view;
    });
  }

  void _showVisitDetails(BuildContext context, _CalendarVisit visit) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text(visit.shipName, style: AppTheme.headingMedium)),
                  StatusBadge(
                    status: visit.status.displayName,
                    color: visit.status.color,
                  ),
                ],
              ),
              const Divider(height: 32),
              _DetailRow(icon: Icons.location_on_outlined, label: 'Liman', value: visit.portName),
              const SizedBox(height: 12),
              _DetailRow(
                icon: Icons.calendar_today_outlined,
                label: 'Varış',
                value: _formatDate(visit.arrivalDate),
              ),
              const SizedBox(height: 12),
              _DetailRow(
                icon: Icons.calendar_today_outlined,
                label: 'Ayrılış',
                value: _formatDate(visit.departureDate),
              ),
              const SizedBox(height: 12),
              _DetailRow(
                icon: Icons.access_time_outlined,
                label: 'Süre',
                value: '${visit.durationDays} gün',
              ),
              if (visit.notes != null && visit.notes!.isNotEmpty) ...[
                const SizedBox(height: 12),
                _DetailRow(
                  icon: Icons.notes_outlined,
                  label: 'Not',
                  value: visit.notes!,
                ),
              ],
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Kapat', style: GoogleFonts.inter(color: AppTheme.secondaryText)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      // TODO: Navigate to order creation
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text('Sipariş Oluştur', style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}

// ============================================================================
// LOCAL MODELS FOR CALENDAR DISPLAY
// ============================================================================

/// Visit status enum for calendar display
enum _VisitStatus {
  planned,
  arrived,
  departed,
  cancelled,
}

extension _VisitStatusExtension on _VisitStatus {
  String get displayName {
    switch (this) {
      case _VisitStatus.planned:
        return 'Planlandı';
      case _VisitStatus.arrived:
        return 'Vardı';
      case _VisitStatus.departed:
        return 'Ayrıldı';
      case _VisitStatus.cancelled:
        return 'İptal';
    }
  }

  Color get color {
    switch (this) {
      case _VisitStatus.planned:
        return AppTheme.info; // Blue
      case _VisitStatus.arrived:
        return AppTheme.success; // Green
      case _VisitStatus.departed:
        return const Color(0xFF64748B); // Slate 500
      case _VisitStatus.cancelled:
        return AppTheme.error; // Red
    }
  }
}

/// Local calendar visit model
class _CalendarVisit {
  final String id;
  final String shipName;
  final String portName;
  final String portId;
  final DateTime arrivalDate;
  final DateTime departureDate;
  final _VisitStatus status;
  final String? notes;

  const _CalendarVisit({
    required this.id,
    required this.shipName,
    required this.portName,
    required this.portId,
    required this.arrivalDate,
    required this.departureDate,
    required this.status,
    this.notes,
  });

  int get durationDays => departureDate.difference(arrivalDate).inDays + 1;
  bool get isUpcoming => arrivalDate.isAfter(DateTime.now());
}

// ============================================================================
// CALENDAR DATA SOURCE & WIDGETS
// ============================================================================

/// Calendar data source for _CalendarVisit
class _ShipVisitDataSource extends CalendarDataSource {
  _ShipVisitDataSource(List<_CalendarVisit> visits) {
    appointments = visits;
  }

  @override
  DateTime getStartTime(int index) => (appointments![index] as _CalendarVisit).arrivalDate;

  @override
  DateTime getEndTime(int index) => (appointments![index] as _CalendarVisit).departureDate;

  @override
  String getSubject(int index) => (appointments![index] as _CalendarVisit).shipName;

  @override
  Color getColor(int index) => (appointments![index] as _CalendarVisit).status.color;

  @override
  String? getNotes(int index) => (appointments![index] as _CalendarVisit).notes;
}

/// View toggle button for desktop
class _ViewToggleButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ViewToggleButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppTheme.accent : Colors.transparent,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : AppTheme.secondaryText,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.white : AppTheme.secondaryText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Desktop appointment card
class _DesktopAppointmentCard extends StatelessWidget {
  final _CalendarVisit visit;

  const _DesktopAppointmentCard({required this.visit});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 1),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: visit.status.color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            visit.shipName,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            visit.portName,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: Colors.white.withOpacity(0.8),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Mobile appointment card
class _MobileAppointmentCard extends StatelessWidget {
  final _CalendarVisit visit;

  const _MobileAppointmentCard({required this.visit});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(color: visit.status.color, width: 4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  visit.shipName,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${visit.portName} • ${visit.durationDays} gün',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppTheme.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: visit.status.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              visit.status.displayName,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: visit.status.color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Upcoming visit card for sidebar
class _UpcomingVisitCard extends StatelessWidget {
  final _CalendarVisit visit;

  const _UpcomingVisitCard({required this.visit});

  @override
  Widget build(BuildContext context) {
    final daysUntil = visit.arrivalDate.difference(DateTime.now()).inDays;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  visit.shipName,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryText,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '$daysUntil gün',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.location_on_outlined, size: 14, color: AppTheme.secondaryText),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  visit.portName,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppTheme.secondaryText,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Detail row for dialog
class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.secondaryText),
        const SizedBox(width: 12),
        SizedBox(
          width: 80,
          child: Text(label, style: AppTheme.bodySmall),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.primaryText,
            ),
          ),
        ),
      ],
    );
  }
}

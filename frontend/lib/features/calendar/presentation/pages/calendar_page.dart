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

  // Real data from Rust API - using CalendarData with events
  List<rust_models.CalendarEvent> _events = [];
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
      // Get calendar data for 1 year range (6 months past, 6 months future)
      final now = DateTime.now();
      final startDate = now.subtract(const Duration(days: 180));
      final endDate = now.add(const Duration(days: 180));
      
      final calendarData = await rust_api.getCalendarData(
        startDate: startDate.toIso8601String().substring(0, 10),
        endDate: endDate.toIso8601String().substring(0, 10),
      );

      if (mounted) {
        setState(() {
          _events = calendarData.events;
          _ports = calendarData.ports;
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

  // Convert CalendarEvents to display format
  List<_CalendarItem> get _calendarItems {
    return _events.map((e) {
      return _CalendarItem(
        id: e.id,
        title: e.title,
        subtitle: e.subtitle,
        portId: e.relatedPortId?.toString() ?? '0',
        startDate: DateTime.parse(e.startDate),
        endDate: DateTime.parse(e.endDate),
        color: _hexToColor(e.color),
        eventType: e.eventType,
        status: e.status,
      );
    }).toList();
  }

  // Get upcoming events
  List<_CalendarItem> get _upcomingEvents {
    final now = DateTime.now();
    return _calendarItems.where((e) => e.startDate.isAfter(now)).toList()
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
  }
  
  Color _hexToColor(String hex) {
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
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
                  // Legend - Event Types
                  LinearContainer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Etkinlik Türleri', style: AppTheme.headingSmall),
                        const SizedBox(height: 16),
                        _LegendItem(color: const Color(0xFF1E40AF), label: '🚢 Gemi Ziyareti'),
                        const SizedBox(height: 8),
                        _LegendItem(color: const Color(0xFF4F46E5), label: '📦 Sipariş'),
                        const SizedBox(height: 8),
                        _LegendItem(color: const Color(0xFFF59E0B), label: '🏭 Depo Teslimatı'),
                        const SizedBox(height: 8),
                        _LegendItem(color: const Color(0xFF10B981), label: '🚚 Gemi Teslimatı'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Upcoming Events
                  Expanded(
                    child: LinearContainer(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Yaklaşan Etkinlikler', style: AppTheme.headingSmall),
                              Text(
                                '${_upcomingEvents.length}',
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
                            child: _upcomingEvents.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.event_busy, size: 32, color: AppTheme.secondaryText),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Yaklaşan etkinlik yok',
                                        style: AppTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: _upcomingEvents.length > 10 ? 10 : _upcomingEvents.length,
                                  itemBuilder: (context, index) {
                                    final event = _upcomingEvents[index];
                                    return _UpcomingEventCard(event: event);
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
        dataSource: _CalendarDataSource(_calendarItems, _ports),
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
          final item = details.appointments.first as _CalendarItem;
          return _MobileAppointmentCard(item: item);
        },
        onTap: (details) {
          if (details.appointments != null && details.appointments!.isNotEmpty) {
            final item = details.appointments!.first as _CalendarItem;
            _showEventDetails(context, item);
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
        dataSource: _CalendarDataSource(_calendarItems, _ports),
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
            final item = details.appointments!.first as _CalendarItem;
            _showEventDetails(context, item);
          }
        },
      );
    }

    // Timeline views with resource grouping
    return SfCalendar(
      controller: _calendarController,
      view: _currentView,
      dataSource: _CalendarDataSource(_calendarItems, _ports),
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
        final item = details.appointments.first as _CalendarItem;
        return _DesktopAppointmentCard(item: item);
      },
      onTap: (details) {
        if (details.appointments != null && details.appointments!.isNotEmpty) {
          final item = details.appointments!.first as _CalendarItem;
          _showEventDetails(context, item);
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

  void _showEventDetails(BuildContext context, _CalendarItem item) {
    final isOrder = item.eventType == rust_models.CalendarEventType.orderDelivery;
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
                  Expanded(child: Text(item.title, style: AppTheme.headingMedium)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: item.color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      item.status,
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: item.color),
                    ),
                  ),
                ],
              ),
              if (item.subtitle != null) ...[
                const SizedBox(height: 8),
                Text(item.subtitle!, style: AppTheme.bodyMedium.copyWith(color: AppTheme.secondaryText)),
              ],
              const Divider(height: 32),
              _DetailRow(
                icon: isOrder ? Icons.inventory_2_outlined : Icons.directions_boat_outlined,
                label: isOrder ? 'Tür' : 'Tür',
                value: isOrder ? 'Sipariş' : 'Gemi Ziyareti',
              ),
              const SizedBox(height: 12),
              _DetailRow(
                icon: Icons.calendar_today_outlined,
                label: 'Başlangıç',
                value: _formatDate(item.startDate),
              ),
              const SizedBox(height: 12),
              _DetailRow(
                icon: Icons.calendar_today_outlined,
                label: 'Bitiş',
                value: _formatDate(item.endDate),
              ),
              const SizedBox(height: 12),
              _DetailRow(
                icon: Icons.access_time_outlined,
                label: 'Süre',
                value: '${item.endDate.difference(item.startDate).inDays + 1} gün',
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Kapat', style: GoogleFonts.inter(color: AppTheme.secondaryText)),
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

/// Unified calendar item for both visits and orders
class _CalendarItem {
  final String id;
  final String title;
  final String? subtitle;
  final String portId;
  final DateTime startDate;
  final DateTime endDate;
  final Color color;
  final rust_models.CalendarEventType eventType;
  final String status;

  const _CalendarItem({
    required this.id,
    required this.title,
    this.subtitle,
    required this.portId,
    required this.startDate,
    required this.endDate,
    required this.color,
    required this.eventType,
    required this.status,
  });
}

// ============================================================================
// CALENDAR DATA SOURCE & WIDGETS
// ============================================================================

/// Calendar data source for unified events
class _CalendarDataSource extends CalendarDataSource {
  final List<CalendarResource> _resources;

  _CalendarDataSource(List<_CalendarItem> items, List<rust_models.Port> ports)
      : _resources = ports
            .map((p) => CalendarResource(
                  id: p.id.toString(),
                  displayName: p.name,
                  color: AppTheme.accent,
                ))
            .toList() {
    appointments = items;
    resources = _resources;
  }

  @override
  DateTime getStartTime(int index) => (appointments![index] as _CalendarItem).startDate;

  @override
  DateTime getEndTime(int index) => (appointments![index] as _CalendarItem).endDate;

  @override
  String getSubject(int index) => (appointments![index] as _CalendarItem).title;

  @override
  Color getColor(int index) => (appointments![index] as _CalendarItem).color;

  @override
  String? getNotes(int index) => (appointments![index] as _CalendarItem).subtitle;

  @override
  List<Object> getResourceIds(int index) {
    final item = appointments![index] as _CalendarItem;
    return [item.portId];
  }
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

/// Desktop appointment card - unified for visits and orders
class _DesktopAppointmentCard extends StatelessWidget {
  final _CalendarItem item;

  const _DesktopAppointmentCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 1),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: item.color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            item.title,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          if (item.subtitle != null)
            Text(
              item.subtitle!,
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

/// Legend item widget
class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 12),
        Text(label, style: AppTheme.bodyMedium),
      ],
    );
  }
}

/// Mobile appointment card for schedule view
class _MobileAppointmentCard extends StatelessWidget {
  final _CalendarItem item;

  const _MobileAppointmentCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(color: item.color, width: 4),
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
                  item.title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryText,
                  ),
                ),
                if (item.subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.subtitle!,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.secondaryText,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: item.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              item.status,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: item.color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Upcoming event card for sidebar
class _UpcomingEventCard extends StatelessWidget {
  final _CalendarItem event;

  const _UpcomingEventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final daysUntil = event.startDate.difference(DateTime.now()).inDays;
    final isOrder = event.eventType == rust_models.CalendarEventType.orderDelivery;
    
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
                  event.title,
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
                  color: event.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '$daysUntil gün',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: event.color,
                  ),
                ),
              ),
            ],
          ),
          if (event.subtitle != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  isOrder ? Icons.inventory_2_outlined : Icons.directions_boat_outlined,
                  size: 14,
                  color: AppTheme.secondaryText,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    event.subtitle!,
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
